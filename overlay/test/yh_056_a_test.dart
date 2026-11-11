// YomiHub 0.5.6 – Phần A (Claude Fable 5.2): U13 "Thư Viện", U12 giao diện
// Cũ / Mới. Các nhóm A3/A4 được thêm ở cuối tệp.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/models/category.dart' as mdl;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/kotatsu/kotatsu_bridge.dart';
import 'package:mangayomi/yomihub/library/library_hub.dart';
import 'package:mangayomi/yomihub/library/library_hub_bar.dart';
import 'package:mangayomi/yomihub/library/side_swipe.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/ui/ui_style.dart';

const _order = <String>[
  '/MangaLibrary',
  '/AnimeLibrary',
  '/NovelLibrary',
  '/playBooks',
  '/booru',
  '/updates',
  '/history',
  '/browse',
  '/more',
  '/trackerLibrary',
];

const _hubTabs = <LibraryHubTab>[
  LibraryHubTab(
    route: '/MangaLibrary',
    label: 'Comic',
    icon: Icons.collections_bookmark_outlined,
    selectedIcon: Icons.collections_bookmark,
  ),
  LibraryHubTab(
    route: '/AnimeLibrary',
    label: 'Film & Movie',
    icon: Icons.video_collection_outlined,
    selectedIcon: Icons.video_collection,
  ),
  LibraryHubTab(
    route: '/NovelLibrary',
    label: 'Novel',
    icon: Icons.local_library_outlined,
    selectedIcon: Icons.local_library,
  ),
  LibraryHubTab(
    route: '/playBooks',
    label: 'Play Books',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
  ),
];

void main() {
  late Directory temp;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('yomihub-056-a-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
    await YomiPrefs.open();
  });

  group('A1 / U13 – Thư Viện (Library) hub rules', () {
    test('the four libraries collapse into one entry, order kept', () {
      final nav = buildMainNav(
        order: _order,
        hidden: const ['/trackerLibrary'],
        tv: false,
        modern: false,
      );
      expect(nav, [kLibraryHubNav, '/booru', '/updates', '/browse', '/more']);
      expect(nav.where((e) => kLibraryHubRoutes.contains(e)), isEmpty);
    });

    test('the hub sits where the first library was in the user order', () {
      final nav = buildMainNav(
        order: const [
          '/updates',
          '/NovelLibrary',
          '/browse',
          '/MangaLibrary',
          '/AnimeLibrary',
          '/playBooks',
          '/more',
        ],
        hidden: const [],
        tv: false,
        modern: false,
      );
      expect(nav, ['/updates', kLibraryHubNav, '/browse', '/more']);
    });

    test('sub-tabs follow the navigation order', () {
      final tabs = libraryHubTabs(
        order: const [
          '/NovelLibrary',
          '/updates',
          '/AnimeLibrary',
          '/playBooks',
          '/MangaLibrary',
        ],
        hidden: const [],
        tv: false,
      );
      expect(tabs, [
        '/NovelLibrary',
        '/AnimeLibrary',
        '/playBooks',
        '/MangaLibrary',
      ]);
    });

    test('a feature switched off hides its tab (case-insensitive)', () {
      final tabs = libraryHubTabs(
        order: _order,
        hidden: const ['/novellibrary', '/playBooks'],
        tv: false,
      );
      expect(tabs, ['/MangaLibrary', '/AnimeLibrary']);
    });

    test('a saved order missing a library still shows its tab', () {
      final tabs = libraryHubTabs(
        order: const ['/MangaLibrary', '/AnimeLibrary', '/more'],
        hidden: const [],
        tv: false,
      );
      expect(tabs, kLibraryHubRoutes);
    });

    test('Android TV: Thư Viện keeps only Film & Movie, no Booru', () {
      final tabs = libraryHubTabs(order: _order, hidden: const [], tv: true);
      expect(tabs, ['/AnimeLibrary']);
      final nav = buildMainNav(
        order: _order,
        hidden: const ['/trackerLibrary'],
        tv: true,
        modern: false,
      );
      expect(nav, [kLibraryHubNav, '/updates', '/browse', '/more']);
      expect(nav.contains('/booru'), isFalse);
    });

    test('Android TV with Film & Movie switched off: no hub entry', () {
      final nav = buildMainNav(
        order: _order,
        hidden: const ['/AnimeLibrary'],
        tv: true,
        modern: false,
      );
      expect(nav.contains(kLibraryHubNav), isFalse);
      expect(nav.first, '/updates');
    });

    test('every library switched off: no hub entry, other tabs stay', () {
      final nav = buildMainNav(
        order: _order,
        hidden: const [...kLibraryHubRoutes],
        tv: false,
        modern: false,
      );
      expect(nav, ['/booru', '/updates', '/browse', '/more', '/trackerLibrary']);
    });

    test('location → navigation entry', () {
      const dest = [kLibraryHubNav, '/booru', '/updates', '/browse', '/more'];
      for (final r in kLibraryHubRoutes) {
        expect(navKeyForLocation(r, dest), kLibraryHubNav);
      }
      expect(navKeyForLocation('/more', dest), '/more');
      expect(navKeyForLocation('/booru', dest), '/booru');
      expect(navKeyForLocation('/updates', dest), '/updates');
      expect(navKeyForLocation(null, dest), isNull);
      // every destination index stays inside the bar
      for (final r in [...kLibraryHubRoutes, '/booru', '/updates', '/more']) {
        expect(dest.indexOf(navKeyForLocation(r, dest)!), isNonNegative);
      }
    });

    test('tapping the hub opens the last library, else the first', () {
      const tabs = ['/MangaLibrary', '/AnimeLibrary'];
      expect(libraryHubTarget(tabs, null), '/MangaLibrary');
      expect(libraryHubTarget(tabs, '/AnimeLibrary'), '/AnimeLibrary');
      expect(libraryHubTarget(tabs, '/NovelLibrary'), '/MangaLibrary');
      expect(libraryHubTarget(const [], '/AnimeLibrary'), isNull);
    });

    test('YomiLibraryHub remembers the library and resolves the entry', () {
      YomiLibraryHub.tabs = const ['/MangaLibrary', '/AnimeLibrary'];
      YomiLibraryHub.last = null;
      YomiLibraryHub.visit('/more');
      expect(YomiLibraryHub.resolve(kLibraryHubNav), '/MangaLibrary');
      YomiLibraryHub.visit('/AnimeLibrary');
      YomiLibraryHub.visit('/browse');
      expect(YomiLibraryHub.resolve(kLibraryHubNav), '/AnimeLibrary');
      expect(YomiLibraryHub.resolve('/more'), '/more');
      YomiLibraryHub.tabs = const [];
      expect(YomiLibraryHub.resolve(kLibraryHubNav), isNull);
    });

    test('strip: shown for a library only with two or more tabs', () {
      YomiLibraryHub.tabs = const ['/MangaLibrary', '/AnimeLibrary'];
      YomiLibraryHub.activity = const [];
      expect(YomiLibraryHub.stripFor('/AnimeLibrary'), [
        '/MangaLibrary',
        '/AnimeLibrary',
      ]);
      expect(YomiLibraryHub.stripFor('/more'), isEmpty);
      expect(YomiLibraryHub.stripFor('/updates'), isEmpty);
      expect(YomiLibraryHub.stripFor(null), isEmpty);
      // Android TV: a single library → no strip
      YomiLibraryHub.tabs = const ['/AnimeLibrary'];
      expect(YomiLibraryHub.stripFor('/AnimeLibrary'), isEmpty);
    });
  });

  group('A1 / U13 – LibraryHubTabBar widget', () {
    Future<List<String>> pump(
      WidgetTester tester, {
      required List<LibraryHubTab> tabs,
      String? current,
      bool pill = false,
    }) async {
      final taps = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LibraryHubTabBar(
                  tabs: tabs,
                  current: current,
                  pill: pill,
                  onSelect: taps.add,
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
      return taps;
    }

    testWidgets('shows one tab per library and reports taps', (tester) async {
      final taps = await pump(tester, tabs: _hubTabs, current: '/MangaLibrary');
      expect(find.text('Comic'), findsOneWidget);
      expect(find.text('Film & Movie'), findsOneWidget);
      expect(find.text('Novel'), findsOneWidget);
      expect(find.text('Play Books'), findsOneWidget);
      // the selected tab uses the filled icon
      expect(find.byIcon(Icons.collections_bookmark), findsOneWidget);
      expect(find.byIcon(Icons.video_collection_outlined), findsOneWidget);
      await tester.tap(find.text('Novel'));
      await tester.tap(find.byKey(const ValueKey('libraryHubTab/playBooks')));
      expect(taps, ['/NovelLibrary', '/playBooks']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a hidden feature has no tab', (tester) async {
      final visible = libraryHubTabs(
        order: _order,
        hidden: const ['/NovelLibrary', '/playBooks'],
        tv: false,
      );
      await pump(
        tester,
        tabs: _hubTabs.where((t) => visible.contains(t.route)).toList(),
        current: '/AnimeLibrary',
      );
      expect(find.text('Novel'), findsNothing);
      expect(find.text('Play Books'), findsNothing);
      expect(find.text('Comic'), findsOneWidget);
      expect(find.byIcon(Icons.video_collection), findsOneWidget);
    });

    testWidgets('D-pad: arrows move focus between tabs, select activates', (
      tester,
    ) async {
      final taps = await pump(
        tester,
        tabs: _hubTabs,
        current: '/MangaLibrary',
        pill: true,
      );
      // first traversal lands on the first tab
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, ['/AnimeLibrary']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(taps, ['/AnimeLibrary', '/playBooks']);
    });

    testWidgets('four tabs fit a narrow phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pump(tester, tabs: _hubTabs, current: '/playBooks', pill: true);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(LibraryHubTabBar)).width, 320);
    });
  });

  group('A1 / U13 – sideways swipe between libraries (Mangayomi 0.9.95)', () {
    test('neighbours of the current tab', () {
      const tabs = ['/MangaLibrary', '/AnimeLibrary', '/NovelLibrary'];
      expect(sideSwipeNeighbours(tabs, '/MangaLibrary'), (null, '/AnimeLibrary'));
      expect(
        sideSwipeNeighbours(tabs, '/AnimeLibrary'),
        ('/MangaLibrary', '/NovelLibrary'),
      );
      expect(sideSwipeNeighbours(tabs, '/NovelLibrary'), ('/AnimeLibrary', null));
      expect(sideSwipeNeighbours(tabs, '/more'), (null, null));
      expect(sideSwipeNeighbours(const [], '/MangaLibrary'), (null, null));
      expect(sideSwipeNeighbours(tabs, null), (null, null));
    });

    Future<List<String>> pump(
      WidgetTester tester,
      Widget child, {
      bool next = true,
      bool previous = true,
    }) async {
      final log = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YomiSideSwipe(
              onNext: next ? () => log.add('next') : null,
              onPrevious: previous ? () => log.add('previous') : null,
              child: child,
            ),
          ),
        ),
      );
      return log;
    }

    testWidgets('a long swipe goes to the next / previous library', (
      tester,
    ) async {
      final log = await pump(
        tester,
        const SizedBox.expand(child: ColoredBox(color: Colors.white)),
      );
      await tester.drag(find.byType(ColoredBox).last, const Offset(-200, 0));
      await tester.pump();
      expect(log, ['next']);
      await tester.drag(find.byType(ColoredBox).last, const Offset(200, 0));
      await tester.pump();
      expect(log, ['next', 'previous']);
      // a short nudge or a vertical scroll does nothing
      await tester.drag(find.byType(ColoredBox).last, const Offset(-30, 0));
      await tester.drag(find.byType(ColoredBox).last, const Offset(0, -300));
      await tester.pump();
      expect(log, ['next', 'previous']);
    });

    testWidgets('no swipe at the ends of the group', (tester) async {
      final log = await pump(
        tester,
        const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        next: false,
      );
      await tester.drag(find.byType(ColoredBox).last, const Offset(-200, 0));
      await tester.pump();
      expect(log, isEmpty);
    });

    testWidgets('category pages keep their swipe; only the pull past the last '
        'page changes library', (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);
      final log = await pump(
        tester,
        PageView(
          controller: controller,
          physics: const ClampingScrollPhysics(),
          children: const [
            Center(child: Text('category 1')),
            Center(child: Text('category 2')),
          ],
        ),
      );
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(controller.page, 1);
      expect(log, isEmpty);
      // already on the last category: pulling further asks for the next library
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(log, ['next']);
    });

    testWidgets('inactive (no callbacks): the tree is the same and nothing '
        'fires', (tester) async {
      final log = await pump(
        tester,
        const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        next: false,
        previous: false,
      );
      await tester.drag(find.byType(ColoredBox).last, const Offset(-300, 0));
      await tester.pump();
      expect(log, isEmpty);
      expect(find.byType(YomiSideSwipe), findsOneWidget);
    });
  });

  group('A2 / U12 – Giao diện ứng dụng: Cũ / Mới', () {
    test('upgraders (no stored value) get the classic layout', () async {
      await YomiPrefs.set(YomiUi.prefKey, null);
      expect(YomiUi.style, YomiUiStyle.classic);
      expect(YomiUi.isModern, isFalse);
      expect(YomiUi.parse(null), YomiUiStyle.classic);
      expect(YomiUi.parse('whatever'), YomiUiStyle.classic);
      expect(YomiUi.parse(1), YomiUiStyle.classic);
      expect(YomiUi.parse('modern'), YomiUiStyle.modern);
    });

    test('the choice is stored, notifies at once, and is part of the backup', () async {
      await YomiPrefs.set(YomiUi.prefKey, null);
      var notified = 0;
      void listener() => notified++;
      YomiPrefs.changes.addListener(listener);
      addTearDown(() => YomiPrefs.changes.removeListener(listener));

      await YomiUi.setStyle(YomiUiStyle.modern);
      expect(notified, 1);
      expect(YomiUi.style, YomiUiStyle.modern);
      // YomiPrefs.dump() is what YomiBackupExtras writes into a backup
      expect(YomiPrefs.dump()[YomiUi.prefKey], 'modern');

      await YomiUi.setStyle(YomiUiStyle.classic);
      expect(YomiPrefs.dump()[YomiUi.prefKey], 'classic');

      // restoring a backup brings the choice back
      await YomiPrefs.restore({YomiUi.prefKey: 'modern'});
      expect(YomiUi.style, YomiUiStyle.modern);
      await YomiPrefs.set(YomiUi.prefKey, null);
      expect(YomiUi.style, YomiUiStyle.classic);
    });

    test('classic: no History tab; modern: Updates + History → Activity', () {
      final classic = buildMainNav(
        order: _order,
        hidden: const ['/trackerLibrary'],
        tv: false,
        modern: false,
      );
      final modern = buildMainNav(
        order: _order,
        hidden: const ['/trackerLibrary'],
        tv: false,
        modern: true,
      );
      expect(classic, [kLibraryHubNav, '/booru', '/updates', '/browse', '/more']);
      expect(modern, [kLibraryHubNav, '/booru', kActivityNav, '/browse', '/more']);
      expect(navKeyForLocation('/history', modern), kActivityNav);
      expect(navKeyForLocation('/updates', modern), kActivityNav);
      // classic: History is opened from "More" and is not on the bar
      expect(navKeyForLocation('/history', classic), '/history');
      expect(classic.contains('/history'), isFalse);
    });

    test('modern: a group needs two visible members (Mangayomi rule)', () {
      // History switched off → Updates keeps its own entry
      expect(
        buildMainNav(
          order: _order,
          hidden: const ['/history', '/trackerLibrary'],
          tv: false,
          modern: true,
        ),
        [kLibraryHubNav, '/booru', '/updates', '/browse', '/more'],
      );
      expect(
        activityTabs(
          order: _order,
          hidden: const ['/updates'],
          tv: false,
          modern: true,
        ),
        isEmpty,
      );
      expect(
        activityTabs(order: _order, hidden: const [], tv: false, modern: true),
        ['/updates', '/history'],
      );
      // classic layout and Android TV never group Updates + History
      expect(
        activityTabs(order: _order, hidden: const [], tv: false, modern: false),
        isEmpty,
      );
      expect(
        activityTabs(order: _order, hidden: const [], tv: true, modern: true),
        isEmpty,
      );
      expect(
        buildMainNav(
          order: _order,
          hidden: const ['/trackerLibrary'],
          tv: true,
          modern: true,
        ),
        [kLibraryHubNav, '/updates', '/history', '/browse', '/more'],
      );
    });

    test('modern: Activity opens the member used last and shows its strip', () {
      YomiLibraryHub.activity = const ['/updates', '/history'];
      YomiLibraryHub.lastActivity = null;
      expect(YomiLibraryHub.resolve(kActivityNav), '/updates');
      YomiLibraryHub.visit('/history');
      expect(YomiLibraryHub.resolve(kActivityNav), '/history');
      expect(YomiLibraryHub.stripFor('/history'), ['/updates', '/history']);
      YomiLibraryHub.activity = const [];
      expect(YomiLibraryHub.resolve(kActivityNav), isNull);
      expect(YomiLibraryHub.stripFor('/history'), isEmpty);
    });

    testWidgets('settings tile switches the layout without a restart', (
      tester,
    ) async {
      await tester.runAsync(() => YomiPrefs.set(YomiUi.prefKey, null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: YomiUiStyleTile())),
      );
      expect(find.text(tr('Giao diện ứng dụng')), findsOneWidget);
      expect(find.text(tr('Cũ')), findsOneWidget);
      expect(find.text(tr('Mới')), findsOneWidget);
      expect(YomiUi.style, YomiUiStyle.classic);

      await tester.tap(find.text(tr('Mới')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(YomiUi.style, YomiUiStyle.modern);
      expect(find.textContaining('Mangayomi'), findsOneWidget);

      await tester.tap(find.text(tr('Cũ')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(YomiUi.style, YomiUiStyle.classic);
      await tester.runAsync(() => YomiPrefs.set(YomiUi.prefKey, null));
    });

    test('every new text is translated into all app languages', () {
      const keys = [
        'Giao diện ứng dụng',
        'Mới – điều hướng kiểu Mangayomi 0.9.95: Cập nhật và Lịch sử gộp thành mục Hoạt động, bộ chọn tab dạng viên',
        'Cũ – bố cục YomiHub: Lịch sử nằm trong Thêm, tab con của Thư Viện ở phía trên',
        'Cũ',
        'Mới',
        'Hoạt động',
      ];
      for (final lang in YomiTr.languages) {
        final file = File('assets/yomihub_i18n/$lang.json');
        expect(file.existsSync(), isTrue, reason: lang);
        final table = Map<String, dynamic>.from(
          jsonDecode(file.readAsStringSync()) as Map,
        );
        for (final k in keys) {
          final v = table[k];
          expect(v, isA<String>(), reason: '$lang: $k');
          expect((v as String).trim(), isNotEmpty, reason: '$lang: $k');
          expect(v, isNot(k), reason: '$lang: "$k" is still Vietnamese');
        }
      }
    });

    test('R14: the "Play Books" tab label goes through tr() and exists in '
        'all app languages', () {
      final src = File('lib/modules/main_view/main_screen.dart')
          .readAsStringSync();
      expect(src, contains("tr('Play Books')"));
      expect(
        RegExp(r"(?<!tr\()'Play Books'").hasMatch(src),
        isFalse,
        reason: 'hard-coded label left in main_screen.dart',
      );
      for (final lang in YomiTr.languages) {
        final table = Map<String, dynamic>.from(
          jsonDecode(File('assets/yomihub_i18n/$lang.json').readAsStringSync())
              as Map,
        );
        final v = table['Play Books'];
        expect(v, isA<String>(), reason: lang);
        expect((v as String).trim(), isNotEmpty, reason: lang);
      }
    });
  });

  group('A3 / U5 – Kotatsu bridge health check ("Cầu nối Kotatsu chưa chạy")', () {
    late DateTime now;
    late int pings;
    late int starts;
    late bool alive;
    late bool startWorks;

    setUp(() {
      now = DateTime(2026, 11, 10, 22);
      pings = 0;
      starts = 0;
      alive = false;
      startWorks = true;
      KotatsuBridge.markDead();
      KotatsuBridge.clock = () => now;
      KotatsuBridge.pingImpl = () async {
        pings++;
        return alive;
      };
      KotatsuBridge.startImpl = () async {
        starts++;
        if (startWorks) alive = true;
        return startWorks;
      };
    });

    test('only loopback bridge URLs are intercepted', () {
      expect(
        KotatsuBridge.isBridgeUrl('http://127.0.0.1:47350/kotatsu/list?source=X'),
        isTrue,
      );
      expect(KotatsuBridge.isBridgeUrl('http://localhost:47350/kotatsu/ping'), isTrue);
      expect(KotatsuBridge.isBridgeUrl('https://example.org/kotatsu/list'), isFalse);
      expect(KotatsuBridge.isBridgeUrl('http://127.0.0.1:47351/ireader/x'), isFalse);
      expect(KotatsuBridge.isBridgeUrl(''), isFalse);
    });

    test('a bridge that does not answer is started, then trusted for a while', () async {
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      expect(starts, 1);
      expect(pings, 2); // dead, then alive after the start
      // within the TTL nothing is pinged again
      now = now.add(const Duration(seconds: 5));
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      expect(pings, 2);
      expect(starts, 1);
    });

    test('a running bridge is not restarted', () async {
      alive = true;
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      expect(starts, 0);
      expect(pings, 1);
    });

    test('after the TTL, or after a failed request, the bridge is checked again '
        'and restarted when it died', () async {
      alive = true;
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      alive = false; // the server died behind our back
      now = now.add(KotatsuBridge.aliveTtl + const Duration(seconds: 1));
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      expect(starts, 1);

      alive = false;
      KotatsuBridge.markDead(); // what a failed request does
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      expect(starts, 2);
    });

    test('concurrent callers share one restart', () async {
      final results = await Future.wait([
        KotatsuBridge.ensureAlive(),
        KotatsuBridge.ensureAlive(),
        KotatsuBridge.ensureAlive(),
      ]);
      expect(results, [true, true, true]);
      expect(starts, 1);
    });

    test('a bridge that cannot start reports false (no fake success)', () async {
      startWorks = false;
      expect(await KotatsuBridge.ensureAlive(), isFalse);
      expect(starts, 1);
      // and the next call tries again instead of caching the failure
      startWorks = true;
      expect(await KotatsuBridge.ensureAlive(), isTrue);
      expect(starts, 2);
    });
  });

  group('A4 / U10 – DbWriteQueue: detached work, nesting, no deadlock', () {
    const guard = Timeout(Duration(seconds: 20));
    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

    test('nested run inside a running task executes at once, in order', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      await q.run(() async {
        log.add('outer-start');
        expect(q.isInsideActiveTask, isTrue);
        await q.run(() async {
          log.add('inner');
          await q.run(() => log.add('inner-inner'));
        });
        log.add('outer-end');
      }).timeout(const Duration(seconds: 5));
      expect(log, ['outer-start', 'inner', 'inner-inner', 'outer-end']);
      expect(q.isIdle, isTrue);
      expect(q.isInsideActiveTask, isFalse);
      expect(q.stallCount, 0);
    }, timeout: guard);

    test('work a task left behind does not skip the queue once the task '
        'has finished (0.5.5 ran it in the middle of the next task)', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      final detachedDone = Completer<void>();

      await q.run(() async {
        log.add('A');
        // not awaited: keeps A's zone and fires while B is running
        unawaited(
          wait(30).then((_) async {
            expect(q.isInsideActiveTask, isFalse);
            await q.run(() => log.add('detached'));
            detachedDone.complete();
          }),
        );
      });
      final b = q.run(() async {
        log.add('B-start');
        await wait(150);
        log.add('B-end');
      });
      await Future.wait([b, detachedDone.future]).timeout(
        const Duration(seconds: 5),
      );
      expect(log, ['A', 'B-start', 'B-end', 'detached']);
      expect(q.stallCount, 0);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('detached work that fires while its own task still runs is nested', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      await q.run(() async {
        final side = wait(10).then((_) => q.run(() => log.add('side')));
        await wait(60);
        log.add('task-end');
        await side;
      }).timeout(const Duration(seconds: 5));
      expect(log, ['side', 'task-end']);
    }, timeout: guard);

    test('FIFO order and error isolation are unchanged', () async {
      final q = DbWriteQueue();
      final log = <int>[];
      final futures = <Future<void>>[
        q.run(() async {
          await wait(30);
          log.add(1);
        }),
        q.run(() => throw StateError('boom')),
        q.run(() => log.add(3)),
        q.run(() async {
          await wait(5);
          log.add(4);
        }),
      ];
      await expectLater(futures[1], throwsStateError);
      await Future.wait([futures[0], futures[2], futures[3]]).timeout(
        const Duration(seconds: 5),
      );
      expect(log, [1, 3, 4]);
      await q.flush().timeout(const Duration(seconds: 5));
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('no deadlock: a task that awaits a queued task is released after '
        'the stall timeout instead of hanging for ever', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(milliseconds: 200));
      final log = <String>[];
      final sw = Stopwatch()..start();
      // The outside caller is queued behind "head", and "head" waits for
      // it: a wait cycle. Without the stall timeout this never completes.
      late Future<void> outside;
      final gate = Completer<void>();
      final head = q.run(() async {
        log.add('head-start');
        await gate.future; // lets the outside caller get queued first
        await outside;
        log.add('head-end');
      });
      outside = q.run(() => log.add('outside'));
      gate.complete();
      await Future.wait([head, outside]).timeout(const Duration(seconds: 5));
      expect(log, ['head-start', 'outside', 'head-end']);
      expect(q.stallCount, 1);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(150));
      // the queue keeps working afterwards and nothing ran twice
      await q.run(() => log.add('after')).timeout(const Duration(seconds: 5));
      expect(log, ['head-start', 'outside', 'head-end', 'after']);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('a long task is not disturbed before the stall timeout', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(seconds: 2));
      final log = <String>[];
      final a = q.run(() async {
        await wait(300);
        log.add('long');
      });
      final b = q.run(() => log.add('next'));
      await Future.wait([a, b]).timeout(const Duration(seconds: 5));
      expect(log, ['long', 'next']);
      expect(q.stallCount, 0);
    }, timeout: guard);

    // ---- R15: a valid long operation is not interrupted ----

    /// Queues [n] writers that each hold a pretend transaction for [holdMs];
    /// [overlaps] counts how often two bodies ran at the same time.
    List<Future<void>> writers(
      DbWriteQueue q,
      int n,
      List<String> log,
      List<int> overlaps,
      List<int> inside, {
      int holdMs = 40,
    }) => [
      for (var i = 1; i <= n; i++)
        q.run(() async {
          if (inside[0] > 0) overlaps[0]++;
          inside[0]++;
          await wait(holdMs);
          inside[0]--;
          log.add('w$i');
        }),
    ];

    test('R15: restore-like task (one long synchronous transaction, longer '
        'than the stall timeout) – waiting writes keep their turn', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(milliseconds: 100));
      final log = <String>[];
      final overlaps = [0], inside = [0];
      final restore = q.run(() {
        // blocks the isolate like writeTxnSync does during a restore
        final sw = Stopwatch()..start();
        while (sw.elapsedMilliseconds < 400) {}
        if (inside[0] > 0) overlaps[0]++;
        log.add('restore');
      }, longRunning: true, label: 'restore');
      final ws = writers(q, 4, log, overlaps, inside);
      await Future.wait([restore, ...ws]).timeout(const Duration(seconds: 10));
      expect(log, ['restore', 'w1', 'w2', 'w3', 'w4']);
      expect(overlaps[0], 0, reason: 'a write ran inside another one');
      expect(q.stallCount, 0);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('R15: a task marked longRunning may hold the queue far beyond the '
        'stall timeout without anything being run out of turn', () async {
      final q = DbWriteQueue(
        stallTimeout: const Duration(milliseconds: 100),
        longStallTimeout: const Duration(seconds: 10),
      );
      final log = <String>[];
      final overlaps = [0], inside = [0];
      final import = q.run(() async {
        inside[0]++;
        await wait(700); // 7 × the stall timeout, no progress reported
        inside[0]--;
        log.add('import');
      }, longRunning: true, label: 'import');
      final ws = writers(q, 3, log, overlaps, inside);
      await Future.wait([import, ...ws]).timeout(const Duration(seconds: 10));
      expect(log, ['import', 'w1', 'w2', 'w3']);
      expect(overlaps[0], 0);
      expect(q.stallCount, 0);
      expect(q.extensionCount, greaterThanOrEqualTo(1));
    }, timeout: guard);

    test('R15: longRunning nested inside an ordinary task protects the '
        'surrounding task while it lasts', () async {
      final q = DbWriteQueue(
        stallTimeout: const Duration(milliseconds: 100),
        longStallTimeout: const Duration(seconds: 10),
      );
      final log = <String>[];
      final overlaps = [0], inside = [0];
      final outer = q.run(() async {
        inside[0]++;
        await q.run(() => wait(500), longRunning: true, label: 'nested');
        inside[0]--;
        log.add('outer');
      });
      final ws = writers(q, 2, log, overlaps, inside);
      await Future.wait([outer, ...ws]).timeout(const Duration(seconds: 10));
      expect(log, ['outer', 'w1', 'w2']);
      expect(overlaps[0], 0);
      expect(q.stallCount, 0);
    }, timeout: guard);

    test('R15: an unmarked task that keeps making progress (nested writes, '
        'reportProgress) is not interrupted either', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(milliseconds: 200));
      final log = <String>[];
      final overlaps = [0], inside = [0];
      final batches = q.run(() async {
        inside[0]++;
        for (var i = 0; i < 8; i++) {
          await wait(50);
          await q.run(() {}); // one batch written
        }
        for (var i = 0; i < 8; i++) {
          await wait(50);
          q.reportProgress();
        }
        inside[0]--;
        log.add('batches'); // ~800 ms = 4 × the stall timeout
      });
      final ws = writers(q, 3, log, overlaps, inside);
      await Future.wait([batches, ...ws]).timeout(const Duration(seconds: 10));
      expect(log, ['batches', 'w1', 'w2', 'w3']);
      expect(overlaps[0], 0);
      expect(q.stallCount, 0);
    }, timeout: guard);

    test('R15: no deadlock even for a longRunning holder – a wait cycle is '
        'broken after longStallTimeout', () async {
      final q = DbWriteQueue(
        stallTimeout: const Duration(milliseconds: 100),
        longStallTimeout: const Duration(milliseconds: 400),
      );
      final log = <String>[];
      final sw = Stopwatch()..start();
      late Future<void> outside;
      final gate = Completer<void>();
      final head = q.run(() async {
        await gate.future;
        await outside; // cycle
        log.add('head');
      }, longRunning: true, label: 'cycle');
      outside = q.run(() => log.add('outside'));
      gate.complete();
      await Future.wait([head, outside]).timeout(const Duration(seconds: 10));
      expect(log, ['outside', 'head']);
      expect(q.stallCount, 1);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(350));
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('R15: wait cycle on a task that is not first in line – waiters are '
        'released oldest first, each runs exactly once', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(milliseconds: 160));
      final log = <String>[];
      late Future<void> third;
      final gate = Completer<void>();
      final head = q.run(() async {
        await gate.future;
        await third; // waits for the third waiter
        log.add('head');
      });
      final first = q.run(() => log.add('w1'));
      final second = q.run(() => log.add('w2'));
      third = q.run(() => log.add('w3'));
      final fourth = q.run(() => log.add('w4'));
      gate.complete();
      await Future.wait([head, first, second, third, fourth]).timeout(
        const Duration(seconds: 10),
      );
      expect(log, ['w1', 'w2', 'w3', 'head', 'w4']);
      expect(q.stallCount, 3);
      await q.flush().timeout(const Duration(seconds: 5));
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('R15: a task started out of turn that is still running when its '
        'turn comes keeps the queue; the next task waits for it', () async {
      final q = DbWriteQueue(stallTimeout: const Duration(milliseconds: 100));
      final log = <String>[];
      late Future<void> outside;
      final gate = Completer<void>();
      final signal = Completer<void>();
      final head = q.run(() async {
        await gate.future;
        await signal.future; // released by the first step of "outside"
        log.add('head-end');
      });
      outside = q.run(() async {
        log.add('outside-start');
        signal.complete();
        await wait(60); // shorter than the stall timeout: it is not stalled
        log.add('outside-end');
      });
      final next = q.run(() => log.add('next'));
      gate.complete();
      await Future.wait([head, outside, next]).timeout(
        const Duration(seconds: 10),
      );
      expect(log, ['outside-start', 'head-end', 'outside-end', 'next']);
      expect(q.stallCount, 1);
      expect(q.isIdle, isTrue);
    }, timeout: guard);

    test('R15: restore / import go through the queue marked longRunning', () {
      final src = File('lib/repositories/restore_repository.dart')
          .readAsStringSync();
      expect(src, contains('longRunning: true'));
      expect(src, contains('writeTxnSyncSafe'));
    });

    test('real Isar: async / sync writes, nested and detached, all land '
        'without "async write transaction already in progress"', () async {
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
      final dir = await Directory.systemTemp.createTemp('yh_056_a_isar_');
      final isar = await Isar.open(
        [mdl.CategorySchema],
        directory: dir.path,
        name: 'yh_056_a_queue',
      );
      try {
        mdl.Category cat(String name) =>
            mdl.Category(name: name, forItemType: ItemType.manga);
        final errors = <Object>[];
        final detachedDone = Completer<void>();

        // task 1: a queued task that leaves a sync write behind (outside
        // the Isar transaction callback); it fires later, in the middle of
        // task 2's transaction
        final t1 = dbWriteQueue.run(() async {
          unawaited(
            wait(40)
                .then(
                  (_) => isar.writeTxnSyncSafe(
                    () => isar.categorys.putSync(cat('detached-sync')),
                  ),
                )
                .then<void>((_) {}, onError: (Object e) => errors.add(e))
                .whenComplete(detachedDone.complete),
          );
          // nested in the running task: goes ahead at once
          await isar.writeTxnAsyncSafe(
            () => isar.categorys.put(cat('async-1')),
          );
        });
        // task 2: holds an async transaction open for 500 ms – longer than
        // the 10 × 20 ms conflict retries a queue-skipping write would get
        final t2 = isar.writeTxnAsyncSafe(() async {
          await isar.categorys.put(cat('async-2'));
          await wait(500);
          await isar.categorys.put(cat('async-2b'));
        });
        // tasks 3-4: queued sync and async writes from outside
        final t3 = isar.writeTxnSyncSafe(
          () => isar.categorys.putSync(cat('sync-3')),
        );
        final t4 = isar.writeTxnAsyncSafe(
          () => isar.categorys.put(cat('async-4')),
        );
        await Future.wait([t1, t2, t3, t4, detachedDone.future]).timeout(
          const Duration(seconds: 15),
        );
        expect(errors, isEmpty);
        final names = isar.categorys
            .where()
            .findAllSync()
            .map((c) => c.name)
            .toSet();
        expect(names, {
          'async-1',
          'async-2',
          'async-2b',
          'sync-3',
          'async-4',
          'detached-sync',
        });
        // Limit of Isar itself (not of the queue): work started *inside* a
        // transaction callback keeps Isar's own transaction zone, so a write
        // it makes later is refused as a nested transaction – with a clear
        // error, never a hang. Such work must be started outside the callback.
        Future<int>? leaked;
        await isar.writeTxnAsyncSafe(() async {
          await isar.categorys.put(cat('async-5'));
          leaked = wait(30).then(
            (_) => isar.writeTxnSyncSafe(
              () => isar.categorys.putSync(cat('leaked-from-txn')),
            ),
          );
          leaked!.ignore();
        });
        await expectLater(
          leaked!.timeout(const Duration(seconds: 5)),
          throwsA(isA<IsarError>()),
        );
        await dbWriteQueue.flush().timeout(const Duration(seconds: 5));
        expect(dbWriteQueue.stallCount, 0);
        expect(dbWriteQueue.isIdle, isTrue);
      } finally {
        await isar.close();
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      }
    }, timeout: guard);
  });
}
