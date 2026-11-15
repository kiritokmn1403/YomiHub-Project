// YomiHub 0.5.7 – gói P1 "Cài đặt & Hợp nhất":
//   U3  câu chữ vị trí sao lưu Booru, U4 công tắc Play Books / Booru ngay trong
//   "Bật/Tắt tính năng", Feature Check 37 (nguồn để đọc sau khi hợp nhất, được
//   nhớ theo bộ), Feature Check 38 (gom công cụ hợp nhất vào "Hợp Nhất Tiện Ích").
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

String _read(String path) => File(path).readAsStringSync();

Manga _title() => Manga(
      name: 'Same title',
      source: 'Alpha',
      sourceId: 1,
      lang: 'vi',
      author: '',
      artist: '',
      genre: [],
      imageUrl: '',
      link: '/title',
      status: Status.ongoing,
      description: '',
    )..id = 77;

Chapter _ch(int id, String name) =>
    Chapter(id: id, mangaId: 77, name: name, url: 'https://x.example/$id');

void main() {
  late Directory temp;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('yomihub-057-p1-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
    await YomiPrefs.open();
    expect(YomiPrefs.isOpen, isTrue);
  });

  setUp(() async {
    // chapters 1-3 exist in both sources (ids 1-3 Alpha, 11-13 Beta);
    // chapter 4 only in Alpha, chapter 5 only in Beta
    final origins = <String, dynamic>{};
    for (final id in [11, 12, 13, 15]) {
      origins['$id'] = {
        'sourceId': 2,
        'source': 'Beta',
        'lang': 'vi',
        'link': '/b',
        'mangaId': 77,
        'chapterUrl': 'https://x.example/$id',
      };
    }
    await YomiPrefs.set('mergedChapterOrigins', origins);
    await YomiPrefs.set('mergedReadSource', <String, dynamic>{});
  });

  // reading order: by number, Alpha's copy first (as getFilteredChapters gives)
  List<Chapter> reading() => [
        _ch(1, 'Chapter 1'), _ch(11, 'Chapter 1'),
        _ch(2, 'Chapter 2'), _ch(12, 'Chapter 2'),
        _ch(3, 'Chapter 3'), _ch(13, 'Chapter 3'),
        _ch(4, 'Chapter 4'),
        _ch(15, 'Chapter 5'),
        _ch(90, 'Special'), _ch(91, 'Extra'),
      ];
  double? numberOf(Chapter c) {
    final m = RegExp(r'Chapter (\d+)').firstMatch(c.name ?? '');
    return m == null ? null : double.parse(m.group(1)!);
  }

  group('Feature Check 37 – nguồn để đọc sau khi hợp nhất', () {
    test('source keys tell the two merged sources apart', () {
      final m = _title();
      expect(ChapterOrigins.sourceKey(_ch(1, 'Chapter 1'), m), '1|Alpha|vi');
      expect(ChapterOrigins.sourceKey(_ch(11, 'Chapter 1'), m), '2|Beta|vi');
    });

    test('no preference: first copy of each number (old behaviour)', () {
      final out = ChapterOrigins.pickForReading(reading(), numberOf, owner: _title());
      expect(out.map((c) => c.id), [1, 2, 3, 4, 15, 90, 91]);
    });

    test('preferred source wins for shared chapters, the other fills the gaps', () {
      final out = ChapterOrigins.pickForReading(
        reading(),
        numberOf,
        owner: _title(),
        preferred: '2|Beta|vi',
      );
      // 1-3 from Beta, 4 only exists in Alpha, 5 from Beta; unnumbered kept
      expect(out.map((c) => c.id), [11, 12, 13, 4, 15, 90, 91]);
    });

    test('preferring the first source changes nothing; an unknown key is harmless', () {
      final a = ChapterOrigins.pickForReading(reading(), numberOf, owner: _title(), preferred: '1|Alpha|vi');
      expect(a.map((c) => c.id), [1, 2, 3, 4, 15, 90, 91]);
      final b = ChapterOrigins.pickForReading(reading(), numberOf, owner: _title(), preferred: '9|Gone|vi');
      expect(b.map((c) => c.id), [1, 2, 3, 4, 15, 90, 91]);
    });

    test('the choice is remembered per title and can be cleared', () async {
      expect(ChapterOrigins.preferredSource(77), isNull);
      await ChapterOrigins.setPreferredSource(77, '2|Beta|vi');
      await ChapterOrigins.setPreferredSource(78, '1|Alpha|vi');
      expect(ChapterOrigins.preferredSource(77), '2|Beta|vi');
      expect(ChapterOrigins.preferredSource(78), '1|Alpha|vi');
      expect(YomiPrefs.dump()['mergedReadSource'], {'77': '2|Beta|vi', '78': '1|Alpha|vi'});
      await ChapterOrigins.setPreferredSource(77, null);
      expect(ChapterOrigins.preferredSource(77), isNull);
      expect(ChapterOrigins.preferredSource(78), '1|Alpha|vi');
      expect(ChapterOrigins.preferredSource(null), isNull);
    });

    test('detail screen restores, saves and applies the remembered source', () {
      final v = _read('lib/modules/manga/detail/manga_detail_view.dart');
      expect(v, contains('_selectedMergedSource = ChapterOrigins.preferredSource(widget.manga?.id);'));
      expect(v, contains('ChapterOrigins.setPreferredSource(widget.manga?.id, picked);'));
      expect(_read('lib/utils/extensions/manga_extensions.dart'), contains('ChapterOrigins.pickForReading('));
      expect(_read('lib/modules/manga/detail/manga_details_view.dart'), contains('getChapterListForReading().firstOrNull'));
    });
  });

  group('U4 – công tắc ngay trong "Bật/Tắt tính năng & Nguồn mở rộng"', () {
    test('both tiles carry a real Switch wired to the on/off logic', () {
      final pb = _read('lib/yomihub/playbooks/playbooks_toggle.dart');
      expect(pb, contains("ValueKey('playBooksSwitch')"));
      expect(pb, contains('onChanged: (v) => YomiPlayBooks.setEnabled(ref, v)'));
      expect(pb, contains("YomiPrefs.set('playBooksEnabled', on)"));
      final bo = _read('lib/yomihub/booru/booru_settings_screen.dart');
      expect(bo, contains("ValueKey('booruSwitch')"));
      expect(bo, contains('onChanged: (v) => setBooruEnabled(ref, v)'));
      final ft = _read('lib/yomihub/features/feature_toggle_screen.dart');
      expect(ft, contains('PlayBooksSettingTile()'));
      expect(ft, contains('BooruSettingTile()'));
    });
  });

  group('U3 / Feature Check 38', () {
    test('Booru backup text names "Sao Lưu & Đồng Bộ"', () {
      final bo = _read('lib/yomihub/booru/booru_settings_screen.dart');
      expect(bo, contains('(Cài đặt › Sao Lưu & Đồng Bộ).'));
      expect(bo, isNot(contains('Cài đặt › Dữ liệu và bộ nhớ, đồng bộ đám mây')));
    });

    test('merge tools live on "Hợp Nhất Tiện Ích"; Data & Storage keeps one shortcut', () {
      final m = _read('lib/yomihub/merge/extension_merge_screen.dart');
      for (final w in ['CustomMergeSourcesTile()', 'MergeDuplicateMangaTile()', 'ManualMergeMangaTile()', "context.push('/contentMerge')"]) {
        expect(m, contains(w), reason: w);
      }
      final d = _read('lib/modules/more/data_and_storage/data_and_storage.dart');
      for (final w in ['MergeDuplicateMangaTile', 'ManualMergeMangaTile', 'CustomMergeSourcesTile']) {
        expect(d, isNot(contains(w)), reason: w);
      }
      expect(d, contains("context.push('/mergeExtensions')"));
    });
  });

  group('0.5.7 bổ sung – Hợp nhất nội dung, nhãn "Nguồn đọc", FC41', () {
    test('"Hợp nhất nội dung" is no longer a second entry in Settings', () {
      final st = _read('lib/modules/more/settings/settings_screen.dart');
      expect(st, isNot(contains("context.push('/contentMerge')")));
      expect(st, contains("context.push('/mergeExtensions')"));
      expect(_read('lib/modules/more/more_screen.dart'), contains("context.push('/mergeExtensions')"));
    });

    test('selector is labelled "Nguồn đọc" and sits in the header after the action buttons', () {
      final v = _read('lib/modules/manga/detail/manga_detail_view.dart');
      expect(v, contains("tr('Nguồn đọc')"));
      final h = _read('lib/modules/manga/detail/widgets/manga_info_header.dart');
      expect(h.indexOf('_DetailActions(manga: widget.manga)'),
          lessThan(h.indexOf('widget.sourceSelector!')));
    });

    test('FC41: Comic / Film & Movie / Novel feature and repo switches exist', () {
      final ft = _read('lib/yomihub/features/feature_toggle_screen.dart');
      for (final w in ['/MangaLibrary', '/AnimeLibrary', '/NovelLibrary',
          "tr('Tính năng Comic')", "tr('Nguồn mở rộng Comic')",
          "tr('Tính năng Film & Movie')", "tr('Nguồn mở rộng Film & Movie')",
          "tr('Tính năng Novel')", "tr('Nguồn mở rộng Novel')",
          'toggleFeature(', 'toggleAllRepos(']) {
        expect(ft, contains(w), reason: w);
      }
    });
  });
}
