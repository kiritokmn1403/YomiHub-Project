import io,sys
p='overlay/lib/repositories/db_write_queue.dart'
s=io.open(p,encoding='utf-8',newline='').read()
crlf='\r\n' in s
s=s.replace('\r\n','\n')
def rep(a,b,n=1):
    global s
    assert s.count(a)==n,(a[:60],s.count(a))
    s=s.replace(a,b)

rep('''///   The limit stays finite in every case, so a deadlock is still impossible.
class DbWriteQueue {''','''///   The limit stays finite in every case, so a deadlock is still impossible.
///
/// 0.5.7 (P7F):
/// - Calls made *while the surrounding task is still running* no longer all
///   start at once. Up to 0.5.6.1 work a task left behind (a timer, a `then`
///   nobody awaits) that fired before the task had finished was taken for a
///   nested call and started its transaction immediately – in the middle of
///   the task's own asynchronous transaction ("An async write transaction is
///   already in progress in this isolate"; seen when the machine is loaded
///   and the task's own write takes longer than the timer).
///   Nested calls of one task now run one after another (FIFO, per level of
///   nesting): a call made from inside a running nested call is its child and
///   starts at once (no self-deadlock); a call made beside a running nested
///   call waits for it.
/// - A task keeps the queue until the nested calls it started have finished,
///   so the next task cannot open a transaction under them.
/// - The wait of a nested call is bounded by [stallTimeout] as well.
class DbWriteQueue {''')

rep('''    final current = Zone.current[_currentQueueKey];
    return current is _QueueTask &&
        identical(current.queue, this) &&
        current.active;
  }''','''    final current = Zone.current[_currentQueueKey];
    return current is _Frame &&
        identical(current.task.queue, this) &&
        current.task.active;
  }''')

rep('''    final current = Zone.current[_currentQueueKey];
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
''','''    final current = Zone.current[_currentQueueKey];
    if (current is _Frame &&
        identical(current.task.queue, this) &&
        current.task.active) {
      // Nested: the surrounding task is alive and working.
      return _runNested<T>(current, body, longRunning, label);
    }

    _pending++;
    final completer = Completer<T>();
    final task = _QueueTask(this, label)..longDepth = longRunning ? 1 : 0;
    final frame = _Frame(task, null);
    Future<void>? running;
''')

rep('''          () async => await body(),
          zoneValues: {_currentQueueKey: task},
        );
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        task.active = false;''','''          () async => await body(),
          zoneValues: {_currentQueueKey: frame},
        );
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        // 0.5.7: nested calls the task started (awaited or not) belong to
        // it; the next task must not begin while one of them is writing.
        while (frame.pending > 0) {
          await frame.tail;
        }
        frame.done = true;
        task.active = false;''')

rep('''  Duration _limitFor(_QueueTask? holder, Duration base) =>''','''  /// A call made while its task is running (0.5.7: one at a time per level).
  Future<T> _runNested<T>(
    _Frame current,
    FutureOr<T> Function() body,
    bool longRunning,
    String? label,
  ) {
    final task = current.task;
    // The nested call that made this one may have finished already (work it
    // left behind): then this is a call of the nearest level still running.
    var parent = current;
    while (parent.done && parent.parent != null) {
      parent = parent.parent!;
    }
    _progress++;
    if (longRunning) {
      task.longDepth++;
      task.label ??= label;
    }
    final frame = _Frame(task, parent);
    final previous = parent.tail;
    final released = Completer<void>();
    parent.pending++;
    parent.tail = released.future;

    Future<T> go() {
      _progress++;
      final result = Future<T>.sync(
        () => runZoned(body, zoneValues: {_currentQueueKey: frame}),
      );
      Future<void> settle() async {
        while (frame.pending > 0) {
          await frame.tail;
        }
        frame.done = true;
        parent.pending--;
        _progress++;
        if (longRunning) task.longDepth--;
        released.complete();
      }

      // Listens on a derived future so an error nobody awaits is still
      // reported exactly as before.
      result.then<void>((_) => settle(), onError: (Object _) => settle());
      return result.whenComplete(() {});
    }

    // Nobody beside us: start in the same turn, as always.
    if (parent.pending == 1) return go();
    return _afterTurn(previous, task, label).then((_) => go());
  }

  /// Completes when [previous] (the nested call ahead) has finished – or,
  /// so that a wait cycle cannot hang for ever, after the stall limit.
  Future<void> _afterTurn(Future<void> previous, _QueueTask task, String? label) {
    final gate = Completer<void>();
    Timer? timer;
    previous.whenComplete(() {
      timer?.cancel();
      if (!gate.isCompleted) gate.complete();
    });
    final base = stallTimeout;
    if (base != null) {
      final limit = _limitFor(task, base);
      timer = Timer(limit, () {
        if (gate.isCompleted) return;
        _stalls++;
        AppLogger.log(
          '[Isar Queue] Lệnh ghi lồng${label == null ? '' : ' ($label)'} đã chờ '
          'lệnh ghi trước đó của cùng tác vụ${_name(task)} ${limit.inSeconds} giây '
          '– chạy ngoài lượt để tránh treo',
          logLevel: LogLevel.warning,
        );
        gate.complete();
      });
    }
    return gate.future;
  }

  Duration _limitFor(_QueueTask? holder, Duration base) =>''')

rep('''// One instance per isolate (the worker isolate''','''/// One level of execution inside a task: the task's own body ([parent] null)
/// or a nested [DbWriteQueue.run] call. Calls made from it are its children
/// and run one at a time.
class _Frame {
  _Frame(this.task, this.parent);
  final _QueueTask task;
  final _Frame? parent;

  /// Children started or waiting that have not finished yet.
  int pending = 0;

  /// Completes when the newest child has finished; never fails.
  Future<void> tail = Future<void>.value();

  /// The body of this level and all its children have finished.
  bool done = false;
}

// One instance per isolate (the worker isolate''')
if crlf: s=s.replace('\n','\r\n')
io.open(p,'w',encoding='utf-8',newline='').write(s)
print('ok')
