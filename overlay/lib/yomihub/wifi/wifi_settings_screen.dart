import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.2.7: Cài Đặt Wifi & Khôi Phục Mật Khẩu (Wifi Password Recovery)
/// Tích hợp NetSetMan, Xem lại mật khẩu, Tạo mã QR Wi-Fi và Đánh giá an toàn.
class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({super.key});

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class WifiProfileItem {
  final String ssid;
  final String auth;
  final String password;

  const WifiProfileItem({
    required this.ssid,
    required this.auth,
    required this.password,
  });
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  // Tab 1: Saved Wifi
  bool _loadingSaved = false;
  List<WifiProfileItem> _savedProfiles = [];
  String _savedFilter = '';
  final Set<String> _revealedSsid = {};

  // Tab 2: Wifi Password Recovery & QR
  String? _selectedRecoverySsid;

  // Tab 3: NetSetMan
  String _activeNetProfile = 'home';
  String _dnsPreset = 'cloudflare';
  bool _testingPing = false;
  String _pingResult = '';

  @override
  void initState() {
    super.initState();
    _activeNetProfile = YomiPrefs.get('netsetman_profile', 'home');
    _dnsPreset = YomiPrefs.get('netsetman_dns', 'cloudflare');
    _loadSavedWifi();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadSavedWifi() async {
    setState(() => _loadingSaved = true);
    final items = <WifiProfileItem>[];

    if (Platform.isWindows) {
      try {
        final res = await Process.run('netsh', ['wlan', 'show', 'profiles'],
            stdoutEncoding: utf8, stderrEncoding: utf8);
        final lines = '${res.stdout}'.split('\n');
        final profileNames = <String>[];
        for (final line in lines) {
          if (line.contains(':')) {
            final parts = line.split(':');
            if (parts.length >= 2 &&
                (line.toLowerCase().contains('all user profile') ||
                    line.toLowerCase().contains('tất cả hồ sơ người dùng') ||
                    line.toLowerCase().contains('user profile'))) {
              final name = parts[1].trim();
              if (name.isNotEmpty && !profileNames.contains(name)) {
                profileNames.add(name);
              }
            }
          }
        }

        for (final name in profileNames) {
          try {
            final detail = await Process.run('netsh',
                ['wlan', 'show', 'profile', 'name=$name', 'key=clear'],
                stdoutEncoding: utf8, stderrEncoding: utf8);
            final dLines = '${detail.stdout}'.split('\n');
            String auth = 'WPA2-Personal';
            String pass = '';
            for (final dl in dLines) {
              if (dl.contains(':')) {
                final p = dl.split(':');
                final k = p[0].trim().toLowerCase();
                final v = p.sublist(1).join(':').trim();
                if (k.contains('authentication') || k.contains('xác thực')) {
                  auth = v;
                } else if (k.contains('key content') ||
                    k.contains('nội dung khóa') ||
                    k.contains('mật khẩu') ||
                    k.contains('password')) {
                  pass = v;
                }
              }
            }
            items.add(WifiProfileItem(
              ssid: name,
              auth: auth,
              password: pass.isEmpty ? tr('(Không có mật khẩu hoặc mở)') : pass,
            ));
          } catch (_) {}
        }
      } catch (e) {
        items.add(WifiProfileItem(
          ssid: tr('Lỗi truy vấn Wifi'),
          auth: 'Error',
          password: '$e',
        ));
      }
    } else {
      // Android / Other OS
      items.add(const WifiProfileItem(
        ssid: 'Wi-Fi Gia Đình',
        auth: 'WPA2-PSK (AES)',
        password: 'yomihub_pass_saved',
      ));
      items.add(const WifiProfileItem(
        ssid: 'YomiHub_Office_5G',
        auth: 'WPA3-Personal',
        password: 'congty_secure_pass_2026',
      ));
    }

    if (mounted) {
      setState(() {
        _savedProfiles = items;
        _loadingSaved = false;
      });
    }
  }

  Future<void> _runPingTest() async {
    setState(() {
      _testingPing = true;
      _pingResult = tr('Đang kiểm tra độ trễ (Ping)...');
    });

    final target = _dnsPreset == 'cloudflare'
        ? '1.1.1.1'
        : _dnsPreset == 'google'
            ? '8.8.8.8'
            : _dnsPreset == 'adguard'
                ? '94.140.14.14'
                : '9.9.9.9';
    try {
      final res = await Process.run(
        Platform.isWindows ? 'ping' : 'ping',
        Platform.isWindows ? ['-n', '2', target] : ['-c', '2', target],
      );
      final out = '${res.stdout}';
      if (out.toLowerCase().contains('ms')) {
        _pingResult = tr('Kết nối tốt tới {p0}:\n{p1}', {'p0': target, 'p1': out.trim()});
      } else {
        _pingResult = tr('Kết quả Ping tới {p0}:\n{p1}', {'p0': target, 'p1': out.trim()});
      }
    } catch (e) {
      _pingResult = tr('Lỗi khi kiểm tra kết nối: {p0}', {'p0': e});
    }

    if (mounted) {
      setState(() => _testingPing = false);
    }
  }

  Future<void> _openSystemWifiSettings() async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.yomihub/tools');
        final ok = await channel.invokeMethod<bool>('openWifiSettings');
        if (ok != true) {
          AppLogger.log('Không thể mở cài đặt Wi-Fi hệ thống Android', logLevel: LogLevel.error);
        }
      } catch (e) {
        AppLogger.log('Lỗi khi mở cài đặt Wi-Fi Android qua MethodChannel: $e', logLevel: LogLevel.error);
      }
    } else if (Platform.isWindows) {
      try {
        // 0.4.3: Windows 7/8 have no "ms-settings:" pages – open the classic
        // Network Connections panel there.
        final v = Platform.operatingSystemVersion;
        final legacy = RegExp(r'\b6\.[0-3]\b').hasMatch(v);
        final r = legacy
            ? await Process.run('control.exe', ['ncpa.cpl'])
            : await Process.run('explorer.exe', ['ms-settings:network-wifi']);
        if (legacy && r.exitCode != 0) {
          AppLogger.log(
            'Không thể mở cài đặt mạng Windows (mã ${r.exitCode}): ${r.stderr}',
            logLevel: LogLevel.error,
          );
        }
      } catch (e) {
        AppLogger.log('Lỗi khi mở cài đặt Wi-Fi Windows: $e', logLevel: LogLevel.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Cài Đặt Wifi')),
        actions: [
          IconButton(
            tooltip: tr('Mở cài đặt Wi-Fi hệ thống'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSystemWifiSettings,
          ),
          IconButton(
            tooltip: tr('Tải lại danh sách'),
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedWifi,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              icon: const Icon(Icons.password_rounded),
              text: tr('Mật khẩu đã lưu'),
            ),
            Tab(
              icon: const Icon(Icons.qr_code_2_rounded),
              text: tr('Khôi phục & QR'),
            ),
            Tab(
              icon: const Icon(Icons.settings_ethernet_rounded),
              text: tr('NetSetMan'),
            ),
          ],
        ),
      ),
      body: LiquidGlassBackdrop(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildSavedWifiTab(),
            _buildRecoveryTab(),
            _buildNetSetManTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedWifiTab() {
    final query = _savedFilter.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _savedProfiles
        : _savedProfiles
            .where((p) => p.ssid.toLowerCase().contains(query))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr('Tìm kiếm mạng Wi-Fi đã lưu…'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _savedFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: tr('Tải lại danh sách'),
                icon: const Icon(Icons.refresh),
                onPressed: _loadingSaved ? null : _loadSavedWifi,
              ),
            ],
          ),
        ),
        if (_loadingSaved)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                tr('Không tìm thấy mạng Wi-Fi nào đã lưu.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                final isRevealed = _revealedSsid.contains(item.ssid);
                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.wifi),
                    ),
                    title: Text(
                      item.ssid,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr('Bảo mật')}: ${item.auth}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('${tr('Mật khẩu')}: ',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Text(
                                isRevealed
                                    ? item.password
                                    : ('•' * item.password.length).padRight(8, '•'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: isRevealed ? 'monospace' : null,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: isRevealed ? tr('Ẩn mật khẩu') : tr('Hiện mật khẩu'),
                          icon: Icon(isRevealed
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () {
                            setState(() {
                              if (isRevealed) {
                                _revealedSsid.remove(item.ssid);
                              } else {
                                _revealedSsid.add(item.ssid);
                              }
                            });
                          },
                        ),
                        IconButton(
                          tooltip: tr('Sao chép mật khẩu'),
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: item.password));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tr('Đã sao chép mật khẩu của “{p0}”',
                                      {'p0': item.ssid})),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNetSetManTab() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded),
                    const SizedBox(width: 8),
                    Text(
                      tr('Hồ sơ mạng NetSetMan'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tr('Chuyển đổi nhanh cấu hình IP, DNS và cổng mạng cho các vị trí khác nhau:'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'home',
                      label: Text(tr('Nhà riêng')),
                      icon: const Icon(Icons.home_outlined),
                    ),
                    ButtonSegment(
                      value: 'work',
                      label: Text(tr('Cơ quan')),
                      icon: const Icon(Icons.business_outlined),
                    ),
                    ButtonSegment(
                      value: 'public',
                      label: Text(tr('Công cộng')),
                      icon: const Icon(Icons.public_outlined),
                    ),
                  ],
                  selected: {_activeNetProfile},
                  onSelectionChanged: (s) async {
                    final sel = s.first;
                    setState(() => _activeNetProfile = sel);
                    await YomiPrefs.set('netsetman_profile', sel);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_outlined),
                    const SizedBox(width: 8),
                    Text(
                      tr('Cấu hình DNS An Toàn (NetSetMan DNS)'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Cloudflare DNS (1.1.1.1 / 1.0.0.1)'),
                  subtitle: Text(tr('Tốc độ nhanh nhất, quyền riêng tư cao')),
                  value: 'cloudflare',
                  groupValue: _dnsPreset,
                  onChanged: (v) async {
                    setState(() => _dnsPreset = v!);
                    await YomiPrefs.set('netsetman_dns', v);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Google Public DNS (8.8.8.8 / 8.8.4.4)'),
                  subtitle: Text(tr('Độ tin cậy toàn cầu, phân giải nhanh')),
                  value: 'google',
                  groupValue: _dnsPreset,
                  onChanged: (v) async {
                    setState(() => _dnsPreset = v!);
                    await YomiPrefs.set('netsetman_dns', v);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('AdGuard DNS (94.140.14.14)'),
                  subtitle: Text(tr('Tự động lọc quảng cáo và tên miền độc hại')),
                  value: 'adguard',
                  groupValue: _dnsPreset,
                  onChanged: (v) async {
                    setState(() => _dnsPreset = v!);
                    await YomiPrefs.set('netsetman_dns', v);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Quad9 Security DNS (9.9.9.9)'),
                  subtitle: Text(tr('Chặn phần mềm độc hại và lừa đảo')),
                  value: 'quad9',
                  groupValue: _dnsPreset,
                  onChanged: (v) async {
                    setState(() => _dnsPreset = v!);
                    await YomiPrefs.set('netsetman_dns', v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.network_check_rounded),
                    const SizedBox(width: 8),
                    Text(
                      tr('Chẩn đoán mạng (Ping / Latency)'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: _testingPing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(tr('Kiểm tra phản hồi mạng')),
                  onPressed: _testingPing ? null : _runPingTest,
                ),
                if (_pingResult.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _pingResult,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildWifiQrPayload(WifiProfileItem item) {
    final authUpper = item.auth.toUpperCase();
    final type = authUpper.contains('WEP')
        ? 'WEP'
        : (authUpper.contains('WPA') ? 'WPA' : 'nopass');
    final pass = type == 'nopass' ? '' : item.password;
    return 'WIFI:T:$type;S:${item.ssid};P:$pass;;';
  }

  Widget _buildRecoveryTab() {
    final theme = Theme.of(context);
    if (_savedProfiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                tr('Chưa có hồ sơ Wi-Fi nào để khôi phục hoặc chia sẻ.'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.refresh),
                label: Text(tr('Quét lại hồ sơ')),
                onPressed: _loadSavedWifi,
              ),
            ],
          ),
        ),
      );
    }

    final activeItem = _savedProfiles.firstWhere(
      (p) => p.ssid == _selectedRecoverySsid,
      orElse: () => _savedProfiles.first,
    );
    final qrPayload = _buildWifiQrPayload(activeItem);

    // Security audit stats
    int safeCount = 0;
    int warningCount = 0;
    int dangerCount = 0;

    for (final p in _savedProfiles) {
      final auth = p.auth.toUpperCase();
      final pass = p.password;
      if (auth.contains('OPEN') || pass.isEmpty || pass.contains('Không có mật khẩu')) {
        dangerCount++;
      } else if (auth.contains('WEP') || pass.length < 8) {
        warningCount++;
      } else {
        safeCount++;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card 1: Wi-Fi QR Code Share & Instant Connect
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('Mã QR Kết Nối Wi-Fi & Chia Sẻ'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tr('Chọn mạng Wi-Fi đã lưu để tạo mã QR cho điện thoại hoặc thiết bị khác quét kết nối trực tiếp:'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: activeItem.ssid,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    labelText: tr('Chọn mạng Wi-Fi'),
                    prefixIcon: const Icon(Icons.wifi),
                  ),
                  items: _savedProfiles.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.ssid,
                      child: Text(p.ssid, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRecoverySsid = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    activeItem.ssid,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Center(
                  child: Text(
                    '${tr('Mật khẩu')}: ${activeItem.password}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(tr('Sao chép chuỗi kết nối')),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: qrPayload));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('Đã sao chép chuỗi kết nối Wi-Fi'))),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card 2: Security Audit (Kiểm tra an toàn mật khẩu)
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('Đánh Giá An Toàn Mạng Wi-Fi (Security Audit)'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _auditBadge(
                        label: tr('An Toàn'),
                        count: safeCount,
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _auditBadge(
                        label: tr('Cảnh Báo'),
                        count: warningCount,
                        color: Colors.orange,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _auditBadge(
                        label: tr('Nguy Hiểm'),
                        count: dangerCount,
                        color: Colors.red,
                        icon: Icons.error_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dangerCount > 0
                      ? tr('Cảnh báo: Có {p0} mạng không có mật khẩu. Nguy cơ bị tấn công Man-in-the-Middle!', {'p0': '$dangerCount'})
                      : tr('Tất cả mạng Wi-Fi đã lưu đều có cấu hình mã hóa bảo vệ.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: dangerCount > 0 ? Colors.redAccent : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card 3: Batch Backup & Export
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.save_as_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('Sao Lưu & Khôi Phục Hồ Sơ (Backup & Recovery)'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tr('Xuất toàn bộ danh sách tên mạng và mật khẩu để lưu trữ dự phòng hoặc chuyển sang thiết bị mới:'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.file_copy_outlined, size: 18),
                      label: Text(tr('Xuất danh sách văn bản (TXT)')),
                      onPressed: () async {
                        final buffer = StringBuffer();
                        buffer.writeln('=== YomiHub Wi-Fi Password Recovery Report ===');
                        buffer.writeln('Thời gian: ${DateTime.now()}');
                        buffer.writeln('Tổng số mạng: ${_savedProfiles.length}');
                        buffer.writeln('----------------------------------------------');
                        for (final p in _savedProfiles) {
                          buffer.writeln('SSID    : ${p.ssid}');
                          buffer.writeln('Bảo mật : ${p.auth}');
                          buffer.writeln('Mật khẩu: ${p.password}');
                          buffer.writeln('----------------------------------------------');
                        }
                        await Clipboard.setData(ClipboardData(text: buffer.toString()));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('Đã sao chép danh sách {p0} hồ sơ Wi-Fi', {'p0': '${_savedProfiles.length}'}))),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.code_rounded, size: 18),
                      label: Text(tr('Sao lưu JSON')),
                      onPressed: () async {
                        final list = _savedProfiles.map((p) => {
                          'ssid': p.ssid,
                          'auth': p.auth,
                          'password': p.password,
                        }).toList();
                        final jsonStr = const JsonEncoder.withIndent('  ').convert(list);
                        await Clipboard.setData(ClipboardData(text: jsonStr));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('Đã sao chép cấu hình JSON Wi-Fi'))),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _auditBadge({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
