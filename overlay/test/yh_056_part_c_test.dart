import 'dart:io';
import 'package:mangayomi/modules/anime/utils/player_lifecycle.dart';
import 'package:mangayomi/services/fetch_item_sources.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/yomihub/integrations/yomi_integrations.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/win/win_diag.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repository refresh reports successful, failed, and empty batches', () async {
    final a = Repo(name: 'a');
    final b = Repo(name: 'b');
    Future<void> fetch(Repo repo) async {
      if (repo == b) throw const FormatException();
    }
    expect(await refreshExtensionRepos([a, b], fetch), (ok: 1, failed: 1));
    expect(await refreshExtensionRepos([b], fetch), (ok: 0, failed: 1));
    expect(await refreshExtensionRepos([], fetch), (ok: 0, failed: 0));
  });

  group('Part C: WinDiag & AMD Ryzen 9 Optimization', () {
    test('the Windows player honors the software output setting', () {
      expect(shouldUseHardwareAcceleratedVideoOutput(userEnabled: false, isWindows: true), isFalse);
      expect(shouldUseHardwareAcceleratedVideoOutput(userEnabled: true, isWindows: true), isTrue);
    });

    test('AMD CPU identification flags', () {
      WinDiag.detectedCpu = 'AMD Ryzen 9 7950X 16-Core Processor';
      expect(WinDiag.isAmdCpu, isTrue);

      WinDiag.detectedCpu = '11th Gen Intel(R) Core(TM) i5-11300H';
      expect(WinDiag.isAmdCpu, isFalse);
    });
  });

  group('Part C: Backup Retention Pruning', () {
    test('pruneOldBackups deletes files exceeding maxCount', () async {
      final tempDir = await Directory.systemTemp.createTemp('yomihub_test_backup_');
      try {
        final dir = await Directory(p.join(tempDir.path, 'autobackup')).create();
        final names = [for (var i = 1; i <= 7; i++) 'yomihub_2026-11-01_09_00_0$i.123456.backup'];
        final unrelated = ['user.zip', 'mihon.backup', 'Aniyomi.backup', 'yomihub_backup_1.zip', 'yomihub_notes.txt', names.first + '.partial'];
        for (final n in [...names, ...unrelated]) {
          await File(p.join(dir.path, n)).writeAsString(n);
        }
        await pruneOldBackups(dir.path);
        expect(await dir.list().length, names.length + unrelated.length);
        for (final n in names) {
          await File(p.join(tempDir.path, n)).create();
        }
        await pruneOldBackups(tempDir.path, maxRetentionCount: 1);
        expect(await tempDir.list().where((f) => f is File).length, names.length);
        expect(await dir.list().length, names.length + unrelated.length);
        await pruneOldBackups(dir.path, maxRetentionCount: 3);
        expect(await dir.list().map((f) => p.basename(f.path)).toList(),
            unorderedEquals([...names.skip(4), ...unrelated]));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('Part C: Yomikiru Reader Enhancer', () {
    test('Keyboard navigation handles correctly', () {
      bool nextCalled = false;
      bool prevCalled = false;

      final eventNext = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      final resNext = YomikiruReaderEnhancer.handleKeyNavigation(
        event: eventNext,
        onNextPage: () => nextCalled = true,
        onPreviousPage: () => prevCalled = true,
        onFirstPage: () {},
        onLastPage: () {},
      );

      expect(resNext, equals(KeyEventResult.handled));
      expect(nextCalled, isTrue);

      final eventPrev = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      );

      final resPrev = YomikiruReaderEnhancer.handleKeyNavigation(
        event: eventPrev,
        onNextPage: () {},
        onPreviousPage: () => prevCalled = true,
        onFirstPage: () {},
        onLastPage: () {},
      );

      expect(resPrev, equals(KeyEventResult.handled));
      expect(prevCalled, isTrue);
    });

    test('BoxFit mapping reflects fitMode', () {
      expect(YomikiruReaderEnhancer.getBoxFit('width'), equals(BoxFit.fitWidth));
      expect(YomikiruReaderEnhancer.getBoxFit('height'), equals(BoxFit.fitHeight));
      expect(YomikiruReaderEnhancer.getBoxFit('original'), equals(BoxFit.none));
      expect(YomikiruReaderEnhancer.getBoxFit('smart'), equals(BoxFit.contain));
    });
  });

  group('Part C: Yomihon Novel Enhancer', () {
    test('Reading time estimation accurately computes minutes', () {
      // 500 words at 250 wpm = 2 minutes
      final words500 = List.generate(500, (i) => 'word$i').join(' ');
      final duration = YomihonNovelEnhancer.estimateReadingTime(words500, wpm: 250);
      expect(duration.inMinutes, equals(2));

      final formatted = YomihonNovelEnhancer.formatReadingTime(duration);
      expect(formatted, contains('2 phút'));
    });

    test('Typography preset applies proper line heights', () {
      const base = TextStyle(fontSize: 16);
      final compact = YomihonNovelEnhancer.applyPreset(base, 'compact');
      final standard = YomihonNovelEnhancer.applyPreset(base, 'standard');
      final relaxed = YomihonNovelEnhancer.applyPreset(base, 'relaxed');

      expect(compact.height, equals(1.4));
      expect(standard.height, equals(1.65));
      expect(relaxed.height, equals(2.0));
    });
  });

  group('Part C: Zenshin Anime Tracker', () {
    test('Smart episode number parsing handles diverse naming patterns', () {
      expect(ZenshinAnimeTracker.parseEpisodeNumber('[SubsPlease] Frieren - 04 (1080p).mkv'), equals(4));
      expect(ZenshinAnimeTracker.parseEpisodeNumber('One Piece Episode 1092 [Vietsub]'), equals(1092));
      expect(ZenshinAnimeTracker.parseEpisodeNumber('Attack on Titan - Tập 15'), equals(15));
      expect(ZenshinAnimeTracker.parseEpisodeNumber('Bleach TYBW [08]'), equals(8));
      expect(ZenshinAnimeTracker.parseEpisodeNumber('Mob Psycho 100 - 05'), 5);
      expect(ZenshinAnimeTracker.parseEpisodeNumber('Series One 100 - 05'), 5);
      expect(ZenshinAnimeTracker.parseEpisodeNumber('Show S02E07'), 7);
      expect(ZenshinAnimeTracker.parseEpisodeNumber('#25 - Grand Finale'), equals(25));
    });

    test('Watch threshold triggers at >= 85%', () {
      const total = Duration(minutes: 24);
      const pos80 = Duration(minutes: 19, seconds: 10); // ~79.8%
      const pos86 = Duration(minutes: 21); // ~87.5%

      expect(ZenshinAnimeTracker.hasReachedWatchThreshold(pos80, total), isFalse);
      expect(ZenshinAnimeTracker.hasReachedWatchThreshold(pos86, total), isTrue);
    });

    test('Title matching confidence scores', () {
      expect(
        ZenshinAnimeTracker.calculateTitleMatchConfidence('Sousou no Frieren', 'Sousou no Frieren'),
        equals(1.0),
      );
      expect(
        ZenshinAnimeTracker.calculateTitleMatchConfidence('[1080p] Sousou no Frieren', 'Sousou no Frieren'),
        greaterThan(0.8),
      );
    });
  });

  group('Part C: Nyora Data Bridge', () {
    test('Parses Nyora JSON manifest successfully', () {
      const jsonStr = '''
      {
        "sources": [
          {
            "id": "nyora_test_source",
            "name": "Test Source",
            "baseUrl": "https://example.com",
            "lang": "vi",
            "version": "1.2.0",
            "isNsfw": false
          }
        ]
      }
      ''';

      final sources = NyoraDataBridge.parseRepositoryManifest(jsonStr);
      expect(sources.length, equals(1));
      expect(sources.first.id, equals('nyora_test_source'));
      expect(sources.first.name, equals('Test Source'));
      expect(sources.first.version, equals('1.2.0'));
    });
  });

  group('Part C: Nuvio Media Hub', () {
    test('Delta calculations are bounded and responsive', () {
      // 70px drag up on 700px screen = +0.14
      final volUp = NuvioMediaHub.computeVolumeDelta(-70, 700);
      expect(volUp, closeTo(0.14, 0.02));

      // Drag down = negative delta
      final volDown = NuvioMediaHub.computeVolumeDelta(70, 700);
      expect(volDown, closeTo(-0.14, 0.02));
    });

    test('Optimal PIP aspect ratio stays within Android limits', () {
      expect(NuvioMediaHub.getOptimalPipAspectRatio(1920, 1080), closeTo(1.77, 0.02));
      // Extreme ratios are clamped to 0.42 .. 2.39
      expect(NuvioMediaHub.getOptimalPipAspectRatio(10000, 100), equals(2.39));
      expect(NuvioMediaHub.getOptimalPipAspectRatio(100, 10000), equals(0.42));
    });
  });

  group('Part C: Gif Viewer Controller', () {
    test('Frame stepping and reverse controls behave predictably', () {
      final ctrl = GifViewerController(totalFrames: 10, autoPlay: false);
      expect(ctrl.currentFrame, equals(0));

      ctrl.stepForward();
      expect(ctrl.currentFrame, equals(1));

      ctrl.stepBackward();
      expect(ctrl.currentFrame, equals(0));

      // Loop backward to last frame
      ctrl.stepBackward();
      expect(ctrl.currentFrame, equals(9));

      // Reverse direction
      ctrl.setReverse(true);
      expect(ctrl.isReverse, isTrue);
      ctrl.advanceFrame();
      expect(ctrl.currentFrame, equals(8));
    });

    test('Speed adjustments persist', () {
      final ctrl = GifViewerController(totalFrames: 5);
      ctrl.setSpeed(2.0);
      expect(ctrl.playbackSpeed, equals(2.0));
    });
  });

  group('Part C: Integration Audit Table', () {
    test('Audit table contains all 6 required projects with explicit rationale', () {
      final table = YomiIntegrations.integrationAuditTable;
      expect(table.length, equals(6));

      final names = table.map((m) => m['project']).toList();
      expect(names, containsAll(['Yomikiru', 'Yomihon', 'Zenshin', 'Nyora', 'Nuvio', 'GIF Viewer']));

      for (final item in table) {
        expect(item['taken']!.isNotEmpty, isTrue);
        expect(item['notTaken']!.isNotEmpty, isTrue);
        expect(item['reason']!.isNotEmpty, isTrue);
      }
    });
  });
}
