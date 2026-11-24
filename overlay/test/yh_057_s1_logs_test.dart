// 0.5.7 (S1): log categorizer for extension errors, image-failure burst
// aggregation, update-source retry (never throws, one retry).
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/utils/log/log_rate_limiter.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/update/multi_source_update.dart';

void main() {
  group('classifyMessage', () {
    test('extension "Bad state: No element" is a source error, not an app error', () {
      final m = AppLogger.classifyMessage(
        'Extension "NHentai" (en, engine: dart, repo: kegareta-sauces <https://x/index.json>) search Seijo: Bad state: No element',
        LogLevel.error,
      );
      expect(m, startsWith('[Lỗi Nguồn] '));
      expect(m, isNot(contains('[Lỗi Ứng Dụng]')));
    });

    test('extension messages keep the 404 / network categories', () {
      expect(
        AppLogger.classifyMessage('Extension "A" (vi, engine: mihon) getDetail /x: HTTP error 404', LogLevel.error),
        startsWith('[Lỗi Nguồn 404]'),
      );
      expect(
        AppLogger.classifyMessage('Extension "A" (en, engine: mihon) search q: connection closed', LogLevel.warning),
        startsWith('[Lỗi Mạng'), // 0.6.5: "[Lỗi Mạng]" unless Tor is involved
      );
    });

    test('real app errors are still app errors', () {
      expect(AppLogger.classifyMessage('FlutterError: Bad state: x', LogLevel.error), startsWith('[Lỗi Ứng Dụng]'));
      expect(AppLogger.classifyMessage('Null check operator used on a null value', LogLevel.error), startsWith('[Lỗi Ứng Dụng]'));
    });
  });

  group('LogBurstAggregator', () {
    test('first line at once, the rest counted per host in one summary', () {
      final out = <String>[];
      final a = LogBurstAggregator(
        emit: out.add,
        summary: (n, h, t) => 'SUM $n/$h: $t',
        useTimer: false,
      );
      final t0 = DateTime(2026, 11, 14, 10);
      a.record('a.com', 'first', now: t0);
      for (var i = 0; i < 9; i++) {
        a.record(i < 6 ? 'a.com' : 'b.com', 'x$i', now: t0.add(Duration(seconds: i)));
      }
      expect(out, ['first']);
      expect(a.suppressed, 9);
      a.flush();
      expect(out.length, 2);
      expect(out[1], 'SUM 9/2: a.com ×6, b.com ×3');
    });

    test('a new window after 1 minute flushes the summary then logs again', () {
      final out = <String>[];
      final a = LogBurstAggregator(emit: out.add, summary: (n, h, t) => 'SUM $n', useTimer: false);
      final t0 = DateTime(2026, 11, 14, 10);
      a.record('a.com', 'one', now: t0);
      a.record('a.com', 'two', now: t0.add(const Duration(seconds: 5)));
      a.record('c.com', 'three', now: t0.add(const Duration(seconds: 61)));
      expect(out, ['one', 'SUM 1', 'three']);
    });

    test('164 events over 20 minutes make far fewer lines', () {
      final out = <String>[];
      final a = LogBurstAggregator(emit: out.add, summary: (n, h, t) => 'SUM $n', useTimer: false);
      final t0 = DateTime(2026, 11, 14, 10);
      for (var i = 0; i < 164; i++) {
        a.record('h${i % 9}.com', 'e$i', now: t0.add(Duration(seconds: i * 7)));
      }
      a.flush();
      expect(out.length, lessThan(40));
      final counted = out.where((l) => l.startsWith('SUM ')).fold<int>(0, (s, l) => s + int.parse(l.substring(4)));
      final first = out.where((l) => !l.startsWith('SUM ')).length;
      expect(counted + first, 164); // nothing lost
    });
  });

  group('update sources', () {
    final ok = ('9.9.9', 'n', 'link', <dynamic>['https://x/YomiHub.apk']);

    test('one failure then success: result returned, no error recorded', () async {
      var n = 0;
      final errors = <String>[];
      final r = await YomiUpdateSources.runSourceForTest('MediaFire k', () async {
        if (n++ == 0) throw Exception('Software caused connection abort');
        return ok;
      }, '0.5.6', errors);
      expect(r, isNotNull);
      expect(n, 2);
      expect(errors, isEmpty);
    });

    test('two failures: null, error recorded, never throws', () async {
      var n = 0;
      final errors = <String>[];
      final r = await YomiUpdateSources.runSourceForTest('Drive k', () async {
        n++;
        throw Exception('boom');
      }, '0.5.6', errors);
      expect(r, isNull);
      expect(n, 2);
      expect(errors.length, 1);
    });

    test('a hanging source times out and does not hang the caller', () async {
      final errors = <String>[];
      final sw = Stopwatch()..start();
      final r = await YomiUpdateSources.runSourceForTest(
        'Drive slow',
        () => Future.delayed(const Duration(hours: 1), () => ok),
        '0.5.6',
        errors,
      );
      expect(r, isNull);
      expect(sw.elapsedMilliseconds, lessThan(2000));
      expect(errors.length, 1);
    });

    test('an older / equal version is not an update', () async {
      final r = await YomiUpdateSources.runSourceForTest('GitHub', () async => ok, '9.9.9', <String>[]);
      expect(r, isNull);
    });

    test('all 8 sources of the "Website Update Apps" sheet are configured', () {
      expect(YomiUpdateSources.githubRepo, 'YomiHub-Project/YomiHub-Project'); // 0.6.5
      expect(YomiUpdateSources.legacyGithubRepo, 'kiritokmn1403/YomiHub-Project');
      expect(YomiUpdateSources.driveFolders.length, 3);
      expect(YomiUpdateSources.mediafireFolders.length, 3);
    });
  });
}
