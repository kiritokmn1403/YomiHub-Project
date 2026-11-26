import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/utils/image_load_timeout.dart';

void main() {
  group('0.6.7 ImageHostBreaker (cdn.donmai.us 239 lần/phút)', () {
    late DateTime now;
    late ImageHostBreaker b;
    setUp(() {
      now = DateTime(2026, 11, 26, 21, 40);
      b = ImageHostBreaker(clock: () => now);
    });

    test('ngắt sau 8 lần lỗi liên tiếp, không ngắt ở lần 7', () {
      for (var i = 0; i < 7; i++) {
        expect(b.fail('cdn.donmai.us'), isFalse);
      }
      expect(b.blockedFor('cdn.donmai.us'), isNull);
      expect(b.fail('cdn.donmai.us'), isTrue);
      expect(b.blockedFor('cdn.donmai.us'), isNotNull);
      expect(b.blockedFor('CDN.DONMAI.US'), isNotNull, reason: 'không phân biệt hoa thường');
      expect(b.blockedFor('i.hinhgg.com'), isNull, reason: 'host khác không bị ảnh hưởng');
    });

    test('thành công gỡ chuỗi lỗi', () {
      for (var i = 0; i < 7; i++) {
        b.fail('a.com');
      }
      b.success('a.com');
      expect(b.fail('a.com'), isFalse);
    });

    test('lỗi rải rác quá cửa sổ 60 s không ngắt', () {
      for (var i = 0; i < 10; i++) {
        expect(b.fail('a.com'), isFalse);
        now = now.add(const Duration(seconds: 61));
      }
    });

    test('hết 30 s cho 1 lượt thử; lỗi tiếp là ngắt lại ngay', () {
      for (var i = 0; i < 8; i++) {
        b.fail('a.com');
      }
      now = now.add(const Duration(seconds: 31));
      expect(b.blockedFor('a.com'), isNull);
      expect(b.fail('a.com'), isTrue);
      expect(b.blockedFor('a.com'), isNotNull);
    });

    test('cổng nội bộ 127.0.0.1 không bao giờ bị ngắt', () {
      for (var i = 0; i < 20; i++) {
        expect(b.fail('127.0.0.1'), isFalse);
      }
      expect(b.blockedFor('127.0.0.1'), isNull);
    });
    test('Codex G1 Cao: lỗi muộn của yêu cầu đang bay không đóng khoảng ngắt', () {
      for (var i = 0; i < 8; i++) {
        b.fail('a.com');
      }
      expect(b.blockedFor('a.com'), isNotNull);
      expect(b.fail('a.com'), isFalse);
      b.success('a.com');
      expect(b.blockedFor('a.com'), isNotNull, reason: 'vẫn ngắt sau lỗi/thành công muộn');
      now = now.add(const Duration(seconds: 31));
      expect(b.blockedFor('a.com'), isNull);
      b.success('a.com');
      expect(b.fail('a.com'), isFalse, reason: 'thử lại thành công thì đếm lại từ đầu');
    });

    test('chỉ lỗi máy chủ/kết nối mới tính (404 là lỗi của riêng ảnh)', () {
      expect(ImageHostBreaker.countsAsHostFailure(null), isTrue);
      expect(ImageHostBreaker.countsAsHostFailure(403), isTrue);
      expect(ImageHostBreaker.countsAsHostFailure(429), isTrue);
      expect(ImageHostBreaker.countsAsHostFailure(503), isTrue);
      expect(ImageHostBreaker.countsAsHostFailure(404), isFalse);
      expect(ImageHostBreaker.countsAsHostFailure(410), isFalse);
    });
  });
}
