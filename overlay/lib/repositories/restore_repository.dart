import 'package:mangayomi/main.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';

// Restore's transactions are large, restore-specific bulk operations (clear +
// replace/merge across mangas, chapters, categories, settings, etc.) that
// don't fit the per-aggregate repositories' intent-named methods - each
// restore path needs its own bespoke logic, not a generic "save" or "putAll".
// This just gives restore its own queued write path, consistent with the
// rest of the app, without forcing that logic into the wrong repository.
class RestoreRepository {
  // 0.5.6 (R15): a restore / import may validly hold the write queue for
  // minutes; marked long-running so that waiting writes are not run in the
  // middle of it (see DbWriteQueue.longStallTimeout).
  Future<T> run<T>(T Function() body) => dbWriteQueue.run(
    () => isar.writeTxnSyncSafe<T>(body),
    longRunning: true,
    label: 'khôi phục / nhập sao lưu',
  );
}

final restoreRepository = RestoreRepository();
