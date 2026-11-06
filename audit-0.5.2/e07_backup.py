import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/providers/backup_format.dart'
edit(F,"import 'dart:io';\nimport 'dart:typed_data';\n","import 'dart:io';\nimport 'dart:isolate';\nimport 'dart:typed_data';\n")
edit(F,"""enum BackupType { unknown, mangayomi, mihon, aniyomi, kotatsu, neko, lnreader }
""","""enum BackupType { unknown, mangayomi, mihon, aniyomi, kotatsu, neko, lnreader }

// ---- 0.5.2: "Sao lưu / Khôi phục bị lỗi" (sheet YomiHub Update) ----------
// Restoring a 12 MB Mihon/Aniyomi .tachibk on the Note 9 showed nothing for
// 45 s before the first dialog (tested 05/11/2026): the file was inflated with
// archive's pure-Dart GZipDecoder up to four times (type sniff, preview,
// restore, repo import), all on the UI isolate. It is now inflated once with
// the platform zlib (dart:io gzip), off the UI isolate, and kept for the
// rest of the restore flow.
class _TachiBkBytes {
  _TachiBkBytes(this.key, this.bytes);
  final String key;
  final Uint8List bytes;
}

_TachiBkBytes? _tachiBkCache;

String _tachiBkKey(String path) {
  final st = File(path).statSync();
  return '$path|${st.size}|${st.modified.millisecondsSinceEpoch}';
}

/// gzip → bytes with the platform zlib; archive's decoder as a fallback.
Uint8List yhGunzip(List<int> raw) {
  try {
    final d = gzip.decode(raw);
    return d is Uint8List ? d : Uint8List.fromList(d);
  } catch (_) {
    return Uint8List.fromList(GZipDecoder().decodeBytes(raw));
  }
}

/// The inflated content of a .tachibk / .proto.gz file (cached per file).
Uint8List tachiBkBytes(String path) {
  final key = _tachiBkKey(path);
  final c = _tachiBkCache;
  if (c != null && c.key == key) return c.bytes;
  final bytes = yhGunzip(File(path).readAsBytesSync());
  _tachiBkCache = _TachiBkBytes(key, bytes);
  return bytes;
}

/// Inflates [path] in a background isolate so the UI keeps drawing.
Future<void> warmTachiBk(String path) async {
  final key = _tachiBkKey(path);
  if (_tachiBkCache?.key == key) return;
  final bytes = await Isolate.run(() => yhGunzip(File(path).readAsBytesSync()));
  _tachiBkCache = _TachiBkBytes(key, bytes);
}

void clearTachiBkCache() => _tachiBkCache = null;

/// 0.5.2: extensions a mangayomi/YomiHub backup carries with their code -
/// a merge restore installs them, so they must not be reported as missing.
List<Map<String, dynamic>> backupInstalledExtensions(Map<String, dynamic> backup) {
  final extras = backup['yomihub'];
  final all = <dynamic>[
    ...?(backup['extensions'] as List?),
    if (extras is Map) ...?(extras['extensions'] as List?),
  ];
  return [
    for (final e in all)
      if (e is Map &&
          e['isAdded'] == true &&
          '${e['sourceCode'] ?? ''}'.isNotEmpty &&
          '${e['name'] ?? ''}'.isNotEmpty)
        Map<String, dynamic>.from(e),
  ];
}
""")
edit(F,"""  final inputStream = InputFileStream(path);
  final content = GZipDecoder().decodeBytes(inputStream.toUint8List());
  inputStream.close();
  final backup = BackupMihon.create();""","""  final content = tachiBkBytes(path);
  final backup = BackupMihon.create();""")
edit(F,"""    final raw = File(path).readAsBytesSync();
    final data = Uint8List.fromList(GZipDecoder().decodeBytes(raw));""","""    final data = tachiBkBytes(path);""")
edit(F,"""  final installedSourceNames = sourceRepository
      .getAll()
      .where((s) => s.isAdded ?? false)
      .map((s) => (s.itemType, s.name?.toLowerCase()))
      .toSet();
  final unmatchedSources = <String, ItemType>{};

  final existingMangaByKey = {""","""  final installedSourceNames = sourceRepository
      .getAll()
      .where((s) => s.isAdded ?? false)
      .map((s) => (s.itemType, s.name?.toLowerCase()))
      .toSet();
  for (final e in backupInstalledExtensions(backup)) {
    installedSourceNames.add((convertToItemType(e), '${e['name']}'.toLowerCase()));
  }
  final unmatchedSources = <String, ItemType>{};

  final existingMangaByKey = {""")
