import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.5.7 – the separate Android 6.0 APK installed on a newer phone.
///
/// logs 7 (13–14/11/2026) came from the `android6` APK running on an
/// Android 7.0+ phone (build id of `build23`). That APK exists only for
/// Android 6.0: its libraries are built for API 23, where interfaces cannot
/// carry default methods, so newer Mihon extension APKs fail in it ("MiMi":
/// `abstract method … GeneratedSerializer.typeParametersSerializers()`).
/// The regular APK has none of these limits, so the app says so once per
/// version and writes one warning line per start.
class YomiA6Notice {
  YomiA6Notice._();
  static const _key = 'a6NoticeShownFor';

  /// Android 7.0 (API 24) and later can run the regular APK.
  static bool applies({required bool a6Build, required int sdkInt}) => a6Build && sdkInt >= 24;

  /// The toast is shown once per app version ([shownFor] = stored value).
  static bool shouldToast({required String shownFor, required String version}) => shownFor != version;

  static Future<void> check() async {
    if (!kIsA6Build || !Platform.isAndroid) return;
    try {
      final v = (await DeviceInfoPlugin().androidInfo).version;
      if (!applies(a6Build: kIsA6Build, sdkInt: v.sdkInt)) return;
      AppLogger.log(
        '[Bản cài] Đang chạy bản APK dành cho Android 6.0 trên Android ${v.release} (SDK ${v.sdkInt}). '
        'Bản này có thể không chạy được một số tiện ích APK mới; hãy cài bản APK thường (Android 7.0 trở lên).',
        logLevel: LogLevel.warning,
      );
      const version = AppIdentity.userAgent;
      if (!YomiPrefs.isOpen || !shouldToast(shownFor: YomiPrefs.get<String>(_key, ''), version: version)) return;
      await YomiPrefs.set(_key, version);
      botToast(
        tr('Bạn đang dùng bản APK dành cho Android 6.0 trên Android {p0}. Bản này có thể không chạy được một số tiện ích APK mới – hãy cài bản APK thường (Android 7.0 trở lên) để dùng đủ tính năng.',
            {'p0': v.release}),
        second: 15,
      );
    } catch (_) {}
  }
}
