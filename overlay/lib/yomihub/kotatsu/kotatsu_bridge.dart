import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mangayomi/yomihub/win/jvm_bridge.dart';
import 'package:mangayomi/services/http/m_client.dart' show yomiSolveCloudflare;

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

  /// 0.2.1: Windows too, through the YomiHub JVM bridge (yomihub_bin\bridge).
  static bool get supported => Platform.isAndroid || Platform.isWindows;

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

  static bool _handler = false;
  static void _installHandler() {
    if (_handler) return;
    _handler = true;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'solveCf') {
        final url = '${(call.arguments as Map?)?['url'] ?? ''}';
        if (url.isEmpty) return {'ok': false};
        try {
          final ua = await yomiSolveCloudflare(url);
          return {'ok': ua != null, 'ua': ua ?? ''};
        } catch (_) {
          return {'ok': false};
        }
      }
      return null;
    });
  }

  static Future<bool> start() async {
    if (!supported) return false;
    if (Platform.isWindows) {
      if (_started && await YomiJvmBridge.kotatsuReady) return true;
      _started = await YomiJvmBridge.ensure();
      return _started;
    }
    _installHandler();
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
      final hasKotatsu = sourceRepository.anyIdBetween(930000000000, 930000000000 + 0x100000000) ||
          sourceRepository.getAll().any((s) =>
              (s.isAdded ?? false) &&
              ((s.baseUrl?.contains('47350') ?? false) ||
                  (s.sourceCode?.contains('kotatsu') ?? false) ||
                  (s.sourceCodeUrl?.contains('kotatsu') ?? false)));
      if (hasKotatsu) await start();
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

  static const _domainsKey = 'kotatsuDomains';

  /// parser id → website ("comick.io"…), cached across launches.
  static Map<String, String> get domains =>
      Map<String, String>.from(YomiPrefs.get<Map>(_domainsKey, const {}));

  static Future<Map<String, String>> refreshDomains() async {
    if (!await start()) return domains;
    try {
      final j = await _get('domains') as Map;
      final m = {for (final e in j.entries) '${e.key}': '${e.value}'};
      if (m.isNotEmpty) await YomiPrefs.set(_domainsKey, m);
      return m;
    } catch (_) {
      return domains;
    }
  }

  static String _baseUrl(String id) {
    final d = domains[id];
    return d == null || d.isEmpty ? 'http://127.0.0.1:$port' : 'https://$d';
  }

  /// YomiHub 0.1.8: Kotatsu Multi Parsers live in Comic › Extensions like
  /// every other extension: each parser is listed there (install / remove
  /// with the usual buttons), opens its real website in WebView and can be
  /// merged with other extensions of the same site.
  static Future<int> syncCatalog() async {
    if (!supported || !await start()) return 0;
    List<KotatsuSource> all;
    try {
      all = await sources();
    } catch (_) {
      return 0;
    }
    final dom = await refreshDomains();
    final rows = <Source>[];
    for (final k in all.where((k) => k.readable)) {
      final id = sourceId(k.id);
      final existing = sourceRepository.getById(id);
      final base = dom[k.id] == null ? 'http://127.0.0.1:$port' : 'https://${dom[k.id]}';
      if (existing != null) {
        if (existing.baseUrl != base && base.startsWith('https')) {
          rows.add(existing..baseUrl = base);
        }
        continue;
      }
      rows.add(
        Source(
          id: id,
          name: '${k.title} (Kotatsu)',
          lang: k.lang.isEmpty ? 'all' : k.lang,
          baseUrl: base,
          iconUrl: dom[k.id] == null ? '' : 'https://www.google.com/s2/favicons?sz=64&domain=${dom[k.id]}',
          typeSource: 'single',
          itemType: ItemType.manga,
          isAdded: false,
          isActive: true,
          isNsfw: k.nsfw,
          version: '0.1.9',
        )
          ..sourceCode = ''
          ..isLocal = false
          ..versionLast = '0.1.9'
          ..notes = 'Kotatsu Multi Parsers • ${k.repo}${k.broken ? ' • có thể đang lỗi' : ''}'
          ..sourceCodeLanguage = SourceCodeLanguage.javascript,
      );
    }
    // 0.2.1: ~1 300 rows in batches instead of one transaction each
    for (var i = 0; i < rows.length; i += 150) {
      await sourceRepository.putAll(rows.sublist(i, i + 150 > rows.length ? rows.length : i + 150));
      await Future<void>.delayed(Duration.zero);
    }
    return rows.length;
  }

  /// At most every 3 days (and after an update of YomiHub).
  static Future<void> syncCatalogIfDue() async {
    if (!supported) return;
    final last = YomiPrefs.get<int>('kotatsuCatalogAt', 0);
    final ver = YomiPrefs.get<String>('kotatsuCatalogVer', '');
    final now = DateTime.now().millisecondsSinceEpoch;
    if (ver == _ver && now - last < 3 * 86400000) return;
    final n = await syncCatalog();
    // YomiHub 0.1.9: installed parsers get the new extension script (full
    // Kotatsu filters, Cloudflare message) and freshly read filter options
    if (ver != _ver) await refreshInstalled();
    if (n >= 0) {
      await YomiPrefs.set('kotatsuCatalogAt', now);
      await YomiPrefs.set('kotatsuCatalogVer', _ver);
    }
  }

  static const _ver = '0.1.9';

  /// Re-installs every installed Kotatsu source with the current script.
  static Future<int> refreshInstalled() async {
    if (!supported || !await start()) return 0;
    var n = 0;
    try {
      final all = await sources();
      for (final k in all) {
        if (!isInstalled(k)) continue;
        try {
          await install(k);
          n++;
        } catch (_) {}
      }
    } catch (_) {}
    return n;
  }

  /// Install from the Comic › Extensions list (row of [syncCatalog]).
  static Future<void> installSource(Source src) async {
    final key = (await sources()).where((k) => sourceId(k.id) == src.id).firstOrNull;
    if (key == null) throw Exception(tr('Không tìm thấy nguồn Kotatsu này'));
    await install(key);
  }

  static Future<void> install(KotatsuSource s) async {
    if (!await start()) {
      throw Exception(Platform.isWindows ? YomiJvmBridge.lastError : tr('Kotatsu chỉ chạy trên Android'));
    }
    Map filters = {};
    try {
      filters = await _get('filters', {'source': s.id}) as Map;
    } catch (_) {}
    final tpl = await rootBundle.loadString('assets/yomihub_extensions/kotatsu.js');
    final code =
        'const KT_ID = ${jsonEncode(s.id)};\nconst KT_LANG = ${jsonEncode(YomiTr.lang)};\nconst KT_FILTERS = ${jsonEncode(filters)};\n$tpl';
    final id = sourceId(s.id);
    final existing = sourceRepository.getById(id);
    final src = existing ??
        (Source(
          id: id,
          name: '${s.title} (Kotatsu)',
          lang: s.lang.isEmpty ? 'all' : s.lang,
          baseUrl: _baseUrl(s.id),
          iconUrl: domains[s.id] == null ? '' : 'https://www.google.com/s2/favicons?sz=64&domain=${domains[s.id]}',
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
      // 0.1.8: not "local" any more: removing it keeps the row in the
      // Comic extension list, ready to be installed again
      ..isLocal = false
      ..baseUrl = _baseUrl(s.id).startsWith('https') ? _baseUrl(s.id) : src.baseUrl
      ..version = _ver
      ..versionLast = _ver
      ..notes = 'Kotatsu Multi Parsers • ${s.repo}${s.broken ? ' • có thể đang lỗi' : ''}'
      ..sourceCodeLanguage = SourceCodeLanguage.javascript;
    await sourceRepository.save(src);
  }

  /// YomiHub 0.2.1: "Đổi URL" of a Kotatsu source sets the parser's own
  /// domain (ConfigKey.Domain) – before, only the WebView URL changed.
  static Future<void> setDomain(Source src, String? url) async {
    if (!supported || !await start()) return;
    final key = (await sources()).where((k) => sourceId(k.id) == src.id).firstOrNull;
    if (key == null) return;
    final host = url == null ? '' : (Uri.tryParse(url)?.host ?? '');
    try {
      await _get('setDomain', {'source': key.id, 'domain': host});
      await refreshDomains();
    } catch (_) {}
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
    if (Platform.isWindows) {
      throw Exception(tr('Kho fork Kotatsu (tệp jar đã chuyển sang dex) chỉ dùng được trên Android; trên Windows có sẵn toàn bộ nguồn Kotatsu-Redo.'));
    }
    if (!await start()) throw Exception(tr('Kotatsu chỉ chạy trên Android'));
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
      throw Exception(tr('Tải thất bại (HTTP {p0})', {'p0': r.statusCode}));
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
