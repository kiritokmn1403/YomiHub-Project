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

  /// 'auto' = system PiP on Android 8.0+, floating mini player elsewhere
  /// (Android 7.x, Windows); 'mini' = always the in-app floating window.
  static String mode = 'auto';

  static Future<void> open() async {
    try {
      _box ??= await Hive.openBox(_boxName);
      autoEnter = _box!.get('autoEnter', defaultValue: true) as bool;
      showButton = _box!.get('showButton', defaultValue: true) as bool;
      mode = _box!.get('mode', defaultValue: 'auto') as String;
    } catch (_) {}
  }

  static Future<void> set({bool? auto, bool? button, String? pipMode}) async {
    if (auto != null) autoEnter = auto;
    if (button != null) showButton = button;
    if (pipMode != null) mode = pipMode;
    try {
      _box ??= await Hive.openBox(_boxName);
      await _box!.put('autoEnter', autoEnter);
      await _box!.put('showButton', showButton);
      await _box!.put('mode', mode);
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
      appBar: AppBar(title: const Text('Hình trong hình (PiP)')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.picture_in_picture_alt_outlined),
            title: const Text('Tự vào Hình trong hình'),
            subtitle: const Text(
              'Đang xem phim mà bấm Home / chuyển app thì video thu nhỏ thành cửa sổ nổi',
            ),
            value: YomiPip.autoEnter,
            onChanged: (v) async {
              await YomiPip.set(auto: v);
              setState(() {});
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.smart_button_outlined),
            title: const Text('Hiện nút PiP trên trình phát'),
            subtitle: const Text('Nút ở thanh trên cùng của trình phát video'),
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
            child: const Column(
              children: [
                RadioListTile(
                  value: 'auto',
                  title: Text('Tự động'),
                  subtitle: Text(
                    'Android 8.0+: Hình trong hình của hệ thống (nổi trên mọi ứng dụng). '
                    'Android 7.x và máy tính: cửa sổ nổi trong YomiHub.',
                  ),
                ),
                RadioListTile(
                  value: 'mini',
                  title: Text('Luôn dùng cửa sổ nổi trong ứng dụng'),
                  subtitle: Text(
                    'Video thu nhỏ thành cửa sổ kéo thả được; vẫn duyệt thư viện, tìm truyện… trong lúc xem',
                  ),
                ),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Android 7.x (dưới 8.0)'),
            subtitle: Text(
              'Hệ điều hành chưa có Hình trong hình cho điện thoại, nên YomiHub dùng cửa sổ nổi riêng: '
              'chạm để hiện nút, chạm đúp để mở lớn, kéo để di chuyển (tự bám cạnh màn hình). '
              'Có thể tắt PiP hệ thống riêng cho YomiHub trong Cài đặt Android > Ứng dụng.',
            ),
          ),
        ],
      ),
    );
  }
}
