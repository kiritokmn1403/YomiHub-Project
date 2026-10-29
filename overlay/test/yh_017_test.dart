// YomiHub 0.1.7 – offline checks for the new pure-Dart pieces.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/yomihub/backup/lnreader_backup.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'package:mangayomi/yomihub/library/local_metadata.dart';
import 'package:mangayomi/yomihub/vpn/win/win_vpn.dart';
import 'package:mangayomi/yomihub/repos/repo_discovery.dart';

void main() {
  group('local metadata', () {
    test('Mihon details.json', () {
      final m = parseLocalJson(jsonEncode({
        'title': 'One Piece',
        'author': 'Oda',
        'description': 'Pirates',
        'genre': ['Action', 'Adventure'],
        'status': '1',
      }))!;
      expect(m.title, 'One Piece');
      expect(m.status, Status.ongoing);
      expect(m.genre, ['Action', 'Adventure']);
    });
    test('Mangayomi json keeps old shape', () {
      final m = parseLocalJson(jsonEncode({'name': 'X', 'status': 1, 'genre': ['A']}))!;
      expect(m.title, 'X');
      expect(m.status, Status.completed);
    });
    test('out-of-range status does not throw', () {
      final m = parseLocalJson(jsonEncode({'name': 'X', 'status': 42}))!;
      expect(m.status, isNull);
    });
    test('Kotatsu index.json', () {
      final m = parseLocalJson(jsonEncode({
        'title': 'K',
        'state': 'FINISHED',
        'tags': [
          {'title': 'Drama'},
        ],
      }))!;
      expect(m.status, Status.completed);
      expect(m.genre, ['Drama']);
    });
    test('ComicInfo.xml', () {
      final m = parseComicInfo(
        '<ComicInfo><Series>Berserk &amp; Co</Series><Writer>Miura</Writer>'
        '<Genre>Dark Fantasy, Action</Genre><Summary>Guts</Summary></ComicInfo>',
      )!;
      expect(m.title, 'Berserk & Co');
      expect(m.author, 'Miura');
      expect(m.genre, ['Dark Fantasy', 'Action']);
    });
    test('applyTo never nulls the title', () {
      final manga = Manga(
        source: 'local', author: '', artist: '', genre: [], imageUrl: '', lang: '',
        link: 'a', name: 'Folder name', status: Status.unknown, description: '',
        itemType: ItemType.manga, sourceId: null,
      );
      LocalMeta().applyTo(manga);
      expect(manga.name, 'Folder name');
    });
  });

  group('URL override', () {
    test('normalise', () {
      expect(YomiUrlOverride.normalise('example.org/'), 'https://example.org');
      expect(YomiUrlOverride.normalise('http://a.b:8080/x/'), 'http://a.b:8080/x');
      expect(YomiUrlOverride.normalise('ftp://x'), isNull);
      expect(YomiUrlOverride.normalise(''), isNull);
    });
  });

  group('LNReader backup', () {
    test('repo from plugin url', () {
      expect(
        lnReaderRepoFromPluginUrl(
          'https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.js/src/plugins/english/novelbin.js',
        ),
        'https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json',
      );
    });
  });

  group('Windows VPN configs', () {
    test('WireGuard conf → Xray', () {
      final j = jsonDecode(WinVpnBackend.wireguardConfig('''
[Interface]
PrivateKey = cHJpdmF0ZWtleXByaXZhdGVrZXlwcml2YXRla2V5MDA=
Address = 172.16.0.2/32, 2606:4700:110:8a36::2/128
DNS = 1.1.1.1
MTU = 1280
[Peer]
PublicKey = bmQ0bG1vZ2UrMmJvZ2Vib2dlYm9nZWJvZ2Vib2dlMDA=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = engage.cloudflareclient.com:2408
''')) as Map;
      final ob = (j['outbounds'] as List).first as Map;
      expect(ob['protocol'], 'wireguard');
      expect((ob['settings']['address'] as List).length, 2);
      expect(ob['settings']['peers'][0]['endpoint'], 'engage.cloudflareclient.com:2408');
      expect((j['inbounds'] as List).map((e) => e['port']), [WinVpnBackend.socksPort, WinVpnBackend.httpPort]);
    });
    test('proxy bridge with password', () {
      final j = jsonDecode(WinVpnBackend.bridgeConfig(Uri.parse('socks5://us%40r:p%3Ass@1.2.3.4:1080'))) as Map;
      final s = j['outbounds'][0]['settings']['servers'][0] as Map;
      expect(j['outbounds'][0]['protocol'], 'socks');
      expect(s['users'][0], {'user': 'us@r', 'pass': 'p:ss'});
    });
  });

  test('VPN helpers present next to the Windows build', () {
    final rel = Directory('build/windows/x64/runner/Release/yomihub_bin');
    if (!rel.existsSync()) return; // only after a Windows build
    expect(File('${rel.path}/xray.exe').existsSync(), isTrue);
    expect(File('${rel.path}/tor/tor.exe').existsSync(), isTrue);
  });

  test('Website Scan sheet: repos found per site (network)', () async {
    var total = 0;
    for (final e in YomiRepoDiscovery.sites.entries) {
      final list = await YomiRepoDiscovery.scanSite(e.key, e.value);
      total += list.length;
      // ignore: avoid_print
      print('SITE ${e.value}: ${list.length} ${YomiRepoDiscovery.siteStatus[e.value]} '
          '${list.take(6).map((r) => r.url).join(' | ')}');
    }
    expect(total, greaterThan(3));
  }, timeout: const Timeout(Duration(minutes: 4)));
}
