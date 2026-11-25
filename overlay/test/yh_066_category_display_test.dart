// YomiHub 0.6.6 – A7: per-category display / sort / order (backup through
// yomihub_prefs).
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/manga.dart' show ItemType;
import 'package:mangayomi/models/settings.dart' show DisplayType;
import 'package:mangayomi/yomihub/library/category_display_store.dart';

void main() {
  test('json round trip and validation', () {
    const v = CategoryDisplay(display: DisplayType.list, sort: 3, reverse: true);
    final back = CategoryDisplay.fromJson(v.toJson())!;
    expect(back.display, DisplayType.list);
    expect(back.sort, 3);
    expect(back.reverse, isTrue);
    expect(CategoryDisplay.fromJson({'display': 9, 'sort': 42}), isNull);
    expect(CategoryDisplay.fromJson('x'), isNull);
    expect(const CategoryDisplay().isEmpty, isTrue);
  });

  test('keys are stable per item type + name', () {
    expect(CategoryDisplayStore.keyOf(ItemType.anime, 'Yêu thích'), '1|Yêu thích');
  });

  test('merge restore keeps this device and adds the backup', () {
    final m = CategoryDisplayStore.merge(
      {'0|A': {'sort': 1}},
      {'0|A': {'sort': 5}, '0|B': {'display': 3}},
    );
    expect(m['0|A'], {'sort': 1});
    expect(m['0|B'], {'display': 3});
  });
}
