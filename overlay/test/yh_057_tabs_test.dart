// 0.5.7 – logs 7: 40x "Null check operator used on a null value" in
// flutter tabs.dart:633 (`controller.animation!`) @ /MangaLibrary and
// /mangaReaderView, from sheets opened with customDraggableTabBar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/widgets/custom_draggable_tabbar.dart';

Widget _sheet(List<int> seen) => DraggableTabsHost(
      length: 3,
      onIndexChanged: seen.add,
      builder: (context, c) => Material(
        child: Column(children: [
          TabBar(controller: c, tabs: const [
            Tab(text: 'A'),
            Tab(text: 'B'),
            Tab(text: 'C'),
          ]),
          Expanded(
            child: TabBarView(controller: c, children: const [
              Text('a'),
              Text('b'),
              Text('c'),
            ]),
          ),
        ]),
      ),
    );

void main() {
  testWidgets('closing the sheet never paints a disposed TabController',
      (tester) async {
    final seen = <int>[];
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: const Scaffold(body: Text('home')),
    ));
    for (var round = 0; round < 3; round++) {
      nav.currentState!.push(MaterialPageRoute(builder: (_) => _sheet(seen)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      nav.currentState!.pop();
      // Step frame by frame through the closing transition.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    }
    expect(seen, contains(2));
  });

  testWidgets('index callback fires once per change, not per frame',
      (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(MaterialApp(home: _sheet(seen)));
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(seen, [1, 2]);
  });
}
