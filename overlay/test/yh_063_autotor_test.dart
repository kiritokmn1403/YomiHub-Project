// YomiHub 0.6.3 – auto Tor for ISP-blocked sites + Tor stall pause guard.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/vpn/auto_tor.dart';
import 'package:mangayomi/yomihub/vpn/tor_fallback.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

void main() {
  test('looksBlocked recognises the log errors (TLS EOF, DNS, reset, handshake)', () {
    const blocked = [
      'RhttpConnectionException: Connection error. URL: https://animevietsub.nl/ (hyper_util::client::legacy::Error(Connect, Custom { kind: Other, error: Custom { kind: UnexpectedEof, error: "tls handshake eof" } }))',
      'connection closed',
      'HandshakeException: Connection terminated during handshake',
      'Unable to resolve host "rule34video.com" (system DNS and DNS-over-HTTPS)',
      "ClientException with SocketException: Failed host lookup: 'api.github.com'",
      'hyper_util::client::legacy::Error(SendRequest, hyper::Error(Io, Kind(ConnectionAborted)))',
    ];
    for (final m in blocked) {
      expect(YomiAutoTor.looksBlocked(Exception(m)), isTrue, reason: m);
    }
    const notBlocked = [
      'HTTP error 404',
      'TimeoutException after 0:00:20.000000: Future not completed',
      'HandshakeException: Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate)',
      'Failed to bypass Cloudflare.',
    ];
    for (final m in notBlocked) {
      expect(YomiAutoTor.looksBlocked(Exception(m)), isFalse, reason: m);
    }
    expect(YomiAutoTor.shortCause(Exception('tls handshake eof')), 'TLS');
    expect(YomiAutoTor.shortCause(Exception('Failed host lookup')), 'DNS');
  });

  test('without a connected Tor the direct error is passed through unchanged', () async {
    YomiVpnState.torEnabled = true;
    YomiVpnState.torRunning = false; // kill-switch port only → no auto Tor
    expect(YomiAutoTor.torProxy(), isNull);
    final c = YomiAutoTorClient(MockClient((_) async => throw Exception('tls handshake eof')), null);
    await expectLater(c.get(Uri.parse('https://blocked.example/')), throwsA(predicate((e) => '$e'.contains('tls handshake eof'))));
    final ok = YomiAutoTorClient(MockClient((_) async => http.Response('ok', 200)), null);
    expect((await ok.get(Uri.parse('https://fine.example/'))).body, 'ok');
    YomiVpnState.torRunning = true;
    YomiVpnState.torHttpPort = 8118;
    expect(YomiAutoTor.torProxy(), 'http://127.0.0.1:8118');
    YomiVpnState.torEnabled = false;
    YomiVpnState.torRunning = false;
  });

  test('Tor stall: time the app is frozen in the background is not a stall', () {
    final t0 = DateTime(2026, 11, 20, 7, 47);
    DateTime at(int s) => t0.add(Duration(seconds: s));
    final tr = TorStallTracker(['snowflake', 'obfs4', ''], t0, pauseGap: const Duration(seconds: 30));
    expect(tr.update(10, at(5)).kind, TorStallKind.none);
    expect(tr.update(10, at(10)).kind, TorStallKind.none);
    // frozen 07:47:10 → 07:50:56 (226 s): no switch
    expect(tr.update(10, at(236)).kind, TorStallKind.none);
    // genuinely stalled afterwards (readings every 5 s) → switch after 75 s
    TorStallStep s = const TorStallStep(TorStallKind.none);
    for (var x = 241; x <= 320 && s.kind == TorStallKind.none; x += 5) {
      s = tr.update(10, at(x));
    }
    expect(s.kind, TorStallKind.switchTo);
    expect(s.to, 'obfs4');
  });
}
