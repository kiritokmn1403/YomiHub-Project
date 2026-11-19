// YomiHub 0.6.0 – fixes for log 18–19/11/2026 (0.5.9 build 2052, Xiaomi Android 16).
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/image_load_timeout.dart';
import 'package:mangayomi/yomihub/a6/a6_notice.dart';
import 'package:mangayomi/yomihub/health/health_connect_service.dart';

void main() {
  group('Cloudflare challenge is not a dead server (CBHentai mirror flip)', () {
    test('cf-mitigated challenge', () {
      expect(isCloudflareChallengeResponse(403, {'cf-mitigated': 'challenge'}), isTrue);
    });
    test('server cloudflare + cf-ray on 403/503', () {
      expect(isCloudflareChallengeResponse(403, {'Server': 'cloudflare', 'CF-RAY': 'abc-SIN'}), isTrue);
      expect(isCloudflareChallengeResponse(503, {'server': 'cloudflare', 'cf-ray': 'x'}), isTrue);
    });
    test('plain 403 / 500 / 522 stay errors (mirror allowed)', () {
      expect(isCloudflareChallengeResponse(403, {'server': 'nginx'}), isFalse);
      expect(isCloudflareChallengeResponse(500, {'server': 'cloudflare', 'cf-ray': 'x'}), isFalse);
      expect(isCloudflareChallengeResponse(522, {'server': 'cloudflare', 'cf-ray': 'x'}), isFalse);
    });
  });

  group('Image log names the real host behind 127.0.0.1', () {
    test('Kotatsu bridge', () {
      const u = 'http://127.0.0.1:47350/kotatsu/image?source=SAYHENTAI&page=https%3A%2F%2Fcdn.pubtranxzyzz.store%2Fhen%2F1.jpeg';
      expect(logImageHost(u), 'cdn.pubtranxzyzz.store (qua cổng nội bộ)');
    });
    test('HLS proxy ?u=', () {
      expect(logImageHost('http://127.0.0.1:35455/yh_hls?u=https%3A%2F%2Fhv-h.phncdn.com%2Fx.m3u8'),
          'hv-h.phncdn.com (qua cổng nội bộ)');
    });
    test('normal url unchanged', () {
      expect(logImageHost('https://uploads.mangadex.org/covers/a.jpg'), 'uploads.mangadex.org');
    });
  });

  group('Health Connect warning once a day', () {
    final d1 = DateTime(2026, 11, 19, 8);
    test('first time logs, same day does not, next day logs', () {
      expect(shouldLogDaily('perm', '', d1), isTrue);
      final st = dailyStamp('perm', d1);
      expect(shouldLogDaily('perm', st, d1.add(const Duration(hours: 10))), isFalse);
      expect(shouldLogDaily('perm', st, DateTime(2026, 11, 20, 1)), isTrue);
      expect(shouldLogDaily('other', st, d1), isTrue);
    });
  });

  group('android6 APK notice', () {
    test('applies only to the a6 build on Android 7.0+', () {
      expect(YomiA6Notice.applies(a6Build: true, sdkInt: 36), isTrue);
      expect(YomiA6Notice.applies(a6Build: true, sdkInt: 23), isFalse);
      expect(YomiA6Notice.applies(a6Build: false, sdkInt: 36), isFalse);
      expect(YomiA6Notice.releasesUrl, contains('/releases/latest'));
    });
  });
}
