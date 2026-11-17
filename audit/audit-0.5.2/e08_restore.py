import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/providers/restore.dart'
edit(F,"""  final inputStream = InputFileStream(path);
  final content = GZipDecoder().decodeBytes(inputStream.toUint8List());
  inputStream.close();
  // YomiHub: bring the other app's extension repositories along.""","""  // 0.5.2: inflated once (platform zlib, background isolate) by the restore
  // screen and reused here instead of a 4th pure-Dart GZipDecoder pass.
  final content = tachiBkBytes(path);
  // YomiHub: bring the other app's extension repositories along.""")
edit(F,"""      await restoreRepository.run(() {
        if (merge) {
          restoredChapterIds = _mergeMangayomiBackup(""","""      var installedFromBackup = 0;
      await restoreRepository.run(() {
        if (merge) {
          installedFromBackup = _installBackupExtensions(backup);
          restoredChapterIds = _mergeMangayomiBackup(""")
edit(F,"""      if (full) {
        if (yomiExtras is Map) {
          await YomiBackupExtras.restore(Map<String, dynamic>.from(yomiExtras));
        }
        _invalidateCommonState(ref);
      }""","""      if (full) {
        if (yomiExtras is Map) {
          await YomiBackupExtras.restore(Map<String, dynamic>.from(yomiExtras));
        }
        _invalidateCommonState(ref);
      } else if (merge) {
        // 0.5.2: the library, the extensions installed above and their
        // settings changed - refresh the screens that show them.
        _invalidateCommonState(ref);
      }
      AppLogger.log(
        '[Sao lưu] Đã khôi phục bản sao lưu YomiHub/Mangayomi (${merge ? 'gộp' : 'thay thế'}): '
        '${manga?.length ?? 0} bộ, ${chapters?.length ?? 0} chương'
        '${installedFromBackup > 0 ? ', cài $installedFromBackup tiện ích có trong bản sao lưu' : ''}',
        logLevel: LogLevel.info,
      );""")
edit(F,"""/// Adds a mangayomi-format backup's library into the existing one instead of""","""/// 0.5.2: a merge ("Gộp") restore skipped the backup's extensions entirely
/// (only a full replace restored them), so every imported title pointed at a
/// source that was not installed: it opened without chapters/episodes and
/// the next restore listed it again under "Không tìm thấy nguồn" (Note 9,
/// Mangayomi backup with 251 installed extensions, 05/11/2026). Extensions
/// the backup carries with their code are now installed when this device
/// has no source of that name/language/type, together with their settings.
/// Returns how many were installed.
int _installBackupExtensions(Map<String, dynamic> backup) {
  final exts = backupInstalledExtensions(backup);
  if (exts.isEmpty) return 0;
  final current = sourceRepository.getAll();
  final byId = {for (final s in current) if (s.id != null) s.id!: s};
  final installedKeys = {
    for (final s in current)
      if (s.isAdded ?? false)
        '${s.itemType.index}|${s.lang}|${s.name?.toLowerCase()}',
  };
  final toPut = <Source>[];
  final newIds = <int>{};
  for (final e in exts) {
    final Source s;
    try {
      s = Source.fromJson(e)..itemType = convertToItemType(e);
    } catch (_) {
      continue;
    }
    final key = '${s.itemType.index}|${s.lang}|${s.name?.toLowerCase()}';
    if (installedKeys.contains(key)) continue;
    final sameId = s.id != null ? byId[s.id] : null;
    if (sameId != null && (sameId.isAdded ?? false)) continue;
    s.isAdded = true;
    s.isActive ??= true;
    toPut.add(s);
    installedKeys.add(key);
    if (s.id != null) newIds.add(s.id!);
  }
  if (toPut.isEmpty) return 0;
  sourceRepository.putAllSync(toPut);
  final extras = backup['yomihub'];
  final prefs = <dynamic>[
    ...?(backup['extensions_preferences'] as List?),
    if (extras is Map) ...?(extras['extensions_preferences'] as List?),
  ];
  final prefsToPut = <SourcePreference>[];
  final seen = <String>{};
  for (final p in prefs) {
    if (p is! Map) continue;
    try {
      final sp = SourcePreference.fromJson(Map<String, dynamic>.from(p));
      if (sp.sourceId == null || !newIds.contains(sp.sourceId)) continue;
      if (!seen.add('${sp.sourceId}|${sp.key}')) continue;
      if (sourcePreferenceRepository.findByKey(sp.sourceId, sp.key) != null) continue;
      sp.id = null; // never overwrite another source's preference row
      prefsToPut.add(sp);
    } catch (_) {}
  }
  if (prefsToPut.isNotEmpty) sourcePreferenceRepository.putAllSync(prefsToPut);
  return toPut.length;
}

/// Adds a mangayomi-format backup's library into the existing one instead of""")
edit(F,"""    if (backupType != BackupType.unknown) {
      showBotToast("Backup restored!");""","""    if (backupType != BackupType.unknown) {
      showBotToast(tr("Đã khôi phục bản sao lưu!"));
      AppLogger.log('[Sao lưu] Khôi phục xong: ${p.basename(path)} (${backupType.name}${merge ? ', gộp' : ''})',
          logLevel: LogLevel.info);""")
edit(F,"""      showBotToast("Backup Type not supported!");
    }
  } catch (e, s) {
    toastError(e, stack: s, source: 'restore');""","""      showBotToast(tr("Định dạng bản sao lưu không được hỗ trợ!"));
      AppLogger.log('[Sao lưu] Không nhận ra định dạng bản sao lưu: ${p.basename(path)}',
          logLevel: LogLevel.warning);
    }
  } catch (e, s) {
    // 0.5.2: restore failures reach the app log too (Feature Check 34).
    AppLogger.log('[Sao lưu] Khôi phục thất bại (${p.basename(path)}): $e\\n$s',
        logLevel: LogLevel.error);
    toastError(e, stack: s, source: 'restore');""")
