import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:mangayomi/yomihub/perf/perf_watchdog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YomiHub 0.4.3', () {
    test('AppIdentity reports a 0.4.x version', () {
      // 0.4.4: the exact version is checked in yh_044_test.dart
      expect(AppIdentity.userAgent, startsWith('YomiHub/0.4.'));
    });

    test('Hand-picked merge groups are recognised by their key prefix', () {
      expect(YomiMerge.isCustom('${YomiMerge.customPrefix}0|123'), isTrue);
      expect(YomiMerge.isCustom('0|hentaicube.xyz'), isFalse);
    });

    test('Merge groups are empty and safe while preferences are closed', () {
      expect(YomiMerge.groups, isEmpty);
      expect(YomiMerge.groupOf(1), isNull);
      expect(YomiMerge.hiddenSecondaries(), isEmpty);
    });

    test('isMangaMerged is cached and false without stored origins', () {
      for (var i = 0; i < 1000; i++) {
        expect(ChapterOrigins.isMangaMerged(i), isFalse);
      }
    });

    test('DNS helper returns IP literals without a lookup', () async {
      expect(await yomiSystemThenDoh('127.0.0.1'), ['127.0.0.1']);
    });

    test('DNS helper completes a real lookup (regression: self-awaiting future)', () async {
      // Two concurrent lookups share one in-flight future; both must finish.
      final r = await Future.wait([
        yomiSystemThenDoh('localhost'),
        yomiSystemThenDoh('localhost'),
      ]).timeout(const Duration(seconds: 20));
      expect(r.length, 2);
      // A later call after the in-flight entry is cleared must also finish.
      await yomiSystemThenDoh('localhost').timeout(const Duration(seconds: 20));
    });

    test('URL sanitizer still repairs a missing slash after the TLD', () {
      expect(
        YomiUrlOverride.sanitizeUrl('https://mimihentai.net24403/48522'),
        'https://mimihentai.net/24403/48522',
      );
    });

    test('Freeze watchdog activity labels can be set and cleared', () {
      YomiPerf.activity('test');
      YomiPerf.activityDone('test');
      YomiPerf.activityDone('other');
    });
  });
}
