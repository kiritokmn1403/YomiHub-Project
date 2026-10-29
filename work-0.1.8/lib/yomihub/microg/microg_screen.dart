import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.1.5: Settings › microG.
///
/// microG (GmsCore, Companion/FakeStore, DroidGuard, UnifiedNlp) replaces
/// Google Play Services at the system level: it must be installed as its own
/// apps and needs signature spoofing, so it cannot run *inside* another app.
/// This screen brings every microG setting into YomiHub instead: it detects
/// the installed components, opens each microG settings page directly
/// (account, cloud messaging, SafetyNet/Play Integrity, location, Exposure
/// notifications, self-check) and links to the official downloads.
class MicroGScreen extends StatefulWidget {
  const MicroGScreen({super.key});

  @override
  State<MicroGScreen> createState() => _MicroGScreenState();
}

class _MicroGScreenState extends State<MicroGScreen> {
  static const _ch = MethodChannel('com.yomihub/tools');
  Map<String, dynamic>? _st;
  bool _loading = true;

  static const _gms = 'com.google.android.gms';

  /// microG settings pages (activity names inside GmsCore). Only the ones
  /// present in the installed GmsCore are shown.
  static const _pages = <(String, String, IconData, String)>[
    ('org.microg.gms.ui.SettingsActivity', 'Cài đặt microG', Icons.settings, 'Trang cài đặt chính của microG'),
    ('org.microg.gms.ui.SelfCheckActivity', 'Tự kiểm tra hệ thống', Icons.fact_check_outlined, 'Signature spoofing, quyền, tối ưu pin…'),
    ('org.microg.gms.ui.AccountsActivity', 'Tài khoản Google', Icons.account_circle_outlined, 'Đăng nhập / quản lý tài khoản Google qua microG'),
    ('org.microg.gms.ui.GcmFragment', 'Cloud Messaging (thông báo đẩy)', Icons.notifications_active_outlined, 'Đăng ký thiết bị nhận thông báo đẩy'),
    ('org.microg.gms.ui.SafetyNetFragment', 'SafetyNet / Play Integrity', Icons.verified_user_outlined, 'Chứng thực thiết bị cho ứng dụng cần'),
    ('org.microg.gms.ui.LocationSettingsActivity', 'Vị trí', Icons.location_on_outlined, 'Nguồn vị trí (Mozilla/BeaconDB, Wi-Fi, trạm phát)'),
    ('org.microg.gms.ui.ExposureNotificationsActivity', 'Thông báo phơi nhiễm', Icons.coronavirus_outlined, 'Exposure Notifications API'),
    ('org.microg.gms.ui.DeviceRegistrationFragment', 'Đăng ký thiết bị Google', Icons.phone_android, 'Device registration'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _ch.invokeMethod('microgStatus');
      _st = Map<String, dynamic>.from(r as Map);
    } catch (_) {
      _st = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic>? _pkg(String k) {
    final v = _st?[k];
    return v == null ? null : Map<String, dynamic>.from(v as Map);
  }

  Future<void> _open(String cls) async {
    final ok = await _ch.invokeMethod<bool>('openComponent', {
      'package': _gms,
      'class': cls,
    });
    if (ok != true) {
      // older/newer microG builds rename activities: fall back to main page
      final ok2 = await _ch.invokeMethod<bool>('openComponent', {
        'package': _gms,
        'class': 'org.microg.gms.ui.SettingsActivity',
      });
      if (ok2 != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được trang này của microG')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('microG')),
        body: const Center(child: Text('microG chỉ có trên Android.')),
      );
    }
    final gms = _pkg('gms');
    final isMicroG = gms?['microg'] == true;
    final acts = ((gms?['activities'] as List?) ?? const []).cast<String>().toSet();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('microG'),
        actions: [
          IconButton(
            tooltip: 'Kiểm tra lại',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: Icon(
                      isMicroG
                          ? Icons.check_circle
                          : gms != null
                          ? Icons.info_outline
                          : Icons.cancel_outlined,
                      color: isMicroG
                          ? Colors.green
                          : gms != null
                          ? Colors.blue
                          : Colors.orange,
                    ),
                    title: Text(
                      isMicroG
                          ? 'Đang dùng microG ${gms!['version']}'
                          : gms != null
                          ? 'Đang dùng Google Play Services gốc'
                          : 'Chưa cài microG / Google Play Services',
                    ),
                    subtitle: Text(
                      isMicroG
                          ? (_st?['signatureSpoofing'] == true
                                ? 'Signature spoofing: đã cấp'
                                : 'Signature spoofing: chưa cấp hoặc ROM tự xử lý (xem Tự kiểm tra)')
                          : 'YomiHub không bắt buộc Google Play Services. Cài microG nếu máy không có Google.',
                    ),
                  ),
                ),
                _component('GmsCore (microG Services)', 'gms'),
                _component('Companion / FakeStore (Play Store)', 'vending'),
                _component('Google Services Framework proxy', 'gsf'),
                _component('DroidGuard Helper', 'droidguard'),
                _component('UnifiedNlp backend (vị trí)', 'nlpBackend'),
                const Divider(),
                if (isMicroG) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Cài đặt microG',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final p in _pages)
                    if (acts.isEmpty || acts.contains(p.$1) || p.$1.endsWith('SettingsActivity'))
                      ListTile(
                        leading: Icon(p.$3),
                        title: Text(p.$2),
                        subtitle: Text(p.$4),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => _open(p.$1),
                      ),
                  ListTile(
                    leading: const Icon(Icons.battery_saver_outlined),
                    title: const Text('Thông tin ứng dụng microG'),
                    subtitle: const Text('Quyền, tối ưu pin (nên tắt để nhận thông báo đẩy)'),
                    onTap: () => _ch.invokeMethod('openAppInfo', {'package': _gms}),
                  ),
                  const Divider(),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Tải microG',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                _link(Icons.download, 'Trang tải chính thức', 'https://microg.org/download.html'),
                _link(Icons.store_mall_directory_outlined, 'Kho F-Droid của microG', 'https://microg.org/fdroid.html'),
                _link(Icons.code, 'Mã nguồn (GitHub)', 'https://github.com/microg/GmsCore'),
                _link(Icons.help_outline, 'Hướng dẫn cài đặt', 'https://github.com/microg/GmsCore/wiki/Installation'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'microG thay thế Google Play Services ở cấp hệ thống (cần ROM hỗ trợ signature spoofing hoặc bản '
                    'cài qua Magisk/LSPosed), nên không thể nhúng vào trong một ứng dụng thường. YomiHub gom mọi cài đặt '
                    'của microG vào đây. Các tính năng của YomiHub (quét QR, sao lưu Google Drive qua OAuth, trình phát, '
                    'tiện ích) đều chạy được dù máy dùng microG hay không có Google.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _component(String name, String key) {
    final p = _pkg(key);
    return ListTile(
      dense: true,
      leading: Icon(
        p == null ? Icons.remove_circle_outline : Icons.check_circle_outline,
        color: p == null ? null : Colors.green,
      ),
      title: Text(name),
      subtitle: Text(
        p == null
            ? 'Chưa cài'
            : '${p['package']} • ${p['version']}${p['microg'] == true ? ' • microG' : ''}${p['enabled'] == false ? ' • đang tắt' : ''}',
      ),
      onTap: p == null
          ? null
          : () => _ch.invokeMethod('openAppInfo', {'package': p['package']}),
    );
  }

  Widget _link(IconData i, String t, String url) => ListTile(
    leading: Icon(i),
    title: Text(t),
    subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );
}
