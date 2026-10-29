import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:mangayomi/yomihub/vpn/vpn_tunnels.dart';

/// "Ứng dụng bên ngoài / toàn bộ thiết bị": which apps a VPN tunnel
/// (WARP, OpenVPN, WireGuard, SoftEther) carries. Kept under the old
/// `warpMode` name/keys so 0.1.4 settings carry over.
enum WarpMode { app, apps, device }

/// The VPN services in "VPN & DNS › Dịch vụ VPN". Only one may be on.
enum VpnKind { tor, warp, openvpn, wireguard, softether, xray, proxy }

extension VpnKindLabel on VpnKind {
  String get label => switch (this) {
        VpnKind.tor => 'Tor',
        VpnKind.warp => 'Cloudflare WARP',
        VpnKind.openvpn => 'OpenVPN',
        VpnKind.wireguard => 'WireGuard',
        VpnKind.softether => 'SoftEther VPN',
        VpnKind.xray => 'Mihon Proxy (Xray)',
        VpnKind.proxy => 'Proxy riêng',
      };

  /// Proxy-type services only reach YomiHub's own connections.
  bool get isProxy => this == VpnKind.tor || this == VpnKind.xray || this == VpnKind.proxy;
}

class InstalledApp {
  final String package;
  final String label;
  final bool system;
  InstalledApp(this.package, this.label, this.system);
}

/// YomiHub "VPN & DNS": one VPN service at a time (Tor, WARP, OpenVPN,
/// WireGuard, SoftEther, Mihon Proxy, custom proxy), an in-app scope
/// (extensions / WebView / browser), an outside-apps scope (YomiHub only,
/// chosen apps, whole device) and the destination country.
class YomiVpnService extends ChangeNotifier {
  YomiVpnService._();
  static final instance = YomiVpnService._();

  static const _channel = MethodChannel('yomihub/vpn');
  static const _boxName = 'yomihub_vpn';
  Box? _box;

  String torStatus = 'OFF';
  bool warpEnabled = false;
  bool warpUp = false;
  WarpMode warpMode = WarpMode.app;
  List<String> warpApps = [];
  String? lastError;

  bool get supported => Platform.isAndroid;

  String? _jvmProxy = '';

  /// Keeps the built-in M-Extension-Server's JVM traffic on the same route
  /// (Tor / custom proxy) when it is applied to every source.
  void _syncJvmProxy() {
    final p = YomiVpnState.proxyFor(null);
    if (p == _jvmProxy) return;
    _jvmProxy = p;
    YomiMes.setJvmProxy(p);
  }

  Future<void> init() async {
    if (_box != null) return;
    addListener(_syncJvmProxy);
    YomiTunnels.instance.addListener(() {
      _syncJvmProxy();
      _applyBrowserProxy();
      notifyListeners();
    });
    YomiTunnels.bypassProvider = tunnelBypass;
    YomiTunnels.wireguardScope = wireguardScoped;
    unawaited(YomiTunnels.instance.init());
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      return;
    }
    final b = _box!;
    YomiVpnState.torEnabled = b.get('torEnabled', defaultValue: false);
    YomiVpnState.killSwitch = b.get('killSwitch', defaultValue: true);
    YomiVpnState.proxyEnabled = b.get('proxyEnabled', defaultValue: false);
    YomiVpnState.proxyUrl = b.get('proxyUrl', defaultValue: '');
    _loadScope(b);
    _syncJvmProxy();
    warpEnabled = b.get('warpEnabled', defaultValue: false);
    warpMode = WarpMode.values[(b.get('warpMode', defaultValue: 0) as int).clamp(0, 2)];
    warpApps = (b.get('warpApps', defaultValue: <dynamic>[]) as List).cast<String>();
    YomiVpnState.bump();
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'torStatus':
          torStatus = call.arguments as String;
          if (torStatus == 'OFF') {
            YomiVpnState.torRunning = false;
            YomiVpnState.bump();
          }
          notifyListeners();
        case 'warpState':
          warpUp = call.arguments as bool;
          notifyListeners();
      }
      return null;
    });
    if (YomiVpnState.torEnabled) {
      // don't block startup
      startTor();
    }
    if (warpEnabled) {
      try {
        warpUp = await _channel.invokeMethod<bool>('warpState') ?? false;
      } catch (_) {}
    }
  }

  Future<void> _put(String k, Object v) async => _box?.put(k, v);

  // ───────────── Tor ─────────────

  Future<void> setTorEnabled(bool v) async {
    YomiVpnState.torEnabled = v;
    await _put('torEnabled', v);
    YomiVpnState.bump();
    notifyListeners();
    if (v) {
      await startTor();
    } else {
      await stopTor();
    }
  }

  /// Extra torrc lines: exit country chosen in "Quốc gia đích đến".
  Future<void> _writeTorrc() async {
    final cc = YomiTunnels.instance.country.toLowerCase();
    // StrictNodes 0: prefer exits in that country, but never leave Tor
    // without a circuit when the country has few or no exit relays.
    final text = cc.isEmpty ? '' : 'ExitNodes {$cc}\nStrictNodes 0\n';
    try {
      await const MethodChannel('yomihub/tunnels').invokeMethod('torrc', {'text': text});
    } catch (_) {}
  }

  /// Re-applies the destination country to Tor (restarts it when running).
  Future<void> applyCountry() async {
    if (!supported) return;
    await _writeTorrc();
    if (YomiVpnState.torEnabled && YomiVpnState.torRunning) {
      // tor cannot be restarted inside the app process: change the exit
      // country live through the control port instead.
      try {
        await _channel.invokeMethod('torExitNodes', {'country': YomiTunnels.instance.country});
      } catch (_) {}
    }
  }

  Future<void> startTor() async {
    if (!supported) return;
    torStatus = 'STARTING';
    notifyListeners();
    await _writeTorrc();
    try {
      final info = Map<String, dynamic>.from(await _channel.invokeMethod('torStart') as Map);
      YomiVpnState.torHttpPort = (info['httpPort'] as num?)?.toInt() ?? 0;
      YomiVpnState.torSocksPort = (info['socksPort'] as num?)?.toInt() ?? 0;
      torStatus = '${info['status']}';
      YomiVpnState.torRunning = torStatus == 'ON' && YomiVpnState.torHttpPort > 0;
      lastError = YomiVpnState.torRunning ? null : 'Tor chưa kết nối được (có thể mạng đang chặn Tor).';
    } catch (e) {
      lastError = '$e';
      torStatus = 'OFF';
      YomiVpnState.torRunning = false;
    }
    YomiVpnState.bump();
    await _applyBrowserProxy();
    notifyListeners();
  }

  Future<void> stopTor() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('torStop');
    } catch (_) {}
    YomiVpnState.torRunning = false;
    torStatus = 'OFF';
    YomiVpnState.bump();
    await _applyBrowserProxy();
    notifyListeners();
  }

  Future<bool> newIdentity() async {
    try {
      return await _channel.invokeMethod<bool>('torNewIdentity') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ───────────── Custom proxy ─────────────

  /// Returns an error message, or null when saved.
  Future<String?> setProxy({required bool enabled, required String url}) async {
    final norm = YomiVpnState.normaliseProxy(url);
    if (enabled && norm.isEmpty) {
      return 'Địa chỉ proxy không hợp lệ. Ví dụ: 1.2.3.4:8080, user:pass@host:3128, socks5://host:1080';
    }
    YomiVpnState.proxyEnabled = enabled;
    YomiVpnState.proxyUrl = norm;
    await _put('proxyEnabled', enabled);
    await _put('proxyUrl', norm);
    YomiVpnState.bump();
    await _applyBrowserProxy();
    notifyListeners();
    return null;
  }

  /// Quick reachability test through the proxy (returns the exit IP).
  Future<String> testProxy() async {
    final url = YomiVpnState.proxyUrl;
    if (url.isEmpty) return 'Chưa nhập proxy';
    final u = Uri.parse(url);
    if (u.scheme.startsWith('socks')) {
      return 'Proxy SOCKS5 được dùng cho tiện ích; hãy mở thử một tiện ích để kiểm tra.';
    }
    final hc = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    hc.findProxy = (_) => 'PROXY ${u.host}:${u.port}';
    if (u.userInfo.isNotEmpty) {
      final parts = u.userInfo.split(':');
      hc.addProxyCredentials(u.host, u.port, '', HttpClientBasicCredentials(
        Uri.decodeComponent(parts.first),
        parts.length > 1 ? Uri.decodeComponent(parts.sublist(1).join(':')) : '',
      ));
    }
    try {
      final req = await hc.getUrl(Uri.parse('https://api.ipify.org?format=json'));
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      return 'Kết nối được • IP ra ngoài: ${jsonDecode(body)['ip']}';
    } catch (e) {
      return 'Không kết nối được: $e';
    } finally {
      hc.close(force: true);
    }
  }

  Future<void> setKillSwitch(bool v) async {
    YomiVpnState.killSwitch = v;
    await _put('killSwitch', v);
    YomiVpnState.bump();
    notifyListeners();
  }

  // ───────────── In-app scope (extensions / WebView / browser) ─────────────

  void _loadScope(Box b) {
    if (b.containsKey('scopeAll')) {
      YomiVpnState.scopeAllSources = b.get('scopeAll') as bool;
      YomiVpnState.scopeSources =
          ((b.get('scopeSources', defaultValue: <dynamic>[]) as List).cast<int>()).toSet();
      YomiVpnState.scopeWebView = b.get('scopeWebView', defaultValue: true) as bool;
      YomiVpnState.scopeBrowser = b.get('scopeBrowser', defaultValue: true) as bool;
      return;
    }
    // 0.1.4 → 0.1.5: merge the separate Tor / proxy / Xray choices.
    final torOn = b.get('torEnabled', defaultValue: false) as bool;
    final torAll = b.get('torAll', defaultValue: false) as bool;
    final proxyAll = b.get('proxyAll', defaultValue: true) as bool;
    final torSrc = (b.get('torSources', defaultValue: <dynamic>[]) as List).cast<int>();
    final proxySrc = (b.get('proxySources', defaultValue: <dynamic>[]) as List).cast<int>();
    final web = (b.get('torBrowser', defaultValue: false) as bool) ||
        (b.get('proxyBrowser', defaultValue: false) as bool) ||
        (b.get('xrayBrowser', defaultValue: true) as bool);
    YomiVpnState.scopeAllSources = torOn ? torAll : proxyAll;
    YomiVpnState.scopeSources = {...torSrc, ...proxySrc};
    YomiVpnState.scopeWebView = web;
    YomiVpnState.scopeBrowser = web;
    _saveScope();
  }

  void _saveScope() {
    _box?.put('scopeAll', YomiVpnState.scopeAllSources);
    _box?.put('scopeSources', YomiVpnState.scopeSources.toList());
    _box?.put('scopeWebView', YomiVpnState.scopeWebView);
    _box?.put('scopeBrowser', YomiVpnState.scopeBrowser);
  }

  Future<void> setScopeAll(bool v) async {
    YomiVpnState.scopeAllSources = v;
    _saveScope();
    YomiVpnState.bump();
    notifyListeners();
  }

  bool isSourceInScope(int id) => YomiVpnState.scopeSources.contains(id);

  Future<void> setSourceInScope(int id, bool v) async {
    v ? YomiVpnState.scopeSources.add(id) : YomiVpnState.scopeSources.remove(id);
    _saveScope();
    YomiVpnState.bump();
    notifyListeners();
  }

  Future<void> setScopeWebView(bool v) async {
    YomiVpnState.scopeWebView = v;
    _saveScope();
    await _applyBrowserProxy();
    notifyListeners();
  }

  Future<void> setScopeBrowser(bool v) async {
    YomiVpnState.scopeBrowser = v;
    _saveScope();
    await _applyBrowserProxy();
    notifyListeners();
  }

  /// The in-app browser tells us when it is on screen: WebView proxying is
  /// process-wide on Android, so the browser and "WebView mode" take turns.
  bool _browserForeground = false;
  Future<void> setBrowserForeground(bool v) async {
    if (_browserForeground == v) return;
    _browserForeground = v;
    await _applyBrowserProxy();
  }

  // ───────────── One service at a time ─────────────

  List<VpnKind> activeKinds() {
    final t = YomiTunnels.instance.active;
    return [
      if (YomiVpnState.torEnabled) VpnKind.tor,
      if (warpEnabled) VpnKind.warp,
      if (t != null)
        switch (t.type) {
          TunnelType.openvpn => VpnKind.openvpn,
          TunnelType.wireguard => VpnKind.wireguard,
          TunnelType.softether => VpnKind.softether,
          TunnelType.xray => VpnKind.xray,
        },
      if (YomiVpnState.proxyEnabled && YomiVpnState.proxyUrl.isNotEmpty) VpnKind.proxy,
    ];
  }

  /// Services that would have to be switched off before [k] can start.
  List<VpnKind> conflictsWith(VpnKind k) => activeKinds().where((a) => a != k).toList();

  /// Turns every service except [keep] off.
  Future<void> stopAllExcept(VpnKind keep) async {
    for (final k in conflictsWith(keep)) {
      switch (k) {
        case VpnKind.tor:
          await setTorEnabled(false);
        case VpnKind.warp:
          await setWarpEnabled(false);
        case VpnKind.openvpn:
        case VpnKind.wireguard:
        case VpnKind.softether:
        case VpnKind.xray:
          await YomiTunnels.instance.disconnect();
        case VpnKind.proxy:
          await setProxy(enabled: false, url: YomiVpnState.proxyUrl);
      }
    }
  }

  // ───────────── Outside apps / whole device ─────────────

  /// OpenVPN (ics-openvpn) takes a list of *excluded* packages: everything
  /// except the chosen apps (or except YomiHub) is excluded.
  Future<List<String>> tunnelBypass() async {
    if (warpMode == WarpMode.device) return const [];
    final own = await _channel.invokeMethod<String>('packageName') ?? 'com.yomihub.app';
    final keep = warpMode == WarpMode.app ? {own} : {own, ...warpApps};
    final all = await installedApps(includeAll: true);
    return all.map((a) => a.package).where((p) => !keep.contains(p)).toList();
  }

  /// WireGuard: add IncludedApplications to a user .conf that has none.
  Future<String> wireguardScoped(String conf) async {
    if (warpMode == WarpMode.device ||
        RegExp(r'^\s*(Included|Excluded)Applications', multiLine: true, caseSensitive: false)
            .hasMatch(conf)) {
      return conf;
    }
    final own = await _channel.invokeMethod<String>('packageName') ?? 'com.yomihub.app';
    final apps = warpMode == WarpMode.app ? [own] : {own, ...warpApps}.toList();
    final i = conf.indexOf(RegExp(r'^\s*\[Peer\]', multiLine: true));
    final line = 'IncludedApplications = ${apps.join(', ')}\n';
    return i < 0 ? '$conf\n$line' : conf.replaceRange(i, i, line);
  }

  /// Sends the in-app WebViews (browser / WebView mode) through the active
  /// proxy-type service, following the in-app scope.
  Future<void> _applyBrowserProxy() async {
    if (!supported) return;
    try {
      final pc = ProxyController.instance();
      final want = _browserForeground ? YomiVpnState.scopeBrowser : YomiVpnState.scopeWebView;
      final useTor = want && YomiVpnState.torEnabled && YomiVpnState.torRunning;
      final useXray = want && !useTor && YomiVpnState.xrayRunning;
      final useProxy = want && !useTor && !useXray && YomiVpnState.proxyEnabled && YomiVpnState.proxyUrl.isNotEmpty;
      if (useXray) {
        await pc.setProxyOverride(
          settings: ProxySettings(
            proxyRules: [ProxyRule(url: '127.0.0.1:${YomiVpnState.xrayHttpPort}')],
            bypassRules: ['localhost', '127.0.0.1'],
          ),
        );
      } else if (useTor) {
        await pc.setProxyOverride(
          settings: ProxySettings(
            proxyRules: [ProxyRule(url: '127.0.0.1:${YomiVpnState.torHttpPort}')],
            bypassRules: ['localhost', '127.0.0.1'],
          ),
        );
      } else if (useProxy) {
        final u = Uri.parse(YomiVpnState.proxyUrl);
        await pc.setProxyOverride(
          settings: ProxySettings(
            proxyRules: [ProxyRule(url: u.scheme.startsWith('socks') ? 'socks5://${u.host}:${u.port}' : '${u.host}:${u.port}')],
            bypassRules: ['localhost', '127.0.0.1'],
          ),
        );
      } else {
        await pc.clearProxyOverride();
      }
    } catch (_) {}
  }

  // ───────────── WARP ─────────────

  Map<String, dynamic>? get warpAccount {
    final raw = _box?.get('warpAccount');
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw as String));
  }

  /// Registers a free WARP device with Cloudflare (same API the official
  /// client uses) and stores the WireGuard parameters it returns.
  Future<Map<String, dynamic>> _registerWarp() async {
    final keys = Map<String, dynamic>.from(await _channel.invokeMethod('warpKeyPair') as Map);
    const api = 'https://api.cloudflareclient.com/v0a2158';
    final headers = {
      'User-Agent': 'okhttp/3.12.1',
      'CF-Client-Version': 'a-6.30-3596',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final r = await http.post(
      Uri.parse('$api/reg'),
      headers: headers,
      body: jsonEncode({
        'key': keys['public'],
        'install_id': '',
        'fcm_token': '',
        'tos': DateTime.now().toUtc().toIso8601String(),
        'model': 'YomiHub',
        'type': 'Android',
        'locale': 'vi_VN',
      }),
    );
    if (r.statusCode >= 300) throw Exception('WARP đăng ký lỗi: HTTP ${r.statusCode}');
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    final id = d['id'], token = d['token'];
    // make sure WARP (not just DNS) is on for this device
    try {
      await http.patch(
        Uri.parse('$api/reg/$id'),
        headers: {...headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'warp_enabled': true}),
      );
    } catch (_) {}
    final cfg = d['config'] as Map<String, dynamic>;
    final peer = (cfg['peers'] as List).first as Map<String, dynamic>;
    final addrs = (cfg['interface'] as Map)['addresses'] as Map;
    final acc = {
      'id': id,
      'token': token,
      'private': keys['private'],
      'peer': peer['public_key'],
      'endpoint': (peer['endpoint'] as Map?)?['host'] ?? 'engage.cloudflareclient.com:2408',
      'endpoint_v4': (peer['endpoint'] as Map?)?['v4'],
      'v4': addrs['v4'],
      'v6': addrs['v6'],
    };
    await _put('warpAccount', jsonEncode(acc));
    return acc;
  }

  String _warpConfig(Map<String, dynamic> a, String ownPackage) {
    String endpoint = '${a['endpoint']}';
    final v4 = '${a['endpoint_v4'] ?? ''}';
    // Prefer the literal IPv4 endpoint: avoids DNS lookups that may be blocked.
    if (v4.isNotEmpty) {
      final host = v4.split(':').first;
      final port = endpoint.split(':').last;
      endpoint = '$host:${int.tryParse(port) == null ? 2408 : port}';
    }
    final apps = switch (warpMode) {
      WarpMode.app => [ownPackage],
      WarpMode.apps => {...warpApps}.toList(),
      WarpMode.device => <String>[],
    };
    final b = StringBuffer()
      ..writeln('[Interface]')
      ..writeln('PrivateKey = ${a['private']}')
      ..writeln('Address = ${a['v4']}/32${(a['v6'] ?? '').toString().isEmpty ? '' : ', ${a['v6']}/128'}')
      ..writeln('DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111')
      ..writeln('MTU = 1280');
    if (apps.isNotEmpty) b.writeln('IncludedApplications = ${apps.join(', ')}');
    b
      ..writeln('[Peer]')
      ..writeln('PublicKey = ${a['peer']}')
      ..writeln('AllowedIPs = 0.0.0.0/0, ::/0')
      ..writeln('Endpoint = $endpoint')
      ..writeln('PersistentKeepalive = 25');
    return b.toString();
  }

  Future<void> setWarpEnabled(bool v) async {
    if (!supported) return;
    lastError = null;
    if (!v) {
      warpEnabled = false;
      await _put('warpEnabled', false);
      try {
        await _channel.invokeMethod('warpDown');
      } catch (_) {}
      warpUp = false;
      notifyListeners();
      return;
    }
    // Android runs one VPN at a time: stop an OpenVPN/WireGuard tunnel first.
    final t = YomiTunnels.instance.active;
    if (t != null && t.type != TunnelType.xray) {
      await YomiTunnels.instance.disconnect();
    }
    try {
      final granted = await _channel.invokeMethod<bool>('vpnPrepare') ?? false;
      if (!granted) {
        lastError = 'Bạn chưa cho phép YomiHub tạo kết nối VPN.';
        notifyListeners();
        return;
      }
      final acc = warpAccount ?? await _registerWarp();
      final pkg = await _channel.invokeMethod<String>('packageName') ?? 'com.yomihub.app';
      await _channel.invokeMethod('warpUp', {'config': _warpConfig(acc, pkg)});
      warpEnabled = true;
      warpUp = true;
      await _put('warpEnabled', true);
    } catch (e) {
      lastError = '$e';
    }
    notifyListeners();
  }

  Future<void> setWarpMode(WarpMode m) async {
    warpMode = m;
    await _put('warpMode', m.index);
    if (warpEnabled) await setWarpEnabled(true);
    await _reapplyTunnelScope();
    notifyListeners();
  }

  Future<void> setWarpApps(List<String> apps) async {
    warpApps = apps;
    await _put('warpApps', apps);
    if (warpEnabled && warpMode == WarpMode.apps) await setWarpEnabled(true);
    await _reapplyTunnelScope();
    notifyListeners();
  }

  /// A running OpenVPN / WireGuard / SoftEther tunnel picks up a new app
  /// scope by reconnecting.
  Future<void> _reapplyTunnelScope() async {
    final t = YomiTunnels.instance.active;
    if (t != null && t.type != TunnelType.xray) {
      await YomiTunnels.instance.connect(t);
    }
  }

  Future<void> resetWarpAccount() async {
    await _box?.delete('warpAccount');
    if (warpEnabled) await setWarpEnabled(true);
  }

  Future<List<InstalledApp>> installedApps({bool includeAll = false}) async {
    final list = await _channel.invokeMethod<List>(
          'installedApps',
          includeAll ? {'all': true} : null,
        ) ??
        [];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((e) => InstalledApp(e['package'], e['label'], e['system'] == true))
        .toList();
  }
}
