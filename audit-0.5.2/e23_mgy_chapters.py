import sys; sys.path.insert(0,'.')
from edit import edit
R='lib/modules/more/data_and_storage/providers/restore.dart'
edit(R,"""      final currentSettings = settingsRepository.currentOrNull;
      Map<int, int>? restoredChapterIds;
      var installedFromBackup = 0;
      await restoreRepository.run(() {
        if (merge) {
          installedFromBackup = _installBackupExtensions(backup);
          restoredChapterIds = _mergeMangayomiBackup(
            manga: manga,
            chapters: chapters,
            categories: categories,
            history: history,
            updates: updates,
            categoryDecisions: categoryDecisions,
            sourceDecisions: sourceDecisions,
          );""","""      final currentSettings = settingsRepository.currentOrNull;
      Map<int, int>? restoredChapterIds;
      var installedFromBackup = 0;
      // 0.5.2: chapter URLs of the series already in the library, read before
      // the write transaction (asynchronous, in batches) - see
      // _mergeMangayomiBackup.
      final preChapterUrls = <int, Set<String>>{};
      if (merge && manga != null) {
        final links = <String>{
          for (final m in manga)
            if (m.link != null) '${m.itemType.index}|${m.link}',
        };
        preChapterUrls.addAll(await yhChapterUrlsFor([
          for (final m in await mangaRepository.getAllAsync())
            if (m.link != null && links.contains('${m.itemType.index}|${m.link}')) m.id,
        ]));
      }
      await restoreRepository.run(() {
        if (merge) {
          installedFromBackup = _installBackupExtensions(backup);
          restoredChapterIds = _mergeMangayomiBackup(
            manga: manga,
            chapters: chapters,
            categories: categories,
            history: history,
            updates: updates,
            categoryDecisions: categoryDecisions,
            sourceDecisions: sourceDecisions,
            preChapterUrls: preChapterUrls,
          );""")
edit(R,"""  required Map<String, bool> categoryDecisions,
  required Map<String, int> sourceDecisions,
}) {
  final oldToNewCategoryId = <int, int>{};""","""  required Map<String, bool> categoryDecisions,
  required Map<String, int> sourceDecisions,
  Map<int, Set<String>> preChapterUrls = const {},
}) {
  final oldToNewCategoryId = <int, int>{};""")
edit(R,"""  final oldToNewChapterId = <int, int>{};
  if (chapters != null) {
    final existingUrlsByMangaId = <int, Set<String>>{};
    for (final tempChapter in chapters) {
      final newMangaId = tempChapter.mangaId != null
          ? oldToNewMangaId[tempChapter.mangaId]
          : null;
      if (newMangaId == null) continue;
      // Only ever landed on genuinely new manga above - an existing manga's
      // own chapters (with real read/download state) are left untouched.
      if (!newMangaIds.contains(newMangaId)) continue;
      final existingUrls = existingUrlsByMangaId.putIfAbsent(
        newMangaId,
        () => chapterRepository
            .getAllByMangaId(newMangaId)
            .map((c) => c.url)
            .whereType<String>()
            .toSet(),
      );
      if (tempChapter.url != null && existingUrls.contains(tempChapter.url)) {
        continue;
      }
      final mangaRef = mangaRepository.findById(newMangaId);
      if (mangaRef == null) continue;""","""  final oldToNewChapterId = <int, int>{};
  if (chapters != null) {
    final existingUrlsByMangaId = <int, Set<String>>{};
    final mangaById = <int, Manga?>{};
    for (final tempChapter in chapters) {
      final newMangaId = tempChapter.mangaId != null
          ? oldToNewMangaId[tempChapter.mangaId]
          : null;
      if (newMangaId == null) continue;
      // 0.5.2: an existing series also receives the backup's chapters it
      // does not have yet (matched by URL) - its own chapters, with their
      // read/download state, are never touched. Before, the preview and the
      // "Đã nhập … thêm N chương mới" toast counted these chapters but the
      // merge skipped them (Note 9: "5858 chương mới", 0 written).
      final existingUrls = existingUrlsByMangaId.putIfAbsent(
        newMangaId,
        () => newMangaIds.contains(newMangaId)
            ? <String>{}
            : {...?preChapterUrls[newMangaId]},
      );
      if (tempChapter.url != null && existingUrls.contains(tempChapter.url)) {
        continue;
      }
      final mangaRef = mangaById.putIfAbsent(
        newMangaId,
        () => mangaRepository.findById(newMangaId),
      );
      if (mangaRef == null) continue;""")
