import sys; sys.path.insert(0,'.')
from edit import edit
V='lib/yomihub/vpn/vpn_service.dart'
edit(V,"""  String _warpConfig(Map<String, dynamic> a, String ownPackage) {
    String endpoint = '${a['endpoint']}';
    final v4 = '${a['endpoint_v4'] ?? ''}';
    // Prefer the literal IPv4 endpoint: avoids DNS lookups that may be blocked.
    if (v4.isNotEmpty) {
      final host = v4.split(':').first;
      final port = endpoint.split(':').last;
      endpoint = '$host:${int.tryParse(port) == null ? 2408 : port}';
    }""","""  String _warpConfig(Map<String, dynamic> a, String ownPackage, {int? port}) {
    String endpoint = '${a['endpoint']}';
    final v4 = '${a['endpoint_v4'] ?? ''}';
    // Prefer the literal IPv4 endpoint: avoids DNS lookups that may be blocked.
    if (v4.isNotEmpty) {
      final host = v4.split(':').first;
      final p = endpoint.split(':').last;
      endpoint = '$host:${port ?? (int.tryParse(p) == null ? 2408 : p)}';
    } else if (port != null) {
      endpoint = '${endpoint.split(':').first}:$port';
    }""")
edit(V,"""      final acc = warpAccount ?? await _registerWarp();
      final pkg = await _channel.invokeMethod<String>('packageName') ?? 'com.yomihub.app';
      await _channel.invokeMethod('warpUp', {'config': _warpConfig(acc, pkg)});
      warpEnabled = true;
      warpUp = true;
      await _put('warpEnabled', true);""","""      final acc = warpAccount ?? await _registerWarp();
      final pkg = await _channel.invokeMethod<String>('packageName') ?? 'com.yomihub.app';
      // 0.5.2 (Note 9 on an office Wi-Fi: "Đã kết nối" was shown while the
      // WireGuard log repeated "Handshake did not complete" and no app had
      // Internet): the tunnel is checked through Cloudflare's trace page;
      // if UDP 2408 is blocked the other ports WARP answers on are tried.
      final saved = int.tryParse('${_get('warpPort', '')}');
      final ports = <int?>[saved, if (saved != 2408) null, 500, 4500, 1701, 854]
          .where((p) => p != saved || p != null)
          .toList();
      var reached = !Platform.isAndroid;
      for (final port in Platform.isAndroid ? ports.toSet() : const <int?>{null}) {
        await _channel.invokeMethod('warpUp', {'config': _warpConfig(acc, pkg, port: port)});
        if (!Platform.isAndroid) break;
        if (await _warpReachable()) {
          reached = true;
          await _put('warpPort', port?.toString() ?? '');
          AppLogger.log('[VPN] WARP đã bắt tay với Cloudflare (cổng ${port ?? 2408})',
              logLevel: LogLevel.info, always: true);
          break;
        }
        AppLogger.log('[VPN] WARP: không bắt tay được qua cổng UDP ${port ?? 2408}',
            logLevel: LogLevel.warning);
      }
      if (!reached) {
        lastError = tr('WARP đã bật nhưng không bắt tay được với máy chủ Cloudflare – mạng hiện tại có thể chặn UDP (cổng 2408, 500, 4500, 1701, 854). Hãy thử mạng khác, hoặc dùng Tor / WireGuard.');
      }
      warpEnabled = true;
      warpUp = reached;
      await _put('warpEnabled', true);""")
edit(V,"""  Future<void> setWarpMode(WarpMode m) async {""","""  /// True when YomiHub's own traffic (always inside the WARP tunnel's app
  /// scope) comes out at Cloudflare with WARP on.
  Future<bool> _warpReachable() async {
    for (var i = 0; i < 2; i++) {
      final c = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      try {
        final rq = await c.getUrl(Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'));
        final rs = await rq.close().timeout(const Duration(seconds: 7));
        final body = await rs.transform(utf8.decoder).join().timeout(const Duration(seconds: 5));
        if (body.contains('warp=on') || body.contains('warp=plus')) return true;
      } catch (_) {
      } finally {
        c.close(force: true);
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  Future<void> setWarpMode(WarpMode m) async {""")
