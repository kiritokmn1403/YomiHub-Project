import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.4.4 – Booru App settings, favourites and search history.
///
/// Kept in the Hive box `yomihub_booru`, which is listed in
/// [YomiBackupExtras.boxes]: backup / restore / cloud sync of the app carry
/// the Booru App data too (the sheet asks for shared backup settings).
/// API keys are "sensitive" and only exported when the user ticks
/// "include sensitive settings".
class BooruStore extends ChangeNotifier {
  BooruStore._();
  static final BooruStore instance = BooruStore._();

  static const boxName = 'yomihub_booru';
  static const route = '/booru';
  static const maxFavourites = 3000;
  static const maxHistory = 60;

  Box? _box;
  bool get ready => _box != null;

  Future<void> init() async {
    if (_box != null) return;
    try {
      _box = Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await YomiHive.open(boxName);
      notifyListeners();
    } catch (e) {
      AppLogger.log('[Booru App] Không mở được dữ liệu Booru: $e', logLevel: LogLevel.error);
    }
  }

  T _get<T>(String k, T def) {
    final v = _box?.get(k);
    return v is T ? v : def;
  }

  Future<void> _put(String k, Object? v) async {
    try {
      if (v == null) {
        await _box?.delete(k);
      } else {
        await _box?.put(k, v);
      }
    } catch (e) {
      AppLogger.log('[Booru App] Không lưu được cài đặt "$k": $e', logLevel: LogLevel.error);
    }
    notifyListeners();
  }

  // ── sites ──
  List<BooruSite> get customSites => [
        for (final m in _get<List>('customSites', const []))
          if (m is Map) BooruSite.fromJson(m),
      ].nonNulls.toList();

  List<BooruSite> get allSites => [...BooruSite.builtIn, ...customSites];

  List<BooruSite> visibleSites(bool showNsfw) =>
      allSites.where((s) => showNsfw || !s.nsfwOnly).toList();

  Future<void> addSite(BooruSite s) async {
    final list = customSites.where((e) => e.id != s.id).map((e) => e.toJson()).toList()..add(s.toJson());
    await _put('customSites', list);
  }

  Future<void> removeSite(String id) async {
    await _put('customSites', customSites.where((e) => e.id != id).map((e) => e.toJson()).toList());
    if (activeSiteId == id) await setActiveSite(BooruSite.builtIn.first.id);
  }

  String get activeSiteId => _get<String>('activeSite', BooruSite.builtIn.first.id);
  Future<void> setActiveSite(String id) => _put('activeSite', id);

  BooruSite site(bool showNsfw) {
    final list = visibleSites(showNsfw);
    return list.where((s) => s.id == activeSiteId).firstOrNull ?? list.first;
  }

  BooruSite? siteById(String id) => allSites.where((s) => s.id == id).firstOrNull;

  // ── credentials (sensitive) ──
  String login(String siteId) => '${(_get<Map>('creds', const {})[siteId] as Map?)?['login'] ?? ''}';
  String apiKey(String siteId) => '${(_get<Map>('creds', const {})[siteId] as Map?)?['key'] ?? ''}';
  Future<void> setCreds(String siteId, String login, String key) async {
    final m = Map<String, dynamic>.from(_get<Map>('creds', const {}));
    if (login.trim().isEmpty && key.trim().isEmpty) {
      m.remove(siteId);
    } else {
      m[siteId] = {'login': login.trim(), 'key': key.trim()};
    }
    await _put('creds', m);
  }

  // ── viewing ──
  int get columns => _get<int>('columns', 3);
  Future<void> setColumns(int v) => _put('columns', v.clamp(2, 6));

  /// true = open the original file in the viewer, false = the sample.
  bool get fullQuality => _get<bool>('fullQuality', false);
  Future<void> setFullQuality(bool v) => _put('fullQuality', v);

  bool get autoplayVideo => _get<bool>('autoplayVideo', true);
  Future<void> setAutoplayVideo(bool v) => _put('autoplayVideo', v);

  Set<String> get blacklist => {
        for (final t in _get<List>('blacklist', const ['guro', 'scat', 'gore'])) '$t'.trim().toLowerCase(),
      }..removeWhere((e) => e.isEmpty);
  Future<void> setBlacklist(Iterable<String> tags) =>
      _put('blacklist', tags.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet().toList());

  // ── favourites ──
  List<BooruPost> get favourites => [
        for (final m in _get<List>('favourites', const []))
          if (m is Map) BooruPost.fromJson(m),
      ];

  bool isFavourite(BooruPost post) => _get<List>('favourites', const [])
      .any((m) => m is Map && m['id'] == post.id && m['siteId'] == post.siteId);

  Future<void> toggleFavourite(BooruPost post) async {
    final list = List<dynamic>.from(_get<List>('favourites', const []));
    final i = list.indexWhere((m) => m is Map && m['id'] == post.id && m['siteId'] == post.siteId);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.insert(0, post.toJson());
      if (list.length > maxFavourites) list.removeRange(maxFavourites, list.length);
    }
    await _put('favourites', list);
  }

  // ── search history ──
  List<String> get history => [for (final h in _get<List>('history', const [])) '$h'];
  Future<void> addHistory(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    final list = history..remove(q)..insert(0, q);
    await _put('history', list.take(maxHistory).toList());
  }

  Future<void> clearHistory() => _put('history', <String>[]);

  // ── downloads ──
  Future<Directory?> downloadDir(BooruSite s) async {
    final base = await StorageProvider().getDirectory();
    if (base == null) return null;
    final d = Directory(p.join(base.path, 'Booru', s.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Saves the original file; returns its path. Errors go to the app log.
  Future<String?> download(BooruPost post, http.Client client) async {
    final s = siteById(post.siteId);
    if (s == null) return null;
    try {
      final dir = await downloadDir(s);
      if (dir == null) throw 'không có thư mục lưu';
      final ext = post.ext.isEmpty ? 'jpg' : post.ext;
      final f = File(p.join(dir.path, '${s.id}_${post.id}.$ext'));
      if (await f.exists() && await f.length() > 0) return f.path;
      final res = await client.get(Uri.parse(post.fileUrl), headers: {
        'User-Agent': 'YomiHub/0.4.4 (Booru App)',
        'Referer': '${s.baseUrl}/',
      }).timeout(const Duration(minutes: 3));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) throw 'HTTP ${res.statusCode}';
      await f.writeAsBytes(res.bodyBytes, flush: true);
      await _put('downloads', _get<int>('downloads', 0) + 1);
      return f.path;
    } catch (e) {
      AppLogger.log('[Booru App] [Tải xuống] Không tải được bài #${post.id} (${s.name}): $e', logLevel: LogLevel.error);
      return null;
    }
  }

  int get downloads => _get<int>('downloads', 0);
}
