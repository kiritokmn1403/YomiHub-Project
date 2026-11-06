// Detecting what kind of backup a file is, and previewing what restoring it
// would do, without writing anything to local storage. Kept apart from
// restore.dart (which actually performs the write) so a backup can be
// inspected - format, conflicts, counts - before the user commits to
// anything destructive.
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:collection/collection.dart';
import 'package:mangayomi/models/category.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/proto/BackupAniyomi.pb.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/proto/BackupMihon.pb.dart';
import 'package:mangayomi/repositories/category_repository.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:protobuf/protobuf.dart';
import 'package:mangayomi/yomihub/repos/repo_importer.dart';
import 'package:mangayomi/yomihub/backup/lnreader_backup.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:path/path.dart' as p;

enum BackupType { unknown, mangayomi, mihon, aniyomi, kotatsu, neko, lnreader }

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

void clearTachiBkCache() {
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
  final sw = Stopwatch()..start();
  final d = await Isolate.run(() => _decodeTachiBk(yhGunzip(File(path).readAsBytesSync()), anime));
  _decodedCache = (key, d);
  AppLogger.log(
    '[Sao lưu] Đã giải mã ${p.basename(path)} (${type.name}) ở luồng nền trong ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
    logLevel: LogLevel.info, always: true,
  );
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

BackupType checkBackupType(String path, Archive archive) {
  // YomiHub 0.1.8: backups are now named yomihub_….backup; the old
  // mangayomi_… name (and renamed files) are still recognised by content.
  if ((archive.files.firstOrNull?.name ?? "").endsWith(".backup.db")) {
    return BackupType.mangayomi;
  } else if (path.toLowerCase().contains("kotatsu") &&
      archive.files.where((f) {
            switch (f.name) {
              case "categories":
              case "favourites":
                return true;
              default:
                return false;
            }
          }).length ==
          2) {
    return BackupType.kotatsu;
  } else if (isLnReaderBackup(archive)) {
    // YomiHub 0.1.7: LNReader (Version.json + NovelAndChapters/…)
    return BackupType.lnreader;
  } else if (path.toLowerCase().endsWith(".tachibk") ||
      path.toLowerCase().endsWith(".proto.gz")) {
    // YomiHub: look at the content, not only the file name. Nekoyomi
    // ("app.nekoyomi_…tachibk"), Anikku and renamed files were detected as
    // Neko/unknown and their anime and extension repos were lost.
    final flavour = _sniffTachiBk(path);
    if (flavour != null) return flavour;
    return path.contains("xyz.jmir.tachiyomi.mi") || path.contains("aniyomi.mi")
        ? BackupType.aniyomi
        : path.contains("tachiyomi") ||
              path.contains("mihon") ||
              path.contains("komikku")
        ? BackupType.mihon
        : path.contains("neko")
        ? BackupType.neko
        : BackupType.unknown;
  }
  return BackupType.unknown;
}

BackupType peekBackupType(String path) {
  final inputStream = InputFileStream(path);
  try {
    final archive = ZipDecoder().decodeStream(inputStream);
    return checkBackupType(path, archive);
  } finally {
    inputStream.close();
  }
}

class TachiBkImportPreview {
  TachiBkImportPreview({
    required this.conflictingCategories,
    required this.unmatchedSourceNames,
    required this.newSeriesCount,
    required this.updatedSeriesCount,
    required this.newChapterCount,
  });

  final List<String> conflictingCategories;

  final Map<String, ItemType> unmatchedSourceNames;

  final int newSeriesCount;
  final int updatedSeriesCount;
  final int newChapterCount;
}

Future<TachiBkImportPreview?> previewTachiBkImport(String path) async {
  final backupType = peekBackupType(path);
  if (backupType != BackupType.mihon &&
      backupType != BackupType.aniyomi &&
      backupType != BackupType.neko) {
    return null;
  }
  final decoded = await decodeTachiBkAsync(path, backupType);
  final backup = decoded.mihon;
  final swPreview = Stopwatch()..start();
  var yieldN = 0; // 0.5.2: let the progress dialog draw between entries

  final existingCategoryNames = categoryRepository
      .getAll()
      .map((c) => c.name)
      .whereType<String>()
      .toSet();
  final categoryNames = <String>{for (var c in backup.backupCategories) c.name};

  final installedSourceNames = sourceRepository
      .getAll()
      .where((s) => s.isAdded ?? false)
      .map((s) => (s.itemType, s.name?.toLowerCase()))
      .toSet();
  final unmatchedSources = <String, ItemType>{};

  // 0.5.2 (Note 9, 12 MB TachiyomiMi backup into a 2 698-series library):
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
  ]);
  int newSeries = 0, updatedSeries = 0, newChapters = 0;
  for (var m in backup.backupManga) {
    if (++yieldN % 150 == 0) await Future<void>.delayed(Duration.zero);
    final sourceId = protoInt(m.source);
    final srcName =
        backup.backupSources
            .firstWhereOrNull((s) => protoInt(s.sourceId) == sourceId)
            ?.name ??
        "Unknown";
    if (!installedSourceNames.contains((
      ItemType.manga,
      srcName.toLowerCase(),
    ))) {
      unmatchedSources[srcName] = ItemType.manga;
    }
    final existing = existingMangaByLink[m.url];
    if (existing != null) {
      updatedSeries++;
      final existingUrls = chapterUrls[existing.id] ?? const <String>{};
      newChapters += m.chapters
          .where((c) => !existingUrls.contains(c.url))
          .length;
    } else {
      newSeries++;
      newChapters += m.chapters.length;
    }
  }

  if (backupType == BackupType.aniyomi) {
    final backupAnime = decoded.aniyomi!;
    final animeCategories = backupAnime.backupAnimeCategories.isNotEmpty
        ? backupAnime.backupAnimeCategories
        : backupAnime.legacyBackupAnimeCategories;
    final animeEntries = backupAnime.backupAnime.isNotEmpty
        ? backupAnime.backupAnime
        : backupAnime.legacyBackupAnime;
    final animeSources = backupAnime.backupAnimeSources.isNotEmpty
        ? backupAnime.backupAnimeSources
        : backupAnime.legacyBackupAnimeSources;
    categoryNames.addAll(animeCategories.map((c) => c.name));
    final existingAnimeByLink = {
      for (var m in allSeries)
        if (m.itemType == ItemType.anime && m.link != null) m.link!: m,
    };
    final episodeUrls = await _chapterUrlsFor([
      for (var a in animeEntries) existingAnimeByLink[a.url]?.id,
    ]);
    for (var a in animeEntries) {
      if (++yieldN % 150 == 0) await Future<void>.delayed(Duration.zero);
      final sourceId = protoInt(a.source);
      final srcName =
          animeSources
              .firstWhereOrNull((s) => protoInt(s.sourceId) == sourceId)
              ?.name ??
          "Unknown";
      if (!installedSourceNames.contains((
        ItemType.anime,
        srcName.toLowerCase(),
      ))) {
        unmatchedSources[srcName] = ItemType.anime;
      }
      final existing = existingAnimeByLink[a.url];
      if (existing != null) {
        updatedSeries++;
        final existingUrls = episodeUrls[existing.id] ?? const <String>{};
        newChapters += a.episodes
            .where((c) => !existingUrls.contains(c.url))
            .length;
      } else {
        newSeries++;
        newChapters += a.episodes.length;
      }
    }
  }

  AppLogger.log(
    '[Sao lưu] Xem trước ${p.basename(path)}: $newSeries bộ mới, $updatedSeries cập nhật, $newChapters chương mới (${(swPreview.elapsedMilliseconds / 1000).toStringAsFixed(1)} s)',
    logLevel: LogLevel.info, always: true,
  );
  return TachiBkImportPreview(
    conflictingCategories: categoryNames
        .where(existingCategoryNames.contains)
        .toList(),
    unmatchedSourceNames: unmatchedSources,
    newSeriesCount: newSeries,
    updatedSeriesCount: updatedSeries,
    newChapterCount: newChapters,
  );
}

List<Source> installedSourcesFor(ItemType itemType) => sourceRepository
    .getAll()
    .where((s) => s.itemType == itemType && (s.isAdded ?? false))
    .toList();

/// Same preview shape as previewTachiBkImport, but for the native
/// mangayomi backup format - already-decoded (and, for encrypted backups,
/// already-decrypted) JSON rather than a path to re-read from disk.
Future<TachiBkImportPreview> previewMangayomiBackup(Map<String, dynamic> backup) async {
  final swPreview = Stopwatch()..start();
  final mangaList = (backup["manga"] as List?)
      ?.map((e) => Manga.fromJson(e)..itemType = convertToItemType(e))
      .toList();
  // 0.5.2: only mangaId + url are needed here - read them from the raw JSON
  // instead of building ~90 000 Chapter objects on the UI isolate.
  final categoryList = (backup["categories"] as List?)
      ?.map(
        (e) =>
            Category.fromJson(e)..forItemType = convertToItemTypeCategory(e),
      )
      .toList();

  final existingCategoryNames = categoryRepository
      .getAll()
      .map((c) => c.name)
      .whereType<String>()
      .toSet();
  final categoryNames = <String>{
    for (final c in categoryList ?? <Category>[])
      if (c.name != null) c.name!,
  };

  final installedSourceNames = sourceRepository
      .getAll()
      .where((s) => s.isAdded ?? false)
      .map((s) => (s.itemType, s.name?.toLowerCase()))
      .toSet();
  for (final e in backupInstalledExtensions(backup)) {
    installedSourceNames.add((convertToItemType(e), '${e['name']}'.toLowerCase()));
  }
  final unmatchedSources = <String, ItemType>{};

  // 0.5.2: asynchronous, batched reads (see previewTachiBkImport) - the
  // 22 MB Mangayomi backup took ~100 s on the Note 9 before its first dialog.
  final existingMangaByKey = {
    for (final m in await mangaRepository.getAllAsync())
      if (m.link != null) '${m.itemType.index}|${m.link}': m,
  };
  final existingChapterUrls = await _chapterUrlsFor([
    for (final m in mangaList ?? <Manga>[])
      if (m.link != null) existingMangaByKey['${m.itemType.index}|${m.link}']?.id,
  ]);
  final chaptersByMangaId = <int, List<String?>>{};
  for (final c in (backup["chapters"] as List?) ?? const []) {
    if (c is! Map) continue;
    final mid = c['mangaId'];
    if (mid is! int) continue;
    chaptersByMangaId.putIfAbsent(mid, () => []).add(c['url'] as String?);
  }

  int newSeries = 0, updatedSeries = 0, newChapters = 0;
  var yieldN = 0;
  for (final m in mangaList ?? <Manga>[]) {
    if (++yieldN % 150 == 0) await Future<void>.delayed(Duration.zero);
    final srcName = m.source ?? "Unknown";
    if (!installedSourceNames.contains((m.itemType, srcName.toLowerCase()))) {
      unmatchedSources[srcName] = m.itemType;
    }
    final key = '${m.itemType.index}|${m.link}';
    final existing = m.link != null ? existingMangaByKey[key] : null;
    final mangaChapters = m.id != null
        ? chaptersByMangaId[m.id!] ?? const <String?>[]
        : const <String?>[];
    if (existing != null) {
      updatedSeries++;
      final existingUrls = existingChapterUrls[existing.id] ?? const <String>{};
      newChapters += mangaChapters
          .where((u) => u != null && !existingUrls.contains(u))
          .length;
    } else {
      newSeries++;
      newChapters += mangaChapters.length;
    }
  }

  AppLogger.log(
    '[Sao lưu] Xem trước bản sao lưu Mangayomi/YomiHub: $newSeries bộ mới, $updatedSeries cập nhật, $newChapters chương mới (${(swPreview.elapsedMilliseconds / 1000).toStringAsFixed(1)} s)',
    logLevel: LogLevel.info, always: true,
  );
  return TachiBkImportPreview(
    conflictingCategories: categoryNames
        .where(existingCategoryNames.contains)
        .toList(),
    unmatchedSourceNames: unmatchedSources,
    newSeriesCount: newSeries,
    updatedSeriesCount: updatedSeries,
    newChapterCount: newChapters,
  );
}

int currentFavoriteMangaCount() => mangaRepository.countFavorites();

ItemType convertToItemType(Map<String, dynamic> backup) {
  final isManga = backup['isManga'];
  return isManga == null
      ? ItemType.values[backup['itemType'] ?? 0]
      : isManga
      ? ItemType.manga
      : ItemType.anime;
}

ItemType convertToItemTypeCategory(Map<String, dynamic> backup) {
  final forManga = backup['forManga'];
  return forManga == null
      ? ItemType.values[backup['forItemType'] ?? 0]
      : forManga
      ? ItemType.manga
      : ItemType.anime;
}

int protoInt(Object value) {
  if (value is int) {
    return value;
  }
  return (value as dynamic).toInt() as int;
}

int secondsToMillis(Object seconds) => protoInt(seconds) * 1000;

Status convertStatusFromTachiBk(int idx) {
  switch (idx) {
    case 1:
      return Status.ongoing;
    case 2:
      return Status.completed;
    case 4:
      return Status.publishingFinished;
    case 5:
      return Status.canceled;
    case 6:
      return Status.onHiatus;
    default:
      return Status.unknown;
  }
}


/// Public entry for the restore (merge) - see [_chapterUrlsFor].
Future<Map<int, Set<String>>> yhChapterUrlsFor(Iterable<int?> ids) =>
    _chapterUrlsFor(ids);

/// Chapter URLs of the given series, read in batches of 200 ids with
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

BackupType? _sniffTachiBk(String path) {
  try {
    final data = tachiBkBytes(path);
    if (data.isEmpty) return null;
    if (YomiRepoImporter.isAniyomiFlavour(data)) return BackupType.aniyomi;
    final lower = path.toLowerCase();
    // Neko (the MangaDex app) keeps its own extra fields; everything else
    // in the Tachiyomi family reads as Mihon.
    if (lower.contains('neko') && !lower.contains('nekoyomi')) return BackupType.neko;
    return BackupType.mihon;
  } catch (_) {
    return null;
  }
}
