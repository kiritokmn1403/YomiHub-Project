import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.4.9 / 0.5.4: single serial FIFO lane for every Isar write on this isolate.
///
/// Prevents "An async write transaction is already in progress in this isolate"
/// errors and ensures watch position / library updates are strictly serialized
/// in FIFO order without race conditions or data loss.
///
/// 0.5.4:
/// - Provides [flush] so callers (player exit, episode switch, DB backup) can await all queued writes.
/// - Strict FIFO execution: every task passed to [run] is chained behind the serial lane.
/// - Propagates errors to the caller while allowing subsequent tasks in the queue to continue.
class DbWriteQueue {
  static final _currentQueueKey = Object();

  Future<void> _tail = Future.value();
  int _pending = 0;

  bool get isIdle => _pending == 0;

  /// Awaits all database writes currently queued on this isolate.
  Future<void> flush() => _tail;

  /// Runs [body] sequentially after all preceding tasks in the queue have completed.
  ///
  /// Tasks are guaranteed to execute in strict FIFO order. If [body] throws or
  /// returns a rejected Future, the returned Future completes with that error,
  /// but subsequent queued tasks will still execute.
  ///
  /// Nested calls to [run] originating from within an active task on this queue
  /// are re-entrant to prevent deadlocks.
  Future<T> run<T>(FutureOr<T> Function() body) {
    if (Zone.current[_currentQueueKey] == this) {
      return Future<T>.sync(body);
    }

    _pending++;
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final result = await runZoned(
          () async => await body(),
          zoneValues: {_currentQueueKey: this},
        );
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _pending--;
      }
    }, onError: (_) {
      // Continue processing subsequent tasks even if a prior task failed
    });
    return completer.future;
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

  /// Sync write with conflict recovery.
  ///
  /// If a conflicting async write transaction is in progress on this isolate:
  /// - A void/nullable write is serialized through [dbWriteQueue] so it executes
  ///   via an async [writeTxn] once preceding transactions finish, preserving FIFO order.
  /// - Errors are logged rather than silently discarded.
  /// - Non-nullable writes whose synchronous return value is required are rethrown.
  T writeTxnSyncSafe<T>(
    T Function() callback, {
    bool silent = false,
  }) {
    try {
      return writeTxnSync(callback, silent: silent);
    } catch (e, st) {
      if (!_isAsyncTxnConflict(e)) rethrow;
      if (null is! T) rethrow;

      unawaited(
        dbWriteQueue.run(() => writeTxnSync(callback, silent: silent)).catchError((err, errSt) {
          AppLogger.log(
            '[Isar Safe] Lỗi khi thực hiện ghi sau tranh chấp: $err\n$errSt',
            logLevel: LogLevel.error,
          );
        }),
      );
      return null as T;
    }
  }
}
