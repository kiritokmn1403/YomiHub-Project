import 'dart:async';
import 'dart:io';

import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/download.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/download_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/services/downloaded_chapter.dart';
import 'package:mangayomi/utils/extensions/string_extensions.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path/path.dart' as p;

/// Result of one indexing pass.
class DownloadIndexResult {
  final int files;
  final int added;
  final int removed;
  final Duration took;
  DownloadIndexResult(this.files, this.added, this.removed, this.took);
}

/// YomiHub 0.1.8: download index (Data & storage › "Lập chỉ mục tải xuống",
/// on by default).
///
/// Like Mihon / Aniyomi's DownloadCache and Kotatsu's local index: the
/// download folder is scanned once (one directory listing per title, not one
/// file check per chapter) and compared with the download records, so that
///  * chapters / episodes whose files are on disk but unknown to the app
///    (copied from another phone or PC, restored backup, reinstall, files
///    of Mihon/Aniyomi/Mangayomi moved into the YomiHub folder) show as
///    downloaded and open offline;
///  * records whose files were deleted outside the app are cleared, so
///    "Downloaded" filters and badges stay right.
/// Runs after start-up (at most every 6 h) and from the settings button.
class YomiDownloadIndex {
  YomiDownloadIndex._();
  static bool _running = false;

  static bool get enabled => YomiPrefs.downloadIndexing;
  static int get lastRun => YomiPrefs.get<int>('downloadIndexAt', 0);
  static int get lastFiles => YomiPrefs.get<int>('downloadIndexFiles', 0);

  static const _media = {'.cbz', '.zip', '.mp4', '.mkv', '.webm', '.ts', '.m4v', '.html', '.epub'};

  static String _typeFolder(ItemType t) => switch (t) {
        ItemType.manga => 'Manga',
        ItemType.anime => 'Anime',
        ItemType.novel => 'Novel',
      };

  /// Background pass after start-up.
  static Future<void> runIfDue() async {
    if (!enabled) return;
    if (DateTime.now().millisecondsSinceEpoch - lastRun < const Duration(hours: 6).inMilliseconds) return;
    await run();
  }

  static Future<DownloadIndexResult?> run() async {
    if (_running) return null;
    _running = true;
    final sw = Stopwatch()..start();
    var files = 0, added = 0, removed = 0;
    try {
      final root = await StorageProvider().getDirectory();
      if (root == null) return null;
      final downloads = Directory(p.join(root.path, 'downloads'));
      // "<type>/<source (LANG)>/<title>" → names (without extension) inside
      final index = <String, Set<String>>{};
      if (await downloads.exists()) {
        for (final t in ItemType.values) {
          final typeDir = Directory(p.join(downloads.path, _typeFolder(t)));
          if (!await typeDir.exists()) continue;
          await for (final src in typeDir.list(followLinks: false)) {
            if (src is! Directory) continue;
            await for (final title in src.list(followLinks: false)) {
              if (title is! Directory) continue;
              final names = <String>{};
              await for (final e in title.list(followLinks: false)) {
                final base = p.basename(e.path);
                if (e is Directory) {
                  names.add(base.trim());
                  files++;
                } else if (_media.contains(p.extension(base).toLowerCase())) {
                  names.add(p.basenameWithoutExtension(base).trim());
                  files++;
                }
              }
              index['${_typeFolder(t)}/${p.basename(src.path)}/${p.basename(title.path)}'] = names;
            }
          }
        }
      }
      // titles that can have downloads: library + every title with a record
      final recorded = downloadRepository.getAll();
      final recordedIds = {for (final d in recorded) d.id!: d};
      final mangaIds = <int>{
        ...mangaRepository.getFavorites().map((m) => m.id!).whereType<int>(),
      };
      for (final d in recorded) {
        final c = chapterRepository.findByIdSync(d.id!);
        final mid = c?.mangaId;
        if (mid != null) mangaIds.add(mid);
      }
      final toAdd = <Chapter>[];
      final toRemove = <int>[];
      int scannedCount = 0;
      for (final mid in mangaIds) {
        await Future.delayed(Duration.zero);
        final m = mangaRepository.findById(mid);
        if (m == null || m.name == null || m.source == null) continue;
        if (m.isLocalArchive ?? false) continue;
        final key =
            '${_typeFolder(m.itemType)}/${m.source} (${(m.lang ?? '').toUpperCase()})/${m.name!.replaceForbiddenCharacters('_')}';
        final names = index[key] ?? const <String>{};
        for (final c in chapterRepository.getAllByMangaId(mid)) {
          scannedCount++;
          if (scannedCount % 20 == 0) {
            await Future.delayed(const Duration(milliseconds: 2));
          }
          if (c.id == null || c.name == null) continue;
          final scan = c.scanlator?.isNotEmpty ?? false ? '${c.scanlator!.replaceForbiddenCharacters('_')}_' : '';
          final entry = (scan + c.name!.replaceForbiddenCharacters('_')).trim();
          final onDisk = names.contains(entry);
          final rec = recordedIds[c.id!];
          if (onDisk && (rec == null || rec.isDownload != true) && rec?.isStartDownload != true) {
            toAdd.add(c);
          } else if (files > 0 && !onDisk && rec?.isDownload == true) {
            if (await findDownloadedChapter(c) == null) toRemove.add(c.id!);
          }
        }
      }
      // YomiHub 0.2.1: an empty or unreadable download folder (storage
      // permission not granted yet, SD card / OneDrive folder not mounted,
      // download location changed) must not wipe every "downloaded" mark.
      // Records are only cleared when the folder really holds downloads.
      if (files == 0 && toRemove.isNotEmpty) {
        AppLogger.log(
          'Download index: download folder is empty or unreadable – kept ${toRemove.length} records',
          logLevel: LogLevel.warning,
        );
        toRemove.clear();
      }
      if (toAdd.isNotEmpty || toRemove.isNotEmpty) {
        await isar.writeTxn(() async {
          for (final c in toAdd) {
            final d = Download(
              id: c.id,
              succeeded: 1,
              failed: 0,
              total: 1,
              isDownload: true,
              isStartDownload: false,
            )..chapter.value = c;
            await isar.downloads.put(d);
            await d.chapter.save();
          }
          for (final id in toRemove) {
            await isar.downloads.delete(id);
          }
        });
      }
      added = toAdd.length;
      removed = toRemove.length;
      await YomiPrefs.set('downloadIndexAt', DateTime.now().millisecondsSinceEpoch);
      await YomiPrefs.set('downloadIndexFiles', files);
      if (added > 0 || removed > 0) {
        AppLogger.log('Download index: $files on disk, +$added, -$removed', logLevel: LogLevel.warning);
      }
      return DownloadIndexResult(files, added, removed, sw.elapsed);
    } catch (e, st) {
      AppLogger.log('Download index failed: $e\n$st', logLevel: LogLevel.error);
      return null;
    } finally {
      _running = false;
    }
  }
}
