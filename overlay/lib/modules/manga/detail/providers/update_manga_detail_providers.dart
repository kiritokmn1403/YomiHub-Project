import 'dart:isolate';
import 'package:mangayomi/utils/chapter_recognition.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/update_repository.dart';
import 'package:mangayomi/services/chapter_cache.dart';
import 'package:mangayomi/services/get_detail.dart';
import 'package:mangayomi/utils/extensions/string_extensions.dart';
import 'package:mangayomi/utils/fetch_interval.dart';
import 'package:mangayomi/utils/utils.dart';
import 'package:mangayomi/utils/error_toast.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'update_manga_detail_providers.g.dart';

@riverpod
Future<dynamic> updateMangaDetail(
  Ref ref, {
  required int? mangaId,
  required bool isInit,
  bool showToast = true,
}) async {
  // 0.5.2: this autoDispose provider is read without a listener; with the
  // async reads below its first await came before `ref` was used and it was
  // disposed mid-flight ("Cannot use the Ref of updateMangaDetailProvider(…)
  // after it has been disposed" - detail page and library update, Note 9
  // 06/11 00:27-00:34). Kept alive until it has finished.
  final keepAlive = ref.keepAlive();
  try {
    // 0.5.2: async reads. The library update calls this for every entry;
    // getSync + chapters.loadSync of a long series ran on the UI isolate and
    // froze the app ("Giao diện bị treo 2.6 giây • đang chạy: cập nhật thư
    // viện", logs 2 04/11 09:52:16).
    final manga = await mangaRepository.findByIdAsync(mangaId!);
    if (manga == null) return;

    await manga.chapters.load();

    if ((manga.isLocalArchive ?? false) ||
        (manga.chapters.isNotEmpty && isInit)) {
      return;
    }
    final source = getSource(
      manga.lang!,
      manga.source!,
      manga.sourceId,
      installedOnly: true,
    );
    if (source == null) return;

    final getManga = await ref.read(
      getDetailProvider(url: manga.link!, source: source).future,
    );

    final genre =
        getManga.genre
            ?.map((e) => e.toString().trim())
            .toList()
            .toSet()
            .toList() ??
        [];

    final imgUrl = getManga.imageUrl.trimmedOrDefault(manga.imageUrl);
    final now = DateTime.now().millisecondsSinceEpoch;

    manga
      ..imageUrl = imgUrl == null
          ? null
          : imgUrl.startsWith('http')
          ? imgUrl
          : '${source.baseUrl ?? ''}/${imgUrl.getUrlWithoutDomain}'
      ..name = getManga.name.trimmedOrDefault(manga.name)
      ..genre = (genre.isEmpty ? null : genre) ?? manga.genre ?? []
      ..author = getManga.author.trimmedOrDefault(manga.author) ?? ""
      ..artist = getManga.artist.trimmedOrDefault(manga.artist) ?? ""
      ..status = getManga.status == Status.unknown
          ? manga.status
          : getManga.status ?? Status.unknown
      ..description =
          getManga.description.trimmedOrDefault(manga.description) ?? ""
      ..link = getManga.link.trimmedOrDefault(manga.link)
      ..source = manga.source
      ..lang = manga.lang
      ..itemType = source.itemType
      ..lastUpdate = now
      ..updatedAt = now;

    final chaps = getManga.chapters;

    // A refresh from the primary extension must not deduplicate or rewrite
    // chapters that belong to a different member of a merged title.
    final existingChapters = manga.chapters.where((c) {
      final origin = ChapterOrigins.of(c);
      return origin == null ||
          (origin['sourceId'] == manga.sourceId &&
              origin['source'] == manga.source &&
              origin['lang'] == manga.lang);
    }).toList();

    // 0.5.8: Offload heavy chapter recognition and regex matching to a background
    // Isolate to prevent UI thread freezes (2.6s - 2.9s UI freezes on long series).
    ChapterDiffResult? diff;
    if (chaps != null && chaps.isNotEmpty) {
      final existingData = [
        for (final c in existingChapters)
          ExistingChapterData(
            id: c.id ?? 0,
            url: c.url,
            name: c.name,
            scanlator: c.scanlator,
            isRead: c.isRead ?? false,
            lastPageRead: c.lastPageRead,
            duration: c.duration,
          )
      ];

      final incomingData = [
        for (final chap in chaps)
          IncomingChapterData(
            name: chap.name ?? '',
            url: chap.url ?? '',
            dateUpload: chap.dateUpload?.toString(),
            scanlator: chap.scanlator,
            isFiller: chap.isFiller,
            thumbnailUrl: chap.thumbnailUrl,
            description: chap.description,
            downloadSize: chap.downloadSize,
            duration: chap.duration,
          )
      ];

      diff = await Isolate.run(() => computeChapterDiffInIsolate(
        ChapterDiffInput(
          mangaTitle: manga.name ?? '',
          existing: existingData,
          incoming: incomingData,
        ),
      ));
    }

    await mangaRepository.writeTransactionAsync(() async {
      final savedMangaId = await mangaRepository.putAsync(manga);
      final d = diff;

      if (d == null || chaps == null || chaps.isEmpty) return;

      final existingById = {
        for (final c in existingChapters)
          if (c.id != null) c.id!: c,
      };

      final chaptersToUpdate = <Chapter>[];
      for (final u in d.toUpdate) {
        final existing = existingById[u.id];
        if (existing != null) {
          if (u.urlChanged) {
            ChapterCache().remove(existing);
          }
          existing
            ..name = u.name
            ..url = u.url
            ..scanlator = u.scanlator
            ..updatedAt = now
            ..isFiller = u.isFiller
            ..thumbnailUrl = u.thumbnailUrl
            ..description = u.description
            ..downloadSize = u.downloadSize
            ..duration = u.duration ?? existing.duration;
          chaptersToUpdate.add(existing);
        }
      }

      if (chaptersToUpdate.isNotEmpty) {
        await chapterRepository.putAllAsync(chaptersToUpdate);
      }

      final newChapters = <Chapter>[];
      for (final ins in d.toInsert) {
        final alreadyRead = d.readStates[ins.url] ?? false;

        final newChapter = Chapter(
          name: ins.name,
          url: ins.url,
          dateUpload: ins.dateUpload ?? now.toString(),
          scanlator: ins.scanlator ?? '',
          mangaId: savedMangaId,
          updatedAt: now,
          isFiller: ins.isFiller,
          thumbnailUrl: ins.thumbnailUrl,
          description: ins.description,
          downloadSize: ins.downloadSize,
          duration: ins.duration,
        )..manga.value = manga;

        if (alreadyRead) {
          newChapter.isRead = alreadyRead;
          newChapter.lastPageRead = "1";
        }

        newChapters.add(newChapter);
      }

      if (newChapters.isNotEmpty) {
        final hasExisting = existingChapters.isNotEmpty;

        final orderedNew = newChapters.reversed.toList();

        for (final chap in orderedNew) {
          chap.manga.value = manga;
        }

        await chapterRepository.putAllAsync(orderedNew);
        for (final chap in orderedNew) {
          await chap.manga.save();
        }

        final updatesToInsert = <Update>[];
        for (final chap in orderedNew) {
          if (hasExisting && !(chap.isRead ?? false)) {
            updatesToInsert.add(
              Update(
                mangaId: savedMangaId,
                chapterName: chap.name,
                date: now.toString(),
                updatedAt: now,
              )..chapter.value = chap,
            );
          }
        }

        if (updatesToInsert.isNotEmpty) {
          await updateRepository.putAllAsync(updatesToInsert);
          for (final upd in updatesToInsert) {
            await upd.chapter.save();
          }
        }
      }

      if (d.duplicateIds.isNotEmpty) {
        await chapterRepository.deleteAllAsync(d.duplicateIds);
      }

      final duplicateSet = d.duplicateIds.toSet();
      final dedupedExisting = duplicateSet.isEmpty
          ? existingChapters
          : existingChapters
                .where((c) => c.id == null || !duplicateSet.contains(c.id))
                .toList();
      final allChapters = newChapters.isEmpty
          ? dedupedExisting
          : [...dedupedExisting, ...newChapters];
      if (allChapters.isNotEmpty) {
        final interval = FetchInterval.calculateInterval(allChapters);
        manga
          ..id = savedMangaId
          ..smartUpdateDays = interval;
        await mangaRepository.putAsync(manga);
      }
    });
  } catch (e, s) {
    if (showToast) {
      toastError(e, stack: s, source: 'updateMangaDetail');
    } else {
      rethrow;
    }
  } finally {
    keepAlive.close();
  }
}

/// Plain data structure representing an existing chapter for background isolate processing.
class ChapterDiffInput {
  final String mangaTitle;
  final List<ExistingChapterData> existing;
  final List<IncomingChapterData> incoming;

  const ChapterDiffInput({
    required this.mangaTitle,
    required this.existing,
    required this.incoming,
  });
}

class ExistingChapterData {
  final int id;
  final String? url;
  final String? name;
  final String? scanlator;
  final bool isRead;
  final String? lastPageRead;
  final String? duration;

  const ExistingChapterData({
    required this.id,
    this.url,
    this.name,
    this.scanlator,
    this.isRead = false,
    this.lastPageRead,
    this.duration,
  });
}

class IncomingChapterData {
  final String name;
  final String url;
  final String? dateUpload;
  final String? scanlator;
  final bool? isFiller;
  final String? thumbnailUrl;
  final String? description;
  final String? downloadSize;
  final String? duration;

  const IncomingChapterData({
    required this.name,
    required this.url,
    this.dateUpload,
    this.scanlator,
    this.isFiller,
    this.thumbnailUrl,
    this.description,
    this.downloadSize,
    this.duration,
  });
}

class ChapterDiffResult {
  final List<int> duplicateIds;
  final List<ExistingChapterUpdate> toUpdate;
  final List<IncomingChapterData> toInsert;
  final Map<String, bool> readStates;

  const ChapterDiffResult({
    required this.duplicateIds,
    required this.toUpdate,
    required this.toInsert,
    required this.readStates,
  });
}

class ExistingChapterUpdate {
  final int id;
  final String name;
  final String url;
  final String? scanlator;
  final bool? isFiller;
  final String? thumbnailUrl;
  final String? description;
  final String? downloadSize;
  final String? duration;
  final bool urlChanged;

  const ExistingChapterUpdate({
    required this.id,
    required this.name,
    required this.url,
    this.scanlator,
    this.isFiller,
    this.thumbnailUrl,
    this.description,
    this.downloadSize,
    this.duration,
    required this.urlChanged,
  });
}

/// Runs in a background Isolate to compute the chapter diff without stalling the UI thread.
ChapterDiffResult computeChapterDiffInIsolate(ChapterDiffInput input) {
  final recognition = ChapterRecognition();
  final mangaTitle = input.mangaTitle;

  String? identityOf(String? name, String? scanlator, {bool withScanlator = true}) {
    if (name == null || name.isEmpty) return null;
    return recognition.chapterIdentityKey(
      mangaTitle,
      name,
      withScanlator ? (scanlator ?? '') : null,
    );
  }

  final existingByUrl = <String, ExistingChapterData>{};
  final existingByComposite = <String, ExistingChapterData>{};
  final duplicateIds = <int>{};

  for (final c in input.existing) {
    final u = c.url?.trim();
    final urlKey = (u == null || u.isEmpty) ? null : u.getUrlWithoutDomain;
    final compositeKey = identityOf(c.name, c.scanlator);

    final prior =
        (urlKey != null ? existingByUrl[urlKey] : null) ??
        (compositeKey != null ? existingByComposite[compositeKey] : null);
    if (prior == null) {
      if (urlKey != null) existingByUrl[urlKey] = c;
      if (compositeKey != null) existingByComposite[compositeKey] = c;
    } else {
      final priorHasState = prior.isRead || (prior.lastPageRead ?? '').isNotEmpty;
      final keep = priorHasState ? prior : c;
      final drop = identical(keep, prior) ? c : prior;
      if (urlKey != null) existingByUrl[urlKey] = keep;
      if (compositeKey != null) existingByComposite[compositeKey] = keep;
      duplicateIds.add(drop.id);
    }
  }

  final readByEpisode = <String, bool>{};
  for (final c in input.existing) {
    final key = identityOf(c.name, null, withScanlator: false);
    if (key != null) {
      readByEpisode[key] = (readByEpisode[key] ?? false) || c.isRead;
    }
  }

  final toInsert = <IncomingChapterData>[];
  final seenKeys = <String>{};
  final toUpdate = <ExistingChapterUpdate>[];
  final readStates = <String, bool>{};

  for (final chap in input.incoming) {
    final url = chap.url.trim();
    if (url.isEmpty) continue;
    final key = url.getUrlWithoutDomain;

    final compositeKey = recognition.chapterIdentityKey(
      mangaTitle,
      chap.name,
      chap.scanlator ?? '',
    );
    final episodeKey = recognition.chapterIdentityKey(mangaTitle, chap.name);

    if (!seenKeys.add(key)) continue;
    if (!seenKeys.add('c:$compositeKey')) {
      continue;
    }

    final existing =
        existingByUrl[key] ??
        (compositeKey != null && compositeKey.isNotEmpty ? existingByComposite[compositeKey] : null);

    if (existing == null) {
      final alreadyRead = readByEpisode[episodeKey] ?? false;
      toInsert.add(chap);
      if (alreadyRead) {
        readStates[url] = true;
      }
    } else {
      toUpdate.add(
        ExistingChapterUpdate(
          id: existing.id,
          name: chap.name,
          url: url,
          scanlator: chap.scanlator,
          isFiller: chap.isFiller,
          thumbnailUrl: chap.thumbnailUrl,
          description: chap.description,
          downloadSize: chap.downloadSize,
          duration: chap.duration ?? existing.duration,
          urlChanged: existing.url != url,
        ),
      );
    }
  }

  return ChapterDiffResult(
    duplicateIds: duplicateIds.toList(),
    toUpdate: toUpdate,
    toInsert: toInsert,
    readStates: readStates,
  );
}
