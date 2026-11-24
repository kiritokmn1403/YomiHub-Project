import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';

import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/repositories/source_preference_repository.dart';
import 'package:mangayomi/yomihub/booru/booru_store.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';

/// YomiHub data that rides along in every backup, whatever options were
/// ticked: the Extensions Repo lists (all three item types), the installed
/// extensions and their settings, and YomiHub's own settings boxes (VPN,
/// AdBlock, filters, player, trackers…).
class YomiBackupExtras {
  YomiBackupExtras._();

  static const boxes = [
    'yomihub_prefs',
    'yomihub_vpn',
    'yomihub_browser',
    'yomihub_filters',
    'yomihub_mes',
    'yomihub_pip',
    'yomihub_reader',
    'yomihub_trackers',
    'yomihub_cloudscraper',
    'yomihub_userscripts',
    'yomihub_booru', // 0.4.4: Booru App (favourites, history, settings)
    'yomihub_bookshelf', // 0.6.3: Tủ Sách Cá Nhân (series, volumes, wishlist…)
    'yomihub_browser_history', // 0.6.5: lịch sử trình duyệt web (YomiHub Update mục 14)
  ];

  static const _sensitiveKeys = {
    'warpAccount',
    'proxyPassword',
    'proxyUrl',
    'creds',
    'saucenaoApiKey', // 0.6.5: SauceNAO API key
  };

  // 0.6.5: runtime state of the Tor crash guard must not travel in a backup
  // (restoring torStartPending=true would count a crash that never happened).
  static const _runtimeKeys = {'torStartPending', 'torCrashStrikes'};

  static dynamic _safe(dynamic v) {
    if (v == null || v is num || v is bool || v is String) return v;
    if (v is List) return v.map(_safe).toList();
    if (v is Map) {
      return {for (final e in v.entries) '${e.key}': _safe(e.value)};
    }
    try {
      return jsonDecode(jsonEncode(v));
    } catch (_) {
      return '$v';
    }
  }

  static Future<Map<String, dynamic>> collect({
    required bool hasExtensions,
    required bool hasExtensionPrefs,
    bool includeSensitive = false,
  }) async {
    final s = settingsRepository.currentOrNull;
    final out = <String, dynamic>{
      'version': 1,
      'repos': {
        'manga': (s?.mangaExtensionsRepo ?? []).map((e) => e.toJson()).toList(),
        'anime': (s?.animeExtensionsRepo ?? []).map((e) => e.toJson()).toList(),
        'novel': (s?.novelExtensionsRepo ?? []).map((e) => e.toJson()).toList(),
      },
    };
    if (!hasExtensions) {
      try {
        out['extensions'] = sourceRepository
            .getAll()
            .where((e) => e.isAdded ?? false)
            .map((e) => e.toJson())
            .toList();
      } catch (_) {
        out['extensions'] = [];
      }
    }
    if (!hasExtensionPrefs) {
      try {
        out['extensions_preferences'] = sourcePreferenceRepository
            .getAll()
            .map((e) => e.toJson())
            .toList();
      } catch (_) {
        out['extensions_preferences'] = [];
      }
    }
    final data = <String, dynamic>{};
    for (final name in boxes) {
      // 0.5.3: "Sao lưu dữ liệu Booru App" switch in Sao Lưu & Đồng Bộ
      if (name == 'yomihub_booru' && !YomiPrefs.get<bool>('backupBooru', true)) continue;
      // 0.6.3: "Tủ Sách Cá Nhân" can be left out too (YomiHub Update mục 10: chọn mục sao lưu)
      if (name == 'yomihub_bookshelf' && !YomiPrefs.get<bool>('backupBookshelf', true)) continue;
      // 0.6.5 (YomiHub Update mục 14): browser history and VPN settings have
      // their own switches in Sao Lưu & Khôi Phục.
      if (name == 'yomihub_browser_history' && !YomiPrefs.get<bool>('backupBrowserHistory', true)) continue;
      if (name == 'yomihub_vpn' && !YomiPrefs.get<bool>('backupVpn', true)) continue;
      try {
        final box = Hive.isBoxOpen(name)
            ? Hive.box(name)
            : await YomiHive.open(name);
        // Login tokens / private keys only when the user ticked
        // "include sensitive settings" (same switch as tracker tokens).
        if (!includeSensitive && name == 'yomihub_trackers') continue;
        data[name] = {
          for (final k in box.keys)
            if (!_runtimeKeys.contains('$k') &&
                (includeSensitive || !_sensitiveKeys.contains('$k')))
              '$k': _safe(box.get(k)),
        };
      } catch (_) {}
    }
    out['boxes'] = data;
    return out;
  }

  static String _norm(String? u) {
    var v = (u ?? '').trim().toLowerCase();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  /// Merges the repositories into the current settings and restores the
  /// YomiHub boxes. Extensions and their preferences restore through the
  /// normal "extensions" / "extensions_preferences" keys.
  static Future<void> restore(Map<String, dynamic> extras) async {
    final repos = extras['repos'];
    if (repos is Map) {
      final s = settingsRepository.currentOrNull;
      if (s != null) {
        List<Repo> merge(List<Repo>? current, dynamic incoming) {
          final list = [...?current];
          // 0.6.5: backups made before the move to YomiHub-Project still
          // carry kiritokmn1403/... and /repo/mangayomi/<type>.json - migrate
          // them so a restore never re-adds the old repo next to the new one.
          final known = list
              .map((e) => _norm(BuiltinExtensions.migrateUrl(e.jsonUrl ?? '')))
              .toSet();
          if (incoming is List) {
            for (final j in incoming.whereType<Map>()) {
              final r = Repo.fromJson(Map<String, dynamic>.from(j));
              final nu = BuiltinExtensions.migrateUrl(r.jsonUrl ?? '');
              if (_norm(nu).isEmpty || !known.add(_norm(nu))) {
                continue;
              }
              r.jsonUrl = nu;
              if (r.website != null) {
                r.website = BuiltinExtensions.migrateUrl(r.website!);
              }
              list.add(r);
            }
          }
          return list;
        }

        s.mangaExtensionsRepo = merge(s.mangaExtensionsRepo, repos['manga']);
        s.animeExtensionsRepo = merge(s.animeExtensionsRepo, repos['anime']);
        s.novelExtensionsRepo = merge(s.novelExtensionsRepo, repos['novel']);
        await settingsRepository.save(s);
      }
    }
    final data = extras['boxes'];
    if (data is Map) {
      for (final e in data.entries) {
        final name = '${e.key}';
        if (!boxes.contains(name) || e.value is! Map) continue;
        try {
          final box = Hive.isBoxOpen(name)
              ? Hive.box(name)
              : await YomiHive.open(name);
          for (final kv in (e.value as Map).entries) {
            // Chapter origins are restored with the database's ID mapping.
            if (name == 'yomihub_prefs' && kv.key == 'mergedChapterOrigins') {
              continue;
            }
            if (_runtimeKeys.contains('${kv.key}')) continue;
            await box.put('${kv.key}', kv.value);
          }
          if (name == 'yomihub_booru') {
            BooruStore.instance.onRestored();
          }
          if (name == 'yomihub_bookshelf') {
            BookshelfStore.instance.onRestored();
          }
        } catch (_) {}
      }
    }
  }
}
