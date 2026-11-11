// YomiHub 0.5.6 Part C2: Giao diện Mới (U12 - Shiori Design System) Widget & Unit Tests
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/library/library_hub.dart';
import 'package:mangayomi/yomihub/library/library_hub_bar.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori.dart';
import 'package:mangayomi/yomihub/ui/ui_style.dart';

void main() {
  late Directory temp;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('yomihub-056-c2-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
    await YomiPrefs.open();
  });

  tearDownAll(() async {
    try {
      await temp.delete(recursive: true);
    } catch (_) {}
  });

  group('Part C2: Shiori Tokens & Theme', () {
    test('ShioriSpace follows 4-point grid', () {
      expect(ShioriSpace.s4, equals(4.0));
      expect(ShioriSpace.s8, equals(8.0));
      expect(ShioriSpace.s12, equals(12.0));
      expect(ShioriSpace.s16, equals(16.0));
      expect(ShioriSpace.s24, equals(24.0));
      expect(ShioriSpace.s32, equals(32.0));
      expect(ShioriSpace.s48, equals(48.0));
    });

    test('ShioriShape defines designated corner radii', () {
      expect(ShioriShape.badge, equals(4.0));
      expect(ShioriShape.cover, equals(6.0));
      expect(ShioriShape.card, equals(12.0));
      expect(ShioriShape.sheet, equals(20.0));
      expect(ShioriShape.pill, equals(999.0));
    });

    test('ShioriMotion provides standard durations and curves', () {
      expect(ShioriMotion.fast, equals(const Duration(milliseconds: 120)));
      expect(ShioriMotion.standard, equals(const Duration(milliseconds: 220)));
      expect(ShioriMotion.enter, equals(const Duration(milliseconds: 350)));
      expect(ShioriMotion.exitSlow, equals(const Duration(milliseconds: 500)));
      expect(ShioriMotion.standardCurve, equals(Curves.easeOutCubic));
    });

    test('ShioriColors.onFill computes high contrast label color', () {
      expect(ShioriColors.onFill(const Color(0xFFFFFFFF)), equals(const Color(0xFF000000)));
      expect(ShioriColors.onFill(const Color(0xFF000000)), equals(const Color(0xFFFFFFFF)));
      expect(ShioriColors.onFill(const Color(0xFF1E88E5)), equals(const Color(0xFFFFFFFF)));
      expect(ShioriColors.onFill(const Color(0xFFFFF9C4)), equals(const Color(0xFF000000)));
    });

    test('ShioriColors adapts to theme brightness', () {
      final darkTheme = ThemeData(brightness: Brightness.dark, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple));
      final darkColors = ShioriColors.fromTheme(darkTheme);
      expect(darkColors.ink0, equals(const Color(0xFF0F1016)));
      expect(darkColors.accent, equals(Colors.deepPurple));

      final lightTheme = ThemeData(brightness: Brightness.light, colorScheme: const ColorScheme.light(primary: Colors.blue));
      final lightColors = ShioriColors.fromTheme(lightTheme);
      expect(lightColors.ink0, equals(const Color(0xFFF6F6F9)));
      expect(lightColors.accent, equals(Colors.blue));
    });

    testWidgets('ShioriTheme decorations render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final cardDeco = ShioriTheme.cardDecoration(context: context);
              expect(cardDeco.borderRadius, equals(BorderRadius.circular(12)));

              final pillDeco = ShioriTheme.pillDecoration(context: context);
              expect(pillDeco.borderRadius, equals(BorderRadius.circular(999)));

              return const Scaffold(body: Placeholder());
            },
          ),
        ),
      );
    });
  });

  group('Part C2: Shiori Badge & Cover Card Widgets', () {
    testWidgets('ShioriBadge displays count and respects max threshold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShioriBadge(count: 5),
                ShioriBadge(count: 1200, max: 999),
                ShioriBadge(count: 0),
                ShioriBadge(count: -1),
                ShioriBadge(count: 0, label: 'NEW'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('999+'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('-1'), findsNothing);
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('ShioriCoverCard renders title, progress bar, and badge', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                child: ShioriCoverCard(
                  title: 'Sousou no Frieren',
                  unreadCount: 4,
                  progress: 0.75,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sousou no Frieren'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(ShioriCoverCard));
      expect(tapped, isTrue);
    });

    testWidgets('ShioriSectionHeader renders title, subtitle, and badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShioriSectionHeader(
              title: 'Thư Viện Truyện Tranh',
              subtitle: '12 bộ đang theo dõi',
              badgeText: 'HOT',
            ),
          ),
        ),
      );

      expect(find.text('Thư Viện Truyện Tranh'), findsOneWidget);
      expect(find.text('12 bộ đang theo dõi'), findsOneWidget);
      expect(find.text('HOT'), findsOneWidget);
    });
  });

  group('Part C2: Shiori Floating Navigation Bar', () {
    testWidgets('ShioriFloatingNavBar renders destinations and handles tap', (tester) async {
      int selected = 0;
      final destinations = [
        const ShioriNavDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: 'Thư Viện'),
        const ShioriNavDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Hoạt động'),
        const ShioriNavDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Duyệt'),
        const ShioriNavDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz), label: 'Thêm'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  bottomNavigationBar: ShioriFloatingNavBar(
                    destinations: destinations,
                    selectedIndex: selected,
                    onDestinationSelected: (idx) {
                      setState(() => selected = idx);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Thư Viện'), findsOneWidget);
      expect(find.text('Hoạt động'), findsOneWidget);
      expect(find.text('Duyệt'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);

      // Tap on 'Duyệt' (index 2)
      await tester.tap(find.text('Duyệt'));
      await tester.pumpAndSettle();
      expect(selected, equals(2));
    });
  });

  group('Part C2: YomiUi Style Switch & LibraryHubTabBar Integration', () {
    test('YomiUi defaults to classic mode and switches cleanly to modern', () async {
      await YomiPrefs.set(YomiUi.prefKey, null);
      expect(YomiUi.style, equals(YomiUiStyle.classic));
      expect(YomiUi.isModern, isFalse);

      await YomiUi.setStyle(YomiUiStyle.modern);
      expect(YomiUi.style, equals(YomiUiStyle.modern));
      expect(YomiUi.isModern, isTrue);

      await YomiUi.setStyle(YomiUiStyle.classic);
      expect(YomiUi.style, equals(YomiUiStyle.classic));
      expect(YomiUi.isModern, isFalse);
    });

    testWidgets('LibraryHubTabBar renders pill mode vs classic mode without error', (tester) async {
      String selectedRoute = '/MangaLibrary';
      const tabs = [
        LibraryHubTab(route: '/MangaLibrary', label: 'Manga', icon: Icons.book_outlined, selectedIcon: Icons.book),
        LibraryHubTab(route: '/AnimeLibrary', label: 'Anime', icon: Icons.movie_outlined, selectedIcon: Icons.movie),
      ];

      // Test classic underline mode (pill: false)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: LibraryHubTabBar(
                tabs: tabs,
                current: selectedRoute,
                pill: false,
                onSelect: (r) => selectedRoute = r,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);

      // Test modern pill mode (pill: true)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: LibraryHubTabBar(
                tabs: tabs,
                current: selectedRoute,
                pill: true,
                onSelect: (r) => selectedRoute = r,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);

      await tester.tap(find.text('Anime'));
      await tester.pumpAndSettle();
      expect(selectedRoute, equals('/AnimeLibrary'));
    });
  });

  group('Part C2: Shiori Page Transitions', () {
    testWidgets('ShioriPageTransition applies translation and opacity', (tester) async {
      final controller = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 300));
      final secondaryController = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          home: ShioriPageTransition(
            animation: controller,
            secondaryAnimation: secondaryController,
            child: const Text('Shiori Transition Child'),
          ),
        ),
      );

      expect(find.text('ShioriTransitionChild', skipOffstage: false), findsNothing);
      expect(find.text('Shiori Transition Child'), findsOneWidget);

      controller.value = 0.5;
      await tester.pump();
      expect(find.text('Shiori Transition Child'), findsOneWidget);

      controller.dispose();
      secondaryController.dispose();
    });
  });

  group('R25: phone layout (bottomNavigationBar slot)', () {
    Future<void> pump(WidgetTester t, Widget nav) async {
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(child: MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(key: ValueKey('body')),
          bottomNavigationBar: nav,
        ),
      )));
      await t.pump();
    }

    testWidgets('Moi: body has height and floating bar sits at bottom',
        (tester) async {
      await pump(
        tester,
        SafeArea(
          top: false,
          child: ShioriFloatingNavBar(
            destinations: const [
              ShioriNavDestination(icon: Icon(Icons.book), label: 'A'),
              ShioriNavDestination(icon: Icon(Icons.image), label: 'B'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      final body = tester.getSize(find.byKey(const ValueKey('body')));
      expect(body.height, greaterThan(700));
      final bar = tester.getRect(find.byKey(const ValueKey('shioriNav_A')));
      expect(bar.bottom, greaterThan(915 - 100));
    });

    testWidgets('Cu: body has height and NavigationBar at bottom',
        (tester) async {
      await pump(
        tester,
        NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.book), label: 'A'),
            NavigationDestination(icon: Icon(Icons.image), label: 'B'),
          ],
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('body'))).height,
        greaterThan(700),
      );
      expect(
        tester.getRect(find.byType(NavigationBar)).bottom,
        closeTo(915, 1),
      );
    });
  });

  group('R26: desktop 1280x800 (rail layout) shows the hub tab strip', () {
    const names = {
      '/MangaLibrary': 'Truyen tranh',
      '/AnimeLibrary': 'Phim & Dien anh',
      '/NovelLibrary': 'Tieu thuyet',
      '/playBooks': 'Play Books',
    };
    LibraryHubTab tabFor(String r) => LibraryHubTab(
      route: r,
      label: names[r]!,
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
    );
    const order = [
      '/MangaLibrary', '/AnimeLibrary', '/NovelLibrary', '/playBooks',
      '/updates', '/browse',
    ];

    for (final modern in [false, true]) {
      testWidgets('${modern ? "Moi" : "Cu"}: strip with Phim & Dien anh next to a rail',
          (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        YomiLibraryHub.tabs =
            libraryHubTabs(order: order, hidden: const [], tv: false);
        final strip = YomiLibraryHub.stripFor('/MangaLibrary');
        expect(strip.length, 4);
        await tester.pumpWidget(ProviderScope(child: MaterialApp(
          home: Scaffold(
            body: Row(children: [
              const SizedBox(width: 100, child: Placeholder()),
              Expanded(
                child: YomiHubShell(
                  stripTabs: strip,
                  location: '/MangaLibrary',
                  pill: modern,
                  swipe: true,
                  tabFor: tabFor,
                  onGo: (_) {},
                  child: const SizedBox.expand(key: ValueKey('body')),
                ),
              ),
            ]),
          ),
        )));
        await tester.pump();
        expect(find.text('Phim & Dien anh'), findsOneWidget);
        expect(find.text('Play Books'), findsOneWidget);
        expect(tester.getSize(find.byKey(const ValueKey('body'))).height,
            greaterThan(600));
      });
    }

    test('feature off: Film tab disappears', () {
      YomiLibraryHub.tabs = libraryHubTabs(
          order: order, hidden: const ['/AnimeLibrary'], tv: false);
      expect(YomiLibraryHub.stripFor('/MangaLibrary'),
          isNot(contains('/AnimeLibrary')));
    });
  });
}
