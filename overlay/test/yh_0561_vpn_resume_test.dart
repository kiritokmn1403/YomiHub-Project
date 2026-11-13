import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/vpn/vpn_tunnels.dart';

/// 0.5.6.1 – AVD 13/11/2026: V8 (WireGuard "Đã kết nối" without a handshake)
/// and V7 (tunnel state lost after swiping YomiHub from recents).
void main() {
  group('V8 – WireGuard health from GoBackend statistics', () {
    test('a handshake means connected', () {
      expect(
          wgHealth(handshakeMillis: 1794511312000, rxBytes: 0, waited: const Duration(seconds: 2)),
          WgHealth.ok);
    });
    test('bytes received also prove the peer answered', () {
      expect(wgHealth(handshakeMillis: 0, rxBytes: 92, waited: const Duration(seconds: 3)), WgHealth.ok);
    });
    test('no answer yet keeps waiting until the limit', () {
      expect(wgHealth(handshakeMillis: 0, rxBytes: 0, waited: const Duration(seconds: 14)), WgHealth.waiting);
    });
    test('no answer at the limit fails (tunnel is taken down)', () {
      expect(wgHealth(handshakeMillis: 0, rxBytes: 0, waited: const Duration(seconds: 15)), WgHealth.failed);
      expect(
          wgHealth(
              handshakeMillis: 0,
              rxBytes: 0,
              waited: const Duration(seconds: 6),
              limit: const Duration(seconds: 5)),
          WgHealth.failed);
    });
  });

  group('V7 – WireGuard tunnel found running at start-up', () {
    const ids = ['wg_home', 'wg_office'];
    test('running + saved profile → adopt it', () {
      expect(wgResume(nativeUp: true, savedId: 'wg_home', wireguardIds: ids), WgResume.adopt);
    });
    test('running but no / unknown profile → orphan, take it down', () {
      expect(wgResume(nativeUp: true, savedId: null, wireguardIds: ids), WgResume.orphan);
      expect(wgResume(nativeUp: true, savedId: 'preset_warp', wireguardIds: ids), WgResume.orphan);
    });
    test('not running → forget the saved profile, or nothing to do', () {
      expect(wgResume(nativeUp: false, savedId: 'wg_home', wireguardIds: ids), WgResume.clearSaved);
      expect(wgResume(nativeUp: false, savedId: null, wireguardIds: ids), WgResume.none);
    });
  });

  group('V7 – WARP at start-up', () {
    test('switch on + tunnel running → adopt (no more "Đang kết nối…")', () {
      expect(warpResume(enabled: true, nativeUp: true), WarpResume.adopt);
    });
    test('switch on + tunnel gone (process restarted) → reconnect', () {
      expect(warpResume(enabled: true, nativeUp: false), WarpResume.reconnect);
    });
    test('switch off + tunnel running → orphan, take it down', () {
      expect(warpResume(enabled: false, nativeUp: true), WarpResume.orphan);
    });
    test('switch off + nothing running → nothing', () {
      expect(warpResume(enabled: false, nativeUp: false), WarpResume.none);
    });
  });

  test('bundled WARP presets are still recognised (to retire them)', () {
    expect(YomiTunnels.isPreset('preset_warp'), isTrue);
    expect(YomiTunnels.isPreset('preset_warp_plus'), isTrue);
    expect(YomiTunnels.isPreset('wg_home'), isFalse);
  });
}
