import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/providers/backup_format.dart'
edit(F,"""void clearTachiBkCache() => _tachiBkCache = null;
""","""void clearTachiBkCache() {
  _tachiBkCache = null;
  _decodedCache = null;
}

/// 0.5.2: the protobuf decode was the real cost (tested on the Note 9 after
/// moving gunzip off the UI: still 53 s before the first dialog) - ~100 MB of
/// protobuf decoded on the UI isolate twice in the preview (Mihon + Aniyomi
/// schema) and again by the restore. It now runs once, in a background
/// isolate, and the preview and the restore share the result.
class TachiBkDecoded {
  TachiBkDecoded(this.mihon, this.aniyomi);
  final BackupMihon mihon;
  final BackupAniyomi? aniyomi;
}

TachiBkDecoded _decodeTachiBk(Uint8List content, bool anime) {
  final m = BackupMihon.create()
    ..mergeFromCodedBufferReader(CodedBufferReader(content, sizeLimit: 250 << 20));
  final a = anime
      ? (BackupAniyomi.create()
          ..mergeFromCodedBufferReader(CodedBufferReader(content, sizeLimit: 250 << 20)))
      : null;
  return TachiBkDecoded(m, a);
}

(String, TachiBkDecoded)? _decodedCache;

Future<TachiBkDecoded> decodeTachiBkAsync(String path, BackupType type) async {
  final key = '${_tachiBkKey(path)}|${type.name}';
  final c = _decodedCache;
  if (c != null && c.$1 == key) return c.$2;
  final anime = type == BackupType.aniyomi;
  final d = await Isolate.run(() => _decodeTachiBk(yhGunzip(File(path).readAsBytesSync()), anime));
  _decodedCache = (key, d);
  return d;
}

TachiBkDecoded tachiBkDecoded(String path, BackupType type) {
  final key = '${_tachiBkKey(path)}|${type.name}';
  final c = _decodedCache;
  if (c != null && c.$1 == key) return c.$2;
  final d = _decodeTachiBk(tachiBkBytes(path), type == BackupType.aniyomi);
  _decodedCache = (key, d);
  return d;
}
""")
edit(F,"""TachiBkImportPreview? previewTachiBkImport(String path) {
  final backupType = peekBackupType(path);
  if (backupType != BackupType.mihon &&
      backupType != BackupType.aniyomi &&
      backupType != BackupType.neko) {
    return null;
  }
  final content = tachiBkBytes(path);
  final backup = BackupMihon.create();
  backup.mergeFromCodedBufferReader(
    CodedBufferReader(content, sizeLimit: 250 << 20),
  );
""","""Future<TachiBkImportPreview?> previewTachiBkImport(String path) async {
  final backupType = peekBackupType(path);
  if (backupType != BackupType.mihon &&
      backupType != BackupType.aniyomi &&
      backupType != BackupType.neko) {
    return null;
  }
  final decoded = await decodeTachiBkAsync(path, backupType);
  final backup = decoded.mihon;
  var yieldN = 0; // 0.5.2: let the progress dialog draw between entries
""")
edit(F,"""  for (var m in backup.backupManga) {
    final sourceId = protoInt(m.source);""","""  for (var m in backup.backupManga) {
    if (++yieldN % 150 == 0) await Future<void>.delayed(Duration.zero);
    final sourceId = protoInt(m.source);""")
edit(F,"""  if (backupType == BackupType.aniyomi) {
    final backupAnime = BackupAniyomi.fromBuffer(content);""","""  if (backupType == BackupType.aniyomi) {
    final backupAnime = decoded.aniyomi!;""")
edit(F,"""    for (var a in animeEntries) {""","""    for (var a in animeEntries) {
      if (++yieldN % 150 == 0) await Future<void>.delayed(Duration.zero);""")
edit(F,"""TachiBkImportPreview previewMangayomiBackup(Map<String, dynamic> backup) {
  final mangaList = (backup["manga"] as List?)
      ?.map((e) => Manga.fromJson(e)..itemType = convertToItemType(e))
      .toList();
  final chapterList = (backup["chapters"] as List?)
      ?.map((e) => Chapter.fromJson(e))
      .toList();""","""Future<TachiBkImportPreview> previewMangayomiBackup(Map<String, dynamic> backup) async {
  final mangaList = (backup["manga"] as List?)
      ?.map((e) => Manga.fromJson(e)..itemType = convertToItemType(e))
      .toList();
  // 0.5.2: only mangaId + url are needed here - read them from the raw JSON
  // instead of building ~90 000 Chapter objects on the UI isolate.""")
edit(F,"""  final chaptersByMangaId = <int, List<Chapter>>{};
  for (final c in chapterList ?? <Chapter>[]) {
    if (c.mangaId == null) continue;
    chaptersByMangaId.putIfAbsent(c.mangaId!, () => []).add(c);
  }

  int newSeries = 0, updatedSeries = 0, newChapters = 0;
  for (final m in mangaList ?? <Manga>[]) {""","""  final chaptersByMangaId = <int, List<String?>>{};
  for (final c in (backup["chapters"] as List?) ?? const []) {
    if (c is! Map) continue;
    final mid = c['mangaId'];
    if (mid is! int) continue;
    chaptersByMangaId.putIfAbsent(mid, () => []).add(c['url'] as String?);
  }

  int newSeries = 0, updatedSeries = 0, newChapters = 0;
  var yieldN = 0;
  for (final m in mangaList ?? <Manga>[]) {
    if (++yieldN % 150 == 0) await Future<void>.delayed(Duration.zero);""")
edit(F,"""    final mangaChapters = m.id != null
        ? chaptersByMangaId[m.id!] ?? const <Chapter>[]
        : const <Chapter>[];""","""    final mangaChapters = m.id != null
        ? chaptersByMangaId[m.id!] ?? const <String?>[]
        : const <String?>[];""")
edit(F,"""      newChapters += mangaChapters
          .where((c) => c.url != null && !existingUrls.contains(c.url))
          .length;""","""      newChapters += mangaChapters
          .where((u) => u != null && !existingUrls.contains(u))
          .length;""")
F2='lib/modules/more/data_and_storage/providers/restore.dart'
edit(F2,"""  final backup = BackupMihon.create();
  backup.mergeFromCodedBufferReader(
    CodedBufferReader(content, sizeLimit: 250 << 20),
  );
  // sourceCode is never null""","""  // 0.5.2: decoded once in a background isolate by the restore screen.
  final decoded = tachiBkDecoded(path, bkType);
  final backup = decoded.mihon;
  // sourceCode is never null""")
edit(F2,"""  if (bkType == BackupType.aniyomi) {
    final backupAnime = BackupAniyomi.fromBuffer(content);""","""  if (bkType == BackupType.aniyomi) {
    final backupAnime = decoded.aniyomi ?? BackupAniyomi.fromBuffer(content);""")
F3='lib/modules/more/data_and_storage/widgets/unified_restore.dart'
edit(F3,"""        tachiPreview = previewTachiBkImport(path);""","""        tachiPreview = await previewTachiBkImport(path);""")
edit(F3,"""    if (!context.mounted) return;
    final l10n = context.l10n;
    final preview = previewMangayomiBackup(backup);
""","""    if (!context.mounted) return;
    final l10n = context.l10n;
    // 0.5.2: comparing a large backup with the library takes a while - show
    // it instead of a frozen screen.
    showBusyDialog(context, tr('Đang đọc bản sao lưu…'));
    final TachiBkImportPreview preview;
    try {
      preview = await previewMangayomiBackup(backup);
    } finally {
      if (context.mounted) hideBusyDialog(context);
    }
    if (!context.mounted) return;
""")
