// YomiHub 0.6.3 – "Tủ Sách Cá Nhân": search, ownership badges, duplicate
// guard, gap detection, shopping list, ISBN, fuzzy series match, CSV.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';

void main() {
  group('logic', () {
    test('normalize strips Vietnamese diacritics and đ', () {
      expect(bsNormalize('Chú Thuật Hồi Chiến!'), 'chu thuat hoi chien');
      expect(bsNormalize('Đô-rê-mon  Tập 5'), 'do re mon tap 5');
    });
    test('query splits trailing volume and drops "tập"', () {
      final q = bsParseQuery('One Piece tập 105');
      expect(q.text, 'one piece');
      expect(q.volume, 105);
      expect(bsParseQuery('86').volume, isNull);
      expect(bsParseQuery('jjk').text, 'jjk');
    });
    test('match score: exact, prefix, initials, alias', () {
      expect(bsMatchScore('one piece', 'One Piece', const []), 100);
      expect(bsMatchScore('one', 'One Piece', const []), 80);
      expect(bsMatchScore('jk', 'Jujutsu Kaisen', const []), 70);
      expect(bsMatchScore('jjk', 'Chú Thuật Hồi Chiến', const ['JJK']), 100);
      expect(bsMatchScore('naruto', 'One Piece', const []), 0);
    });
    test('ISBN-10/13 validation and conversion', () {
      expect(bsToIsbn13('978-604-2-33451-9'), isNull); // wrong check digit
      expect(bsToIsbn13('978-604-2-33451-8'), '9786042334518');
      expect(bsToIsbn13('9780306406157'), '9780306406157');
      expect(bsToIsbn13('0-306-40615-2'), '9780306406157');
      expect(bsIsValidIsbn10('080442957X'), isTrue);
    });
    test('volume and series key from catalogue titles', () {
      expect(bsVolumeFromTitle('One Piece - Tập 105'), 105);
      expect(bsVolumeFromTitle('Spy x Family Vol. 12'), 12);
      expect(bsSeriesKey('One Piece - Tập 105 (Bản Đặc Biệt)'), 'one piece');
      expect(bsSimilarity('Jujutsu Kaisen', 'Jujutsu Kaisen'), 1);
      expect(bsSimilarity('Jujutsu Kaisen', 'Jujustu Kaisen'), greaterThan(0.4));
    });
    test('gaps, ranges and CSV', () {
      expect(bsGaps([1, 2, 3, 5, 8]), [4, 6, 7]);
      expect(bsGaps([0, 2]), [1]);
      expect(bsGaps([1.5, 2]), [1]);
      expect(bsRangeText([1, 2, 3, 5, 7, 8]), '1-3, 5, 7-8');
      expect(bsParseRange('1-3, 7; 10'), [1, 2, 3, 7, 10]);
      final rows = bsParseCsv('﻿a,"b ""q"", c"\r\nx;y\n');
      expect(rows, [
        ['a', 'b "q", c'],
        ['x', 'y'],
      ]);
    });
  });

  group('store', () {
    late Directory temp;
    final store = BookshelfStore.instance;
    setUpAll(() async {
      temp = await Directory.systemTemp.createTemp('yh063_bs');
      Hive.init(temp.path);
      await store.initWithBox(await Hive.openBox(BookshelfStore.boxName));
    });
    tearDownAll(() async {
      await Hive.close();
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    });

    test('search + ownership badges + duplicate guard (FN-01/02/21/26)', () async {
      final op = await store.createSeries('One Piece', publisher: 'Kim Đồng');
      final jjk = await store.createSeries('Chú Thuật Hồi Chiến', aliases: ['Jujutsu Kaisen', 'JJK']);
      expect(await store.addVolumes(op.id, bsParseRange('1-105')), 105);
      await store.addVolumes(jjk.id, [for (var i = 0; i <= 24; i++) if (i != 19) i.toDouble()]);
      await store.addVolume(jjk.id, 20, edition: BsEdition.limited);

      final hits = store.search('one piece 105');
      expect(hits.first.series.id, op.id);
      expect(hits.first.ownership, BsOwnership.owned);
      expect(store.search('one piece 106').first.ownership, BsOwnership.missing);
      // JJK has a limited edition → owning only the regular one is orange
      expect(store.search('jjk 18').first.ownership, BsOwnership.regularOnly);
      expect(store.search('jjk 20').first.ownership, BsOwnership.owned);
      expect(store.search('chu thuat 19').first.ownership, BsOwnership.missing);

      final dup = await store.addVolume(op.id, 50);
      expect(dup.duplicate, isTrue);
      final extra = await store.addVolume(op.id, 50, allowExtraCopy: true);
      expect(extra.duplicate, isFalse);
      expect(extra.volume.copies, 2);
    });

    test('gaps, latest, shopping list, stats (FN-05/06/24/25)', () async {
      final jjk = store.search('jjk').first.series;
      expect(store.gapsOf(jjk.id), [19]);
      expect(store.latestOf(jjk.id), 24);
      final list = store.shoppingList();
      expect(list.any((e) => e.series.id == jjk.id && e.volume == 19 && e.reason == 'gap'), isTrue);
      expect(list.any((e) => e.series.id == jjk.id && e.volume == 25 && e.reason == 'next'), isTrue);
      await store.addWish(jjk.id, volume: 25, edition: BsEdition.limited);
      expect(store.shoppingList().where((e) => e.reason == 'wish').length, 1);
      await store.addVolume(jjk.id, 25, edition: BsEdition.limited);
      expect(store.shoppingList().where((e) => e.reason == 'wish').length, 0, reason: 'bought → wish removed');
      final st = store.stats();
      expect(st['series'], 2);
      expect((st['books'] as int) >= 105 + 24, isTrue);
    });

    test('fuzzy series match + ISBN lookup (cache, Google, shelf) (FN-08/19)', () async {
      expect(store.matchSeries('Jujutsu Kaisen - Tập 26')?.title, 'Chú Thuật Hồi Chiến');
      expect(store.matchSeries('Doraemon tập 3'), isNull);
      final mock = MockClient((req) async {
        if (req.url.host == 'www.googleapis.com') {
          return http.Response(
              '{"items":[{"volumeInfo":{"title":"Thám Tử Lừng Danh Conan - Tập 104","authors":["Gosho Aoyama"],"publisher":"Kim Đồng"}}]}',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('{}', 404);
      });
      final r = await store.lookupIsbn('9780306406157', client: mock);
      expect(r?.source, 'google');
      expect(r?.volume, 104);
      final op = store.search('one piece').first.series;
      await store.addVolume(op.id, 106, isbn: '0-306-40615-2');
      final own = await store.lookupIsbn('9780306406157', client: mock);
      expect(own?.source, 'shelf');
      expect(store.volumesByIsbn('978-0-306-40615-7').length, 1);
    });

    test('CSV export → import round trip (FN-30)', () async {
      final csv = store.exportCsv();
      expect(csv.startsWith('﻿Tên bộ'), isTrue);
      final r = await store.importCsv('Tên bộ,Tập\r\nFrieren,1-11\r\nOne Piece,107\r\n,5\r\n');
      expect(r.series, 1);
      expect(r.volumes, 12);
      expect(r.skipped, 1);
      expect(store.search('frieren 11').first.ownership, BsOwnership.owned);
    });

    test('0.6.3 review: CSV keeps read status, never merges near-named series', () async {
      final r = await store.importCsv('Tên bộ,Tập,Phiên bản,ISBN,Giá,Ngày mua,Nơi mua,NXB,Trạng thái đọc\r\n'
          'Solaris,1,regular,,,,,,read\r\nSolaris Plus,1,regular,,,,,,Đang đọc\r\n');
      expect(r.series, 2);
      expect(r.volumes, 2);
      final a = store.series.firstWhere((s) => s.title == 'Solaris');
      final b = store.series.firstWhere((s) => s.title == 'Solaris Plus');
      expect(store.volumesOf(a.id).single.readStatus, BsReadStatus.read);
      expect(store.volumesOf(b.id).single.readStatus, BsReadStatus.reading);
    });

    test('0.6.3 review: bulk add drops the matching wish', () async {
      final s = store.series.firstWhere((s) => s.title == 'Solaris');
      await store.addWish(s.id, volume: 2);
      expect(store.shoppingList().any((e) => e.series.id == s.id && e.volume == 2 && e.reason == 'wish'), isTrue);
      await store.addVolumes(s.id, [2]);
      expect(store.shoppingList().any((e) => e.series.id == s.id && e.volume == 2 && e.reason == 'wish'), isFalse);
    });

    test('data survives a reload from the box (backup restore path)', () async {
      final before = store.series.length;
      store.onRestored();
      expect(store.series.length, before);
      expect(store.search('frieren').isNotEmpty, isTrue);
    });
  });
}
