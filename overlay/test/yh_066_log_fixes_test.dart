// YomiHub 0.6.6 – fixes for logs 16 (YH 0.6.4/0.6.5 on Windows 26H2,
// 23–25/11/2026) and the owner's screenshot of 25/11 21:35.
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/lnreader/service.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

void main() {
  group('LNReader plugins get site-relative paths (Hako ln.hako.vnhttps)', () {
    test('full URL is reduced to path + query', () {
      expect(
        LNReaderExtensionService.relPath(
            'https://docln.sbs/truyen/23117-vi-toi-tu-do?a=1#c'),
        '/truyen/23117-vi-toi-tu-do?a=1#c',
      );
      expect(LNReaderExtensionService.relPath('http://ln.hako.vn'), '/');
    });

    test('relative paths are untouched', () {
      expect(LNReaderExtensionService.relPath('/truyen/358-re'), '/truyen/358-re');
      expect(LNReaderExtensionService.relPath('truyen/358'), 'truyen/358');
    });
  });

  group('Windows M-Extension-Server errors', () {
    test('missing Android class is an incompatible extension (AVSub)', () {
      expect(
          YomiExtErrors.isIncompatible(
              'android.app.ActivityThread \n\n\nstatusCode: 500'),
          isTrue);
      expect(
          YomiExtErrors.isIncompatible(
              'class x2 cannot be cast to class d0 (x2 and d0 are in unnamed module)'),
          isTrue);
      expect(YomiExtErrors.isIncompatible('HTTP 404 not found'), isFalse);
    });

    test('missing server is logged once per run', () {
      final e = MesUnavailableException('x', installing: true);
      expect(e.toString(), 'x');
      expect(e.installing, isTrue);
      expect(MesUnavailableException.firstInSession(), isTrue);
      expect(MesUnavailableException.firstInSession(), isFalse);
    });
  });

  group('Windows: extension follows WebView2 route after a Cloudflare solve', () {
    test('only proxy routes are recorded, per host, case-insensitive', () {
      expect(YomiVpnState.alignedRoute('danbooru.donmai.us'), isNull);
      YomiVpnState.alignHostToWebView('Danbooru.Donmai.us', 'http://127.0.0.1:10809');
      expect(YomiVpnState.alignedRoute('danbooru.donmai.us'), 'http://127.0.0.1:10809');
      YomiVpnState.alignHostToWebView('example.com', '');
      expect(YomiVpnState.alignedRoute('example.com'), isNull);
      YomiVpnState.alignHostToWebView('127.0.0.1', 'http://127.0.0.1:10809');
      expect(YomiVpnState.alignedRoute('127.0.0.1'), isNull);
    });
  });
}
