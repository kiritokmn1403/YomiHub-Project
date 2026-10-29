import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'package:mangayomi/yomihub/net/chunk_proxy.dart';
import 'package:mangayomi/yomihub/cloudflare/cloak_solver.dart';
import 'package:mangayomi/yomihub/net/media_sniffer.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';

import 'dart:async';
import 'dart:io';

import 'package:mangayomi/eval/model/m_source.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    as flutter_inappwebview;
import 'package:mangayomi/models/settings.dart';
import 'package:http/io_client.dart';
import 'package:mangayomi/services/http/rhttp/src/model/settings.dart';
import 'package:mangayomi/utils/log/log.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/services/http/rhttp/rhttp.dart' as rhttp;
import 'package:mangayomi/services/http/doh/doh_resolver.dart';
import 'package:mangayomi/services/http/doh/doh_providers.dart';
import 'package:mangayomi/services/http/doh/doh_custom_store.dart';
import 'package:mangayomi/services/http/cf_proxy_store.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';
import 'package:mangayomi/yomihub/cloudflare/cf_challenge.dart';
import 'package:mangayomi/yomihub/cloudflare/cf_webfetch.dart';
import 'package:mangayomi/utils/localized_message.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

class MClient {
  MClient();
  // 0.2.3: Dart HttpClient with the same DNS fallback as rhttp (repo lists,
  // extension downloads). logs 4: x.noz.one / observeroftime.frama.io
  // 'Failed host lookup' although both resolve outside the phone's ISP DNS.
  static final defaultClient = IOClient(yomiDartHttpClient());
  // YomiHub 0.1.6: keyed by a signature string. Keyed by ClientSettings
  // (no ==/hashCode) every call built a brand-new native client, so the pool
  // grew with every request (memory + connection reuse lost).
  static final Map<String, Client> rhttpPool = {};
  static final Map<String, DnsSettings> _dnsCache = {};

  /// DNS-over-HTTPS settings for [provider], cached so clients can be reused.
  static DnsSettings dohSettings(DoHProvider provider) => _dnsCache.putIfAbsent(
    'doh:${provider.id}:${provider.url}',
    () => DnsSettings.dynamic(
      resolver: (host) => DoHResolver.resolve(host, provider: provider),
    ),
  );

  /// Client that resolves through Cloudflare DoH regardless of the DNS
  /// setting – used to retry requests the ISP's DNS refuses to resolve.
  static InterceptedClient dohFallback({bool showCloudFlareError = false}) =>
      init(showCloudFlareError: showCloudFlareError, forceDoh: true);
  static Client httpClient({
    Map<String, dynamic>? reqcopyWith,
    rhttp.ClientSettings? settings,
    int? sourceId,
    String? baseUrl,
    DnsSettings? dns,
    String dnsKey = '',
  }) {
    // YomiHub VPN: route this request through Tor when the source (or every
    // source) is switched to Tor in Settings > VPN.
    final torProxy = (reqcopyWith?["noProxy"] ?? false)
        ? null
        : YomiVpnState.proxyFor(sourceId ?? reqcopyWith?["yomihubSourceId"] as int?);
    if (!(reqcopyWith?["useDartHttpClient"] ?? false)) {
      try {
        final callerSettings = settings;
        settings ??= rhttp.ClientSettings(
          throwOnStatusCode: false,
          proxySettings: reqcopyWith?["noProxy"] ?? false
              ? const rhttp.ProxySettings.noProxy()
              : null,
          timeout: reqcopyWith?["timeout"] != null
              ? Duration(seconds: reqcopyWith?["timeout"])
              : null,
          timeoutSettings: TimeoutSettings(
            connectTimeout: reqcopyWith?["connectTimeout"] != null
                ? Duration(seconds: reqcopyWith?["connectTimeout"])
                : null,
          ),
          tlsSettings: rhttp.TlsSettings(
            verifyCertificates: reqcopyWith?["verifyCertificates"] ?? false,
          ),
        );
        if (dns != null) settings = settings.copyWith(dnsSettings: dns);
        if (torProxy != null) {
          settings = settings.copyWith(
            proxySettings: rhttp.StaticProxy(
              url: torProxy,
              condition: rhttp.ProxyCondition.all,
            ),
          );
        }
        final s = settings;
        final key = callerSettings != null
            ? 'c${identityHashCode(callerSettings)}|$torProxy|$dnsKey'
            : 'd|${reqcopyWith?["noProxy"]}|${reqcopyWith?["timeout"]}|'
                  '${reqcopyWith?["connectTimeout"]}|'
                  '${reqcopyWith?["verifyCertificates"]}|$torProxy|$dnsKey';
        final existing = rhttpPool[key];
        if (existing is rhttp.RhttpCompatibleClient && existing.client.ref.isDisposed) {
          rhttpPool.remove(key);
        }
        final rawClient = rhttpPool.putIfAbsent(key, () {
          return rhttp.RhttpCompatibleClient.createSync(settings: s);
        });
        return _PooledClientWrapper(rawClient, key, s, baseUrl ?? (reqcopyWith?['baseUrl'] as String?));
      } catch (_) {}
    }
    if (torProxy != null && !torProxy.startsWith('socks')) {
      return _dartProxyClients.putIfAbsent(torProxy, () {
        final hc = HttpClient();
        final pu = Uri.parse(torProxy);
        hc.findProxy = (_) => 'PROXY ${pu.host}:${pu.port}';
        if (pu.userInfo.isNotEmpty) {
          final parts = pu.userInfo.split(':');
          hc.addProxyCredentials(
            pu.host,
            pu.port,
            '',
            HttpClientBasicCredentials(
              Uri.decodeComponent(parts.first),
              parts.length > 1 ? Uri.decodeComponent(parts.sublist(1).join(':')) : '',
            ),
          );
        }
        return IOClient(hc);
      });
    }
    return defaultClient;
  }

  static final Map<String, Client> _dartProxyClients = {};

  static InterceptedClient init({
    MSource? source,
    Map<String, dynamic>? reqcopyWith,
    rhttp.ClientSettings? settings,
    bool showCloudFlareError = true,
    bool forceDoh = false,
  }) {
    final appSettings = settingsRepository.currentOrNull;
    final useDoH = appSettings?.doHEnabled ?? false;
    final doHProviderId = appSettings?.doHProviderId;

    DnsSettings? dnsSettings;
    String dnsKey = '';
    if (forceDoh) {
      dnsSettings = dohSettings(DoHProviders.cloudflare);
      dnsKey = 'doh-fallback';
    } else if (useDoH && doHProviderId != null) {
      // Use DoH resolver with the selected provider — either a preset or, when
      // the custom sentinel id is set, one built from the user's saved URL.
      final provider = doHProviderId == DoHProviders.customId
          ? (DohCustomStore.url.trim().isNotEmpty
                ? DoHProviders.custom(DohCustomStore.url.trim())
                : null)
          : DoHProviders.byId[doHProviderId];
      if (provider != null) {
        dnsSettings = dohSettings(provider);
        dnsKey = 'doh:${provider.id}:${provider.url}';
      }
    } else if (customDns != null && customDns!.trim().isNotEmpty) {
      // Fallback to custom static DNS
      final ip = customDns!.trim();
      dnsKey = 'static:$ip';
      dnsSettings = _dnsCache.putIfAbsent(
        dnsKey,
        () => DnsSettings.dynamic(resolver: (host) async => [ip]),
      );
    } else if (!Platform.isLinux) {
      // YomiHub 0.2.2: system DNS first, DoH (Cloudflare → Google, bootstrap
      // IPs) when the system/ISP resolver fails. logs 3: hentaivn.show and
      // api.fikfap.com did not resolve on the phone's network although both
      // exist (VN ISP DNS filtering) → "RhttpConnectionException".
      dnsKey = 'sys+doh';
      dnsSettings = _dnsCache.putIfAbsent(
        dnsKey,
        () => DnsSettings.dynamic(resolver: yomiSystemThenDoh),
      );
    }

    return InterceptedClient.build(
      client: httpClient(
        settings: settings,
        reqcopyWith: reqcopyWith,
        sourceId: source?.id,
        baseUrl: source?.baseUrl ?? (reqcopyWith?['baseUrl'] as String?),
        dns: dnsSettings,
        dnsKey: dnsKey,
      ),
      retryPolicy: ResolveCloudFlareChallenge(showCloudFlareError),
      interceptors: [
        // YomiHub 0.1.7: "Cưỡng chế đổi URL" (must run before cookies)
        YomiUrlRewriteInterceptor(),
        MCookieManager(reqcopyWith),
        // YomiHub 0.4.1: Must run BEFORE LoggerInterceptor so WebView fallback can convert 403 into 200 before logging/error
        YomiCfFallbackInterceptor(showCloudFlareError),
        LoggerInterceptor(showCloudFlareError),
      ],
    );
  }

  // Matches request/stored hosts either way (exact, or one a subdomain of
  // the other) on a real dot boundary - a plain host.contains(stored) check
  // only matched when the stored host happened to be the shorter one, so a
  // cookie captured under a more specific host (e.g. the WebView landing on
  // "www.example.com") never got attached to requests against the bare
  // domain "example.com" a source actually scrapes, leaving Cloudflare
  // looking "unresolved" even right after a successful manual bypass.
  static bool _hostsMatch(String a, String b) {
    return a == b || a.endsWith('.$b') || b.endsWith('.$a') || a.contains(b);
  }

  static Map<String, String> getCookiesPref(String url) {
    final cookiesList = settingsRepository.currentOrNull?.cookiesList ?? [];
    if (cookiesList.isEmpty) return {};
    final host = Uri.parse(url).host;
    final matching = cookiesList.where(
      (element) =>
          element.host != null &&
          element.cookie != null &&
          element.cookie!.isNotEmpty &&
          _hostsMatch(host, element.host!),
    );
    if (matching.isEmpty) return {};
    final cookieMap = <String, String>{};
    for (final entry in matching) {
      for (final pair in entry.cookie!.split(';')) {
        final trimmed = pair.trim();
        if (trimmed.isEmpty) continue;
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final val = parts.sublist(1).join('=').trim();
          cookieMap[key] = val;
        }
      }
    }
    if (cookieMap.isEmpty) return {};
    final combined = cookieMap.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    return {HttpHeaders.cookieHeader: combined};
  }

  static Future<void> setCookie(
    String url,
    String ua,
    flutter_inappwebview.InAppWebViewController? webViewController, {
    String? cookie,
  }) async {
    List<String> cookies = [];
    // if incoming cookie is not empty, use it first
    if (cookie != null && cookie.isNotEmpty) {
      cookies = cookie
          .split(RegExp('(?<=)(,)(?=[^;]+?=)'))
          .where((cookie) => cookie.isNotEmpty)
          .toList();
    } else if (!Platform.isLinux) {
      cookies =
          (await flutter_inappwebview.CookieManager.instance(
                webViewEnvironment: webViewEnvironment,
              ).getCookies(
                url: flutter_inappwebview.WebUri(url),
                webViewController: webViewController,
              ))
              .map((e) => "${e.name}=${e.value}")
              .toList();
    }
    if (cookies.isNotEmpty) {
      final host = Uri.parse(url).host;
      final newCookie = cookies.join("; ");
      final existingCookies = settingsRepository.current.cookiesList ?? [];
      final filteredCookies = removeCookiesForHost(existingCookies, host);
      filteredCookies.add(
        MCookie()
          ..host = host
          ..cookie = newCookie,
      );
      await settingsRepository.update((s) => s.cookiesList = filteredCookies);
      if (newCookie.contains('cf_clearance=')) YomiCf.rememberUa(host, ua);
    }
    if (ua.isNotEmpty) {
      await settingsRepository.update((s) => s.userAgent = ua);
    }
  }

  static List<MCookie> removeCookiesForHost(
    List<MCookie> allCookies,
    String host,
  ) {
    return allCookies
        .where((cookie) => !_hostsMatch(host, cookie.host!))
        .toList();
  }

  static Future<void> deleteAllCookies(String url) async {
    final oldCookies = settingsRepository.current.cookiesList ?? [];
    final host = Uri.parse(url).host;
    final newCookies = removeCookiesForHost(oldCookies, host);
    await settingsRepository.update((s) => s.cookiesList = newCookies);
  }
}

class MCookieManager extends InterceptorContract {
  MCookieManager(this.reqcopyWith);
  Map<String, dynamic>? reqcopyWith;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    // YomiHub 0.2.0: logs.txt 07/10 – "type 'List<dynamic>' is not a subtype
    // of type 'String'" thrown from the header map here broke AVSub's
    // getPopular. Normalise the headers to plain strings first and never let
    // cookie handling fail the request.
    try {
      _normaliseHeaders(request);
    } catch (_) {} // 0.2.3: never let header cleanup skip the cookies
    try {
      await _applyCookies(request);
    } catch (e) {
      AppLogger.logOnce('cookie:${request.url.host}',
          'Cookie interceptor skipped for ${request.url.host}: $e');
    }
    return _applyOptions(request);
  }

  static void _normaliseHeaders(BaseRequest request) {
    try {
      final clean = <String, String>{};
      final raw = request.headers as dynamic;
      final keys = (raw.keys as Iterable).toList();
      for (final dynamic k in keys) {
        try {
          final dynamic v = raw[k];
          if (k == null || v == null) continue;
          final keyStr = k is List ? k.join(',') : '$k';
          final valStr = v is List
              ? v.join(keyStr.toLowerCase() == 'cookie' ? '; ' : ', ')
              : '$v';
          clean[keyStr] = valStr;
        } catch (_) {}
      }
      request.headers.clear();
      request.headers.addAll(clean);
    } catch (_) {}
  }

  Future<void> _applyCookies(BaseRequest request) async {
    try {
      final cookie = MClient.getCookiesPref(request.url.toString());
      if (cookie.isNotEmpty) {
        final settings = await settingsRepository.currentAsync;
        final userAgent = settings?.userAgent;
        final stored = cookie[HttpHeaders.cookieHeader] ?? '';
        String? own;
        try {
          own = request.headers[HttpHeaders.cookieHeader] ??
              request.headers['Cookie'];
        } catch (_) {}

        if (own == null || own.isEmpty) {
          try {
            request.headers.addAll(cookie);
          } catch (_) {}
        } else if (!own.contains('cf_clearance=')) {
          final cf = RegExp(r'cf_clearance=[^;]+').firstMatch(stored)?.group(0);
          if (cf != null) {
            try {
              request.headers[HttpHeaders.cookieHeader] = '$own; $cf';
            } catch (_) {}
          }
        }

        String? currentCookies;
        try {
          currentCookies = request.headers[HttpHeaders.cookieHeader] ??
              request.headers['Cookie'];
        } catch (_) {}

        final cfUa = (currentCookies ?? '').contains('cf_clearance=')
            ? YomiCf.uaFor(request.url.host)
            : null;
        if (cfUa != null) {
          try {
            request.headers.removeWhere(
              (k, _) => k.toLowerCase() == HttpHeaders.userAgentHeader,
            );
            request.headers[HttpHeaders.userAgentHeader] = cfUa;
          } catch (_) {}
        } else if (userAgent != null && userAgent.isNotEmpty) {
          try {
            final hasUa = request.headers.keys
                .any((k) => k.toLowerCase() == HttpHeaders.userAgentHeader);
            if (!hasUa) {
              request.headers[HttpHeaders.userAgentHeader] = userAgent;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      AppLogger.logOnce('cookie:${request.url.host}',
          'Cookie interceptor skipped for ${request.url.host}: $e');
    }
  }

  BaseRequest _applyOptions(BaseRequest request) {
    try {
      if (reqcopyWith != null) {
        if (reqcopyWith!["followRedirects"] != null) {
          request.followRedirects = reqcopyWith!["followRedirects"];
        }
        if (reqcopyWith!["maxRedirects"] != null) {
          request.maxRedirects = reqcopyWith!["maxRedirects"];
        }
        if (reqcopyWith!["contentLength"] != null) {
          request.contentLength = reqcopyWith!["contentLength"];
        }
        if (reqcopyWith!["persistentConnection"] != null) {
          request.persistentConnection = reqcopyWith!["persistentConnection"];
        }
      }
    } catch (_) {}
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }
}

class LoggerInterceptor extends InterceptorContract {
  LoggerInterceptor(this.showCloudFlareError);
  bool showCloudFlareError;
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    CloudScraper.applyTo(request.headers);
    final content =
        "----- Request -----\n${request.toString()}\nheaders: ${request.headers.toString()}";

    if (kDebugMode || useLogger) {
      // ignore: avoid_print
      print(content);
      Logger.add(LoggerLevel.info, content);
    }

    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (showCloudFlareError) {
      final cloudflare = isCloudflare(response);
      final content =
          "----- Response -----\n${response.request?.method}: ${response.request?.url}, statusCode: ${response.statusCode} ${cloudflare ? "Failed to bypass Cloudflare" : ""}";

      if (kDebugMode || useLogger) {
        // ignore: avoid_print
        print(content);
        Logger.add(LoggerLevel.info, content);
      }
      if (cloudflare) {
        // The in-app resolver is disabled on Linux, and cookies cannot be read
        // back from a webview there either, so the offer to solve it manually
        // in one is an offer nobody on Linux can take. A proxy is the only
        // thing that gets past this, so say that instead.
        //
        // This is also reached by sites nobody thinks of as "having
        // Cloudflare": a plain proxied site answers every response with
        // `server: cloudflare`, including a 403 raised for some other reason,
        // and that is enough to land here.
        final noResolverAvailable =
            Platform.isLinux && CfProxyStore.url.trim().isEmpty;
        try {
          botToast(
            noResolverAvailable
                ? "${response.statusCode} blocked by Cloudflare. Set a "
                      "FlareSolverr or Byparr URL in Settings > General to get "
                      "past it on Linux."
                : "${response.statusCode} Failed to bypass Cloudflare",
            // The button opens the webview resolver, which does nothing here.
            hasCloudFlare: cloudflare && !noResolverAvailable,
            url: response.request!.url.toString(),
          );
        } catch (e) {
          throw noResolverAvailable
              ? "Blocked by Cloudflare.\n\n\nThe in-app resolver is not available on Linux. Set a FlareSolverr or Byparr URL in Settings > General.\n\n\nstatusCode: ${response.statusCode}"
              : "Failed to bypass Cloudflare.\n\n\nYou can try to bypass it manually in the webview \n\n\nstatusCode: ${response.statusCode}";
        }
      }
    }

    return response;
  }
}

bool isCloudflare(BaseResponse response) {
  if (![403, 503].contains(response.statusCode) ||
      !["cloudflare-nginx", "cloudflare"].contains(response.headers["server"])) {
    return false;
  }
  // YomiHub 0.1.4: some sites behind Cloudflare (e.g. AnimeVietsub) answer
  // normal pages with 403 + full content. Only treat it as a challenge when
  // Cloudflare says so (`cf-mitigated: challenge`) or the body is one.
  if ((response.headers["cf-mitigated"] ?? '').contains('challenge')) return true;
  if (response is Response) {
    final b = response.body;
    return b.contains('<title>Just a moment') ||
        b.contains('challenge-platform') ||
        b.contains('cf-browser-verification') ||
        b.contains('Attention Required! | Cloudflare');
  }
  return true;
}

class ResolveCloudFlareChallenge extends RetryPolicy {
  bool showCloudFlareError;
  ResolveCloudFlareChallenge(this.showCloudFlareError);
  @override
  int get maxRetryAttempts => CloudScraper.retries.clamp(0, 5);
  @override
  Future<bool> shouldAttemptRetryOnResponse(BaseResponse response) async {
    if (!showCloudFlareError) return false;
    if (!isCloudflare(response)) return false;
    // YomiHub CloudScraper settings: solver choice and retry delay.
    if (!CloudScraper.enabled || CloudScraper.solver == 'off') return false;
    if (CloudScraper.delayMs > 0) {
      await Future.delayed(Duration(milliseconds: CloudScraper.delayMs));
    }
    final url = response.request!.url.toString();
    // YomiHub 0.1.6: one solve per host at a time, then (if the invisible
    // WebView can't pass) the visible challenge page.
    return YomiCf.solve(url, () => _solveHeadless(url));
  }

  Future<bool> _solveHeadless(String url) async {

    // Prefer an external Cloudflare-bypass proxy (FlareSolverr / Byparr) when
    // one is configured. It also works on Linux, where the in-app webview
    // resolver below is disabled.
    final proxyUrl = CfProxyStore.url.trim();
    if (proxyUrl.isNotEmpty &&
        (CloudScraper.solver == 'flaresolverr' || Platform.isLinux)) {
      return solveWithCfProxy(proxyUrl, url);
    }

    // YomiHub 0.1.8: CloakBrowser (Windows), then the WebView as fallback
    if (CloudScraper.solver == 'cloak' && Platform.isWindows) {
      if (await YomiCloak.solve(url)) return true;
    }

    // Fall back to the bundled webview resolver (not available on Linux).
    if (Platform.isLinux) return false;
    try {
      return await http
          .post(
            Uri.parse('http://localhost:$cfPort/resolve_cf'),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .then((res) {
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body) as Map<String, dynamic>;
              return data['result'] as bool;
            }
            return false;
          });
    } catch (e) {
      return false;
    }
  }
}

/// Solves a Cloudflare challenge for [targetUrl] through a FlareSolverr- /
/// Byparr-compatible proxy at [proxyUrl] (e.g. `http://localhost:8191/v1`).
///
/// On success it stores the returned `cf_clearance` cookies + user-agent via
/// [MClient.setCookie] (exactly like the webview resolver does), so the retried
/// request carries them, and returns `true` to trigger the retry.
Future<bool> solveWithCfProxy(String proxyUrl, String targetUrl) async {
  try {
    final res = await http
        .post(
          Uri.parse(proxyUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'cmd': 'request.get',
            'url': targetUrl,
            'maxTimeout': 60000,
          }),
        )
        .timeout(const Duration(seconds: 70));
    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'ok') return false;

    final solution = data['solution'] as Map<String, dynamic>?;
    if (solution == null) return false;

    final cookieList = (solution['cookies'] as List?) ?? [];
    final cookie = cookieList
        .whereType<Map>()
        .map((c) => "${c['name']}=${c['value']}")
        .join('; ');
    if (cookie.isEmpty) return false;

    final ua = (solution['userAgent'] as String?) ?? '';
    await MClient.setCookie(targetUrl, ua, null, cookie: cookie);
    return true;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('CF proxy solve failed: $e');
    }
    return false;
  }
}

int cfPort = 0;
HttpServer? _cfServer;

/// Cloudflare Resolution Webview Server
Future<void> webviewServer() async {
  try {
    _cfServer = await HttpServer.bind(InternetAddress.loopbackIPv4, cfPort);
    cfPort = _cfServer!.port;
    _cfServer!.listen(
      (HttpRequest request) {
        if (request.method == 'POST' && request.uri.path == '/resolve_cf') {
          _handleResolveCf(request);
        } else if (request.method == 'POST' &&
            request.uri.path == '/evaluateJavascriptViaWebview') {
          _evaluateJavascriptViaWebview(request);
        } else if (request.method == 'POST' && request.uri.path == '/yh_webfetch') {
          yomiHandleWebFetch(request);
        } else if (request.uri.path == '/yh_chunk') {
          YomiChunkProxy.handle(request);
        } else if (request.uri.path == '/yh_hls') {
          YomiHlsAdFilter.handle(request);
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found')
            ..close();
        }
      },
      onError: (e, st) {
        if (kDebugMode) {
          debugPrint("CF server listener error: $e\n$st");
        }
      },
      cancelOnError: false,
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        "Couldn't start Cloudflare Resolution Webview Server: $e\n$st",
      );
    }
    botToast(
      localizedMessage(
        (l10n) => l10n.cloudflare_resolution_webview_server_start_failed,
      ),
    );
  }
}

Future<void> stopwebviewServer() async {
  final server = _cfServer;
  if (server == null) return;
  try {
    await server.close(force: true);
  } finally {
    _cfServer = null;
    cfPort = 0;
  }
}

void _handleResolveCf(HttpRequest request) async {
  int time = 0;
  bool timeOut = false;
  bool solved = false;
  bool savedDone = false;
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final url = data['url'] as String?;

    if (url == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Missing url parameter'}))
        ..close();
      return;
    }

    final webUri = flutter_inappwebview.WebUri(url);

    // Whether the challenge actually passed is determined by Cloudflare's
    // own cf_clearance cookie, which it only sets once the challenge is
    // solved. The previous check (a string search for '#challenge-success-
    // text' in document.head.innerHTML) is unreliable: Cloudflare's
    // challenge template references that id in a <style> block in <head>
    // from the very first load, pass or fail, so the search was true
    // immediately and the resolver silently ran out the clock without ever
    // saving cookies.
    flutter_inappwebview.HeadlessInAppWebView? headlessWebView;
    headlessWebView = flutter_inappwebview.HeadlessInAppWebView(
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: flutter_inappwebview.URLRequest(url: webUri),
      onLoadStop: (controller, _) async {
        // 0.2.2: the clearance may be on the host the page redirected to
        solved = await YomiCf.hasClearance(url, controller);

        await Future.doWhile(() async {
          if (!timeOut && !solved) {
            solved = await YomiCf.hasClearance(url, controller);
          }
          if (!solved) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          return !solved && !timeOut;
        });

        if (solved) {
          await YomiCf.saveFromWebView(url, controller);
          savedDone = true;
        }
      },
    );

    headlessWebView.run();

    await Future.doWhile(() async {
      timeOut = time == 20;
      if ((solved && savedDone) || timeOut) {
        return false;
      }
      await Future.delayed(const Duration(seconds: 1));
      time++;
      return true;
    });
    try {
      headlessWebView.dispose();
    } catch (_) {}

    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'result': solved}))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(jsonEncode({'error': 'Invalid JSON'}))
      ..close();
  }
}

Future<void> _evaluateJavascriptViaWebview(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final url = data['url'] as String;
    final headers =
        (data['headers'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        {};
    final scripts =
        (data['scripts'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final time = data['time'] as int? ?? 30;
    if (scripts.isNotEmpty && scripts.first == '__yh_sniff__') {
      final r = await YomiMediaSniffer.sniff(
        url,
        headers,
        timeoutSec: time,
        pattern: scripts.length > 1 ? scripts[1] : null,
        userAgentSuffix: scripts.length > 2 ? scripts[2] : null,
      );
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'result': YomiMediaSniffer.encode(r)}))
        ..close();
      return;
    }

    int t = 0;
    bool timeOut = false;
    bool isOk = false;
    String response = "";
    flutter_inappwebview.HeadlessInAppWebView? headlessWebView;
    try {
      headlessWebView = flutter_inappwebview.HeadlessInAppWebView(
        webViewEnvironment: webViewEnvironment,
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'setResponse',
            callback: (args) {
              response = args[0] as String;
              isOk = true;
            },
          );
        },
        initialUrlRequest: flutter_inappwebview.URLRequest(
          url: flutter_inappwebview.WebUri(url),
          headers: headers,
        ),
        onLoadStop: (controller, url) async {
          for (var script in scripts) {
            await controller.platform.evaluateJavascript(source: script);
          }
        },
      );

      await headlessWebView.run();

      await Future.doWhile(() async {
        timeOut = time == t;
        if (timeOut || isOk) {
          return false;
        }
        await Future.delayed(const Duration(seconds: 1));
        t++;
        return true;
      });
    } finally {
      try {
        await headlessWebView?.dispose();
      } catch (_) {}
    }
    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'result': response}))
      ..close();
  } catch (_) {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(jsonEncode({'error': 'Invalid JSON'}))
      ..close();
  }
}

/// YomiHub 0.1.9: solve the Cloudflare challenge of [url] with the app's
/// solver chain (FlareSolverr / CloakBrowser / headless WebView, then the
/// visible challenge page). Used by bridges whose HTTP runs outside Dart
/// (Kotatsu parsers). Returns the User-Agent bound to the clearance, or null.
Future<String?> yomiSolveCloudflare(String url) async {
  final ok = await YomiCf.solve(
    url,
    () => ResolveCloudFlareChallenge(true)._solveHeadless(url),
  );
  if (!ok) return null;
  final host = Uri.tryParse(url)?.host ?? '';
  return YomiCf.uaFor(host) ?? '';
}


/// YomiHub 0.2.2: resolve with the system resolver, fall back to DoH.
final Map<String, (DateTime, List<String>)> _yomiDnsCache = {};

/// 0.4.3: hosts that failed recently (no network / DNS blocked) and lookups
/// already in flight. Without them every request at start-up repeated the
/// 5 s system lookup plus two DoH queries – with ~30 repositories refreshed at
/// once and no network the app stalled for minutes (log 27/10: 111 s).
final Map<String, DateTime> _yomiDnsFail = {};
final Map<String, Future<List<String>>> _yomiDnsInflight = {};

Future<List<String>> yomiSystemThenDoh(String host) {
  final c = _yomiDnsCache[host];
  if (c != null && DateTime.now().difference(c.$1).inMinutes < 10) {
    return Future.value(c.$2);
  }
  if (InternetAddress.tryParse(host) != null) return Future.value([host]);
  final f = _yomiDnsFail[host];
  if (f != null && DateTime.now().difference(f).inSeconds < 30) {
    return Future.value(const <String>[]);
  }
  // 0.4.3 hotfix: the callback must not return the removed Future. An arrow
  // `() => map.remove(host)` hands whenComplete the very Future it is
  // building, which then waits on itself forever – every DNS lookup through
  // this resolver hung (sources, icons and repos never loaded).
  return _yomiDnsInflight[host] ??= _yomiResolve(host).whenComplete(() {
    _yomiDnsInflight.remove(host);
  });
}

Future<List<String>> _yomiResolve(String host) async {
  List<String> ips = const [];
  try {
    final r = await InternetAddress.lookup(host).timeout(const Duration(seconds: 5));
    ips = r.map((a) => a.address).toList();
  } catch (_) {}
  if (ips.isEmpty) {
    for (final p in [DoHProviders.cloudflare, DoHProviders.google]) {
      try {
        ips = await DoHResolver.resolve(host, provider: p)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      if (ips.isNotEmpty) {
        AppLogger.logOnce('dohfb:$host', 'DNS hệ thống không phân giải được $host – dùng DNS-over-HTTPS (${p.name})', logLevel: LogLevel.info);
        break;
      }
    }
  }
  if (ips.isNotEmpty) {
    if (_yomiDnsCache.length > 500) _yomiDnsCache.clear();
    _yomiDnsCache[host] = (DateTime.now(), ips);
    _yomiDnsFail.remove(host);
  } else {
    if (_yomiDnsFail.length > 500) _yomiDnsFail.clear();
    _yomiDnsFail[host] = DateTime.now();
  }
  return ips;
}


/// YomiHub 0.2.3: dart:io HttpClient whose connections resolve with the
/// system DNS first and DNS-over-HTTPS when that fails (ISP DNS filtering).
HttpClient yomiDartHttpClient() {
  final hc = HttpClient();
  hc.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
    if (proxyHost != null) {
      return Socket.startConnect(proxyHost, proxyPort ?? 80);
    }
    final host = uri.host;
    final secure = uri.scheme == 'https' || uri.scheme == 'wss';
    final port = uri.hasPort ? uri.port : (secure ? 443 : 80);
    if (InternetAddress.tryParse(host) != null) {
      return secure ? SecureSocket.startConnect(host, port) : Socket.startConnect(host, port);
    }
    final ips = await yomiSystemThenDoh(host);
    if (ips.isEmpty) {
      throw SocketException("Failed host lookup: '$host' (DNS hệ thống và DNS-over-HTTPS)");
    }
    final ordered = [...ips.where((e) => !e.contains(':')), ...ips.where((e) => e.contains(':'))];
    final task = await Socket.startConnect(ordered.first, port);
    if (!secure) return task;
    return ConnectionTask.fromSocket(
      task.socket.then<Socket>((s) => SecureSocket.secure(s, host: host)),
      task.cancel,
    );
  };
  return hc;
}

/// YomiHub 0.2.8: Wraps a pooled Client so individual request completions
/// calling close() do not dispose the underlying shared connection pool.
/// Automatically handles client re-creation if RhttpClient was disposed.
class _PooledClientWrapper extends BaseClient {
  Client _inner;
  final String? _key;
  final rhttp.ClientSettings? _settings;
  final String? _baseUrl;

  _PooledClientWrapper(this._inner, [this._key, this._settings, this._baseUrl]);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    BaseRequest actualRequest = request;
    final originalUrlStr = request.url.toString();
    final sanitizedUrlStr = YomiUrlOverride.sanitizeUrl(
      originalUrlStr,
      baseUrl: _baseUrl,
      headers: request.headers,
    );
    if (sanitizedUrlStr != originalUrlStr) {
      final sanitizedUri = Uri.tryParse(sanitizedUrlStr);
      if (sanitizedUri != null && request is Request) {
        final newReq = Request(request.method, sanitizedUri)
          ..headers.addAll(request.headers)
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection;
        if (request.bodyBytes.isNotEmpty) newReq.bodyBytes = request.bodyBytes;
        actualRequest = newReq;
      }
    }

    StreamedResponse? primaryRes;
    Object? initialError;
    try {
      if (_key != null && MClient.rhttpPool.containsKey(_key)) {
        _inner = MClient.rhttpPool[_key]!;
      }
      if (_inner is rhttp.RhttpCompatibleClient) {
        final client = _inner as rhttp.RhttpCompatibleClient;
        if (client.client.ref.isDisposed) {
          _refreshClient();
        }
      }
      primaryRes = await _inner.send(actualRequest);
      final mirrors = YomiUrlOverride.getMirrorsFor(actualRequest.url.toString());
      final isErr = primaryRes.statusCode == 403 || primaryRes.statusCode >= 500;
      if (!isErr || mirrors.isEmpty) {
        return primaryRes;
      }
    } catch (e) {
      initialError = e;
      final msg = e.toString();
      if ((msg.contains('DisposedException') || msg.contains('is disposed')) && _key != null) {
        _refreshClient();
        try {
          return await _inner.send(actualRequest);
        } catch (e2) {
          initialError = e2;
        }
      }
    }

    // YomiHub 0.2.9: Tự động đổi sang URL phụ / mirror khi máy chủ chính lỗi
    final mirrors = YomiUrlOverride.getMirrorsFor(actualRequest.url.toString());
    if (mirrors.isNotEmpty && actualRequest is Request) {
      for (final m in mirrors) {
        final mUri = Uri.tryParse(m);
        if (mUri == null || mUri.host.toLowerCase() == actualRequest.url.host.toLowerCase()) continue;
        final fallbackUrl = actualRequest.url.replace(
          scheme: mUri.scheme,
          host: mUri.host,
          port: mUri.hasPort ? mUri.port : null,
        );
        try {
          final fbReq = Request(actualRequest.method, fallbackUrl)
            ..headers.addAll(actualRequest.headers)
            ..followRedirects = actualRequest.followRedirects
            ..maxRedirects = actualRequest.maxRedirects
            ..persistentConnection = actualRequest.persistentConnection;
          if (actualRequest.bodyBytes.isNotEmpty) fbReq.bodyBytes = actualRequest.bodyBytes;
          fbReq.headers.removeWhere((k, _) => k.toLowerCase() == 'host');
          for (final h in ['referer', 'origin']) {
            final k = fbReq.headers.keys.where((e) => e.toLowerCase() == h).firstOrNull;
            if (k != null) fbReq.headers[k] = mUri.toString();
          }
          final res = await _inner.send(fbReq);
          if (res.statusCode < 400) {
            AppLogger.logOnce(
              'mirror_fb:${actualRequest.url.host}',
              '[Tự động đổi URL] Đã chuyển từ ${actualRequest.url.host} sang ${mUri.host} do máy chủ chính lỗi (${primaryRes?.statusCode ?? 'mạng'}).',
              logLevel: LogLevel.info,
            );
            return res;
          }
        } catch (_) {}
      }
    }

    if (primaryRes != null) return primaryRes;
    if (initialError != null) throw initialError;
    return await _inner.send(actualRequest);
  }

  void _refreshClient() {
    if (_key != null) {
      MClient.rhttpPool.remove(_key);
      try {
        final fresh = rhttp.RhttpCompatibleClient.createSync(settings: _settings);
        MClient.rhttpPool[_key] = fresh;
        _inner = fresh;
      } catch (_) {}
    }
  }

  @override
  void close() {
    // Keep the pooled client alive for subsequent requests
  }
}

