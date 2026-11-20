// YomiHub 0.6.3 – LNReader worker isolates got the default VPN state (Tor off),
// so Hako / TruyenSS / TruyenDich never went through Tor or auto-Tor
// (logs 12, 19–20/11 "HandshakeException: Connection terminated during handshake").
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/vpn/auto_tor.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

void main() {
  test('VPN snapshot survives an isolate hop and is applied there', () async {
    YomiVpnState.torEnabled = true;
    YomiVpnState.torRunning = true;
    YomiVpnState.torHttpPort = 8118;
    YomiVpnState.scopeAllSources = false;
    YomiVpnState.scopeSources = {42};
    YomiAutoTor.enabledOverride = true;
    YomiAutoTor.applySnapshot({'routed': ['Docln.net']});
    final vpn = YomiVpnState.snapshot();
    final at = YomiAutoTor.snapshot();

    final r = await Isolate.run(() {
      YomiVpnState.applySnapshot(vpn);
      YomiAutoTor.applySnapshot(at);
      return [
        YomiVpnState.proxyFor(42),
        YomiVpnState.proxyFor(7),
        YomiAutoTor.torProxy(),
        YomiAutoTor.isRouted('docln.net'),
        YomiAutoTor.enabled,
      ];
    });
    expect(r, ['http://127.0.0.1:8118', null, 'http://127.0.0.1:8118', true, true]);
  });

  test('applying a changed snapshot bumps the client revision', () {
    YomiVpnState.torEnabled = false;
    final rev = YomiVpnState.revision;
    YomiVpnState.applySnapshot({'torEnabled': true});
    expect(YomiVpnState.revision, rev + 1);
    YomiVpnState.applySnapshot({'torEnabled': true});
    expect(YomiVpnState.revision, rev + 1);
    YomiVpnState.applySnapshot(null);
    expect(YomiVpnState.torEnabled, true);
  });
}
