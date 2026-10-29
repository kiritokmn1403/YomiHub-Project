import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// YomiHub: Picture-in-Picture (Hình trong hình) settings for the video player.
///
/// The media_kit fork already drives Activity.enterPictureInPictureMode; this
/// class only stores the user's choices so the player can read them
/// synchronously.
class YomiPip {
  YomiPip._();
  static const _boxName = 'yomihub_pip';
  static Box? _box;

  /// Enter PiP automatically when leaving the app while a video plays.
  static bool autoEnter = true;

  /// Show the PiP button in the player's top bar.
  static bool showButton = true;

  /// YomiHub 0.1.9: the system Back key (navigation bar) puts a playing
  /// video in Picture-in-Picture instead of closing the player.
  static bool backToPip = true;

  /// 'auto' = system PiP on Android 8.0+, floating mini player elsewhere
  /// (Android 7.x, Windows); 'mini' = always the in-app floating window.
  static String mode = 'auto';

  static Future<void> open() async {
    try {
      _box ??= await YomiHive.open(_boxName);
      autoEnter = _box!.get('autoEnter', defaultValue: true) as bool;
      showButton = _box!.get('showButton', defaultValue: true) as bool;
      mode = _box!.get('mode', defaultValue: 'auto') as String;
      backToPip = _box!.get('backToPip', defaultValue: true) as bool;
    } catch (_) {}
  }

  static Future<void> set({bool? auto, bool? button, String? pipMode, bool? back}) async {
    if (back != null) backToPip = back;
    if (auto != null) autoEnter = auto;
    if (button != null) showButton = button;
    if (pipMode != null) mode = pipMode;
    try {
      _box ??= await YomiHive.open(_boxName);
      await _box!.put('autoEnter', autoEnter);
      await _box!.put('showButton', showButton);
      await _box!.put('mode', mode);
      await _box!.put('backToPip', backToPip);
    } catch (_) {}
  }
}

class PipSettingsScreen extends StatefulWidget {
  const PipSettingsScreen({super.key});
  @override
  State<PipSettingsScreen> createState() => _PipSettingsScreenState();
}

class _PipSettingsScreenState extends State<PipSettingsScreen> {
  @override
  void initState() {
    super.initState();
    YomiPip.open().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Hình trong hình (PiP)'))),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.keyboard_return),
            title: Text(tr('Bấm Quay lại để thu nhỏ video')),
            subtitle: Text(
              tr('Đang xem video mà bấm phím Quay lại trên thanh điều hướng thì video tự vào Hình trong hình (nút ← trên màn hình vẫn thoát trình phát)'),
            ),
            value: YomiPip.backToPip,
            onChanged: (v) async {
              await YomiPip.set(back: v);
              setState(() {});
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.picture_in_picture_alt_outlined),
            title: Text(tr('Tự vào Hình trong hình')),
            subtitle: Text(
              tr('Đang xem phim mà bấm Home / chuyển app thì video thu nhỏ thành cửa sổ nổi'),
            ),
            value: YomiPip.autoEnter,
            onChanged: (v) async {
              await YomiPip.set(auto: v);
              setState(() {});
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.smart_button_outlined),
            title: Text(tr('Hiện nút PiP trên trình phát')),
            subtitle: Text(tr('Nút ở thanh trên cùng của trình phát video')),
            value: YomiPip.showButton,
            onChanged: (v) async {
              await YomiPip.set(button: v);
              setState(() {});
            },
          ),
          const Divider(),
          RadioGroup<String>(
            groupValue: YomiPip.mode,
            onChanged: (v) async {
              await YomiPip.set(pipMode: v);
              setState(() {});
            },
            child: Column(
              children: [
                RadioListTile(
                  value: 'auto',
                  title: Text(tr('Tự động')),
                  subtitle: Text(
                    tr('Android 8.0+: Hình trong hình của hệ thống (nổi trên mọi ứng dụng). Android 7.x và máy tính: cửa sổ nổi trong YomiHub.'),
                  ),
                ),
                RadioListTile(
                  value: 'mini',
                  title: Text(tr('Luôn dùng cửa sổ nổi trong ứng dụng')),
                  subtitle: Text(
                    tr('Video thu nhỏ thành cửa sổ kéo thả được; vẫn duyệt thư viện, tìm truyện… trong lúc xem'),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(tr('Android 7.x (dưới 8.0)')),
            subtitle: Text(
              tr('Hệ điều hành chưa có Hình trong hình cho điện thoại, nên YomiHub dùng cửa sổ nổi riêng: chạm để hiện nút, chạm đúp để mở lớn, kéo để di chuyển (tự bám cạnh màn hình). Có thể tắt PiP hệ thống riêng cho YomiHub trong Cài đặt Android > Ứng dụng.'),
            ),
          ),
        ],
      ),
    );
  }
}
