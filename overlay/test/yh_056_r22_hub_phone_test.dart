import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/router/router.dart';
import 'package:mangayomi/yomihub/library/library_hub.dart';
import 'package:mangayomi/yomihub/library/library_hub_bar.dart';

/// R22 (QA2 Android): on a phone the Library sub-tab strip and the sideways
/// swipe were missing on a cold start. Cause: the current location kept
/// null because the first page opens before the location listener exists.
const _order = [
  '/MangaLibrary',
  '/AnimeLibrary',
  '/NovelLibrary',
  '/playBooks',
  '/updates',
  '/history',
  '/browse',
];

LibraryHubTab _tab(String r) => LibraryHubTab(
  route: r,
  label: 'L$r',
  icon: Icons.book_outlined,
  selectedIcon: Icons.book,
);

/// A real GoRouter with the four library branches under the same shell
/// widget the app uses ([YomiHubShell]), driven by the same hub rules.
GoRouter _router({
  required bool modern,
  required bool tv,
  List<String> hidden = const [],
}) {
  YomiLibraryHub.tabs = libraryHubTabs(order: _order, hidden: hidden, tv: tv);
  return GoRouter(
    initialLocation: tv ? '/AnimeLibrary' : '/MangaLibrary',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          final location = state.uri.toString();
          return YomiHubShell(
            stripTabs: YomiLibraryHub.stripFor(location),
            location: location,
            pill: modern,
            swipe: !tv,
            tabFor: _tab,
            onGo: GoRouter.of(context).go,
            child: shell,
          );
        },
        branches: [
          for (final r in kLibraryHubRoutes)
            StatefulShellBranch(
              routes: [
                GoRoute(path: r, builder: (_, _) => Center(child: Text('page $r'))),
              ],
            ),
        ],
      ),
    ],
  );
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required bool modern,
  bool tv = false,
  List<String> hidden = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2340); // phone portrait
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = _router(modern: modern, tv: tv, hidden: hidden);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

String _loc(GoRouter r) => r.routerDelegate.currentConfiguration.uri.toString();

void main() {
  for (final modern in [false, true]) {
    final mode = modern ? 'Mới' : 'Cũ';
    group('Thư Viện trên điện thoại, giao diện $mode', () {
      testWidgets('có đủ dải tab, bấm tab đổi trang', (tester) async {
        final router = await _pump(tester, modern: modern);
        for (final r in kLibraryHubRoutes) {
          expect(find.byKey(ValueKey('libraryHubTab$r')), findsOneWidget);
        }
        await tester.tap(find.byKey(const ValueKey('libraryHubTab/AnimeLibrary')));
        await tester.pumpAndSettle();
        expect(_loc(router), '/AnimeLibrary');
        expect(find.text('page /AnimeLibrary'), findsOneWidget);
      });

      testWidgets('vuốt ngang sang tab kế và quay lại', (tester) async {
        final router = await _pump(tester, modern: modern);
        await tester.fling(find.text('page /MangaLibrary'), const Offset(-300, 0), 1500);
        await tester.pumpAndSettle();
        expect(_loc(router), '/AnimeLibrary');
        await tester.fling(find.text('page /AnimeLibrary'), const Offset(300, 0), 1500);
        await tester.pumpAndSettle();
        expect(_loc(router), '/MangaLibrary');
      });

      testWidgets('tắt tính năng Phim thì ẩn tab Phim', (tester) async {
        await _pump(tester, modern: modern, hidden: ['/AnimeLibrary']);
        expect(find.byKey(const ValueKey('libraryHubTab/AnimeLibrary')), findsNothing);
        expect(find.byKey(const ValueKey('libraryHubTab/NovelLibrary')), findsOneWidget);
      });

      testWidgets('TV: chỉ Phim & Điện ảnh, không có dải tab', (tester) async {
        await _pump(tester, modern: modern, tv: true);
        expect(find.byType(LibraryHubTabBar), findsNothing);
        expect(find.text('page /AnimeLibrary'), findsOneWidget);
      });
    });
  }

  testWidgets('vị trí hiện tại không còn null khi khởi động nguội', (tester) async {
    final router = GoRouter(
      initialLocation: '/MangaLibrary',
      routes: [GoRoute(path: '/MangaLibrary', builder: (_, _) => const SizedBox())],
    );
    final container = ProviderContainer(
      overrides: [routerProvider.overrideWithValue(router)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(container.read(routerCurrentLocationStateProvider), isNull);
    await tester.pump(); // the post-frame listener registration runs
    expect(container.read(routerCurrentLocationStateProvider), '/MangaLibrary');
  });
}
