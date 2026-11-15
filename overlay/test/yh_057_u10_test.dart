// YomiHub 0.5.7 – P7F (U10): APK android6 mở thư viện gốc bằng đường dẫn
// tuyệt đối (Android 6 làm mất thư mục lib của app khỏi LD_LIBRARY_PATH).
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/a6/a6_native.dart';

void main() {
  group('U10 – a6_native', () {
    test('lib dir is taken from the libapp.so mapping', () {
      const maps = [
        '12c00000-12e07000 rw-p 00000000 00:04 7347 /dev/ashmem/dalvik-main space (deleted)',
        '7f1c6a9e8000-7f1c6b6e1000 r-xp 00000000 fd:00 1234 /data/app/com.yomihub.app-1/lib/x86_64/libflutter.so',
        '7f1c60000000-7f1c62000000 r--p 00000000 fd:00 1235 /data/app/com.yomihub.app-1/lib/x86_64/libapp.so',
        '7f1c7a000000-7f1c7a001000 r-xp 00000000 fd:00 99   /system/lib64/libc.so',
      ];
      expect(yhA6LibDirFromMaps(maps), '/data/app/com.yomihub.app-1/lib/x86_64');
    });

    test('libapp.so wins over a relinked libflutter.so, libflutter is the fallback', () {
      expect(
        yhA6LibDirFromMaps(const [
          '1-2 r-xp 0 fd:00 1 /data/data/com.yomihub.app/app_lib/libflutter.so',
          '3-4 r--p 0 fd:00 2 /data/app/com.yomihub.app-2/lib/arm64/libapp.so',
        ]),
        '/data/app/com.yomihub.app-2/lib/arm64',
      );
      expect(
        yhA6LibDirFromMaps(const ['1-2 r-xp 0 fd:00 1 /data/app/x-1/lib/arm/libflutter.so']),
        '/data/app/x-1/lib/arm',
      );
    });

    test('no mapping (libs kept inside the APK) gives null', () {
      expect(
        yhA6LibDirFromMaps(const [
          '1-2 r-xp 0 fd:00 1 /data/app/x-1/base.apk',
          '3-4 rw-p 0 00:00 0 [heap]',
          '',
        ]),
        isNull,
      );
    });

    test('the main APK never takes the android6 path', () {
      expect(kIsA6Build, isFalse);
      // Không ném lỗi và không in gì ở bản thường.
      yhA6PreloadNative();
      yhA6Diag('khong in');
    });
  });
}
