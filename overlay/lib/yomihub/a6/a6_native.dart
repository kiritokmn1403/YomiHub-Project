// YomiHub 0.5.7 (P7F, U10): thư viện gốc mở bằng dart:ffi trên Android 6.
//
// Android 6 (API 23) chưa có linker namespace: thư mục lib của app chỉ nằm
// trong LD_LIBRARY_PATH của tiến trình vì `Runtime.doLoad()` gọi
// `android_update_LD_LIBRARY_PATH(<đường dẫn của ClassLoader đang nạp>)` ở MỖI
// lần `System.loadLibrary`. Khi một lớp của framework/WebView (ClassLoader
// khác) nạp thư viện của nó, đường dẫn này bị ghi đè và mọi
// `DynamicLibrary.open('libxxx.so')` bằng tên trần sau đó báo
// `dlopen failed: library "libxxx.so" not found` dù tệp có trong lib/<abi>.
// libisar/librust được mở ngay lúc khởi động nên không sao; libqjs.so
// (tiện ích JavaScript) và libsubsampling_scale_image_view.so (trang truyện)
// mở trễ nên hỏng. Cách sửa: mở bằng đường dẫn tuyệt đối (thư mục chứa
// libapp.so, đọc từ /proc/self/maps – dùng được trong mọi isolate) và nạp
// trước libqjs.so lúc khởi động (linker tìm lại thư viện đã nạp theo SONAME).
// Chỉ có hiệu lực trong APK android6 (`kIsA6Build`).
import 'dart:ffi';
import 'dart:io';

import 'package:mangayomi/utils/platform_utils.dart';

/// Thư mục chứa libapp.so / libflutter.so theo nội dung /proc/self/maps.
String? yhA6LibDirFromMaps(Iterable<String> lines) {
  String? flutterDir;
  for (final l in lines) {
    final i = l.indexOf('/');
    if (i < 0) continue;
    final path = l.substring(i).trim();
    final cut = path.lastIndexOf('/');
    if (cut <= 0) continue;
    if (path.endsWith('/libapp.so')) return path.substring(0, cut);
    if (path.endsWith('/libflutter.so')) flutterDir ??= path.substring(0, cut);
  }
  return flutterDir;
}

String? _dir;
bool _dirDone = false;

String? yhA6NativeLibDir() {
  if (_dirDone) return _dir;
  _dirDone = true;
  try {
    _dir = yhA6LibDirFromMaps(File('/proc/self/maps').readAsLinesSync());
  } catch (_) {}
  return _dir;
}

/// Mở một thư viện gốc đóng gói trong APK. Bản android6: thử đường dẫn tuyệt
/// đối trước; mọi bản khác (và khi không tìm được thư mục): tên trần như cũ.
DynamicLibrary yhOpenAndroidLib(String name) {
  if (kIsA6Build && Platform.isAndroid) {
    final d = yhA6NativeLibDir();
    if (d != null) {
      try {
        return DynamicLibrary.open('$d/$name');
      } catch (_) {}
    }
  }
  return DynamicLibrary.open(name);
}

final List<DynamicLibrary> _keep = [];

/// Gọi một lần ở main(): nạp trước các thư viện mà gói bên ngoài mở bằng tên
/// trần (flutter_qjs → 'libqjs.so').
void yhA6PreloadNative() {
  if (!kIsA6Build || !Platform.isAndroid) return;
  final d = yhA6NativeLibDir();
  final done = <String>[];
  for (final n in const ['libqjs.so', 'libsubsampling_scale_image_view.so']) {
    try {
      if (d == null) throw StateError('khong tim thay thu muc lib');
      _keep.add(DynamicLibrary.open('$d/$n'));
      done.add(n);
    } catch (e) {
      // ignore: avoid_print
      print('[YomiA6Native] KHONG nap truoc duoc $n: $e');
    }
  }
  // ignore: avoid_print
  print('[YomiA6Native] thu muc lib = $d; da nap truoc: ${done.join(', ')}');
}

int _diagLeft = 60;

/// Nhật ký chẩn đoán chỉ có trong APK android6 (logcat, tối đa 60 dòng/phiên).
void yhA6Diag(String message) {
  if (!kIsA6Build || _diagLeft <= 0) return;
  _diagLeft--;
  // ignore: avoid_print
  print('[YomiA6Diag] $message');
}
