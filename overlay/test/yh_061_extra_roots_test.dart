import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/net/extra_roots.dart';

void main() {
  test('YomiHub 0.6.1: 4 gốc Let\'s Encrypt hợp lệ, nạp được vào SecurityContext', () {
    expect(YomiExtraRoots.pems.keys, containsAll(['root-ye', 'root-yr', 'isrg-root-x2', 'isrgrootx1']));
    for (final p in YomiExtraRoots.pems.values) {
      expect(p.trim().startsWith('-----BEGIN CERTIFICATE-----'), isTrue);
      expect(p.trim().endsWith('-----END CERTIFICATE-----'), isTrue);
    }
    final ctx = SecurityContext(withTrustedRoots: false);
    YomiExtraRoots.install(ctx);
    // gọi lại lần hai không ném lỗi
    YomiExtraRoots.install(ctx);
  });
}
