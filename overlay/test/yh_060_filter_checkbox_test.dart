// YomiHub 0.6.0: mọi lựa chọn trong bộ lọc tiện ích là ô chọn (checkbox).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/modules/manga/home/widget/filter_widget.dart';
import 'package:mangayomi/yomihub/filters/filter_checkbox.dart';
import 'package:mangayomi/yomihub/filters/filter_profiles.dart';

SelectFilter _sel() => SelectFilter('SelectFilter', 'Trạng thái', 0, [
      SelectFilterOption('Tất cả', 'all', null),
      SelectFilterOption('Đang ra', 'ongoing', null),
      SelectFilterOption('Hoàn thành', 'done', null),
    ], null);

SortFilter _sort() => SortFilter('SortFilter', 'Sắp xếp', SortState(0, false, null), [
      SelectFilterOption('Mới cập nhật', 'update', null),
      SelectFilterOption('Lượt xem', 'view', null),
    ], null);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

bool _checked(WidgetTester t, String label) {
  final tile = t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label));
  return tile.value == true;
}

void main() {
  group('YomiHub 0.6.0 filter checkboxes', () {
    test('logic: select / sort / tri-state', () {
      final s = _sel();
      expect(yomiSelectPick(s, 2), isTrue);
      expect(s.state, 2);
      expect(yomiSelectPick(s, 2), isFalse);
      expect(yomiSelectPick(s, 9), isFalse);
      s.state = 7; // state hỏng
      expect(yomiSelectIndex(s), 0);
      final o = _sort();
      yomiSortPick(o, 1);
      expect(o.state.index, 1);
      expect(o.state.ascending, isFalse);
      yomiSortPick(o, 1);
      expect(o.state.ascending, isTrue);
      expect([yomiTriNext(0), yomiTriNext(1), yomiTriNext(2)], [1, 2, 0]);
    });

    testWidgets('Mangayomi FilterWidget: SelectFilter là ô chọn, không còn Dropdown', (t) async {
      final s = _sel();
      var calls = 0;
      await t.pumpWidget(_host(FilterWidget(filterList: [s], onChanged: (_) => calls++)));
      await t.pumpAndSettle();
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(_checked(t, 'Tất cả'), isTrue);
      await t.tap(find.text('Hoàn thành'));
      await t.pumpAndSettle();
      expect(s.state, 2);
      expect(calls, 1);
      // tự vẽ lại dù màn cha không setState (lỗi "không chọn được" 0.5.9)
      expect(_checked(t, 'Hoàn thành'), isTrue);
      expect(_checked(t, 'Tất cả'), isFalse);
    });

    testWidgets('SortFilter: ô chọn + bấm lại đổi chiều', (t) async {
      final o = _sort();
      await t.pumpWidget(_host(FilterWidget(filterList: [o], onChanged: (_) {})));
      await t.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      await t.tap(find.text('Lượt xem'));
      await t.pumpAndSettle();
      expect(o.state.index, 1);
      expect(_checked(t, 'Lượt xem'), isTrue);
      await t.tap(find.text('Lượt xem'));
      await t.pumpAndSettle();
      expect(o.state.ascending, isTrue);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('TriState + CheckBox trong FilterWidget tự vẽ lại', (t) async {
      final tri = TriStateFilter('TriStateFilter', 'Hành động', 'action', null);
      final cb = CheckBoxFilter('CheckBoxFilter', 'Có màu', 'color', null);
      await t.pumpWidget(_host(FilterWidget(filterList: [tri, cb], onChanged: (_) {})));
      await t.tap(find.text('Hành động'));
      await t.pumpAndSettle();
      expect(tri.state, 1);
      expect(_checked(t, 'Hành động'), isTrue);
      await t.tap(find.text('Hành động'));
      await t.pumpAndSettle();
      expect(tri.state, 2);
      expect(t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Hành động')).value, isNull);
      await t.tap(find.text('Có màu'));
      await t.pumpAndSettle();
      expect(cb.state, isTrue);
      expect(_checked(t, 'Có màu'), isTrue);
    });

    testWidgets('Kotatsu + Aniyomi: không còn chip, tất cả là ô chọn', (t) async {
      final s = _sel();
      final g = GroupFilter('GroupFilter', 'Thể loại', [
        TriStateFilter('TriStateFilter', 'Hài', 'comedy', null),
        TriStateFilter('TriStateFilter', 'Kinh dị', 'horror', null),
      ], null);
      for (final p in [YomiFilterProfile.kotatsu, YomiFilterProfile.aniyomi]) {
        await t.pumpWidget(_host(filterBodyFor(p, [s, g], () {})));
        await t.pumpAndSettle();
        if (p == YomiFilterProfile.aniyomi) {
          await t.tap(find.text('Thể loại'));
          await t.pumpAndSettle();
        }
        expect(find.byType(ChoiceChip), findsNothing, reason: '$p');
        expect(find.byType(FilterChip), findsNothing, reason: '$p');
        expect(find.byType(DropdownButton<int>), findsNothing, reason: '$p');
        expect(find.byType(CheckboxListTile), findsNWidgets(5), reason: '$p');
        await t.tap(find.text('Kinh dị'));
        await t.pumpAndSettle();
        expect((g.state[1] as TriStateFilter).state, 1, reason: '$p');
        (g.state[1] as TriStateFilter).state = 0;
      }
    });
  });
}
