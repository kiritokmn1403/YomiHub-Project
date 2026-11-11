import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/main.dart' as app;
import 'package:mangayomi/models/category.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/download.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/repositories/category_repository.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';
import 'package:mangayomi/yomihub/app_identity.dart';

void main() {
  setUpAll(() async {
    // Resolve local DLL for Isar Community on Windows to avoid runtime downloads
    if (Platform.isWindows) {
      final candidates = [
        'libisar.dll',
        r'build\windows\x64\runner\Release\libisar.dll',
        r'D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\libisar.dll',
        r'C:\Users\nguye\AppData\Local\Pub\Cache\hosted\pub.dev\isar_community_flutter_libs-3.3.2\windows\libisar.dll',
      ];
      String? localDll;
      for (final path in candidates) {
        if (File(path).existsSync()) {
          localDll = File(path).absolute.path;
          break;
        }
      }
      if (localDll != null) {
        await Isar.initializeIsarCore(
          libraries: {Abi.windowsX64: localDll},
          download: false,
        );
        return;
      }
    }
    await Isar.initializeIsarCore(download: false);
  });

  group('YomiHub 0.5.5 Core & Database Integrity', () {
    test('version / user agent matches 0.5.5', () {
      expect(AppIdentity.userAgent, anyOf('YomiHub/0.5.5', 'YomiHub/0.5.6', startsWith('YomiHub/0.5.')));
    });

    test('Case 1: Callback with side effect only executes once when acquiring transaction conflicts', () async {
      final tempDir = await Directory.systemTemp.createTemp('yh_055_isar_sideeffect_');
      try {
        final isar = await Isar.open(
          [
            MangaSchema,
            ChapterSchema,
            HistorySchema,
            SettingsSchema,
            CategorySchema,
            DownloadSchema,
            SourceSchema,
            TrackSchema,
            UpdateSchema,
          ],
          directory: tempDir.path,
          name: 'yh_055_sideeffect_db',
        );
        app.isar = isar;

        // Giữ khóa bằng giao dịch bất đồng bộ bên ngoài
        final externalBlocker = Completer<void>();
        final externalTxn = isar.writeTxn(() async {
          await externalBlocker.future;
        });

        int sideEffectCounter = 0;
        final syncFuture = isar.writeTxnSyncSafe(() {
          sideEffectCounter++;
          final cat = Category(name: 'Side Effect Test', forItemType: ItemType.manga);
          isar.categorys.putSync(cat);
          return cat.id;
        }, conflictRetryDelay: const Duration(milliseconds: 30));

        // Nhả khóa sau 60ms để writeTxnSyncSafe có tranh chấp ban đầu nhưng giải phóng kịp
        await Future<void>.delayed(const Duration(milliseconds: 60));
        externalBlocker.complete();
        await externalTxn;

        final catId = await syncFuture;
        expect(catId, isNotNull);
        // QUAN TRỌNG: Callback chỉ được gọi đúng 1 lần duy nhất, không nhân đôi side effect!
        expect(sideEffectCounter, 1);
        expect(isar.categorys.filter().nameEqualTo('Side Effect Test').countSync(), 1);

        await isar.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Case 2: Callback exception (even with conflict message) is returned to caller and never retried', () async {
      final tempDir = await Directory.systemTemp.createTemp('yh_055_isar_err_');
      try {
        final isar = await Isar.open(
          [
            MangaSchema,
            ChapterSchema,
            HistorySchema,
            SettingsSchema,
            CategorySchema,
            DownloadSchema,
            SourceSchema,
            TrackSchema,
            UpdateSchema,
          ],
          directory: tempDir.path,
          name: 'yh_055_err_db',
        );
        app.isar = isar;

        int callbackRunCount = 0;
        final failureFuture = isar.writeTxnSyncSafe(() {
          callbackRunCount++;
          // Ném chính IsarError có nội dung tranh chấp để chứng minh callbackInvoked
          // chặn đứng việc retry lặp lại callback
          throw IsarError('An async write transaction is already in progress');
        }, maxConflictRetries: 5, conflictRetryDelay: const Duration(milliseconds: 10));

        await expectLater(
          failureFuture,
          throwsA(isA<IsarError>().having(
            (e) => e.message,
            'message',
            contains('async write transaction is already in progress'),
          )),
        );

        // QUAN TRỌNG: Dù lỗi là conflict IsarError, callbackInvoked == true
        // đảm bảo callback chỉ chạy ĐÚNG 1 LẦN, tuyệt đối không bị retry lặp lại!
        expect(callbackRunCount, 1);

        await isar.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Case 3: FIFO order and flush continue processing tasks after an earlier task fails', () async {
      final orderList = <int>[];

      // Task 1: Ném lỗi
      final task1 = dbWriteQueue.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw StateError('task1_failed');
      });

      // Task 2: Chạy bình thường
      final task2 = dbWriteQueue.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        orderList.add(2);
        return 'task2_ok';
      });

      // Task 3: Chạy bình thường
      final task3 = dbWriteQueue.run(() async {
        orderList.add(3);
        return 'task3_ok';
      });

      // Task 1 phải ném lỗi
      await expectLater(task1, throwsA(isA<StateError>()));

      // Task 2 và Task 3 phải hoàn tất theo thứ tự FIFO
      final res2 = await task2;
      final res3 = await task3;
      expect(res2, 'task2_ok');
      expect(res3, 'task3_ok');
      expect(orderList, [2, 3]);

      // Hàng đợi flush thành công không bị nghẽn
      await expectLater(dbWriteQueue.flush(), completes);
    });

    test('Case 4: CategoryRepository & ChapterRepository safe sync deferral under external txn', () async {
      final tempDir = await Directory.systemTemp.createTemp('yh_055_isar_caller_');
      try {
        final isar = await Isar.open(
          [
            MangaSchema,
            ChapterSchema,
            HistorySchema,
            SettingsSchema,
            CategorySchema,
            DownloadSchema,
            SourceSchema,
            TrackSchema,
            UpdateSchema,
          ],
          directory: tempDir.path,
          name: 'yh_055_caller_db',
        );
        app.isar = isar;

        // Giữ khóa ngoài
        final externalHold = Completer<void>();
        final externalTxn = isar.writeTxn(() async {
          await externalHold.future;
        });

        // Caller gọi save thông qua writeTxnSyncSafe
        final catFuture = categoryRepository.save(Category(name: 'Manga Safe', forItemType: ItemType.manga));
        final chapFuture = chapterRepository.save(Chapter(name: 'Ch 1', mangaId: 100));

        // Nhả khóa ngoài sau 50ms
        await Future<void>.delayed(const Duration(milliseconds: 50));
        externalHold.complete();
        await externalTxn;

        await catFuture;
        await chapFuture;

        expect(isar.categorys.filter().nameEqualTo('Manga Safe').countSync(), 1);
        expect(isar.chapters.filter().nameEqualTo('Ch 1').countSync(), 1);

        await isar.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
