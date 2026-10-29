import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Small key/value store for YomiHub settings that don't belong in Isar
/// (adding Isar fields needs code generation and a schema migration).
///
/// Every key here is included in backups (see `YomiBackupExtras`).
class YomiPrefs {
  YomiPrefs._();
  static const boxName = 'yomihub_prefs';
  static Box? _box;
  static final changes = ValueNotifier<int>(0);

  static bool get isOpen => _box != null;

  /// Completes once Hive is initialised and the prefs box is open (0.1.8:
  /// boxes opened from early start-up callbacks wait for it).
  static final _ready = Completer<void>();
  static Future<void> get ready => _ready.future;

  static Future<void> open() async {
    if (_box != null) return;
    try {
      _box = await YomiHive.open(boxName);
    } catch (_) {}
    if (!_ready.isCompleted) _ready.complete();
  }

  static T get<T>(String key, T def) {
    final v = _box?.get(key);
    return v is T ? v : def;
  }

  static Future<void> set(String key, Object? value) async {
    if (value == null) {
      await _box?.delete(key);
    } else {
      await _box?.put(key, value);
    }
    changes.value++;
  }

  static Map<String, dynamic> dump() =>
      {for (final k in _box?.keys ?? const []) '$k': _box!.get(k)};

  static Future<void> restore(Map<String, dynamic> data) async {
    for (final e in data.entries) {
      await _box?.put(e.key, e.value);
    }
    changes.value++;
  }

  /// Only an explicit user choice disables automatic local indexing.
  static bool get downloadIndexing => get('downloadIndexing', true);

  // ───────── Novel reader ─────────
  /// Continuous mode: the next chapters are appended below the current one.
  static bool get novelInfiniteScroll => get('novelInfiniteScroll', true);
  static set novelInfiniteScroll(bool v) => set('novelInfiniteScroll', v);

  /// Go to the next chapter at the end of a chapter (overscroll, last page,
  /// auto-scroll reaching the end).
  static bool get novelAutoNextChapter => get('novelAutoNextChapter', true);
  static set novelAutoNextChapter(bool v) => set('novelAutoNextChapter', v);

  // ───────── Film & Movie player ─────────
  /// Switch to the next server when the current one fails or stalls.
  static bool get autoServerSwitch => get('autoServerSwitch', true);
  static set autoServerSwitch(bool v) => set('autoServerSwitch', v);

  /// Seconds of buffering without progress before switching server.
  static int get serverStallSeconds => get('serverStallSeconds', 12);
  static set serverStallSeconds(int v) => set('serverStallSeconds', v);
}
