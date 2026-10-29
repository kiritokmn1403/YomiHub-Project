import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/net/gh_mirror.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mangayomi/yomihub/win/jvm_bridge.dart';

/// YomiHub 0.1.9: IReader extensions (IReaderorg/IReader-extensions).
///
/// The APK is downloaded into the app's files, loaded by `YomiIReader.kt`
/// (IReader's source-api is compiled into YomiHub) and every catalog source
/// in it becomes a small JavaScript novel extension
/// (`assets/yomihub_extensions/ireader.js`) talking to the loopback bridge on
/// port 47360, so it behaves like any other Novel extension.
class IReaderBridge {
  IReaderBridge._();
  static const _ch = MethodChannel('yomihub/ireader');
  static const port = 47360;
  static const marker = 'ireader:';
  static bool _started = false;

  /// 0.2.1: Windows too – IReader's desktop extension jars run in the
  /// YomiHub JVM bridge (yomihub_bin\bridge).
  static bool get supported => Platform.isAndroid || Platform.isWindows;

  static String get _ext => Platform.isWindows ? '.jar' : '.apk';

  /// Windows uses the desktop build published next to each APK
  /// (`.../apk/x.apk` → `.../jar/x.jar`).
  static String _platformUrl(String apkUrl) => Platform.isWindows
      ? apkUrl.replaceFirst('/apk/', '/jar/').replaceFirst(RegExp(r'\.apk$'), '.jar')
      : apkUrl;

  /// A row created from an IReader repository index (not installed yet, or
  /// installed: then its sourceCode is the generated script).
  static bool isIReaderSource(Source s) =>
      (s.additionalParams ?? '').startsWith(marker);

  /// `ireader:<pkg>|<apk url>|<source id>`
  static (String pkg, String apk, String id) _parse(Source s) {
    final p = (s.additionalParams ?? '').substring(marker.length).split('|');
    return (p[0], p.length > 1 ? p[1] : '', p.length > 2 ? p[2] : '');
  }

  static String paramsFor(String pkg, String apkUrl, String id) => '$marker$pkg|$apkUrl|$id';

  static Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/ireader_ext');
    await d.create(recursive: true);
    return d;
  }

  static Future<bool> start() async {
    if (!supported) return false;
    if (_started) return true;
    if (Platform.isWindows) {
      _started = await YomiJvmBridge.ensure() && await YomiJvmBridge.ireaderReady;
      if (_started) await _loadAll();
      return _started;
    }
    try {
      final p = await _ch.invokeMethod<int>('start');
      _started = (p ?? 0) > 0;
    } catch (_) {
      _started = false;
    }
    if (_started) await _loadAll();
    return _started;
  }

  /// At launch: only when an IReader extension is installed.
  static Future<void> startIfNeeded() async {
    if (!supported) return;
    try {
      if (sourceRepository.anyInstalledWithParamsPrefix(marker)) {
        await start();
      }
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> _load(String path) async {
    if (Platform.isWindows) return YomiJvmBridge.loadIReaderJar(path);
    final res = await _ch.invokeMethod<String>('load', {'path': path}) ?? '';
    if (!res.startsWith('ok:')) throw Exception(res.replaceFirst('error:', ''));
    return [
      for (final e in jsonDecode(res.substring(3)) as List) Map<String, dynamic>.from(e as Map),
    ];
  }

  static Future<void> _loadAll() async {
    final d = await _dir();
    for (final f in d.listSync().whereType<File>().where((f) => f.path.endsWith(_ext))) {
      try {
        await _load(f.path);
      } catch (e) {
        AppLogger.logOnce('ireader-load:${f.path}', 'IReader: cannot load ${f.path}: $e');
      }
    }
  }

  /// Installs (or updates) the IReader extension of row [src].
  static Future<void> installSource(Source src) async {
    if (!supported) throw Exception(tr('Tiện ích IReader chỉ chạy trên Android'));
    if (!await start()) {
      throw Exception(Platform.isWindows
          ? (YomiJvmBridge.lastError.isNotEmpty ? YomiJvmBridge.lastError : tr('Không khởi động được cầu nối IReader'))
          : tr('Không khởi động được cầu nối IReader (cần Android 8.0 trở lên)'));
    }
    final (pkg, apkUrl, wantedId) = _parse(src);
    final d = await _dir();
    final file = File('${d.path}/$pkg$_ext');
    final r = await GhMirror.get(http.Client(), Uri.parse(_platformUrl(apkUrl)), timeout: const Duration(seconds: 90));
    if (r.statusCode != 200 || r.bodyBytes.length < 1000) {
      throw Exception(tr('Tải thất bại (HTTP {p0})', {'p0': r.statusCode}));
    }
    if (await file.exists()) {
      try {
        await file.setLastModified(DateTime.now());
        await file.delete();
      } catch (_) {}
    }
    await file.writeAsBytes(r.bodyBytes, flush: true);
    final list = await _load(file.path);
    final tpl = await rootBundle.loadString('assets/yomihub_extensions/ireader.js');
    for (final s in list) {
      final id = '${s['id']}';
      var filters = '[]';
      try {
        final r = await http
            .get(Uri.parse('http://127.0.0.1:$port/ireader/filters?source=$id'))
            .timeout(const Duration(seconds: 20));
        if (r.statusCode == 200 && r.body.trim().startsWith('[')) filters = r.body;
      } catch (_) {}
      // the row the user tapped, and any other source of the same APK
      final row = id == wantedId || list.length == 1
          ? src
          : (sourceRepository.getById(_rowId(id)) ?? _newRow(src, s, pkg, apkUrl));
      row
        ..sourceCode = 'const IR_ID = ${jsonEncode(id)};\nconst IR_FILTERS = $filters;\n$tpl'
        ..isAdded = true
        ..isActive = true
        ..baseUrl = ('${s['baseUrl'] ?? ''}').isNotEmpty ? '${s['baseUrl']}' : row.baseUrl
        ..version = row.versionLast ?? row.version
        ..additionalParams = paramsFor(pkg, apkUrl, id)
        ..sourceCodeLanguage = SourceCodeLanguage.javascript
        ..itemType = ItemType.novel
        ..updatedAt = DateTime.now().millisecondsSinceEpoch;
      await sourceRepository.save(row);
    }
  }

  static int _rowId(String irId) => 'ireader-$irId'.hashCode;

  static Source _newRow(Source like, Map<String, dynamic> s, String pkg, String apkUrl) => Source()
    ..id = _rowId('${s['id']}')
    ..name = '${s['name']}'
    ..lang = '${s['lang'] ?? like.lang}'
    ..iconUrl = like.iconUrl
    ..isNsfw = like.isNsfw
    ..version = like.version
    ..versionLast = like.versionLast
    ..notes = like.notes
    ..repo = like.repo
    ..typeSource = 'single'
    ..isLocal = false
    ..isObsolete = false;

  /// Builds the Source row for one entry of an IReader repository index.
  static Source fromIndex(Map<String, dynamic> e, String repoBaseUrl) {
    final pkg = '${e['pkg']}';
    final apkUrl = '$repoBaseUrl/apk/${e['apk']}';
    final id = '${e['id'] ?? ''}';
    final icon = '$repoBaseUrl/icon/${(e['apk'] as String).replaceAll('.apk', '.png')}';
    return Source()
      ..id = _rowId(id.isEmpty ? pkg : id)
      ..name = '${e['name']}'
      ..lang = '${e['lang'] ?? 'en'}'
      ..baseUrl = ''
      ..apiUrl = ''
      ..appMinVerReq = ''
      ..dateFormat = ''
      ..dateFormatLocale = ''
      ..hasCloudflare = false
      ..headers = ''
      ..isActive = true
      ..isAdded = false
      ..isFullData = false
      ..isNsfw = e['nsfw'] == true || e['nsfw'] == 1
      ..isPinned = false
      ..lastUsed = false
      ..sourceCode = ''
      ..sourceCodeUrl = apkUrl
      ..typeSource = 'single'
      ..version = '${e['version'] ?? '1.0'}'
      ..versionLast = '${e['version'] ?? '1.0'}'
      ..isObsolete = false
      ..isLocal = false
      ..iconUrl = icon
      ..additionalParams = paramsFor(pkg, apkUrl, id)
      ..notes = 'IReader • ${e['description'] ?? ''}'
      ..sourceCodeLanguage = SourceCodeLanguage.javascript
      ..itemType = ItemType.novel;
  }
}
