import sys; sys.path.insert(0,'.')
from edit import edit
B='lib/modules/more/data_and_storage/providers/backup_format.dart'
# 1) timing of the background decode
edit(B,"""  final anime = type == BackupType.aniyomi;
  final d = await Isolate.run(() => _decodeTachiBk(yhGunzip(File(path).readAsBytesSync()), anime));
  _decodedCache = (key, d);
  return d;""","""  final anime = type == BackupType.aniyomi;
  final sw = Stopwatch()..start();
  final d = await Isolate.run(() => _decodeTachiBk(yhGunzip(File(path).readAsBytesSync()), anime));
  _decodedCache = (key, d);
  AppLogger.log(
    '[Sao lưu] Đã giải mã ${p.basename(path)} (${type.name}) ở luồng nền trong ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
    logLevel: LogLevel.info,
  );
  return d;""")
# 2) existing chapter URLs: one asynchronous batched query instead of a
#    synchronous query per series on the UI thread
edit(B,"""  final decoded = await decodeTachiBkAsync(path, backupType);
  final backup = decoded.mihon;
  var yieldN = 0; // 0.5.2: let the progress dialog draw between entries
""","""  final decoded = await decodeTachiBkAsync(path, backupType);
  final backup = decoded.mihon;
  final swPreview = Stopwatch()..start();
  var yieldN = 0; // 0.5.2: let the progress dialog draw between entries
""")
edit(B,"""  final existingMangaByLink = {
    for (var m in mangaRepository.getByItemType(ItemType.manga))
      if (m.link != null) m.link!: m,
  };""","""  // 0.5.2 (Note 9, 12 MB TachiyomiMi backup into a 2 698-series library):
  // one synchronous chapter query per already-present series froze the UI
  // for 2-3 s at a time ("Giao diện bị treo 2.7 giây"). All series and the
  // chapter URLs of the ones present are now read with asynchronous,
  // batched queries.
  final allSeries = await mangaRepository.getAllAsync();
  final existingMangaByLink = {
    for (var m in allSeries)
      if (m.itemType == ItemType.manga && m.link != null) m.link!: m,
  };
  final chapterUrls = await _chapterUrlsFor([
    for (var m in backup.backupManga) existingMangaByLink[m.url]?.id,
  ]);""")
edit(B,"""    final existing = existingMangaByLink[m.url];
    if (existing != null) {
      updatedSeries++;
      final existingUrls = chapterRepository
          .getAllByMangaId(existing.id)
          .map((c) => c.url)
          .whereType<String>()
          .toSet();
      newChapters += m.chapters
          .where((c) => !existingUrls.contains(c.url))
          .length;""","""    final existing = existingMangaByLink[m.url];
    if (existing != null) {
      updatedSeries++;
      final existingUrls = chapterUrls[existing.id] ?? const <String>{};
      newChapters += m.chapters
          .where((c) => !existingUrls.contains(c.url))
          .length;""")
edit(B,"""    final existingAnimeByLink = {
      for (var m in mangaRepository.getByItemType(ItemType.anime))
        if (m.link != null) m.link!: m,
    };""","""    final existingAnimeByLink = {
      for (var m in allSeries)
        if (m.itemType == ItemType.anime && m.link != null) m.link!: m,
    };
    final episodeUrls = await _chapterUrlsFor([
      for (var a in animeEntries) existingAnimeByLink[a.url]?.id,
    ]);""")
edit(B,"""      final existing = existingAnimeByLink[a.url];
      if (existing != null) {
        updatedSeries++;
        final existingUrls = chapterRepository
            .getAllByMangaId(existing.id)
            .map((c) => c.url)
            .whereType<String>()
            .toSet();""","""      final existing = existingAnimeByLink[a.url];
      if (existing != null) {
        updatedSeries++;
        final existingUrls = episodeUrls[existing.id] ?? const <String>{};""")
edit(B,"""  return TachiBkImportPreview(
    conflictingCategories: categoryNames""","""  AppLogger.log(
    '[Sao lưu] Xem trước ${p.basename(path)}: $newSeries bộ mới, $updatedSeries cập nhật, $newChapters chương mới (${(swPreview.elapsedMilliseconds / 1000).toStringAsFixed(1)} s)',
    logLevel: LogLevel.info,
  );
  return TachiBkImportPreview(
    conflictingCategories: categoryNames""")
edit(B,"""BackupType? _sniffTachiBk(String path) {""","""/// Chapter URLs of the given series, read in batches of 200 ids with
/// asynchronous Isar queries (0.5.2).
Future<Map<int, Set<String>>> _chapterUrlsFor(Iterable<int?> ids) async {
  final wanted = ids.whereType<int>().toSet().toList();
  final out = <int, Set<String>>{};
  for (var i = 0; i < wanted.length; i += 200) {
    final part = wanted.sublist(i, i + 200 > wanted.length ? wanted.length : i + 200);
    for (final c in await chapterRepository.getAllByMangaIds(part)) {
      final id = c.mangaId, url = c.url;
      if (id != null && url != null) (out[id] ??= <String>{}).add(url);
    }
  }
  return out;
}

BackupType? _sniffTachiBk(String path) {""")
