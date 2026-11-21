// YomiHub 0.6.4 – fixes for logs_13 (YH 0.6.3 on Xiaomi 15T, 20–21/11/2026).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/mihon/service.dart';
import 'package:mangayomi/services/fetch_sources_list.dart' show yomiSiblingIndexUrl, yomiRepoGone;
import 'package:mangayomi/yomihub/net/chunk_proxy.dart';

void main() {
  group('APK bridge time limit (getPageList waited 3 minutes)', () {
    test('browsing, search and page lists give up after 90 s', () {
      for (final m in [
        'getPageList',
        'getPopularManga',
        'getPopularAnime',
        'getLatestManga',
        'getSearchAnime',
        'getFilterList',
      ]) {
        expect(MihonExtensionService.dalvikTimeoutFor('{"method":"$m","data":"x"}'),
            const Duration(seconds: 90),
            reason: m);
      }
      // jsonEncode output with spaces is accepted too
      expect(MihonExtensionService.dalvikTimeoutFor('{"method" : "getPageList"}'),
          const Duration(seconds: 90));
    });

    test('details, chapter/episode lists and videos keep 3 minutes', () {
      for (final m in ['getDetailsManga', 'getChapterList', 'getEpisodeList', 'getVideoList', '']) {
        expect(MihonExtensionService.dalvikTimeoutFor('{"method":"$m"}'), const Duration(minutes: 3),
            reason: m);
      }
      expect(MihonExtensionService.dalvikTimeoutFor('not json'), const Duration(minutes: 3));
    });
  });

  group('HLS ad filter proxy ("Failed to open http://127.0.0.1:…/yh_hls")', () {
    late HttpServer proxy;

    setUp(() async {
      proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      proxy.listen(YomiHlsAdFilter.handle);
    });

    tearDown(() => proxy.close(force: true));

    Future<HttpClientResponse> ask(String target) async {
      final c = HttpClient();
      final req = await c.getUrl(Uri.parse(
          'http://127.0.0.1:${proxy.port}/yh_hls?u=${Uri.encodeComponent(target)}&h='));
      req.followRedirects = false;
      final res = await req.close();
      await res.drain<void>();
      c.close(force: true);
      return res;
    }

    test('an unreachable playlist host sends the player to the origin (302), not 502', () async {
      // nothing listens on this port → connection refused inside the proxy
      final dead = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = dead.port;
      await dead.close();
      final target = 'http://127.0.0.1:$port/film/index.m3u8';
      final res = await ask(target);
      expect(res.statusCode, HttpStatus.found);
      expect(res.headers.value(HttpHeaders.locationHeader), target);
    });

    test('a real playlist is still served and filtered', () async {
      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      origin.listen((r) {
        r.response
          ..headers.contentType = ContentType('application', 'vnd.apple.mpegurl')
          ..write('#EXTM3U\n#EXT-X-TARGETDURATION:6\n#EXTINF:6,\nseg1.ts\n#EXT-X-ENDLIST\n')
          ..close();
      });
      try {
        final res = await ask('http://127.0.0.1:${origin.port}/film/index.m3u8');
        expect(res.statusCode, HttpStatus.ok);
      } finally {
        await origin.close(force: true);
      }
    });
  });

  group('dead / renamed repository index (Windows 0.6.3: anymex 451, sugoi 404)', () {
    test('index.min.json <-> index.json sibling, query kept', () {
      expect(yomiSiblingIndexUrl('https://raw.githubusercontent.com/Schnitzel5/sugoi-modules/main/index.min.json'),
          'https://raw.githubusercontent.com/Schnitzel5/sugoi-modules/main/index.json');
      expect(yomiSiblingIndexUrl('https://x.org/repo/index.json?v=2'), 'https://x.org/repo/index.min.json?v=2');
      expect(yomiSiblingIndexUrl('https://x.org/repo/anime_index.json'), isNull);
      expect(yomiSiblingIndexUrl('https://x.org/repo/index.pb'), isNull);
    });

    test('404 / 410 / 451 mean the repo is gone; 5xx and 403 do not', () {
      for (final c in [404, 410, 451]) {
        expect(yomiRepoGone(c), isTrue, reason: '$c');
      }
      for (final c in [200, 403, 429, 500, 503]) {
        expect(yomiRepoGone(c), isFalse, reason: '$c');
      }
    });
  });
}
