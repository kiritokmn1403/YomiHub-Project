// YomiHub 0.6.2: lỗi văng "type 'bool' is not a subtype of type 'double?' in
// type cast" (ScrollPosition.restoreScrollOffset) + "Null check" ở EditableText
// khi mở nhóm bộ lọc dài có ô tìm (log 19/11/2026 21:53, MeHentai/TruyenHentaivn).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/modules/manga/home/widget/filter_widget.dart';
import 'package:mangayomi/yomihub/filters/filter_checkbox.dart';

SelectFilter _big(String name) => SelectFilter('SelectFilter', name, 0, [
      for (var i = 0; i < kYomiFilterSearchMin + 5; i++) SelectFilterOption('Mục $i', 'v$i', null),
    ], null);

Widget _host(List<dynamic> filters) => MaterialApp(
      home: Scaffold(
        body: ListView(
          key: const PageStorageKey<String>('outer_sheet'),
          children: [FilterWidget(filterList: filters, onChanged: (_) {})],
        ),
      ),
    );

void main() {
  testWidgets('mở/gập nhóm dài có ô tìm không văng bool→double', (t) async {
    final f = [_big('Thể loại'), _big('Năm')];
    await t.pumpWidget(_host(f));
    for (var round = 0; round < 3; round++) {
      await t.tap(find.text('Thể loại'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    // ô tìm có mặt khi đang mở; gõ chữ không lỗi Null check
    await t.tap(find.text('Thể loại'));
    await t.pumpAndSettle();
    final tf = find.byType(TextField);
    expect(tf, findsWidgets);
    await t.tap(tf.first);
    await t.enterText(tf.first, 'Mục 1');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('GroupFilter lồng danh sách bộ lọc: mở lại không văng', (t) async {
    final g = GroupFilter('GroupFilter', 'Nhóm', [_big('Con A'), CheckBoxFilter(null, 'Ô', 'o', null)], null);
    await t.pumpWidget(_host([g]));
    for (var round = 0; round < 4; round++) {
      await t.tap(find.text('Nhóm'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });
}
