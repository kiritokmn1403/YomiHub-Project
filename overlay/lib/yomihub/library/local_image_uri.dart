import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// YomiHub 0.6.7 (log 17, dòng 946/1015/1029 – 0.6.5 trên Android 16):
/// ảnh bìa người dùng chọn từ bộ nhớ máy (`content://com.android.
/// externalstorage.documents/...`) bị bộ tải ảnh mạng gửi đi như một URL HTTP
/// → luôn lỗi "Máy chủ com.android.externalstorage.documents từ chối" và kéo
/// cả cảnh báo lặp mỗi phút. Ảnh cục bộ (`content://`, `file://`) được đọc
/// thẳng từ máy: `file://` bằng dart:io, `content://` qua ContentResolver
/// (kênh `com.yomihub/tools` › `readUri`, chạy trên hàng đợi nền).

/// Giới hạn một ảnh bìa đọc từ máy (tránh đọc nhầm tệp video lớn vào RAM).
const int kLocalImageMaxBytes = 32 << 20;

/// Có phải URI ảnh nằm trên máy (không đi mạng) không.
bool isLocalImageUri(String url) {
  final u = url.trimLeft().toLowerCase();
  return u.startsWith('content://') || u.startsWith('file://');
}

/// Đọc ảnh cục bộ. Ném [StateError] với lý do tiếng Việt khi không đọc được
/// (mất quyền truy cập thư mục, tệp đã xoá, nền tảng không hỗ trợ).
Future<Uint8List> readLocalImageUri(
  String url, {
  MethodChannel channel = const MethodChannel('com.yomihub/tools'),
  bool? isAndroid,
}) async {
  final s = url.trim();
  if (s.toLowerCase().startsWith('file://')) {
    final bytes = BytesBuilder(copy: false);
    try {
      final file = File.fromUri(Uri.parse(s));
      await for (final chunk in file.openRead(0, kLocalImageMaxBytes + 1)) {
        bytes.add(chunk);
      }
    } on FileSystemException {
      throw StateError('Không đọc được ảnh từ bộ nhớ máy.');
    }
    if (bytes.length > kLocalImageMaxBytes) {
      throw StateError('Ảnh cục bộ vượt giới hạn kích thước.');
    }
    if (bytes.length == 0) throw StateError('Ảnh cục bộ rỗng.');
    return bytes.takeBytes();
  }
  if (!(isAndroid ?? Platform.isAndroid)) {
    throw StateError('URI content:// chỉ đọc được trên Android.');
  }
  final Uint8List? b;
  try {
    b = await channel.invokeMethod<Uint8List>('readUri', {
      'uri': s,
      'max': kLocalImageMaxBytes,
    });
  } on PlatformException {
    throw StateError('Không đọc được ảnh từ bộ nhớ máy – có thể ứng dụng đã mất quyền truy cập.');
  }
  if (b == null || b.isEmpty) {
    throw StateError('Ảnh cục bộ rỗng hoặc không còn tồn tại.');
  }
  return b;
}
