import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/router/router.dart';
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
///
/// 0.6.0 (log 18–19/11/2026: Xiaomi Android 16 still on the android6 APK of
/// 0.5.9): the one-time toast was easy to miss, so a dialog now offers a
/// button that opens the latest GitHub Release, where the regular APK is
/// listed. The in-app updater (0.5.9 `apk_variant_picker.dart`) already picks
/// the regular APK on Android 7.0+, so the next update also fixes it.
class YomiA6Notice {
  YomiA6Notice._();
  static const _key = 'a6NoticeShownFor';
  static const releasesUrl = 'https://github.com/kiritokmn1403/YomiHub-Project/releases/latest';

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
      final msg = tr('Bạn đang dùng bản APK dành cho Android 6.0 trên Android {p0}. Bản này có thể không chạy được một số tiện ích APK mới – hãy cài bản APK thường (Android 7.0 trở lên) để dùng đủ tính năng.',
          {'p0': v.release});
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        botToast(msg, second: 15);
        return;
      }
      final go = await showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: Text(tr('Nên cài bản APK thường')),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Để sau'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Tải bản APK thường'))),
          ],
        ),
      );
      if (go == true) {
        final ok = await launchUrl(Uri.parse(releasesUrl), mode: LaunchMode.externalApplication);
        if (!ok) AppLogger.log('[Bản cài] Không mở được trang tải $releasesUrl', logLevel: LogLevel.warning);
      }
    } catch (_) {}
  }
}
