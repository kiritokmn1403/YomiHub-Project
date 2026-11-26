// YomiHub 0.6.6 (hotfix Windows 26/11/2026): M-Extension-Server không khởi
// động được trên Windows từ 0.6.5 vì JDK 21 coi -XX:-BytecodeVerificationRemote
// là tuỳ chọn chẩn đoán – thiếu -XX:+UnlockDiagnosticVMOptions (đặt trước) thì
// JVM thoát ngay. Đọc mã nguồn như các test yh_057.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final src = File('lib/yomihub/mes/yomi_mes.dart').readAsStringSync();

  test('cờ mở khoá tuỳ chọn chẩn đoán đứng trước BytecodeVerificationRemote', () {
    final unlock = src.indexOf("'-XX:+UnlockDiagnosticVMOptions'");
    final verify = src.indexOf("'-XX:-BytecodeVerificationRemote'");
    expect(unlock, greaterThan(0));
    expect(verify, greaterThan(unlock));
  });

  test('cả hai cờ nằm trước -jar trong lệnh khởi động Windows', () {
    final start = src.indexOf('static Future<String?> _startWindows()');
    expect(start, greaterThan(0));
    final body = src.substring(start, src.indexOf("'-jar'", start));
    expect(body, contains("'-XX:+UnlockDiagnosticVMOptions'"));
    expect(body, contains("'-XX:-BytecodeVerificationRemote'"));
  });

  test('vẫn tìm máy chủ kèm sẵn trong yomihub_bin\\mes trước bản tự tải', () {
    expect(src, contains("scan(Directory(p.join(WinProc.binDir, 'mes'))) ?? await scan(await _winInstallDir())"));
  });
}
