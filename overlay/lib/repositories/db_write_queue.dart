import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.4.9 / 0.5.4 / 0.5.5: single serial FIFO lane for every Isar write on this isolate.
///
/// Prevents "An async write transaction is already in progress in this isolate"
/// errors and ensures watch position / library updates are strictly serialized
/// in FIFO order without race conditions or data loss.
///
/// 0.5.5:
/// - Provides [flush] so callers (player exit, episode switch, DB backup) can await all queued writes.
/// - Strict FIFO execution: every task passed to [run] is chained behind the serial lane.
/// - [run] executes [body] strictly once without retrying [body]. Side effects prior to
///   the transaction are never duplicated on transaction conflict.
/// - Transaction acquisition conflicts are retried specifically at the transaction acquisition
///   step (in [writeTxnAsyncSafe] and [writeTxnSyncSafe]) BEFORE any caller callback begins execution.
/// - Once a callback begins executing, it is never retried; callback errors are propagated with full fidelity.
/// - Propagates errors to the caller while allowing subsequent tasks in the queue and [flush] to continue.
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
  ///
  /// Note: [run] does NOT retry [body]. Any transaction-level retry on conflict
  /// is narrowed to the transaction acquisition step before caller callbacks execute.
  /// Optional parameters [maxConflictRetries] and [conflictRetryDelay] are
  /// accepted for backwards compatibility with callers.
  Future<T> run<T>(
    FutureOr<T> Function() body, {
    int maxConflictRetries = 10,
    Duration conflictRetryDelay = const Duration(milliseconds: 20),
  }) {
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
      writeTxnAsyncSafe(callback, silent: silent);

  /// Async write transaction with bounded retry on transaction acquisition conflict.
  ///
  /// Serializes the write through [dbWriteQueue]. If another async transaction
  /// holds the lock, retries acquiring the transaction with backoff BEFORE
  /// [callback] is invoked. Once [callback] begins execution, it is executed
  /// at most once and never retried on failure.
  Future<T> writeTxnAsyncSafe<T>(
    Future<T> Function() callback, {
    bool silent = false,
    int maxConflictRetries = 10,
    Duration conflictRetryDelay = const Duration(milliseconds: 20),
  }) =>
      dbWriteQueue.run(() async {
        int attempts = 0;
        while (true) {
          var callbackInvoked = false;
          try {
            return await writeTxn(() async {
              callbackInvoked = true;
              return await callback();
            }, silent: silent);
          } catch (e, st) {
            if (!callbackInvoked &&
                _isAsyncTxnConflict(e) &&
                attempts < maxConflictRetries) {
              attempts++;
              await Future.delayed(conflictRetryDelay);
              continue;
            }
            Error.throwWithStackTrace(e, st);
          }
        }
      });

  /// Queued synchronous write transaction with bounded retry on acquisition conflict.
  ///
  /// Serializes the synchronous write through [dbWriteQueue]. If an async transaction
  /// is in progress on this isolate, retries acquiring the sync transaction with backoff
  /// BEFORE [callback] is invoked. Once [callback] begins execution, it is executed
  /// at most once and never retried on failure.
  Future<T> writeTxnSyncSafe<T>(
    T Function() callback, {
    bool silent = false,
    int maxConflictRetries = 10,
    Duration conflictRetryDelay = const Duration(milliseconds: 20),
  }) =>
      dbWriteQueue.run(() async {
        int attempts = 0;
        while (true) {
          var callbackInvoked = false;
          final T result;
          try {
            result = writeTxnSync(() {
              callbackInvoked = true;
              return callback();
            }, silent: silent);
          } catch (e, st) {
            if (!callbackInvoked &&
                _isAsyncTxnConflict(e) &&
                attempts < maxConflictRetries) {
              attempts++;
              await Future.delayed(conflictRetryDelay);
              continue;
            }
            Error.throwWithStackTrace(e, st);
          }
          return result;
        }
      });

  /// Direct synchronous write without queueing or async retry backoff.
  T writeTxnSyncDirect<T>(
    T Function() callback, {
    bool silent = false,
  }) {
    try {
      return writeTxnSync(callback, silent: silent);
    } catch (e) {
      if (_isAsyncTxnConflict(e)) {
        AppLogger.log(
          '[Isar Direct] Tranh chấp async write transaction khi ghi đồng bộ: $e',
          logLevel: LogLevel.warning,
        );
      }
      rethrow;
    }
  }
}
