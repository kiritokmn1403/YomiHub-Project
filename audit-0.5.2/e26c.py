import sys; sys.path.insert(0,'.')
from edit import edit
V='lib/yomihub/vpn/vpn_service.dart'
edit(V,"""      if (!reached) {
        lastError = tr('WARP đã bật nhưng không bắt tay được với máy chủ Cloudflare – mạng hiện tại có thể chặn UDP (cổng 2408, 500, 4500, 1701, 854). Hãy thử mạng khác, hoặc dùng Tor / WireGuard.');
      }
      warpEnabled = true;
      warpUp = reached;
      await _put('warpEnabled', true);""","""      if (!reached) {
        // A tunnel without a handshake cuts every app in its scope off the
        // Internet - take it down and say why.
        try {
          await _channel.invokeMethod('warpDown');
        } catch (_) {}
        warpEnabled = false;
        warpUp = false;
        await _put('warpEnabled', false);
        lastError = tr('WARP đã bật nhưng không bắt tay được với máy chủ Cloudflare – mạng hiện tại có thể chặn UDP (cổng 2408, 500, 4500, 1701, 854). Hãy thử mạng khác, hoặc dùng Tor / WireGuard.');
        AppLogger.log('[VPN] $lastError', logLevel: LogLevel.warning);
        notifyListeners();
        return;
      }
      warpEnabled = true;
      warpUp = true;
      await _put('warpEnabled', true);""")
edit(V,"""    for (var i = 0; i < 2; i++) {
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
    return false;""","""    await Future<void>.delayed(const Duration(seconds: 1));
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final rq = await c.getUrl(Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'));
      final rs = await rq.close().timeout(const Duration(seconds: 6));
      final body = await rs.transform(utf8.decoder).join().timeout(const Duration(seconds: 4));
      return body.contains('warp=on') || body.contains('warp=plus');
    } catch (_) {
      return false;
    } finally {
      c.close(force: true);
    }""")
