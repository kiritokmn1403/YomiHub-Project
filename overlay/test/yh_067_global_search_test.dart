import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/browse/global_search/global_search_screen.dart';

void main() {
  group('0.6.7 FetchGate không vượt giới hạn (log 17 dòng 644–702)', () {
    test('lượt mới không chen vào slot vừa trao cho lượt chờ', () async {
      final g = FetchGate(2);
      var running = 0, peak = 0;
      Future<void> job(Duration d) async {
        await g.acquire();
        running++;
        if (running > peak) peak = running;
        await Future<void>.delayed(d);
        running--;
        g.release();
      }

      final all = <Future<void>>[];
      for (var i = 0; i < 12; i++) {
        all.add(job(Duration(milliseconds: 5 + (i % 3) * 3)));
        // xen kẽ lượt mới ngay lúc lượt cũ đang nhả slot
        if (i.isEven) await Future<void>.delayed(const Duration(milliseconds: 4));
      }
      await Future.wait(all);
      expect(peak, lessThanOrEqualTo(2));
      expect(g.activeForTest, 0);
    });

    test('release thừa không làm bộ đếm âm', () {
      final g = FetchGate(3);
      g.release();
      expect(g.activeForTest, 0);
    });
  });

  group('0.6.7 nhớ nguồn chết DNS trong tìm kiếm toàn cục', () {
    setUp(GlobalSearchDeadSources.clear);

    test('chỉ nhớ lỗi DNS, hết hạn sau 10 phút', () {
      final t0 = DateTime(2026, 11, 26, 22);
      GlobalSearchDeadSources.record(1, 'Kotatsu: Unable to resolve host "nettruyen1905.com"', now: t0);
      GlobalSearchDeadSources.record(2, 'TimeoutException after 0:01:30', now: t0);
      expect(GlobalSearchDeadSources.cached(1, now: t0.add(const Duration(minutes: 5))), contains('nettruyen1905'));
      expect(GlobalSearchDeadSources.cached(2, now: t0), isNull, reason: 'timeout không phải DNS – vẫn thử lại');
      expect(GlobalSearchDeadSources.cached(1, now: t0.add(const Duration(minutes: 11))), isNull);
    });

    test('nhận diện thông điệp DNS của các engine', () {
      for (final e in [
        'Unable to resolve host "kagane.to" (system DNS and DNS-over-HTTPS)',
        'ClientException with SocketException: Failed host lookup: \'api.github.com\'',
        'tcp: Failed to resolve hostname cdn7.x.asia: No address associated with hostname',
      ]) {
        expect(GlobalSearchDeadSources.isDnsFailure(e), isTrue, reason: e);
      }
      expect(GlobalSearchDeadSources.isDnsFailure('HTTP error 404'), isFalse);
    });
  });
}
