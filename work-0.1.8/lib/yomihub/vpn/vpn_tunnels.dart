import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:mangayomi/yomihub/vpn/win/win_vpn.dart';

/// Kinds of tunnels YomiHub 0.1.4 can bring up.
enum TunnelType { openvpn, wireguard, softether, xray }

extension TunnelTypeName on TunnelType {
  String get label => switch (this) {
    TunnelType.openvpn => 'OpenVPN',
    TunnelType.wireguard => 'WireGuard',
    TunnelType.softether => 'SoftEther VPN',
    TunnelType.xray => 'Mihon Proxy (Xray)',
  };
}

/// One saved VPN profile.
class VpnProfile {
  String id;
  String name;
  TunnelType type;
  String config;
  String username;
  String password;

  /// ISO 3166 alpha-2 country of the server ('' = unknown).
  String country;

  VpnProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.config,
    this.username = '',
    this.password = '',
    this.country = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'config': config,
    'username': username,
    'password': password,
    'country': country,
  };

  factory VpnProfile.fromJson(Map<String, dynamic> j) => VpnProfile(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    type: TunnelType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => TunnelType.openvpn,
    ),
    config: '${j['config'] ?? ''}',
    username: '${j['username'] ?? ''}',
    password: '${j['password'] ?? ''}',
    country: '${j['country'] ?? ''}',
  );
}

/// A public SoftEther "VPN Gate" relay (academic project of the University
/// of Tsukuba). They accept OpenVPN connections with user/pass vpn/vpn.
class VpnGateServer {
  final String host, ip, country, countryCode;
  final int score, ping, speed, sessions;
  final String ovpnBase64;
  VpnGateServer({
    required this.host,
    required this.ip,
    required this.country,
    required this.countryCode,
    required this.score,
    required this.ping,
    required this.speed,
    required this.sessions,
    required this.ovpnBase64,
  });

  String get ovpn {
    try {
      return utf8.decode(base64.decode(ovpnBase64.trim()));
    } catch (_) {
      return '';
    }
  }

  bool get hasTcp => ovpn.contains('proto tcp');
}

/// Countries offered in "Quốc gia đích đến".
const vpnCountries = <String, String>{
  '': 'Tự động (nhanh nhất)',
  'VN': 'Việt Nam',
  'JP': 'Nhật Bản',
  'KR': 'Hàn Quốc',
  'SG': 'Singapore',
  'TH': 'Thái Lan',
  'HK': 'Hồng Kông',
  'TW': 'Đài Loan',
  'CN': 'Trung Quốc',
  'ID': 'Indonesia',
  'MY': 'Malaysia',
  'PH': 'Philippines',
  'IN': 'Ấn Độ',
  'AU': 'Úc',
  'US': 'Hoa Kỳ',
  'CA': 'Canada',
  'BR': 'Brazil',
  'GB': 'Anh',
  'FR': 'Pháp',
  'DE': 'Đức',
  'NL': 'Hà Lan',
  'SE': 'Thụy Điển',
  'CH': 'Thụy Sĩ',
  'RU': 'Nga',
  'UA': 'Ukraina',
  'PL': 'Ba Lan',
  'TR': 'Thổ Nhĩ Kỳ',
};

String countryFlag(String cc) {
  if (cc.length != 2) return '🌐';
  final a = cc.toUpperCase().codeUnits;
  return String.fromCharCodes([0x1F1E6 + a[0] - 65, 0x1F1E6 + a[1] - 65]);
}

/// Profiles, VPN Gate, country choice and the active tunnel.
class YomiTunnels extends ChangeNotifier {
  YomiTunnels._();
  static final instance = YomiTunnels._();
  static final _channel = VpnChannel('yomihub/tunnels');
  static final _vpnChannel = VpnChannel('yomihub/vpn');
  Box? _box;

  List<VpnProfile> profiles = [];
  String country = '';
  String? activeId;

  /// idle / connecting / connected / error / disconnected
  String state = 'idle';
  String? error;
  String traffic = '';
  List<VpnGateServer>? vpnGate;
  DateTime? vpnGateAt;

  /// Route the in-app browser / WebViews through the Xray proxy.
  bool xrayBrowser = true;
  String? _prevProxy;
  bool? _prevProxyEnabled;

  /// Set by YomiVpnService: the outside-apps scope ("VPN & DNS").
  static Future<List<String>> Function()? bypassProvider;
  static Future<String> Function(String conf)? wireguardScope;

  bool get supported => Platform.isAndroid || Platform.isWindows;
  VpnProfile? get active =>
      profiles.where((p) => p.id == activeId).firstOrNull;

  Future<void> init() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox('yomihub_vpn');
    } catch (_) {
      return;
    }
    final raw = _box!.get('profiles', defaultValue: '[]') as String;
    try {
      profiles = (jsonDecode(raw) as List)
          .map((e) => VpnProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {}
    country = _box!.get('country', defaultValue: '') as String;
    xrayBrowser = _box!.get('xrayBrowser', defaultValue: true) as bool;
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'ovpnState':
          final s = '${call.arguments}';
          state = switch (s) {
            'connected' => 'connected',
            'disconnected' || 'idle' => activeId == null ? 'idle' : 'disconnected',
            'error' || 'denied' => 'error',
            _ => 'connecting',
          };
          if (s == 'denied') error = 'Bạn chưa cho phép YomiHub tạo VPN';
          if (state == 'disconnected' || state == 'error') {
            // The OpenVPN process stopped: show the reason from its log.
            unawaited(_explainOvpnFailure());
          }
          notifyListeners();
        case 'ovpnTraffic':
          final m = Map<String, dynamic>.from(call.arguments as Map);
          traffic = '⏱ ${_elapsed('${m['duration'] ?? ''}')} ↓ ${_bytes(m['in'])} ↑ ${_bytes(m['out'])}';
          notifyListeners();
        case 'wgState':
          state = call.arguments == true ? 'connected' : 'disconnected';
          notifyListeners();
      }
      return null;
    });
  }

  /// A WireGuard tunnel comes up even when the peer never answers, and then
  /// swallows all traffic: probe once so the user can see it.
  Future<void> _checkInternet(TunnelType type) async {
    await Future.delayed(const Duration(seconds: 3));
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await c.getUrl(Uri.parse('http://www.gstatic.com/generate_204'));
      final res = await req.close().timeout(const Duration(seconds: 12));
      await res.drain<void>();
    } catch (e) {
      if (active?.type == type && state == 'connected') {
        error = 'Đường hầm đã bật nhưng không vào được Internet – máy chủ không phản hồi. Kiểm tra lại cấu hình hoặc bấm Ngắt.';
        notifyListeners();
      }
    } finally {
      c.close(force: true);
    }
  }

  /// Xray starts even when the server is wrong: probe through the local
  /// proxy so the user sees whether the profile actually works.
  Future<void> _checkXray() async {
    await Future.delayed(const Duration(seconds: 2));
    final c = HttpClient()
      ..findProxy = ((_) => 'PROXY 127.0.0.1:${XrayLinks.httpPort}')
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await c.getUrl(Uri.parse('http://www.gstatic.com/generate_204'));
      final res = await req.close().timeout(const Duration(seconds: 12));
      await res.drain<void>();
      if (res.statusCode != 204 && res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    } catch (e) {
      if (active?.type == TunnelType.xray) {
        error = 'Mihon Proxy đang chạy nhưng không vào được Internet qua máy chủ này ($e). Kiểm tra lại link.';
        notifyListeners();
      }
    } finally {
      c.close(force: true);
    }
  }

  // The OpenVPN helper reports "connected since" as a date; show elapsed time.
  static String _elapsed(String v) {
    final t = DateTime.tryParse(v.replaceFirst(' ', 'T'));
    if (t == null) return v;
    final d = DateTime.now().difference(t);
    if (d.isNegative) return '00:00:00';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  static String _bytes(Object? v) {
    final n = int.tryParse('${v ?? ''}');
    if (n == null) return '${v ?? ''}';
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    if (n < 1024 * 1024 * 1024) return '${(n / 1048576).toStringAsFixed(1)} MB';
    return '${(n / 1073741824).toStringAsFixed(2)} GB';
  }

  /// OpenVPN 2.6 only negotiates ciphers listed in data-ciphers; older
  /// configs (VPN Gate / SoftEther exports) only say `cipher AES-128-CBC`.
  static String ovpnCompat(String cfg, {bool withAuth = false}) {
    var extra = '';
    final m = RegExp(r'^\s*cipher\s+(\S+)', multiLine: true).firstMatch(cfg);
    if (m != null && !RegExp(r'^\s*data-ciphers', multiLine: true).hasMatch(cfg)) {
      final c = m.group(1)!;
      extra += '\ndata-ciphers $c:AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305\ndata-ciphers-fallback $c\n';
    }
    // VPN Gate / SoftEther listeners need a (dummy) user name + password, but
    // their .ovpn files leave `auth-user-pass` commented out, so the client
    // never sends it and the server answers AUTH_FAILED.
    if (withAuth && !RegExp(r'^\s*auth-user-pass', multiLine: true).hasMatch(cfg)) {
      extra += '\nauth-user-pass\n';
    }
    if (extra.isEmpty) return cfg;
    final i = cfg.indexOf('<ca>');
    return i > 0 ? cfg.substring(0, i) + extra + cfg.substring(i) : cfg + extra;
  }

  /// Last log lines of a failed OpenVPN connection, as a short error text.
  List<String> ovpnLog = const [];
  Future<void> _explainOvpnFailure() async {
    try {
      final lines = List<String>.from(await _channel.invokeMethod<List>('ovpnLog') ?? const []);
      ovpnLog = lines;
      final bad = lines.reversed.firstWhere(
        (l) => RegExp(r'error|fail|exit|refused|timeout|unreachable|denied|TLS|AUTH', caseSensitive: false).hasMatch(l),
        orElse: () => lines.isEmpty ? '' : lines.last,
      );
      if (bad.isNotEmpty && state != 'connected') {
        final all = lines.join('\n');
        final why = all.contains('AUTH_FAILED') || all.contains('auth-failure')
            ? 'máy chủ từ chối đăng nhập (sai tài khoản/mật khẩu)'
            : RegExp(r'Connection refused|Connection timed out|Network is unreachable|Cannot resolve').hasMatch(all)
            ? 'không kết nối được tới máy chủ – hãy thử máy chủ khác'
            : RegExp(r'Options error|Unrecognized option').hasMatch(all)
            ? 'cấu hình .ovpn không hợp lệ'
            : bad;
        error = 'OpenVPN: $why';
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveProfiles() async =>
      _box?.put('profiles', jsonEncode(profiles.map((e) => e.toJson()).toList()));

  Future<void> setCountry(String cc) async {
    country = cc;
    await _box?.put('country', cc);
    notifyListeners();
  }

  Future<void> setXrayBrowser(bool v) async {
    xrayBrowser = v;
    await _box?.put('xrayBrowser', v);
    notifyListeners();
  }

  // ───────────── profiles ─────────────

  /// Guesses the type from the text (an .ovpn, a WireGuard .conf, or share
  /// links for Xray) and saves a profile. Returns an error text or null.
  Future<String?> importText(
    String text, {
    String name = '',
    TunnelType? type,
    String country = '',
    String username = '',
    String password = '',
  }) async {
    text = text.trim();
    if (text.isEmpty) return 'Nội dung trống';
    type ??= detectType(text);
    if (type == null) {
      return 'Không nhận ra cấu hình (cần file .ovpn, .conf WireGuard hoặc link vless:// vmess:// trojan:// ss://)';
    }
    if (type == TunnelType.xray) {
      final links = text
          .split(RegExp(r'\s+'))
          .where((l) => RegExp(r'^(vless|vmess|trojan|ss)://').hasMatch(l))
          .toList();
      if (links.isEmpty) return 'Không có link Xray hợp lệ';
      var n = 0;
      for (final l in links) {
        try {
          XrayLinks.outbound(l); // validates the link
          profiles.add(
            VpnProfile(
              id: '${DateTime.now().microsecondsSinceEpoch}_$n',
              name: name.isNotEmpty && links.length == 1
                  ? name
                  : XrayLinks.name(l),
              type: TunnelType.xray,
              config: l,
              country: country.isNotEmpty ? country : _guessCountry(XrayLinks.name(l)),
            ),
          );
          n++;
        } catch (_) {}
      }
      await _saveProfiles();
      notifyListeners();
      return n == 0 ? 'Link không hợp lệ' : null;
    }
    final guessedName = name.isNotEmpty
        ? name
        : type == TunnelType.openvpn
        ? (RegExp(r'^remote\s+(\S+)', multiLine: true).firstMatch(text)?.group(1) ??
              'OpenVPN')
        : (RegExp(r'^Endpoint\s*=\s*(\S+)', multiLine: true).firstMatch(text)?.group(1) ??
              'WireGuard');
    profiles.add(
      VpnProfile(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: guessedName,
        type: type,
        config: text,
        username: username,
        password: password,
        country: country.isNotEmpty ? country : _guessCountry(guessedName),
      ),
    );
    await _saveProfiles();
    notifyListeners();
    return null;
  }

  static TunnelType? detectType(String text) {
    if (RegExp(r'^(vless|vmess|trojan|ss)://', multiLine: true).hasMatch(text)) {
      return TunnelType.xray;
    }
    if (text.contains('[Interface]') && text.contains('[Peer]')) {
      return TunnelType.wireguard;
    }
    if (RegExp(r'^\s*(client|remote|dev\s+tun|<ca>)', multiLine: true).hasMatch(text)) {
      return TunnelType.openvpn;
    }
    return null;
  }

  static String _guessCountry(String name) {
    final m = RegExp(r'(?:^|[^A-Za-z])([A-Z]{2})(?:[^A-Za-z]|$)').firstMatch(name);
    final cc = m?.group(1) ?? '';
    return vpnCountries.containsKey(cc) ? cc : '';
  }

  Future<void> deleteProfile(String id) async {
    if (activeId == id) await disconnect();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(VpnProfile p) async {
    await _saveProfiles();
    notifyListeners();
  }

  // ───────────── VPN Gate (SoftEther) ─────────────

  Future<List<VpnGateServer>> loadVpnGate({bool force = false}) async {
    if (!force &&
        vpnGate != null &&
        vpnGateAt != null &&
        DateTime.now().difference(vpnGateAt!).inMinutes < 30) {
      return vpnGate!;
    }
    final res = await http
        .get(Uri.parse('https://www.vpngate.net/api/iphone/'))
        .timeout(const Duration(seconds: 40));
    final lines = const LineSplitter().convert(utf8.decode(res.bodyBytes, allowMalformed: true));
    final out = <VpnGateServer>[];
    for (final line in lines) {
      if (line.startsWith('*') || line.startsWith('#') || line.trim().isEmpty) {
        continue;
      }
      final f = line.split(',');
      if (f.length < 15) continue;
      out.add(
        VpnGateServer(
          host: f[0],
          ip: f[1],
          score: int.tryParse(f[2]) ?? 0,
          ping: int.tryParse(f[3]) ?? 0,
          speed: int.tryParse(f[4]) ?? 0,
          country: f[5],
          countryCode: f[6],
          sessions: int.tryParse(f[7]) ?? 0,
          ovpnBase64: f[14],
        ),
      );
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    vpnGate = out;
    vpnGateAt = DateTime.now();
    notifyListeners();
    return out;
  }

  /// Best VPN Gate server for the chosen country (or overall).
  Future<VpnGateServer?> pickVpnGate([String? cc]) async {
    final list = await loadVpnGate();
    final want = (cc ?? country).toUpperCase();
    final pool = want.isEmpty
        ? list
        : list.where((s) => s.countryCode.toUpperCase() == want).toList();
    return pool.firstOrNull;
  }

  Future<String?> connectVpnGate(VpnGateServer s) async {
    final cfg = s.ovpn;
    if (cfg.isEmpty) return 'Máy chủ không có cấu hình OpenVPN';
    final p = VpnProfile(
      id: 'vpngate_${s.ip}',
      name: '${s.country} • ${s.host}',
      type: TunnelType.softether,
      config: cfg,
      username: 'vpn',
      password: 'vpn',
      country: s.countryCode,
    );
    profiles.removeWhere((e) => e.id == p.id);
    profiles.insert(0, p);
    await _saveProfiles();
    return connect(p);
  }

  // ───────────── connect / disconnect ─────────────

  Future<bool> _prepare() async {
    try {
      return await _vpnChannel.invokeMethod<bool>('vpnPrepare') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Only one Android VPN can run; WARP and the WireGuard tunnel share one
  /// engine. The caller (YomiVpnService) turns WARP off first.
  Future<String?> connect(VpnProfile p) async {
    if (!supported) return 'Chưa hỗ trợ trên nền tảng này';
    error = null;
    await disconnect(silent: true);
    activeId = p.id;
    state = 'connecting';
    notifyListeners();
    try {
      switch (p.type) {
        case TunnelType.openvpn:
        case TunnelType.softether:
          if (!await _prepare()) throw 'Bạn chưa cho phép YomiHub tạo VPN';
          await _channel.invokeMethod('ovpnUp', {
            'config': ovpnCompat(p.config, withAuth: p.username.isNotEmpty),
            'username': p.username,
            'password': p.password,
            'name': p.name,
            'bypass': await (bypassProvider?.call() ?? Future.value(<String>[])),
          });
        case TunnelType.wireguard:
          if (!await _prepare()) throw 'Bạn chưa cho phép YomiHub tạo VPN';
          final conf = await (wireguardScope?.call(p.config) ?? Future.value(p.config));
          await _channel.invokeMethod('wgUp', {'config': conf});
          state = 'connected';
          if (Platform.isWindows) {
            // Windows: WireGuard runs in Xray as a local proxy.
            YomiVpnState.xrayHttpPort = WinVpnBackend.httpPort;
            YomiVpnState.xrayRunning = true;
            YomiVpnState.bump();
            unawaited(_checkXray());
          } else {
            unawaited(_checkInternet(TunnelType.wireguard));
          }
        case TunnelType.xray:
          final cfg = await XrayLinks.config(p.config);
          await _channel.invokeMethod('xrayStart', {'config': cfg});
          _prevProxy ??= YomiVpnState.proxyUrl;
          _prevProxyEnabled ??= YomiVpnState.proxyEnabled;
          YomiVpnState.xrayHttpPort = XrayLinks.httpPort;
          YomiVpnState.xrayRunning = true;
          YomiVpnState.bump();
          state = 'connected';
          unawaited(_checkXray());
      }
    } catch (e) {
      error = e is PlatformException ? (e.message ?? e.code) : '$e';
      state = 'error';
      activeId = null;
    }
    notifyListeners();
    return error;
  }

  Future<void> disconnect({bool silent = false}) async {
    final p = active;
    if (p == null) return;
    try {
      switch (p.type) {
        case TunnelType.openvpn:
        case TunnelType.softether:
          await _channel.invokeMethod('ovpnDown');
        case TunnelType.wireguard:
          await _channel.invokeMethod('wgDown');
          if (Platform.isWindows) {
            YomiVpnState.xrayRunning = false;
            YomiVpnState.bump();
          }
        case TunnelType.xray:
          await _channel.invokeMethod('xrayStop');
          YomiVpnState.xrayRunning = false;
          YomiVpnState.bump();
          _prevProxy = null;
          _prevProxyEnabled = null;
      }
    } catch (_) {}
    activeId = null;
    state = 'idle';
    traffic = '';
    if (!silent) notifyListeners();
  }
}

/// Share links (v2rayN style) → Xray JSON.
class XrayLinks {
  static const socksPort = 10808;
  static const httpPort = 10809;

  static String name(String link) {
    final i = link.indexOf('#');
    if (link.startsWith('vmess://')) {
      try {
        final j = _vmessJson(link);
        return '${j['ps'] ?? j['add'] ?? 'VMess'}';
      } catch (_) {}
    }
    if (i > 0) return Uri.decodeComponent(link.substring(i + 1));
    final u = Uri.tryParse(link);
    return '${u?.scheme.toUpperCase() ?? 'Xray'} ${u?.host ?? ''}'.trim();
  }

  static Map<String, dynamic> _vmessJson(String link) {
    var b = link.substring(8).trim();
    b = b.padRight((b.length + 3) ~/ 4 * 4, '=');
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64.decode(b.replaceAll('-', '+').replaceAll('_', '/')))) as Map,
    );
  }

  static String _b64(String s) {
    var b = s.replaceAll('-', '+').replaceAll('_', '/');
    b = b.padRight((b.length + 3) ~/ 4 * 4, '=');
    return utf8.decode(base64.decode(b));
  }

  static Map<String, dynamic> _stream(Map<String, String> q, String host) {
    final net = q['type'] ?? q['net'] ?? 'tcp';
    final security = q['security'] ?? q['tls'] ?? 'none';
    final s = <String, dynamic>{'network': net == 'h2' ? 'http' : net};
    final sni = q['sni'] ?? q['peer'] ?? q['host'] ?? host;
    if (security == 'tls') {
      s['security'] = 'tls';
      s['tlsSettings'] = {
        'serverName': sni,
        if ((q['fp'] ?? '').isNotEmpty) 'fingerprint': q['fp'],
        if ((q['alpn'] ?? '').isNotEmpty) 'alpn': q['alpn']!.split(','),
        'allowInsecure': q['allowInsecure'] == '1' || q['insecure'] == '1',
      };
    } else if (security == 'reality') {
      s['security'] = 'reality';
      s['realitySettings'] = {
        'serverName': sni,
        'fingerprint': (q['fp'] ?? '').isEmpty ? 'chrome' : q['fp'],
        'publicKey': q['pbk'] ?? '',
        'shortId': q['sid'] ?? '',
        'spiderX': q['spx'] ?? '',
      };
    } else {
      s['security'] = 'none';
    }
    switch (net) {
      case 'ws':
        s['wsSettings'] = {
          'path': q['path'] ?? '/',
          if ((q['host'] ?? '').isNotEmpty) 'headers': {'Host': q['host']},
        };
      case 'grpc':
        s['grpcSettings'] = {
          'serviceName': q['serviceName'] ?? q['path'] ?? '',
          'multiMode': q['mode'] == 'multi',
        };
      case 'h2':
      case 'http':
        s['httpSettings'] = {
          'path': q['path'] ?? '/',
          if ((q['host'] ?? '').isNotEmpty) 'host': [q['host']],
        };
      case 'xhttp':
      case 'splithttp':
        s['xhttpSettings'] = {
          'path': q['path'] ?? '/',
          if ((q['host'] ?? '').isNotEmpty) 'host': q['host'],
          if ((q['mode'] ?? '').isNotEmpty) 'mode': q['mode'],
        };
      case 'httpupgrade':
        s['httpupgradeSettings'] = {
          'path': q['path'] ?? '/',
          if ((q['host'] ?? '').isNotEmpty) 'host': q['host'],
        };
      case 'tcp':
        if (q['headerType'] == 'http') {
          s['tcpSettings'] = {
            'header': {
              'type': 'http',
              'request': {
                'path': [q['path'] ?? '/'],
                'headers': {
                  'Host': [q['host'] ?? host],
                },
              },
            },
          };
        }
    }
    return s;
  }

  /// The "proxy" outbound for a share link.
  static Map<String, dynamic> outbound(String link) {
    link = link.trim();
    if (link.startsWith('vmess://')) {
      final j = _vmessJson(link);
      final q = {
        for (final e in j.entries) e.key: '${e.value}',
        'type': '${j['net'] ?? 'tcp'}',
        'security': '${j['tls'] ?? ''}' == 'tls' ? 'tls' : 'none',
        'headerType': '${j['type'] ?? ''}',
      };
      return {
        'tag': 'proxy',
        'protocol': 'vmess',
        'settings': {
          'vnext': [
            {
              'address': j['add'],
              'port': int.tryParse('${j['port']}') ?? 443,
              'users': [
                {
                  'id': j['id'],
                  'alterId': int.tryParse('${j['aid'] ?? 0}') ?? 0,
                  'security': (j['scy'] ?? 'auto').toString().isEmpty ? 'auto' : j['scy'],
                },
              ],
            },
          ],
        },
        'streamSettings': _stream(q, '${j['add']}'),
      };
    }
    if (link.startsWith('ss://')) {
      var body = link.substring(5);
      final hash = body.indexOf('#');
      if (hash >= 0) body = body.substring(0, hash);
      String method, pass, host;
      int port;
      if (body.contains('@')) {
        final at = body.lastIndexOf('@');
        var userinfo = body.substring(0, at);
        final hp = body.substring(at + 1).split('?').first;
        if (!userinfo.contains(':')) userinfo = _b64(Uri.decodeComponent(userinfo));
        method = userinfo.split(':').first;
        pass = userinfo.substring(method.length + 1);
        host = hp.substring(0, hp.lastIndexOf(':'));
        port = int.parse(hp.substring(hp.lastIndexOf(':') + 1));
      } else {
        final dec = _b64(body);
        final at = dec.lastIndexOf('@');
        final up = dec.substring(0, at);
        final hp = dec.substring(at + 1);
        method = up.split(':').first;
        pass = up.substring(method.length + 1);
        host = hp.substring(0, hp.lastIndexOf(':'));
        port = int.parse(hp.substring(hp.lastIndexOf(':') + 1));
      }
      return {
        'tag': 'proxy',
        'protocol': 'shadowsocks',
        'settings': {
          'servers': [
            {'address': host, 'port': port, 'method': method, 'password': pass},
          ],
        },
      };
    }
    final u = Uri.parse(link.split('#').first);
    final q = u.queryParameters.map((k, v) => MapEntry(k, v));
    if (u.scheme == 'vless') {
      return {
        'tag': 'proxy',
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': u.host,
              'port': u.port,
              'users': [
                {
                  'id': Uri.decodeComponent(u.userInfo),
                  'encryption': q['encryption'] ?? 'none',
                  if ((q['flow'] ?? '').isNotEmpty) 'flow': q['flow'],
                },
              ],
            },
          ],
        },
        'streamSettings': _stream(q, u.host),
      };
    }
    if (u.scheme == 'trojan') {
      return {
        'tag': 'proxy',
        'protocol': 'trojan',
        'settings': {
          'servers': [
            {
              'address': u.host,
              'port': u.port,
              'password': Uri.decodeComponent(u.userInfo),
            },
          ],
        },
        'streamSettings': _stream({'security': 'tls', ...q}, u.host),
      };
    }
    throw FormatException('Không hỗ trợ: ${u.scheme}');
  }

  /// Full Xray config: SOCKS 10808 + HTTP 10809 on loopback → the link.
  static Future<String> config(String link) async {
    final ob = outbound(link);
    // Resolve the server name here: Xray's Go resolver can't read Android's
    // DNS settings.
    try {
      final vnext = (ob['settings']?['vnext'] ?? ob['settings']?['servers']) as List?;
      final first = vnext?.first as Map?;
      final host = '${first?['address'] ?? ''}';
      if (host.isNotEmpty && InternetAddress.tryParse(host) == null) {
        final addrs = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 8));
        final v4 = addrs.where((a) => a.type == InternetAddressType.IPv4).firstOrNull;
        if (v4 != null) first!['address'] = v4.address;
      }
    } catch (_) {}
    return jsonEncode({
      'log': {'loglevel': 'warning', 'access': 'none'},
      'dns': {
        'servers': ['1.1.1.1', '8.8.8.8'],
      },
      'inbounds': [
        {
          'tag': 'socks',
          'listen': '127.0.0.1',
          'port': socksPort,
          'protocol': 'socks',
          'settings': {'auth': 'noauth', 'udp': true},
        },
        {
          'tag': 'http',
          'listen': '127.0.0.1',
          'port': httpPort,
          'protocol': 'http',
          'settings': {},
        },
      ],
      'outbounds': [
        ob,
        {'tag': 'direct', 'protocol': 'freedom'},
      ],
    });
  }
}
