import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// YomiHub: converts DRM-free Kindle books (AZW3 / KF8, MOBI, AZW) to EPUB so
/// the existing EPUB reader can open them.
///
/// Books protected by Amazon DRM are refused: the reader has no right to
/// decrypt them and this converter does not try.
class MobiToEpub {
  static const supportedExtensions = ['azw3', 'mobi', 'azw', 'kf8', 'prc'];

  static bool isKindleFile(String path) =>
      supportedExtensions.contains(p.extension(path).toLowerCase().replaceFirst('.', ''));

  /// Converts [path] and writes `<name>.epub` into [outDir]. Returns the path.
  static Future<String> convertFile(String path, Directory outDir) async {
    final bytes = await File(path).readAsBytes();
    final epub = convert(bytes, fallbackTitle: p.basenameWithoutExtension(path));
    await outDir.create(recursive: true);
    final out = File(p.join(outDir.path, '${p.basenameWithoutExtension(path)}.epub'));
    await out.writeAsBytes(epub, flush: true);
    return out.path;
  }

  static Uint8List convert(Uint8List data, {String fallbackTitle = 'Book'}) {
    final book = _MobiBook(data);
    return book.toEpub(fallbackTitle);
  }
}

class MobiFormatException implements Exception {
  final String message;
  MobiFormatException(this.message);
  @override
  String toString() => message;
}

class _Header {
  late int compression;
  late int textRecordCount;
  late int encryption;
  late int textEncoding;
  late int mobiVersion;
  late int firstNonBook;
  late int firstResource;
  late int extraFlags;
  late int fdstIndex;
  late int fdstCount;
  String? fullName;
  final Map<int, List<Uint8List>> exth = {};
}

class _MobiBook {
  final Uint8List d;
  late final List<int> _offsets;
  late final ByteData _bd;

  _MobiBook(this.d) {
    _bd = ByteData.sublistView(d);
    if (d.length < 78) throw MobiFormatException('Tệp quá nhỏ, không phải sách Kindle');
    final type = ascii.decode(d.sublist(60, 68), allowInvalid: true);
    if (type != 'BOOKMOBI' && type != 'TEXtREAd') {
      throw MobiFormatException('Không phải định dạng AZW3/MOBI ($type)');
    }
    final n = _bd.getUint16(76);
    _offsets = [for (var i = 0; i < n; i++) _bd.getUint32(78 + i * 8)];
  }

  /// Record [i]; offsets past the end of a truncated file give empty data
  /// instead of crashing so the readable part of the book is still kept.
  Uint8List record(int i) {
    if (i < 0 || i >= _offsets.length) return Uint8List(0);
    final start = _offsets[i].clamp(0, d.length);
    final next = i + 1 < _offsets.length ? _offsets[i + 1] : d.length;
    final end = next.clamp(start, d.length);
    return Uint8List.sublistView(d, start, end);
  }

  _Header _readHeader(int recIndex) {
    final r = record(recIndex);
    final b = ByteData.sublistView(r);
    final h = _Header()
      ..compression = b.getUint16(0)
      ..textRecordCount = b.getUint16(8)
      ..encryption = b.getUint16(12);
    h
      ..textEncoding = 1252
      ..mobiVersion = 0
      ..firstNonBook = 0xFFFFFFFF
      ..firstResource = 0xFFFFFFFF
      ..extraFlags = 0
      ..fdstIndex = 0xFFFFFFFF
      ..fdstCount = 0;
    if (r.length >= 24 && ascii.decode(r.sublist(16, 20), allowInvalid: true) == 'MOBI') {
      final hl = b.getUint32(20);
      h.textEncoding = b.getUint32(28);
      h.mobiVersion = b.getUint32(36);
      h.firstNonBook = b.getUint32(0x50);
      final nameOff = b.getUint32(0x54), nameLen = b.getUint32(0x58);
      if (nameOff + nameLen <= r.length) {
        h.fullName = utf8.decode(r.sublist(nameOff, nameOff + nameLen), allowMalformed: true);
      }
      h.firstResource = b.getUint32(0x6C);
      if (hl >= 0xE4 && 16 + hl <= r.length) h.extraFlags = b.getUint16(0xF2);
      if (h.mobiVersion >= 8 && hl >= 0xC8) {
        h.fdstIndex = b.getUint32(0xC0);
        h.fdstCount = b.getUint32(0xC4);
      }
      final exthFlags = b.getUint32(0x80);
      final exthPos = 16 + hl;
      if (exthFlags & 0x40 != 0 &&
          exthPos + 12 <= r.length &&
          ascii.decode(r.sublist(exthPos, exthPos + 4), allowInvalid: true) == 'EXTH') {
        final count = b.getUint32(exthPos + 8);
        var pos = exthPos + 12;
        for (var i = 0; i < count && pos + 8 <= r.length; i++) {
          final t = b.getUint32(pos), len = b.getUint32(pos + 4);
          if (len < 8 || pos + len > r.length) break;
          h.exth.putIfAbsent(t, () => []).add(Uint8List.fromList(r.sublist(pos + 8, pos + len)));
          pos += len;
        }
      }
    }
    return h;
  }

  String? _exthString(_Header h, int t) {
    final v = h.exth[t];
    if (v == null || v.isEmpty) return null;
    return utf8.decode(v.first, allowMalformed: true).trim();
  }

  int? _exthInt(_Header h, int t) {
    final v = h.exth[t];
    if (v == null || v.isEmpty || v.first.length < 4) return null;
    return ByteData.sublistView(v.first).getUint32(0);
  }

  // ---- text decompression ----

  static int _trailingSize(Uint8List rec, int flags) {
    int size = 0;
    int end = rec.length;
    int getVarLenBackward(int endPos) {
      int value = 0, shift = 0, pos = endPos;
      while (pos > 0) {
        final byte = rec[pos - 1];
        value |= (byte & 0x7F) << shift;
        shift += 7;
        pos--;
        if (byte & 0x80 != 0 || shift >= 28) break;
      }
      return value;
    }

    for (var bit = 15; bit >= 1; bit--) {
      if (flags & (1 << bit) != 0) {
        final s = getVarLenBackward(end - size);
        size += s;
      }
    }
    if (flags & 1 != 0 && end - size - 1 >= 0) {
      size += (rec[end - size - 1] & 3) + 1;
    }
    return size.clamp(0, rec.length);
  }

  static Uint8List _palmDoc(Uint8List src) {
    final out = BytesBuilder(copy: false);
    final buf = <int>[];
    var i = 0;
    while (i < src.length) {
      final c = src[i++];
      if (c == 0 || (c >= 0x09 && c <= 0x7F)) {
        buf.add(c);
      } else if (c >= 0x01 && c <= 0x08) {
        for (var k = 0; k < c && i < src.length; k++) {
          buf.add(src[i++]);
        }
      } else if (c >= 0xC0) {
        buf
          ..add(0x20)
          ..add(c ^ 0x80);
      } else if (i < src.length) {
        final pair = (c << 8) | src[i++];
        final dist = (pair >> 3) & 0x7FF;
        final len = (pair & 7) + 3;
        if (dist > 0 && dist <= buf.length) {
          for (var k = 0; k < len; k++) {
            buf.add(buf[buf.length - dist]);
          }
        }
      }
    }
    out.add(buf);
    return out.takeBytes();
  }

  Uint8List _text(_Header h, int base) {
    if (h.encryption != 0) {
      throw MobiFormatException('Sách có DRM của Amazon – YomiHub không mở được sách bị khóa.');
    }
    if (h.compression == 17480) {
      throw MobiFormatException('Sách dùng nén HUFF/CDIC chưa được hỗ trợ.');
    }
    final out = BytesBuilder(copy: false);
    for (var i = 1; i <= h.textRecordCount && base + i < _offsets.length; i++) {
      var rec = record(base + i);
      final trail = _trailingSize(rec, h.extraFlags);
      rec = Uint8List.sublistView(rec, 0, rec.length - trail);
      out.add(h.compression == 2 ? _palmDoc(rec) : rec);
    }
    return out.takeBytes();
  }

  // ---- resources ----

  static String? _imageExt(Uint8List r) {
    if (r.length < 4) return null;
    if (r[0] == 0xFF && r[1] == 0xD8) return 'jpg';
    if (r[0] == 0x89 && r[1] == 0x50 && r[2] == 0x4E && r[3] == 0x47) return 'png';
    if (r[0] == 0x47 && r[1] == 0x49 && r[2] == 0x46) return 'gif';
    if (r[0] == 0x42 && r[1] == 0x4D) return 'bmp';
    if (r.length > 12 && ascii.decode(r.sublist(8, 12), allowInvalid: true) == 'WEBP') return 'webp';
    return null;
  }

  static const _mime = {
    'jpg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    'webp': 'image/webp',
  };

  // ---- conversion ----

  Uint8List toEpub(String fallbackTitle) {
    final h0 = _readHeader(0);
    var h = h0;
    var base = 0;
    final boundary = _exthInt(h0, 121);
    if (boundary != null && boundary > 0 && boundary < _offsets.length && h0.mobiVersion < 8) {
      // Combined MOBI7+KF8 file: prefer the KF8 part.
      try {
        final k = _readHeader(boundary);
        if (k.mobiVersion >= 8) {
          h = k;
          base = boundary;
        }
      } catch (_) {}
    }
    final isKf8 = h.mobiVersion >= 8;
    final raw = _text(h, base);
    final enc = h.textEncoding == 65001 ? utf8 : latin1;
    String decode(List<int> b) => enc == utf8 ? utf8.decode(b, allowMalformed: true) : latin1.decode(b);

    final title = _exthString(h0, 503) ?? h0.fullName ?? fallbackTitle;
    final author = _exthString(h0, 100) ?? '';
    final description = _exthString(h0, 103) ?? '';
    final language = _exthString(h0, 524) ?? 'vi';

    // Resources (images) live after the text. KF8 indexes them from its own
    // first-resource record; the base is relative to the KF8 section.
    final resStart = h.firstResource != 0xFFFFFFFF
        ? base + h.firstResource
        : (h0.firstResource != 0xFFFFFFFF ? h0.firstResource : _offsets.length);
    final images = <int, (String name, String ext)>{}; // 1-based index
    final imageData = <String, Uint8List>{};
    for (var i = resStart, n = 1; i < _offsets.length; i++, n++) {
      final r = record(i);
      final ext = _imageExt(r);
      if (ext == null) {
        if (r.length >= 4) {
          final tag = ascii.decode(r.sublist(0, 4), allowInvalid: true);
          if (tag == 'BOUN' || tag == 'EOF\r') break;
        }
        continue;
      }
      final name = 'image_${n.toString().padLeft(4, '0')}.$ext';
      images[n] = (name, ext);
      imageData[name] = r;
    }
    int? coverIdx;
    final coverOff = _exthInt(h0, 201);
    if (coverOff != null && images.containsKey(coverOff + 1)) coverIdx = coverOff + 1;

    // Split into flows (KF8) – flow 0 is the HTML text, others are CSS/SVG.
    final flows = <Uint8List>[];
    if (isKf8 && h.fdstIndex != 0xFFFFFFFF && base + h.fdstIndex < _offsets.length) {
      final f = record(base + h.fdstIndex);
      final fb = ByteData.sublistView(f);
      if (f.length >= 12 && ascii.decode(f.sublist(0, 4), allowInvalid: true) == 'FDST') {
        final off = fb.getUint32(4), cnt = fb.getUint32(8);
        for (var i = 0; i < cnt && off + i * 8 + 8 <= f.length; i++) {
          final s = fb.getUint32(off + i * 8), e = fb.getUint32(off + i * 8 + 4);
          if (s <= e && e <= raw.length) flows.add(Uint8List.sublistView(raw, s, e));
        }
      }
    }
    if (flows.isEmpty) flows.add(raw);

    if (!isKf8) flows[0] = _insertFileposAnchors(flows[0]);
    final html = decode(flows.first);
    final cssFiles = <String, String>{};
    for (var i = 1; i < flows.length; i++) {
      final text = decode(flows[i]);
      if (text.contains('<svg')) continue;
      cssFiles['style_$i.css'] = text;
    }

    String fixRefs(String s) {
      s = s.replaceAllMapped(RegExp(r'kindle:embed:([0-9A-Va-v]{4})(\?mime=[^"\x27)]*)?'), (m) {
        final idx = int.tryParse(m.group(1)!.toUpperCase(), radix: 32);
        final img = idx == null ? null : images[idx];
        return img == null ? '' : '../Images/${img.$1}';
      });
      s = s.replaceAllMapped(RegExp(r'kindle:flow:([0-9A-Va-v]{4})\?mime=text/css'), (m) {
        final idx = int.tryParse(m.group(1)!.toUpperCase(), radix: 32) ?? 0;
        return '../Styles/style_$idx.css';
      });
      s = s.replaceAll(RegExp(r'kindle:pos:fid:[0-9A-Va-v]{4}:off:[0-9A-Va-v]{10}'), '#');
      // MOBI7 images
      s = s.replaceAllMapped(RegExp(r'<img([^>]*?)recindex="?0*(\d+)"?([^>]*)>', caseSensitive: false), (m) {
        final img = images[int.parse(m.group(2)!)];
        return img == null ? '' : '<img${m.group(1)}src="../Images/${img.$1}"${m.group(3)}>';
      });
      s = s.replaceAll(RegExp(r'<mbp:[^>]*>|</mbp:[^>]*>', caseSensitive: false), '');
      return _toXhtml(s);
    }

    // Chapters
    List<String> parts;
    if (isKf8) {
      final starts = RegExp(r'<\?xml|<html', caseSensitive: false).allMatches(html).map((m) => m.start).toList();
      // drop "<html" that directly follows an "<?xml" prolog
      final cleaned = <int>[];
      for (final s in starts) {
        if (cleaned.isNotEmpty && s - cleaned.last < 200 && html.substring(cleaned.last, s).startsWith('<?xml')) {
          continue;
        }
        cleaned.add(s);
      }
      if (cleaned.isEmpty || cleaned.first != 0) cleaned.insert(0, 0);
      parts = [
        for (var i = 0; i < cleaned.length; i++)
          html.substring(cleaned[i], i + 1 < cleaned.length ? cleaned[i + 1] : html.length),
      ].where((e) => e.trim().isNotEmpty).toList();
    } else {
      parts = html.split(RegExp(r'<mbp:pagebreak\s*/?>', caseSensitive: false)).where((e) => e.trim().isNotEmpty).toList();
    }
    if (parts.isEmpty) parts = [html];

    final chapters = <(String file, String title, String xhtml)>[];
    final cssLinks = cssFiles.keys.map((k) => '<link rel="stylesheet" type="text/css" href="../Styles/$k"/>').join();
    for (var i = 0; i < parts.length; i++) {
      var body = fixRefs(parts[i]);
      String chapTitle = 'Phần ${i + 1}';
      final t = RegExp(r'<h[1-3][^>]*>(.*?)</h[1-3]>', caseSensitive: false, dotAll: true).firstMatch(body) ??
          RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(body);
      if (t != null) {
        final plain = t.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (plain.isNotEmpty && plain.length < 120) chapTitle = plain;
      }
      // Keep only the body content; wrap in a clean document.
      final bm = RegExp(r'<body[^>]*>(.*)', caseSensitive: false, dotAll: true).firstMatch(body);
      var inner = bm != null ? bm.group(1)! : body;
      inner = inner
          .replaceAll(RegExp(r'</body>|</html>|<html[^>]*>|<head>.*?</head>|<\?xml[^>]*\?>|<!DOCTYPE[^>]*>',
              caseSensitive: false, dotAll: true), '')
          .replaceAll(RegExp(r'<body[^>]*>', caseSensitive: false), '');
      final doc = '<?xml version="1.0" encoding="utf-8"?>\n'
          '<!DOCTYPE html>\n<html xmlns="http://www.w3.org/1999/xhtml"><head><meta charset="utf-8"/>'
          '<title>${_esc(chapTitle)}</title>$cssLinks</head><body>$inner</body></html>';
      chapters.add(('chapter_${(i + 1).toString().padLeft(4, '0')}.xhtml', chapTitle, doc));
    }

    // MOBI7 internal links: filepos=N -> chapter file + anchor
    if (!isKf8) {
      final where = <String, String>{};
      for (final c in chapters) {
        for (final m in RegExp(r'id="(fp\d+)"').allMatches(c.$3)) {
          where[m.group(1)!] = c.$1;
        }
      }
      for (var i = 0; i < chapters.length; i++) {
        final c = chapters[i];
        final fixed = c.$3.replaceAllMapped(RegExp(r'filepos="?0*(\d+)"?', caseSensitive: false), (m) {
          final id = 'fp${m.group(1)}';
          final f = where[id];
          return f == null ? 'href="#"' : 'href="${f == c.$1 ? '' : f}#$id"';
        });
        chapters[i] = (c.$1, c.$2, fixed);
      }
    }

    // ---- EPUB assembly ----
    final arc = Archive();
    void add(String name, List<int> bytes, {bool store = false}) {
      arc.add(store
          ? ArchiveFile.noCompress(name, bytes.length, bytes)
          : ArchiveFile.bytes(name, bytes));
    }

    add('mimetype', ascii.encode('application/epub+zip'), store: true);
    add('META-INF/container.xml', utf8.encode('<?xml version="1.0"?>'
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
        '<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
        '</rootfiles></container>'));
    final manifest = StringBuffer();
    final spine = StringBuffer();
    final nav = StringBuffer();
    for (var i = 0; i < chapters.length; i++) {
      final c = chapters[i];
      add('OEBPS/Text/${c.$1}', utf8.encode(c.$3));
      manifest.write('<item id="c$i" href="Text/${c.$1}" media-type="application/xhtml+xml"/>');
      spine.write('<itemref idref="c$i"/>');
      nav.write('<navPoint id="n$i" playOrder="${i + 1}"><navLabel><text>${_esc(c.$2)}</text></navLabel>'
          '<content src="Text/${c.$1}"/></navPoint>');
    }
    for (final e in cssFiles.entries) {
      add('OEBPS/Styles/${e.key}', utf8.encode(e.value));
      manifest.write('<item id="${e.key.replaceAll('.', '_')}" href="Styles/${e.key}" media-type="text/css"/>');
    }
    String? coverItem;
    for (final e in images.entries) {
      final (name, ext) = e.value;
      add('OEBPS/Images/$name', imageData[name]!);
      final id = 'img${e.key}';
      if (e.key == coverIdx) coverItem = id;
      manifest.write('<item id="$id" href="Images/$name" media-type="${_mime[ext]}"'
          '${e.key == coverIdx ? ' properties="cover-image"' : ''}/>');
    }
    manifest.write('<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    final uid = 'yomihub-${title.hashCode.toUnsigned(32)}';
    add('OEBPS/content.opf', utf8.encode('<?xml version="1.0" encoding="utf-8"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="uid">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">'
        '<dc:title>${_esc(title)}</dc:title><dc:creator>${_esc(author)}</dc:creator>'
        '<dc:language>${_esc(language)}</dc:language><dc:identifier id="uid">$uid</dc:identifier>'
        '<dc:description>${_esc(description)}</dc:description>'
        '${coverItem != null ? '<meta name="cover" content="$coverItem"/>' : ''}'
        '</metadata><manifest>$manifest</manifest><spine toc="ncx">$spine</spine></package>'));
    add('OEBPS/toc.ncx', utf8.encode('<?xml version="1.0" encoding="utf-8"?>'
        '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1"><head>'
        '<meta name="dtb:uid" content="$uid"/></head><docTitle><text>${_esc(title)}</text></docTitle>'
        '<navMap>$nav</navMap></ncx>'));
    return Uint8List.fromList(ZipEncoder().encode(arc));
  }

  static String _esc(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}


/// Inserts `<a id="fpN"></a>` at every byte offset referenced by a MOBI7
/// `filepos=N` link (offsets are byte positions in the decompressed text).
Uint8List _insertFileposAnchors(Uint8List text) {
  final asLatin = latin1.decode(text);
  final targets = RegExp(r'filepos="?0*(\d+)"?', caseSensitive: false)
      .allMatches(asLatin)
      .map((m) => int.parse(m.group(1)!))
      .where((o) => o >= 0 && o < text.length)
      .toSet()
      .toList()
    ..sort();
  if (targets.isEmpty) return text;
  final out = BytesBuilder(copy: false);
  var pos = 0;
  for (final t in targets) {
    // never cut a tag in half: step back to the start of the tag we landed in
    var k = t;
    while (k > pos && text[k] != 0x3C && text[k - 1] != 0x3E) {
      k--;
      if (t - k > 400) {
        k = t;
        break;
      }
    }
    if (k < pos) k = pos;
    out.add(Uint8List.sublistView(text, pos, k));
    out.add(ascii.encode('<a id="fp$t"></a>'));
    pos = k;
  }
  out.add(Uint8List.sublistView(text, pos));
  return out.takeBytes();
}

const _voidTags = {'br', 'hr', 'img', 'meta', 'link', 'input', 'col', 'area', 'base', 'wbr', 'source'};

/// Light HTML -> XHTML clean-up for old Kindle markup: quotes bare attribute
/// values and closes void elements, so strict EPUB readers accept it.
String _toXhtml(String s) {
  final bareAttr = RegExp('(\\s[\\w:-]+)\\s*=\\s*([^\\s"\'>]+)');
  s = s.replaceAllMapped(RegExp(r'<([a-zA-Z][\w:-]*)((?:\s[^<>]*?)?)(/?)>'), (m) {
    final tag = m.group(1)!;
    var attrs = m.group(2) ?? '';
    attrs = attrs.replaceAllMapped(bareAttr, (a) => '${a.group(1)}="${a.group(2)}"');
    final close = (m.group(3) == '/' || _voidTags.contains(tag.toLowerCase())) ? '/' : '';
    return '<$tag$attrs$close>';
  });
  // closing tags of void elements (</br>, </img>) are invalid in XHTML
  s = s.replaceAll(RegExp(r'</(br|hr|img|meta|link|input|col|area|base|wbr|source)\s*>', caseSensitive: false), '');
  // bare ampersands
  s = s.replaceAll(RegExp(r'&(?!#?[a-zA-Z0-9]+;)'), '&amp;');
  return s;
}
