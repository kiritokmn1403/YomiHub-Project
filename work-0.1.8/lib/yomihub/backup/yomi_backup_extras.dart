import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/repositories/source_preference_repository.dart';

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
  ];

  static const _sensitiveKeys = {'warpAccount', 'proxyPassword', 'proxyUrl'};

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
    final s = settingsRepository.current;
    final out = <String, dynamic>{
      'version': 1,
      'repos': {
        'manga': (s.mangaExtensionsRepo ?? []).map((e) => e.toJson()).toList(),
        'anime': (s.animeExtensionsRepo ?? []).map((e) => e.toJson()).toList(),
        'novel': (s.novelExtensionsRepo ?? []).map((e) => e.toJson()).toList(),
      },
    };
    if (!hasExtensions) {
      out['extensions'] = sourceRepository
          .getAll()
          .where((e) => e.isAdded ?? false)
          .map((e) => e.toJson())
          .toList();
    }
    if (!hasExtensionPrefs) {
      out['extensions_preferences'] = sourcePreferenceRepository
          .getAll()
          .map((e) => e.toJson())
          .toList();
    }
    final data = <String, dynamic>{};
    for (final name in boxes) {
      try {
        final box = Hive.isBoxOpen(name)
            ? Hive.box(name)
            : await Hive.openBox(name);
        // Login tokens / private keys only when the user ticked
        // "include sensitive settings" (same switch as tracker tokens).
        if (!includeSensitive && name == 'yomihub_trackers') continue;
        data[name] = {
          for (final k in box.keys)
            if (includeSensitive || !_sensitiveKeys.contains('$k'))
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
      final s = settingsRepository.current;
      List<Repo> merge(List<Repo>? current, dynamic incoming) {
        final list = [...?current];
        final known = list.map((e) => _norm(e.jsonUrl)).toSet();
        if (incoming is List) {
          for (final j in incoming.whereType<Map>()) {
            final r = Repo.fromJson(Map<String, dynamic>.from(j));
            if (_norm(r.jsonUrl).isEmpty || !known.add(_norm(r.jsonUrl))) {
              continue;
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
    final data = extras['boxes'];
    if (data is Map) {
      for (final e in data.entries) {
        final name = '${e.key}';
        if (!boxes.contains(name) || e.value is! Map) continue;
        try {
          final box = Hive.isBoxOpen(name)
              ? Hive.box(name)
              : await Hive.openBox(name);
          for (final kv in (e.value as Map).entries) {
            await box.put('${kv.key}', kv.value);
          }
        } catch (_) {}
      }
    }
  }
}
