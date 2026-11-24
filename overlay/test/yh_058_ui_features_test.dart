// YomiHub 0.5.8 - UI Features Test Suite:
//   1) Loading screen animation (5 seconds duration, rounded logo, smooth morph animation from square to circle)
//   2) Mangayomi New Version UI theme integration with toggle between YomiHub Old Version and New Version
//   3) Local Folders in Downloads allowing multiple distinct folders
//   4) Booru search history and settings included in App Backup/Restore
//   5) Widget Merging settings consolidation
//   6) i18n audit across 18 languages in assets/yomihub_i18n/*.json
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/library/providers/file_scanner.dart';
import 'package:mangayomi/modules/library/widgets/library_entry_utils.dart';
import 'package:mangayomi/yomihub/backup/yomi_backup_extras.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/booru/booru_store.dart';
import 'package:mangayomi/yomihub/library/local_folders.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/splash/yomi_splash.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori.dart';
import 'package:mangayomi/yomihub/ui/ui_style.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('yomihub-058-ui-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tempDir.path,
        );
    await YomiPrefs.open();
    await BooruStore.instance.init();
  });

  tearDownAll(() async {
    YomiUi.debugOverride = null;
    try {
      await Hive.close();
    } catch (_) {}
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  tearDown(() {
    YomiUi.debugOverride = null;
  });

  group('Domain 1: Loading screen animation', () {
    test('Splash duration is exactly 5 seconds', () {
      expect(YomiSplash.total, equals(const Duration(milliseconds: 5000)));
    });

    test('Morph radius transitions smoothly from square (r=0) to full circle (r=size/2)', () {
      const size = 132.0;
      const expectedCircleRadius = size / 2; // 66.0

      // Before morph starts (t <= 0.05), radius is sharp square (0.0)
      expect(YomiSplash.morphRadius(0.0, size), equals(0.0));
      expect(YomiSplash.morphRadius(0.05, size), equals(0.0));

      // During morph (0.05 < t < 0.35), radius increases smoothly
      final rMid = YomiSplash.morphRadius(0.20, size);
      expect(rMid, greaterThan(0.0));
      expect(rMid, lessThan(expectedCircleRadius));

      // Monotonically increasing curve
      final r1 = YomiSplash.morphRadius(0.10, size);
      final r2 = YomiSplash.morphRadius(0.20, size);
      final r3 = YomiSplash.morphRadius(0.30, size);
      expect(r1, lessThan(r2));
      expect(r2, lessThan(r3));

      // After morph ends (t >= 0.35), radius is full circle / rounded logo (66.0)
      expect(YomiSplash.morphRadius(0.35, size), equals(expectedCircleRadius));
      expect(YomiSplash.morphRadius(0.50, size), equals(expectedCircleRadius));
      expect(YomiSplash.morphRadius(0.85, size), equals(expectedCircleRadius));
      expect(YomiSplash.morphRadius(1.0, size), equals(expectedCircleRadius));
    });

    testWidgets('YomiSplash builds correctly with child and animation controller', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YomiSplash(
              child: Text('Underlying App Content'),
            ),
          ),
        ),
      );

      // Underlying content is mounted and present in the widget tree
      expect(find.text('Underlying App Content'), findsOneWidget);

      // Mark ready completes cleanly
      YomiSplash.markReady();
      expect(YomiSplash.ready.isCompleted, isTrue);
    });
  });

  group('Domain 2: Mangayomi New Version UI theme integration and toggle', () {
    test('Toggle between Old Version (classic) and New Version (modern)', () async {
      // Classic mode
      YomiUi.debugOverride = YomiUiStyle.classic;
      expect(YomiUi.isModern, isFalse);
      expect(YomiUi.style, equals(YomiUiStyle.classic));

      // Modern mode
      YomiUi.debugOverride = YomiUiStyle.modern;
      expect(YomiUi.isModern, isTrue);
      expect(YomiUi.style, equals(YomiUiStyle.modern));

      // Parsing strings
      expect(YomiUi.parse('classic'), equals(YomiUiStyle.classic));
      expect(YomiUi.parse('modern'), equals(YomiUiStyle.modern));
      expect(YomiUi.parse('mangayomiV2'), equals(YomiUiStyle.mangayomiV2));
      expect(YomiUi.parse('unknown'), equals(YomiUiStyle.classic));
      expect(YomiUi.parse(null), equals(YomiUiStyle.classic));
    });

    testWidgets('YomiUiStyleTile renders toggle switch with Old (Cũ) and New (Mới) options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YomiUiStyleTile(),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('yomiUiStyleSwitch')), findsOneWidget);
      // 0.6.2: Old / Shiori (0.9.95) / New Version (Mangayomi 0.9.96)
      expect(find.text('YomiHub Old Version'), findsOneWidget);
      expect(find.text('Shiori (0.9.95)'), findsOneWidget);
      expect(find.text('YomiHub New Version'), findsOneWidget);
    });

    testWidgets('ShioriSectionHeader and ShioriCard adapt to theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const ShioriSectionHeader(
                    title: 'Section Title',
                    subtitle: 'Section Subtitle',
                    badgeText: 'Badge',
                  ),
                  ShioriCard(
                    child: const Text('Card Inner Text'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Section Subtitle'), findsOneWidget);
      expect(find.text('Badge'), findsOneWidget);
      expect(find.text('Card Inner Text'), findsOneWidget);
    });

    testWidgets('Cover and Badge adapt between Classic and Modern styles', (tester) async {
      // Classic
      YomiUi.debugOverride = YomiUiStyle.classic;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EntryBadgeChip(label: 'CustomChip'),
          ),
        ),
      );
      expect(find.byType(ShioriBadge), findsNothing);
      expect(find.text('CustomChip'), findsOneWidget);

      // Modern
      YomiUi.debugOverride = YomiUiStyle.modern;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EntryBadgeChip(label: 'CustomChip'),
          ),
        ),
      );
      expect(find.byType(ShioriBadge), findsOneWidget);
      expect(find.text('CustomChip'), findsOneWidget);
    });
  });

  group('Domain 3: Local Folders in Downloads allowing multiple distinct folders', () {
    test('Multiple distinct local folders can be validated and added', () {
      final existing = [
        LocalFolder(name: 'Folder A', path: '/storage/emulated/0/Mangas/FolderA'),
        LocalFolder(name: 'Folder B', path: '/storage/emulated/0/Mangas/FolderB'),
      ];

      // Exact duplicate path rejected
      final errDup = YomiLocalFolders.validateNew(
        '/storage/emulated/0/Mangas/FolderA',
        existing,
      );
      expect(errDup, isNotNull);
      expect(errDup, contains('đã có trong danh sách'));

      // Nested subfolder rejected
      final errSub = YomiLocalFolders.validateNew(
        '/storage/emulated/0/Mangas/FolderA/SubDir',
        existing,
      );
      expect(errSub, isNotNull);
      expect(errSub, contains('nằm bên trong'));

      // Parent containing existing folder rejected
      final errParent = YomiLocalFolders.validateNew(
        '/storage/emulated/0/Mangas',
        existing,
      );
      expect(errParent, isNotNull);
      expect(errParent, contains('chứa'));

      // Distinct, non-overlapping folder allowed
      final errOk = YomiLocalFolders.validateNew(
        '/storage/emulated/0/Mangas/FolderC',
        existing,
      );
      expect(errOk, isNull);

      final errDifferentRoot = YomiLocalFolders.validateNew(
        '/sdcard/Downloads/AnimeLocal',
        existing,
      );
      expect(errDifferentRoot, isNull);
    });

    test('Path normalization and disk space formatting', () {
      expect(YomiLocalFolders.formatBytes(500), equals('500 B'));
      expect(YomiLocalFolders.formatBytes(2048), equals('2.0 KB'));
      expect(YomiLocalFolders.formatBytes(1024 * 1024 * 15), equals('15.0 MB'));
      expect(YomiLocalFolders.formatBytes(1024 * 1024 * 1024 * 3), equals('3.0 GB'));

      expect(localFolderPathKey('/storage/emulated/0/local/'), equals('/storage/emulated/0/local'));
      expect(localFolderPathKey('C:\\Downloads\\Local\\\\'),
          equals(Platform.isWindows ? 'c:/downloads/local' : 'C:/Downloads/Local'));
    });
  });

  group('Domain 4: Booru search history and settings in App Backup/Restore', () {
    test('BooruStore manages search history and settings in Hive', () async {
      final store = BooruStore.instance;

      // Add search history
      await store.addHistory('hatsune_miku');
      await store.addHistory('landscape');
      expect(store.history, contains('hatsune_miku'));
      expect(store.history, contains('landscape'));
      expect(store.history.first, equals('landscape')); // most recent first

      // Configure settings
      await store.setColumns(4);
      expect(store.columns, equals(4));

      await store.setFullQuality(true);
      expect(store.fullQuality, isTrue);

      await store.setAutoplayVideo(false);
      expect(store.autoplayVideo, isFalse);

      await store.setBlacklist(['guro', 'spoiler']);
      expect(store.blacklist, contains('guro'));
      expect(store.blacklist, contains('spoiler'));

      // Toggle favorite
      final post = BooruPost(
        id: 9999,
        siteId: 'danbooru',
        previewUrl: 'https://example.com/thumb.jpg',
        sampleUrl: 'https://example.com/sample.jpg',
        fileUrl: 'https://example.com/file.jpg',
        width: 1920,
        height: 1080,
        tags: ['scenery', 'night'],
        rating: BooruRating.general,
        score: 42,
        source: 'https://example.com',
        postUrl: 'https://example.com/posts/9999',
      );
      await store.toggleFavourite(post);
      expect(store.isFavourite(post), isTrue);
      expect(store.favourites.any((p) => p.id == 9999), isTrue);
    });

    test('YomiBackupExtras collects and restores Booru search history and settings', () async {
      // 1. Collect backup extras
      final collected = await YomiBackupExtras.collect(
        hasExtensions: true,
        hasExtensionPrefs: true,
        includeSensitive: true,
      );

      final boxes = collected['boxes'] as Map<String, dynamic>;
      expect(boxes.containsKey('yomihub_booru'), isTrue);

      final booruData = boxes['yomihub_booru'] as Map<String, dynamic>;
      expect(booruData.containsKey('history'), isTrue);
      expect(booruData.containsKey('columns'), isTrue);
      expect(booruData.containsKey('fullQuality'), isTrue);
      expect(booruData.containsKey('blacklist'), isTrue);
      expect(booruData.containsKey('favourites'), isTrue);

      final historyList = (booruData['history'] as List).cast<String>();
      expect(historyList, contains('hatsune_miku'));
      expect(historyList, contains('landscape'));
      expect(booruData['columns'], equals(4));
      expect(booruData['fullQuality'], isTrue);

      // 2. Clear history and modify settings to simulate empty / reset state
      await BooruStore.instance.clearHistory();
      expect(BooruStore.instance.history, isEmpty);
      await BooruStore.instance.setColumns(2);
      expect(BooruStore.instance.columns, equals(2));

      // 3. Restore backup extras
      await YomiBackupExtras.restore(collected);

      // 4. Verify Booru search history and settings are restored!
      expect(BooruStore.instance.history, contains('hatsune_miku'));
      expect(BooruStore.instance.history, contains('landscape'));
      expect(BooruStore.instance.columns, equals(4));
      expect(BooruStore.instance.fullQuality, isTrue);
      expect(BooruStore.instance.blacklist, contains('guro'));
      expect(BooruStore.instance.blacklist, contains('spoiler'));
    });
  });

  group('Domain 5: Widget Merging settings consolidation', () {
    test('ExtensionMergeScreen consolidates all merge tools and group management', () {
      final code = _read('lib/yomihub/merge/extension_merge_screen.dart');

      // Consolidated actions and tools
      expect(code, contains('CustomMergeSourcesTile()'));
      // 0.6.5: series tools moved to "Hợp Nhất Các Bộ" (content_merge_screen)
      final series = _read('lib/yomihub/merge/content_merge_screen.dart');
      expect(series, contains('MergeDuplicateMangaTile()'));
      expect(series, contains('ManualMergeMangaTile()'));
      expect(code, contains("context.push('/contentMerge')"));
      expect(code, contains("ValueKey('mergeTools')"));
      expect(code, contains('Tự chọn các tiện ích để hợp nhất'));

      // Shiori styling connected when modern UI is active
      expect(code, contains('ShioriSectionHeader'));
      expect(code, contains('ShioriShape.card'));
      expect(code, contains('YomiUi.isModern'));
    });

    test('Data & Storage contains single consolidated entry to mergeExtensions', () {
      final dataStorageCode = _read('lib/modules/more/data_and_storage/data_and_storage.dart');

      // Merging shortcut present
      expect(dataStorageCode, contains("context.push('/mergeExtensions')"));
      expect(dataStorageCode, contains('Hợp Nhất Tiện Ích'));

      // Individual merge tiles are consolidated away from Data & Storage
      expect(dataStorageCode, isNot(contains('CustomMergeSourcesTile()')));
      expect(dataStorageCode, isNot(contains('MergeDuplicateMangaTile()')));
      expect(dataStorageCode, isNot(contains('ManualMergeMangaTile()')));
    });
  });

  group('Domain 6: i18n audit across 18 languages', () {
    test('All 18 language translation files exist and have identical symmetric keys', () {
      const i18nPath = 'assets/yomihub_i18n';
      const expectedLangs = [
        'ar.json', 'as.json', 'de.json', 'en.json', 'es.json', 'es_419.json',
        'fr.json', 'hi.json', 'id.json', 'it.json', 'ja.json', 'ko.json',
        'pt.json', 'pt_BR.json', 'ru.json', 'th.json', 'tr.json', 'zh.json',
      ];

      expect(expectedLangs.length, equals(18));

      final enRaw = File('$i18nPath/en.json').readAsStringSync();
      final enMap = jsonDecode(enRaw) as Map<String, dynamic>;
      final enKeys = enMap.keys.toSet();

      expect(enKeys.length, greaterThanOrEqualTo(1645));

      for (final langFile in expectedLangs) {
        final f = File('$i18nPath/$langFile');
        expect(f.existsSync(), isTrue, reason: '$langFile must exist');
        final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect(map.keys.length, equals(enKeys.length),
            reason: '$langFile key count (${map.keys.length}) must match en.json (${enKeys.length})');
        expect(map.keys.toSet().difference(enKeys), isEmpty,
            reason: '$langFile has keys not in en.json');
        expect(enKeys.difference(map.keys.toSet()), isEmpty,
            reason: '$langFile is missing keys from en.json');
      }
    });

    test('All static tr() calls in overlay/lib exist in en.json', () {
      final enRaw = File('assets/yomihub_i18n/en.json').readAsStringSync();
      final enMap = jsonDecode(enRaw) as Map<String, dynamic>;

      final re = RegExp(r"""\btr\(\s*'((?:[^'\\\n]|\\.)*)'""");
      final missing = <String>[];

      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        for (final m in re.allMatches(f.readAsStringSync())) {
          var v = m.group(1)!;
          if (v.replaceAll(r'\$', '').contains(r'$')) continue;
          v = v.replaceAll(r"\'", "'").replaceAll(r'\n', '\n').replaceAll(r'\$', r'$');
          if (!enMap.containsKey(v)) missing.add(v);
        }
      }

      expect(missing, isEmpty, reason: 'Missing translation keys:\n${missing.take(10).join('\n')}');
    });
  });
}
