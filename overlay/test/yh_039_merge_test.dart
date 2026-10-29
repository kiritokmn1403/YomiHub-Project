import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/main.dart' as app;
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/download.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/delete_source.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:mangayomi/yomihub/merge/content_merge_screen.dart';
import 'package:mangayomi/yomihub/merge/extension_merge_screen.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

void main() {
  test('both merge routes can be constructed', () {
    expect(const ContentMergeScreen(), isNotNull);
    expect(const ExtensionMergeScreen(), isNotNull);
  });
  late Directory temp;
  late Isar db;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('yomihub-039-merge-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
    final override = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      await Isar.initializeIsarCore(download: true);
    } finally {
      HttpOverrides.global = override;
    }
    await YomiPrefs.open();
    expect(YomiPrefs.isOpen, isTrue);
  });
  setUp(() async {
    db = await Isar.open(
      [
        MangaSchema,
        ChapterSchema,
        HistorySchema,
        UpdateSchema,
        TrackSchema,
        DownloadSchema,
        SourceSchema,
      ],
      directory: temp.path,
      name: 'merge',
    );
    app.isar = db;
    await YomiPrefs.set('mergedChapterOrigins', <String, dynamic>{});
    await YomiPrefs.set('mergeGroups', <String, dynamic>{});
  });
  tearDown(() async {
    await db.close(deleteFromDisk: true);
  });

  Future<Manga> addTitle(int sourceId, String sourceName) async {
    final source = Source(
      id: sourceId,
      name: sourceName,
      lang: 'vi',
      baseUrl: 'https://$sourceName.example',
      isAdded: true,
      isActive: true,
    );
    final manga = Manga(
      name: 'Same title',
      source: sourceName,
      sourceId: sourceId,
      lang: 'vi',
      author: '',
      artist: '',
      genre: [],
      imageUrl: '',
      link: '/title',
      status: Status.ongoing,
      description: '',
      favorite: true,
    );
    await db.writeTxn(() async {
      await db.sources.put(source);
      await db.mangas.put(manga);
    });
    final chapter = Chapter(
      mangaId: manga.id,
      name: 'Chapter 1',
      url: 'https://$sourceName.example/chapter-1',
      scanlator: 'Translation team',
    )..manga.value = manga;
    await db.writeTxn(() async {
      await db.chapters.put(chapter);
      await chapter.manga.save();
    });
    return manga;
  }

  test(
    'merge keeps identical chapter paths from different sources readable',
    () async {
      final primary = await addTitle(1, 'one');
      final other = await addTitle(2, 'two');
      await mergeMangaGroup(primary, [other]);
      final chapters = chapterRepository.getAllByMangaId(primary.id);
      expect(chapters, hasLength(2));
      expect(chapters.map((c) => ChapterOrigins.sourceFor(c)?.id).toSet(), {
        1,
        2,
      });
      expect(
        chapters.map((c) => c.scanlator),
        everyElement('Translation team'),
      );
      expect(mangaRepository.findById(other.id!), isNull);
    },
  );

  test(
    'backup merge remaps source metadata without overwriting existing IDs',
    () async {
      await YomiPrefs.set('mergedChapterOrigins', {
        '1': {'source': 'existing'},
      });
      await ChapterOrigins.restore(
        {
          '1': {'source': 'imported'},
          '2': {'source': 'skipped'},
        },
        idMap: {1: 8},
      );
      final data = YomiPrefs.get<Map>('mergedChapterOrigins', {});
      expect(data['1']['source'], 'existing');
      expect(data['8']['source'], 'imported');
      expect(data.containsKey('2'), isFalse);
      await ChapterOrigins.restore(null);
      expect(YomiPrefs.get<Map>('mergedChapterOrigins', {}), isEmpty);
    },
  );

  test(
    'moving a chapter restores its parent link and history together',
    () async {
      final primary = await addTitle(1, 'one');
      final other = await addTitle(2, 'two');
      final chapter = chapterRepository.getAllByMangaId(primary.id).single;
      final history = History(
        mangaId: primary.id,
        chapterId: chapter.id,
        itemType: ItemType.manga,
        date: '1',
      )..chapter.value = chapter;
      await db.writeTxn(() async {
        await db.historys.put(history);
        await history.chapter.save();
      });
      chapter.mangaId = other.id;
      chapter.manga.value = other;
      await chapterRepository.saveWithMangaLink(chapter);
      expect(chapterRepository.getById(chapter.id!).manga.value?.id, other.id);
      expect(db.historys.getSync(history.id!)?.mangaId, other.id);
    },
  );

  test(
    'merging extension groups removes overlapping hidden primaries',
    () async {
      await YomiMerge.merge('first', 1, [1, 2]);
      await YomiMerge.merge('second', 2, [2, 3]);
      expect(YomiMerge.groups.keys, ['second']);
      expect(YomiMerge.hiddenSecondaries(), {3});
    },
  );
}
