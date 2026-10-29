import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mangayomi/yomihub/win/win_process.dart';

/// YomiHub 0.1.7 – "VPN & DNS" on Windows.
///
/// Implements the same calls the Android side answers on the `yomihub/vpn`
/// and `yomihub/tunnels` channels, with helper programs shipped in
/// `yomihub_bin\` next to YomiHub.exe:
///
/// * **Tor** – `tor.exe` (Tor Expert Bundle) with an optional bridge
///   (Snowflake / obfs4 / meek through `lyrebird.exe`) for networks that
///   block Tor; control port for "new identity" and the exit country.
/// * **Cloudflare WARP, WireGuard, Mihon Proxy (VLESS / VMess / Trojan /
///   SS)** – `xray.exe` (Xray-core): WARP and WireGuard use Xray's
///   WireGuard outbound in user space, so no driver and no admin rights.
/// * **OpenVPN / SoftEther (VPN Gate)** – handed to OpenVPN GUI when it is
///   installed (a TAP/Wintun driver is required and only an installer can
///   add it).
///
/// Every proxy-type service is exposed on the same local port
/// ([httpPort] HTTP, [socksPort] SOCKS), so the WebView2 browser and the
/// "whole device" option (Windows system proxy) never need reconfiguring
/// when the user switches service.
class WinVpnBackend {
  WinVpnBackend._();
  static final instance = WinVpnBackend._();

  static const httpPort = 10809;
  static const socksPort = 10808;

  final _handlers = <String, Future<dynamic> Function(MethodCall call)?>{};

  void setHandler(String channel, Future<dynamic> Function(MethodCall call)? h) => _handlers[channel] = h;

  void _emit(String channel, String method, [dynamic args]) {
    final h = _handlers[channel];
    if (h == null) return;
    scheduleMicrotask(() => h(MethodCall(method, args)));
  }

  Directory? _data;
  Future<Directory> _dataDir() async {
    if (_data != null) return _data!;
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'vpn'));
    await d.create(recursive: true);
    return _data = d;
  }

  String get _bin => WinProc.binDir;
  String get _xrayExe => p.join(_bin, 'xray.exe');
  String get _torExe => p.join(_bin, 'tor', 'tor.exe');

  WinProc? _xray;
  String _xrayFor = '';
  WinProc? _tor;
  int _torSocks = 0;
  int _torControl = 0;
  String _torrcExtra = '';
  String torStatus = 'OFF';
  bool warpUp = false;
  bool wgUp = false;

  /// '' (none), 'snowflake', 'obfs4', 'meek'
  String torBridge = '';

  Future<dynamic> invoke(String channel, String method, dynamic args) async {
    final a = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
    switch (method) {
      // ── yomihub/vpn ──
      case 'vpnPrepare':
        return true;
      case 'packageName':
        return 'YomiHub.exe';
      case 'installedApps':
        return <Map<String, dynamic>>[];
      case 'torStart':
        return _torStart();
      case 'torStop':
        await _torStop();
        return true;
      case 'torStatus':
        return _torInfo();
      case 'torNewIdentity':
        return _torControlCmd(['SIGNAL NEWNYM']);
      case 'torExitNodes':
        final cc = '${a['country'] ?? ''}'.toLowerCase();
        return _torControlCmd(cc.isEmpty
            ? ['RESETCONF ExitNodes StrictNodes', 'SIGNAL NEWNYM']
            : ['SETCONF ExitNodes={$cc} StrictNodes=0', 'SIGNAL NEWNYM']);
      case 'torVpnStart':
      case 'torVpnStop':
      case 'torVpnState':
        // "whole device" on Windows = system proxy, handled by
        // YomiVpnService.applyWindowsSystemProxy.
        return {'up': false, 'error': null};
      case 'warpKeyPair':
        return _x25519();
      case 'warpUp':
        await _wireguardUp('${a['config'] ?? ''}', 'warp');
        warpUp = true;
        _emit('yomihub/vpn', 'warpState', true);
        return true;
      case 'warpDown':
        if (_xrayFor == 'warp') await _xrayStop();
        warpUp = false;
        _emit('yomihub/vpn', 'warpState', false);
        return true;
      case 'warpState':
        return warpUp && (_xray?.alive ?? false);
      case 'jvmProxy':
        return true;
      // ── yomihub/tunnels ──
      case 'torrc':
        _torrcExtra = '${a['text'] ?? ''}';
        return true;
      case 'xrayStart':
        await _xrayStart('${a['config']}', 'link');
        return true;
      case 'xrayStop':
        if (_xrayFor == 'link' || _xrayFor == 'proxy') await _xrayStop();
        return true;
      case 'wgUp':
        await _wireguardUp('${a['config'] ?? ''}', 'wg');
        wgUp = true;
        _emit('yomihub/tunnels', 'wgState', true);
        return true;
      case 'wgDown':
        if (_xrayFor == 'wg') await _xrayStop();
        wgUp = false;
        _emit('yomihub/tunnels', 'wgState', false);
        return true;
      case 'ovpnUp':
        return _ovpnUp(a);
      case 'ovpnDown':
        return _ovpnDown();
      case 'ovpnLog':
        return _ovpnLogTail();
    }
    throw PlatformException(code: 'unimplemented', message: tr('{p0} chưa hỗ trợ trên Windows', {'p0': method}));
  }

  // ───────────── Xray ─────────────

  bool get xrayRunning => _xray?.alive ?? false;
  String get xrayPurpose => _xrayFor;

  Future<void> _xrayStart(String configJson, String purpose) async {
    if (!File(_xrayExe).existsSync()) {
      throw PlatformException(code: 'xray', message: tr('Thiếu yomihub_bin\\xray.exe – hãy giải nén lại đầy đủ gói YomiHub cho Windows.'));
    }
    await _xrayStop();
    // Ports must be free: another copy of Xray/v2rayN often holds 10808/10809.
    for (final port in [httpPort, socksPort]) {
      if (await WinProc.freePort(port) != port) {
        throw PlatformException(
          code: 'xray',
          message: tr('Cổng {p0} đang bị chương trình khác dùng (v2rayN, Xray…). Hãy tắt chương trình đó rồi thử lại.', {'p0': port}),
        );
      }
    }
    final dir = await _dataDir();
    final cfg = File(p.join(dir.path, 'xray_$purpose.json'));
    await cfg.writeAsString(configJson);
    final proc = await WinProc.start('xray', _xrayExe, ['run', '-c', cfg.path], workingDirectory: _bin);
    if (!await WinProc.waitPort(httpPort, timeout: const Duration(seconds: 10))) {
      final why = proc.log.where((l) => l.contains('Failed') || l.contains('failed') || l.contains('error')).join('\n');
      await proc.kill();
      throw PlatformException(code: 'xray', message: tr('Xray không khởi động được{p0}', {'p0': why.isEmpty ? '' : ':\n$why'}));
    }
    _xray = proc;
    _xrayFor = purpose;
  }

  Future<void> _xrayStop() async {
    final x = _xray;
    _xray = null;
    _xrayFor = '';
    await x?.kill();
  }

  static Map<String, dynamic> _inbounds() => {
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
      };

  /// Local HTTP/SOCKS in front of an upstream proxy (Tor's SOCKS port, or
  /// the user's own HTTP/SOCKS proxy with or without a password).
  static String bridgeConfig(Uri upstream) {
    final user = upstream.userInfo.isEmpty ? null : Uri.decodeComponent(upstream.userInfo.split(':').first);
    final pass = upstream.userInfo.contains(':')
        ? Uri.decodeComponent(upstream.userInfo.substring(upstream.userInfo.indexOf(':') + 1))
        : null;
    final socks = upstream.scheme.startsWith('socks');
    return jsonEncode({
      'log': {'loglevel': 'warning', 'access': 'none'},
      ..._inbounds(),
      'outbounds': [
        {
          'tag': 'proxy',
          'protocol': socks ? 'socks' : 'http',
          'settings': {
            'servers': [
              {
                'address': upstream.host,
                'port': upstream.port,
                if (user != null) 'users': [
                  {'user': user, 'pass': pass ?? ''},
                ],
              },
            ],
          },
        },
      ],
    });
  }

  /// Starts the local bridge for the custom proxy (used by WebView2 and the
  /// system proxy; extensions talk to the proxy directly).
  Future<void> proxyBridge(String? url) async {
    if (url == null || url.isEmpty) {
      if (_xrayFor == 'proxy') await _xrayStop();
      return;
    }
    final u = Uri.parse(url);
    await _xrayStart(bridgeConfig(u), 'proxy');
  }

  // ───────────── WireGuard / WARP through Xray ─────────────

  /// WireGuard .conf → Xray config with a WireGuard outbound.
  static String wireguardConfig(String conf) {
    final iface = <String, String>{}, peer = <String, String>{};
    Map<String, String>? cur;
    for (final raw in const LineSplitter().convert(conf)) {
      final line = raw.split('#').first.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase() == '[interface]') {
        cur = iface;
      } else if (line.toLowerCase() == '[peer]') {
        cur = peer;
      } else if (cur != null && line.contains('=')) {
        final i = line.indexOf('=');
        cur[line.substring(0, i).trim().toLowerCase()] = line.substring(i + 1).trim();
      }
    }
    List<String> list(String? v) => (v ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final priv = iface['privatekey'];
    final pub = peer['publickey'];
    final endpoint = peer['endpoint'];
    if (priv == null || pub == null || endpoint == null) {
      throw PlatformException(code: 'wg', message: tr('Cấu hình WireGuard thiếu PrivateKey / PublicKey / Endpoint'));
    }
    final dns = list(iface['dns']).where((d) => InternetAddress.tryParse(d) != null).toList();
    return jsonEncode({
      'log': {'loglevel': 'warning', 'access': 'none'},
      'dns': {'servers': dns.isEmpty ? ['1.1.1.1', '8.8.8.8'] : dns},
      ..._inbounds(),
      'outbounds': [
        {
          'tag': 'proxy',
          'protocol': 'wireguard',
          'settings': {
            'secretKey': priv,
            'address': list(iface['address']),
            'mtu': int.tryParse(iface['mtu'] ?? '') ?? 1280,
            'domainStrategy': 'ForceIPv4',
            'peers': [
              {
                'publicKey': pub,
                if (peer['presharedkey'] != null) 'preSharedKey': peer['presharedkey'],
                'endpoint': endpoint,
                'allowedIPs': list(peer['allowedips']).isEmpty ? ['0.0.0.0/0', '::/0'] : list(peer['allowedips']),
                if (peer['persistentkeepalive'] != null) 'keepAlive': int.tryParse(peer['persistentkeepalive']!) ?? 0,
              },
            ],
          },
        },
        {'tag': 'direct', 'protocol': 'freedom'},
      ],
    });
  }

  Future<void> _wireguardUp(String conf, String purpose) => _xrayStart(wireguardConfig(conf), purpose);

  /// X25519 key pair for WARP, generated by `xray x25519`.
  Future<Map<String, String>> _x25519() async {
    final out = await WinProc.run(_xrayExe, ['x25519']);
    String? field(List<String> names) {
      for (final n in names) {
        final m = RegExp('^$n\\s*:\\s*(\\S+)', multiLine: true, caseSensitive: false).firstMatch(out);
        if (m != null) return m.group(1);
      }
      return null;
    }

    final priv = field(['Private ?key']);
    final pub = field(['Public ?key', r'Password(?: \(PublicKey\))?']);
    if (priv == null || pub == null) {
      throw PlatformException(code: 'warp', message: tr('Không tạo được khoá WARP: {p0}', {'p0': out}));
    }
    // Xray prints URL-safe base64 without padding; WireGuard wants standard.
    String std(String k) {
      var s = k.replaceAll('-', '+').replaceAll('_', '/');
      while (s.length % 4 != 0) {
        s += '=';
      }
      return s;
    }

    return {'private': std(priv), 'public': std(pub)};
  }

  // ───────────── Tor ─────────────

  Map<String, dynamic> _torInfo() => {
        'status': torStatus,
        'httpPort': torStatus == 'ON' ? httpPort : 0,
        'socksPort': _torSocks,
      };

  /// Bridge lines shipped with the Tor Expert Bundle (pt_config.json).
  Future<List<String>> _bridgeLines(String kind) async {
    try {
      final f = File(p.join(_bin, 'tor', 'pluggable_transports', 'pt_config.json'));
      final j = jsonDecode(await f.readAsString()) as Map;
      final b = (j['bridges'] as Map?)?[kind == 'meek' ? 'meek-azure' : kind] ?? (j['bridges'] as Map?)?[kind];
      if (b is List) return b.map((e) => '$e').toList();
    } catch (_) {}
    return const [];
  }

  Future<Map<String, dynamic>> _torStart() async {
    if (_tor?.alive ?? false) return _torInfo();
    if (!File(_torExe).existsSync()) {
      throw PlatformException(code: 'tor', message: tr('Thiếu yomihub_bin\\tor\\tor.exe – hãy giải nén lại đầy đủ gói YomiHub cho Windows.'));
    }
    torStatus = 'STARTING';
    _emit('yomihub/vpn', 'torStatus', torStatus);
    final dir = await _dataDir();
    final data = Directory(p.join(dir.path, 'tor_data'));
    await data.create(recursive: true);
    _torSocks = await WinProc.freePort(9150);
    _torControl = await WinProc.freePort(9151);
    final geo = p.join(_bin, 'tor', 'geoip');
    final b = StringBuffer()
      ..writeln('SocksPort 127.0.0.1:$_torSocks')
      ..writeln('ControlPort 127.0.0.1:$_torControl')
      ..writeln('CookieAuthentication 1')
      ..writeln('DataDirectory ${WinProc.shortPath(data.path)}')
      ..writeln('ClientOnly 1')
      ..writeln('AvoidDiskWrites 1')
      ..writeln('Log notice stdout');
    if (File(geo).existsSync()) b.writeln('GeoIPFile ${WinProc.shortPath(geo)}');
    final geo6 = p.join(_bin, 'tor', 'geoip6');
    if (File(geo6).existsSync()) b.writeln('GeoIPv6File ${WinProc.shortPath(geo6)}');
    if (torBridge.isNotEmpty) {
      final lyre = p.join(_bin, 'tor', 'pluggable_transports', 'lyrebird.exe');
      final lines = await _bridgeLines(torBridge);
      if (File(lyre).existsSync() && lines.isNotEmpty) {
        b
          ..writeln('UseBridges 1')
          ..writeln('ClientTransportPlugin meek_lite,obfs2,obfs3,obfs4,scramblesuit,webtunnel,snowflake exec ${WinProc.shortPath(lyre)}');
        for (final l in lines) {
          b.writeln('Bridge $l');
        }
      }
    }
    b.write(_torrcExtra);
    final torrc = File(p.join(dir.path, 'torrc'));
    await torrc.writeAsString(b.toString());
    final proc = await WinProc.start('tor', _torExe, ['-f', WinProc.shortPath(torrc.path)], workingDirectory: p.dirname(_torExe));
    _tor = proc;
    final done = Completer<bool>();
    late final StreamSubscription sub;
    sub = proc.lines.listen((l) {
      final m = RegExp(r'Bootstrapped (\d+)%').firstMatch(l);
      if (m != null && m.group(1) == '100' && !done.isCompleted) done.complete(true);
      if (l.contains('[err]') && !done.isCompleted) done.complete(false);
    }, onDone: () {
      if (!done.isCompleted) done.complete(false);
    });
    // Bridges (Snowflake) can take a few minutes on slow networks.
    final ok = await done.future.timeout(Duration(seconds: torBridge.isEmpty ? 120 : 240), onTimeout: () => false);
    await sub.cancel();
    if (!ok) {
      final last = proc.log.reversed.take(6).toList().reversed.join('\n');
      await _torStop();
      throw PlatformException(
        code: 'tor',
        message: tr('Tor chưa dựng được mạch (mạng có thể đang chặn Tor – thử bật “Cầu nối” Snowflake/obfs4).\n{p0}', {'p0': last}),
      );
    }
    // Local HTTP proxy in front of Tor's SOCKS port (plain HTTP and CONNECT).
    await _xrayStart(bridgeConfig(Uri.parse('socks5://127.0.0.1:$_torSocks')), 'tor');
    torStatus = 'ON';
    _emit('yomihub/vpn', 'torStatus', torStatus);
    _watchTor(proc);
    return _torInfo();
  }

  void _watchTor(WinProc proc) {
    Timer.periodic(const Duration(seconds: 5), (t) {
      if (!identical(_tor, proc)) {
        t.cancel();
        return;
      }
      if (!proc.alive) {
        t.cancel();
        _tor = null;
        torStatus = 'OFF';
        if (_xrayFor == 'tor') unawaited(_xrayStop());
        _emit('yomihub/vpn', 'torStatus', torStatus);
      }
    });
  }

  Future<void> _torStop() async {
    final t = _tor;
    _tor = null;
    if (_xrayFor == 'tor') await _xrayStop();
    await t?.kill();
    torStatus = 'OFF';
    _emit('yomihub/vpn', 'torStatus', torStatus);
  }

  Future<bool> _torControlCmd(List<String> cmds) async {
    if (_torControl == 0 || !(_tor?.alive ?? false)) return false;
    Socket? s;
    try {
      final cookie = await File(p.join((await _dataDir()).path, 'tor_data', 'control_auth_cookie')).readAsBytes();
      final hex = cookie.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      s = await Socket.connect(InternetAddress.loopbackIPv4, _torControl, timeout: const Duration(seconds: 5));
      final replies = StringBuffer();
      final sub = s.listen((d) => replies.write(utf8.decode(d, allowMalformed: true)));
      s.write('AUTHENTICATE $hex\r\n');
      for (final c in cmds) {
        s.write('$c\r\n');
      }
      s.write('QUIT\r\n');
      await s.flush();
      await Future.delayed(const Duration(milliseconds: 600));
      await sub.cancel();
      return replies.toString().contains('250 OK') && !replies.toString().contains('515');
    } catch (_) {
      return false;
    } finally {
      s?.destroy();
    }
  }

  // ───────────── OpenVPN (OpenVPN GUI) ─────────────

  static String? openVpnGui() {
    for (final base in [
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramW6432'],
      Platform.environment['ProgramFiles(x86)'],
    ]) {
      if (base == null) continue;
      final f = File(p.join(base, 'OpenVPN', 'bin', 'openvpn-gui.exe'));
      if (f.existsSync()) return f.path;
    }
    return null;
  }

  static String get _ovpnHome => p.join(Platform.environment['USERPROFILE'] ?? '', 'OpenVPN');
  static const _ovpnName = 'YomiHub';
  Timer? _ovpnPoll;

  Future<bool> _ovpnUp(Map<String, dynamic> a) async {
    final gui = openVpnGui();
    if (gui == null) {
      throw PlatformException(
        code: 'ovpn',
        message: tr('Windows cần OpenVPN GUI để tạo đường hầm (cần driver mạng ảo). Cài “OpenVPN Community” tại openvpn.net/community-downloads rồi bấm Kết nối lại.'),
      );
    }
    final cfgDir = Directory(p.join(_ovpnHome, 'config'));
    await cfgDir.create(recursive: true);
    var conf = '${a['config'] ?? ''}';
    final user = '${a['username'] ?? ''}';
    if (user.isNotEmpty) {
      final auth = File(p.join(cfgDir.path, '$_ovpnName.auth'));
      await auth.writeAsString('$user\n${a['password'] ?? ''}\n');
      conf = conf.replaceAll(RegExp(r'^\s*auth-user-pass.*$', multiLine: true), '');
      conf += '\nauth-user-pass $_ovpnName.auth\n';
    }
    await File(p.join(cfgDir.path, '$_ovpnName.ovpn')).writeAsString(conf);
    final log = File(p.join(_ovpnHome, 'log', '$_ovpnName.log'));
    try {
      if (log.existsSync()) await log.writeAsString('');
    } catch (_) {}
    await Process.start(gui, ['--command', 'connect', '$_ovpnName.ovpn'], mode: ProcessStartMode.detached);
    // When the GUI is not running yet, --command is ignored: start it.
    await Future.delayed(const Duration(seconds: 2));
    if (!await _ovpnLogHas('')) {
      await Process.start(gui, ['--connect', '$_ovpnName.ovpn'], mode: ProcessStartMode.detached);
    }
    _emit('yomihub/tunnels', 'ovpnState', 'connecting');
    _ovpnPoll?.cancel();
    var ticks = 0;
    _ovpnPoll = Timer.periodic(const Duration(seconds: 2), (t) async {
      ticks++;
      final text = await _ovpnLogText();
      if (text.contains('Initialization Sequence Completed')) {
        t.cancel();
        _emit('yomihub/tunnels', 'ovpnState', 'connected');
      } else if (text.contains('AUTH_FAILED') || text.contains('Exiting due to fatal error') || ticks > 45) {
        t.cancel();
        _emit('yomihub/tunnels', 'ovpnState', 'error');
      }
    });
    return true;
  }

  Future<String> _ovpnLogText() async {
    try {
      return await File(p.join(_ovpnHome, 'log', '$_ovpnName.log')).readAsString();
    } catch (_) {
      return '';
    }
  }

  Future<bool> _ovpnLogHas(String s) async {
    final t = await _ovpnLogText();
    return t.isNotEmpty && t.contains(s);
  }

  Future<List<String>> _ovpnLogTail() async {
    final t = await _ovpnLogText();
    final lines = const LineSplitter().convert(t);
    return lines.length > 40 ? lines.sublist(lines.length - 40) : lines;
  }

  Future<bool> _ovpnDown() async {
    _ovpnPoll?.cancel();
    final gui = openVpnGui();
    if (gui != null) {
      await Process.start(gui, ['--command', 'disconnect', '$_ovpnName.ovpn'], mode: ProcessStartMode.detached);
    }
    _emit('yomihub/tunnels', 'ovpnState', 'disconnected');
    return true;
  }

  Future<void> shutdown() async {
    await setSystemProxy(null);
    await _xrayStop();
    await _torStop();
  }

  // ───────────── Windows system proxy ("Toàn bộ máy tính") ─────────────

  static const _inetKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';
  String? _activeSystemProxy;

  Future<File> get _savedProxyFile async => File(p.join((await _dataDir()).path, 'system_proxy_backup.json'));

  Future<String?> _regQuery(String name) async {
    final out = await WinProc.run('reg', ['query', _inetKey, '/v', name]);
    final m = RegExp('$name\\s+REG_\\w+\\s+(.*)\$', multiLine: true).firstMatch(out);
    return m?.group(1)?.trim();
  }

  Future<void> _regSet(String name, String type, String value) =>
      WinProc.run('reg', ['add', _inetKey, '/v', name, '/t', type, '/d', value, '/f']);

  Future<void> _regDelete(String name) => WinProc.run('reg', ['delete', _inetKey, '/v', name, '/f']);

  /// Points Windows (WinINet: Edge, Chrome, most apps) at [hostPort], or
  /// restores the user's previous settings when null.
  Future<void> setSystemProxy(String? hostPort) async {
    if (!Platform.isWindows) return;
    if (hostPort == _activeSystemProxy) return;
    final backup = await _savedProxyFile;
    if (hostPort != null) {
      if (!backup.existsSync()) {
        await backup.writeAsString(jsonEncode({
          'enable': await _regQuery('ProxyEnable'),
          'server': await _regQuery('ProxyServer'),
          'override': await _regQuery('ProxyOverride'),
        }));
      }
      await _regSet('ProxyEnable', 'REG_DWORD', '1');
      await _regSet('ProxyServer', 'REG_SZ', hostPort);
      await _regSet('ProxyOverride', 'REG_SZ', '<local>;localhost;127.*;10.*;192.168.*');
      _activeSystemProxy = hostPort;
    } else {
      await restoreSystemProxy();
    }
    _notifyInternetSettings();
  }

  /// Restores the proxy settings saved before YomiHub changed them (also
  /// run at start-up, in case YomiHub was killed while "whole device" was on).
  Future<void> restoreSystemProxy() async {
    final backup = await _savedProxyFile;
    if (!backup.existsSync()) {
      _activeSystemProxy = null;
      return;
    }
    try {
      final j = jsonDecode(await backup.readAsString()) as Map;
      final en = '${j['enable'] ?? '0x0'}';
      await _regSet('ProxyEnable', 'REG_DWORD', en.contains('1') ? '1' : '0');
      j['server'] == null ? await _regDelete('ProxyServer') : await _regSet('ProxyServer', 'REG_SZ', '${j['server']}');
      j['override'] == null ? await _regDelete('ProxyOverride') : await _regSet('ProxyOverride', 'REG_SZ', '${j['override']}');
    } catch (_) {}
    try {
      await backup.delete();
    } catch (_) {}
    _activeSystemProxy = null;
    _notifyInternetSettings();
  }

  void _notifyInternetSettings() {
    try {
      final wininet = DynamicLibrary.open('wininet.dll');
      final setOption = wininet.lookupFunction<Int32 Function(Pointer, Uint32, Pointer, Uint32), int Function(Pointer, int, Pointer, int)>(
        'InternetSetOptionW',
      );
      setOption(nullptr, 39 /*INTERNET_OPTION_SETTINGS_CHANGED*/, nullptr, 0);
      setOption(nullptr, 37 /*INTERNET_OPTION_REFRESH*/, nullptr, 0);
    } catch (_) {}
  }

  bool get systemProxyActive => _activeSystemProxy != null;
}

/// Same API as [MethodChannel] for the VPN code: Android talks to the
/// Kotlin side, Windows to [WinVpnBackend].
class VpnChannel {
  final String name;
  final MethodChannel _ch;
  VpnChannel(this.name) : _ch = MethodChannel(name);

  Future<T?> invokeMethod<T>(String method, [dynamic args]) async {
    if (Platform.isWindows) {
      final r = await WinVpnBackend.instance.invoke(name, method, args);
      return r as T?;
    }
    return _ch.invokeMethod<T>(method, args);
  }

  Future<List<T>?> invokeListMethod<T>(String method, [dynamic args]) async {
    final r = await invokeMethod<List>(method, args);
    return r?.cast<T>();
  }

  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? h) {
    if (Platform.isWindows) {
      WinVpnBackend.instance.setHandler(name, h);
    } else {
      _ch.setMethodCallHandler(h);
    }
  }
}
