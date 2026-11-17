import sys; sys.path.insert(0,'.')
from edit import edit
B='lib/modules/more/data_and_storage/providers/backup_format.dart'
edit(B,"""/// Chapter URLs of the given series, read in batches of 200 ids with
/// asynchronous Isar queries (0.5.2).""","""/// Public entry for the restore (merge) - see [_chapterUrlsFor].
Future<Map<int, Set<String>>> yhChapterUrlsFor(Iterable<int?> ids) =>
    _chapterUrlsFor(ids);

/// Chapter URLs of the given series, read in batches of 200 ids with
/// asynchronous Isar queries (0.5.2).""")
R='lib/modules/more/data_and_storage/providers/restore.dart'
# preload before the manga transaction
edit(R,"""  final categoryByOrder = <int, Category>{};
  await restoreRepository.run(() {
    if (!merge) {
      categoryRepository.clearSync();
      mangaRepository.clearSync();
      chapterRepository.clearSync();
      historyRepository.clearSync();
    }""","""  // 0.5.2 (Note 9: merging a 12 MB TachiyomiMi backup into a 4 400-series
  // library froze the UI for 46 s): the chapter URLs of the series already in
  // the library are read before the write transaction, asynchronously and in
  // batches, instead of one synchronous query per series inside it; series
  // that gain nothing are not rewritten.
  final preChapterUrls = <int, Set<String>>{};
  if (merge) {
    final wanted = <String>{
      for (final m in backup.backupManga) m.url,
      if (bkType == BackupType.aniyomi)
        for (final a in [
          ...?decoded.aniyomi?.backupAnime,
          ...?decoded.aniyomi?.legacyBackupAnime,
        ])
          a.url,
    };
    final ids = <int?>[
      for (final m in await mangaRepository.getAllAsync())
        if (m.link != null && wanted.contains(m.link)) m.id,
    ];
    preChapterUrls.addAll(await yhChapterUrlsFor(ids));
  }
  final categoryByOrder = <int, Category>{};
  await restoreRepository.run(() {
    if (!merge) {
      categoryRepository.clearSync();
      mangaRepository.clearSync();
      chapterRepository.clearSync();
      historyRepository.clearSync();
    }""")
edit(R,"""      final existingManga = existingMangaByLink[tempManga.url];
      final Manga manga;
      final bool isNewManga = existingManga == null;
      if (existingManga != null) {
        manga = existingManga;
        manga.favorite = true;
        manga.categories = {...?manga.categories, ...newCategoryIds}.toList();
      } else {""","""      final existingManga = existingMangaByLink[tempManga.url];
      final Manga manga;
      final bool isNewManga = existingManga == null;
      var changed = isNewManga;
      if (existingManga != null) {
        manga = existingManga;
        final cats = {...?manga.categories, ...newCategoryIds}.toList();
        changed = manga.favorite != true ||
            cats.length != (manga.categories?.length ?? 0);
        manga.favorite = true;
        manga.categories = cats;
      } else {""")
edit(R,"""      mangaRepository.putSync(manga);
      final existingChaptersByUrl = merge && !isNewManga
          ? {
              for (var c in chapterRepository.getAllByMangaId(manga.id))
                if (c.url != null) c.url!: c,
            }
          : <String, Chapter>{};
      History? history;
      for (var tempChapter in tempManga.chapters) {
        if (existingChaptersByUrl.containsKey(tempChapter.url)) continue;""","""      final existingChapterUrls = merge && !isNewManga
          ? (preChapterUrls[manga.id] ?? const <String>{})
          : const <String>{};
      final freshChapters = tempManga.chapters
          .where((c) => !existingChapterUrls.contains(c.url))
          .toList();
      if (!changed && freshChapters.isEmpty) continue;
      mangaRepository.putSync(manga);
      History? history;
      for (var tempChapter in freshChapters) {""")
edit(R,"""        final existingAnime = existingAnimeByLink[tempAnime.url];
        final Manga anime;
        final bool isNewAnime = existingAnime == null;
        if (existingAnime != null) {
          anime = existingAnime;
          anime.favorite = true;
          anime.categories = {...?anime.categories, ...newCategoryIds}.toList();
        } else {""","""        final existingAnime = existingAnimeByLink[tempAnime.url];
        final Manga anime;
        final bool isNewAnime = existingAnime == null;
        var changed = isNewAnime;
        if (existingAnime != null) {
          anime = existingAnime;
          final cats = {...?anime.categories, ...newCategoryIds}.toList();
          changed = anime.favorite != true ||
              cats.length != (anime.categories?.length ?? 0);
          anime.favorite = true;
          anime.categories = cats;
        } else {""")
edit(R,"""        mangaRepository.putSync(anime);
        final existingEpisodesByUrl = merge && !isNewAnime
            ? {
                for (var c in chapterRepository.getAllByMangaId(anime.id))
                  if (c.url != null) c.url!: c,
              }
            : <String, Chapter>{};
        History? history;
        for (var tempEpisode in tempAnime.episodes) {
          if (existingEpisodesByUrl.containsKey(tempEpisode.url)) continue;""","""        final existingEpisodeUrls = merge && !isNewAnime
            ? (preChapterUrls[anime.id] ?? const <String>{})
            : const <String>{};
        final freshEpisodes = tempAnime.episodes
            .where((e) => !existingEpisodeUrls.contains(e.url))
            .toList();
        if (!changed && freshEpisodes.isEmpty) continue;
        mangaRepository.putSync(anime);
        History? history;
        for (var tempEpisode in freshEpisodes) {""")
