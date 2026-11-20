// YomiHub 0.6.3 – chủ dự án 20/11 11:28 (Xiaomi 15T, DamCoNuong): các mục của
// nhóm "Thể Loại" hiện biểu tượng ⓘ, không chọn được. Tiện ích Keiyoushi mới gửi
// mục TriState chỉ gồm {name, state: 0..2} và bị đọc thành HeaderFilter.
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';

void main() {
  test('int-state entries inside a Group become TriState checkboxes', () {
    final f = filtersFromJson([
      {'name': 'Ghi chú', 'state': 0},
      {
        'name': 'Thể loại',
        'state': [
          {'name': '16+', 'state': 0},
          {'name': 'Action', 'state': 1},
          {'name': 'Drama', 'state': 2},
        ],
      },
    ]);
    expect(f.first, isA<HeaderFilter>());
    final g = f[1] as GroupFilter;
    expect(g.state.length, 3);
    expect(g.state.every((e) => e is TriStateFilter), isTrue);
    expect((g.state[1] as TriStateFilter).state, 1);
    expect((g.state[2] as TriStateFilter).state, 2);
  });

  test('isIncluded/isExcluded keys are read as TriState too', () {
    final f = filtersFromJson([
      {'name': 'Romance', 'state': 0, 'isIncluded': false, 'isExcluded': false, 'isIgnored': true},
    ]);
    expect(f.single, isA<TriStateFilter>());
  });

  test('saved lists with headers inside a Group are healed on read', () {
    final f = [
      HeaderFilter('Ghi chú', 'HeaderFilter'),
      GroupFilter('Thể loạiFilter', 'Thể loại', [HeaderFilter('16+', 'x'), HeaderFilter('Action', 'x')], 'GroupFilter'),
    ];
    yomiHealGroupHeaders(f);
    expect(f.first, isA<HeaderFilter>());
    expect((f[1] as GroupFilter).state.every((e) => e is TriStateFilter), isTrue);
  });
}
