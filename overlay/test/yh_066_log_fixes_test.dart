// YomiHub 0.6.6 – fixes for logs 16 (YH 0.6.4/0.6.5 on Windows 26H2,
// 23–25/11/2026) and the owner's screenshot of 25/11 21:35.
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/lnreader/service.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';

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
}
