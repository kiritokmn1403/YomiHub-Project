// YomiHub 0.6.6 – kiểm thử cho các bản vá V8/V9/V12/V13/V14 (ALL_066.diff).
// Chạy từ thư mục overlay/ (đường dẫn lib/...), như yh_057_p5b_test.dart.
// Đọc mã nguồn thay vì import: updates_preload.dart kéo theo main.dart (Isar),
// và _safeName là hàm riêng tư của cloud_backup_service.dart.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String _read(String path) => File(path).readAsStringSync();

/// Khối bắt đầu tại [start]; dấu '{' mở khối là lần xuất hiện đầu tiên của
/// [open] sau [start] (tránh nhầm với '{' của tham số có tên).
String _block(String src, String start, {String open = '{'}) {
  final i = src.indexOf(start);
  expect(i, greaterThanOrEqualTo(0), reason: 'không thấy "$start"');
  final o = src.indexOf(open, i);
  expect(o, greaterThanOrEqualTo(0), reason: 'không thấy "$open" sau "$start"');
  final brace = o + open.lastIndexOf('{');
  var depth = 0;
  for (var k = brace; k < src.length; k++) {
    if (src[k] == '{') depth++;
    if (src[k] == '}' && --depth == 0) return src.substring(i, k + 1);
  }
  fail('khối "$start" không đóng');
}

// Bản sao logic _safeName của V9 (cùng biểu thức với cloud_backup_service.dart);
// test bên dưới kiểm tra mã nguồn thật vẫn khớp biểu thức này.
String _safeName(String name) {
  final base = p.basename(name.replaceAll('\\', '/'));
  return base.isEmpty || base == '.' || base == '..' ? 'yomihub_download.backup' : base;
}

int _utf8Len(String s) => utf8.encode(s).length;

void main() {
  final cloud = _read('lib/yomihub/cloud/cloud_backup_service.dart');
  final preload = _read('lib/yomihub/perf/updates_preload.dart');
  final qr = _read('lib/yomihub/qr/qr_screen.dart');

  group('V9 – tên tệp từ máy chủ không thoát khỏi thư mục đích', () {
    test('mã nguồn dùng đúng biểu thức _safeName', () {
      final fn = _block(cloud, 'String _safeName(');
      expect(fn, contains("name.replaceAll('\\\\', '/')"));
      expect(fn, contains('p.basename('));
      expect(fn, contains("'yomihub_download.backup'"));
    });
    test('hành vi', () {
      expect(_safeName('../../etc/passwd'), 'passwd');
      expect(_safeName(r'..\..\evil.exe'), 'evil.exe');
      expect(_safeName('a/b/c.backup'), 'c.backup');
      expect(_safeName('ok.yomihub'), 'ok.yomihub');
      expect(_safeName(''), 'yomihub_download.backup');
      expect(_safeName('..'), 'yomihub_download.backup');
      expect(_safeName('dir/..'), 'yomihub_download.backup');
    });
    test('mọi download() đều qua _safeName, không còn p.join(..., f.name)', () {
      expect(RegExp(r'p\.join\(into\.path,\s*(f|file)\.name\)').hasMatch(cloud), isFalse);
      expect(RegExp(r'_safeName\((f|file)\.name\)').allMatches(cloud).length, greaterThanOrEqualTo(7));
    });
  });

  group('V8 – Drive resumable upload: 308', () {
    final up = _block(cloud, 'class GoogleDriveProvider');
    test('không có Range => tiếp tục từ 0, không nhảy tới end', () {
      expect(up, contains('range == null ? 0 :'));
      expect(up, isNot(contains('range == null ? end :')));
    });
    test('3 lần 308 liên tiếp không tiến triển thì ném lỗi', () {
      expect(up, contains('var stalls = 0;'));
      expect(up, contains('stalls = next <= pos ? stalls + 1 : 0;'));
      expect(up, contains('if (stalls >= 3) throw Exception('));
    });
    test('mô phỏng vòng lặp: có tiến triển thì không đếm stall', () {
      int run(List<String?> ranges, int total) {
        var pos = 0, stalls = 0, i = 0;
        while (pos < total) {
          final range = i < ranges.length ? ranges[i++] : null;
          final next = range == null ? 0 : int.parse(range.split('-').last) + 1;
          stalls = next <= pos ? stalls + 1 : 0;
          if (stalls >= 3) throw Exception('stall');
          pos = next;
        }
        return pos;
      }
      expect(run(['0-99', '0-199', '0-299'], 300), 300);
      expect(() => run([null, null, null], 300), throwsException);
      expect(() => run(['0-99', '0-99', '0-99', '0-99'], 300), throwsException);
    });
  });

  group('V12 – yomiSwitchMap', () {
    final sw = _block(preload, 'Stream<R> yomiSwitchMap<T, R>(', open: 'map) {');
    test('đóng luồng ra khi nguồn và luồng trong đều xong', () {
      expect(sw, contains('var outerDone = false;'));
      expect(sw, contains('outerDone = true;'));
      expect(sw, contains('if (inner == null) c.close();'));
      expect(sw, contains('if (outerDone) c.close();'));
    });
    test('map() ném lỗi => addError', () {
      expect(sw, contains('} catch (e, st) {'));
      expect(sw, contains('c.addError(e, st);'));
    });
    test('tạm dừng được kế thừa bởi luồng trong mới', () {
      expect(sw, contains('final paused = c.isPaused;'));
      expect(sw, contains('if (paused) sub.pause();'));
    });
    test('onCancel luôn huỷ luồng ngoài dù huỷ luồng trong lỗi', () {
      final cancel = sw.substring(sw.indexOf('onCancel'));
      expect(cancel, contains('finally'));
      expect(cancel, contains('await outer?.cancel();'));
    });
  });

  group('V13 – kUpdateMangaCache chỉ nhận lượt preload mới nhất', () {
    test('có bộ đếm thế hệ và chỉ ghi cache khi còn là mới nhất', () {
      expect(preload, contains('int _cacheGen = 0;'));
      final fn = _block(preload, 'Future<List<Update>> preloadUpdateChapters(', open: ') async {');
      expect(fn, contains('final gen = ++_cacheGen;'));
      final i = fn.indexOf('if (gen == _cacheGen)');
      expect(i, greaterThanOrEqualTo(0));
      expect(fn.indexOf('kUpdateMangaCache', i), greaterThan(i));
      expect(RegExp(r'kUpdateMangaCache\s*\.\.clear').allMatches(fn).length, 1);
    });
  });

  group('V14 – giới hạn mã QR tính theo byte UTF-8', () {
    test('dùng utf8.encode(data).length > 2331 thay cho data.length > 2900', () {
      expect(qr, contains("import 'dart:convert';"));
      expect(qr, contains('utf8.encode(data).length > 2331'));
      expect(qr, isNot(contains('data.length > 2900')));
      expect(qr, contains('tối đa ~2.300 byte'));
    });
    test('biên 2331 byte (ASCII và chữ 3 byte)', () {
      bool tooLong(String s) => _utf8Len(s) > 2331;
      expect(tooLong('a' * 2331), isFalse);
      expect(tooLong('a' * 2332), isTrue);
      expect(tooLong('ệ' * 777), isFalse);
      expect(tooLong('ệ' * 778), isTrue);
    });
  });
}
