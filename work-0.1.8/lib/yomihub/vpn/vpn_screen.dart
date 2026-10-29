import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/vpn/vpn_service.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:mangayomi/yomihub/vpn/vpn_tunnels.dart';
import 'package:mangayomi/yomihub/vpn/dns_section.dart';
import 'package:mangayomi/yomihub/vpn/win/win_vpn.dart';

/// YomiHub 0.1.5: "VPN & DNS" — a hub with five separate pages:
/// VPN services (one at a time), in-app scope (extensions / WebView /
/// browser), outside apps / whole device, destination country, and DNS.
class VpnScreen extends StatefulWidget {
  /// hub, services, scope, apps, country, dns
  final String page;
  const VpnScreen({super.key, this.page = 'hub'});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  final vpn = YomiVpnService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    vpn.addListener(_refresh);
    YomiTunnels.instance.addListener(_refresh);
    vpn.init().then((_) => YomiTunnels.instance.init()).then((_) => _refresh());
  }

  @override
  void dispose() {
    vpn.removeListener(_refresh);
    YomiTunnels.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _maskProxy(String u) => u.replaceAll(RegExp(r'//[^@/]*@'), '//***@');

  Future<void> _editProxy() async {
    final ctrl = TextEditingController(text: YomiVpnState.proxyUrl);
    bool on = YomiVpnState.proxyEnabled || YomiVpnState.proxyUrl.isEmpty;
    String? err;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Proxy riêng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bật proxy'),
                  value: on,
                  onChanged: (v) => set(() => on = v),
                ),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ proxy',
                    hintText: 'host:port, user:pass@host:port, socks5://host:1080',
                    errorText: err,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tiện ích / WebView / trình duyệt đi qua proxy theo mục “VPN cho tiện ích, WebView & trình duyệt”.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                if (on && YomiVpnState.normaliseProxy(ctrl.text).isEmpty) {
                  set(() => err = 'Địa chỉ proxy không hợp lệ');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (save != true) return;
    if (on && !await _guard(VpnKind.proxy)) return;
    final e = await vpn.setProxy(enabled: on, url: ctrl.text);
    if (e != null) _snack(e);
    _refresh();
  }

  String _torLabel() => switch (vpn.torStatus) {
        'ON' => 'Đã kết nối • HTTP ${YomiVpnState.torHttpPort} • SOCKS ${YomiVpnState.torSocksPort}'
            '${vpn.torVpnUp ? ' • ${_appsSummary.replaceFirst('YomiHub + ', '')} qua Tor' : ''}'
            '${vpn.torVpnError != null && !vpn.torVpnUp && vpn.warpMode != WarpMode.app ? ' • VPN: ${vpn.torVpnError}' : ''}',
        'STARTING' => 'Đang kết nối mạng Tor…',
        'STOPPING' => 'Đang dừng…',
        _ => 'Đã tắt',
      };

  final tun = YomiTunnels.instance;

  /// Only one VPN service may run. Asks before switching; returns false when
  /// the user keeps the current one.
  Future<bool> _guard(VpnKind next) async {
    final others = vpn.conflictsWith(next);
    if (others.isEmpty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text('Chỉ bật được 1 dịch vụ VPN'),
        content: Text(
          'Đang bật: ${others.map((k) => k.label).join(', ')}.\n\n'
          'Chuyển sang ${next.label}? Dịch vụ đang bật sẽ tự tắt.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ nguyên')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Chuyển sang ${next.label}')),
        ],
      ),
    );
    if (ok != true) return false;
    await vpn.stopAllExcept(next);
    return true;
  }

  String get _activeSummary {
    final a = vpn.activeKinds();
    if (a.isEmpty) return 'Chưa bật dịch vụ nào';
    final k = a.first;
    final detail = switch (k) {
      VpnKind.tor => _torLabel(),
      VpnKind.warp => vpn.warpUp ? 'Đã kết nối' : 'Đang kết nối…',
      VpnKind.proxy => _maskProxy(YomiVpnState.proxyUrl),
      _ => '${tun.active?.name ?? ''} • ${_stateLabel(tun.state)}',
    };
    return '${k.label} • $detail';
  }

  String get _scopeSummary {
    final parts = <String>[
      YomiVpnState.scopeAllSources ? 'mọi tiện ích' : '${YomiVpnState.scopeSources.length} tiện ích',
      if (YomiVpnState.scopeWebView) 'WebView',
      if (YomiVpnState.scopeBrowser) 'trình duyệt',
    ];
    return parts.join(' • ');
  }

  String get _appsSummary => switch (vpn.warpMode) {
        WarpMode.app => 'Chỉ YomiHub',
        WarpMode.apps => 'YomiHub + ${vpn.warpApps.length} ứng dụng',
        WarpMode.device => Platform.isWindows ? 'Toàn bộ máy tính (proxy hệ thống)' : 'Toàn bộ thiết bị',
      };

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.page) {
      'services' => 'Dịch vụ VPN',
      'scope' => 'VPN cho tiện ích, WebView & trình duyệt',
      'apps' => Platform.isWindows ? 'VPN cho toàn bộ máy tính' : 'VPN cho ứng dụng ngoài / toàn thiết bị',
      'country' => 'Quốc gia đích',
      'dns' => 'DNS',
      _ => 'VPN & DNS',
    };
    final needsVpn = widget.page != 'dns' && widget.page != 'hub';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: needsVpn && !vpn.supported
          ? const Center(child: Text('Mục VPN hỗ trợ Android và Windows. Mục DNS dùng được trên mọi nền tảng.'))
          : ListView(
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (vpn.webViewNeedsRestart && widget.page != 'dns')
                  const MaterialBanner(
                    leading: Icon(Icons.restart_alt, color: Colors.orange),
                    content: Text(
                      'Windows: WebView2 (trình duyệt, xác minh Cloudflare, WebView của tiện ích) chỉ đổi đường đi khi '
                      'khởi động lại YomiHub. Tiện ích và tải xuống đã dùng cài đặt mới ngay.',
                    ),
                    actions: [SizedBox.shrink()],
                  ),
                if (vpn.lastError != null || tun.error != null)
                  MaterialBanner(
                    content: Text(vpn.lastError ?? tun.error!),
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() {
                          vpn.lastError = null;
                          tun.error = null;
                        }),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                ...switch (widget.page) {
                  'services' => _servicesPage(),
                  'scope' => _scopePage(),
                  'apps' => _appsPage(),
                  'country' => _countryPage(),
                  'dns' => const [YomiDnsSection()],
                  _ => _hubPage(),
                },
              ],
            ),
    );
  }

  void _open(String page) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VpnScreen(page: page)),
      );

  Widget _statusCard() {
    final on = vpn.activeKinds().isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: on ? cs.primaryContainer : null,
      child: ListTile(
        leading: Icon(on ? Icons.vpn_lock : Icons.vpn_key_off_outlined,
            color: on ? Colors.green : null),
        title: Text(on ? 'VPN đang bật' : 'VPN đang tắt'),
        subtitle: Text(_activeSummary),
        trailing: on
            ? TextButton(
                onPressed: () => _run(() async {
                  for (final k in vpn.activeKinds()) {
                    switch (k) {
                      case VpnKind.tor:
                        await vpn.setTorEnabled(false);
                      case VpnKind.warp:
                        await vpn.setWarpEnabled(false);
                      case VpnKind.proxy:
                        await vpn.setProxy(enabled: false, url: YomiVpnState.proxyUrl);
                      default:
                        await tun.disconnect();
                    }
                  }
                }),
                child: const Text('Tắt'),
              )
            : null,
      ),
    );
  }

  List<Widget> _hubPage() => [
        if (vpn.supported) _statusCard(),
        if (vpn.supported) ...[
          _hubTile(Icons.shield_outlined, 'Dịch vụ VPN', 'Tor, Cloudflare WARP, OpenVPN, WireGuard, SoftEther, Mihon Proxy, Proxy riêng — chỉ bật 1 dịch vụ cùng lúc', 'services'),
          _hubTile(Icons.extension_outlined, 'VPN cho tiện ích, WebView & trình duyệt', _scopeSummary, 'scope'),
          _hubTile(Icons.apps_outlined,
              Platform.isWindows ? 'VPN cho toàn bộ máy tính' : 'VPN cho ứng dụng ngoài / toàn thiết bị', _appsSummary, 'apps'),
          _hubTile(Icons.public, 'Quốc gia đích',
              '${countryFlag(tun.country)} ${vpnCountries[tun.country] ?? tun.country}', 'country'),
        ],
        _hubTile(Icons.dns_outlined, 'DNS', 'DNS-over-HTTPS (DoH) và nhà cung cấp DNS', 'dns'),
      ];

  Widget _hubTile(IconData icon, String title, String sub, String page) => ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(page),
      );

  List<Widget> _servicesPage() {
    final theme = Theme.of(context);
    return [
      _statusCard(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          'Chỉ một dịch vụ VPN được bật cùng lúc. Bật dịch vụ khác sẽ hiện cảnh báo; đồng ý thì YomiHub tự tắt dịch vụ cũ và chuyển sang dịch vụ mới.',
          style: theme.textTheme.bodySmall,
        ),
      ),
      _section('Tor', Icons.security, subtitle: _torLabel(), children: [
        SwitchListTile(
          title: const Text('Bật Tor'),
          subtitle: Text(_torLabel()),
          value: YomiVpnState.torEnabled,
          onChanged: (v) => _run(() async {
            if (v && !await _guard(VpnKind.tor)) return;
            await vpn.setTorEnabled(v);
          }),
        ),
        SwitchListTile(
          title: const Text('Kill switch'),
          subtitle: const Text('Chặn kết nối được định tuyến khi Tor chưa sẵn sàng (không lộ IP thật)'),
          value: YomiVpnState.killSwitch,
          onChanged: (v) => vpn.setKillSwitch(v),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Đổi danh tính (mạch Tor mới)'),
          enabled: vpn.torStatus == 'ON',
          onTap: () async {
            final ok = await vpn.newIdentity();
            _snack(ok ? 'Đã yêu cầu mạch Tor mới' : 'Không đổi được danh tính');
          },
        ),
        SwitchListTile(
          title: const Text('Tự động đổi danh tính'),
          value: vpn.autoTorIdentity,
          onChanged: (v) => vpn.setRotation('autoTorIdentity', v),
        ),
        if (vpn.autoTorIdentity)
          _rotationInterval('Thời gian làm mới danh tính', vpn.torIdentityMinutes, 'torIdentityMinutes'),
        if (Platform.isWindows)
          ListTile(
            leading: const Icon(Icons.alt_route),
            title: const Text('Cầu nối (khi mạng chặn Tor)'),
            subtitle: Text(switch (vpn.torBridge) {
              'snowflake' => 'Snowflake',
              'obfs4' => 'obfs4',
              'meek' => 'meek (Azure)',
              _ => 'Không dùng – kết nối thẳng vào mạng Tor',
            }),
            trailing: DropdownButton<String>(
              value: vpn.torBridge,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: '', child: Text('Tắt')),
                DropdownMenuItem(value: 'snowflake', child: Text('Snowflake')),
                DropdownMenuItem(value: 'obfs4', child: Text('obfs4')),
                DropdownMenuItem(value: 'meek', child: Text('meek')),
              ],
              onChanged: (v) => v == null ? null : _run(() => vpn.setTorBridge(v)),
            ),
          ),
      ]),
      _section(
        'Cloudflare WARP',
        Icons.cloud_outlined,
        subtitle: vpn.warpEnabled ? (vpn.warpUp ? 'Đã kết nối' : 'Đang kết nối…') : 'Đã tắt',
        children: [
          SwitchListTile(
            title: const Text('Bật WARP'),
            subtitle: Text(vpn.warpEnabled
                ? (vpn.warpUp ? 'Đã kết nối • $_appsSummary' : 'Đang kết nối…')
                : 'Mã hoá kết nối qua mạng 1.1.1.1 của Cloudflare'),
            value: vpn.warpEnabled,
            onChanged: (v) => _run(() async {
              if (v && !await _guard(VpnKind.warp)) return;
              await vpn.setWarpEnabled(v);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Tạo lại tài khoản WARP'),
            onTap: () => _run(vpn.resetWarpAccount),
          ),
        ],
      ),
      _profileSection(
        TunnelType.openvpn,
        Icons.lock_outline,
        Platform.isWindows
            ? 'Nhập file .ovpn của nhà cung cấp VPN. Windows: YomiHub chuyển hồ sơ cho OpenVPN GUI '
                '(${WinVpnBackend.openVpnGui() == null ? 'chưa cài – tải “OpenVPN Community” tại openvpn.net' : 'đã cài'}), '
                'đường hầm OpenVPN luôn áp cho toàn máy.'
            : 'Nhập file .ovpn của nhà cung cấp VPN (hoặc máy chủ OpenVPN của bạn).',
      ),
      _profileSection(
        TunnelType.wireguard,
        Icons.shield_moon_outlined,
        Platform.isWindows
            ? 'Nhập file .conf WireGuard. Windows: chạy trong lõi Xray của YomiHub (không cần driver, không cần quyền quản trị).'
            : 'Nhập file .conf WireGuard.',
      ),
      _softEtherSection(theme),
      _profileSection(
        TunnelType.xray,
        Icons.alt_route,
        'Mihon Proxy: dán link vless:// (REALITY), vmess://, trojan://, ss://. '
            'YomiHub chạy lõi Xray và đưa tiện ích, WebView và trình duyệt (theo phạm vi đã chọn) qua proxy cục bộ.',
      ),
      _section('Proxy riêng (thay cho HolaVPN)', Icons.settings_ethernet, children: [
        ListTile(
          leading: Icon(YomiVpnState.proxyEnabled ? Icons.check_circle : Icons.circle_outlined,
              color: YomiVpnState.proxyEnabled ? Colors.green : null),
          title: const Text('Proxy HTTP(S) / SOCKS5'),
          subtitle: Text(YomiVpnState.proxyEnabled && YomiVpnState.proxyUrl.isNotEmpty
              ? _maskProxy(YomiVpnState.proxyUrl)
              : 'Đã tắt – chạm để nhập proxy'),
          onTap: _editProxy,
        ),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: const Text('Kiểm tra proxy'),
          enabled: YomiVpnState.proxyUrl.isNotEmpty,
          onTap: () async => _snack(await vpn.testProxy()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'HolaVPN không có mã nguồn hay API công khai để tích hợp. Bạn có thể nhập proxy của nhà cung cấp '
            'VPN/proxy mình dùng, hoặc proxy chạy trên máy tính của bạn.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ]),
    ];
  }

  List<Widget> _scopePage() {
    final theme = Theme.of(context);
    return [
      SwitchListTile(
        secondary: const Icon(Icons.extension_outlined),
        title: const Text('Mọi tiện ích'),
        subtitle: const Text('Kể cả ảnh bìa, trang truyện, luồng phim và tải xuống. Tắt để chọn riêng từng tiện ích.'),
        value: YomiVpnState.scopeAllSources,
        onChanged: (v) => vpn.setScopeAll(v),
      ),
      ListTile(
        leading: const Icon(Icons.checklist),
        title: const Text('Chọn tiện ích dùng VPN'),
        subtitle: Text(YomiVpnState.scopeAllSources
            ? 'Đang áp dụng cho mọi tiện ích'
            : '${YomiVpnState.scopeSources.length} tiện ích'),
        enabled: !YomiVpnState.scopeAllSources,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const _ScopeSourcesScreen()))
            .then((_) => _refresh()),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.web_asset),
        title: const Text('Chế độ WebView'),
        subtitle: const Text('Màn hình WebView của tiện ích, xác minh Cloudflare, WebView ẩn của tiện ích'),
        value: YomiVpnState.scopeWebView,
        onChanged: (v) => vpn.setScopeWebView(v),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.public),
        title: const Text('Trình duyệt trong ứng dụng'),
        subtitle: const Text('Các tab Chromium của nút Trình duyệt'),
        value: YomiVpnState.scopeBrowser,
        onChanged: (v) => vpn.setScopeBrowser(v),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          Platform.isWindows
              ? 'Windows: phạm vi này áp dụng cho Tor, WARP, WireGuard, Mihon Proxy và Proxy riêng. WebView2 '
                  '(WebView, trình duyệt) nhận thay đổi sau khi khởi động lại YomiHub. OpenVPN/SoftEther mang toàn bộ máy.'
              : 'Phạm vi này áp dụng cho Tor, Mihon Proxy và Proxy riêng. WARP, OpenVPN, WireGuard và SoftEther '
                  'là đường hầm VPN: chúng mang toàn bộ kết nối của YomiHub (xem mục “Ứng dụng ngoài / toàn thiết bị”).',
          style: theme.textTheme.bodySmall,
        ),
      ),
    ];
  }

  List<Widget> _appsPage() {
    final theme = Theme.of(context);
    if (Platform.isWindows) {
      return [
        RadioGroup<WarpMode>(
          groupValue: vpn.warpMode == WarpMode.apps ? WarpMode.app : vpn.warpMode,
          onChanged: (m) => m == null ? null : _run(() => vpn.setWarpMode(m)),
          child: const Column(
            children: [
              RadioListTile(
                value: WarpMode.app,
                title: Text('Chỉ YomiHub'),
                subtitle: Text('Tiện ích, WebView và trình duyệt theo mục “VPN cho tiện ích”'),
              ),
              RadioListTile(
                value: WarpMode.device,
                title: Text('Toàn bộ máy tính'),
                subtitle: Text('Đặt proxy hệ thống của Windows (Edge, Chrome, Cốc Cốc và đa số ứng dụng)'),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(
            WinVpnBackend.instance.systemProxyActive ? Icons.check_circle : Icons.circle_outlined,
            color: WinVpnBackend.instance.systemProxyActive ? Colors.green : null,
          ),
          title: Text(WinVpnBackend.instance.systemProxyActive
              ? 'Proxy hệ thống: 127.0.0.1:${WinVpnBackend.httpPort}'
              : 'Proxy hệ thống: không dùng'),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Áp dụng cho Tor, Cloudflare WARP, WireGuard, Mihon Proxy và Proxy riêng (YomiHub chạy chúng qua lõi Xray '
            'tại 127.0.0.1:${WinVpnBackend.httpPort}). Khi tắt dịch vụ hoặc đóng YomiHub, cài đặt proxy cũ của Windows '
            'được trả lại. Ứng dụng không dùng proxy hệ thống (một số game, ứng dụng UDP) sẽ không đi qua. '
            'OpenVPN / SoftEther qua OpenVPN GUI luôn áp cho toàn máy. Chọn từng ứng dụng riêng chỉ có trên Android.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ];
    }
    return [
      RadioGroup<WarpMode>(
        groupValue: vpn.warpMode,
        onChanged: (m) => m == null ? null : _run(() => vpn.setWarpMode(m)),
        child: const Column(
          children: [
            RadioListTile(value: WarpMode.app, title: Text('Chỉ YomiHub')),
            RadioListTile(
              value: WarpMode.apps,
              title: Text('YomiHub và các ứng dụng đã chọn'),
              subtitle: Text('Hỗ trợ từng ứng dụng cụ thể'),
            ),
            RadioListTile(
              value: WarpMode.device,
              title: Text('Toàn bộ thiết bị'),
              subtitle: Text('Mọi ứng dụng trên máy đi qua VPN'),
            ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.apps),
        title: const Text('Chọn ứng dụng'),
        subtitle: Text('${vpn.warpApps.length} ứng dụng'),
        enabled: vpn.warpMode == WarpMode.apps,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const _WarpAppsScreen()))
            .then((_) => _refresh()),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Áp dụng cho Tor, Cloudflare WARP, OpenVPN, WireGuard và SoftEther (đang kết nối thì tự kết nối lại). '
          'Tor cho ứng dụng ngoài/toàn thiết bị chạy qua VPN của Android (tun2socks → cổng SOCKS của Tor, '
          'DNS phân giải qua Tor); YomiHub vẫn dùng Tor theo phạm vi trong app. Tor chỉ mang TCP: '
          'UDP khác (QUIC, game) không đi qua được. Mihon Proxy và Proxy riêng chỉ phục vụ YomiHub. '
          'Nếu file WireGuard .conf đã có IncludedApplications/ExcludedApplications thì giữ nguyên cấu hình đó.',
          style: theme.textTheme.bodySmall,
        ),
      ),
    ];
  }

  List<Widget> _countryPage() {
    final theme = Theme.of(context);
    return [
      ListTile(
        leading: Text(countryFlag(tun.country), style: const TextStyle(fontSize: 24)),
        title: const Text('Chọn quốc gia'),
        subtitle: Text(vpnCountries[tun.country] ?? tun.country),
        onTap: _pickCountry,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'Áp dụng cho: nút điểm ra của Tor, máy chủ SoftEther/VPN Gate được chọn tự động và hồ sơ '
          'OpenVPN / WireGuard / Mihon Proxy gắn quốc gia. Cloudflare WARP luôn dùng máy chủ gần nhất.',
          style: theme.textTheme.bodySmall,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.bolt),
        title: const Text('Kết nối nhanh tới quốc gia này'),
        subtitle: const Text('Ưu tiên hồ sơ của bạn, nếu không có thì dùng máy chủ VPN Gate (SoftEther)'),
        onTap: () => _run(_quickConnect),
      ),
    ];
  }

  String _stateLabel(String s) => switch (s) {
        'connected' => 'Đã kết nối',
        'connecting' => 'Đang kết nối…',
        'error' => 'Lỗi',
        'disconnected' => 'Đã ngắt',
        _ => s,
      };

  Widget _section(
    String title,
    IconData icon, {
    required List<Widget> children,
    String? subtitle,
    bool initiallyExpanded = false,
  }) {
    final c = Theme.of(context).colorScheme.primary;
    return ExpansionTile(
      leading: Icon(icon, color: c),
      title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
      subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      initiallyExpanded: initiallyExpanded,
      maintainState: true,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: children,
    );
  }

  Future<void> _pickCountry() async {
    final cc = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Quốc gia đích đến'),
        children: [
          for (final e in vpnCountries.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e.key),
              child: Row(children: [
                Text(countryFlag(e.key), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value)),
                if (e.key == tun.country) const Icon(Icons.check, size: 18),
              ]),
            ),
        ],
      ),
    );
    if (cc == null) return;
    await tun.setCountry(cc);
    await _run(vpn.applyCountry);
  }

  Future<void> _quickConnect() async {
    final cc = tun.country;
    final mine = tun.profiles
        .where((p) => p.type != TunnelType.softether && (cc.isEmpty || p.country == cc))
        .toList();
    if (mine.isNotEmpty) {
      await _connect(mine.first);
      return;
    }
    try {
      final s = await tun.pickVpnGate(cc);
      if (s == null) {
        _snack('Không có máy chủ VPN Gate cho ${vpnCountries[cc] ?? cc}');
        return;
      }
      if (!await _guard(VpnKind.softether)) return;
      final err = await tun.connectVpnGate(s);
      if (err != null) _snack(err);
    } catch (e) {
      _snack('Không tải được danh sách VPN Gate: $e');
    }
  }

  static VpnKind _kindOf(TunnelType t) => switch (t) {
        TunnelType.openvpn => VpnKind.openvpn,
        TunnelType.wireguard => VpnKind.wireguard,
        TunnelType.softether => VpnKind.softether,
        TunnelType.xray => VpnKind.xray,
      };

  Future<void> _connect(VpnProfile p) async {
    if (!await _guard(_kindOf(p.type))) return;
    final err = await tun.connect(p);
    if (err != null) _snack(err);
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _profileSection(TunnelType type, IconData icon, String help, {List<Widget> extra = const []}) {
    final list = tun.profiles.where((p) => p.type == type).toList();
    final activeHere = tun.active?.type == type;
    return _section(
      type.label,
      icon,
      subtitle: activeHere ? '${_stateLabel(tun.state)} • ${tun.active!.name}' : '${list.length} hồ sơ',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(help, style: Theme.of(context).textTheme.bodySmall),
        ),
        ...extra,
        for (final p in list)
          ListTile(
            leading: Text(countryFlag(p.country), style: const TextStyle(fontSize: 22)),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(tun.activeId == p.id ? _stateLabel(tun.state) : (vpnCountries[p.country] ?? 'Chưa gắn quốc gia')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: tun.activeId == p.id ? 'Ngắt' : 'Kết nối',
                  icon: Icon(tun.activeId == p.id ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                  onPressed: () => _run(() async {
                    if (tun.activeId == p.id) {
                      await tun.disconnect();
                    } else {
                      await _connect(p);
                    }
                  }),
                ),
                PopupMenuButton<int>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('Gắn quốc gia')),
                    PopupMenuItem(value: 1, child: Text('Đổi tên / tài khoản')),
                    PopupMenuItem(value: 2, child: Text('Xoá')),
                  ],
                  onSelected: (v) async {
                    if (v == 0) {
                      final cc = await showDialog<String>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Quốc gia của máy chủ'),
                          children: [
                            for (final e in vpnCountries.entries)
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(ctx, e.key),
                                child: Text('${countryFlag(e.key)}  ${e.key.isEmpty ? 'Không rõ' : e.value}'),
                              ),
                          ],
                        ),
                      );
                      if (cc != null) {
                        p.country = cc;
                        await tun.updateProfile(p);
                      }
                    } else if (v == 1) {
                      await _editProfile(p);
                    } else {
                      await tun.deleteProfile(p.id);
                    }
                  },
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.content_paste),
              label: Text(type == TunnelType.xray ? 'Dán link' : 'Dán cấu hình'),
              onPressed: () => _importPaste(type),
            ),
            if (type != TunnelType.xray)
              TextButton.icon(
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Chọn file'),
                onPressed: () => _importFile(type),
              ),
          ],
        ),
      ],
    );
  }

  Widget _softEtherSection(ThemeData theme) {
    final servers = tun.vpnGate;
    final cc = tun.country;
    final shown = (servers ?? const <VpnGateServer>[])
        .where((s) => cc.isEmpty || s.countryCode.toUpperCase() == cc)
        .take(30)
        .toList();
    final own = tun.profiles.where((p) => p.type == TunnelType.softether && !p.id.startsWith('vpngate_')).toList();
    return _section(
      'SoftEther VPN',
      Icons.hub_outlined,
      subtitle: tun.active?.type == TunnelType.softether
          ? '${_stateLabel(tun.state)} • ${tun.active!.name}'
          : 'VPN Gate + máy chủ SoftEther của bạn',
      children: [
        SwitchListTile(
          title: const Text('Tự động đổi máy chủ SoftEther'),
          subtitle: const Text('Chuyển sang máy chủ khác trong cùng nhóm khi đang kết nối. Kết nối có thể bị gián đoạn.'),
          value: vpn.autoSoftEtherServer,
          onChanged: (v) => vpn.setRotation('autoSoftEtherServer', v),
        ),
        if (vpn.autoSoftEtherServer)
          _rotationInterval('Thời gian đổi máy chủ', vpn.softEtherMinutes, 'softEtherMinutes'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Kết nối tới máy chủ SoftEther qua giao thức OpenVPN: mạng VPN Gate công khai (Đại học Tsukuba) '
            'hoặc máy chủ SoftEther của bạn (xuất file .ovpn trong SoftEther Server Manager › OpenVPN / MS-SSTP).',
            style: theme.textTheme.bodySmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: Text(servers == null ? 'Tải danh sách máy chủ VPN Gate' : 'Làm mới danh sách (${servers.length} máy chủ)'),
          subtitle: Text('Lọc theo: ${countryFlag(cc)} ${vpnCountries[cc] ?? cc}'),
          onTap: () => _run(() async {
            try {
              await tun.loadVpnGate(force: true);
            } catch (e) {
              _snack('Không tải được VPN Gate: $e');
            }
          }),
        ),
        for (final s in shown)
          ListTile(
            dense: true,
            leading: Text(countryFlag(s.countryCode), style: const TextStyle(fontSize: 20)),
            title: Text(s.host),
            subtitle: Text('${s.country} • ping ${s.ping} ms • ${(s.speed / 1e6).toStringAsFixed(1)} Mbps • ${s.sessions} phiên'),
            trailing: tun.activeId == 'vpngate_${s.ip}'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.play_circle_outline),
            onTap: () => _run(() async {
              if (!await _guard(VpnKind.softether)) return;
              final err = await tun.connectVpnGate(s);
              if (err != null) _snack(err);
            }),
          ),
        for (final p in own)
          ListTile(
            leading: Text(countryFlag(p.country), style: const TextStyle(fontSize: 22)),
            title: Text(p.name),
            subtitle: Text(tun.activeId == p.id ? _stateLabel(tun.state) : 'Máy chủ SoftEther của bạn'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => tun.deleteProfile(p.id),
            ),
            onTap: () => _run(() async {
              if (tun.activeId == p.id) {
                await tun.disconnect();
              } else {
                await _connect(p);
              }
            }),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Thêm máy chủ SoftEther (.ovpn)'),
          onPressed: () => _importFile(TunnelType.softether),
        ),
      ],
    );
  }

  Widget _rotationInterval(String title, int value, String key) {
    final values = <int>{1, 5, 10, 15, 30, 60, value}.toList()..sort();
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<int>(
        value: value,
        items: [for (final minutes in values)
          DropdownMenuItem(value: minutes, child: Text('$minutes phút'))],
        onChanged: (minutes) {
          if (minutes != null) vpn.setRotation(key, minutes);
        },
      ),
    );
  }

  Future<void> _importPaste(TunnelType type) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm ${type.label}'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: type == TunnelType.xray ? 'vless://… (mỗi dòng một link)' : 'Dán nội dung cấu hình',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Thêm')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final err = await tun.importText(text, type: type, country: tun.country);
    if (err != null) _snack(err);
  }

  Future<void> _importFile(TunnelType type) async {
    final files = await FilePicker.pickFiles();
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final text = await File(path).readAsString();
        final err = await tun.importText(
          text,
          type: type,
          name: f.name.replaceAll(RegExp(r'\.(ovpn|conf)$'), ''),
        );
        if (err != null) _snack('${f.name}: $err');
      } catch (e) {
        _snack('${f.name}: $e');
      }
    }
  }

  Future<void> _editProfile(VpnProfile p) async {
    final name = TextEditingController(text: p.name);
    final user = TextEditingController(text: p.username);
    final pass = TextEditingController(text: p.password);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hồ sơ VPN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên')),
            if (p.type == TunnelType.openvpn || p.type == TunnelType.softether) ...[
              TextField(controller: user, decoration: const InputDecoration(labelText: 'Tài khoản (nếu có)')),
              TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu (nếu có)')),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    p
      ..name = name.text.trim().isEmpty ? p.name : name.text.trim()
      ..username = user.text.trim()
      ..password = pass.text;
    await tun.updateProfile(p);
  }
}

class _ScopeSourcesScreen extends StatefulWidget {
  const _ScopeSourcesScreen();
  @override
  State<_ScopeSourcesScreen> createState() => _ScopeSourcesScreenState();
}

class _ScopeSourcesScreenState extends State<_ScopeSourcesScreen> {
  final vpn = YomiVpnService.instance;
  String _q = '';
  late final List<Source> _all = sourceRepository
      .getAll()
      .where((s) => (s.isAdded ?? false) && s.id != null)
      .toList()
    ..sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));

  String _type(Source s) => switch (s.itemType) {
        ItemType.manga => 'Comic',
        ItemType.anime => 'Film & Movie',
        ItemType.novel => 'Novel',
      };

  @override
  Widget build(BuildContext context) {
    final list = _all.where((s) => (s.name ?? '').toLowerCase().contains(_q.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(hintText: 'Tìm tiện ích…', border: InputBorder.none),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: list.isEmpty
          ? const Center(child: Text('Chưa cài tiện ích nào'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final s = list[i];
                return SwitchListTile(
                  title: Text(s.name ?? ''),
                  subtitle: Text('${_type(s)} • ${s.lang ?? ''} • ${s.baseUrl ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  value: vpn.isSourceInScope(s.id!),
                  onChanged: (v) async {
                    await vpn.setSourceInScope(s.id!, v);
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}

class _WarpAppsScreen extends StatefulWidget {
  const _WarpAppsScreen();
  @override
  State<_WarpAppsScreen> createState() => _WarpAppsScreenState();
}

class _WarpAppsScreenState extends State<_WarpAppsScreen> {
  final vpn = YomiVpnService.instance;
  List<InstalledApp>? _apps;
  late Set<String> _sel = {...vpn.warpApps};
  String _q = '';
  bool _showSystem = false;

  @override
  void initState() {
    super.initState();
    vpn.installedApps().then((a) => mounted ? setState(() => _apps = a) : null);
  }

  @override
  Widget build(BuildContext context) {
    final apps = (_apps ?? [])
        .where((a) => _showSystem || !a.system)
        .where((a) => a.label.toLowerCase().contains(_q.toLowerCase()) || a.package.contains(_q))
        .toList();
    return PopScope(
      onPopInvokedWithResult: (_, _) => vpn.setWarpApps(_sel.toList()),
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            decoration: const InputDecoration(hintText: 'Tìm ứng dụng…', border: InputBorder.none),
            onChanged: (v) => setState(() => _q = v),
          ),
          actions: [
            IconButton(
              tooltip: 'Hiện ứng dụng hệ thống',
              icon: Icon(_showSystem ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showSystem = !_showSystem),
            ),
          ],
        ),
        body: _apps == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: apps.length,
                itemBuilder: (_, i) {
                  final a = apps[i];
                  return CheckboxListTile(
                    title: Text(a.label),
                    subtitle: Text(a.package, style: const TextStyle(fontSize: 11)),
                    value: _sel.contains(a.package),
                    onChanged: (v) => setState(() {
                      _sel = {..._sel};
                      v == true ? _sel.add(a.package) : _sel.remove(a.package);
                    }),
                  );
                },
              ),
      ),
    );
  }
}
