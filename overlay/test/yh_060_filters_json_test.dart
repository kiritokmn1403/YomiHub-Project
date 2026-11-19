// YomiHub 0.6.0 – Feature Check 7: filters of extensions survive malformed
// entries (port of Mangayomi v0.9.96 PR #1150 behaviour).
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';

void main() {
  test('malformed select options are skipped, numbers become strings', () {
    final r = filtersFromJson([
      {
        'name': 'Genre',
        'state': 1,
        'values': [
          'Action',
          {'value': 'Drama'},
          {'nope': 1},
          null,
          42,
          ['x'],
        ],
      },
    ]);
    expect(r, hasLength(1));
    final f = r.first as SelectFilter;
    expect(f.values.map((e) => e.value), ['Action', 'Drama', '42']);
    expect(f.state, 1);
  });

  test('bad vals / sort / tristate do not drop the whole list', () {
    final r = filtersFromJson([
      {'name': 'Sort', 'state': {'index': null, 'ascending': 'yes'}, 'values': ['A', 'B']},
      {'name': 'Type', 'state': 9, 'vals': [{'first': null}, 'junk', {'first': 'Manga', 'second': null}]},
      {'included': false, 'ignored': true, 'excluded': false, 'name': 7},
      {'name': 'Completed', 'state': true},
      'garbage',
      {'name': 'Query', 'state': 'abc'},
    ]);
    expect(r.whereType<SortFilter>().single.state.index, 0);
    expect(r.whereType<SortFilter>().single.state.ascending, isFalse);
    final sel = r.whereType<SelectFilter>().single;
    expect(sel.values.single.value, 'Manga');
    expect(sel.state, 0); // clamped into range
    expect(r.whereType<CheckBoxFilter>(), hasLength(1));
    expect(r.whereType<TextFilter>(), hasLength(1));
    expect(r.whereType<TriStateFilter>(), isEmpty); // name not a string
  });

  test('groups recurse', () {
    final r = filtersFromJson([
      {'name': 'Tags', 'state': [{'name': 'Isekai', 'state': false}, null]},
    ]);
    expect((r.single as GroupFilter).state, hasLength(1));
  });
}
