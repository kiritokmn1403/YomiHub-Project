import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.2.2 – "Có vài extension sau khi giải xong Cloudflare trên
/// Webview vẫn không truy cập được".
///
/// Some sites accept `cf_clearance` only from the browser that earned it:
/// Cloudflare also checks the TLS / HTTP-2 fingerprint, and the app's HTTP
/// client is not Chrome. The request then comes back as a challenge again
/// although it carries a valid cookie and the right User-Agent.
///
/// When that happens for a page request (HTML / JSON, not images) the page
/// is loaded by a headless WebView instead – the same engine that passed
/// the challenge – and its content is handed to the extension. Both the
/// "still blocked after solving" case and a failing WebView load are written
/// to the app log.
class YomiCfFallbackInterceptor extends InterceptorContract {
  YomiCfFallbackInterceptor(this.enabled);
  final bool enabled;

  static final Map<String, DateTime> _failedHost = {};
  static final Map<String, DateTime> _loggedHost = {};
  static int _running = 0;

  static final RegExp _binary = RegExp(
    r'\.(jpe?g|png|gif|webp|avif|bmp|svg|ico|mp4|m3u8|ts|m4s|webm|mp3|woff2?|ttf|css|zip|apk|aix)(\?|$)',
    caseSensitive: false,
  );

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async => request;

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async {
    try {
      if (!enabled || response is! http.Response || cfPort == 0 || Platform.isLinux) {
        return response;
      }
      final req = response.request;
      if (req == null || req.method != 'GET') return response;
      final cookie = req.headers.entries
          .firstWhere((e) => e.key.toLowerCase() == 'cookie', orElse: () => const MapEntry('', ''))
          .value;
      if (!cookie.contains('cf_clearance=')) return response; // not solved yet
      if (!isCloudflare(response)) return response;
      final url = req.url.toString();
      final host = req.url.host;
      final accept = req.headers.entries
          .where((e) => e.key.toLowerCase() == 'accept')
          .map((e) => e.value)
          .join();
      if (_binary.hasMatch(req.url.path) || accept.startsWith('image/')) return response;

      final last = _loggedHost[host];
      if (last == null || DateTime.now().difference(last).inMinutes >= 10) {
        _loggedHost[host] = DateTime.now();
        AppLogger.log(
          '[Cloudflare] $host: đã giải xong Cloudflare trên WebView nhưng tiện ích vẫn bị chặn '
          '(HTTP ${response.statusCode}, cookie cf_clearance đã gửi) – chuyển sang tải trang qua WebView. URL: $url',
          logLevel: LogLevel.error,
        );
      }
      final f = _failedHost[host];
      if (f != null && DateTime.now().difference(f).inMinutes < 3) return response;
      if (_running >= 2) return response;
      _running++;
      try {
        final r = await http
            .post(
              Uri.parse('http://127.0.0.1:$cfPort/yh_webfetch'),
              headers: {HttpHeaders.contentTypeHeader: 'application/json'},
              body: jsonEncode({
                'url': url,
                'headers': {
                  for (final e in req.headers.entries)
                    if (!const {'cookie', 'user-agent', 'host', 'content-length', 'accept-encoding'}
                        .contains(e.key.toLowerCase()))
                      e.key: e.value,
                },
              }),
            )
            .timeout(const Duration(seconds: 40));
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final body = (d['body'] as String?) ?? '';
        if (r.statusCode == 200 && d['ok'] == true && body.isNotEmpty) {
          return http.Response(
            body,
            200,
            request: req,
            headers: {
              'content-type': '${d['contentType'] ?? 'text/html'}; charset=utf-8',
              'x-yomihub-via': 'webview',
            },
          );
        }
        _failedHost[host] = DateTime.now();
        AppLogger.log(
          '[Cloudflare] $host: tải trang qua WebView cũng không được (${d['error'] ?? 'vẫn là trang xác minh'}). '
          'Mở tiện ích bằng WebView, xác minh lại hoặc đổi tên miền (Đổi URL). URL: $url',
          logLevel: LogLevel.error,
        );
      } finally {
        _running--;
      }
    } catch (e) {
      AppLogger.logOnce('cfwf:${response.request?.url.host}', '[Cloudflare] lỗi tải qua WebView: $e');
    }
    return response;
  }
}

/// Server side of `/yh_webfetch` (runs on the main isolate, where WebViews live).
Future<void> yomiHandleWebFetch(HttpRequest request) async {
  HeadlessInAppWebView? wv;
  Map<String, dynamic> out = {'ok': false};
  try {
    final data = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final url = data['url'] as String;
    final headers = (data['headers'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? <String, String>{};
    final done = Completer<void>();
    var checks = 0;
    Future<void> grab(InAppWebViewController c) async {
      if (done.isCompleted) return;
      final title = (await c.getTitle()) ?? '';
      if (title.contains('Just a moment') || title.contains('Một chút') || title.contains('Attention Required')) {
        return; // still on the challenge – wait for the next load
      }
      final res = await c.evaluateJavascript(source: '''
(function(){
  var ct = document.contentType || 'text/html';
  if (ct.indexOf('html') < 0) return JSON.stringify({ct: ct, b: document.body ? document.body.innerText : ''});
  return JSON.stringify({ct: 'text/html', b: '<!DOCTYPE html>' + document.documentElement.outerHTML});
})()''');
      final m = jsonDecode('$res') as Map<String, dynamic>;
      out = {'ok': true, 'body': m['b'], 'contentType': m['ct'], 'finalUrl': (await c.getUrl())?.toString()};
      if (!done.isCompleted) done.complete();
    }

    wv = HeadlessInAppWebView(
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri(url), headers: headers),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        thirdPartyCookiesEnabled: true,
        blockNetworkImage: true,
      ),
      onLoadStop: (c, _) async {
        // challenge pages reload themselves; poll a little after each load
        for (var i = 0; i < 6 && !done.isCompleted; i++) {
          checks++;
          try {
            await grab(c);
          } catch (_) {}
          if (!done.isCompleted) await Future.delayed(const Duration(seconds: 2));
        }
      },
    );
    await wv.run();
    await done.future.timeout(const Duration(seconds: 30), onTimeout: () {
      out = {'ok': false, 'error': 'hết thời gian chờ (${checks}x vẫn là trang xác minh)'};
    });
  } catch (e) {
    out = {'ok': false, 'error': '$e'};
  } finally {
    try {
      await wv?.dispose();
    } catch (_) {}
  }
  try {
    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(out));
    await request.response.close();
  } catch (_) {}
}
