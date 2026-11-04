import 'dart:convert';
import 'dart:typed_data';

/// YomiHub 0.5.1: Android binary XML (AXML) decoder – the compiled
/// `AndroidManifest.xml` inside an APK.
///
/// Dart port of `Pact/decode_manifest.js` from
/// https://github.com/kiritokmn1403/Decode-Extract (project owner's repo),
/// with bounds checks and two fixes:
/// * UTF-8 string lengths ≥ 128 use two bytes (the script skipped the second
///   byte but kept only the first, cutting long strings);
/// * namespace prefixes are written on the root element only once.
///
/// Used by [ApkInspector] to read extension APKs (Mihon / Aniyomi / IReader):
/// package, version, `<meta-data>` such as `tachiyomi.extension.class`.
class AxmlElement {
  final String name;
  final Map<String, String> attributes;
  final List<AxmlElement> children = [];
  AxmlElement(this.name, this.attributes);

  /// First attribute whose local name is [local] (any namespace prefix).
  String? attr(String local) {
    for (final e in attributes.entries) {
      final k = e.key;
      if (k == local || k.endsWith(':$local')) return e.value;
    }
    return null;
  }

  Iterable<AxmlElement> descendants(String tag) sync* {
    for (final c in children) {
      if (c.name == tag) yield c;
      yield* c.descendants(tag);
    }
  }
}

class AxmlDocument {
  final AxmlElement? root;
  final String xml;
  AxmlDocument(this.root, this.xml);
}

class AxmlDecoder {
  AxmlDecoder._();

  static const _resXmlType = 0x0003;
  static const _stringPool = 0x0001;
  static const _resourceMap = 0x0180;
  static const _startNamespace = 0x0100;
  static const _endNamespace = 0x0101;
  static const _startTag = 0x0102;
  static const _endTag = 0x0103;
  static const _cdata = 0x0104;

  /// Throws [FormatException] when [bytes] is not binary XML.
  static AxmlDocument decode(Uint8List bytes) {
    final b = ByteData.sublistView(bytes);
    int u16(int o) => b.getUint16(o, Endian.little);
    int u32(int o) => b.getUint32(o, Endian.little);
    int i32(int o) => b.getInt32(o, Endian.little);
    if (bytes.length < 8 || u16(0) != _resXmlType) {
      throw const FormatException('Không phải Android binary XML');
    }

    var pos = 8;
    // ---- string pool
    final strings = <String>[];
    if (u16(pos) == _stringPool) {
      final chunkSize = u32(pos + 4);
      final count = u32(pos + 8);
      final flags = u32(pos + 16);
      final utf8Pool = (flags & (1 << 8)) != 0;
      final stringsStart = pos + u32(pos + 20);
      for (var i = 0; i < count; i++) {
        var s = stringsStart + u32(pos + 28 + i * 4);
        try {
          if (utf8Pool) {
            // utf16 length (1–2 bytes), then utf8 length (1–2 bytes)
            s += (bytes[s] & 0x80) != 0 ? 2 : 1;
            var len = bytes[s];
            if ((len & 0x80) != 0) {
              len = ((len & 0x7f) << 8) | bytes[s + 1];
              s += 2;
            } else {
              s += 1;
            }
            strings.add(utf8.decode(bytes.sublist(s, s + len), allowMalformed: true));
          } else {
            var len = u16(s);
            s += 2;
            if ((len & 0x8000) != 0) {
              len = ((len & 0x7fff) << 16) | u16(s);
              s += 2;
            }
            final units = <int>[for (var k = 0; k < len; k++) u16(s + k * 2)];
            strings.add(String.fromCharCodes(units));
          }
        } catch (_) {
          strings.add('');
        }
      }
      pos += chunkSize;
    }
    String str(int idx) => idx >= 0 && idx < strings.length ? strings[idx] : '';

    if (pos + 8 <= bytes.length && u16(pos) == _resourceMap) pos += u32(pos + 4);

    final ns = <String, String>{}; // uri -> prefix
    final stack = <AxmlElement>[];
    AxmlElement? root;
    final out = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n');
    var nsWritten = false;
    String esc(String v) => v
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    while (pos + 8 <= bytes.length) {
      final type = u16(pos);
      final size = u32(pos + 4);
      if (size == 0 || pos + size > bytes.length) break;
      if (type == _startNamespace) {
        ns[str(i32(pos + 20))] = str(i32(pos + 16));
      } else if (type == _endNamespace) {
        // nothing
      } else if (type == _startTag) {
        final name = str(i32(pos + 20));
        final attrStart = u16(pos + 24);
        final attrSize = u16(pos + 26);
        final attrCount = u16(pos + 28);
        final attrs = <String, String>{};
        for (var i = 0; i < attrCount; i++) {
          final a = pos + 16 + attrStart + i * attrSize;
          if (a + 20 > bytes.length) break;
          final nsUri = str(i32(a));
          final prefix = ns[nsUri];
          final aName = str(i32(a + 4));
          final raw = i32(a + 8);
          final vType = bytes[a + 15];
          final data = u32(a + 16);
          String v;
          if (raw >= 0) {
            v = str(raw);
          } else {
            switch (vType) {
              case 3:
                v = str(data);
              case 18:
                v = data != 0 ? 'true' : 'false';
              case 1:
                v = '@0x${data.toRadixString(16)}';
              case 16:
                v = b.getInt32(a + 16, Endian.little).toString();
              case 17:
                v = '0x${data.toRadixString(16)}';
              default:
                v = data.toString();
            }
          }
          attrs[(prefix != null && prefix.isNotEmpty) ? '$prefix:$aName' : aName] = v;
        }
        final el = AxmlElement(name, attrs);
        if (stack.isEmpty) {
          root ??= el;
        } else {
          stack.last.children.add(el);
        }
        final pad = '    ' * stack.length;
        out.write('$pad<$name');
        if (!nsWritten) {
          for (final e in ns.entries) {
            out.write(' xmlns:${e.value}="${esc(e.key)}"');
          }
          nsWritten = true;
        }
        for (final e in attrs.entries) {
          out.write('\n$pad    ${e.key}="${esc(e.value)}"');
        }
        out.write('>\n');
        stack.add(el);
      } else if (type == _endTag) {
        if (stack.isNotEmpty) stack.removeLast();
        out.write('${'    ' * stack.length}</${str(i32(pos + 20))}>\n');
      } else if (type == _cdata) {
        final t = str(i32(pos + 16));
        if (t.isNotEmpty) out.write('${'    ' * stack.length}${esc(t)}\n');
      }
      pos += size;
    }
    return AxmlDocument(root, out.toString());
  }
}
