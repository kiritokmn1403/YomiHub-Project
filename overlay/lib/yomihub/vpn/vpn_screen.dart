import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
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
import 'package:mangayomi/yomihub/vpn/ext_vpn.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

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
          title: Text(tr('Proxy riêng')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('Bật proxy')),
                  value: on,
                  onChanged: (v) => set(() => on = v),
                ),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: tr('Địa chỉ proxy'),
                    hintText: 'host:port, user:pass@host:port, socks5://host:1080',
                    errorText: err,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Tiện ích / WebView / trình duyệt đi qua proxy theo mục “VPN cho tiện ích, WebView & trình duyệt”.'),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Hủy'))),
            FilledButton(
              onPressed: () {
                if (on && YomiVpnState.normaliseProxy(ctrl.text).isEmpty) {
                  set(() => err = tr('Địa chỉ proxy không hợp lệ'));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(tr('Lưu')),
            ),
          ],
        ),
      ),
    );
    if (save != true) return;
    if (on && !await _guard(VpnKind.proxy)) return;
    await YomiPrefs.set('proxyOwner', '');
    final e = await vpn.setProxy(enabled: on, url: ctrl.text);
    if (e != null) _snack(e);
    _refresh();
  }

  String _torLabel() => switch (vpn.torStatus) {
        'ON' => tr('Đã kết nối • HTTP {p0} • SOCKS {p1}{p2}{p3}', {'p0': YomiVpnState.torHttpPort, 'p1': YomiVpnState.torSocksPort, 'p2': vpn.torVpnUp ? ' • ${_appsSummary.replaceFirst('YomiHub + ', '')}' : '', 'p3': vpn.torVpnError != null && !vpn.torVpnUp && vpn.warpMode != WarpMode.app ? ' • VPN: ${vpn.torVpnError}' : ''}),
        'STARTING' => tr('Đang kết nối mạng Tor…'),
        'STOPPING' => tr('Đang dừng…'),
        _ => tr('Đã tắt'),
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
        title: Text(tr('Chỉ bật được 1 dịch vụ VPN')),
        content: Text(
          tr('Đang bật: {p0}.\n\nChuyển sang {p1}? Dịch vụ đang bật sẽ tự tắt.', {'p0': others.map((k) => k.label).join(', '), 'p1': next.label}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Giữ nguyên'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Chuyển sang {p0}', {'p0': next.label}))),
        ],
      ),
    );
    if (ok != true) return false;
    await vpn.stopAllExcept(next);
    return true;
  }

  String get _activeSummary {
    final a = vpn.activeKinds();
    if (a.isEmpty) return tr('Chưa bật dịch vụ nào');
    final k = a.first;
    final detail = switch (k) {
      VpnKind.tor => _torLabel(),
      VpnKind.warp => vpn.warpUp ? tr('Đã kết nối') : tr('Đang kết nối…'),
      VpnKind.proxy => _maskProxy(YomiVpnState.proxyUrl),
      VpnKind.adguard => 'SOCKS5 ${YomiExtVpn.adguardHost}:${YomiExtVpn.adguardPort}',
      _ => '${tun.active?.name ?? ''} • ${_stateLabel(tun.state)}',
    };
    return '${k.label} • $detail';
  }

  String get _scopeSummary {
    final parts = <String>[
      YomiVpnState.scopeAllSources ? tr('mọi tiện ích') : tr('{p0} tiện ích', {'p0': YomiVpnState.scopeSources.length}),
      if (YomiVpnState.scopeWebView) 'WebView',
      if (YomiVpnState.scopeBrowser) tr('trình duyệt'),
    ];
    return parts.join(' • ');
  }

  String get _appsSummary => switch (vpn.warpMode) {
        WarpMode.app => tr('Chỉ YomiHub'),
        WarpMode.apps => tr('YomiHub + {p0} ứng dụng', {'p0': vpn.warpApps.length}),
        WarpMode.device => Platform.isWindows ? tr('Toàn bộ máy tính (proxy hệ thống)') : tr('Toàn bộ thiết bị'),
      };

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.page) {
      'services' => tr('Dịch vụ VPN'),
      'scope' => tr('VPN cho tiện ích, WebView & trình duyệt'),
      'apps' => Platform.isWindows ? tr('VPN cho toàn bộ máy tính') : tr('VPN cho ứng dụng ngoài / toàn thiết bị'),
      'country' => tr('Quốc gia đích'),
      'dns' => 'DNS',
      _ => 'VPN & DNS',
    };
    final needsVpn = widget.page != 'dns' && widget.page != 'hub';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: needsVpn && !vpn.supported
          ? Center(child: Text(tr('Mục VPN hỗ trợ Android và Windows. Mục DNS dùng được trên mọi nền tảng.')))
          : ListView(
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (vpn.webViewNeedsRestart && widget.page != 'dns')
                  MaterialBanner(
                    leading: Icon(Icons.restart_alt, color: Colors.orange),
                    content: Text(
                      tr('Windows: WebView2 (trình duyệt, xác minh Cloudflare, WebView của tiện ích) chỉ đổi đường đi khi khởi động lại YomiHub. Tiện ích và tải xuống đã dùng cài đặt mới ngay.'),
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
                        child: Text(tr('Đóng')),
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
        title: Text(on ? tr('VPN đang bật') : tr('VPN đang tắt')),
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
                      case VpnKind.adguard:
                        await vpn.setProxy(enabled: false, url: YomiVpnState.proxyUrl);
                        await YomiPrefs.set('proxyOwner', '');
                      default:
                        await tun.disconnect();
                    }
                  }
                }),
                child: Text(tr('Tắt')),
              )
            : null,
      ),
    );
  }

  List<Widget> _hubPage() => [
        if (vpn.supported) _statusCard(),
        if (vpn.supported) ...[
          _hubTile(Icons.shield_outlined, tr('Dịch vụ VPN'), tr('Tor, Cloudflare WARP, OpenVPN, WireGuard, SoftEther, AdGuard VPN, Urban VPN, Mihon Proxy, Proxy riêng — chỉ bật 1 dịch vụ cùng lúc'), 'services'),
          _hubTile(Icons.extension_outlined, tr('VPN cho tiện ích, WebView & trình duyệt'), _scopeSummary, 'scope'),
          _hubTile(Icons.apps_outlined,
              Platform.isWindows ? tr('VPN cho toàn bộ máy tính') : tr('VPN cho ứng dụng ngoài / toàn thiết bị'), _appsSummary, 'apps'),
          _hubTile(Icons.public, tr('Quốc gia đích'),
              '${countryFlag(tun.country)} ${vpnCountries[tun.country] ?? tun.country}', 'country'),
        ],
        _hubTile(Icons.dns_outlined, 'DNS', tr('DNS-over-HTTPS (DoH) và nhà cung cấp DNS'), 'dns'),
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
          tr('Chỉ một dịch vụ VPN được bật cùng lúc. Bật dịch vụ khác sẽ hiện cảnh báo; đồng ý thì YomiHub tự tắt dịch vụ cũ và chuyển sang dịch vụ mới.'),
          style: theme.textTheme.bodySmall,
        ),
      ),
      _section('Tor', Icons.security, subtitle: _torLabel(), children: [
        SwitchListTile(
          title: Text(tr('Bật Tor')),
          subtitle: Text(_torLabel()),
          value: YomiVpnState.torEnabled,
          onChanged: (v) => _run(() async {
            if (v && !await _guard(VpnKind.tor)) return;
            await vpn.setTorEnabled(v);
          }),
        ),
        SwitchListTile(
          title: const Text('Kill switch'),
          subtitle: Text(tr('Chặn kết nối được định tuyến khi Tor chưa sẵn sàng (không lộ IP thật)')),
          value: YomiVpnState.killSwitch,
          onChanged: (v) => vpn.setKillSwitch(v),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: Text(tr('Đổi danh tính (mạch Tor mới)')),
          enabled: vpn.torStatus == 'ON',
          onTap: () async {
            final ok = await vpn.newIdentity();
            _snack(ok ? tr('Đã yêu cầu mạch Tor mới') : tr('Không đổi được danh tính'));
          },
        ),
        SwitchListTile(
          title: Text(tr('Tự động đổi danh tính')),
          value: vpn.autoTorIdentity,
          onChanged: (v) => vpn.setRotation('autoTorIdentity', v),
        ),
        if (vpn.autoTorIdentity)
          _rotationInterval(tr('Thời gian làm mới danh tính'), vpn.torIdentityMinutes, 'torIdentityMinutes'),
        // 0.4.5: Android too (lyrebird), with "Tự động" as default
        if (Platform.isWindows || Platform.isAndroid)
          ListTile(
            leading: const Icon(Icons.alt_route),
            title: Text(tr('Cầu nối (khi mạng chặn Tor)')),
            subtitle: Text('${switch (vpn.torBridge) {
              'auto' => tr('Tự động: kết nối thẳng, nếu bị chặn thì thử Snowflake → obfs4 → meek'),
              'snowflake' => 'Snowflake',
              'obfs4' => 'obfs4',
              'meek' => 'meek (Azure)',
              _ => tr('Không dùng – kết nối thẳng vào mạng Tor'),
            }}${vpn.torBridgeActive.isEmpty ? '' : ' • ${tr('đang dùng: {p0}', {'p0': vpn.torBridgeActive})}'}'),
            trailing: DropdownButton<String>(
              value: vpn.torBridge,
              underline: const SizedBox.shrink(),
              items: [
                if (Platform.isAndroid) DropdownMenuItem(value: 'auto', child: Text(tr('Tự động'))),
                DropdownMenuItem(value: '', child: Text(tr('Tắt'))),
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
        subtitle: vpn.warpEnabled ? (vpn.warpUp ? tr('Đã kết nối') : tr('Đang kết nối…')) : tr('Đã tắt'),
        children: [
          SwitchListTile(
            title: Text(tr('Bật WARP')),
            subtitle: Text(vpn.warpEnabled
                ? (vpn.warpUp ? tr('Đã kết nối • {p0}', {'p0': _appsSummary}) : tr('Đang kết nối…'))
                : tr('Mã hoá kết nối qua mạng 1.1.1.1 của Cloudflare')),
            value: vpn.warpEnabled,
            onChanged: (v) => _run(() async {
              if (v && !await _guard(VpnKind.warp)) return;
              await vpn.setWarpEnabled(v);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(tr('Tạo lại tài khoản WARP')),
            onTap: () => _run(vpn.resetWarpAccount),
          ),
        ],
      ),
      _profileSection(
        TunnelType.openvpn,
        Icons.lock_outline,
        Platform.isWindows
            ? tr('Nhập file .ovpn của nhà cung cấp VPN. Windows: YomiHub chuyển hồ sơ cho OpenVPN GUI ({p0}), đường hầm OpenVPN luôn áp cho toàn máy.', {'p0': WinVpnBackend.openVpnGui() == null ? tr('chưa cài – tải “OpenVPN Community” tại openvpn.net') : tr('đã cài')})
            : tr('Nhập file .ovpn của nhà cung cấp VPN (hoặc máy chủ OpenVPN của bạn).'),
      ),
      _profileSection(
        TunnelType.wireguard,
        Icons.shield_moon_outlined,
        Platform.isWindows
            ? tr('Nhập file .conf WireGuard. Windows: chạy trong lõi Xray của YomiHub (không cần driver, không cần quyền quản trị).')
            : tr('Nhập file .conf WireGuard.'),
      ),
      _softEtherSection(theme),
      _adguardSection(theme),
      _urbanSection(theme),
      _profileSection(
        TunnelType.xray,
        Icons.alt_route,
        tr('Mihon Proxy: dán link vless:// (REALITY), vmess://, trojan://, ss://. YomiHub chạy lõi Xray và đưa tiện ích, WebView và trình duyệt (theo phạm vi đã chọn) qua proxy cục bộ.'),
      ),
      _section(tr('Proxy riêng (thay cho HolaVPN)'), Icons.settings_ethernet, children: [
        ListTile(
          leading: Icon(YomiVpnState.proxyEnabled ? Icons.check_circle : Icons.circle_outlined,
              color: YomiVpnState.proxyEnabled ? Colors.green : null),
          title: const Text('Proxy HTTP(S) / SOCKS5'),
          subtitle: Text(YomiVpnState.proxyEnabled && YomiVpnState.proxyUrl.isNotEmpty
              ? _maskProxy(YomiVpnState.proxyUrl)
              : tr('Đã tắt – chạm để nhập proxy')),
          onTap: _editProxy,
        ),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: Text(tr('Kiểm tra proxy')),
          enabled: YomiVpnState.proxyUrl.isNotEmpty,
          onTap: () async => _snack(await vpn.testProxy()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            tr('HolaVPN không có mã nguồn hay API công khai để tích hợp. Bạn có thể nhập proxy của nhà cung cấp VPN/proxy mình dùng, hoặc proxy chạy trên máy tính của bạn.'),
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
        title: Text(tr('Mọi tiện ích')),
        subtitle: Text(tr('Kể cả ảnh bìa, trang truyện, luồng phim và tải xuống. Tắt để chọn riêng từng tiện ích.')),
        value: YomiVpnState.scopeAllSources,
        onChanged: (v) => vpn.setScopeAll(v),
      ),
      ListTile(
        leading: const Icon(Icons.checklist),
        title: Text(tr('Chọn tiện ích dùng VPN')),
        subtitle: Text(YomiVpnState.scopeAllSources
            ? tr('Đang áp dụng cho mọi tiện ích')
            : tr('{p0} tiện ích', {'p0': YomiVpnState.scopeSources.length})),
        enabled: !YomiVpnState.scopeAllSources,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const _ScopeSourcesScreen()))
            .then((_) => _refresh()),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.web_asset),
        title: Text(tr('Chế độ WebView')),
        subtitle: Text(tr('Màn hình WebView của tiện ích, xác minh Cloudflare, WebView ẩn của tiện ích')),
        value: YomiVpnState.scopeWebView,
        onChanged: (v) => vpn.setScopeWebView(v),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.public),
        title: Text(tr('Trình duyệt trong ứng dụng')),
        subtitle: Text(tr('Các tab Chromium của nút Trình duyệt')),
        value: YomiVpnState.scopeBrowser,
        onChanged: (v) => vpn.setScopeBrowser(v),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          Platform.isWindows
              ? tr('Windows: phạm vi này áp dụng cho Tor, WARP, WireGuard, Mihon Proxy và Proxy riêng. WebView2 (WebView, trình duyệt) nhận thay đổi sau khi khởi động lại YomiHub. OpenVPN/SoftEther mang toàn bộ máy.')
              : tr('Phạm vi này áp dụng cho Tor, Mihon Proxy và Proxy riêng. WARP, OpenVPN, WireGuard và SoftEther là đường hầm VPN: chúng mang toàn bộ kết nối của YomiHub (xem mục “Ứng dụng ngoài / toàn thiết bị”).'),
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
          child: Column(
            children: [
              RadioListTile(
                value: WarpMode.app,
                title: Text(tr('Chỉ YomiHub')),
                subtitle: Text(tr('Tiện ích, WebView và trình duyệt theo mục “VPN cho tiện ích”')),
              ),
              RadioListTile(
                value: WarpMode.device,
                title: Text(tr('Toàn bộ máy tính')),
                subtitle: Text(tr('Đặt proxy hệ thống của Windows (Edge, Chrome, Cốc Cốc và đa số ứng dụng)')),
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
              ? tr('Proxy hệ thống: 127.0.0.1:{p0}', {'p0': WinVpnBackend.httpPort})
              : tr('Proxy hệ thống: không dùng')),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            tr('Áp dụng cho Tor, Cloudflare WARP, WireGuard, Mihon Proxy và Proxy riêng (YomiHub chạy chúng qua lõi Xray tại 127.0.0.1:{p0}). Khi tắt dịch vụ hoặc đóng YomiHub, cài đặt proxy cũ của Windows được trả lại. Ứng dụng không dùng proxy hệ thống (một số game, ứng dụng UDP) sẽ không đi qua. OpenVPN / SoftEther qua OpenVPN GUI luôn áp cho toàn máy. Chọn từng ứng dụng riêng chỉ có trên Android.', {'p0': WinVpnBackend.httpPort}),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ];
    }
    return [
      RadioGroup<WarpMode>(
        groupValue: vpn.warpMode,
        onChanged: (m) => m == null ? null : _run(() => vpn.setWarpMode(m)),
        child: Column(
          children: [
            RadioListTile(value: WarpMode.app, title: Text(tr('Chỉ YomiHub'))),
            RadioListTile(
              value: WarpMode.apps,
              title: Text(tr('YomiHub và các ứng dụng đã chọn')),
              subtitle: Text(tr('Hỗ trợ từng ứng dụng cụ thể')),
            ),
            RadioListTile(
              value: WarpMode.device,
              title: Text(tr('Toàn bộ thiết bị')),
              subtitle: Text(tr('Mọi ứng dụng trên máy đi qua VPN')),
            ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.apps),
        title: Text(tr('Chọn ứng dụng')),
        subtitle: Text(tr('{p0} ứng dụng', {'p0': vpn.warpApps.length})),
        enabled: vpn.warpMode == WarpMode.apps,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const _WarpAppsScreen()))
            .then((_) => _refresh()),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          tr('Áp dụng cho Tor, Cloudflare WARP, OpenVPN, WireGuard và SoftEther (đang kết nối thì tự kết nối lại). Tor cho ứng dụng ngoài/toàn thiết bị chạy qua VPN của Android (tun2socks → cổng SOCKS của Tor, DNS phân giải qua Tor); YomiHub vẫn dùng Tor theo phạm vi trong app. Tor chỉ mang TCP: UDP khác (QUIC, game) không đi qua được. Mihon Proxy và Proxy riêng chỉ phục vụ YomiHub. Nếu file WireGuard .conf đã có IncludedApplications/ExcludedApplications thì giữ nguyên cấu hình đó.'),
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
        title: Text(tr('Chọn quốc gia')),
        subtitle: Text(vpnCountries[tun.country] ?? tun.country),
        onTap: _pickCountry,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          tr('Áp dụng cho: nút điểm ra của Tor, máy chủ SoftEther/VPN Gate được chọn tự động và hồ sơ OpenVPN / WireGuard / Mihon Proxy gắn quốc gia. Cloudflare WARP luôn dùng máy chủ gần nhất.'),
          style: theme.textTheme.bodySmall,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.bolt),
        title: Text(tr('Kết nối nhanh tới quốc gia này')),
        subtitle: Text(tr('Ưu tiên hồ sơ của bạn, nếu không có thì dùng máy chủ VPN Gate (SoftEther)')),
        onTap: () => _run(_quickConnect),
      ),
    ];
  }

  String _stateLabel(String s) => switch (s) {
        'connected' => tr('Đã kết nối'),
        'connecting' => tr('Đang kết nối…'),
        'error' => tr('Lỗi'),
        'disconnected' => tr('Đã ngắt'),
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
        title: Text(tr('Quốc gia đích đến')),
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
        _snack(tr('Không có máy chủ VPN Gate cho {p0}', {'p0': vpnCountries[cc] ?? cc}));
        return;
      }
      if (!await _guard(VpnKind.softether)) return;
      final err = await tun.connectVpnGate(s);
      if (err != null) {
        yomiLogVpnError('VPN Gate (SoftEther)', err);
        _snack(err);
      }
    } catch (e) {
      yomiLogVpnError('Tải danh sách VPN Gate', e);
      _snack(tr('Không tải được danh sách VPN Gate: {p0}', {'p0': e}));
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
      subtitle: activeHere ? '${_stateLabel(tun.state)} • ${tun.active!.name}' : tr('{p0} hồ sơ', {'p0': list.length}),
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
            subtitle: Text(tun.activeId == p.id ? _stateLabel(tun.state) : (vpnCountries[p.country] ?? tr('Chưa gắn quốc gia'))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: tun.activeId == p.id ? tr('Ngắt') : tr('Kết nối'),
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
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(tr('Gắn quốc gia'))),
                    PopupMenuItem(value: 1, child: Text(tr('Đổi tên / tài khoản'))),
                    PopupMenuItem(value: 2, child: Text(tr('Xoá'))),
                  ],
                  onSelected: (v) async {
                    if (v == 0) {
                      final cc = await showDialog<String>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: Text(tr('Quốc gia của máy chủ')),
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
              label: Text(type == TunnelType.xray ? tr('Dán link') : tr('Dán cấu hình')),
              onPressed: () => _importPaste(type),
            ),
            if (type != TunnelType.xray)
              TextButton.icon(
                icon: const Icon(Icons.file_open_outlined),
                label: Text(tr('Chọn file')),
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
          : tr('VPN Gate + máy chủ SoftEther của bạn'),
      children: [
        SwitchListTile(
          title: Text(tr('Tự động đổi máy chủ SoftEther')),
          subtitle: Text(tr('Chuyển sang máy chủ khác trong cùng nhóm khi đang kết nối. Kết nối có thể bị gián đoạn.')),
          value: vpn.autoSoftEtherServer,
          onChanged: (v) => vpn.setRotation('autoSoftEtherServer', v),
        ),
        if (vpn.autoSoftEtherServer)
          _rotationInterval(tr('Thời gian đổi máy chủ'), vpn.softEtherMinutes, 'softEtherMinutes'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            tr('Kết nối tới máy chủ SoftEther qua giao thức OpenVPN: mạng VPN Gate công khai (Đại học Tsukuba) hoặc máy chủ SoftEther của bạn (xuất file .ovpn trong SoftEther Server Manager › OpenVPN / MS-SSTP).'),
            style: theme.textTheme.bodySmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: Text(servers == null ? tr('Tải danh sách máy chủ VPN Gate') : tr('Làm mới danh sách ({p0} máy chủ)', {'p0': servers.length})),
          subtitle: Text(tr('Lọc theo: {p0} {p1}', {'p0': countryFlag(cc), 'p1': vpnCountries[cc] ?? cc})),
          onTap: () => _run(() async {
            try {
              await tun.loadVpnGate(force: true);
            } catch (e) {
              yomiLogVpnError('Tải danh sách VPN Gate', e);
              _snack(tr('Không tải được VPN Gate: {p0}', {'p0': e}));
            }
          }),
        ),
        for (final s in shown)
          ListTile(
            dense: true,
            leading: Text(countryFlag(s.countryCode), style: const TextStyle(fontSize: 20)),
            title: Text(s.host),
            subtitle: Text(tr('{p0} • ping {p1} ms • {p2} Mbps • {p3} phiên', {'p0': s.country, 'p1': s.ping, 'p2': (s.speed / 1e6).toStringAsFixed(1), 'p3': s.sessions})),
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
            subtitle: Text(tun.activeId == p.id ? _stateLabel(tun.state) : tr('Máy chủ SoftEther của bạn')),
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
          label: Text(tr('Thêm máy chủ SoftEther (.ovpn)')),
          onPressed: () => _importFile(TunnelType.softether),
        ),
      ],
    );
  }

  // ───────── 0.1.8: AdGuard VPN ─────────
  bool? _systemVpn;

  Widget _adguardSection(ThemeData theme) {
    final on = YomiExtVpn.adguardSocksOn;
    return _section(
      'AdGuard VPN',
      Icons.verified_user_outlined,
      subtitle: on
          ? tr('Chỉ YomiHub • SOCKS5 {p0}:{p1}', {'p0': YomiExtVpn.adguardHost, 'p1': YomiExtVpn.adguardPort})
          : (_systemVpn == true ? tr('VPN của thiết bị đang bật') : tr('Đã tắt')),
      children: [
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: Text(tr('Mở AdGuard VPN (toàn thiết bị)')),
          subtitle: Text(tr('Đăng nhập, chọn vị trí và bật VPN trong ứng dụng AdGuard VPN chính thức. Nếu chưa cài, YomiHub mở trang tải về.')),
          onTap: () async {
            await YomiExtVpn.openAdGuard();
          },
        ),
        ListTile(
          leading: const Icon(Icons.radar),
          title: Text(tr('Kiểm tra VPN của thiết bị')),
          subtitle: Text(_systemVpn == null
              ? tr('Xem AdGuard VPN (hoặc VPN khác) có đang bật trên thiết bị không')
              : (_systemVpn! ? tr('Đang có VPN bật trên thiết bị') : tr('Chưa có VPN nào bật'))),
          onTap: () async {
            final v = await YomiExtVpn.systemVpnActive(nameHint: Platform.isWindows ? 'adguard' : null);
            setState(() => _systemVpn = v);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.settings_ethernet),
          title: Text(tr('Chỉ YomiHub qua AdGuard VPN (SOCKS5)')),
          subtitle: Text(tr('Bật chế độ SOCKS5 trong AdGuard VPN rồi bật mục này: tiện ích, WebView, trình duyệt và tải xuống đi qua 127.0.0.1:{p0} (theo mục “VPN cho tiện ích…”).', {'p0': YomiExtVpn.adguardPort})),
          value: on,
          onChanged: (v) => _run(() async {
            if (v && !await _guard(VpnKind.adguard)) return;
            final e = await YomiExtVpn.setAdGuardSocks(v);
            if (e != null) _snack(e);
          }),
        ),
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(tr('Cổng SOCKS5 của AdGuard VPN')),
          subtitle: Text('${YomiExtVpn.adguardHost}:${YomiExtVpn.adguardPort}'),
          onTap: () async {
            final hostCtrl = TextEditingController(text: YomiExtVpn.adguardHost);
            final portCtrl = TextEditingController(text: '${YomiExtVpn.adguardPort}');
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(tr('SOCKS5 của AdGuard VPN')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: hostCtrl, decoration: InputDecoration(labelText: tr('Máy (thường là 127.0.0.1)'))),
                    TextField(
                      controller: portCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: tr('Cổng (xem trong Cài đặt › Chế độ của AdGuard VPN)')),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Hủy'))),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Lưu'))),
                ],
              ),
            );
            if (ok != true) return;
            final port = int.tryParse(portCtrl.text.trim());
            if (port == null || port <= 0 || port > 65535) {
              _snack(tr('Cổng không hợp lệ'));
              return;
            }
            final e = await YomiExtVpn.setAdGuardSocks(YomiExtVpn.adguardSocksOn, host: hostCtrl.text, port: port);
            if (e != null) _snack(e);
            _refresh();
          },
        ),
        ListTile(
          leading: const Icon(Icons.block),
          title: Text(tr('Bộ lọc quảng cáo AdGuard')),
          subtitle: Text(tr('AdGuard Base / Mobile / Tracking / Annoyances / Vietnamese đã có trong AdBlock của YomiHub')),
        ),
      ],
    );
  }

  // ───────── 0.1.8: Urban VPN ─────────
  bool? _urbanReady;

  Widget _urbanSection(ThemeData theme) {
    final active = tun.active;
    final on = active != null && active.id.startsWith('urban_');
    if (_urbanReady == null) {
      YomiExtVpn.urbanImported.then((v) {
        if (mounted) setState(() => _urbanReady = v);
      });
    }
    return _section(
      'Urban VPN',
      Icons.travel_explore,
      subtitle: on ? '${active.name} • ${_stateLabel(tun.state)}' : tr('Đã tắt'),
      children: [
        if (_urbanReady == true) ...[
          ListTile(
            leading: Text(countryFlag(YomiExtVpn.urbanCountry == 'uk' ? 'GB' : YomiExtVpn.urbanCountry.toUpperCase()),
                style: const TextStyle(fontSize: 22)),
            title: Text(tr('Vị trí')),
            subtitle: Text(vpnCountries[YomiExtVpn.urbanCountry.toUpperCase()] ?? YomiExtVpn.urbanCountry.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickUrbanLocation,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.power_settings_new),
            title: Text(tr('Kết nối Urban VPN')),
            subtitle: Text(on ? _stateLabel(tun.state) : tr('Kết nối bằng lõi OpenVPN của YomiHub')),
            value: on,
            onChanged: (v) => _run(() async {
              if (!v) {
                await tun.disconnect();
                return;
              }
              if (!await _guard(VpnKind.urban)) return;
              final e = await YomiExtVpn.connectUrban(YomiExtVpn.urbanCountry);
              if (e != null) _snack(e);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(tr('Xoá cấu hình Urban VPN đã nhập')),
            onTap: () async {
              await YomiExtVpn.forgetUrban();
              setState(() => _urbanReady = false);
            },
          ),
        ] else
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: Text(tr('Nhập cấu hình Urban VPN')),
            subtitle: Text(Platform.isWindows
                ? tr('Từ Urban VPN Desktop đã cài (tự tìm file .ovpn) hoặc chọn file .ovpn + tài khoản Urban VPN của bạn')
                : tr('Chọn file .ovpn (lấy từ Urban VPN Desktop) và nhập tài khoản Urban VPN của bạn')),
            onTap: _importUrban,
          ),
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: Text(tr('Mở ứng dụng Urban VPN (toàn thiết bị)')),
          onTap: () => YomiExtVpn.openUrban(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Text(
            tr('Giống dự án Urban Proxy: YomiHub dùng cấu hình và tài khoản Urban VPN của chính bạn, lưu trong kho bảo mật của thiết bị, không gửi đi đâu. Danh sách 83 vị trí là bản chụp {p0}.', {'p0': YomiExtVpn.snapshot}),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _importUrban() async {
    String? text;
    if (Platform.isWindows) {
      final found = await YomiExtVpn.findUrbanOvpnWindows();
      if (found != null) {
        try {
          text = await File(found).readAsString();
        } catch (_) {}
      }
    }
    if (text == null) {
      final r = await FilePicker.pickFiles();
      final f = r.firstOrNull;
      if (f == null || f.path == null) return;
      text = await File(f.path!).readAsString();
    }
    final user = TextEditingController();
    final pass = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Tài khoản Urban VPN')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: user, decoration: InputDecoration(labelText: tr('Tên đăng nhập'))),
            TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: tr('Mật khẩu'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Hủy'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Lưu'))),
        ],
      ),
    );
    if (ok != true) return;
    final e = await YomiExtVpn.importUrban(text, username: user.text, password: pass.text);
    if (e != null) {
      _snack(e);
      return;
    }
    setState(() => _urbanReady = true);
    _snack(tr('Đã nhập cấu hình Urban VPN'));
  }

  Future<void> _pickUrbanLocation() async {
    final all = await YomiExtVpn.locations();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: ListView(
          children: [
            for (final l in all)
              ListTile(
                leading: Text(countryFlag(l.country), style: const TextStyle(fontSize: 22)),
                title: Text(vpnCountries[l.country] ?? (l.name.isEmpty ? l.country : l.name)),
                subtitle: Text('${l.group} • ${l.host}'),
                selected: l.cc == YomiExtVpn.urbanCountry,
                onTap: () => Navigator.pop(ctx, l.cc),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await YomiPrefs.set('urbanCountry', picked);
    final active = tun.active;
    if (active != null && active.id.startsWith('urban_')) {
      await _run(() async {
        final e = await YomiExtVpn.connectUrban(picked);
        if (e != null) _snack(e);
      });
    }
    _refresh();
  }

  Widget _rotationInterval(String title, int value, String key) {
    final values = <int>{1, 5, 10, 15, 30, 60, value}.toList()..sort();
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<int>(
        value: value,
        items: [for (final minutes in values)
          DropdownMenuItem(value: minutes, child: Text(tr('{p0} phút', {'p0': minutes})))],
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
        title: Text(tr('Thêm {p0}', {'p0': type.label})),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: type == TunnelType.xray ? tr('vless://… (mỗi dòng một link)') : tr('Dán nội dung cấu hình'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Huỷ'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(tr('Thêm'))),
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
        if (err != null) {
          yomiLogVpnError('Nhập cấu hình ${f.name}', err);
          _snack('${f.name}: $err');
        }
      } catch (e) {
        yomiLogVpnError('Nhập cấu hình ${f.name}', e);
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
        title: Text(tr('Hồ sơ VPN')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: tr('Tên'))),
            if (p.type == TunnelType.openvpn || p.type == TunnelType.softether) ...[
              TextField(controller: user, decoration: InputDecoration(labelText: tr('Tài khoản (nếu có)'))),
              TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: tr('Mật khẩu (nếu có)'))),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Huỷ'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Lưu'))),
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
        ItemType.manga => YomiTr.term(0),
        ItemType.anime => YomiTr.term(1),
        ItemType.novel => YomiTr.term(2),
      };

  @override
  Widget build(BuildContext context) {
    final list = _all.where((s) => (s.name ?? '').toLowerCase().contains(_q.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(hintText: tr('Tìm tiện ích…'), border: InputBorder.none),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: list.isEmpty
          ? Center(child: Text(tr('Chưa cài tiện ích nào')))
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
            decoration: InputDecoration(hintText: tr('Tìm ứng dụng…'), border: InputBorder.none),
            onChanged: (v) => setState(() => _q = v),
          ),
          actions: [
            IconButton(
              tooltip: tr('Hiện ứng dụng hệ thống'),
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
