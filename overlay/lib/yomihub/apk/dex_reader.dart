import 'dart:convert';
import 'dart:typed_data';

/// One class of a `classes*.dex` file: names and signatures only (no code).
class DexClass {
  final String name; // java form: a.b.C
  final int accessFlags;
  final String? superclass;
  final List<String> interfaces;
  final String? sourceFile;
  final List<String> fields; // "static final int X"
  final List<String> methods; // "public void foo(int, java.lang.String)"
  DexClass(this.name, this.accessFlags, this.superclass, this.interfaces,
      this.sourceFile, this.fields, this.methods);

  bool get isInterface => (accessFlags & 0x0200) != 0;
  bool get isAbstract => (accessFlags & 0x0400) != 0;
  String get packageName => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : '';
  String get simpleName => name.substring(name.lastIndexOf('.') + 1);

  /// Java-like outline (what `extract_classes.js` wrote to .java files).
  String outline() {
    final kind = isInterface ? 'interface' : ((accessFlags & 0x4000) != 0 ? 'enum' : 'class');
    final head = StringBuffer('${DexReader.modifiers(accessFlags & ~0x0020)} $kind $simpleName'.trim());
    if (superclass != null && superclass != 'java.lang.Object' && !isInterface) head.write(' extends $superclass');
    if (interfaces.isNotEmpty) head.write(' implements ${interfaces.join(', ')}');
    final sb = StringBuffer();
    if (packageName.isNotEmpty) sb.writeln('package $packageName;\n');
    if (sourceFile != null) sb.writeln('// Compiled from $sourceFile');
    sb.writeln('$head {');
    for (final f in fields) {
      sb.writeln('    $f;');
    }
    for (final m in methods) {
      sb.writeln('    $m;');
    }
    sb.writeln('}');
    return sb.toString();
  }
}

/// YomiHub 0.5.1: Dalvik Executable reader.
///
/// Dart port of `Pact/extract_classes.js` from
/// https://github.com/kiritokmn1403/Decode-Extract (project owner's repo).
/// It reads the DEX header tables (strings, types, protos, fields, methods,
/// class_defs) and the class_data_item of each class and returns names and
/// signatures only – method bodies (bytecode) are not decoded, exactly like
/// the original script. Generalised from "com.vbook classes of classes3.dex"
/// to any package filter; nothing is written to disk.
///
/// Used by [ApkInspector] to find the extension entry classes of an
/// extension APK (Mihon `Source` / `SourceFactory`, Aniyomi, IReader).
class DexReader {
  DexReader._();

  static String modifiers(int f) {
    final m = <String>[];
    if (f & 0x0001 != 0) m.add('public');
    if (f & 0x0002 != 0) m.add('private');
    if (f & 0x0004 != 0) m.add('protected');
    if (f & 0x0008 != 0) m.add('static');
    if (f & 0x0010 != 0) m.add('final');
    if (f & 0x0020 != 0) m.add('synchronized');
    if (f & 0x0100 != 0) m.add('native');
    if (f & 0x0400 != 0) m.add('abstract');
    return m.join(' ');
  }

  static String javaType(String? d) {
    if (d == null || d.isEmpty) return 'void';
    if (d.startsWith('[')) return '${javaType(d.substring(1))}[]';
    switch (d) {
      case 'V':
        return 'void';
      case 'Z':
        return 'boolean';
      case 'B':
        return 'byte';
      case 'S':
        return 'short';
      case 'C':
        return 'char';
      case 'I':
        return 'int';
      case 'J':
        return 'long';
      case 'F':
        return 'float';
      case 'D':
        return 'double';
    }
    if (d.startsWith('L') && d.endsWith(';')) return d.substring(1, d.length - 1).replaceAll('/', '.');
    return d;
  }

  /// Classes of [dex]; [packagePrefix] (java form, e.g. "eu.kanade") limits
  /// the result. Throws [FormatException] when [dex] is not a DEX file.
  /// Number of classes defined in [dex] (header only).
  static int classCount(Uint8List dex) =>
      dex.length < 0x70 ? 0 : ByteData.sublistView(dex).getUint32(0x60, Endian.little);

  /// [keep] (0.5.1) decides from name / superclass / interfaces whether a
  /// class is returned; members are decoded only for kept classes.
  static List<DexClass> read(Uint8List dex,
      {String? packagePrefix,
      int maxClasses = 20000,
      bool Function(String name, String? superclass, List<String> interfaces)? keep}) {
    if (dex.length < 0x70 || utf8.decode(dex.sublist(0, 3), allowMalformed: true) != 'dex') {
      throw const FormatException('Không phải tệp DEX');
    }
    final b = ByteData.sublistView(dex);
    int u16(int o) => b.getUint16(o, Endian.little);
    int u32(int o) => b.getUint32(o, Endian.little);
    var p = 0;
    int uleb() {
      var v = 0, shift = 0;
      while (true) {
        final x = dex[p++];
        v |= (x & 0x7f) << shift;
        if (x & 0x80 == 0) break;
        shift += 7;
      }
      return v;
    }

    final strings = <String>[];
    final nStr = u32(0x38), offStr = u32(0x3c);
    for (var i = 0; i < nStr; i++) {
      p = u32(offStr + i * 4);
      uleb(); // utf16 length
      var e = p;
      while (e < dex.length && dex[e] != 0) {
        e++;
      }
      // MUTF-8 is UTF-8 for everything that matters here
      strings.add(utf8.decode(dex.sublist(p, e), allowMalformed: true));
    }
    String s(int i) => i >= 0 && i < strings.length ? strings[i] : '';

    final types = <String>[];
    final nType = u32(0x40), offType = u32(0x44);
    for (var i = 0; i < nType; i++) {
      types.add(s(u32(offType + i * 4)));
    }
    String t(int i) => i >= 0 && i < types.length ? types[i] : '';

    final protos = <(String, List<String>)>[];
    final nProto = u32(0x48), offProto = u32(0x4c);
    for (var i = 0; i < nProto; i++) {
      final o = offProto + i * 12;
      final ret = t(u32(o + 4));
      final params = <String>[];
      final po = u32(o + 8);
      if (po != 0) {
        final n = u32(po);
        for (var j = 0; j < n; j++) {
          params.add(t(u16(po + 4 + j * 2)));
        }
      }
      protos.add((ret, params));
    }

    final fieldIds = <(String, String)>[]; // type, name
    final nField = u32(0x50), offField = u32(0x54);
    for (var i = 0; i < nField; i++) {
      final o = offField + i * 8;
      fieldIds.add((t(u16(o + 2)), s(u32(o + 4))));
    }

    final methodIds = <(int, String)>[]; // proto, name
    final nMethod = u32(0x58), offMethod = u32(0x5c);
    for (var i = 0; i < nMethod; i++) {
      final o = offMethod + i * 8;
      methodIds.add((u16(o + 2), s(u32(o + 4))));
    }

    final out = <DexClass>[];
    final nClass = u32(0x60), offClass = u32(0x64);
    for (var i = 0; i < nClass && out.length < maxClasses; i++) {
      final o = offClass + i * 32;
      final name = javaType(t(u32(o)));
      if (packagePrefix != null && !name.startsWith(packagePrefix)) continue;
      final flags = u32(o + 4);
      final sup = u32(o + 8);
      final ifOff = u32(o + 12);
      final src = u32(o + 16);
      final dataOff = u32(o + 24);
      final ifaces = <String>[];
      if (ifOff != 0) {
        final n = u32(ifOff);
        for (var j = 0; j < n; j++) {
          ifaces.add(javaType(t(u16(ifOff + 4 + j * 2))));
        }
      }
      final supName = sup == 0xffffffff ? null : javaType(t(sup));
      if (keep != null && !keep(name, supName, ifaces)) continue;
      final fields = <String>[];
      final methods = <String>[];
      if (dataOff != 0) {
        p = dataOff;
        final sf = uleb(), inf = uleb(), dm = uleb(), vm = uleb();
        var last = 0;
        for (var k = 0; k < sf + inf; k++) {
          if (k == sf) last = 0; // instance fields restart the index diff
          last += uleb();
          final fl = uleb();
          if (last < fieldIds.length) {
            fields.add('${modifiers(fl)} ${javaType(fieldIds[last].$1)} ${fieldIds[last].$2}'.trim());
          }
        }
        last = 0;
        for (var k = 0; k < dm + vm; k++) {
          if (k == dm) last = 0; // virtual methods restart the index diff
          last += uleb();
          final fl = uleb();
          uleb(); // code_off (bodies are not decoded)
          if (last < methodIds.length) {
            final (pi, mName) = methodIds[last];
            final (ret, params) = pi < protos.length ? protos[pi] : ('V', const <String>[]);
            final args = params.map(javaType).join(', ');
            final simple = name.substring(name.lastIndexOf('.') + 1).split(r'$').last;
            final sig = mName == '<init>'
                ? '$simple($args)'
                : mName == '<clinit>'
                    ? 'static {}'
                    : '${javaType(ret)} $mName($args)';
            methods.add('${mName == '<clinit>' ? '' : modifiers(fl & ~0x10000)} $sig'.trim());
          }
        }
      }
      out.add(DexClass(name, flags, sup == 0xffffffff ? null : javaType(t(sup)), ifaces,
          src == 0xffffffff ? null : s(src), fields, methods));
    }
    return out;
  }
}
