import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;

import 'mobi_to_epub.dart';

/// YomiHub ebook import (Calibre-style conversion to EPUB):
/// AZW3 / MOBI / AZW / PRC (Kindle), FB2, TXT, HTML. The result is an EPUB 2
/// that the novel reader opens like any other book.
class YomiEbook {
  static const kindle = ['.azw3', '.azw', '.mobi', '.kf8', '.prc'];
  static const others = ['.fb2', '.txt', '.html', '.htm', '.xhtml'];

  static bool isConvertible(String path) {
    final e = p.extension(path).toLowerCase();
    return kindle.contains(e) || others.contains(e) || path.toLowerCase().endsWith('.fb2.zip');
  }

  static bool isSupported(String path) =>
      path.toLowerCase().endsWith('.epub') || isConvertible(path);

  /// Converts [path] once into [outDir] (cached by name + size) and returns
  /// the EPUB path.
  static Future<String> convertFile(String path, Directory outDir) async {
    if (MobiToEpub.isKindleFile(path)) return MobiToEpub.convertFile(path, outDir);
    final f = File(path);
    final stat = await f.stat();
    await outDir.create(recursive: true);
    final base = p.basenameWithoutExtension(path).replaceAll(RegExp(r'[^\w\-. ]+'), '_');
    final out = File(p.join(outDir.path, '${base}_${stat.size}.epub'));
    if (await out.exists()) return out.path;
    var bytes = await f.readAsBytes();
    final lower = path.toLowerCase();
    Uint8List epub;
    if (lower.endsWith('.fb2.zip')) {
      final arc = ZipDecoder().decodeBytes(bytes);
      final fb2 = arc.files.firstWhere((e) => e.name.toLowerCase().endsWith('.fb2'));
      bytes = Uint8List.fromList(fb2.content as List<int>);
      epub = Fb2ToEpub.convert(bytes, base);
    } else if (lower.endsWith('.fb2')) {
      epub = Fb2ToEpub.convert(bytes, base);
    } else if (lower.endsWith('.txt')) {
      epub = TxtToEpub.convert(bytes, base);
    } else {
      epub = HtmlToEpub.convert(bytes, base);
    }
    await out.writeAsBytes(epub, flush: true);
    return out.path;
  }
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Decodes text files written by Vietnamese tools: UTF-8 (with/without BOM),
/// UTF-16 LE/BE; falls back to Latin-1.
String decodeText(Uint8List b) {
  if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
    final codes = <int>[];
    for (var i = 2; i + 1 < b.length; i += 2) {
      codes.add(b[i] | (b[i + 1] << 8));
    }
    return String.fromCharCodes(codes);
  }
  if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
    final codes = <int>[];
    for (var i = 2; i + 1 < b.length; i += 2) {
      codes.add((b[i] << 8) | b[i + 1]);
    }
    return String.fromCharCodes(codes);
  }
  var start = 0;
  if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) start = 3;
  try {
    return utf8.decode(b.sublist(start));
  } catch (_) {
    return utf8.decode(b.sublist(start), allowMalformed: true);
  }
}

class EpubChapter {
  final String title;
  final String body; // XHTML body content
  EpubChapter(this.title, this.body);
}

/// Minimal EPUB 2 writer shared by the converters.
class EpubWriter {
  static Uint8List build({
    required String title,
    String author = '',
    String language = 'vi',
    String description = '',
    required List<EpubChapter> chapters,
    Map<String, (Uint8List, String)> images = const {}, // name -> (bytes, mime)
    String? coverImage,
  }) {
    final arc = Archive();
    void add(String name, List<int> bytes, {bool store = false}) => arc.add(
      store ? ArchiveFile.noCompress(name, bytes.length, bytes) : ArchiveFile.bytes(name, bytes),
    );
    add('mimetype', ascii.encode('application/epub+zip'), store: true);
    add('META-INF/container.xml', utf8.encode('<?xml version="1.0"?>'
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
        '<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
        '</rootfiles></container>'));
    final css = 'body{line-height:1.6;margin:0 4%;} p{text-indent:1.2em;margin:0 0 .6em 0;} '
        'h1,h2,h3{text-align:center;} img{max-width:100%;}';
    add('OEBPS/Styles/style.css', utf8.encode(css));
    final manifest = StringBuffer(
        '<item id="css" href="Styles/style.css" media-type="text/css"/>'
        '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    final spine = StringBuffer();
    final nav = StringBuffer();
    final list = chapters.isEmpty ? [EpubChapter(title, '<p></p>')] : chapters;
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      final file = 'chapter_${(i + 1).toString().padLeft(4, '0')}.xhtml';
      final doc = '<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE html>\n'
          '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta charset="utf-8"/>'
          '<title>${_esc(c.title)}</title><link rel="stylesheet" type="text/css" href="../Styles/style.css"/>'
          '</head><body>${c.body}</body></html>';
      add('OEBPS/Text/$file', utf8.encode(doc));
      manifest.write('<item id="c$i" href="Text/$file" media-type="application/xhtml+xml"/>');
      spine.write('<itemref idref="c$i"/>');
      nav.write('<navPoint id="n$i" playOrder="${i + 1}"><navLabel><text>${_esc(c.title)}</text></navLabel>'
          '<content src="Text/$file"/></navPoint>');
    }
    var imgN = 0;
    String? coverId;
    images.forEach((name, v) {
      add('OEBPS/Images/$name', v.$1);
      final id = 'img${imgN++}';
      if (name == coverImage) coverId = id;
      manifest.write('<item id="$id" href="Images/$name" media-type="${v.$2}"/>');
    });
    final uid = 'yomihub-${title.hashCode.toUnsigned(32)}-${chapters.length}';
    add('OEBPS/content.opf', utf8.encode('<?xml version="1.0" encoding="utf-8"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="uid">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">'
        '<dc:title>${_esc(title)}</dc:title><dc:creator>${_esc(author)}</dc:creator>'
        '<dc:language>${_esc(language)}</dc:language><dc:identifier id="uid">$uid</dc:identifier>'
        '<dc:description>${_esc(description)}</dc:description>'
        '${coverId != null ? '<meta name="cover" content="$coverId"/>' : ''}'
        '</metadata><manifest>$manifest</manifest><spine toc="ncx">$spine</spine></package>'));
    add('OEBPS/toc.ncx', utf8.encode('<?xml version="1.0" encoding="utf-8"?>'
        '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1"><head>'
        '<meta name="dtb:uid" content="$uid"/></head><docTitle><text>${_esc(title)}</text></docTitle>'
        '<navMap>$nav</navMap></ncx>'));
    return Uint8List.fromList(ZipEncoder().encode(arc));
  }
}

/// TXT → EPUB. Chapters are detected from headings such as
/// "Chương 12: …", "Chapter 3", "Hồi 5", "Quyển 2", "第十章", "Phần 1".
class TxtToEpub {
  static final _heading = RegExp(
    r'^\s*((chương|chuong|chapter|hồi|hoi|quyển|quyen|tập|tap|phần|phan|vol(ume)?|book|part|episode)\s*[\dIVXLCDMivxlcdm]+[^\n]{0,80}|第[0-9零一二三四五六七八九十百千]+[章回节卷][^\n]{0,60}|(mở đầu|lời mở đầu|lời tựa|prologue|epilogue|vĩ thanh|ngoại truyện|phiên ngoại)[^\n]{0,60})\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  static Uint8List convert(Uint8List bytes, String fallbackTitle) {
    final text = decodeText(bytes).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = text.split('\n');
    var title = fallbackTitle;
    // first short non-empty line is usually the title
    for (final l in lines.take(10)) {
      final t = l.trim();
      if (t.isNotEmpty && t.length < 120 && !_heading.hasMatch(t)) {
        title = t;
        break;
      }
    }
    final chapters = <EpubChapter>[];
    String curTitle = 'Mở đầu';
    final buf = StringBuffer();
    void flush() {
      final body = buf.toString().trim();
      if (body.isNotEmpty) {
        chapters.add(EpubChapter(curTitle, '<h2>${_esc(curTitle)}</h2>$body'));
      }
      buf.clear();
    }

    var paraCount = 0;
    for (final raw in lines) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      if (l.length < 100 && _heading.hasMatch(l)) {
        flush();
        curTitle = l;
        paraCount = 0;
        continue;
      }
      buf.write('<p>${_esc(l)}</p>');
      paraCount++;
      // no headings at all: split long books into ~300-paragraph parts
      if (chapters.isEmpty && curTitle == 'Mở đầu' && paraCount >= 300 && !_heading.hasMatch(text)) {
        curTitle = 'Phần ${chapters.length + 1}';
        flush();
        curTitle = 'Phần ${chapters.length + 1}';
        paraCount = 0;
      }
    }
    flush();
    return EpubWriter.build(title: title, chapters: chapters);
  }
}

/// FictionBook 2 → EPUB (sections become chapters, binaries become images).
class Fb2ToEpub {
  static String _href(xml.XmlElement e) {
    for (final a in e.attributes) {
      if (a.name.local == 'href') return a.value;
    }
    return '';
  }

  static Iterable<xml.XmlElement> _kids(xml.XmlElement e, String name) =>
      e.children.whereType<xml.XmlElement>().where((c) => c.name.local == name);

  static xml.XmlElement? _first(xml.XmlNode root, List<String> path) {
    xml.XmlNode cur = root;
    for (final n in path) {
      final list = (cur is xml.XmlDocument ? cur.children : (cur as xml.XmlElement).children)
          .whereType<xml.XmlElement>()
          .where((c) => c.name.local == n);
      if (list.isEmpty) return null;
      cur = list.first;
    }
    return cur is xml.XmlElement ? cur : null;
  }

  static Uint8List convert(Uint8List bytes, String fallbackTitle) {
    final doc = xml.XmlDocument.parse(decodeText(bytes));
    final root = doc.rootElement;
    String q(List<String> path) => _first(root, path)?.innerText.trim() ?? '';
    final ti = ['description', 'title-info'];
    final title = q([...ti, 'book-title']).isNotEmpty ? q([...ti, 'book-title']) : fallbackTitle;
    final author = [
      q([...ti, 'author', 'first-name']),
      q([...ti, 'author', 'middle-name']),
      q([...ti, 'author', 'last-name']),
    ].where((e) => e.isNotEmpty).join(' ');
    final lang = q([...ti, 'lang']).isNotEmpty ? q([...ti, 'lang']) : 'vi';
    final annotation = q([...ti, 'annotation']);

    final images = <String, (Uint8List, String)>{};
    for (final b in _kids(root, 'binary')) {
      final id = b.getAttribute('id') ?? '';
      final mime = b.getAttribute('content-type') ?? 'image/jpeg';
      if (id.isEmpty) continue;
      try {
        final data = base64.decode(b.innerText.replaceAll(RegExp(r'\s+'), ''));
        final ext = mime.contains('png') ? 'png' : (mime.contains('gif') ? 'gif' : 'jpg');
        final clean = id.replaceAll(RegExp(r'[^\w\-.]'), '_');
        images[clean.contains('.') ? clean : '$clean.$ext'] = (Uint8List.fromList(data), mime);
      } catch (_) {}
    }
    String imgName(String href) {
      final clean = href.replaceFirst('#', '').replaceAll(RegExp(r'[^\w\-.]'), '_');
      return images.keys.firstWhere((k) => k == clean || k.startsWith('$clean.'), orElse: () => clean);
    }

    String? cover;
    final coverPage = _first(root, [...ti, 'coverpage']);
    if (coverPage != null) {
      final img = _kids(coverPage, 'image');
      if (img.isNotEmpty && _href(img.first).isNotEmpty) cover = imgName(_href(img.first));
    }

    String render(xml.XmlNode n) {
      if (n is xml.XmlText) return _esc(n.value);
      if (n is xml.XmlCDATA) return _esc(n.value);
      if (n is! xml.XmlElement) return '';
      final tag = n.name.local;
      if (tag == 'section') return ''; // nested sections become chapters
      final inner = n.children.map(render).join();
      switch (tag) {
        case 'p':
        case 'v':
          return '<p>$inner</p>';
        case 'emphasis':
          return '<em>$inner</em>';
        case 'strong':
          return '<strong>$inner</strong>';
        case 'strikethrough':
          return '<del>$inner</del>';
        case 'sup':
        case 'sub':
        case 'code':
          return '<$tag>$inner</$tag>';
        case 'empty-line':
          return '<br/>';
        case 'subtitle':
          return '<h3>$inner</h3>';
        case 'title':
          return '<h2>${n.innerText.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll('&', '&amp;').replaceAll('<', '&lt;')}</h2>';
        case 'epigraph':
        case 'cite':
          return '<blockquote>$inner</blockquote>';
        case 'text-author':
          return '<p><em>$inner</em></p>';
        case 'image':
          final h = _href(n);
          return h.isEmpty ? '' : '<div style="text-align:center"><img src="../Images/${imgName(h)}" alt=""/></div>';
        default:
          return inner;
      }
    }

    final chapters = <EpubChapter>[];
    if (cover != null && images.containsKey(cover)) {
      chapters.add(EpubChapter(title, '<div style="text-align:center"><img src="../Images/$cover" alt=""/></div>'));
    }
    void walk(xml.XmlElement section) {
      final titles = _kids(section, 'title');
      final t = titles.isEmpty ? '' : titles.first.innerText.trim().replaceAll(RegExp(r'\s+'), ' ');
      final body = section.children.map(render).join();
      final plain = body.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      if (plain.isNotEmpty && plain != t) {
        chapters.add(EpubChapter(t.isNotEmpty ? t : 'Phần ${chapters.length + 1}', body));
      }
      for (final s in _kids(section, 'section')) {
        walk(s);
      }
    }

    for (final body in _kids(root, 'body')) {
      if ((body.getAttribute('name') ?? '') == 'notes') {
        final notes = body.descendants
            .whereType<xml.XmlElement>()
            .where((e) => e.name.local == 'section')
            .map((s) => s.children.map(render).join())
            .join('<hr/>');
        if (notes.isNotEmpty) chapters.add(EpubChapter('Chú thích', notes));
        continue;
      }
      final sections = _kids(body, 'section').toList();
      if (sections.isEmpty) {
        chapters.add(EpubChapter(title, body.children.map(render).join()));
      }
      for (final s in sections) {
        walk(s);
      }
    }
    return EpubWriter.build(
      title: title,
      author: author,
      language: lang,
      description: annotation,
      chapters: chapters,
      images: images,
      coverImage: cover,
    );
  }
}

/// Single HTML file → EPUB, split at <h1>/<h2>.
class HtmlToEpub {
  static Uint8List convert(Uint8List bytes, String fallbackTitle) {
    final doc = html.parse(decodeText(bytes));
    doc.querySelectorAll('script,style,noscript,iframe,nav,footer').forEach((e) => e.remove());
    final title = doc.querySelector('title')?.text.trim().isNotEmpty == true
        ? doc.querySelector('title')!.text.trim()
        : fallbackTitle;
    final body = doc.body;
    final chapters = <EpubChapter>[];
    var curTitle = title;
    final buf = StringBuffer();
    void flush() {
      if (buf.toString().replaceAll(RegExp(r'<[^>]+>'), '').trim().isNotEmpty) {
        chapters.add(EpubChapter(curTitle, buf.toString()));
      }
      buf.clear();
    }

    String xhtml(dom.Node n) {
      if (n is dom.Text) return _esc(n.text);
      if (n is! dom.Element) return '';
      const voids = {'br', 'hr', 'img'};
      final tag = n.localName ?? 'div';
      if (tag == 'img') {
        // remote images can't be packed offline; keep alt text
        final alt = n.attributes['alt'] ?? '';
        return alt.isEmpty ? '' : '<p><em>[${_esc(alt)}]</em></p>';
      }
      if (voids.contains(tag)) return '<$tag/>';
      const keep = {'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'em', 'i', 'b', 'strong', 'blockquote', 'ul', 'ol', 'li', 'pre', 'code', 'sup', 'sub', 'table', 'tr', 'td', 'th', 'tbody', 'thead'};
      final inner = n.nodes.map(xhtml).join();
      return keep.contains(tag) ? '<$tag>$inner</$tag>' : inner;
    }

    for (final n in body?.nodes ?? const <dom.Node>[]) {
      if (n is dom.Element && (n.localName == 'h1' || n.localName == 'h2')) {
        flush();
        curTitle = n.text.trim().isNotEmpty ? n.text.trim() : curTitle;
      }
      buf.write(xhtml(n));
    }
    flush();
    return EpubWriter.build(title: title, chapters: chapters);
  }
}
