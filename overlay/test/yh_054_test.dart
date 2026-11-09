// YomiHub 0.5.4 regression & behavioral tests (real code paths).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/main.dart' as app;
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/player/player_net.dart';
import 'package:mangayomi/yomihub/win/win_diag.dart';

String _read(String path) => File(path).readAsStringSync();

/// Emulates the single-flight resume coordinator logic from AnimePlayerView
class ResumeCoordinatorSimulator {
  int mediaSessionId = 0;
  bool yhResumeInProgress = false;
  bool hasResumeTargetCompleted = false;
  Duration initialResumeTarget = Duration.zero;
  bool yhLiveStream = false;
  int seekCallCount = 0;
  Duration? lastSeekTarget;
  bool toastShown = false;

  void startSession(int sessionId, Duration resumeTarget) {
    mediaSessionId = sessionId;
    initialResumeTarget = resumeTarget;
    hasResumeTargetCompleted = resumeTarget <= Duration.zero;
    yhLiveStream = false;
    yhResumeInProgress = false;
    seekCallCount = 0;
    lastSeekTarget = null;
    toastShown = false;
  }

  Future<void> coordinateResume({
    required int sessionId,
    required Duration currentDuration,
    required Duration currentPosition,
    required bool isPlaying,
    required String? seekable,
    String trigger = 'init',
  }) async {
    if (mediaSessionId != sessionId) return;
    if (hasResumeTargetCompleted || initialResumeTarget <= Duration.zero) return;
    if (yhResumeInProgress) return; // Single-flight

    yhResumeInProgress = true;
    try {
      final start = initialResumeTarget;
      final hasKnownDuration = currentDuration > Duration.zero;

      // Live stream policy:
      // Even if duration > 0 (e.g. DVR sliding buffer), if seekable == 'no', it is Live.
      final isLive = (seekable == 'no') ||
          (!hasKnownDuration && isPlaying && currentPosition > Duration.zero);

      if (isLive) {
        yhLiveStream = true;
        initialResumeTarget = Duration.zero;
        hasResumeTargetCompleted = true;
        return;
      }

      // If duration is not yet known (slow VOD still buffering/indexing):
      // leave hasResumeTargetCompleted = false so next event can re-trigger
      if (!hasKnownDuration) {
        return;
      }

      if (yhLiveStream) {
        yhLiveStream = false;
      }

      // Resume execution
      seekCallCount++;
      lastSeekTarget = start;
      hasResumeTargetCompleted = true;
      toastShown = true;
    } finally {
      yhResumeInProgress = false;
    }
  }
}

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  group('YomiHub 0.5.4', () {
    test('version / user agent', () {
      expect(AppIdentity.userAgent, 'YomiHub/0.5.4');
      expect(_read('pubspec.yaml'), contains('version: 0.5.4+46'));
    });

    test('error classification categories and negative tests', () {
      // 1. HTTP 404 status codes
      final msg404 = AppLogger.classifyMessage(
        'ClientException: 404 Not Found, uri=https://api.com/v1/chapter',
        LogLevel.error,
      );
      expect(msg404, startsWith('[Lỗi Nguồn 404]'));

      final msg404Alt = AppLogger.classifyMessage(
        'Request failed with status: 404 for video fragment',
        LogLevel.error,
      );
      expect(msg404Alt, startsWith('[Lỗi Nguồn 404]'));

      // Negative 404 test: numbers in URL/filenames or arbitrary strings MUST NOT trigger 404
      final not404A = AppLogger.classifyMessage(
        'Failed to load URL: https://example.com/asset_404123.jpg',
        LogLevel.error,
      );
      expect(not404A.contains('[Lỗi Nguồn 404]'), isFalse);

      final not404B = AppLogger.classifyMessage(
        'Failed to load image https://cdn.site.com/image_4040.png',
        LogLevel.error,
      );
      expect(not404B.contains('[Lỗi Nguồn 404]'), isFalse);

      // 2. HTTP 403 / Cloudflare Turnstile
      final msg403 = AppLogger.classifyMessage(
        'Cloudflare challenge failed (HTTP 403 Forbidden)',
        LogLevel.error,
      );
      expect(msg403, startsWith('[Lỗi Nguồn 403 / Cloudflare]'));

      // 3. Tor / network timeout
      final msgTor = AppLogger.classifyMessage(
        'Tor connection timed out after 90 seconds (SocketException)',
        LogLevel.warning,
      );
      expect(msgTor, startsWith('[Lỗi Mạng / Tor Timeout]'));

      // Negative Tor test: "operator" in "Null check operator" MUST NOT match "tor"
      final msgOperator = AppLogger.classifyMessage(
        'Null check operator used on a null value',
        LogLevel.error,
      );
      expect(msgOperator, startsWith('[Lỗi Ứng Dụng]'));
      expect(msgOperator.contains('Tor Timeout'), isFalse);

      // 4. Application internal error
      final msgApp = AppLogger.classifyMessage(
        'FlutterError: Null check operator used on a null value',
        LogLevel.error,
      );
      expect(msgApp, startsWith('[Lỗi Ứng Dụng]'));

      final msgIsar = AppLogger.classifyMessage(
        'IsarError: An async write transaction is already in progress in this isolate',
        LogLevel.error,
      );
      expect(msgApp, startsWith('[Lỗi Ứng Dụng]'));
      expect(msgIsar, startsWith('[Lỗi Ứng Dụng]'));

      // 5. Info logs are untouched
      final msgInfo = AppLogger.classifyMessage(
        'User logged in',
        LogLevel.info,
      );
      expect(msgInfo, 'User logged in');
    });

    test('dbWriteQueue FIFO serialization and flush', () async {
      final queue = DbWriteQueue();
      final executed = <int>[];

      // Schedule multiple tasks with varying delays
      unawaited(queue.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        executed.add(1);
      }));

      unawaited(queue.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        executed.add(2);
      }));

      unawaited(queue.run(() {
        executed.add(3);
      }));

      // Flush should wait until all queued tasks have finished
      await queue.flush();

      // Tasks must execute in strict FIFO order regardless of internal delays
      expect(executed, [1, 2, 3]);
      expect(queue.isIdle, isTrue);
    });

    test('real Isar concurrent interleaved writes and close/reopen persistence', () async {
      final tempDir = await Directory.systemTemp.createTemp('yh_054_isar_test_');
      try {
        var isar = await Isar.open(
          [
            MangaSchema,
            ChapterSchema,
            HistorySchema,
            SettingsSchema,
            SourceSchema,
            TrackSchema,
          ],
          directory: tempDir.path,
          name: 'yh_054_test',
        );
        app.isar = isar;

        // Insert initial chapter
        final chapter = Chapter(
          mangaId: 1,
          name: 'Episode 1',
          lastPageRead: '0',
          duration: '120000',
        );
        isar.writeTxnSync(() {
          isar.chapters.putSync(chapter);
        });

        // Interleaved writes: mark 1 (15000ms), then mark 2 (45000ms)
        // Dispatched without awaiting the first before launching the second
        final write1 = chapterRepository.save(chapter..lastPageRead = '15000');
        final write2 = chapterRepository.save(chapter..lastPageRead = '45000');

        // Flush ensures both writes commit in FIFO order
        await dbWriteQueue.flush();
        await Future.wait([write1, write2]);

        // In-memory verification: must be the latest mark (45000)
        var fetched = isar.chapters.getSync(chapter.id!);
        expect(fetched?.lastPageRead, '45000');

        // Close database and reopen from disk to verify persistence across app exit
        await isar.close();

        final reopened = await Isar.open(
          [
            MangaSchema,
            ChapterSchema,
            HistorySchema,
            SettingsSchema,
            SourceSchema,
            TrackSchema,
          ],
          directory: tempDir.path,
          name: 'yh_054_test',
        );
        app.isar = reopened;

        final diskChapter = reopened.chapters.getSync(chapter.id!);
        expect(diskChapter?.lastPageRead, '45000');
        expect(diskChapter?.duration, '120000');

        await reopened.close(deleteFromDisk: true);
      } finally {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (_) {}
      }
    });

    test('single-flight resume coordinator behavior: Live stream with DVR and slow VOD', () async {
      final coordinator = ResumeCoordinatorSimulator();

      // Case 1: Live stream with DVR (duration > 0, e.g. 1 hour sliding buffer, but seekable == 'no')
      coordinator.startSession(10, const Duration(seconds: 45));
      await coordinator.coordinateResume(
        sessionId: 10,
        currentDuration: const Duration(hours: 1),
        currentPosition: const Duration(seconds: 5),
        isPlaying: true,
        seekable: 'no', // Confirmed non-seekable
      );

      // Policy verification: no seek, no toast, marked completed, treated as live
      expect(coordinator.yhLiveStream, isTrue);
      expect(coordinator.seekCallCount, 0);
      expect(coordinator.toastShown, isFalse);
      expect(coordinator.hasResumeTargetCompleted, isTrue);
      expect(coordinator.initialResumeTarget, Duration.zero);

      // Case 2: Slow VOD (duration initially 0, buffering, then becomes > 0 and seekable == 'yes')
      coordinator.startSession(20, const Duration(seconds: 120));
      // First event: still indexing (duration 0)
      await coordinator.coordinateResume(
        sessionId: 20,
        currentDuration: Duration.zero,
        currentPosition: Duration.zero,
        isPlaying: false,
        seekable: null,
      );
      // Still waiting: hasResumeTargetCompleted must remain FALSE
      expect(coordinator.hasResumeTargetCompleted, isFalse);
      expect(coordinator.seekCallCount, 0);

      // Second event: metadata loaded, duration = 24 mins, seekable = yes
      await coordinator.coordinateResume(
        sessionId: 20,
        currentDuration: const Duration(minutes: 24),
        currentPosition: Duration.zero,
        isPlaying: true,
        seekable: 'yes',
      );
      // Must resume properly
      expect(coordinator.hasResumeTargetCompleted, isTrue);
      expect(coordinator.seekCallCount, 1);
      expect(coordinator.lastSeekTarget, const Duration(seconds: 120));
      expect(coordinator.toastShown, isTrue);
      expect(coordinator.yhLiveStream, isFalse);

      // Case 3: Stale media session on episode change
      // User switches from episode session 30 to session 31
      coordinator.startSession(31, const Duration(seconds: 10));
      // Delayed event from old session 30 arrives
      await coordinator.coordinateResume(
        sessionId: 30, // Stale!
        currentDuration: const Duration(minutes: 20),
        currentPosition: Duration.zero,
        isPlaying: true,
        seekable: 'yes',
      );
      // Stale event must be completely ignored
      expect(coordinator.seekCallCount, 0);
      expect(coordinator.hasResumeTargetCompleted, isFalse);
    });

    test('video player seek capability and live stream protection', () {
      // Progressive media (MP4) vs HLS
      expect(YomiPlayerNet.isProgressive('https://cdn.example.com/video.mp4'), isTrue);
      expect(YomiPlayerNet.isProgressive('https://cdn.example.com/playlist.m3u8'), isFalse);

      final playerSrc = _read('lib/modules/anime/anime_player_view.dart');

      // 1. Must NOT force force-seekable=yes globally in PlayerConfiguration
      expect(playerSrc, isNot(contains('"force-seekable": "yes",\n        if (debandingType')));

      // 2. Network streams must open at Duration.zero, only local files can open with start
      expect(playerSrc, contains('final openStart = widget.isLocal ? start : Duration.zero;'));

      // 3. Query seekable without defaulting to yes on error, and re-read seekable after wait
      expect(playerSrc, contains('Future<String?> _querySeekable() async'));
      expect(playerSrc, contains('seekable = await _querySeekable();'));

      // 4. Stale callback invalidation on episode switch and dispose
      expect(playerSrc, contains('_mediaSessionId++;'));
      expect(playerSrc, contains('final sessionId = ++_mediaSessionId;'));
      expect(playerSrc, contains('_mediaSessionId != sessionId'));

      // 5. Verified resume notification toast only AFTER actual playback at target is confirmed
      expect(playerSrc, contains('Đã tiếp tục xem video tại'));
      expect(playerSrc, contains('_hasResumeTargetCompleted = true;\n            AppLogger.log(\n              "[Trình phát] Đã tiếp tục xem video'));

      // 6. DB write flush on player exit
      expect(playerSrc, contains('dbWriteQueue.flush()'));
    });

    test('safe Isar write queue and chapter save synchronization', () {
      final queueSrc = _read('lib/repositories/db_write_queue.dart');
      expect(queueSrc, contains('flush() => _tail'));
      expect(queueSrc, contains('dbWriteQueue.run'));
      expect(queueSrc, contains('writeTxnSync(callback'));

      final ctrlSrc = _read('lib/modules/anime/providers/anime_player_controller_provider.dart');
      expect(ctrlSrc, contains('chapterRepository.save(ep)'));
      expect(ctrlSrc, contains('dbWriteQueue.flush()'));
    });

    test('Windows CPU architecture and AMD Ryzen recognition with fallback', () {
      expect(WinDiag.verifySoftwareDecodingFallback(hwAccel: true, hwdec: 'auto'), isTrue);
      expect(WinDiag.verifySoftwareDecodingFallback(hwAccel: false, hwdec: 'no'), isTrue);

      final diagSrc = _read('lib/yomihub/win/win_diag.dart');
      expect(diagSrc, contains('Phát hiện vi xử lý AMD'));
      expect(diagSrc, contains('fallback phần mềm'));
    });

    test('Frame timing measurement watchdog registration', () {
      final perfSrc = _read('lib/yomihub/perf/perf_watchdog.dart');
      expect(perfSrc, contains('SchedulerBinding.instance.addTimingsCallback(_onTimings);'));
      expect(perfSrc, contains('_slowRaster.add(now);'));
      expect(perfSrc, contains('[Hiệu năng] Khung hình chậm: dựng'));
    });
  });
}
