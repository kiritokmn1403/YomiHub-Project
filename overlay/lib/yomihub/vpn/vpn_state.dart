/// YomiHub VPN: the bits of VPN state the HTTP layer reads on every request.
///
/// Kept free of Flutter/Hive so MClient can consult it synchronously and
/// cheaply. [YomiVpnService] owns persistence and keeps this in sync.
class YomiVpnState {
  YomiVpnState._();

  /// Bumped whenever routing changes, so cached HTTP clients get rebuilt.
  static int revision = 0;

  static bool torEnabled = false;
  static bool torRunning = false;
  static int torHttpPort = 0;
  static int torSocksPort = 0;

  /// Block routed traffic while Tor is not connected instead of leaking it.
  static bool killSwitch = true;

  /// Custom HTTP(S)/SOCKS5 proxy (paid VPN providers, Hola-style residential
  /// proxies, a proxy on your own PC…). Used for sources Tor doesn't route.
  static bool proxyEnabled = false;
  static String proxyUrl = '';

  /// Xray core (Mihon Proxy) running as a local HTTP proxy.
  static bool xrayRunning = false;
  static int xrayHttpPort = 10809;

  static void bump() => revision++;

  // ── YomiHub 0.1.5: one in-app scope for whichever VPN service is on ──
  // (only one service runs at a time, so Tor, Mihon Proxy and the custom
  // proxy share these settings instead of keeping three copies).

  /// Route every extension (incl. covers, pages, downloads) through the VPN.
  static bool scopeAllSources = true;

  /// Extensions routed when [scopeAllSources] is off.
  static Set<int> scopeSources = {};

  /// Route every Booru site through the VPN by default (0.4.6).
  static bool scopeAllBooru = true;

  /// Booru sites routed when [scopeAllBooru] is off.
  static Set<String> scopeBooruSites = {};

  /// WebView mode: extension WebViews, Cloudflare solver, hidden WebViews.
  static bool scopeWebView = true;

  /// The in-app browser (Chromium tabs; Gecko tabs use their own proxy prefs).
  static bool scopeBrowser = true;

  static bool routes(int? sourceId) =>
      scopeAllSources || (sourceId != null && scopeSources.contains(sourceId));

  static bool routesBooru(String? siteId) =>
      scopeAllBooru || (siteId != null && scopeBooruSites.contains(siteId));

  /// Returns the current active VPN proxy URL if any service is on, or null.
  static String? activeProxy() {
    if (torEnabled) {
      if (torRunning && torHttpPort > 0) return 'http://127.0.0.1:$torHttpPort';
      // Port 9 (discard) refuses connections: nothing leaks outside Tor.
      if (killSwitch) return 'http://127.0.0.1:9';
    }
    if (xrayRunning && xrayHttpPort > 0) return 'http://127.0.0.1:$xrayHttpPort';
    if (proxyEnabled && proxyUrl.isNotEmpty) return proxyUrl;
    return null;
  }

  /// Proxy URL for a request made on behalf of [sourceId] (null = not a
  /// source request), or null to connect directly.
  static String? proxyFor(int? sourceId) {
    if (!routes(sourceId)) return null;
    return activeProxy();
  }

  /// Proxy URL for a Booru site request, or null to connect directly.
  static String? proxyForBooru(String? siteId) {
    if (!routesBooru(siteId)) return null;
    return activeProxy();
  }

  // ── YomiHub 0.5.7: Cloudflare clearance vs. route ──

  /// Proxy the in-app WebViews (Cloudflare solver, WebView mode) use on
  /// Android, null = direct. Mirrors YomiVpnService._applyBrowserProxy.
  static String? webViewProxy() {
    if (!scopeWebView) return null;
    if (torEnabled && torRunning && torHttpPort > 0) return 'http://127.0.0.1:$torHttpPort';
    if (xrayRunning && xrayHttpPort > 0) return 'http://127.0.0.1:$xrayHttpPort';
    if (proxyEnabled && proxyUrl.isNotEmpty) return proxyUrl;
    return null;
  }

  /// `cf_clearance` is bound to the IP address that solved the challenge.
  /// Returns a Vietnamese note for the log when the WebView and the
  /// extension ([extensionProxy], null = direct) leave through different
  /// routes, '' when they share one.
  static String routeNote(String? extensionProxy) {
    final w = webViewProxy() ?? '';
    final e = extensionProxy ?? '';
    if (w == e) return '';
    String name(String p) => p.isEmpty
        ? 'đi thẳng'
        : (p.endsWith(':9') ? 'bị Kill switch chặn (Tor chưa kết nối)' : 'qua VPN/proxy $p');
    return ' Lưu ý: WebView ${name(w)} còn tiện ích ${name(e)} – cf_clearance gắn với địa chỉ IP đã xác minh '
        'nên không dùng chung được giữa hai đường mạng; trong VPN & DNS › Phạm vi hãy bật (hoặc tắt) cùng lúc "WebView" và tiện ích này.';
  }

  // ── YomiHub 0.5.7: loopback never goes through a proxy ──

  /// Whether [host] is this device itself (localhost, 127.0.0.0/8, ::1).
  /// Requests to it must never be sent to Tor / the kill switch / a proxy.
  static bool isLoopbackHost(String host) {
    var h = host.trim().toLowerCase();
    if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
    if (h.endsWith('.')) h = h.substring(0, h.length - 1);
    if (h.isEmpty) return false;
    if (h == 'localhost' || h.endsWith('.localhost')) return true;
    if (h == '::1' || h == '0:0:0:0:0:0:0:1') return true;
    if (h.startsWith('::ffff:')) h = h.substring(7);
    final m = RegExp(r'^127\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(h);
    if (m == null) return false;
    for (var i = 1; i <= 3; i++) {
      if (int.parse(m.group(i)!) > 255) return false;
    }
    return true;
  }

  /// Loopback servers that fetch web pages themselves, inside the app's JVM
  /// (Kotatsu 47350, IReader 47360). Their traffic follows [jvmBridgeProxy],
  /// not the HTTP client of the extension that calls them.
  static const Set<int> jvmBridgePorts = {47350, 47360};

  /// Proxy the in-process JVM bridges currently use for their own traffic
  /// (Android: follows the VPN when it covers every source), null = direct.
  static String? jvmBridgeProxy;

  /// True when a request routed through [proxy] targets a JVM bridge whose
  /// own traffic would NOT take that route - sending it on would reach the
  /// site with the real IP although the source is switched to VPN/Tor.
  static bool bridgeWouldLeak(Uri url, String? proxy) {
    if (proxy == null || proxy.isEmpty) return false;
    if (!isLoopbackHost(url.host) || !jvmBridgePorts.contains(url.port)) return false;
    return jvmBridgeProxy != proxy;
  }

  /// Normalises "host:port", "user:pass@host:port", "socks5://…".
  static String normaliseProxy(String input) {
    var t = input.trim();
    if (t.isEmpty) return '';
    if (!t.contains('://')) t = 'http://$t';
    final u = Uri.tryParse(t);
    if (u == null || u.host.isEmpty || !u.hasPort) return '';
    if (!const ['http', 'https', 'socks5', 'socks5h'].contains(u.scheme)) return '';
    return t;
  }
}
