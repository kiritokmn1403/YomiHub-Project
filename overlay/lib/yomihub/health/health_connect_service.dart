import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.3.0: Dịch vụ tích hợp Health Connect & Chăm sóc sức khỏe số (Digital Wellbeing)
/// Dựa trên chuẩn Android Jetpack Health Connect (androidx.health.connect), HCGateway
/// và react-native-health-connect từ Project GitHub.
///
/// Hỗ trợ:
/// - Theo dõi thời gian đọc truyện và xem phim (Mindful/Rest Screen Time).
/// - Nhắc nhở giải lao bảo vệ mắt theo quy tắc 20-20-20 (nghỉ ngơi sau mỗi chu kỳ đọc/xem liên tục).
/// - Kết nối và đồng bộ dữ liệu thời gian giải trí lành mạnh sang Health Connect trên Android.
/// - Hoạt động độc lập và mượt mà trên cả Android và Windows mà không gây gián đoạn ứng dụng.
class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService instance = HealthConnectService._();

  static const _channel = MethodChannel('com.yomihub/health_connect');

  // Keys lưu cấu hình
  static const _prefEnabled = 'healthConnect_enabled';
  static const _prefAutoSync = 'healthConnect_autoSync';
  static const _prefEyeCareReminder = 'healthConnect_eyeCareReminder';
  static const _prefReminderInterval =
      'healthConnect_reminderInterval'; // tính theo phút
  static const _prefDailyGoalMinutes = 'healthConnect_dailyGoalMinutes';
  static const _prefTodayReadingMinutes = 'healthConnect_todayReadingMinutes';
  static const _prefTodayWatchingMinutes = 'healthConnect_todayWatchingMinutes';
  static const _prefLastRecordedDay = 'healthConnect_lastRecordedDay';

  Timer? _sessionTimer;
  int _continuousMinutes = 0;

  bool get isEnabled => YomiPrefs.get<bool>(_prefEnabled, false);
  set isEnabled(bool v) => YomiPrefs.set(_prefEnabled, v);

  bool get autoSync => YomiPrefs.get<bool>(_prefAutoSync, true);
  set autoSync(bool v) => YomiPrefs.set(_prefAutoSync, v);

  bool get eyeCareReminder => YomiPrefs.get<bool>(_prefEyeCareReminder, true);
  set eyeCareReminder(bool v) => YomiPrefs.set(_prefEyeCareReminder, v);

  int get reminderIntervalMinutes =>
      YomiPrefs.get<int>(_prefReminderInterval, 30);
  set reminderIntervalMinutes(int v) => YomiPrefs.set(_prefReminderInterval, v);

  int get dailyGoalMinutes => YomiPrefs.get<int>(_prefDailyGoalMinutes, 120);
  set dailyGoalMinutes(int v) => YomiPrefs.set(_prefDailyGoalMinutes, v);

  int get todayReadingMinutes {
    _checkDayRollover();
    return YomiPrefs.get<int>(_prefTodayReadingMinutes, 0);
  }

  int get todayWatchingMinutes {
    _checkDayRollover();
    return YomiPrefs.get<int>(_prefTodayWatchingMinutes, 0);
  }

  int get totalTodayMinutes => todayReadingMinutes + todayWatchingMinutes;

  void _checkDayRollover() {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final savedDay = YomiPrefs.get<String>(_prefLastRecordedDay, '');
    if (savedDay != todayKey) {
      YomiPrefs.set(_prefLastRecordedDay, todayKey);
      YomiPrefs.set(_prefTodayReadingMinutes, 0);
      YomiPrefs.set(_prefTodayWatchingMinutes, 0);
    }
  }

  /// Ghi nhận thêm phút đọc truyện
  void recordReadingMinutes(int minutes) {
    if (minutes <= 0) return;
    _checkDayRollover();
    final cur = YomiPrefs.get<int>(_prefTodayReadingMinutes, 0);
    YomiPrefs.set(_prefTodayReadingMinutes, cur + minutes);
    _onActivityTime(minutes);
  }

  /// Ghi nhận thêm phút xem anime/phim
  void recordWatchingMinutes(int minutes) {
    if (minutes <= 0) return;
    _checkDayRollover();
    final cur = YomiPrefs.get<int>(_prefTodayWatchingMinutes, 0);
    YomiPrefs.set(_prefTodayWatchingMinutes, cur + minutes);
    _onActivityTime(minutes);
  }

  void _onActivityTime(int addedMinutes) {
    _continuousMinutes += addedMinutes;
    if (eyeCareReminder && _continuousMinutes >= reminderIntervalMinutes) {
      _continuousMinutes = 0;
      AppLogger.log(
        '[Health Connect] Nhắc nhở bảo vệ mắt: Bạn đã đọc/xem liên tục ${reminderIntervalMinutes} phút. Hãy nghỉ ngơi nhìn xa 20 giây!',
        logLevel: LogLevel.info,
      );
    }
    if (isEnabled && autoSync && Platform.isAndroid) {
      syncToAndroidHealthConnect(addedMinutes);
    }
  }

  /// Bắt đầu đếm phiên xem/đọc liên tục
  void startContinuousSession({required VoidCallback onEyeCareAlert}) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _continuousMinutes++;
      if (eyeCareReminder && _continuousMinutes >= reminderIntervalMinutes) {
        _continuousMinutes = 0;
        onEyeCareAlert();
      }
    });
  }

  /// Dừng phiên
  void stopContinuousSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _continuousMinutes = 0;
  }

  /// Kiểm tra trạng thái cài đặt Health Connect trên Android
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isAvailable');
      return res ?? false;
    } catch (error) {
      AppLogger.logOnce(
        'hc_availability_err',
        '[Health Connect] Cannot verify native integration: $error',
        logLevel: LogLevel.error,
      );
      return false;
    }
  }

  /// 0.4.4: chi tiết khả năng của thiết bị (Android): available, canWrite,
  /// granted, platformApi, sdk.
  Future<Map<String, dynamic>> status() async {
    if (!Platform.isAndroid) return const {};
    try {
      return Map<String, dynamic>.from(await _channel.invokeMethod('status') as Map);
    } catch (e) {
      AppLogger.logOnce('hc_status_err', '[Health Connect] Không đọc được trạng thái: $e', logLevel: LogLevel.error);
      return const {};
    }
  }

  /// 0.4.4: xin quyền ghi phiên "Chánh niệm" (Android 14+). true = đã có quyền.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (e) {
      AppLogger.log('[Health Connect] Không xin được quyền ghi: $e', logLevel: LogLevel.error);
      return false;
    }
  }

  /// Mở cài đặt hệ thống Health Connect
  Future<void> openHealthConnectSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openSettings');
        return;
      } catch (_) {}
      // Thử mở qua Intent trực tiếp hoặc Google Play
      final uri = Uri.parse(
        'market://details?id=com.google.android.apps.healthdata',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
      final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Đồng bộ phiên thư giãn/nghỉ ngơi sang Health Connect
  Future<bool> syncToAndroidHealthConnect(int minutes) async {
    if (!Platform.isAndroid || !isEnabled) return false;
    try {
      final res = await _channel.invokeMethod<bool>('syncSession', {
        'minutes': minutes,
        'type': 'MindfulSession',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return res ?? false;
    } catch (e) {
      // Ghi log nhẹ nhàng không làm crash ứng dụng
      // 0.4.4: real errors (permission, unsupported device) go to the
      // application log as warnings, once per run.
      final msg = e is PlatformException ? (e.message ?? e.code) : '$e';
      AppLogger.logOnce(
        'hc_sync_err',
        '[Health Connect] Chưa đồng bộ được phiên với hệ điều hành: $msg',
        logLevel: LogLevel.warning,
      );
      return false;
    }
  }
}
