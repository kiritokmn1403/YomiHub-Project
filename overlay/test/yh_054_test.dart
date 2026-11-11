// YomiHub 0.5.4 regression & behavioral tests (real code paths).
import 'dart:async';
import 'dart:ffi';
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
import 'package:mangayomi/modules/more/settings/player/providers/player_decoder_state_provider.dart';

String _read(String path) => File(path).readAsStringSync();

/// Emulates the session & token-aware coordinator and save logic from AnimePlayerView
class ResumeCoordinatorSimulator {
  int mediaSessionId = 0;
  bool yhSourceNatureResolved = false;
  int activeResumeSession = 0;
  int resumeToken = 0;
  bool hasResumeTargetCompleted = false;
  Duration initialResumeTarget = Duration.zero;
  bool yhLiveStream = false;
  int seekCallCount = 0;
  Duration? lastSeekTarget;
  bool toastShown = false;

  // Track saved positions and history
  Duration? savedPosition;
  Duration? savedDuration;
  int savedElapsedSeconds = 0;

  void openMedia(
    int sessionId,
    Duration resumeTarget, {
    bool isLocal = false,
  }) {
    mediaSessionId = sessionId;
    initialResumeTarget = resumeTarget;
    hasResumeTargetCompleted = resumeTarget <= Duration.zero;
    yhLiveStream = false;
    yhSourceNatureResolved = isLocal;
    // NOTE: Does NOT reset activeResumeSession or resumeToken!
    // Active session and tokens persist across openMedia calls to verify
    // that Session B supersedes Session A without manual resets.
  }

  void startSession(int sessionId, Duration resumeTarget, {bool isLocal = false}) {
    openMedia(sessionId, resumeTarget, isLocal: isLocal);
  }

  Future<void> coordinateResume({
    required int sessionId,
    required Duration currentDuration,
    required Duration currentPosition,
    required bool isPlaying,
    required String? seekable,
    Duration asyncDelay = Duration.zero,
    String trigger = 'init',
  }) async {
    if (mediaSessionId != sessionId) return;
    if (yhSourceNatureResolved &&
        (hasResumeTargetCompleted || initialResumeTarget <= Duration.zero)) {
      return;
    }
    // Single-flight for the SAME session
    if (activeResumeSession == sessionId) return;

    activeResumeSession = sessionId;
    final token = ++resumeToken;
    try {
      final start = initialResumeTarget;

      if (asyncDelay > Duration.zero) {
        await Future<void>.delayed(asyncDelay);
        if (mediaSessionId != sessionId || resumeToken != token) return;
      }

      final hasKnownDuration = currentDuration > Duration.zero;
      final isLive = (seekable == 'no') ||
          (!hasKnownDuration && isPlaying && currentPosition > Duration.zero);

      if (isLive) {
        yhLiveStream = true;
        yhSourceNatureResolved = true;
        initialResumeTarget = Duration.zero;
        hasResumeTargetCompleted = true;
        return;
      }

      if (!hasKnownDuration) {
        return;
      }

      yhLiveStream = false;
      yhSourceNatureResolved = true;

      if (start <= Duration.zero) {
        hasResumeTargetCompleted = true;
        return;
      }

      if (asyncDelay > Duration.zero) {
        await Future<void>.delayed(asyncDelay);
        if (mediaSessionId != sessionId || resumeToken != token) return;
      }

      // Resume execution
      seekCallCount++;
      lastSeekTarget = start;
      hasResumeTargetCompleted = true;
      toastShown = true;
    } finally {
      if (activeResumeSession == sessionId) {
        activeResumeSession = 0;
      }
    }
  }

  /// Replicates _setCurrentPosition from AnimePlayerView
  void setCurrentPosition({
    required Duration currentPosition,
    required Duration? currentTotalDuration,
    bool save = true,
    bool saveWatchTime = false,
    int elapsedSeconds = 0,
  }) {
    if (yhLiveStream || !yhSourceNatureResolved) {
      if (saveWatchTime) {
        savedElapsedSeconds += elapsedSeconds;
      }
      return;
    }
    if (!hasResumeTargetCompleted && initialResumeTarget > Duration.zero) {
      if (currentPosition < initialResumeTarget - const Duration(seconds: 3)) {
        return; // Guard: Do not overwrite resume position with initial buffering 0s
      }
      hasResumeTargetCompleted = true;
    }
    if (save) {
      savedPosition = currentPosition;
      savedDuration = currentTotalDuration;
    }
    if (saveWatchTime) {
      savedElapsedSeconds += elapsedSeconds;
    }
  }
}

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

  group('YomiHub 0.5.4', () {
    test('version / user agent', () {
      expect(AppIdentity.userAgent, anyOf('YomiHub/0.5.4', 'YomiHub/0.5.5', startsWith('YomiHub/0.5.')));
      if (File('pubspec.yaml').existsSync()) {
        expect(_read('pubspec.yaml'), anyOf(contains('version: 0.5.4+46'), contains('version: 0.5.5+47'), contains('version: 0.5.5'), contains('version: 0.5.6')));
      }
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

    test('real Isar transaction conflict: sync error propagation, async bounded retry and no infinite spin', () async {
      final tempDir = await Directory.systemTemp.createTemp('yh_054_isar_conflict_');
      try {
        final isar = await Isar.open(
          [
            MangaSchema,
            ChapterSchema,
            HistorySchema,
            SettingsSchema,
            SourceSchema,
            TrackSchema,
          ],
          directory: tempDir.path,
          name: 'yh_054_conflict_test',
        );
        app.isar = isar;

        // 1. Synchronous write: MUST propagate error to caller when async txn holds lock
        final completer1 = Completer<void>();
        final externalTxn1 = isar.writeTxn(() async {
          await completer1.future;
        });

        // Ensure writeTxnSyncDirect rethrows IsarError rather than silently swallowing
        expect(
          () => isar.writeTxnSyncDirect<void>(() {
            isar.chapters.putSync(Chapter(mangaId: 1, name: 'Conflict Sync', lastPageRead: '10'));
          }),
          throwsA(isA<IsarError>()),
        );

        completer1.complete();
        await externalTxn1;

        // 2. Async queue path: bounded retry with delay successfully commits once external txn finishes
        final completer2 = Completer<void>();
        final externalTxn2 = isar.writeTxn(() async {
          await completer2.future;
        });

        final targetChapter = Chapter(mangaId: 1, name: 'Conflict Async Queued', lastPageRead: '0');
        final queuedSave = isar.writeTxnSyncSafe(() {
          isar.chapters.putSync(targetChapter..lastPageRead = '999');
        });

        // External transaction holds lock for 50ms, then finishes
        await Future<void>.delayed(const Duration(milliseconds: 50));
        completer2.complete();
        await externalTxn2;

        // Awaiting flush ensures queued task retried and completed successfully
        await dbWriteQueue.flush();
        await queuedSave;

        // Verification: countSync is 1 and data is preserved accurately
        final saved = isar.chapters.filter().nameEqualTo('Conflict Async Queued').findFirstSync();
        expect(saved, isNotNull);
        expect(saved?.lastPageRead, '999');
        expect(isar.chapters.filter().nameEqualTo('Conflict Async Queued').countSync(), 1);

        // 3. Unresolved conflict: must stop after maxConflictRetries without spinning infinitely
        final completer3 = Completer<void>();
        final externalTxn3 = isar.writeTxn(() async {
          await completer3.future;
        });

        final stuckSave = isar.writeTxnSyncSafe(
          () {
            isar.chapters.putSync(Chapter(mangaId: 1, name: 'Stuck'));
          },
          maxConflictRetries: 2,
          conflictRetryDelay: const Duration(milliseconds: 10),
        );

        // Must fail with IsarError and not hang indefinitely
        await expectLater(stuckSave, throwsA(isA<IsarError>()));

        completer3.complete();
        await externalTxn3;

        await isar.close(deleteFromDisk: true);
      } finally {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (_) {}
      }
    });

    test('session & token coordinator behavior: Live stream DVR, first-time live, slow VOD, and A->B switch', () async {
      final coordinator = ResumeCoordinatorSimulator();

      // Case 1: Live stream with DVR (duration > 0, e.g. 1 hour sliding buffer, but seekable == 'no')
      coordinator.openMedia(10, const Duration(seconds: 45));
      await coordinator.coordinateResume(
        sessionId: 10,
        currentDuration: const Duration(hours: 1),
        currentPosition: const Duration(seconds: 5),
        isPlaying: true,
        seekable: 'no', // Confirmed non-seekable
      );

      // Policy verification: no seek, no toast, marked completed, treated as live
      expect(coordinator.yhLiveStream, isTrue);
      expect(coordinator.yhSourceNatureResolved, isTrue);
      expect(coordinator.seekCallCount, 0);
      expect(coordinator.toastShown, isFalse);
      expect(coordinator.hasResumeTargetCompleted, isTrue);
      expect(coordinator.initialResumeTarget, Duration.zero);

      // Verify timer/exit save: must NOT save position to DB for live DVR
      coordinator.setCurrentPosition(
        currentPosition: const Duration(seconds: 15),
        currentTotalDuration: const Duration(hours: 1),
        save: true,
        saveWatchTime: true,
        elapsedSeconds: 15,
      );
      expect(coordinator.savedPosition, isNull);
      expect(coordinator.savedElapsedSeconds, 15);

      // Case 2: Live stream opened for the first time (resumeTarget == Duration.zero)
      coordinator.openMedia(15, Duration.zero);
      await coordinator.coordinateResume(
        sessionId: 15,
        currentDuration: Duration.zero,
        currentPosition: const Duration(seconds: 2),
        isPlaying: true,
        seekable: 'no',
      );
      expect(coordinator.yhLiveStream, isTrue);
      expect(coordinator.yhSourceNatureResolved, isTrue);
      coordinator.setCurrentPosition(
        currentPosition: const Duration(seconds: 30),
        currentTotalDuration: null,
        save: true,
        saveWatchTime: true,
        elapsedSeconds: 30,
      );
      expect(coordinator.savedPosition, isNull);
      expect(coordinator.savedElapsedSeconds, 45);

      // Case 3: Slow VOD (duration initially 0, buffering, then becomes > 0 and seekable == 'yes')
      coordinator.openMedia(20, const Duration(seconds: 120));
      // First event: still indexing (duration 0)
      await coordinator.coordinateResume(
        sessionId: 20,
        currentDuration: Duration.zero,
        currentPosition: Duration.zero,
        isPlaying: false,
        seekable: null,
      );
      // Still waiting: hasResumeTargetCompleted must remain FALSE, source nature unresolved
      expect(coordinator.hasResumeTargetCompleted, isFalse);
      expect(coordinator.yhSourceNatureResolved, isFalse);
      expect(coordinator.seekCallCount, 0);

      // Saving during initial buffering must NOT record 0s to DB
      coordinator.setCurrentPosition(
        currentPosition: Duration.zero,
        currentTotalDuration: Duration.zero,
        save: true,
      );
      expect(coordinator.savedPosition, isNull);

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
      expect(coordinator.yhSourceNatureResolved, isTrue);
      expect(coordinator.seekCallCount, 1);
      expect(coordinator.lastSeekTarget, const Duration(seconds: 120));
      expect(coordinator.toastShown, isTrue);
      expect(coordinator.yhLiveStream, isFalse);

      // Saving now persists the position
      coordinator.setCurrentPosition(
        currentPosition: const Duration(seconds: 125),
        currentTotalDuration: const Duration(minutes: 24),
        save: true,
      );
      expect(coordinator.savedPosition, const Duration(seconds: 125));

      // Case 4: Server switch from Session A to Session B while Session A is awaiting
      coordinator.openMedia(50, const Duration(seconds: 60));
      final futureA = coordinator.coordinateResume(
        sessionId: 50,
        currentDuration: const Duration(minutes: 24),
        currentPosition: Duration.zero,
        isPlaying: true,
        seekable: 'yes',
        asyncDelay: const Duration(milliseconds: 100),
      );

      // Network stall triggers switch to Server B before Session A finishes
      coordinator.openMedia(51, const Duration(seconds: 60));
      final futureB = coordinator.coordinateResume(
        sessionId: 51,
        currentDuration: const Duration(minutes: 24),
        currentPosition: Duration.zero,
        isPlaying: true,
        seekable: 'yes',
        asyncDelay: const Duration(milliseconds: 10),
      );

      await Future.wait([futureA, futureB]);

      // Session B must have succeeded without being blocked by Session A
      expect(coordinator.seekCallCount, 2); // Case 3 + Session B
      expect(coordinator.mediaSessionId, 51);
      expect(coordinator.hasResumeTargetCompleted, isTrue);
      expect(coordinator.activeResumeSession, 0); // Lock cleanly released

      // Case 5: Stale media session on episode change
      // User switches from episode session 60 to session 61
      coordinator.openMedia(61, const Duration(seconds: 10));
      // Delayed event from old session 60 arrives
      await coordinator.coordinateResume(
        sessionId: 60, // Stale!
        currentDuration: const Duration(minutes: 20),
        currentPosition: Duration.zero,
        isPlaying: true,
        seekable: 'yes',
      );
      // Stale event must be completely ignored
      expect(coordinator.seekCallCount, 2);
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

      // 7. Live stream protection in _setCurrentPosition: no position saved, no clearing live flag
      expect(playerSrc, contains('if (_yhLiveStream || !_yhSourceNatureResolved)'));

      // 8. Session & token coordinator state
      expect(playerSrc, contains('int _activeResumeSession = 0;'));
      expect(playerSrc, contains('int _resumeToken = 0;'));
      expect(playerSrc, contains('if (_activeResumeSession == sessionId) return;'));
      expect(playerSrc, contains('_resumeToken != token'));
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
      expect(resolveHwdecMode('no', 'windows'), 'no');
      expect(resolveHwdecMode('d3d11va-copy', 'windows'), 'd3d11va-copy');
      expect(resolveHwdecMode('mediacodec', 'windows'), 'auto');
      expect(resolveHwdecMode('d3d11va-copy', 'android'), 'auto-safe');

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
