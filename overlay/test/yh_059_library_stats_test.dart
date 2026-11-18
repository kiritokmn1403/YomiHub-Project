import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/library/library_chapter_stats.dart';

void main() {
  test('countIds ignores null mangaId and counts per title', () {
    expect(LibraryChapterStats.countIds([1, 1, 2, null, 1]), {1: 3, 2: 1});
  });
  test('unread = total - read; titles without rows are not covered', () {
    final s = LibraryChapterStats(total: {1: 10, 2: 3}, read: {1: 10, 2: 1}, bookmarked: {2: 1});
    expect(s.unreadOf(1), 0);
    expect(s.unreadOf(2), 2);
    expect(s.hasBookmark(2), isTrue);
    expect(s.hasBookmark(1), isFalse);
    expect(s.covers(3), isFalse);
  });
  test('downloaded chapters are mapped to their title through aligned id lists', () {
    final m = LibraryChapterStats.countForChapters([10, 11, 12, 13], [1, 1, 2, null], {11, 12, 13});
    expect(m, {1: 1, 2: 1});
  });
  test('large library stays linear (88k chapters)', () {
    final mids = [for (var i = 0; i < 88000; i++) i % 4490];
    final sw = Stopwatch()..start();
    final total = LibraryChapterStats.countIds(mids);
    expect(total.length, 4490);
    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
