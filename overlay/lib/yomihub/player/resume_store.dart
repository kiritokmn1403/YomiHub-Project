import 'dart:async';

import 'package:hive/hive.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/player/resume_policy.dart';
import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';

/// YomiHub 0.5.7 (U7 / FC39): the last watched position of every episode,
/// kept in memory and in a small Hive box next to the Isar row.
///
/// Why: the Isar write goes through the serialized database write queue. When
/// a long job holds that queue (library update, backup, extension sync) the
/// position written on exit is still waiting when the episode is reopened, so
/// the player read the previous value and "did not resume from where I left".
/// The mark is written synchronously (memory) and without the queue (Hive),
/// so reopening – even after the app was killed – sees the real last position.
class YomiResumeStore {
  YomiResumeStore._();
  static const boxName = 'yomihub_resume';
  static const maxEntries = 300;

  static final Map<int, ResumeMark> _mem = {};
  static Box? _box;
  static Future<void>? _opening;

  /// Unit tests switch the Hive part off (memory only).
  static bool persistent = true;

  /// Loads the persisted marks once. Never throws, never waits more than 2 s.
  static Future<void> ensureOpen() => !persistent
      ? Future<void>.value()
      : _opening ??= _load()
      .timeout(const Duration(seconds: 2))
      .catchError((Object e) {
        AppLogger.logOnce(
          'resume-store-open',
          '[Trình phát] Không mở được bộ nhớ vị trí xem (vẫn dùng cơ sở dữ liệu): $e',
          logLevel: LogLevel.warning,
        );
      });

  static Future<void> _load() async {
    final box = await YomiHive.open(boxName);
    _box = box;
    final stale = <dynamic>[];
    final all = <(dynamic, ResumeMark)>[];
    for (final k in box.keys) {
      final id = int.tryParse('$k');
      final mark = ResumeMark.fromList(box.get(k));
      if (id == null || mark == null) {
        stale.add(k);
        continue;
      }
      all.add((k, mark));
      // A newer in-memory mark (taken before the box finished opening) wins.
      final cur = _mem[id];
      if (cur == null || cur.atMs < mark.atMs) _mem[id] = mark;
    }
    if (all.length > maxEntries) {
      all.sort((a, b) => a.$2.atMs.compareTo(b.$2.atMs));
      for (final e in all.take(all.length - maxEntries)) {
        stale.add(e.$1);
        _mem.remove(int.tryParse('${e.$1}'));
      }
    }
    if (stale.isNotEmpty) unawaited(box.deleteAll(stale).catchError((_) {}));
  }

  static ResumeMark? peek(int? episodeId) =>
      episodeId == null ? null : _mem[episodeId];

  static void remember(
    int? episodeId,
    Duration position,
    Duration? total, {
    int? nowMs,
  }) {
    if (episodeId == null) return;
    final mark = ResumeMark(
      position.inMilliseconds,
      total?.inMilliseconds ?? 0,
      nowMs ?? DateTime.now().millisecondsSinceEpoch,
    );
    _mem[episodeId] = mark;
    if (!persistent) return;
    final box = _box;
    if (box == null) {
      unawaited(ensureOpen());
      return;
    }
    try {
      unawaited(
        box.put('$episodeId', mark.toList()).catchError((Object e) {
          AppLogger.logOnce(
            'resume-store-put',
            '[Trình phát] Trình phát video không lưu đúng vị trí đã xem (bộ nhớ phụ): $e',
            logLevel: LogLevel.warning,
          );
        }),
      );
    } catch (e) {
      AppLogger.logOnce(
        'resume-store-put',
        '[Trình phát] Trình phát video không lưu đúng vị trí đã xem (bộ nhớ phụ): $e',
        logLevel: LogLevel.warning,
      );
    }
  }

  static void forget(int? episodeId) {
    if (episodeId == null) return;
    _mem.remove(episodeId);
    try {
      final f = _box?.delete('$episodeId');
      if (f != null) unawaited(f.catchError((_) {}));
    } catch (_) {}
  }

  /// Test hook.
  static void resetForTest() {
    _mem.clear();
    _box = null;
    _opening = null;
  }
}
