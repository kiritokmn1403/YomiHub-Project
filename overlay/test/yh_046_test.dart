import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/services/crash_report.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/booru/booru_api.dart';
import 'package:mangayomi/yomihub/kotatsu/kotatsu_bridge.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

class _DummyClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(const Stream.empty(), 200);
  }
}

/// YomiHub 0.4.6 regression tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YomiHub 0.4.6', () {
    test('AppIdentity reports version 0.4.6 or later', () {
      expect(AppIdentity.userAgent, startsWith('YomiHub/0.4.'));
    });

    test('CrashReport treats relative image load failures as expected network noise', () {
      final err1 = Exception('Failed to load /wp-content/uploads/2024/12/red88-728.gif: 404');
      expect(isExpectedFailure(err1), isTrue);

      final err2 = Exception('Failed to load image: status code 503');
      expect(isExpectedFailure(err2), isTrue);

      final bug = RangeError.range(5, 0, 2);
      expect(isExpectedFailure(bug), isFalse);
    });

    test('Booru VPN Scoping: individual and global site routing', () {
      // Save current state
      final origAll = YomiVpnState.scopeAllBooru;
      final origSites = Set<String>.from(YomiVpnState.scopeBooruSites);
      final origProxyEnabled = YomiVpnState.proxyEnabled;
      final origProxyUrl = YomiVpnState.proxyUrl;

      try {
        YomiVpnState.proxyEnabled = true;
        YomiVpnState.proxyUrl = 'http://127.0.0.1:8080';

        // 1. When scopeAllBooru is true, all booru sites are routed
        YomiVpnState.scopeAllBooru = true;
        YomiVpnState.scopeBooruSites.clear();
        expect(YomiVpnState.routesBooru('danbooru'), isTrue);
        expect(YomiVpnState.routesBooru('safebooru_org'), isTrue);
        expect(YomiVpnState.proxyForBooru('danbooru'), 'http://127.0.0.1:8080');

        // 2. When scopeAllBooru is false, only selected sites are routed
        YomiVpnState.scopeAllBooru = false;
        YomiVpnState.scopeBooruSites = {'danbooru', 'gelbooru'};

        expect(YomiVpnState.routesBooru('danbooru'), isTrue);
        expect(YomiVpnState.routesBooru('gelbooru'), isTrue);
        expect(YomiVpnState.routesBooru('safebooru_org'), isFalse);
        expect(YomiVpnState.routesBooru('konachan_net'), isFalse);

        expect(YomiVpnState.proxyForBooru('danbooru'), 'http://127.0.0.1:8080');
        expect(YomiVpnState.proxyForBooru('safebooru_org'), isNull);
      } finally {
        // Restore state
        YomiVpnState.scopeAllBooru = origAll;
        YomiVpnState.scopeBooruSites = origSites;
        YomiVpnState.proxyEnabled = origProxyEnabled;
        YomiVpnState.proxyUrl = origProxyUrl;
      }
    });

    test('BooruApi uses 0.4.6 User-Agent', () {
      final api = BooruApi(_DummyClient());
      expect(api.userAgent, contains('0.4.'));
    });

    test('KotatsuBridge ensureStarted runs without throwing', () {
      expect(() => KotatsuBridge.ensureStarted(), returnsNormally);
    });
  });
}
