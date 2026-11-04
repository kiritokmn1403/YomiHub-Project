import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:mangayomi/yomihub/apk/axml_decoder.dart';
import 'package:mangayomi/yomihub/apk/dex_reader.dart';

/// What [ApkInspector] found in an APK.
class ApkInfo {
  String package = '';
  String versionName = '';
  String versionCode = '';
  String minSdk = '';
  String targetSdk = '';
  String label = '';
  final Map<String, String> metaData = {};
  final List<String> permissions = [];
  String kind = 'Ứng dụng Android';
  List<String> extensionClasses = [];
  bool? nsfw;
  String? libVersion;
  int dexFiles = 0;
  int classCount = 0;
  List<DexClass> sourceClasses = [];
  String manifestXml = '';
  final List<String> warnings = [];
}

/// YomiHub 0.5.1: reads an extension APK without installing it – package,
/// version, `<meta-data>` (Mihon / Tachiyomi `tachiyomi.extension.*`,
/// Aniyomi `tachiyomi.animeextension.*`, IReader `source.*`) and the classes
/// that implement a source. Built on [AxmlDecoder] and [DexReader] (ports of
/// the "Decode & Extract" scripts of the project owner).
class ApkInspector {
  ApkInspector._();

  static const _sourceMarkers = [
    'eu.kanade.tachiyomi.source.Source',
    'eu.kanade.tachiyomi.source.SourceFactory',
    'eu.kanade.tachiyomi.source.online.HttpSource',
    'eu.kanade.tachiyomi.source.online.ParsedHttpSource',
    'eu.kanade.tachiyomi.animesource.AnimeSource',
    'eu.kanade.tachiyomi.animesource.AnimeSourceFactory',
    'eu.kanade.tachiyomi.animesource.online.AnimeHttpSource',
    'eu.kanade.tachiyomi.animesource.online.ParsedAnimeHttpSource',
    'ireader.core.source.Source',
    'ireader.core.source.HttpSource',
    'ireader.core.source.SourceFactory',
  ];

  static ApkInfo inspect(Uint8List apk) => _inspect(ZipDecoder().decodeBytes(apk));

  /// 0.5.1 (Note 9, 86.7 MB APK: the screen waited for minutes): reads the
  /// APK as a stream from [path] – the whole file is never copied into
  /// memory or between isolates.
  static ApkInfo inspectFile(String path) {
    final input = InputFileStream(path);
    try {
      return _inspect(ZipDecoder().decodeStream(input));
    } finally {
      input.closeSync();
    }
  }

  static ApkInfo _inspect(Archive zip) {
    final info = ApkInfo();
    final manifest = zip.findFile('AndroidManifest.xml');
    if (manifest == null) throw const FormatException('Tệp không có AndroidManifest.xml – không phải APK');
    final doc = AxmlDecoder.decode(Uint8List.fromList(manifest.content as List<int>));
    info.manifestXml = doc.xml;
    final root = doc.root;
    if (root != null) {
      info.package = root.attr('package') ?? '';
      info.versionName = root.attr('versionName') ?? '';
      info.versionCode = root.attr('versionCode') ?? '';
      for (final u in root.descendants('uses-sdk')) {
        info.minSdk = u.attr('minSdkVersion') ?? info.minSdk;
        info.targetSdk = u.attr('targetSdkVersion') ?? info.targetSdk;
      }
      for (final pm in root.descendants('uses-permission')) {
        final n = pm.attr('name');
        if (n != null) info.permissions.add(n);
      }
      for (final app in root.descendants('application')) {
        info.label = app.attr('label') ?? '';
      }
      for (final md in root.descendants('meta-data')) {
        final n = md.attr('name');
        if (n != null) info.metaData[n] = md.attr('value') ?? md.attr('resource') ?? '';
      }
    }
    final m = info.metaData;
    String? cls;
    if (m.containsKey('tachiyomi.animeextension.class')) {
      info.kind = 'Tiện ích Aniyomi (Phim & Điện ảnh)';
      cls = m['tachiyomi.animeextension.class'];
      info.nsfw = _flag(m['tachiyomi.animeextension.nsfw']);
    } else if (m.containsKey('tachiyomi.extension.class')) {
      info.kind = 'Tiện ích Mihon / Tachiyomi (Truyện tranh)';
      cls = m['tachiyomi.extension.class'];
      info.nsfw = _flag(m['tachiyomi.extension.nsfw']);
    } else if (m.keys.any((k) => k.startsWith('source.') || k.contains('ireader'))) {
      info.kind = 'Tiện ích IReader (Tiểu thuyết)';
      cls = m['source.class'] ?? m['ireader.source.class'];
      info.nsfw = _flag(m['source.nsfw']);
    }
    // "class" lists may be relative (".MangaDex") and ';'-separated
    if (cls != null && cls.isNotEmpty) {
      info.extensionClasses = cls
          .split(';')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .map((c) => c.startsWith('.') ? '${info.package}$c' : c)
          .toList();
    }
    final libKey = info.package.contains('animeextension') ? 'tachiyomi.animeextension' : 'tachiyomi.extension';
    if (info.versionName.isNotEmpty && m.containsKey('$libKey.class')) {
      // Mihon: versionName "1.4.12" = lib version "1.4" + extension version 12
      final parts = info.versionName.split('.');
      if (parts.length >= 3) info.libVersion = '${parts[0]}.${parts[1]}';
    }

    // classes*.dex – entry classes and every class that extends a source type
    final dexes = zip.files.where((f) => RegExp(r'^classes\d*\.dex$').hasMatch(f.name)).toList();
    info.dexFiles = dexes.length;
    final wanted = {...info.extensionClasses};
    for (final f in dexes) {
      try {
        final dex = Uint8List.fromList(f.content as List<int>);
        info.classCount += DexReader.classCount(dex);
        // members are decoded only for source candidates (a full app has
        // tens of thousands of classes)
        final classes = DexReader.read(dex,
            keep: (name, sup, ifaces) =>
                wanted.contains(name) || _sourceMarkers.contains(sup) || ifaces.any(_sourceMarkers.contains));
        for (final c in classes) {
          if (info.sourceClasses.length < 300) info.sourceClasses.add(c);
        }
      } catch (e) {
        info.warnings.add('${f.name}: $e');
      }
    }
    for (final c in info.extensionClasses) {
      if (!info.sourceClasses.any((s) => s.name == c)) {
        info.warnings.add('Không thấy lớp $c trong classes*.dex');
      }
    }
    return info;
  }

  static bool? _flag(String? v) => v == null ? null : (v == '1' || v.toLowerCase() == 'true');
}
