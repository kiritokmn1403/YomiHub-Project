import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.2.1: single entry point for Hive.
///
/// 0.2.0 initialised Hive inside `_postLaunchInit`, i.e. *after* `runApp`.
/// Screens built on the first frame (Library → genre filter, browser, PDF
/// reader…) called `Hive.openBox` before that and crashed the zone with
/// "HiveError: You need to initialize Hive or provide a path to store the box"
/// (logs 07/10/2026 @ /MangaLibrary). Every box is now opened through
/// [YomiHive.open], which waits for the one-time init.
class YomiHive {
  YomiHive._();

  static Completer<void>? _init;
  static final Map<String, Future<Box>> _opening = {};

  static bool get isReady => _init?.isCompleted ?? false;

  /// Idempotent and safe to call from anywhere (also concurrently).
  static Future<void> ensure() {
    final c = _init;
    if (c != null) return c.future;
    final n = _init = Completer<void>();
    () async {
      try {
        final isApple = Platform.isIOS || Platform.isMacOS;
        final hivePath = isApple
            ? 'databases'
            : p.join(AppIdentity.dirName, 'databases');
        await Hive.initFlutter(Platform.isAndroid ? '' : hivePath);
        n.complete();
      } catch (e, st) {
        _init = null; // allow a retry
        n.completeError(e, st);
      }
    }();
    return n.future;
  }

  /// Opens (or returns the already open) box [name]. Concurrent callers share
  /// one open operation, so two widgets can no longer race on the same box.
  static Future<Box<T>> open<T>(String name) async {
    await ensure();
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    final pending = _opening[name];
    if (pending != null) return (await pending) as Box<T>;
    final f = Hive.openBox<T>(name);
    _opening[name] = f;
    try {
      return await f;
    } catch (e) {
      // a corrupt box (app killed while writing) must not keep the app from
      // starting: drop it and start empty (settings fall back to defaults).
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return Hive.openBox<T>(name);
    } finally {
      _opening.remove(name);
    }
  }

  /// Synchronous access when the box is already open, otherwise null.
  static Box<T>? maybe<T>(String name) =>
      isReady && Hive.isBoxOpen(name) ? Hive.box<T>(name) : null;
}
