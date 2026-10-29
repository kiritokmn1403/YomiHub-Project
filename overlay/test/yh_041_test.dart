import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('YomiHub 0.4.1 Upgrades & Bug Fixes', () {
    test('AppIdentity reports version', () {
      expect(AppIdentity.userAgent, startsWith('YomiHub/'));
    });

    test('sanitizeUrl unwraps concatenated encoded URLs', () {
      const raw =
          'https://sayhentaii.art/https%3A%2F%2Fcdn.pubtranxzyzz.store%2Fhen%2F6604%2F0%2F0.jpg%3Ftoken%3DHS256';
      expect(
        YomiUrlOverride.sanitizeUrl(raw),
        'https://cdn.pubtranxzyzz.store/hen/6604/0/0.jpg?token=HS256',
      );
    });

    test('sanitizeUrl unwraps Kotatsu local bridge proxy image URLs', () {
      const raw =
          'http://127.0.0.1:47350/kotatsu/image?source=SAYHENTAI&page=https%3A%2F%2Fcdn.pubtranxzyzz.store%2Fhen%2F6604%2F0%2F8.jpg';
      expect(
        YomiUrlOverride.sanitizeUrl(raw),
        'https://cdn.pubtranxzyzz.store/hen/6604/0/8.jpg',
      );
    });

    test('sanitizeUrl maintains existing domain slash fix and protocol normalization', () {
      expect(
        YomiUrlOverride.sanitizeUrl('https://mimihentai.net24403'),
        'https://mimihentai.net/24403',
      );
      expect(
        YomiUrlOverride.sanitizeUrl('https://vi-hentai.moehttps://2tencb.top/page1'),
        'https://2tencb.top/page1',
      );
      expect(
        YomiUrlOverride.sanitizeUrl('//cdn.domain.com/image.jpg'),
        'https://cdn.domain.com/image.jpg',
      );
    });

    test('sanitizeUrl resolves relative paths with baseUrl', () {
      expect(
        YomiUrlOverride.sanitizeUrl(
          '/truyen-hentai/sample',
          baseUrl: 'https://hentaivn.gold',
        ),
        'https://hentaivn.gold/truyen-hentai/sample',
      );
    });
  });
}
