import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.2.2: every failed transfer in "AirDrop & Quicksharing"
/// (Wi-Fi/LAN, Quick Share, Bluetooth) is written to the app log
/// (Cài đặt › Giới thiệu › Nhật ký ứng dụng).
class YomiShareLog {
  YomiShareLog._();

  /// 0.5.7 (P5b): non-fatal problem (no device found, permission denied,
  /// swallowed error) -> WARNING, one line, no token.
  static void warn(String channel, String message, {Object? error}) {
    AppLogger.log(
      '[AirDrop & Quick Share] $channel – $message${error != null ? ' • lỗi: $error' : ''}',
      logLevel: LogLevel.warning,
    );
  }

  static void error(
    String channel,
    String action, {
    String? target,
    Object? error,
    List<String>? files,
    int? sent,
  }) {
    final names = files == null
        ? ''
        : ' • tệp: ${files.take(5).map((f) => f.split(RegExp(r'[\\/]')).last).join(', ')}'
            '${files.length > 5 ? ' (+${files.length - 5})' : ''}';
    final count = sent != null && files != null ? ' • đã gửi $sent/${files.length}' : '';
    AppLogger.log(
      '[AirDrop & Quick Share] $channel – $action thất bại'
      '${target != null ? ' • tới: $target' : ''}$count$names'
      '${error != null ? ' • lỗi: $error' : ''}',
      logLevel: LogLevel.error,
    );
  }
}
