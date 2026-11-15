// YomiHub 0.5.7 – P7F (Claude Fable 5.2): DbWriteQueue – các lệnh ghi lồng
// trong cùng một tác vụ chạy lần lượt; việc "bỏ lại" nổ khi tác vụ còn chạy
// không được mở giao dịch chen vào giao dịch async của chính tác vụ đó.
import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/models/category.dart' as mdl;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  const guard = Timeout(Duration(seconds: 30));

  group('P7F – DbWriteQueue nested lane', () {
    test('detached work firing while its task still runs waits for the '
        'nested call in progress, and the next task waits for both', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      final detachedDone = Completer<void>();
      final t1 = q.run(() async {
        unawaited(
          wait(20)
              .then(
                (_) => q.run(() async {
                  log.add('detached-start');
                  await wait(60);
                  log.add('detached-end');
                }),
              )
              .whenComplete(detachedDone.complete),
        );
        await q.run(() async {
          log.add('own-start');
          await wait(120);
          log.add('own-end');
        });
        log.add('t1-body-end');
      });
      final t2 = q.run(() async => log.add('t2'));
      await Future.wait([t1, t2, detachedDone.future]);
      int at(String s) => log.indexOf(s);
      expect(log, hasLength(6));
      expect(log.first, 'own-start');
      expect(at('own-end'), lessThan(at('detached-start')));
      expect(at('own-end'), lessThan(at('t1-body-end')));
      expect(at('detached-end'), at('detached-start') + 1 + (at('t1-body-end') > at('detached-start') ? 1 : 0));
      expect(log.last, 't2');
      expect(q.stallCount, 0);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('a call made inside a running nested call starts at once '
        '(three levels, no self-deadlock)', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      final r = await q.run(() async {
        log.add('a');
        return await q.run(() async {
          log.add('b');
          final v = await q.run(() {
            log.add('c');
            return 7;
          });
          log.add('b-end');
          return v + 1;
        });
      }).timeout(const Duration(seconds: 5));
      expect(r, 8);
      expect(log, ['a', 'b', 'c', 'b-end']);
      expect(q.stallCount, 0);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('the first nested call still starts synchronously', () async {
      final q = DbWriteQueue();
      var started = false;
      await q.run(() async {
        final f = q.run(() {
          started = true;
        });
        expect(started, isTrue);
        await f;
      });
    }, timeout: guard);

    test('nested calls started side by side run one at a time, in order',
        () async {
      final q = DbWriteQueue();
      final log = <String>[];
      var running = 0;
      var maxRunning = 0;
      Future<int> job(int i, int ms) => q.run(() async {
        running++;
        if (running > maxRunning) maxRunning = running;
        log.add('s$i');
        await wait(ms);
        log.add('e$i');
        running--;
        return i;
      });
      final r = await q.run(
        () => Future.wait([job(1, 40), job(2, 5), job(3, 20)]),
      );
      expect(r, [1, 2, 3]);
      expect(log, ['s1', 'e1', 's2', 'e2', 's3', 'e3']);
      expect(maxRunning, 1);
    }, timeout: guard);

    test('a task keeps the queue until a nested call it did not await has '
        'finished', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      final t1 = q.run(() async {
        unawaited(
          q.run(() async {
            log.add('left-start');
            await wait(80);
            log.add('left-end');
          }),
        );
        log.add('t1-end');
      });
      final t2 = q.run(() async => log.add('t2'));
      await t1;
      // the caller gets its result as soon as the body ends
      expect(log, ['left-start', 't1-end']);
      await t2;
      expect(log, ['left-start', 't1-end', 'left-end', 't2']);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('work left behind by a finished nested call is a sibling of the '
        'calls that follow it, not an intruder', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      final leftDone = Completer<void>();
      await q.run(() async {
        await q.run(() async {
          // fires after this nested call has returned
          unawaited(
            wait(20)
                .then(
                  (_) => q.run(() async {
                    log.add('left-start');
                    await wait(10);
                    log.add('left-end');
                  }),
                )
                .whenComplete(leftDone.complete),
          );
        });
        await q.run(() async {
          log.add('second-start');
          await wait(80);
          log.add('second-end');
        });
      });
      await leftDone.future;
      expect(log, ['second-start', 'second-end', 'left-start', 'left-end']);
    }, timeout: guard);

    test('an error in a nested call reaches its caller and does not block '
        'the calls behind it', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      await q.run(() async {
        final bad = q.run<void>(() async {
          await wait(10);
          throw StateError('boom');
        });
        final good = q.run(() async => log.add('good'));
        await expectLater(bad, throwsStateError);
        await good;
      });
      expect(log, ['good']);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('a nested wait cycle is bounded by stallTimeout', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(milliseconds: 200));
      final log = <String>[];
      await q.run(() async {
        final later = Completer<void>();
        // first nested call waits for the second, which is queued behind it
        final first = q.run(() async {
          await later.future;
          log.add('first');
        });
        final second = q.run(() async => log.add('second'));
        later.complete(second);
        await Future.wait([first, second]).timeout(const Duration(seconds: 5));
      });
      expect(log, ['second', 'first']);
      expect(q.stallCount, 1);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('real Isar: a sync write left behind that fires while the task\'s '
        'own async transaction is open does not collide (0.5.6.1: '
        '"async write transaction is already in progress")', () async {
      if (Platform.isWindows) {
        const candidates = [
          'libisar.dll',
          r'build\windows\x64\runner\Release\libisar.dll',
          r'D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\libisar.dll',
        ];
        String? dll;
        for (final c in candidates) {
          if (File(c).existsSync()) {
            dll = File(c).absolute.path;
            break;
          }
        }
        if (dll != null) {
          await Isar.initializeIsarCore(
            libraries: {Abi.windowsX64: dll},
            download: false,
          );
        } else {
          await Isar.initializeIsarCore(download: false);
        }
      } else {
        await Isar.initializeIsarCore(download: false);
      }
      final dir = await Directory.systemTemp.createTemp('yh_057_p7f_isar_');
      final isar = await Isar.open(
        [mdl.CategorySchema],
        directory: dir.path,
        name: 'yh_057_p7f_queue',
      );
      try {
        mdl.Category cat(String name) =>
            mdl.Category(name: name, forItemType: ItemType.manga);
        final errors = <Object>[];
        final detachedDone = Completer<void>();
        // task 1: its own async transaction stays open 400 ms (a loaded
        // machine); the write it left behind fires after 50 ms
        final t1 = dbWriteQueue.run(() async {
          unawaited(
            wait(50)
                .then(
                  (_) => isar.writeTxnSyncSafe(
                    () => isar.categorys.putSync(cat('detached-sync')),
                  ),
                )
                .then<void>((_) {}, onError: (Object e) => errors.add(e))
                .whenComplete(detachedDone.complete),
          );
          await isar.writeTxnAsyncSafe(() async {
            await isar.categorys.put(cat('own-1'));
            await wait(400);
            await isar.categorys.put(cat('own-2'));
          });
        });
        // task 2: another long async transaction right behind
        final t2 = isar.writeTxnAsyncSafe(() async {
          await isar.categorys.put(cat('next-1'));
          await wait(400);
          await isar.categorys.put(cat('next-2'));
        });
        final t3 = isar.writeTxnSyncSafe(
          () => isar.categorys.putSync(cat('sync-3')),
        );
        await Future.wait([t1, t2, t3, detachedDone.future]).timeout(
          const Duration(seconds: 20),
        );
        expect(errors, isEmpty);
        final names = isar.categorys
            .where()
            .findAllSync()
            .map((c) => c.name)
            .toSet();
        expect(names, {
          'own-1',
          'own-2',
          'next-1',
          'next-2',
          'sync-3',
          'detached-sync',
        });
        expect(dbWriteQueue.isIdle, isTrue);
      } finally {
        await isar.close(deleteFromDisk: true);
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }, timeout: guard);
  });
}
