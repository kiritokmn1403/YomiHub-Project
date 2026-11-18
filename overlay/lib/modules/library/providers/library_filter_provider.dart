import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/yomihub/filters/genre_filter.dart';
import 'package:mangayomi/utils/extensions/manga_extensions.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/download_repository.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mangayomi/main.dart' show isar;
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/library/library_chapter_stats.dart';
part 'library_filter_provider.g.dart';

/// Sorts unread counts while keeping fully-read entries at the end.
///
/// Reversing the active unread values must not promote the inactive zero
/// value above titles that still have something to read.
List<T> sortByUnreadCount<T>(
  Iterable<T> values, {
  required int Function(T value) unreadCountOf,
  bool descending = false,
}) {
  final sorted = values.toList();
  final counts = <T, int>{
    for (final value in sorted) value: unreadCountOf(value),
  };
  sorted.sort((a, b) {
    final aCount = counts[a]!;
    final bCount = counts[b]!;
    if (aCount == 0 && bCount != 0) return 1;
    if (bCount == 0 && aCount != 0) return -1;
    return descending ? bCount.compareTo(aCount) : aCount.compareTo(bCount);
  });
  return sorted;
}

/// Pre-fetches all downloaded chapter IDs in a single Isar query.
/// Returns a [Set<int>] for O(1) lookup instead of per-chapter queries.
@riverpod
Stream<Set<int>> downloadedChapterIds(Ref ref) {
  return downloadRepository.watchDownloaded().map(
    (list) => list.map((d) => d.id).whereType<int>().toSet(),
  );
}

/// Pre-fetches all manga IDs that have at least one tracking entry reactively.
@riverpod
Stream<Set<int>> trackedMangaIds(Ref ref) {
  return trackRepository.watchAll().map(
    (tracks) => tracks.map((t) => t.mangaId).whereType<int>().toSet(),
  );
}

/// Filters and sorts a list of [Manga] based on library filter/sort settings.
@riverpod
List<Manga> filteredLibraryManga(
  Ref ref, {
  required List<Manga> data,
  required int downloadFilterType,
  required int unreadFilterType,
  required int startedFilterType,
  required int bookmarkedFilterType,
  required int completedFilterType,
  required int trackingFilterType,
  required int sortType,
  required bool downloadedOnly,
  required String searchQuery,
  required bool ignoreFiltersOnSearch,
  required List<String> sourceIds,
  required Settings settings,
}) {
  final downloadedIds =
      ref.watch(downloadedChapterIdsProvider).asData?.value ?? const <int>{};
  final trackedIds =
      ref.watch(trackedMangaIdsProvider).asData?.value ?? const <int>{};
  final genreFilter = ref.watch(yomiGenreFilterProvider);

  List<Manga> mangas;

  // 0.5.9: per-title chapter facts from index/property queries (see
  // library_chapter_stats.dart) instead of loading every title's chapters on
  // the UI thread – the cause of the 2.6–3.1 s library freezes in the log.
  final searchOnly = searchQuery.isNotEmpty && ignoreFiltersOnSearch;
  final wantDownloads = downloadFilterType != 0 || downloadedOnly;
  final needsStats = !searchOnly &&
      (wantDownloads ||
          unreadFilterType != 0 ||
          startedFilterType != 0 ||
          bookmarkedFilterType != 0 ||
          sortType == 3 ||
          sortType == 4);
  LibraryChapterStats? stats;
  if (needsStats) {
    final sw = Stopwatch()..start();
    try {
      stats = LibraryChapterStats.load(
        isar,
        downloadedChapterIds: wantDownloads ? downloadedIds : null,
      );
    } catch (e) {
      stats = null;
      AppLogger.logOnce('lib-stats', '[Thư viện] Không đọc được thống kê chương nhanh ($e) – dùng cách cũ',
          logLevel: LogLevel.warning);
    }
    if (sw.elapsedMilliseconds > 250) {
      AppLogger.log('[Hiệu năng] Thống kê chương thư viện mất ${sw.elapsedMilliseconds} ms (${data.length} mục)');
    }
  }
  final st = stats;
  bool fast(Manga m) => st != null && m.id != null && st.covers(m.id!);

  // Skip all filters, just do search
  if (searchQuery.isNotEmpty && ignoreFiltersOnSearch) {
    mangas = data
        .where((element) => _matchesSearchQuery(element, searchQuery))
        .toList();
  } else {
    mangas = data.where((element) {
      // Filter by download — uses Set lookup instead of per-chapter Isar query
      if ((downloadFilterType == 1 || downloadedOnly) && fast(element)) {
        if (!st!.hasDownload(element.id!)) return false;
      } else if (downloadFilterType == 2 && fast(element)) {
        if (st!.hasDownload(element.id!)) return false;
      } else if (downloadFilterType == 1 || downloadedOnly) {
        final hasDownloaded = element.chapters.any(
          (chap) => chap.id != null && downloadedIds.contains(chap.id),
        );
        if (!hasDownloaded) return false;
      } else if (downloadFilterType == 2) {
        final allNotDownloaded = element.chapters.every(
          (chap) => chap.id == null || !downloadedIds.contains(chap.id),
        );
        if (!allNotDownloaded) return false;
      }

      // Filter by unread or started
      if ((unreadFilterType == 1 || startedFilterType == 1) && fast(element)) {
        if (st!.unreadOf(element.id!) <= 0) return false;
      } else if ((unreadFilterType == 2 || startedFilterType == 2) && fast(element)) {
        if (st!.unreadOf(element.id!) > 0) return false;
      } else if (unreadFilterType == 1 || startedFilterType == 1) {
        final hasUnread = element.chapters.any((chap) => !chap.isRead!);
        if (!hasUnread) return false;
      } else if (unreadFilterType == 2 || startedFilterType == 2) {
        final allRead = element.chapters.every((chap) => chap.isRead!);
        if (!allRead) return false;
      }

      // Filter by bookmarked
      if (bookmarkedFilterType == 1 && fast(element)) {
        if (!st!.hasBookmark(element.id!)) return false;
      } else if (bookmarkedFilterType == 2 && fast(element)) {
        if (st!.hasBookmark(element.id!)) return false;
      } else if (bookmarkedFilterType == 1) {
        final hasBookmarked = element.chapters.any(
          (chap) => chap.isBookmarked!,
        );
        if (!hasBookmarked) return false;
      } else if (bookmarkedFilterType == 2) {
        final allNotBookmarked = element.chapters.every(
          (chap) => !chap.isBookmarked!,
        );
        if (!allNotBookmarked) return false;
      }

      // Filter by completed status
      if (completedFilterType == 1) {
        if (element.status != Status.completed) return false;
      } else if (completedFilterType == 2) {
        if (element.status == Status.completed) return false;
      }

      // Filter by tracking
      if (trackingFilterType == 1) {
        if (element.id == null || !trackedIds.contains(element.id)) {
          return false;
        }
      } else if (trackingFilterType == 2) {
        if (element.id != null && trackedIds.contains(element.id)) {
          return false;
        }
      }

      // YomiHub: tag/genre include-exclude (Nekoyomi)
      if (!genreFilter.matches(element)) return false;

      // Filter by source
      if (sourceIds.isNotEmpty) {
        if (element.source == null || !sourceIds.contains(element.source)) {
          return false;
        }
      }

      // Search filter
      if (searchQuery.isNotEmpty) {
        if (!_matchesSearchQuery(element, searchQuery)) return false;
      }

      return true;
    }).toList();
  }

  // Sort
  if (mangas.isNotEmpty) {
    if (sortType == 3) {
      final unreadCounts = <int, int>{};
      for (final manga in mangas) {
        if (manga.id != null) {
          // Scanlator-aware unread count (respects the per-manga filter);
          // 0.5.9: titles without a scanlator filter use the fast stats.
          final hasScanFilter = settings.filterScanlatorList
                  ?.any((e) => e.mangaId == manga.id && (e.scanlators?.isNotEmpty ?? false)) ??
              false;
          unreadCounts[manga.id!] = (!hasScanFilter && fast(manga))
              ? st!.unreadOf(manga.id!)
              : manga.unreadChaptersCount(settings);
        }
      }
      mangas = sortByUnreadCount(
        mangas,
        unreadCountOf: (manga) =>
            manga.id != null ? (unreadCounts[manga.id] ?? 0) : 0,
      );
    } else if (sortType == 4) {
      final totalCounts = <int, int>{};
      for (final manga in mangas) {
        if (manga.id != null) {
          totalCounts[manga.id!] =
              fast(manga) ? st!.totalOf(manga.id!) : manga.chapters.length;
        }
      }
      mangas.sort((a, b) {
        final aVal = a.id != null ? (totalCounts[a.id] ?? 0) : 0;
        final bVal = b.id != null ? (totalCounts[b.id] ?? 0) : 0;
        return aVal.compareTo(bVal);
      });
    } else if (sortType == 5) {
      final lastUpload = {
        for (final manga in mangas)
          manga.id: manga.chapters.lastOrNull?.dateUpload ?? "",
      };
      mangas.sort(
        (a, b) => (lastUpload[a.id] ?? "").compareTo(lastUpload[b.id] ?? ""),
      );
    } else {
      mangas.sort((a, b) {
        switch (sortType) {
          case 0:
            return a.name!.compareTo(b.name!);
          case 1:
            return a.lastRead!.compareTo(b.lastRead!);
          case 2:
            return a.lastUpdate?.compareTo(b.lastUpdate ?? 0) ?? 0;
          case 6:
            return a.dateAdded?.compareTo(b.dateAdded ?? 0) ?? 0;
          default:
            return 0;
        }
      });
    }
  }

  return mangas;
}

bool _matchesSearchQuery(Manga manga, String query) {
  final keywords = query
      .toLowerCase()
      .split(',')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty);

  return keywords.any(
    (keyword) =>
        (manga.name?.toLowerCase().contains(keyword) ?? false) ||
        (manga.source?.toLowerCase().contains(keyword) ?? false) ||
        (manga.genre?.any((g) => g.toLowerCase().contains(keyword)) ?? false),
  );
}
