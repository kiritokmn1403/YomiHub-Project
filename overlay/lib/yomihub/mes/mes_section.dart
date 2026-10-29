import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/settings/browse/extension_server/android_proxy_server_dialog.dart';
import 'package:mangayomi/modules/more/settings/browse/extension_server/extension_server_tiles.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/services/m_extension_server.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

/// Settings › Browse › M-Extension-Server – Android and (0.1.7) Windows.
///
/// * Android: the built-in Dalvik bridge (also usable by other devices on
///   the LAN, ApkBridge-compatible).
/// * Windows: the desktop M-Extension-Server (Java) run by YomiHub itself –
///   bundled with the full package or installed with one tap – or
///   "ApkBridge": a phone running YomiHub / the ApkBridge app on the LAN.
class YomiMesSection extends ConsumerStatefulWidget {
  const YomiMesSection({super.key});

  @override
  ConsumerState<YomiMesSection> createState() => _YomiMesSectionState();
}

class _YomiMesSectionState extends ConsumerState<YomiMesSection> {
  bool _busy = false;
  bool? _alive;
  bool _embedded = true;
  bool _installed = true;
  double? _progress;
  String _progressText = '';
  List<String>? _lan;

  bool get _win => Platform.isWindows;

  @override
  void initState() {
    super.initState();
    YomiMes.open().then((_) async {
      if (_win) _installed = await YomiMes.locateWindows(jre: YomiMes.configuredJre, jar: YomiMes.configuredJar);
      if (!mounted) return;
      setState(() => _embedded = YomiMes.embedded);
      _check();
    });
  }

  String get _currentUrl {
    final url = ref.read(androidProxyServerStateProvider);
    if (_embedded) return YomiMes.baseUrl ?? url;
    return YomiMes.remoteUrl.isNotEmpty ? YomiMes.remoteUrl : url;
  }

  Future<void> _check() async {
    final ok = _embedded ? await YomiMes.alive(_currentUrl) : await YomiMes.aliveAny(_currentUrl);
    if (mounted) setState(() => _alive = ok);
  }

  Future<void> _restart() async {
    setState(() => _busy = true);
    await YomiMes.ensure(restart: true);
    if (YomiMes.baseUrl != null) {
      ref.read(androidProxyServerStateProvider.notifier).set(YomiMes.baseUrl!);
    }
    await _check();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggle(bool v) async {
    setState(() {
      _busy = true;
      _embedded = v;
    });
    await YomiMes.setEmbedded(v);
    if (v) {
      await MExtensionServerPlatform(ref).startServer(force: true);
    } else if (YomiMes.remoteUrl.isNotEmpty) {
      ref.read(androidProxyServerStateProvider.notifier).set(YomiMes.remoteUrl);
    }
    await _check();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _progress = 0;
      _progressText = tr('Đang tìm bản mới nhất…');
    });
    final err = await YomiMes.installWindows(
      progress: (got, total) {
        if (!mounted) return;
        setState(() {
          _progress = total > 0 ? got / total : null;
          _progressText = '${(got / 1048576).toStringAsFixed(1)}'
              '${total > 0 ? ' / ${(total / 1048576).toStringAsFixed(1)}' : ''} MB';
        });
      },
    );
    _installed = err == null;
    if (err == null) {
      _progressText = tr('Đang khởi động…');
      if (mounted) setState(() {});
      await MExtensionServerPlatform(ref).startServer(force: true);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _progressText = err == null ? '' : tr('Lỗi: {p0}', {'p0': err});
    });
    await _check();
  }

  Future<void> _setRemote(String server) async {
    await YomiMes.setRemoteUrl(server);
    ref.read(androidProxyServerStateProvider.notifier).set(server);
    await _check();
  }

  Future<void> _scanLan() async {
    setState(() {
      _busy = true;
      _progress = 0;
      _progressText = tr('Đang tìm ApkBridge / YomiHub trong mạng…');
      _lan = null;
    });
    final found = await YomiMes.scanLan(
      progress: (v) {
        if (mounted) setState(() => _progress = v);
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _progressText = found.isEmpty ? tr('Không thấy máy chủ nào (cổng 47321 / 8080) trong mạng.') : '';
      _lan = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(androidProxyServerStateProvider);
    final secondary = TextStyle(color: context.secondaryColor);
    final title = TextStyle(fontSize: 13, color: context.primaryColor);
    final routed = YomiVpnState.proxyFor(null);
    final shown = _currentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_win ? 'M-Extension-Server + ApkBridge (Windows)' : tr('M-Extension-Server + ApkBridge tích hợp'), style: title),
        const SizedBox(height: 8),
        Text(
          _win
              ? tr('Tiện ích APK của Mihon / Tachiyomi / Komikku và Aniyomi / Anikku / Nekoyomi chạy bằng M-Extension-Server (Java) do YomiHub tự chạy và tự tắt – không cần cài riêng, không hiện cửa sổ dòng lệnh. Máy chủ chỉ khởi động khi bạn có tiện ích APK. Hoặc dùng ApkBridge: YomiHub trên điện thoại (hoặc app ApkBridge) trong cùng mạng Wi-Fi.')
              : tr('Tiện ích APK của Mihon / Tachiyomi / Komikku và Aniyomi / Anikku / Nekoyomi chạy thẳng trong YomiHub (nạp lớp Dalvik ngay trong ứng dụng). Không cần cài ứng dụng MExtension Server hay Mangayomi ApkBridge riêng: máy chủ tích hợp dùng đúng giao thức /dalvik của ApkBridge, nên YomiHub / Mangayomi trên máy tính cùng mạng có thể dùng địa chỉ bên dưới làm ApkBridge.'),
          style: secondary,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_win ? tr('Chạy máy chủ trên máy tính này') : tr('Dùng máy chủ tích hợp')),
          subtitle: Text(_win
              ? tr('Tắt để dùng ApkBridge (điện thoại / máy khác trong mạng)')
              : tr('Tắt nếu bạn muốn dùng một máy chủ ngoài')),
          value: _embedded,
          onChanged: _busy ? null : _toggle,
        ),
        if (_win && _embedded && !_installed)
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: Text(tr('Chưa có M-Extension-Server')),
              subtitle: Text(tr('Cài tự động bản mới nhất từ GitHub (JRE + máy chủ, khoảng 130 MB)')),
              trailing: FilledButton(onPressed: _busy ? null : _install, child: Text(tr('Cài tự động'))),
            ),
          ),
        if (_progress != null || _progressText.isNotEmpty) ...[
          const SizedBox(height: 6),
          if (_busy) LinearProgressIndicator(value: _progress),
          if (_progressText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_progressText, style: secondary),
            ),
        ],
        ExtensionServerStatusTile(
          label: _embedded ? (_win ? tr('Máy chủ trên máy này') : tr('Máy chủ tích hợp')) : (_win ? 'ApkBridge' : tr('Máy chủ ngoài')),
          value: _alive == null
              ? tr('Đang kiểm tra…')
              : (_alive! ? tr('Đang chạy · {p0}', {'p0': shown}) : tr('Không phản hồi · {p0}', {'p0': shown})),
          exists: _alive ?? false,
        ),
        if (_win && _embedded && _installed && YomiMes.winJar.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(YomiMes.winJar, style: secondary.copyWith(fontSize: 11)),
        ],
        if (_embedded && YomiMes.restarts > 0) ...[
          const SizedBox(height: 6),
          Text(tr('Đã tự khởi động lại {p0} lần', {'p0': YomiMes.restarts}), style: secondary),
        ],
        if (YomiMes.lastError != null && _embedded) ...[
          const SizedBox(height: 6),
          Text(YomiMes.lastError!, style: const TextStyle(color: Colors.orange)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _check,
              icon: const Icon(Icons.wifi_tethering),
              label: Text(tr('Kiểm tra')),
            ),
            if (_embedded)
              OutlinedButton.icon(
                onPressed: _busy || (_win && !_installed) ? null : _restart,
                icon: const Icon(Icons.restart_alt),
                label: Text(tr('Khởi động lại')),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: () => showAndroidProxyServerDialog(
                  context,
                  proxyServer: _currentUrl,
                  onConfirm: _setRemote,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(tr('Địa chỉ ApkBridge')),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _scanLan,
                icon: const Icon(Icons.radar),
                label: Text(tr('Tìm trong mạng LAN')),
              ),
            ],
            if (_win && _embedded && _installed)
              TextButton.icon(
                onPressed: _busy ? null : _install,
                icon: const Icon(Icons.system_update_alt),
                label: Text(tr('Cập nhật máy chủ')),
              ),
          ],
        ),
        if (_lan != null && _lan!.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final u in _lan!)
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone_android),
              title: Text(u),
              subtitle: Text(u.endsWith(':8080') ? 'ApkBridge' : 'YomiHub / M-Extension-Server'),
              trailing: TextButton(onPressed: () => _setRemote(u), child: Text(tr('Dùng'))),
            ),
        ],
        if (_embedded && YomiMes.baseUrl != null) ...[
          const SizedBox(height: 6),
          FutureBuilder<List<NetworkInterface>>(
            future: NetworkInterface.list(type: InternetAddressType.IPv4),
            builder: (context, snap) {
              final port = Uri.tryParse(YomiMes.baseUrl!)?.port ?? YomiMes.preferredPort;
              final ips = (snap.data ?? const <NetworkInterface>[])
                  .expand((i) => i.addresses)
                  .where((a) => !a.isLoopback)
                  .map((a) => 'http://${a.address}:$port')
                  .toList();
              return Text(
                ips.isEmpty
                    ? tr('ApkBridge: chỉ trên máy này')
                    : tr('ApkBridge cho máy khác trong mạng: {p0}', {'p0': ips.join(', ')}),
                style: secondary,
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        Text(
          routed != null
              ? tr('Mạng của tiện ích APK đang đi qua: {p0} (VPN & DNS › VPN cho tiện ích).', {'p0': routed})
              : tr('Mạng của tiện ích APK đi thẳng. Bật một dịch vụ trong VPN & DNS (phạm vi “Mọi tiện ích”) để định tuyến.'),
          style: secondary,
        ),
      ],
    );
  }
}
