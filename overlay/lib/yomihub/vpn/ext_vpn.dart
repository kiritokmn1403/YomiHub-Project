import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/vpn/vpn_service.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:mangayomi/yomihub/vpn/vpn_tunnels.dart';
import 'package:url_launcher/url_launcher.dart';

/// One Urban VPN location (country) of the bundled snapshot.
class UrbanLocation {
  final String cc;
  final String name;
  final String group;
  final String host;
  final int port;
  UrbanLocation(this.cc, this.name, this.group, this.host, this.port);
  String get country => cc == 'uk' ? 'GB' : cc.toUpperCase();
}

/// YomiHub 0.1.8: AdGuard VPN and Urban VPN in "VPN & DNS › Dịch vụ VPN".
///
/// Neither service publishes an API, so YomiHub works with the official
/// apps and the user's own account, the way the GitHub projects in the sheet
/// do:
///
/// **AdGuard VPN** (AdguardTeam): the official app (Android / Windows)
/// does the VPN. YomiHub can
///  * open / install the app and see whether its VPN is up (whole device);
///  * use the app's SOCKS5 proxy mode ("Chỉ YomiHub"): extensions, WebView,
///    the browser and downloads go through `socks5://127.0.0.1:<port>` with
///    the same scope settings as every other service;
///  * AdGuard's filters themselves are part of YomiHub's AdBlock.
///
/// **Urban VPN** (Urban-Proxy, urbanvpn repos): like Urban Proxy, YomiHub
/// imports the OpenVPN configuration and login of the user's own Urban VPN
/// installation (.ovpn + account) once and connects with its built-in
/// OpenVPN engine to any of the 83 locations, switching country without the
/// official app. No credentials are bundled or uploaded. "Toàn thiết bị"
/// can also just open the official app.
class YomiExtVpn {
  YomiExtVpn._();
  static const _tools = MethodChannel('com.yomihub/tools');
  static const _secure = FlutterSecureStorage();

  // ───────── AdGuard VPN ─────────
  static const adguardPackage = 'com.adguard.vpn';
  static const adguardSite = 'https://adguard-vpn.com/';

  static int get adguardPort => YomiPrefs.get<int>('adguardSocksPort', 1080);
  static String get adguardHost => YomiPrefs.get<String>('adguardSocksHost', '127.0.0.1');

  static Future<bool> appInstalled(String pkg) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _tools.invokeMethod<bool>('appInstalled', {'package': pkg}) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// A VPN of another app (AdGuard VPN, Urban VPN…) is up on the device.
  static Future<bool> systemVpnActive({String? nameHint}) async {
    if (Platform.isAndroid) {
      try {
        return await _tools.invokeMethod<bool>('systemVpnActive') ?? false;
      } catch (_) {
        return false;
      }
    }
    try {
      final ifs = await NetworkInterface.list(includeLoopback: false);
      return ifs.any((i) {
        final n = i.name.toLowerCase();
        if (nameHint != null) return n.contains(nameHint);
        return n.contains('adguard') || n.contains('urban') || n.contains('tap') || n.contains('wintun') || n.contains('vpn');
      });
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _findWindowsExe(List<String> dirs, RegExp name) async {
    final roots = [
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramFiles(x86)'],
      Platform.environment['LOCALAPPDATA'],
      if (Platform.environment['LOCALAPPDATA'] != null) '${Platform.environment['LOCALAPPDATA']}\\Programs',
    ].whereType<String>();
    for (final r in roots) {
      for (final d in dirs) {
        final dir = Directory('$r\\$d');
        if (!await dir.exists()) continue;
        try {
          await for (final f in dir.list(recursive: true, followLinks: false)) {
            if (f is File && name.hasMatch(f.path.split('\\').last)) return f.path;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Opens the official app (or its download page when it isn't installed).
  static Future<bool> openApp({required String package, required List<String> winDirs, required RegExp winExe, required String site}) async {
    if (Platform.isAndroid) {
      try {
        final ok = await _tools.invokeMethod<bool>('openComponent', {'package': package}) ?? false;
        if (ok) return true;
      } catch (_) {}
      return launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=$package'),
          mode: LaunchMode.externalApplication);
    }
    if (Platform.isWindows) {
      final exe = await _findWindowsExe(winDirs, winExe);
      if (exe != null) {
        await Process.start(exe, const [], mode: ProcessStartMode.detached);
        return true;
      }
    }
    return launchUrl(Uri.parse(site), mode: LaunchMode.externalApplication);
  }

  static Future<bool> openAdGuard() => openApp(
        package: adguardPackage,
        winDirs: const ['AdGuardVpn', 'AdGuard VPN'],
        winExe: RegExp(r'^AdGuardVpn\.exe$', caseSensitive: false),
        site: adguardSite,
      );

  /// "Chỉ YomiHub": routes YomiHub through AdGuard VPN's SOCKS5 proxy.
  static Future<String?> setAdGuardSocks(bool on, {String? host, int? port}) async {
    final vpn = YomiVpnService.instance;
    if (host != null) await YomiPrefs.set('adguardSocksHost', host.trim());
    if (port != null) await YomiPrefs.set('adguardSocksPort', port);
    if (!on) {
      if (YomiPrefs.get<String>('proxyOwner', '') == 'adguard') {
        await vpn.setProxy(enabled: false, url: YomiVpnState.proxyUrl);
        await YomiPrefs.set('proxyOwner', '');
      }
      return null;
    }
    await vpn.stopAllExcept(VpnKind.adguard);
    await YomiPrefs.set('proxyOwner', 'adguard');
    final e = await vpn.setProxy(enabled: true, url: 'socks5://$adguardHost:$adguardPort');
    if (e != null) {
      await YomiPrefs.set('proxyOwner', '');
      return e;
    }
    // is AdGuard VPN's SOCKS5 really listening?
    try {
      final s = await Socket.connect(adguardHost, adguardPort, timeout: const Duration(seconds: 3));
      s.destroy();
    } catch (_) {
      return tr('Chưa thấy proxy SOCKS5 của AdGuard VPN ở {p0}:{p1}. Mở AdGuard VPN, chọn chế độ SOCKS5 và bấm Kết nối (cổng phải trùng với cổng ở đây).', {'p0': adguardHost, 'p1': adguardPort});
    }
    return null;
  }

  static bool get adguardSocksOn =>
      YomiVpnState.proxyEnabled && YomiPrefs.get<String>('proxyOwner', '') == 'adguard';

  // ───────── Urban VPN ─────────
  static const urbanPackage = 'com.urbanvpn.android';
  static const urbanSite = 'https://www.urban-vpn.com/';
  static List<UrbanLocation>? _locations;
  static String snapshot = '';

  static Future<List<UrbanLocation>> locations() async {
    if (_locations != null) return _locations!;
    try {
      final j = jsonDecode(await rootBundle.loadString('assets/yomihub_vpn/urban_locations.json')) as Map;
      snapshot = '${j['snapshot'] ?? ''}';
      _locations = [
        for (final l in (j['locations'] as List))
          UrbanLocation('${l['cc']}', '${l['name']}', '${l['group']}', '${l['host']}', (l['port'] as num).toInt()),
      ]..sort((a, b) => (a.name.isEmpty ? a.cc : a.name).compareTo(b.name.isEmpty ? b.cc : b.name));
    } catch (_) {
      _locations = [];
    }
    return _locations!;
  }

  static Future<bool> openUrban() => openApp(
        package: urbanPackage,
        winDirs: const ['Urban VPN', 'UrbanVPN', 'Urban VPN Desktop'],
        winExe: RegExp(r'^Urban.*VPN.*\.exe$', caseSensitive: false),
        site: urbanSite,
      );

  static Future<bool> get urbanImported async =>
      (await _secure.read(key: 'urban_cert') ?? '').isNotEmpty;

  static String? _section(String text, String tag) {
    final m = RegExp('<$tag>\\s*([\\s\\S]*?)\\s*</$tag>').firstMatch(text);
    return m?.group(1)?.trim();
  }

  /// Imports the .ovpn of the user's Urban VPN installation (it holds the
  /// client certificate and key) plus the account login.
  static Future<String?> importUrban(String ovpn, {required String username, required String password}) async {
    final cert = _section(ovpn, 'cert');
    final key = _section(ovpn, 'key');
    if (cert == null || key == null || !cert.contains('BEGIN CERTIFICATE') || !key.contains('PRIVATE KEY')) {
      return tr('File .ovpn không có <cert> và <key> của Urban VPN');
    }
    await _secure.write(key: 'urban_cert', value: cert);
    await _secure.write(key: 'urban_key', value: key);
    final ca = _section(ovpn, 'ca');
    await _secure.write(key: 'urban_ca', value: ca ?? '');
    final tlsAuth = _section(ovpn, 'tls-auth') ?? _section(ovpn, 'tls-crypt');
    await _secure.write(key: 'urban_tls', value: tlsAuth ?? '');
    await _secure.write(key: 'urban_tls_kind', value: _section(ovpn, 'tls-crypt') != null ? 'tls-crypt' : (tlsAuth != null ? 'tls-auth' : ''));
    await _secure.write(key: 'urban_user', value: username.trim());
    await _secure.write(key: 'urban_pass', value: password);
    return null;
  }

  /// Windows: looks for the .ovpn that Urban VPN Desktop installs.
  static Future<String?> findUrbanOvpnWindows() async {
    if (!Platform.isWindows) return null;
    final p = await _findWindowsExe(
      const ['Urban VPN', 'UrbanVPN', 'Urban VPN Desktop'],
      RegExp(r'\.ovpn$', caseSensitive: false),
    );
    if (p != null) return p;
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      for (final d in ['Urban VPN', 'UrbanVPN', 'urban-vpn-desktop']) {
        final dir = Directory('$appData\\$d');
        if (!await dir.exists()) continue;
        await for (final f in dir.list(recursive: true, followLinks: false)) {
          if (f is File && f.path.toLowerCase().endsWith('.ovpn')) return f.path;
        }
      }
    }
    return null;
  }

  static Future<void> forgetUrban() async {
    for (final k in ['urban_cert', 'urban_key', 'urban_ca', 'urban_tls', 'urban_tls_kind', 'urban_user', 'urban_pass']) {
      await _secure.delete(key: k);
    }
  }

  /// OpenVPN profile for one location (same settings as Urban Proxy).
  static Future<String> urbanProfile(UrbanLocation l) async {
    final cert = await _secure.read(key: 'urban_cert') ?? '';
    final key = await _secure.read(key: 'urban_key') ?? '';
    final ca = await _secure.read(key: 'urban_ca') ?? '';
    final tls = await _secure.read(key: 'urban_tls') ?? '';
    final tlsKind = await _secure.read(key: 'urban_tls_kind') ?? '';
    final b = StringBuffer()
      ..writeln('client')
      ..writeln('dev tun')
      ..writeln('proto tcp-client')
      ..writeln('remote ${l.host} ${l.port}')
      ..writeln('nobind')
      ..writeln('persist-key')
      ..writeln('auth-user-pass')
      ..writeln('auth-nocache')
      ..writeln('data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC')
      ..writeln('data-ciphers-fallback AES-256-CBC')
      ..writeln('allow-compression asym')
      ..writeln('comp-lzo no')
      ..writeln('redirect-gateway def1')
      ..writeln('connect-timeout 10')
      ..writeln('connect-retry 2 5')
      ..writeln('resolv-retry 10')
      ..writeln('verb 3');
    if (ca.isNotEmpty) {
      b.writeln('<ca>\n$ca\n</ca>');
    } else {
      // pin the server the way Urban Proxy does when there is no CA
      final der = base64.decode(cert
          .split('\n')
          .where((l) => !l.startsWith('-----') && l.trim().isNotEmpty)
          .join());
      final fp = sha256.convert(der).bytes.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
      b.writeln('peer-fingerprint $fp');
    }
    if (tls.isNotEmpty && tlsKind.isNotEmpty) {
      b.writeln('<$tlsKind>\n$tls\n</$tlsKind>');
      if (tlsKind == 'tls-auth') b.writeln('key-direction 1');
    }
    b
      ..writeln('<cert>\n$cert\n</cert>')
      ..writeln('<key>\n$key\n</key>');
    return b.toString();
  }

  static String get urbanCountry => YomiPrefs.get<String>('urbanCountry', 'us');

  static Future<String?> connectUrban(String cc) async {
    final all = await locations();
    final l = all.where((e) => e.cc == cc).firstOrNull;
    if (l == null) return tr('Không có địa điểm {p0}', {'p0': cc});
    if (!await urbanImported) return tr('Chưa nhập cấu hình Urban VPN');
    await YomiPrefs.set('urbanCountry', cc);
    final vpn = YomiVpnService.instance;
    await vpn.stopAllExcept(VpnKind.urban);
    final p = VpnProfile(
      id: 'urban_$cc',
      name: 'Urban VPN • ${l.name.isEmpty ? l.country : l.name}',
      type: TunnelType.openvpn,
      config: await urbanProfile(l),
      username: await _secure.read(key: 'urban_user') ?? '',
      password: await _secure.read(key: 'urban_pass') ?? '',
      country: l.country,
    );
    final e = await YomiTunnels.instance.connectGenerated(p, 'urban_');
    if (e != null) AppLogger.log('Urban VPN $cc: $e', logLevel: LogLevel.error);
    return e;
  }
}
