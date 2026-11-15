// YomiHub 0.5.7 – lỗi còn lại trong logs 7 (12–14/11/2026) chưa được xử lý ở đợt 1:
// Kavita "OPDS URL required" (ERROR + stack), HTTP 530 / "HTTP 0" của nguồn đã
// chết, tiện ích "(Ngừng hoạt động)", Aidoku "SourceError", "MiMi"
// (kotlinx.serialization: abstract method … typeParametersSerializers) và bản
// APK Android 6.0 chạy trên máy Android 7.0+.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/a6/a6_notice.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/scanner/web_scanner.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('logs 7 – phân loại lỗi tiện ích', () {
    test('Kavita without a server is "needs setup", not an app error', () {
      const kavita = 'OPDS URL required\nPlease configure your Kavita server connection \n\n\nstatusCode: 500';
      expect(YomiExtErrors.isSetupError(kavita), isTrue);
      expect(YomiExtErrors.short(kavita), 'OPDS URL required\nPlease configure your Kavita server connection');
      expect(YomiExtErrors.isSetupError('HTTP error 404'), isFalse);
      expect(YomiExtErrors.isSetupError('Bad state: No element'), isFalse);
    });

    test('HTTP 530 / "HTTP 0" are site problems with a hint', () {
      for (final e in [
        'HTTP error 530 \n\n\nstatusCode: 530',
        'Error: HTTP 530 https://phimnhua.online/\n    at check (<eval>:26:5048)',
        'Error: HTTP 0 https://www.rophim.soy/\n    at check (<eval>:26:4797)',
        'HTTP error 522',
        'Kotatsu: . Status=522, URL=[https://tcbscans-manga.com/wp-admin/admin-ajax.php]',
      ]) {
        expect(YomiExtErrors.isNetworkError(e), isTrue, reason: e);
      }
      expect(YomiExtErrors.hint('HTTP error 530'), isNotNull);
      for (final e in [
        'HTTP error 404',
        'Error: Kotatsu: . Status=500, URL=[https://cuutruyen.moe/tim-kiem?page=1]',
        'Bad state: No element',
        'Error: HTTP 404 https://example.org/530',
      ]) {
        expect(YomiExtErrors.isNetworkError(e), isFalse, reason: e);
      }
    });

    test('MiMi: an extension that needs a newer runner is recognised', () {
      const mimi =
          'abstract method "kotlinx.serialization.KSerializer[] kotlinx.serialization.internal.GeneratedSerializer.typeParametersSerializers()" on receiver java.lang.Class<r0> \n\n\nstatusCode: 500';
      expect(YomiExtErrors.isIncompatible(mimi), isTrue);
      expect(YomiExtErrors.isIncompatible('java.lang.NoClassDefFoundError: kotlinx/serialization/protobuf/ProtoNumber'), isTrue);
      expect(YomiExtErrors.isIncompatible('HTTP error 404'), isFalse);
      expect(YomiExtErrors.isIncompatible('Refresh the chapter list.'), isFalse);
      expect(YomiExtErrors.incompatibleHint(), contains('Android 6.0'));
    });

    test('answers the extension cannot read are source errors (no stack)', () {
      for (final e in [
        'SourceError: missing result',
        'SourceError: JSON parse error',
        'Error: Kotatsu: CSRF token not found\n    at call (<eval>:25:59)',
        'Error: Kotatsu: No value for img\n    at call (<eval>:25:59)',
        'Error: Kotatsu: End of input at character 0 of \n    at call (<eval>:25:59)',
        'Error: Kotatsu: Method Not Allowed. Status=405, URL=[https://vivicomi8.info/wp-admin/admin-ajax.php]',
      ]) {
        expect(YomiExtErrors.isSourceDataError(e), isTrue, reason: e);
      }
      for (final e in [
        'Bad state: No element',
        'Null check operator used on a null value',
        "FormatException: Unexpected character (at character 1)",
        'RangeError (index): Invalid value: Valid value range is empty: 0',
      ]) {
        expect(YomiExtErrors.isSourceDataError(e), isFalse, reason: e);
      }
    });

    test('extensions the repository marks as discontinued are noted once', () {
      expect(YomiExtErrors.isDiscontinued('Phim Nhựa (Ngừng hoạt động)'), isTrue);
      expect(YomiExtErrors.isDiscontinued('AVSub – AnimeVietsub (Ngừng hoạt động)'), isTrue);
      expect(YomiExtErrors.isDiscontinued('AVSub – AnimeVietsub'), isFalse);
      expect(YomiExtErrors.isDiscontinued(null), isFalse);
      expect(YomiExtErrors.noteDiscontinuedOnce('Rổ Phim (Ngừng hoạt động)', 'vi'), isTrue);
      expect(YomiExtErrors.noteDiscontinuedOnce('Rổ Phim (Ngừng hoạt động)', 'vi'), isFalse);
      expect(YomiExtErrors.noteDiscontinuedOnce('Rổ Phim (Ngừng hoạt động)', 'en'), isTrue);
    });

    test('isolate_service uses the new classes before the ERROR + stack fallback', () {
      final s = _read('lib/services/isolate_service.dart');
      final order = [
        'YomiExtErrors.isDiscontinued(source?.name)',
        'YomiExtErrors.isSetupError(e)',
        'YomiExtErrors.isNetworkError(e)',
        'YomiExtErrors.isIncompatible(e)',
        'sourceerror: missing result|bad state: no element',
        'YomiExtErrors.isSourceDataError(e)',
        r"timeout ? '$where: ${YomiExtErrors.short(e)}' : '$where: $e\n$st'",
      ];
      var at = -1;
      for (final o in order) {
        final i = s.indexOf(o, at + 1);
        expect(i, greaterThan(at), reason: o);
        at = i;
      }
    });
  });

  group('bản APK Android 6.0 trên máy Android 7.0+', () {
    test('only the android6 build on API 24+ gets the notice, once per version', () {
      expect(YomiA6Notice.applies(a6Build: true, sdkInt: 23), isFalse);
      expect(YomiA6Notice.applies(a6Build: true, sdkInt: 24), isTrue);
      expect(YomiA6Notice.applies(a6Build: true, sdkInt: 36), isTrue);
      expect(YomiA6Notice.applies(a6Build: false, sdkInt: 36), isFalse);
      expect(YomiA6Notice.shouldToast(shownFor: '', version: 'YomiHub/0.5.7'), isTrue);
      expect(YomiA6Notice.shouldToast(shownFor: 'YomiHub/0.5.7', version: 'YomiHub/0.5.7'), isFalse);
      expect(YomiA6Notice.shouldToast(shownFor: 'YomiHub/0.5.6.1', version: 'YomiHub/0.5.7'), isTrue);
    });

    test('flag and start-up hook exist', () {
      expect(_read('lib/utils/platform_utils.dart'), contains("bool.fromEnvironment('IS_A6_BUILD'"));
      expect(_read('lib/main.dart'), contains('YomiA6Notice.check'));
    });
  });

  group('Feature Check 32 – Web Scanner ghi Nhật Ký Ứng Dụng', () {
    test('a failed scan becomes one warning line', () {
      final line = YomiWebScanner.scanFailureLine(
          'https://x.example', 'không tải được trang', 'SocketException: Failed host lookup\n#0 stack');
      expect(line, '[Web Scanner] Quét https://x.example thất bại – không tải được trang: SocketException: Failed host lookup');
      final src = _read('lib/yomihub/scanner/web_scanner.dart');
      expect(src, contains("logScanFailure(url, 'chứng chỉ HTTPS không hợp lệ', e);"));
      expect(src, contains("logScanFailure(url, 'không tải được trang', e);"));
    });
  });
}
