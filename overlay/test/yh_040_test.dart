import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('YomiHub 0.4.0 Upgrades & Regression Fixes', () {
    test('AppIdentity reports version', () {
      expect(AppIdentity.userAgent, startsWith('YomiHub/'));
    });

    test('sanitizeUrl repairs missing slash between domain TLD and digits', () {
      expect(
        YomiUrlOverride.sanitizeUrl('https://mimihentai.net24403'),
        'https://mimihentai.net/24403',
      );
      expect(
        YomiUrlOverride.sanitizeUrl('https://mimihentai.net24403/chapter-1'),
        'https://mimihentai.net/24403/chapter-1',
      );
    });

    test('sanitizeUrl strips accidental double protocol prefix', () {
      expect(
        YomiUrlOverride.sanitizeUrl('https://vi-hentai.moehttps://2tencb.top/page1'),
        'https://2tencb.top/page1',
      );
    });

    test('sanitizeUrl handles protocol-relative URLs', () {
      expect(
        YomiUrlOverride.sanitizeUrl('//cdn.domain.com/image.jpg'),
        'https://cdn.domain.com/image.jpg',
      );
    });

    test('sanitizeUrl resolves relative paths with baseUrl', () {
      expect(
        YomiUrlOverride.sanitizeUrl(
          '/truyen-hentai/co-giao-thao-1',
          baseUrl: 'https://hentaivn.gold',
        ),
        'https://hentaivn.gold/truyen-hentai/co-giao-thao-1',
      );
      expect(
        YomiUrlOverride.sanitizeUrl(
          'chapter/2',
          baseUrl: 'https://truyenvn.shop/',
        ),
        'https://truyenvn.shop/chapter/2',
      );
    });

    test('sanitizeUrl resolves relative paths from referer or host header when baseUrl is missing', () {
      expect(
        YomiUrlOverride.sanitizeUrl(
          '/read/chapter-10',
          headers: {'Referer': 'https://custom-manga.com/manga/100'},
        ),
        'https://custom-manga.com/read/chapter-10',
      );
      expect(
        YomiUrlOverride.sanitizeUrl(
          '/api/v1/episodes',
          headers: {'Host': 'api.custom-anime.com'},
        ),
        'https://api.custom-anime.com/api/v1/episodes',
      );
    });

    test('sanitizeUrl heuristic fallback for common domains when no base or header', () {
      expect(
        YomiUrlOverride.sanitizeUrl('/truyen-hentai/1'),
        'https://hentaivn.gold/truyen-hentai/1',
      );
      expect(
        YomiUrlOverride.sanitizeUrl('/truyen-tranh/1'),
        'https://truyenvn.shop/truyen-tranh/1',
      );
      expect(
        YomiUrlOverride.sanitizeUrl('/phim/tap-1'),
        'https://ophim1.com/phim/tap-1',
      );
    });

    test('Manga entry tolerates null name and null source safely', () {
      final m = Manga(
        sourceId: 1,
        name: null,
        source: null,
        author: '',
        artist: '',
        genre: [],
        imageUrl: '',
        lang: 'vi',
        link: '',
        status: Status.unknown,
        description: '',
      );
      expect(m.name ?? '', '');
      expect(m.source ?? '', '');
    });
  });
}
