import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:mangayomi/yomihub/vpn/vpn_tunnels.dart';

String _vmess(Map<String, dynamic> j) => 'vmess://${base64.encode(utf8.encode(jsonEncode(j)))}';

void main() {
  group('0.5.7 VPN – Xray share links (V1)', () {
    test('vmess tls with empty host/sni falls back to the server name', () {
      final ob = XrayLinks.outbound(_vmess({
        'v': '2', 'ps': 'x', 'add': 'vm.example.com', 'port': '443', 'id': 'uuid',
        'aid': '0', 'net': 'ws', 'type': 'none', 'host': '', 'path': '/ws', 'tls': 'tls', 'sni': '',
      }));
      final s = ob['streamSettings'] as Map;
      expect((s['tlsSettings'] as Map)['serverName'], 'vm.example.com');
      expect(((s['wsSettings'] as Map)['headers'] as Map)['Host'], 'vm.example.com');
    });

    test('vless with empty sni= uses the host, a real sni wins', () {
      final a = XrayLinks.outbound('vless://id@vl.example.com:443?security=tls&sni=&type=tcp#a');
      expect((((a['streamSettings'] as Map)['tlsSettings']) as Map)['serverName'], 'vl.example.com');
      final b = XrayLinks.outbound('vless://id@1.2.3.4:443?security=tls&sni=front.example.org&type=ws&host=cdn.example.org#b');
      final s = b['streamSettings'] as Map;
      expect((s['tlsSettings'] as Map)['serverName'], 'front.example.org');
      expect(((s['wsSettings'] as Map)['headers'] as Map)['Host'], 'cdn.example.org');
    });

    test('reality with empty sni keeps a usable serverName', () {
      final o = XrayLinks.outbound('vless://id@rl.example.com:443?security=reality&sni=&pbk=K&sid=1&type=tcp#r');
      expect((((o['streamSettings'] as Map)['realitySettings']) as Map)['serverName'], 'rl.example.com');
    });
  });

  group('0.5.7 VPN – routing state', () {
    setUp(() {
      YomiVpnState.torEnabled = false;
      YomiVpnState.torRunning = false;
      YomiVpnState.torHttpPort = 0;
      YomiVpnState.xrayRunning = false;
      YomiVpnState.proxyEnabled = false;
      YomiVpnState.proxyUrl = '';
      YomiVpnState.killSwitch = true;
      YomiVpnState.scopeAllSources = true;
      YomiVpnState.scopeSources = {};
    });

    test('kill switch blocks while Tor is starting, then follows Tor', () {
      YomiVpnState.torEnabled = true;
      expect(YomiVpnState.activeProxy(), 'http://127.0.0.1:9');
      YomiVpnState.killSwitch = false;
      expect(YomiVpnState.activeProxy(), isNull);
      YomiVpnState.torRunning = true;
      YomiVpnState.torHttpPort = 8118;
      expect(YomiVpnState.activeProxy(), 'http://127.0.0.1:8118');
    });

    test('scope: only chosen sources are routed when "all" is off', () {
      YomiVpnState.proxyEnabled = true;
      YomiVpnState.proxyUrl = 'http://1.2.3.4:8080';
      YomiVpnState.scopeAllSources = false;
      YomiVpnState.scopeSources = {7};
      expect(YomiVpnState.proxyFor(7), 'http://1.2.3.4:8080');
      expect(YomiVpnState.proxyFor(8), isNull);
      expect(YomiVpnState.proxyFor(null), isNull);
    });

    test('normaliseProxy accepts host:port and rejects junk', () {
      expect(YomiVpnState.normaliseProxy('1.2.3.4:8080'), 'http://1.2.3.4:8080');
      expect(YomiVpnState.normaliseProxy('socks5://h:1080'), 'socks5://h:1080');
      expect(YomiVpnState.normaliseProxy('ftp://h:21'), '');
      expect(YomiVpnState.normaliseProxy('hostonly'), '');
    });
  });
}
