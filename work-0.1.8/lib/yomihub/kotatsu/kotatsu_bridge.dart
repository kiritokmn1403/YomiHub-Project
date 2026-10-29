import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path_provider/path_provider.dart';

/// One parser exposed by the Kotatsu bridge (built-in Kotatsu-Redo or a fork).
class KotatsuSource {
  final String id;
  final String title;
  final String lang;
  final String type;
  final String repo;
  final bool broken;
  KotatsuSource(this.id, this.title, this.lang, this.type, this.repo, this.broken);
  factory KotatsuSource.fromJson(Map m) => KotatsuSource(
    '${m['id']}',
    '${m['title'] ?? m['name']}',
    '${m['lang'] ?? ''}',
    '${m['type'] ?? 'MANGA'}',
    '${m['repo'] ?? ''}',
    m['broken'] == true,
  );
  bool get nsfw => type == 'HENTAI';
  bool get readable => type != 'NOVEL';
}

/// YomiHub 0.1.4: Kotatsu Multi Parsers integration (Android only).
///
/// The parsers run inside the app (see `YomiKotatsu.kt`) behind a loopback
/// HTTP API; each enabled parser is installed as a small JavaScript source
/// (`assets/yomihub_extensions/kotatsu.js`) so it appears in Browse like any
/// other extension and works with library, history, downloads and trackers.
class KotatsuBridge {
  KotatsuBridge._();
  static const _ch = MethodChannel('yomihub/kotatsu');
  static const port = 47350;
  static const _host = 'http://127.0.0.1:$port/kotatsu';
  static const _forksKey = 'kotatsuForks';
  static bool _started = false;

  static bool get supported => Platform.isAndroid;

  /// Stable Isar id for a Kotatsu parser (93xxxxxxxxxx range).
  static int sourceId(String key) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode('kotatsu:$key')) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return 930000000000 + h;
  }

  static bool isKotatsuSource(Source s) =>
      (s.id ?? 0) >= 930000000000 && (s.id ?? 0) < 930000000000 + 0x100000000;

  static Future<bool> start() async {
    if (!supported) return false;
    if (_started) return true;
    try {
      final port = await _ch.invokeMethod<int>('start');
      _started = (port ?? 0) > 0;
      if (_started) await _reloadForks();
    } catch (_) {
      _started = false;
    }
    return _started;
  }

  /// Called at startup: only spins the bridge up when a Kotatsu source is installed.
  static Future<void> startIfNeeded() async {
    if (!supported) return;
    try {
      if (sourceRepository.getAll().any(isKotatsuSource)) await start();
    } catch (_) {}
  }

  static Future<dynamic> _get(String path, [Map<String, String>? q]) async {
    final uri = Uri.parse('$_host/$path').replace(queryParameters: q);
    final r = await http.get(uri).timeout(const Duration(seconds: 60));
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<List<KotatsuSource>> sources() async {
    if (!await start()) return [];
    final j = await _get('sources');
    return [for (final m in (j as List)) KotatsuSource.fromJson(m as Map)]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  static bool isInstalled(KotatsuSource s) {
    final src = sourceRepository.getById(sourceId(s.id));
    return src != null && (src.isAdded ?? false);
  }

  static ItemType _itemType(KotatsuSource s) => ItemType.manga;

  static Future<void> install(KotatsuSource s) async {
    if (!await start()) throw Exception('Kotatsu chỉ chạy trên Android');
    Map filters = {};
    try {
      filters = await _get('filters', {'source': s.id}) as Map;
    } catch (_) {}
    final tpl = await rootBundle.loadString('assets/yomihub_extensions/kotatsu.js');
    final code =
        'const KT_ID = ${jsonEncode(s.id)};\nconst KT_FILTERS = ${jsonEncode(filters)};\n$tpl';
    final id = sourceId(s.id);
    final existing = sourceRepository.getById(id);
    final src = existing ??
        (Source(
          id: id,
          name: '${s.title} (Kotatsu)',
          lang: s.lang.isEmpty ? 'all' : s.lang,
          baseUrl: 'http://127.0.0.1:$port',
          iconUrl: '',
          typeSource: 'single',
          itemType: _itemType(s),
          isAdded: true,
          isActive: true,
          isNsfw: s.nsfw,
          version: '0.1.4',
        )..sourceCodeLanguage = SourceCodeLanguage.javascript);
    src
      ..sourceCode = code
      ..isAdded = true
      ..isActive = true
      ..isLocal = true
      ..version = '0.1.4'
      ..versionLast = '0.1.4'
      ..notes = 'Kotatsu Multi Parsers • ${s.repo}${s.broken ? ' • có thể đang lỗi' : ''}'
      ..sourceCodeLanguage = SourceCodeLanguage.javascript;
    await sourceRepository.save(src);
  }

  static Future<void> uninstall(KotatsuSource s) async {
    final src = sourceRepository.getById(sourceId(s.id));
    if (src == null) return;
    src.isAdded = false;
    await sourceRepository.save(src);
  }

  // ───────────── forks ─────────────

  static List<Map<String, dynamic>> forks() => [
    for (final f in YomiPrefs.get<List>(_forksKey, const []))
      Map<String, dynamic>.from(f as Map),
  ];

  /// Downloads a kotatsu-parsers fork (a d8-processed .jar) and loads it.
  /// Returns the number of parsers added.
  static Future<int> addFork(String name, String url) async {
    if (!await start()) throw Exception('Kotatsu chỉ chạy trên Android');
    name = name.trim().replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    if (name.isEmpty) name = 'fork${forks().length + 1}';
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/kotatsu_forks');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$name.jar');
    if (await file.exists()) {
      await file.delete();
    }
    final r = await http.get(Uri.parse(url.trim()));
    if (r.statusCode != 200 || r.bodyBytes.length < 1000) {
      throw Exception('Tải thất bại (HTTP ${r.statusCode})');
    }
    await file.writeAsBytes(r.bodyBytes);
    final n = await _load(name, file.path);
    final list = forks()..removeWhere((f) => f['name'] == name);
    list.add({'name': name, 'url': url.trim(), 'path': file.path});
    await YomiPrefs.set(_forksKey, list);
    return n;
  }

  static Future<void> removeFork(String name) async {
    final list = forks();
    final f = list.where((e) => e['name'] == name).firstOrNull;
    list.removeWhere((e) => e['name'] == name);
    await YomiPrefs.set(_forksKey, list);
    if (f != null) {
      try {
        await File('${f['path']}').delete();
      } catch (_) {}
    }
  }

  static Future<int> _load(String name, String path) async {
    final res = await _ch.invokeMethod<String>('loadFork', {'name': name, 'path': path}) ?? '';
    if (res.startsWith('ok:')) return int.tryParse(res.substring(3)) ?? 0;
    throw Exception(res.replaceFirst('error:', ''));
  }

  static Future<void> _reloadForks() async {
    for (final f in forks()) {
      try {
        if (await File('${f['path']}').exists()) await _load('${f['name']}', '${f['path']}');
      } catch (_) {}
    }
  }
}
