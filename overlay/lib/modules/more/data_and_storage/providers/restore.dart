import 'dart:async';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/repos/repo_importer.dart';
import 'package:mangayomi/yomihub/backup/lnreader_backup.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:path/path.dart' as p;
import 'package:mangayomi/l10n/generated/app_localizations.dart';
import 'package:mangayomi/eval/model/source_preference.dart';
import 'package:mangayomi/yomihub/backup/yomi_backup_extras.dart';
import 'package:mangayomi/models/category.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:mangayomi/models/custom_button.dart';
import 'package:mangayomi/models/download.dart';
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/yomihub/browser/browser_screen.dart'
    show BrowserHistory;
import 'package:mangayomi/modules/more/data_and_storage/providers/backup_decoder.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup_format.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/proto/BackupAniyomi.pb.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/proto/BackupMihon.pb.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/kotatsu_backup.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/blend_level_state_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/flex_scheme_color_state_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/pure_black_dark_mode_state_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/theme_mode_state_provider.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/modules/more/settings/sync/providers/sync_providers.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/router/router.dart';
import 'package:mangayomi/repositories/category_repository.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/custom_button_repository.dart';
import 'package:mangayomi/repositories/download_repository.dart';
import 'package:mangayomi/repositories/history_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/restore_repository.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/repositories/source_preference_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:mangayomi/repositories/update_repository.dart';
import 'package:mangayomi/services/sync_server.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/error_toast.dart';
import 'package:protobuf/protobuf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'restore.g.dart';

@riverpod
Future<void> doRestore(
  Ref ref, {
  required String path,
  required BuildContext context,
  bool merge = false,
  Map<String, bool> categoryDecisions = const {},
  Map<String, int> sourceDecisions = const {},
  // Already-decoded/decrypted mangayomi-format backup, if the caller ran
  // decodeMangayomiBackup itself to preview it first. Skips re-decoding
  // (and re-prompting for a password) here.
  Map<String, dynamic>? decodedMangayomiBackup,
  // Caller's answer to "upload this restore to your sync server?", asked
  // only when a server was connected. true = upload, false = the user chose
  // to turn sync off instead (so stale server data can't come back and
  // undo this restore), null = no server was connected, nothing to do.
  bool? syncAfterRestore,
}) async {
  // Without this, doRestore is autoDispose with only the calling widget's
  // watch keeping it alive — if that widget unmounts mid-restore (dialog
  // closes, screen pops), the provider gets disposed mid-flight and every
  // ref use below throws UnmountedRefException.
  ref.keepAlive();
  // Resolved before any await, so it's safe to use after one.
  final l10n = l10nLocalizations(context);
  // Yield once first: doRestore is itself a provider, and mutating another
  // provider synchronously before its first await counts as modifying it
  // "during initialization", which Riverpod forbids. A microtask (not a
  // real delay) so no frame runs in between — a real delay let the busy
  // dialog close and unmount this autoDispose provider's context first.
  await Future<void>.value();
  // Blocks the auto-sync timer and any manual sync trigger until this
  // restore (and its post-restore upload, if any) finishes — otherwise
  // either could race the restore and pull stale server data back down.
  ref.read(restoreSyncGuardProvider.notifier).start();
  var uploadStarted = false;
  try {
    // Zip filenames aren't encrypted even when file content is, so this
    // initial pass (no password) is always enough to list files and
    // determine backup type. Password resolution only happens below, and
    // only for the mangayomi format, right before reading file *content*.
    final probeStream = InputFileStream(path);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(probeStream);
    } finally {
      probeStream.close();
    }
    final backupType = checkBackupType(path, archive);
    switch (backupType) {
      case BackupType.mangayomi:
        if (!context.mounted) return;
        final backup =
            decodedMangayomiBackup ??
            await decodeMangayomiBackup(path, context);
        await ref.read(
          restoreBackupProvider(
            backup,
            merge: merge,
            categoryDecisions: categoryDecisions,
            sourceDecisions: sourceDecisions,
          ).future,
        );
        break;
      case BackupType.kotatsu:
        await ref.read(restoreKotatsuBackupProvider(archive).future);
        break;
      case BackupType.lnreader:
        final r = await importLnReaderBackup(ref, archive);
        _invalidateCommonState(ref);
        showBotToast(r.toString());
        break;
      case BackupType.mihon:
      case BackupType.aniyomi:
      case BackupType.neko:
        await ref.read(
          restoreTachiBkBackupProvider(
            path,
            backupType,
            merge: merge,
            categoryDecisions: categoryDecisions,
            sourceDecisions: sourceDecisions,
          ).future,
        );
        break;
      default:
    }
    // 0.5.2: refresh the screens here - this provider is kept alive, the
    // restore providers above may already be disposed.
    if (backupType != BackupType.unknown && backupType != BackupType.lnreader) {
      _invalidateCommonState(ref);
    }
    if (backupType != BackupType.unknown) {
      showBotToast(tr("Đã khôi phục bản sao lưu!"));
      AppLogger.log('[Sao lưu] Khôi phục xong: ${p.basename(path)} (${backupType.name}${merge ? ', gộp' : ''})',
          logLevel: LogLevel.info, always: true);
      if (syncAfterRestore == false) {
        // User declined to push this restore to the server — turn sync off
        // rather than leave it running, since the next sync would otherwise
        // pull the server's old data back down and undo the restore.
        final syncNotifier = ref.read(synchingProvider(syncId: 1).notifier);
        syncNotifier.setSyncOn(false);
        syncNotifier.setAutoSyncFrequency(0);
        if (l10n != null) botToast(l10n.sync_disabled_after_restore);
      } else if (syncAfterRestore == true && l10n != null) {
        // Sync may have been disabled by a previous restore — re-enable it
        // before pushing, since startSync below is the connection check
        // (its own error handling reports a bad server/credentials).
        ref.read(synchingProvider(syncId: 1).notifier).setSyncOn(true);
        // Not awaited: this pushes to the sync server over the network, and
        // shouldn't hold up the restore flow (e.g. a caller's busy dialog)
        // waiting on it. It owns clearing the guard once it settles.
        uploadStarted = true;
        unawaited(_uploadToSyncServerIfConnected(ref, l10n));
      }
    } else {
      showBotToast(tr("Định dạng bản sao lưu không được hỗ trợ!"));
      AppLogger.log('[Sao lưu] Không nhận ra định dạng bản sao lưu: ${p.basename(path)}',
          logLevel: LogLevel.warning);
    }
  } catch (e, s) {
    // 0.5.2: restore failures reach the app log too (Feature Check 34).
    final msg = '$e';
    AppLogger.log('[Sao lưu] Khôi phục thất bại (${p.basename(path)}): '
        '${msg.length > 600 ? '${msg.substring(0, 600)}…' : msg}\n$s',
        logLevel: LogLevel.error);
    toastError(e, stack: s, source: 'restore');
  } finally {
    if (!uploadStarted) {
      ref.read(restoreSyncGuardProvider.notifier).finish();
    }
  }
}

/// Pushes the just-restored data to the sync server (if connected) so it
/// isn't left holding the pre-restore state, which the next sync would
/// otherwise pull back down and undo the restore. Silently skipped when no
/// server is configured. Always clears the restore guard on the way out,
/// since doRestore hands off ownership of it to this function once called.
Future<void> _uploadToSyncServerIfConnected(
  Ref ref,
  AppLocalizations l10n,
) async {
  try {
    final syncPreference = ref.read(synchingProvider(syncId: 1));
    final connected =
        (syncPreference.authToken?.isNotEmpty ?? false) &&
        (syncPreference.server?.isNotEmpty ?? false);
    if (!connected) return;
    botToast(l10n.restore_sync_uploading);
    // silent: true suppresses startSync's own generic "Starting/Finished"
    // toasts (this one is restore-specific below) - it still shows its own
    // "Sync failed" toast on failure, so that case doesn't need one here.
    final success = await ref
        .read(syncServerProvider(syncId: 1).notifier)
        .startSync(l10n, true, upload: true, bypassRestoreGuard: true);
    if (success) {
      botToast(l10n.restore_sync_upload_success);
    }
  } catch (e) {
    botToast(
      "Backup restored, but couldn't push it to your sync server: $e. "
      "The server still has the old data until the next successful sync.",
    );
  } finally {
    ref.read(restoreSyncGuardProvider.notifier).finish();
  }
}

void showBotToast(String text) {
  BotToast.showNotification(
    animationDuration: const Duration(milliseconds: 200),
    animationReverseDuration: const Duration(milliseconds: 200),
    duration: const Duration(seconds: 5),
    backButtonBehavior: BackButtonBehavior.none,
    leading: (_) => Image.asset(appIconAssets[1], height: 40),
    title: (_) => Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
    enableSlideOff: true,
    onlyOne: true,
    crossPage: true,
  );
}

@riverpod
Future<void> restoreBackup(
  Ref ref,
  Map<String, dynamic> backup, {
  bool full = true,
  // When true, adds this backup's library into the existing one instead of
  // wiping it first - only categories/manga/chapters/history/updates
  // participate (mirrors what Mihon-family merge covers; device config like
  // settings/sources/customButtons is a replace-only concept either way).
  bool merge = false,
  Map<String, bool> categoryDecisions = const {},
  Map<String, int> sourceDecisions = const {},
}) async {
  final version = backup['version'];
  final yomiExtras = backup['yomihub'];
  if (yomiExtras is Map) {
    // Extensions saved by YomiHub even when "extensions" wasn't ticked.
    backup['extensions'] ??= yomiExtras['extensions'];
    backup['extensions_preferences'] ??= yomiExtras['extensions_preferences'];
  }
  final browserHistory = backup['yomihub_browser_history'];
  if (browserHistory is List) {
    await BrowserHistory.replaceAll(
      browserHistory
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      merge: merge,
    );
  }
  if (["1", "2"].any((e) => e == version)) {
    try {
      final manga = (backup["manga"] as List?)
          ?.map((e) => Manga.fromJson(e)..itemType = convertToItemType(e))
          .toList();
      final chapters = (backup["chapters"] as List?)
          ?.map((e) => Chapter.fromJson(e))
          .toList();
      final categories = (backup["categories"] as List?)
          ?.map(
            (e) =>
                Category.fromJson(e)
                  ..forItemType = convertToItemTypeCategory(e),
          )
          .toList();
      final track = (backup["tracks"] as List?)
          ?.map((e) => Track.fromJson(e)..itemType = convertToItemType(e))
          .toList();
      final trackPreferences = (backup["trackPreferences"] as List?)
          ?.map((e) => TrackPreference.fromJson(e))
          .toList();
      final history = (backup["history"] as List?)
          ?.map((e) => History.fromJson(e)..itemType = convertToItemType(e))
          .toList();
      final downloads = (backup["downloads"] as List?)
          ?.map((e) => Download.fromJson(e))
          .toList();
      final settings = (backup["settings"] as List?)
          ?.map((e) => Settings.fromJson(e))
          .toList();
      final extensions = (backup["extensions"] as List?)
          ?.map((e) => Source.fromJson(e)..itemType = convertToItemType(e))
          .toList();
      final sourcesPrefs = (backup["extensions_preferences"] as List?)
          ?.map((e) => SourcePreference.fromJson(e))
          .toList();
      final updates = (backup["updates"] as List?)
          ?.map((e) => Update.fromJson(e))
          .toList();
      final customButtons = (backup["customButtons"] as List?)
          ?.map((e) => CustomButton.fromJson(e))
          .toList();

      final currentSettings = settingsRepository.currentOrNull;
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
          );
          return;
        }
        mangaRepository.clearSync();
        if (manga != null) {
          mangaRepository.putAllSync(manga);
          if (chapters != null) {
            chapterRepository.clearSync();
            final mangaMap = {for (var m in mangaRepository.getAll()) m.id!: m};
            final chaptersToPut = <Chapter>[];
            for (var chapter in chapters) {
              final manga = mangaMap[chapter.mangaId];
              if (manga != null) {
                chapter.manga.value = manga;
                chaptersToPut.add(chapter);
              }
            }
            chapterRepository.putAllSync(chaptersToPut);
            for (var chapter in chaptersToPut) {
              chapter.manga.saveSync();
            }

            final chapterMap = {
              for (var c in chapterRepository.getAll()) c.id!: c,
            };

            if (full) {
              downloadRepository.clearSync();
              if (downloads != null) {
                final downloadsToPut = <Download>[];
                for (var download in downloads) {
                  final chapter = chapterMap[download.id];
                  if (chapter != null) {
                    download.chapter.value = chapter;
                    downloadsToPut.add(download);
                  }
                }
                downloadRepository.putAllSync(downloadsToPut);
                for (var download in downloadsToPut) {
                  download.chapter.saveSync();
                }
              }
            }

            historyRepository.clearSync();
            if (history != null) {
              final historyToPut = <History>[];
              for (var element in history) {
                final chapter = chapterMap[element.chapterId];
                if (chapter != null) {
                  element.chapter.value = chapter;
                  historyToPut.add(element);
                }
              }
              historyRepository.putAllSync(historyToPut);
              for (var element in historyToPut) {
                element.chapter.saveSync();
              }
            }

            updateRepository.clearSync();
            if (updates != null) {
              final chapterMapByKey = {
                for (var c in chapterMap.values) "${c.mangaId}_${c.name}": c,
              };
              final updatesToPut = <Update>[];
              for (var update in updates) {
                final matchingChapter =
                    chapterMapByKey["${update.mangaId}_${update.chapterName}"];
                if (matchingChapter != null) {
                  update.chapter.value = matchingChapter;
                  updatesToPut.add(update);
                }
              }
              updateRepository.putAllSync(updatesToPut);
              for (var update in updatesToPut) {
                update.chapter.saveSync();
              }
            }
          }

          categoryRepository.clearSync();
          if (categories != null) {
            categoryRepository.putAllSync(categories);
          }
        }

        trackRepository.clearSync();
        if (track != null) {
          trackRepository.putAllSync(track);
        }

        if (full) {
          if (trackPreferences != null) {
            trackRepository.clearPreferencesSync();
            trackRepository.putAllPreferencesSync(trackPreferences);
          }
          sourceRepository.clearSync();
          if (extensions != null) {
            sourceRepository.putAllSync(extensions);
          }
          sourcePreferenceRepository.clearSync();
          if (sourcesPrefs != null) {
            sourcePreferenceRepository.putAllSync(sourcesPrefs);
          }
          settingsRepository.clearSync();
          if (settings != null) {
            settingsRepository.putAllSync(
              settings
                  .map(
                    (settings) => currentSettings == null
                        ? settings
                        : _preserveDeviceLocalSettings(
                            settings,
                            currentSettings,
                          ),
                  )
                  .toList(),
            );
          }
          customButtonRepository.clearSync();
          if (customButtons != null) {
            customButtonRepository.putAllSync(customButtons);
          }
        }
      });
      if (chapters != null) {
        final boxes = yomiExtras is Map ? yomiExtras['boxes'] : null;
        final prefs = boxes is Map ? boxes['yomihub_prefs'] : null;
        final originData = prefs is Map ? prefs['mergedChapterOrigins'] : null;
        await ChapterOrigins.restore(originData, idMap: restoredChapterIds);
      }
      if (full) {
        if (yomiExtras is Map) {
          await YomiBackupExtras.restore(Map<String, dynamic>.from(yomiExtras));
        }
      }
      // 0.5.2: no `ref` after an await here. This autoDispose provider can be
      // disposed while a long restore runs ("Cannot use the Ref of
      // restoreBackupProvider(...) after it has been disposed", Note 9
      // 06/11 00:22:39 - the restore was reported as failed at its very end).
      // doRestore, whose ref is kept alive, refreshes the screens instead.
      AppLogger.log(
        '[Sao lưu] Đã khôi phục bản sao lưu YomiHub/Mangayomi (${merge ? 'gộp' : 'thay thế'}): '
        '${manga?.length ?? 0} bộ, ${chapters?.length ?? 0} chương'
        '${installedFromBackup > 0 ? ', cài $installedFromBackup tiện ích có trong bản sao lưu' : ''}',
        logLevel: LogLevel.info, always: true,
      );
    } catch (e) {
      rethrow;
    }
  } else {
    throw "Failed to restore the backup";
  }
}

/// 0.5.2: a merge ("Gộp") restore skipped the backup's extensions entirely
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

/// Adds a mangayomi-format backup's library into the existing one instead of
/// wiping it first. Mirrors what restoreTachiBkBackup already does for
/// Mihon-family merges: match manga by link, keep the existing entry's
/// state on conflict, only carry over chapters/history/updates that don't
/// already exist. Everything here re-inserts with a fresh id rather than
/// reusing the backup's original one - unlike a full replace (which clears
/// the tables first, so reusing ids is safe), a merge runs against a
/// non-empty library where the backup's ids could belong to something else
/// entirely on this device.
Map<int, int> _mergeMangayomiBackup({
  required List<Manga>? manga,
  required List<Chapter>? chapters,
  required List<Category>? categories,
  required List<History>? history,
  required List<Update>? updates,
  required Map<String, bool> categoryDecisions,
  required Map<String, int> sourceDecisions,
  Map<int, Set<String>> preChapterUrls = const {},
}) {
  final oldToNewCategoryId = <int, int>{};
  if (categories != null) {
    final existingCategories = categoryRepository.getAll();
    for (final category in categories) {
      final oldId = category.id;
      final existing = existingCategories.firstWhereOrNull(
        (c) => c.name == category.name && c.forItemType == category.forItemType,
      );
      if (existing != null) {
        if (oldId != null) oldToNewCategoryId[oldId] = existing.id!;
        continue;
      }
      if (categoryDecisions[category.name] == false) continue;
      category.id = null;
      categoryRepository.putSync(category);
      if (oldId != null) oldToNewCategoryId[oldId] = category.id!;
    }
  }

  final oldToNewMangaId = <int, int>{};
  final newMangaIds = <int>{};
  // 0.5.2: installed sources read once (installedSourcesFor() loads every
  // source with its code - it was called for each of 4 494 entries).
  final installedByType = {
    for (final t in ItemType.values) t: installedSourcesFor(t),
  };
  Source? installedNamed(ItemType t, String name, String? lang) {
    final n = name.toLowerCase();
    final all = installedByType[t] ?? const <Source>[];
    return all.firstWhereOrNull((s) => s.name?.toLowerCase() == n && (lang == null || s.lang == lang)) ??
        all.firstWhereOrNull((s) => s.name?.toLowerCase() == n);
  }
  if (manga != null) {
    final existingMangaByKey = {
      for (final m in mangaRepository.getAll())
        if (m.link != null) '${m.itemType.index}|${m.link}': m,
    };
    for (final tempManga in manga) {
      final oldId = tempManga.id;
      final key = '${tempManga.itemType.index}|${tempManga.link}';
      final existing = tempManga.link != null ? existingMangaByKey[key] : null;
      final remappedCategories = (tempManga.categories ?? [])
          .map((id) => oldToNewCategoryId[id])
          .whereType<int>()
          .toList();
      if (existing != null) {
        existing.favorite = true;
        existing.categories = {
          ...?existing.categories,
          ...remappedCategories,
        }.toList();
        // 0.5.2: an entry that was imported earlier without a working
        // source (sourceId null - e.g. from a Mihon/Nekoyomi backup whose
        // extension was missing) is bound to the source this backup names
        // when that source is installed now (Note 9: 780 CBHentai entries
        // stayed "missing" after the Mangayomi merge installed CBHentai).
        if (existing.sourceId == null) {
          final bound = installedNamed(tempManga.itemType, tempManga.source ?? '', tempManga.lang);
          if (bound != null) {
            existing.sourceId = bound.id;
            existing.source = bound.name;
            existing.lang = bound.lang;
          }
        }
        mangaRepository.putSync(existing);
        if (oldId != null) oldToNewMangaId[oldId] = existing.id!;
        continue;
      }
      final originalSourceName = tempManga.source ?? "Unknown";
      final decidedSourceId = sourceDecisions[originalSourceName];
      final boundSource = decidedSourceId != null
          ? sourceRepository.getById(decidedSourceId)
          : installedNamed(tempManga.itemType, originalSourceName, tempManga.lang);
      tempManga.id = null;
      tempManga.categories = remappedCategories;
      tempManga.favorite = true;
      if (boundSource != null) {
        tempManga.sourceId = boundSource.id;
        tempManga.source = boundSource.name;
      } else {
        tempManga.sourceId = null;
      }
      mangaRepository.putSync(tempManga);
      if (oldId != null) oldToNewMangaId[oldId] = tempManga.id!;
      newMangaIds.add(tempManga.id!);
    }
  }

  final oldToNewChapterId = <int, int>{};
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
      if (mangaRef == null) continue;
      final oldId = tempChapter.id;
      tempChapter.id = null;
      tempChapter.mangaId = newMangaId;
      chapterRepository.putSync(tempChapter..manga.value = mangaRef);
      tempChapter.manga.saveSync();
      if (tempChapter.url != null) existingUrls.add(tempChapter.url!);
      if (oldId != null) oldToNewChapterId[oldId] = tempChapter.id!;
    }
  }

  if (history != null) {
    for (final tempHistory in history) {
      final newChapterId = tempHistory.chapterId != null
          ? oldToNewChapterId[tempHistory.chapterId]
          : null;
      final newMangaId = tempHistory.mangaId != null
          ? oldToNewMangaId[tempHistory.mangaId]
          : null;
      // Only for chapters we just inserted above - an existing chapter's
      // history already reflects this device's own progress.
      if (newChapterId == null || newMangaId == null) continue;
      final chapterRef = chapterRepository.findByIdSync(newChapterId);
      if (chapterRef == null) continue;
      tempHistory.id = null;
      tempHistory.mangaId = newMangaId;
      tempHistory.chapterId = newChapterId;
      historyRepository.putSync(tempHistory..chapter.value = chapterRef);
      tempHistory.chapter.saveSync();
    }
  }

  if (updates != null) {
    for (final tempUpdate in updates) {
      final newMangaId = tempUpdate.mangaId != null
          ? oldToNewMangaId[tempUpdate.mangaId]
          : null;
      if (newMangaId == null || !newMangaIds.contains(newMangaId)) continue;
      final chapter = chapterRepository.findByMangaIdAndName(
        newMangaId,
        tempUpdate.chapterName,
      );
      if (chapter == null) continue;
      tempUpdate.id = null;
      tempUpdate.mangaId = newMangaId;
      updateRepository.putSync(tempUpdate..chapter.value = chapter);
      tempUpdate.chapter.saveSync();
    }
  }
  return oldToNewChapterId;
}

@riverpod
Future<void> restoreKotatsuBackup(Ref ref, Archive archive) async {
  try {
    final backup = parseKotatsuBackup(archive);
    await restoreRepository.run(() {
      categoryRepository.clearSync();
      mangaRepository.clearSync();

      final categoryIdMap = <int, int>{};
      for (final category in backup.categories) {
        final restoredId = categoryRepository.putSync(
          Category(
            name: category.name,
            forItemType: ItemType.manga,
            pos: category.position,
            hide: category.hidden,
          ),
        );
        final sourceId = category.sourceId;
        if (sourceId != null) categoryIdMap[sourceId] = restoredId;
      }

      for (final favourite in backup.mangas) {
        final tempManga = favourite.manga;
        final manga = Manga(
          source: tempManga["source"],
          author: tempManga["author"],
          artist: null,
          genre:
              (tempManga["tags"] as List?)
                  ?.map((t) => t["title"] as String)
                  .toList() ??
              [],
          imageUrl: tempManga["large_cover_url"],
          lang: 'en',
          link: tempManga["url"],
          name: tempManga["title"],
          status: Status.values.firstWhere(
            (s) =>
                s.name.toLowerCase() ==
                (tempManga["state"] as String?)?.toLowerCase(),
            orElse: () => Status.unknown,
          ),
          description: null,
          categories: remapKotatsuCategoryIds(favourite, categoryIdMap),
          itemType: ItemType.manga,
          favorite: true,
          sourceId: null,
        );
        mangaRepository.putSync(manga);
      }
    });
    await restoreRepository.run(() {
      chapterRepository.clearSync();
      downloadRepository.clearSync();
      historyRepository.clearSync();
      updateRepository.clearSync();
      trackRepository.clearSync();
      trackRepository.clearPreferencesSync();
    });
    // 0.5.2: refreshed by doRestore (see restoreBackup).
  } catch (e) {
    rethrow;
  }
}

@riverpod
Future<void> restoreTachiBkBackup(
  Ref ref,
  String path,
  BackupType bkType, {
  bool merge = false,
  Map<String, bool> categoryDecisions = const {},
  Map<String, int> sourceDecisions = const {},
}) async {
  // 0.5.2: kept alive for the repository import below (it awaits the
  // network and then uses ref); the screens are refreshed by doRestore.
  final keepAlive = ref.keepAlive();
  // 0.5.2: inflated once (platform zlib, background isolate) by the restore
  // screen and reused here instead of a 4th pure-Dart GZipDecoder pass.
  final content = tachiBkBytes(path);
  // YomiHub: bring the other app's extension repositories along.
  // 0.5.2: in the background - addAll() fetches every repository index, and
  // one unreachable repo (kohiden.xyz, TLS error) kept the restore dialog
  // open ~40 s on the Note 9 before the library was even written.
  var repoImport = Future<void>.value();
  try {
    final repos = YomiRepoImporter.fromTachiBk(Uint8List.fromList(content));
    if (repos.isNotEmpty) {
      repoImport = () async {
        try {
          await YomiRepoImporter.addAll(ref, repos);
        } catch (_) {}
      }();
    }
  } catch (_) {}
  // 0.5.2: decoded once in a background isolate by the restore screen.
  final decoded = tachiBkDecoded(path, bkType);
  final backup = decoded.mihon;
  // sourceCode is never null for a browsed-but-not-installed source (every
  // repo listing path defaults it to '' rather than leaving it null) - isAdded
  // is the only field that actually means "installed".
  final installedSources = sourceRepository
      .getAll()
      .where((s) => s.isAdded ?? false)
      .toList();
  Source? resolveSource(String originalName, ItemType itemType) {
    final decision = sourceDecisions[originalName];
    if (decision != null) return sourceRepository.getById(decision);
    return installedSources.firstWhereOrNull(
      (s) =>
          s.itemType == itemType &&
          s.name?.toLowerCase() == originalName.toLowerCase(),
    );
  }

  // 0.5.2 (Note 9: merging a 12 MB TachiyomiMi backup into a 4 400-series
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
    }
    final existingCategories = merge
        ? categoryRepository.getByItemType(ItemType.manga)
        : <Category>[];
    for (var category in backup.backupCategories) {
      final order = protoInt(category.order);
      final existing = existingCategories.firstWhereOrNull(
        (c) => c.name == category.name,
      );
      if (existing != null) {
        if (categoryDecisions[category.name] == false) continue;
        categoryByOrder[order] = existing;
        continue;
      }
      final cat = Category(
        name: category.name,
        forItemType: ItemType.manga,
        pos: order,
      );
      categoryRepository.putSync(cat);
      categoryByOrder[order] = cat;
    }
    final existingMangaByLink = merge
        ? {
            for (var m in mangaRepository.getByItemType(ItemType.manga))
              if (m.link != null) m.link!: m,
          }
        : <String, Manga>{};
    for (var tempManga in backup.backupManga) {
      final sourceId = protoInt(tempManga.source);
      final categoryOrders = tempManga.categories.map(protoInt).toSet();
      final newCategoryIds = categoryOrders
          .map((o) => categoryByOrder[o]?.id)
          .whereType<int>()
          .toList();
      final existingManga = existingMangaByLink[tempManga.url];
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
      } else {
        final originalSourceName =
            backup.backupSources
                .firstWhereOrNull((src) => protoInt(src.sourceId) == sourceId)
                ?.name ??
            "Unknown";
        final boundSource = resolveSource(originalSourceName, ItemType.manga);
        manga = Manga(
          source: boundSource?.name ?? originalSourceName,
          author: tempManga.author,
          artist: tempManga.artist,
          genre: tempManga.genre,
          imageUrl: tempManga.thumbnailUrl,
          lang: boundSource?.lang ?? 'en',
          link: tempManga.url,
          name: tempManga.title,
          status: convertStatusFromTachiBk(tempManga.status),
          description: tempManga.description,
          categories: newCategoryIds,
          itemType: ItemType.manga,
          favorite: true,
          dateAdded: protoInt(tempManga.dateAdded),
          lastUpdate: protoInt(tempManga.lastModifiedAt),
          sourceId: boundSource?.id,
        );
        if (bkType == BackupType.neko && boundSource == null) {
          manga.source = "MangaDex";
        }
      }
      final existingChapterUrls = merge && !isNewManga
          ? (preChapterUrls[manga.id] ?? const <String>{})
          : const <String>{};
      final freshChapters = tempManga.chapters
          .where((c) => !existingChapterUrls.contains(c.url))
          .toList();
      if (!changed && freshChapters.isEmpty) continue;
      mangaRepository.putSync(manga);
      History? history;
      for (var tempChapter in freshChapters) {
        final chapter = Chapter(
          mangaId: manga.id!,
          name: tempChapter.name,
          dateUpload: bkType != BackupType.neko
              ? "${protoInt(tempChapter.dateUpload)}"
              : "${DateTime.now().millisecondsSinceEpoch - protoInt(tempChapter.dateUpload).abs()}",
          isBookmarked: tempChapter.bookmark,
          isRead: tempChapter.read,
          lastPageRead: protoInt(tempChapter.lastPageRead) != 0
              ? "${protoInt(tempChapter.lastPageRead)}"
              : "1",
          scanlator: tempChapter.scanlator,
          url: tempChapter.url,
        );
        chapterRepository.putSync(chapter..manga.value = manga);
        chapter.manga.saveSync();
        if ((history == null ||
            int.parse(history.date ?? "0") <
                protoInt(tempChapter.lastModifiedAt))) {
          history = History(
            mangaId: manga.id,
            date: bkType != BackupType.neko
                ? "${protoInt(tempChapter.lastModifiedAt)}"
                : "${DateTime.now().millisecondsSinceEpoch - protoInt(tempChapter.dateUpload).abs()}",
            itemType: ItemType.manga,
            chapterId: chapter.id,
          )..chapter.value = chapter;
        }
      }
      if (history != null &&
          (!merge || historyRepository.findFirstByMangaId(manga.id) == null)) {
        historyRepository.putSync(history);
        history.chapter.saveSync();
      }
    }
  });
  if (bkType == BackupType.aniyomi) {
    final backupAnime = decoded.aniyomi ?? BackupAniyomi.fromBuffer(content);
    final animeCategories = backupAnime.backupAnimeCategories.isNotEmpty
        ? backupAnime.backupAnimeCategories
        : backupAnime.legacyBackupAnimeCategories;
    final animeEntries = backupAnime.backupAnime.isNotEmpty
        ? backupAnime.backupAnime
        : backupAnime.legacyBackupAnime;
    final animeSources = backupAnime.backupAnimeSources.isNotEmpty
        ? backupAnime.backupAnimeSources
        : backupAnime.legacyBackupAnimeSources;
    final categoryByOrder = <int, Category>{};
    await restoreRepository.run(() {
      final existingAnimeCategories = merge
          ? categoryRepository.getByItemType(ItemType.anime)
          : <Category>[];
      for (var category in animeCategories) {
        final order = protoInt(category.order);
        final existing = existingAnimeCategories.firstWhereOrNull(
          (c) => c.name == category.name,
        );
        if (existing != null) {
          if (categoryDecisions[category.name] == false) continue;
          categoryByOrder[order] = existing;
          continue;
        }
        final cat = Category(
          name: category.name,
          forItemType: ItemType.anime,
          pos: order,
        );
        categoryRepository.putSync(cat);
        categoryByOrder[order] = cat;
      }
      final existingAnimeByLink = merge
          ? {
              for (var m in mangaRepository.getByItemType(ItemType.anime))
                if (m.link != null) m.link!: m,
            }
          : <String, Manga>{};
      for (var tempAnime in animeEntries) {
        final sourceId = protoInt(tempAnime.source);
        final categoryOrders = tempAnime.categories.map(protoInt).toSet();
        final newCategoryIds = categoryOrders
            .map((o) => categoryByOrder[o]?.id)
            .whereType<int>()
            .toList();
        final existingAnime = existingAnimeByLink[tempAnime.url];
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
        } else {
          final originalSourceName =
              animeSources
                  .firstWhereOrNull((src) => protoInt(src.sourceId) == sourceId)
                  ?.name ??
              "Unknown";
          final boundSource = resolveSource(originalSourceName, ItemType.anime);
          anime = Manga(
            source: boundSource?.name ?? originalSourceName,
            author: tempAnime.author,
            artist: tempAnime.artist,
            genre: tempAnime.genre,
            imageUrl: tempAnime.thumbnailUrl,
            lang: boundSource?.lang ?? 'en',
            link: tempAnime.url,
            name: tempAnime.title,
            status: convertStatusFromTachiBk(tempAnime.status),
            description: tempAnime.description,
            categories: newCategoryIds,
            itemType: ItemType.anime,
            favorite: true,
            dateAdded: protoInt(tempAnime.dateAdded),
            lastUpdate: protoInt(tempAnime.lastModifiedAt),
            sourceId: boundSource?.id,
          );
        }
        final existingEpisodeUrls = merge && !isNewAnime
            ? (preChapterUrls[anime.id] ?? const <String>{})
            : const <String>{};
        final freshEpisodes = tempAnime.episodes
            .where((e) => !existingEpisodeUrls.contains(e.url))
            .toList();
        if (!changed && freshEpisodes.isEmpty) continue;
        mangaRepository.putSync(anime);
        History? history;
        for (var tempEpisode in freshEpisodes) {
          final episode = Chapter(
            mangaId: anime.id!,
            name: tempEpisode.name,
            dateUpload: "${protoInt(tempEpisode.dateUpload)}",
            isBookmarked: tempEpisode.bookmark,
            isRead: tempEpisode.seen,
            lastPageRead: protoInt(tempEpisode.lastSecondSeen) != 0
                ? "${secondsToMillis(tempEpisode.lastSecondSeen)}"
                : "1",
            scanlator: tempEpisode.scanlator,
            url: tempEpisode.url,
          );
          chapterRepository.putSync(episode..manga.value = anime);
          episode.manga.saveSync();
          if ((history == null ||
              int.parse(history.date ?? "0") <
                  protoInt(tempEpisode.lastModifiedAt))) {
            history = History(
              mangaId: anime.id,
              date: "${protoInt(tempEpisode.lastModifiedAt)}",
              itemType: ItemType.anime,
              chapterId: episode.id,
            )..chapter.value = episode;
          }
        }
        if (history != null &&
            (!merge ||
                historyRepository.findFirstByMangaId(anime.id) == null)) {
          historyRepository.putSync(history);
          history.chapter.saveSync();
        }
      }
    });
  }
  await restoreRepository.run(() {
    if (!merge) {
      downloadRepository.clearSync();
      updateRepository.clearSync();
      trackRepository.clearSync();
      trackRepository.clearPreferencesSync();
    }
  });
  // 0.5.2: screens refreshed by doRestore; kept alive until the repository
  // import started above has finished.
  unawaited(repoImport.whenComplete(keepAlive.close));
}

Settings _preserveDeviceLocalSettings(Settings incoming, Settings current) {
  return incoming
    ..id = current.id
    ..localFolders = current.localFolders
    ..namedLocalFolders = current.namedLocalFolders
    ..downloadLocalFolderName = current.downloadLocalFolderName
    ..askDownloadDestination = current.askDownloadDestination
    ..androidProxyServer = current.androidProxyServer
    ..jrePath = current.jrePath
    ..extensionServerPath = current.extensionServerPath;
}

void _invalidateCommonState(Ref ref) {
  // Now called after the restore's own transaction has already closed (see
  // the three call sites above), so this needs its own transaction too.
  ref.read(synchingProvider(syncId: 1).notifier).clearAllChangedParts(true);
  ref.invalidate(followSystemThemeStateProvider);
  ref.invalidate(themeModeStateProvider);
  ref.invalidate(blendLevelStateProvider);
  ref.invalidate(flexSchemeColorStateProvider);
  ref.invalidate(pureBlackDarkModeStateProvider);
  ref.invalidate(l10nLocaleStateProvider);
  ref.invalidate(navigationOrderStateProvider);
  ref.invalidate(hideItemsStateProvider);
  ref.invalidate(extensionsRepoStateProvider(ItemType.manga));
  ref.invalidate(extensionsRepoStateProvider(ItemType.anime));
  ref.invalidate(extensionsRepoStateProvider(ItemType.novel));
  ref.read(routerCurrentLocationStateProvider.notifier).refresh();
}
