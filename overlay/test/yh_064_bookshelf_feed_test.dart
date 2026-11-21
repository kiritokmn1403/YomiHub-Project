// YomiHub 0.6.4 – Tủ Sách FN-16/FN-29 (publisher news) and FN-22 (cover photo).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mangayomi/yomihub/bookshelf/bookshelf_cover_match.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_feed.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';

void main() {
  final shelf = [
    BsSeries(id: 's1', title: 'One Piece'),
    BsSeries(id: 's2', title: 'Chú Thuật Hồi Chiến', original: 'Jujutsu Kaisen'),
    BsSeries(id: 's3', title: 'Doraemon'),
    BsSeries(id: 's4', title: 'Tôi'), // too short (< 4 letters) – never matched
  ];

  group('FN-16 publisher page parsing', () {
    test('HTML "new books" page: product links of the same host, no navigation', () {
      const html = '''
<html><body>
<nav><a href="/">Trang chủ</a><a href="/lien-he">Liên hệ</a><a href="/tin-tuc">Tin tức</a></nav>
<div class="products">
  <a href="/one-piece-tap-108"><img src="/img/op108.jpg" alt="One Piece - Tập 108"></a>
  <a href="/one-piece-tap-108">One Piece - Tập 108</a>
  <a href="/chu-thuat-hoi-chien-tap-25-ban-dac-biet" title="Chú Thuật Hồi Chiến - Tập 25 - Bản Đặc Biệt">xem</a>
  <a href="https://other.site/doraemon-tap-1">Doraemon - Tập 1 (site khác)</a>
  <a href="#top">Lên đầu trang</a>
</div></body></html>''';
      final items = BookshelfFeed.parseFeed(html, Uri.parse('https://nxbkimdong.com.vn/sach-moi-phat-hanh'), 'kimdong');
      expect(items.map((i) => i.link), [
        'https://nxbkimdong.com.vn/one-piece-tap-108',
        'https://nxbkimdong.com.vn/chu-thuat-hoi-chien-tap-25-ban-dac-biet',
      ]);
      expect(items.first.title, 'One Piece - Tập 108');
      expect(items.first.image, 'https://nxbkimdong.com.vn/img/op108.jpg');
      expect(items.last.title, contains('Bản Đặc Biệt'));
    });

    test('RSS and Atom feeds', () {
      const rss = '<?xml version="1.0"?><rss><channel><item><title>Doraemon Tập 45</title><link>https://x.vn/d45</link></item></channel></rss>';
      final r = BookshelfFeed.parseFeed(rss, Uri.parse('https://x.vn/feed'), 'tre');
      expect(r.single.title, 'Doraemon Tập 45');
      const atom = '<feed xmlns="http://www.w3.org/2005/Atom"><entry><title>Jujutsu Kaisen Artbook</title><link href="/a1"/></entry></feed>';
      final a = BookshelfFeed.parseFeed(atom, Uri.parse('https://ipm.vn/blogs/news.atom'), 'ipm');
      expect(a.single.link, 'https://ipm.vn/a1');
    });
  });

  group('FN-16 matching + FN-29 settings', () {
    test('kinds detected from the title', () {
      expect(BookshelfFeed.kindsOf('Chú Thuật Hồi Chiến - Tập 25 - Bản Đặc Biệt'), {BsFeedKind.limited});
      expect(BookshelfFeed.kindsOf('One Piece ColorWalk 10'), {BsFeedKind.colorwalk});
      expect(BookshelfFeed.kindsOf('Doraemon - Boxset trọn bộ'), {BsFeedKind.boxset});
      expect(BookshelfFeed.kindsOf('One Piece Tập 108'), {BsFeedKind.regular});
    });

    test('whole-word, accent-insensitive match; original title and aliases count', () {
      expect(BookshelfFeed.matchOf('ONE PIECE - TẬP 108', shelf)?.id, 's1');
      expect(BookshelfFeed.matchOf('Chu thuat hoi chien tap 25', shelf)?.id, 's2');
      expect(BookshelfFeed.matchOf('Jujutsu Kaisen Official Fanbook', shelf)?.id, 's2');
      expect(BookshelfFeed.matchOf('Doraemonland 3', shelf), isNull); // not a whole word
      expect(BookshelfFeed.matchOf('Tôi thấy hoa vàng trên cỏ xanh', shelf), isNull); // name < 4 letters
    });

    test('filter: source off, dismissed, muted series, kinds, maximum', () {
      final items = [
        const BsFeedItem(title: 'One Piece Tập 108', link: 'l1', sourceId: 'kimdong'),
        const BsFeedItem(title: 'One Piece Poster', link: 'l2', sourceId: 'kimdong'),
        const BsFeedItem(title: 'Doraemon Tập 45', link: 'l3', sourceId: 'tre'),
        const BsFeedItem(title: 'Jujutsu Kaisen Limited', link: 'l4', sourceId: 'ipm'),
        const BsFeedItem(title: 'Sách không liên quan', link: 'l5', sourceId: 'ipm'),
      ];
      List<String> run({Set<String>? src, Set<BsFeedKind> kinds = const {}, Set<String> dis = const {}, Set<String> mute = const {}, int max = 5}) =>
          BookshelfFeed.filterMatches(
            items: items,
            series: shelf,
            enabledSources: src ?? {'kimdong', 'tre', 'ipm'},
            kinds: kinds,
            dismissed: dis,
            muted: mute,
            max: max,
          ).map((m) => m.item.link).toList();
      expect(run(), ['l1', 'l2', 'l3', 'l4']);
      expect(run(src: {'kimdong'}), ['l1', 'l2']);
      expect(run(dis: {'l1'}), ['l2', 'l3', 'l4']);
      expect(run(mute: {'s1'}), ['l3', 'l4']);
      expect(run(kinds: {BsFeedKind.poster, BsFeedKind.limited}), ['l2', 'l4']);
      expect(run(max: 2), ['l1', 'l2']);
    });
  });

  group('FN-22 cover photo recognition (dHash)', () {
    Uint8List png(img.Image i) => Uint8List.fromList(img.encodePng(i));

    img.Image cover(int seed) {
      final i = img.Image(width: 120, height: 180);
      for (var y = 0; y < 180; y++) {
        for (var x = 0; x < 120; x++) {
          final v = ((x * (seed + 3) + y * (seed * 7 + 1)) ~/ 9 + seed * 40) % 256;
          i.setPixelRgb(x, y, v, (v * seed) % 256, 255 - v);
        }
      }
      return i;
    }

    test('identical and resized/margined copies match, other covers do not', () {
      final a = cover(1), b = cover(5);
      final ha = BookshelfCoverMatch.hashes(png(a))!;
      final hb = BookshelfCoverMatch.hashes(png(b))!;
      // a "photo": the cover scaled down with a white margin around it
      final photo = img.Image(width: 150, height: 225);
      img.fill(photo, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(photo, img.copyResize(a, width: 120, height: 180), dstX: 15, dstY: 22);
      final hp = BookshelfCoverMatch.hashes(png(photo))!;
      expect(BookshelfCoverMatch.distance(ha.first, ha.first), 0);
      final ranked = BookshelfCoverMatch.rank(hp, {'a': ha.first, 'b': hb.first});
      expect(ranked, isNotEmpty);
      expect(ranked.first.key, 'a');
      expect(ranked.any((e) => e.key == 'b'), isFalse, reason: 'distance ${BookshelfCoverMatch.distance(hp.first, hb.first)}');
    });

    test('undecodable bytes give no hash', () {
      expect(BookshelfCoverMatch.hashes(Uint8List.fromList([1, 2, 3])), isNull);
      expect(BookshelfCoverMatch.distance(0, -1), 64);
    });
  });
}
