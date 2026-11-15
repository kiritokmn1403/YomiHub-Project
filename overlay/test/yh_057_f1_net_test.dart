// YomiHub 0.5.7 (F1) – network errors of "logs 7.txt" (12–14/11/2026):
//  1. Kotatsu bridge request sent to the VPN kill switch (127.0.0.1:9)
//  2. Tor bootstrap stuck with a fixed bridge (snowflake) – fallback logic
//  3. Cloudflare solved in the WebView but the extension stays blocked
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/cloudflare/cf_identity.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';
import 'package:mangayomi/yomihub/net/loopback_bypass.dart';
import 'package:mangayomi/yomihub/vpn/tor_fallback.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

void _resetVpn() {
  YomiVpnState.torEnabled = false;
  YomiVpnState.torRunning = false;
  YomiVpnState.torHttpPort = 0;
  YomiVpnState.xrayRunning = false;
  YomiVpnState.proxyEnabled = false;
  YomiVpnState.proxyUrl = '';
  YomiVpnState.killSwitch = true;
  YomiVpnState.scopeAllSources = true;
  YomiVpnState.scopeSources = {};
  YomiVpnState.scopeWebView = true;
  YomiVpnState.jvmBridgeProxy = null;
}

void main() {
  setUp(_resetVpn);
  tearDown(_resetVpn);

  group('1. loopback never goes through a proxy', () {
    test('isLoopbackHost', () {
      for (final h in ['127.0.0.1', 'localhost', 'LOCALHOST', '127.8.9.10', '::1', '[::1]', 'foo.localhost', '::ffff:127.0.0.1', 'localhost.']) {
        expect(YomiVpnState.isLoopbackHost(h), isTrue, reason: h);
      }
      for (final h in ['', '128.0.0.1', '127.0.0.1.evil.com', 'localhost.evil.com', '10.0.0.1', '192.168.1.1', 'hentaicube.xyz', '1127.0.0.1', '127.0.0.256', '0.0.0.0']) {
        expect(YomiVpnState.isLoopbackHost(h), isFalse, reason: h);
      }
    });

    test('bypass client: loopback → direct, everything else → proxied', () async {
      final seen = <String>[];
      final proxied = MockClient((r) async {
        seen.add('proxied ${r.url}');
        return http.Response('p', 200);
      });
      final direct = MockClient((r) async {
        seen.add('direct ${r.url}');
        return http.Response('d', 200);
      });
      final c = YomiLoopbackBypassClient(proxied, direct, proxy: 'http://127.0.0.1:9');
      YomiVpnState.jvmBridgeProxy = 'http://127.0.0.1:9';
      expect((await c.get(Uri.parse('http://127.0.0.1:47350/kotatsu/list?source=HENTAICUBE'))).body, 'd');
      expect((await c.get(Uri.parse('http://localhost:5555/yh_webfetch'))).body, 'd');
      expect((await c.get(Uri.parse('https://hentaicube.xyz/'))).body, 'p');
      expect(seen, [
        'direct http://127.0.0.1:47350/kotatsu/list?source=HENTAICUBE',
        'direct http://localhost:5555/yh_webfetch',
        'proxied https://hentaicube.xyz/',
      ]);
    });

    test('leak guard: a routed source may only reach a JVM bridge that takes the same route', () async {
      const tor = 'http://127.0.0.1:8118';
      final kotatsu = Uri.parse('http://127.0.0.1:47350/kotatsu/list?source=X');
      // per-extension scope: the JVM (Kotatsu / IReader) is not proxied
      YomiVpnState.jvmBridgeProxy = null;
      expect(YomiVpnState.bridgeWouldLeak(kotatsu, tor), isTrue);
      expect(YomiVpnState.bridgeWouldLeak(Uri.parse('http://127.0.0.1:47360/ireader/x'), tor), isTrue);
      // other loopback servers do not fetch on behalf of the source
      expect(YomiVpnState.bridgeWouldLeak(Uri.parse('http://127.0.0.1:5555/yh_chunk'), tor), isFalse);
      // not routed at all → nothing to protect
      expect(YomiVpnState.bridgeWouldLeak(kotatsu, null), isFalse);
      // "all extensions" on Android: the JVM follows the same proxy
      YomiVpnState.jvmBridgeProxy = tor;
      expect(YomiVpnState.bridgeWouldLeak(kotatsu, tor), isFalse);

      YomiVpnState.jvmBridgeProxy = null;
      var directCalls = 0;
      final c = YomiLoopbackBypassClient(
        MockClient((_) async => http.Response('p', 200)),
        MockClient((_) async {
          directCalls++;
          return http.Response('d', 200);
        }),
        proxy: tor,
      );
      expect(YomiRouteBlocked.caused(const SocketException('Connection refused')), isFalse);
      await expectLater(c.get(kotatsu), throwsA(isA<YomiRouteBlocked>()));
      expect(directCalls, 0);
      // the JS runtime must not restart the Kotatsu bridge for this error,
      // even when an HTTP wrapper re-throws it as another type
      expect(YomiRouteBlocked.caused(Exception('wrapped')), isTrue);
    });

    test('MClient: kill switch on (Tor starting) – a loopback server still answers (dart:io client)', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) {
        r.response
          ..write('pong ${r.uri.path}')
          ..close();
      });
      addTearDown(() => server.close(force: true));
      YomiVpnState.torEnabled = true; // not running → kill switch http://127.0.0.1:9
      expect(YomiVpnState.proxyFor(null), 'http://127.0.0.1:9');
      final c = MClient.httpClient(reqcopyWith: {'useDartHttpClient': true});
      expect(c, isA<YomiLoopbackBypassClient>());
      final r = await c.get(Uri.parse('http://127.0.0.1:${server.port}/kotatsu/ping')).timeout(const Duration(seconds: 10));
      expect(r.statusCode, 200);
      expect(r.body, 'pong /kotatsu/ping');
      // …while a real site is still blocked by the kill switch
      await expectLater(
        c.get(Uri.parse('http://example.invalid/')).timeout(const Duration(seconds: 10)),
        throwsA(anything),
      );
    });

    test('MClient: default path (rhttp when available) is wrapped too when a proxy applies', () {
      YomiVpnState.torEnabled = true;
      expect(MClient.httpClient(), isA<YomiLoopbackBypassClient>());
      YomiVpnState.torEnabled = false;
      expect(MClient.httpClient(), isNot(isA<YomiLoopbackBypassClient>()));
    });
  });

  group('2. Tor bridge fallback (stall = progress not increasing)', () {
    final t0 = DateTime(2026, 11, 12, 6, 26, 55);
    DateTime at(int s) => t0.add(Duration(seconds: s));

    test('order: chosen transport, the other transports with bridge lines, then direct', () {
      expect(TorBridgeFallback.order('snowflake', ['meek', 'obfs4', 'snowflake']), ['snowflake', 'obfs4', 'meek', '']);
      expect(TorBridgeFallback.order('obfs4', ['meek', 'obfs4', 'snowflake']), ['obfs4', 'snowflake', 'meek', '']);
      expect(TorBridgeFallback.order('meek', ['snowflake']), ['meek', 'snowflake', '']);
      // "auto" (native watcher) and "no bridge" keep their behaviour
      expect(TorBridgeFallback.order('auto', ['snowflake']), ['auto']);
      expect(TorBridgeFallback.order('', ['snowflake']), ['']);
      expect(TorBridgeFallback.appliesTo('auto'), isFalse);
      expect(TorBridgeFallback.appliesTo(''), isFalse);
    });

    test('parses status/bootstrap-phase', () {
      const b = 'NOTICE BOOTSTRAP PROGRESS=45 TAG=requesting_descriptors SUMMARY="Asking for relay descriptors"';
      expect(TorBridgeFallback.progressOf(b), 45);
      expect(TorBridgeFallback.summaryOf(b), 'Asking for relay descriptors');
      expect(TorBridgeFallback.progressOf(''), isNull);
    });

    test('log 12/11 06:27: stuck at 45 % with snowflake → switch after 75 s without progress', () {
      final tr = TorStallTracker(TorBridgeFallback.order('snowflake', ['snowflake', 'obfs4', 'meek']), t0);
      expect(tr.update(null, at(5)).kind, TorStallKind.none); // control port not up
      expect(tr.update(10, at(8)).kind, TorStallKind.none);
      expect(tr.update(45, at(10)).kind, TorStallKind.none);
      expect(tr.update(45, at(60)).kind, TorStallKind.none);
      expect(tr.update(45, at(84)).kind, TorStallKind.none); // 74 s
      final s = tr.update(45, at(86));
      expect(s.kind, TorStallKind.switchTo);
      expect(s.from, 'snowflake');
      expect(s.to, 'obfs4');
      expect(s.percent, 45);
      expect(s.stalled.inSeconds, 76);
      expect([s.attempt, s.total], [2, 4]);
      expect(tr.current, 'obfs4');
      expect(tr.onFallback, isTrue);
    });

    test('a slow bootstrap that keeps advancing is never interrupted', () {
      final tr = TorStallTracker(TorBridgeFallback.order('snowflake', ['snowflake', 'obfs4', 'meek']), t0);
      var pct = 5;
      for (var s = 0; s <= 600; s += 60) {
        expect(tr.update(pct, at(s)).kind, TorStallKind.none, reason: 't=$s');
        pct += 5; // +5 % a minute: slower than the old fixed 90 s limit
      }
      expect(tr.onFallback, isFalse);
      expect(tr.update(100, at(660)).kind, TorStallKind.done);
      expect(tr.finished, isTrue);
    });

    test('tries every transport, direct last (40 s), then goes back to the chosen one', () {
      final tr = TorStallTracker(TorBridgeFallback.order('snowflake', ['snowflake', 'obfs4', 'meek']), t0);
      var t = 0;
      final switches = <String>[];
      TorStallStep? last;
      while (!tr.finished && t < 2000) {
        t += 5;
        final s = tr.update(45, at(t));
        if (s.kind == TorStallKind.switchTo) switches.add('${s.to}@$t');
        last = s;
      }
      // 45 % first seen at t=5; +75 s for each transport, +40 s for direct
      expect(switches, ['obfs4@80', 'meek@160', '@240']);
      expect(last!.kind, TorStallKind.exhausted);
      expect(last.to, 'snowflake');
      expect(t, 285);
      expect(tr.tried, ['snowflake', 'obfs4', 'meek', '']);
      // nothing more after that
      expect(tr.update(45, at(5000)).kind, TorStallKind.none);
    });

    test('progress after a switch restarts the clock; 100 % ends on the fallback transport', () {
      final tr = TorStallTracker(TorBridgeFallback.order('snowflake', ['snowflake', 'obfs4']), t0);
      tr.update(45, at(0));
      expect(tr.update(45, at(80)).kind, TorStallKind.switchTo);
      expect(tr.update(45, at(85)).kind, TorStallKind.none); // first reading on obfs4
      expect(tr.update(50, at(150)).kind, TorStallKind.none); // progress
      expect(tr.update(50, at(220)).kind, TorStallKind.none); // 70 s since progress
      final d = tr.update(100, at(221));
      expect(d.kind, TorStallKind.done);
      expect(d.from, 'obfs4');
      expect(tr.onFallback, isTrue);
    });

    test('labels used in the Vietnamese log', () {
      expect(TorBridgeFallback.label('obfs4'), 'cầu nối "obfs4"');
      expect(TorBridgeFallback.label(''), contains('kết nối thẳng'));
    });
  });

  group('3. Cloudflare: identity of the WebView that earned cf_clearance', () {
    const wvUa = 'Mozilla/5.0 (Linux; Android 15; 2412DPC0AG Build/AP3A.240905.015; wv) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Version/4.0 Chrome/141.0.7390.122 Mobile Safari/537.36';

    test('captured identity → exact client hints + languages', () {
      final id = CfIdentity.parse(jsonEncode({
        'ua': wvUa,
        'brands': [
          ['Android WebView', '141'],
          ['Chromium', '141'],
          ['Not?A_Brand', '8'],
        ],
        'mobile': true,
        'platform': 'Android',
        'langs': ['vi-VN', 'vi', 'en-US', 'en'],
      }))!;
      expect(id.secChUa, '"Android WebView";v="141", "Chromium";v="141", "Not?A_Brand";v="8"');
      expect(id.secChUaMobile, '?1');
      expect(id.secChUaPlatform, '"Android"');
      expect(id.acceptLanguage, 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7');
      // survives storage, also when evaluateJavascript double-encodes
      final again = CfIdentity.parse(jsonEncode(id.encode()))!;
      expect(again.secChUa, id.secChUa);
      expect(again.languages, id.languages);
    });

    test('clearance saved before 0.5.7 (User-Agent only): hints derived from that User-Agent', () {
      const id = CfIdentity(ua: wvUa);
      expect(id.secChUa, contains('"Android WebView";v="141"'));
      expect(id.secChUa, contains('"Chromium";v="141"'));
      expect(id.secChUaMobile, '?1');
      expect(id.secChUaPlatform, '"Android"');
      expect(id.acceptLanguage, isNull);
      const win = CfIdentity(ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0');
      expect(win.secChUa, contains('"Microsoft Edge";v="139"'));
      expect(win.secChUaMobile, '?0');
      expect(win.secChUaPlatform, '"Windows"');
    });

    test('applyTo: replaces the extension\'s UA and contradicting hints, keeps its language', () {
      final id = CfIdentity.parse(jsonEncode({
        'ua': wvUa,
        'brands': [
          ['Android WebView', '141'],
          ['Chromium', '141'],
        ],
        'mobile': true,
        'platform': 'Android',
        'langs': ['vi-VN', 'vi'],
      }))!;
      final h = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0) Chrome/120.0.0.0 Safari/537.36',
        'Sec-CH-UA': '"Google Chrome";v="120"',
        'sec-ch-ua-full-version-list': '"Google Chrome";v="120.0.1.2"',
        'Accept-Language': 'en-US',
        'Cookie': 'cf_clearance=abc',
        'Referer': 'https://hentaicube.xyz/',
      };
      id.applyTo(h);
      final l = {for (final e in h.entries) e.key.toLowerCase(): e.value};
      expect(h.length, l.length, reason: 'no duplicate header names: $h');
      expect(l['user-agent'], wvUa);
      expect(l['sec-ch-ua'], '"Android WebView";v="141", "Chromium";v="141"');
      expect(l['sec-ch-ua-mobile'], '?1');
      expect(l['sec-ch-ua-platform'], '"Android"');
      expect(l.containsKey('sec-ch-ua-full-version-list'), isFalse);
      expect(l['accept-language'], 'en-US');
      expect(l['cookie'], 'cf_clearance=abc');
      expect(l['referer'], 'https://hentaicube.xyz/');

      final none = <String, String>{'Cookie': 'cf_clearance=abc'};
      id.applyTo(none);
      expect(none['accept-language'], 'vi-VN,vi;q=0.9');
    });

    test('Firefox (GeckoView) identity sends no client hints; CloudScraper does not add its own', () {
      const id = CfIdentity(ua: 'Mozilla/5.0 (Android 14; Mobile; rv:143.0) Gecko/143.0 Firefox/143.0');
      final h = <String, String>{'cookie': 'cf_clearance=abc', 'sec-ch-ua': '"Google Chrome";v="140"'};
      id.applyTo(h);
      expect(h.keys.where((k) => k.toLowerCase().startsWith('sec-ch-ua')), isEmpty);
      CloudScraper.enabled = true;
      CloudScraper.emulateBrowser = true;
      CloudScraper.applyTo(h);
      expect(h.keys.where((k) => k.toLowerCase().startsWith('sec-ch-ua')), isEmpty);
      expect(h['user-agent'], id.ua, reason: 'the clearance User-Agent is kept');
      // a request without clearance still gets the emulated browser profile
      final plain = <String, String>{};
      CloudScraper.applyTo(plain);
      expect(plain.keys.map((k) => k.toLowerCase()), containsAll(['user-agent', 'sec-ch-ua', 'accept-language']));
    });

    test('page state: a leftover cookie on a challenge page is not "solved"', () {
      expect(cfPageState(jsonEncode({'t': 'Just a moment...', 'c': true})), CfPageState.challenge);
      expect(cfPageState(jsonEncode({'t': 'Chờ một chút...', 'c': false})), CfPageState.challenge);
      // localised title, only the page marker gives it away
      expect(cfPageState(jsonEncode({'t': 'しばらくお待ちください...', 'c': true})), CfPageState.challenge);
      expect(cfPageState(jsonEncode({'t': 'Attention Required! | Cloudflare', 'c': false, 'b': true})), CfPageState.blocked);
      expect(cfPageState(jsonEncode({'t': 'CBHentai - Đọc truyện', 'c': false, 'b': false})), CfPageState.ok);
      // double-encoded / broken probe results never block a real page
      expect(cfPageState(jsonEncode(jsonEncode({'t': 'Just a moment...', 'c': true}))), CfPageState.challenge);
      expect(cfPageState(null), CfPageState.ok);
      expect(cfPageState('not json'), CfPageState.ok);
    });

    test('route note: cf_clearance is bound to the IP – WebView and extension must share a route', () {
      // nothing on: both direct
      expect(YomiVpnState.routeNote(YomiVpnState.proxyFor(null)), '');
      // Tor connected, WebView in scope: same route
      YomiVpnState.torEnabled = true;
      YomiVpnState.torRunning = true;
      YomiVpnState.torHttpPort = 8118;
      expect(YomiVpnState.routeNote(YomiVpnState.proxyFor(null)), '');
      // WebView taken out of the VPN scope: different exit IP
      YomiVpnState.scopeWebView = false;
      final n = YomiVpnState.routeNote(YomiVpnState.proxyFor(null));
      expect(n, contains('WebView đi thẳng'));
      expect(n, contains('8118'));
      // Tor still starting: WebView direct, extension held by the kill switch
      YomiVpnState.scopeWebView = true;
      YomiVpnState.torRunning = false;
      expect(YomiVpnState.routeNote(YomiVpnState.proxyFor(null)), contains('Kill switch'));
    });
  });
}
