import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/yomihub/filters/filter_checkbox.dart';
import 'package:mangayomi/yomihub/filters/multi_select_search.dart';

SelectFilterOption _o(String n, String v) => SelectFilterOption(n, v, 'SelectOption');

SelectFilter _genre() => SelectFilter('SelectFilter', 'Thể loại', 0, [
  _o('Tất cả', ''),
  _o('Hành động', 'action'),
  _o('Hài hước', 'comedy'),
  _o('Kinh dị', 'horror'),
], 'SelectFilter');

SelectFilter _sort() => SelectFilter('SelectFilter', 'Sắp xếp', 0, [
  _o('Mới cập nhật', '-updated_at'),
  _o('Mới nhất', '-created_at'),
  _o('Xem nhiều', '-views'),
], 'SelectFilter');

MManga _m(String link) => MManga()..link = link..name = link;

void main() {
  group('YomiHub 0.6.1 – bộ lọc chọn nhiều', () {
    test('chọn nhiều ô, bỏ "Tất cả", bỏ hết → về "Tất cả"', () {
      final g = _genre();
      expect(yomiSelectMultiAllowed(g), isTrue);
      expect(yomiSelectToggle(g, 1), isTrue);
      expect(yomiSelectChosen(g), [1]);
      expect(yomiSelectToggle(g, 3), isTrue);
      expect(yomiSelectChosen(g), [1, 3]);
      expect(g.state, 1);
      expect(g.multi, [1, 3]);
      yomiSelectToggle(g, 1);
      yomiSelectToggle(g, 3);
      expect(yomiSelectChosen(g), [0]);
      yomiSelectToggle(g, 2);
      yomiSelectToggle(g, 0); // bấm "Tất cả" → chỉ còn Tất cả
      expect(yomiSelectChosen(g), [0]);
      expect(g.multi, isEmpty);
    });

    test('bộ lọc kiểu Sắp xếp vẫn chỉ chọn một', () {
      final s = _sort();
      expect(yomiSelectMultiAllowed(s), isFalse);
      yomiSelectToggle(s, 1);
      yomiSelectToggle(s, 2);
      expect(yomiSelectChosen(s), [2]);
      expect(s.multi, isEmpty);
    });

    test('tách thành từng lượt tìm, giữ JSON qua lại', () {
      final g = _genre()..state = 1..multi = [1, 2];
      final s = _sort()..state = 2;
      final v = yomiExpandMultiSelect([s, g]);
      expect(v.length, 2);
      expect(v.map((l) => (l[1] as SelectFilter).state).toList(), [1, 2]);
      expect(v.every((l) => (l[0] as SelectFilter).state == 2), isTrue);
      expect(v.every((l) => (l[1] as SelectFilter).multi.isEmpty), isTrue);
      final back = SelectFilter.fromJson(g.toJson());
      expect(back.multi, [1, 2]);
      expect(yomiExpandMultiSelect([_genre()]).length, 1);
    });

    test('gộp kết quả bỏ trùng, hasNextPage nếu một lượt còn trang', () async {
      final g = _genre()..state = 1..multi = [1, 3];
      final r = await yomiSearchMulti([g], (f) async {
        final st = (f.first as SelectFilter).state;
        return st == 1
            ? MPages(list: [_m('a'), _m('b')], hasNextPage: false)
            : MPages(list: [_m('b'), _m('c')], hasNextPage: true);
      });
      expect(r!.list.map((e) => e.link).toList(), ['a', 'b', 'c']);
      expect(r.hasNextPage, isTrue);
    });

    testWidgets('ô chọn: tick 2 thể loại cùng lúc', (t) async {
      final g = _genre();
      var calls = 0;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (c, ss) => ListView(children: [
              YomiSelectCheckboxes(filter: g, onChanged: () => ss(() => calls++)),
            ]),
          ),
        ),
      ));
      await t.tap(find.text('Hành động'));
      await t.pumpAndSettle();
      await t.tap(find.text('Kinh dị'));
      await t.pumpAndSettle();
      bool checked(String n) => t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, n)).value == true;
      expect(checked('Hành động'), isTrue);
      expect(checked('Kinh dị'), isTrue);
      expect(checked('Tất cả'), isFalse);
      expect(calls, 2);
    });
  });
}
