// YomiHub 0.5.7 – gói P5b: FC24/FC32 chia sẻ, FC42 Telegram, FC40 Booru, tải xuống.
// Mọi nhánh lỗi phải ghi vào Nhật Ký Ứng Dụng; không lộ token.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/booru/booru_api.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';

String _read(String p) => File(p).readAsStringSync();

void main() {
  group('Telegram', () {
    test('maskToken che token và mẫu bot<id>:<khóa>', () {
      const tok = '123456:ABCdefGHIjklMNOpqrSTUvwxYZ0123456789';
      final m = TelegramProvider.maskToken('GET https://api.telegram.org/bot$tok/getMe failed', tok);
      expect(m.contains(tok), isFalse);
      expect(m, contains('<token>'));
      final m2 = TelegramProvider.maskToken('x bot999999:ABCdefGHIjklMNOpqrSTUvwxYZ0123 y', '');
      expect(m2, contains('bot<token>'));
    });
    test('partName xếp theo tên và mang số mảnh', () {
      expect(TelegramProvider.partName('b.yomihub', 1, 5), 'b.yomihub.part02of05');
      expect(TelegramProvider.partSize, 19 * 1024 * 1024);
    });
    test('nhánh lỗi Telegram có ghi log và log đi qua _mask', () {
      final s = _read('lib/yomihub/cloud/cloud_backup_service.dart');
      final t = s.substring(s.indexOf('class TelegramProvider'), s.indexOf('class CloudUploadResult'));
      expect(t, contains('kết nối thất bại: \${_mask(e)}'));
      expect(t, contains('không đọc được danh sách tệp từ bot'));
      expect(t, contains('lịch sử sao lưu đã lưu bị hỏng'));
      expect(t, contains('tải "\${file.name}" thất bại'));
      expect(t, contains('không đủ dung lượng'));
      // không có log nào in $e thô (rò token)
      for (final m in RegExp(r"AppLogger\.log\('\[Đồng bộ đám mây\] Telegram[^;]*;").allMatches(t)) {
        expect(m.group(0)!.contains(r'$e'), isFalse, reason: m.group(0));
      }
    });
  });

  group('Booru', () {
    final site = BooruSite.builtIn.first;
    test('JSON hỏng thành BooruException(format), không văng FormatException', () {
      final s = _read('lib/yomihub/booru/booru_api.dart');
      expect(s, contains('on FormatException catch'));
      expect(s, contains('BooruError.format'));
    });
    test('parsePosts bỏ qua dữ liệu lạ', () {
      expect(BooruApi.parsePosts(site, <dynamic>[]), isEmpty);
      expect(BooruApi.parsePosts(site, {'posts': <dynamic>[]}), isEmpty);
    });
    test('viewer ghi log khi mở/chia sẻ lỗi', () {
      final s = _read('lib/yomihub/booru/booru_viewer.dart');
      expect(s, contains('Không mở được bài'));
      expect(s, contains('Không chia sẻ được bài'));
    });
  });

  group('AirDrop & Quick Share', () {
    test('share_log có warn(); lan_share chỉ còn catch rỗng ở dọn phản hồi HTTP', () {
      expect(_read('lib/yomihub/share/share_log.dart'), contains('static void warn('));
      final s = _read('lib/yomihub/share/lan_share.dart');
      expect(RegExp(r'catch \(_\) \{\}').allMatches(s).length, lessThanOrEqualTo(2));
      expect(s, contains('Không tìm thấy thiết bị YomiHub nào'));
      expect(s, contains('mã liên kết sai/hết hạn'));
    });
    test('nhận tệp: xoá tệp dở và kiểm dung lượng', () {
      final s = _read('lib/yomihub/share/lan_share.dart');
      expect(s, contains('tệp nhận không đủ dung lượng'));
      expect(s, contains('partial.delete()'));
    });
    test('Bluetooth: từ chối quyền và bật thất bại được ghi log', () {
      final s = _read('lib/yomihub/share/bluetooth_share.dart');
      expect(s, contains('Quyền Bluetooth/thiết bị lân cận bị từ chối'));
      expect(s, contains('Bluetooth vẫn tắt sau 15 giây'));
      expect(s, contains('Đọc danh sách thiết bị đã ghép đôi'));
    });
    test('share_screen: bật nhận lỗi được ghi log', () {
      final s = _read('lib/yomihub/share/share_screen.dart');
      expect(s, contains("'Bật chế độ nhận để chia sẻ tệp'"));
    });
  });

  group('Tải xuống', () {
    test('Wi-Fi only và hàng chờ có log', () {
      final s = _read('lib/modules/manga/download/providers/download_provider.dart');
      expect(s, contains('chỉ tải qua Wi-Fi'));
      expect(s, contains('Không đọc được chương trong hàng chờ'));
      expect(s, contains('markDownloadFailed(chapter, startFailure'));
    });
  });
}
