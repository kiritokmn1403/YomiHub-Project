import sys; sys.path.insert(0,'.')
from edit import edit
B='lib/modules/more/data_and_storage/providers/backup_format.dart'
edit(B,"""Future<TachiBkImportPreview> previewMangayomiBackup(Map<String, dynamic> backup) async {
  final mangaList""","""Future<TachiBkImportPreview> previewMangayomiBackup(Map<String, dynamic> backup) async {
  final swPreview = Stopwatch()..start();
  final mangaList""")
edit(B,"""  final existingMangaByKey = {
    for (final m in mangaRepository.getAll())
      if (m.link != null) '${m.itemType.index}|${m.link}': m,
  };""","""  // 0.5.2: asynchronous, batched reads (see previewTachiBkImport) - the
  // 22 MB Mangayomi backup took ~100 s on the Note 9 before its first dialog.
  final existingMangaByKey = {
    for (final m in await mangaRepository.getAllAsync())
      if (m.link != null) '${m.itemType.index}|${m.link}': m,
  };
  final existingChapterUrls = await _chapterUrlsFor([
    for (final m in mangaList ?? <Manga>[])
      if (m.link != null) existingMangaByKey['${m.itemType.index}|${m.link}']?.id,
  ]);""")
edit(B,"""    if (existing != null) {
      updatedSeries++;
      final existingUrls = chapterRepository
          .getAllByMangaId(existing.id)
          .map((c) => c.url)
          .whereType<String>()
          .toSet();
      newChapters += mangaChapters""","""    if (existing != null) {
      updatedSeries++;
      final existingUrls = existingChapterUrls[existing.id] ?? const <String>{};
      newChapters += mangaChapters""")
edit(B,"""      newChapters += mangaChapters.length;
    }
  }

  return TachiBkImportPreview(""","""      newChapters += mangaChapters.length;
    }
  }

  AppLogger.log(
    '[Sao lưu] Xem trước bản sao lưu Mangayomi/YomiHub: $newSeries bộ mới, $updatedSeries cập nhật, $newChapters chương mới (${(swPreview.elapsedMilliseconds / 1000).toStringAsFixed(1)} s)',
    logLevel: LogLevel.info, always: true,
  );
  return TachiBkImportPreview(""")
