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
///
/// 0.5.6:
/// - Re-entrancy is tied to the task that is *running*, not to the zone: work
///   a task left behind without awaiting it (a timer, a stream listener, a
///   `then` nobody awaits) inherits the task's zone and, up to 0.5.5, was
///   taken for a nested call for ever after – it skipped the queue and could
///   start a transaction in the middle of another task's. Such detached work
///   is now queued like any other caller once its task has finished.
/// - The queue cannot wait for ever: when the task holding the queue shows no
///   sign of life for [stallTimeout] (it awaits a queued task – a wait
///   cycle), the oldest waiting task is run without its turn and a warning is
///   logged. If a real transaction is still open Isar then answers with its
///   own, explicit error instead of the application hanging.
/// - R15: "no sign of life" is measured, not assumed from the waiting time.
///   A valid long operation (restoring a big backup, importing a library) is
///   never interrupted merely because others have waited 120 s:
///   * every task that starts or ends in its turn, every nested [run] of the
///     holder and every [reportProgress] restarts the measurement;
///   * time during which the isolate could not run timers at all (a long
///     synchronous transaction – how restore writes) is not counted;
///   * a task started with `longRunning: true` (restore / import) gets
///     [longStallTimeout] instead of [stallTimeout].
///   The limit stays finite in every case, so a deadlock is still impossible.
class DbWriteQueue {
  DbWriteQueue({
    this.stallTimeout = const Duration(seconds: 120),
    this.longStallTimeout = const Duration(minutes: 30),
  });

  static final _currentQueueKey = Object();

  /// How long the task holding the queue may show no progress, while others
  /// wait, before the oldest waiting task is run anyway.
  /// Null waits without limit (the 0.5.5 behaviour).
  final Duration? stallTimeout;

  /// The same limit for a holder started with `longRunning: true`.
  /// Never shorter than [stallTimeout].
  final Duration longStallTimeout;

  Future<void> _tail = Future.value();
  int _pending = 0;
  int _stalls = 0;
  int _extensions = 0;

  /// Tasks that have not started yet, oldest first.
  final List<_QueueTask> _waiting = [];

  /// The task running in its turn (null between two tasks).
  _QueueTask? _holder;

  // Watchdog: exists only while somebody waits.
  Timer? _watch;
  final Stopwatch _sinceTick = Stopwatch();
  Duration _idle = Duration.zero;
  int _progress = 0;
  int _seenProgress = 0;

  bool get isIdle => _pending == 0;

  /// How many tasks had to be run out of turn because the holder stalled.
  int get stallCount => _stalls;

  /// How many times a wait longer than [stallTimeout] was accepted because
  /// the holder was still making progress or was marked long-running.
  int get extensionCount => _extensions;

  /// Awaits all database writes currently queued on this isolate.
  Future<void> flush() => _tail;

  /// Whether the caller runs inside a task of this queue that is still
  /// executing (so a nested [run] may go ahead at once).
  bool get isInsideActiveTask {
    final current = Zone.current[_currentQueueKey];
    return current is _QueueTask &&
        identical(current.queue, this) &&
        current.active;
  }

  /// Tells the queue that the running operation is alive (for a long task
  /// that neither nests [run] calls nor blocks: e.g. one long async
  /// transaction reporting once per batch). Cheap; may be called anywhere.
  void reportProgress() => _progress++;

  /// Runs [body] sequentially after all preceding tasks in the queue have completed.
  ///
  /// Tasks are guaranteed to execute in strict FIFO order. If [body] throws or
  /// returns a rejected Future, the returned Future completes with that error,
  /// but subsequent queued tasks will still execute.
  ///
  /// Nested calls to [run] made while the surrounding task is still running
  /// are re-entrant to prevent deadlocks. Calls made from work the task left
  /// behind, after it finished, are queued (0.5.6).
  ///
  /// [longRunning] marks an operation that may validly hold the queue for
  /// minutes (restore, import); [label] names it in the log.
  ///
  /// Note: [run] does NOT retry [body]. Any transaction-level retry on conflict
  /// is narrowed to the transaction acquisition step before caller callbacks execute.
  /// Optional parameters [maxConflictRetries] and [conflictRetryDelay] are
  /// accepted for backwards compatibility with callers.
  Future<T> run<T>(
    FutureOr<T> Function() body, {
    int maxConflictRetries = 10,
    Duration conflictRetryDelay = const Duration(milliseconds: 20),
    bool longRunning = false,
    String? label,
  }) {
    final current = Zone.current[_currentQueueKey];
    if (current is _QueueTask &&
        identical(current.queue, this) &&
        current.active) {
      // Nested: the surrounding task is alive and working.
      _progress++;
      if (longRunning) {
        current.longDepth++;
        current.label ??= label;
      }
      return Future<T>.sync(body).whenComplete(() {
        _progress++;
        if (longRunning) current.longDepth--;
      });
    }

    _pending++;
    final completer = Completer<T>();
    final task = _QueueTask(this, label)..longDepth = longRunning ? 1 : 0;
    Future<void>? running;

    Future<void> execute({required bool inTurn}) async {
      _waiting.remove(task);
      if (_waiting.isEmpty) _stopWatch();
      task.active = true;
      if (inTurn) {
        _holder = task;
        _progress++;
      }
      try {
        final result = await runZoned(
          () async => await body(),
          zoneValues: {_currentQueueKey: task},
        );
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        task.active = false;
        _pending--;
        if (identical(_holder, task)) {
          _holder = null;
          _progress++;
        }
      }
    }

    task.startOutOfTurn = () {
      running ??= execute(inTurn: false);
    };
    _waiting.add(task);
    _startWatch();

    _tail = _tail.then((_) {
      final started = running;
      if (started == null) return running = execute(inTurn: true);
      // Already started out of turn: it holds the queue from here on, and
      // the next task waits until it has finished.
      if (task.active) {
        _holder = task;
        _progress++;
      }
      return started;
    }, onError: (_) {
      // Continue processing subsequent tasks even if a prior task failed
    });
    return completer.future;
  }

  Duration _limitFor(_QueueTask? holder, Duration base) =>
      holder != null && holder.longDepth > 0 && longStallTimeout > base
      ? longStallTimeout
      : base;

  void _startWatch() {
    final limit = stallTimeout;
    if (limit == null || _watch != null) return;
    var tick = limit ~/ 8;
    if (tick < const Duration(milliseconds: 1)) {
      tick = const Duration(milliseconds: 1);
    }
    _idle = Duration.zero;
    _seenProgress = _progress;
    _sinceTick
      ..reset()
      ..start();
    _watch = Timer.periodic(tick, (_) => _onTick(limit, tick));
  }

  void _stopWatch() {
    _watch?.cancel();
    _watch = null;
    _sinceTick.stop();
  }

  void _onTick(Duration base, Duration tick) {
    final elapsed = _sinceTick.elapsed;
    _sinceTick.reset();
    if (_waiting.isEmpty) {
      _stopWatch();
      return;
    }
    final holder = _holder;
    final oldest = _waiting.first;
    // The isolate could not run this timer on time: it was busy (a long
    // synchronous transaction), which is work, not a deadlock.
    final wasBlocked =
        elapsed >= tick * 2 + const Duration(seconds: 1);
    final limit = _limitFor(holder, base);
    if (_progress != _seenProgress || wasBlocked) {
      _seenProgress = _progress;
      _idle = Duration.zero;
    } else {
      _idle += tick;
    }
    if (_idle < limit) {
      if (holder != null &&
          !holder.extensionLogged &&
          oldest.waited.elapsed >= base + tick) {
        holder.extensionLogged = true;
        _extensions++;
        AppLogger.log(
          '[Isar Queue] Tác vụ ghi đã chờ ${oldest.waited.elapsed.inSeconds} giây; '
          'tác vụ đang giữ hàng đợi${_name(holder)} '
          '${holder.longDepth > 0 ? 'là thao tác dài hợp lệ' : 'vẫn đang tiến triển'} '
          '– tiếp tục chờ, không ghi chen '
          '(giới hạn không tiến triển: ${limit.inSeconds} giây)',
          logLevel: LogLevel.info,
        );
      }
      return;
    }
    // No progress for the whole limit while the isolate was free to run:
    // the holder waits for something that cannot happen. Let the oldest
    // waiting task go (one per tick while the stall lasts).
    _stalls++;
    AppLogger.log(
      '[Isar Queue] Tác vụ đang giữ hàng đợi${_name(holder)} không tiến triển '
      'suốt ${_idle.inSeconds} giây (có thể đang chờ chính tác vụ ghi đang xếp hàng); '
      'tác vụ${_name(oldest)} đã chờ ${oldest.waited.elapsed.inSeconds} giây '
      '– chạy ngoài lượt để tránh treo',
      logLevel: LogLevel.warning,
    );
    oldest.startOutOfTurn?.call();
  }

  static String _name(_QueueTask? t) =>
      t?.label == null ? '' : ' (${t!.label})';
}

/// One queued task; [active] only while its body is executing.
class _QueueTask {
  _QueueTask(this.queue, this.label);
  final DbWriteQueue queue;
  String? label;
  bool active = false;

  /// > 0 while the task (or a nested call inside it) is marked long-running.
  int longDepth = 0;
  bool extensionLogged = false;
  final Stopwatch waited = Stopwatch()..start();
  void Function()? startOutOfTurn;
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
