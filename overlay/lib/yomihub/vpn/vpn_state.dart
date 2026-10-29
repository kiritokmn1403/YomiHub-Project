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

  /// WebView mode: extension WebViews, Cloudflare solver, hidden WebViews.
  static bool scopeWebView = true;

  /// The in-app browser (Chromium tabs; Gecko tabs use their own proxy prefs).
  static bool scopeBrowser = true;

  static bool routes(int? sourceId) =>
      scopeAllSources || (sourceId != null && scopeSources.contains(sourceId));

  /// Proxy URL for a request made on behalf of [sourceId] (null = not a
  /// source request), or null to connect directly.
  static String? proxyFor(int? sourceId) {
    if (!routes(sourceId)) return null;
    if (torEnabled) {
      if (torRunning && torHttpPort > 0) return 'http://127.0.0.1:$torHttpPort';
      // Port 9 (discard) refuses connections: nothing leaks outside Tor.
      if (killSwitch) return 'http://127.0.0.1:9';
    }
    if (xrayRunning && xrayHttpPort > 0) return 'http://127.0.0.1:$xrayHttpPort';
    if (proxyEnabled && proxyUrl.isNotEmpty) return proxyUrl;
    return null;
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
