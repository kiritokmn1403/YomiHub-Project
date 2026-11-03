import 'dart:async';

import 'package:isar_community/isar.dart';

/// YomiHub 0.4.9: single serial lane for every Isar write on this isolate.
///
/// Before 0.4.9 about fifteen `isar.writeTxn(...)` calls ran outside the
/// queue. While one of them was awaiting, a queued `writeTxnSync` (e.g. the
/// video player saving the watch position) failed with
/// "An async write transaction is already in progress in this isolate"
/// (logs_6, 01/11/2026 11:42:46) and the resume position was lost.
///
/// `run` is re-entrant: a body already running inside the queue executes
/// nested writes directly instead of deadlocking behind itself.
class DbWriteQueue {
  Future<void> _tail = Future.value();
  int _pending = 0;
  static final Object _zoneKey = Object();

  bool get inQueue => Zone.current[_zoneKey] == true;
  bool get isIdle => _pending == 0;

  Future<T> run<T>(FutureOr<T> Function() body) {
    if (inQueue) return Future.sync(body);
    _pending++;
    final result = _tail.then(
      (_) => runZoned(
        () => Future.sync(body),
        zoneValues: {_zoneKey: true},
      ),
    );
    _tail = result.then((_) {}, onError: (_) {}).whenComplete(() {
      _pending--;
    });
    return result;
  }
}

// One instance per isolate (the worker isolate in isolate_service.dart gets
// its own copy, matching its own Isar instance).
final dbWriteQueue = DbWriteQueue();

bool _isAsyncTxnConflict(Object e) =>
    e is IsarError &&
    e.toString().contains('async write transaction is already in progress');

extension YhSafeIsarWrite on Isar {
  /// Queued async write transaction (replaces direct `writeTxn`).
  Future<T> writeTxnQ<T>(Future<T> Function() callback, {bool silent = false}) =>
      dbWriteQueue.run(() => writeTxn(callback, silent: silent));

  /// Sync write that never throws the "async transaction in progress" error:
  /// on conflict a void/nullable write is re-queued and runs right after the
  /// active async transaction; a write whose result the caller needs is
  /// rethrown unchanged.
  T writeTxnSyncSafe<T>(T Function() callback, {bool silent = false}) {
    try {
      return writeTxnSync(callback, silent: silent);
    } catch (e) {
      if (!_isAsyncTxnConflict(e) || dbWriteQueue.inQueue) rethrow;
      if (null is T) {
        unawaited(
          dbWriteQueue
              .run(() => writeTxnSync(callback, silent: silent))
              .catchError((Object _) => null as T),
        );
        return null as T;
      }
      rethrow;
    }
  }
}
