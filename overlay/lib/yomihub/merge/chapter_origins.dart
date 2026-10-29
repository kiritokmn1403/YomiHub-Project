import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/utils/utils.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// Source identity belongs to a chapter even after moving it to a merged title.
/// Stored in the existing backed-up preferences box; scanlator remains the
/// translation group's name and is never used as an extension identifier.
class ChapterOrigins {
  static const _key = 'mergedChapterOrigins';

  static Map? of(Chapter chapter) {
    final value = YomiPrefs.get<Map>(_key, const {})['${chapter.id}'];
    if (value is! Map) return null;
    if (value['chapterUrl'] != null && value['chapterUrl'] != chapter.url)
      return null;
    return value;
  }

  /// Checks whether a manga title contains chapters originating from merged sources.
  ///
  /// 0.4.3: answered from a cached set of merged manga ids. The old version
  /// walked every stored chapter origin for every library cover that was
  /// built, which made scrolling a large library with merged titles stutter
  /// (sheet "YomiHub Update": "Hợp nhất … rất lag … gây treo").
  static bool isMangaMerged(int? mangaId) {
    if (mangaId == null || !YomiPrefs.isOpen) return false;
    return _mergedIds().contains(mangaId);
  }

  static Object? _cacheSrc;
  static Set<int> _cache = const {};

  static Set<int> _mergedIds() {
    final origins = YomiPrefs.get<Map>(_key, const {});
    if (identical(origins, _cacheSrc)) return _cache;
    final ids = <int>{};
    for (final v in origins.values) {
      if (v is Map && v['mangaId'] is int) ids.add(v['mangaId'] as int);
    }
    _cacheSrc = origins;
    _cache = ids;
    return ids;
  }

  static Future<void> capture(List<Manga> mangas) async {
    if (!YomiPrefs.isOpen) throw StateError('Merge storage is not open');
    final origins = Map<String, dynamic>.from(
      YomiPrefs.get<Map>(_key, const {}),
    );
    for (final manga in mangas) {
      for (final chapter in chapterRepository.getAllByMangaId(manga.id)) {
        origins.putIfAbsent(
          '${chapter.id}',
          () => {
            'sourceId': manga.sourceId,
            'source': manga.source,
            'lang': manga.lang,
            'link': manga.link,
            'mangaId': manga.id,
            'chapterUrl': chapter.url,
          },
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
    await YomiPrefs.set(_key, origins);
  }

  /// A merged backup receives new database IDs. Never attach its source
  /// metadata to unrelated chapters that happen to have the old IDs.
  static Future<void> restore(dynamic incoming, {Map<int, int>? idMap}) async {
    final restored = idMap == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(YomiPrefs.get<Map>(_key, const {}));
    if (incoming is Map) {
      for (final entry in incoming.entries) {
        final oldId = int.tryParse('${entry.key}');
        final newId = idMap == null ? oldId : idMap[oldId];
        if (newId != null && entry.value is Map)
          restored['$newId'] = entry.value;
      }
    }
    await YomiPrefs.set(_key, restored);
  }

  /// 0.4.3: [owner] (the title being shown) avoids loading the Isar link
  /// of every chapter one by one while the chapter list is built.
  static String sourceLabel(Chapter chapter, [Manga? owner]) =>
      (of(chapter)?['source'] as String?) ??
      (owner ?? chapter.manga.value)?.source ??
      '';

  static String sourceKey(Chapter chapter, [Manga? owner]) {
    final origin = of(chapter);
    final manga = origin != null ? null : (owner ?? chapter.manga.value);
    return '${origin?['sourceId'] ?? manga?.sourceId}|'
        '${origin?['source'] ?? manga?.source}|${origin?['lang'] ?? manga?.lang}';
  }

  static Source? sourceFor(Chapter chapter) {
    final origin = of(chapter);
    final manga = chapter.manga.value;
    return getSource(
      (origin?['lang'] as String?) ?? manga?.lang ?? '',
      (origin?['source'] as String?) ?? manga?.source ?? '',
      (origin?['sourceId'] as int?) ?? manga?.sourceId,
      installedOnly: true,
    );
  }
}
