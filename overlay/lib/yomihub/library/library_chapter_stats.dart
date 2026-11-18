// 0.5.9: chapter statistics for the whole library from index/property
// queries instead of loading every `manga.chapters` IsarLinks on the UI thread.
//
// Log 16–17/11: "Giao diện bị treo 3.0 giây • /MangaLibrary", "Khung hình
// chậm: dựng 3127ms" on a library of ~4,490 titles / ~88,000 chapters. The
// filter/sort provider evaluated `element.chapters.any(...)` /
// `unreadChaptersCount` for every title, which synchronously deserialises all
// chapter objects. Property queries return only ints/bools (no objects).
import 'package:isar_community/isar.dart';
import 'package:mangayomi/models/chapter.dart';

class LibraryChapterStats {
  LibraryChapterStats({
    required this.total,
    required this.read,
    required this.bookmarked,
    this.downloaded = const {},
  });

  /// mangaId → number of chapters / read chapters / bookmarked / downloaded.
  final Map<int, int> total;
  final Map<int, int> read;
  final Map<int, int> bookmarked;
  final Map<int, int> downloaded;

  /// Whether chapter rows for [mangaId] carry the `mangaId` field. Titles
  /// without it (very old data, or no chapters) fall back to the IsarLinks.
  bool covers(int mangaId) => total.containsKey(mangaId);
  int totalOf(int mangaId) => total[mangaId] ?? 0;
  int unreadOf(int mangaId) => totalOf(mangaId) - (read[mangaId] ?? 0);
  bool hasBookmark(int mangaId) => (bookmarked[mangaId] ?? 0) > 0;
  bool hasDownload(int mangaId) => (downloaded[mangaId] ?? 0) > 0;

  static Map<int, int> countIds(Iterable<int?> ids) {
    final m = <int, int>{};
    for (final id in ids) {
      if (id != null) m[id] = (m[id] ?? 0) + 1;
    }
    return m;
  }

  /// Counts per manga for the chapter ids in [chapterIds] given aligned
  /// (same order) lists of all chapter ids and their mangaIds.
  static Map<int, int> countForChapters(
    List<int> allIds,
    List<int?> allMangaIds,
    Set<int> chapterIds,
  ) {
    final m = <int, int>{};
    if (chapterIds.isEmpty) return m;
    for (var i = 0; i < allIds.length && i < allMangaIds.length; i++) {
      final mid = allMangaIds[i];
      if (mid != null && chapterIds.contains(allIds[i])) m[mid] = (m[mid] ?? 0) + 1;
    }
    return m;
  }

  static LibraryChapterStats load(
    Isar isar, {
    Set<int>? downloadedChapterIds,
  }) {
    final c = isar.chapters;
    final total = countIds(c.where().mangaIdProperty().findAllSync());
    final read = countIds(c.where().isReadEqualTo(true).mangaIdProperty().findAllSync());
    final bm = countIds(c.where().isBookmarkedEqualTo(true).mangaIdProperty().findAllSync());
    var dl = const <int, int>{};
    if (downloadedChapterIds != null && downloadedChapterIds.isNotEmpty) {
      // both property queries walk the primary index → same order
      final ids = c.where().idProperty().findAllSync();
      final mids = c.where().mangaIdProperty().findAllSync();
      dl = countForChapters(ids, mids, downloadedChapterIds);
    }
    return LibraryChapterStats(total: total, read: read, bookmarked: bm, downloaded: dl);
  }
}
