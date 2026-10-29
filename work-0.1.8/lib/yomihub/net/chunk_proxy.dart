import 'dart:async';
import 'dart:io';

import 'package:mangayomi/services/http/m_client.dart';

/// YomiHub: local range-chunking proxy.
///
/// Some CDNs (YouTube's googlevideo.com) refuse open-ended requests
/// ("Range: bytes=0-" or none at all) and only serve bounded ranges, which is
/// what mpv/ffmpeg sends. The player is pointed at this loopback endpoint and
/// the proxy fetches the file in bounded chunks, streaming them back as one
/// continuous response, the same trick NewPipe and yt-dlp use.
class YomiChunkProxy {
  static const _chunk = 2 * 1024 * 1024;
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 30);

  static bool needs(String url) =>
      url.contains('.googlevideo.com/videoplayback') && !url.contains('/manifest/');

  static String wrap(String url, Map<String, dynamic>? headers) {
    if (cfPort == 0 || !needs(url)) return url;
    final ua = (headers?['User-Agent'] ?? headers?['user-agent'] ?? '').toString();
    return 'http://127.0.0.1:$cfPort/yh_chunk?u=${Uri.encodeComponent(url)}'
        '${ua.isNotEmpty ? '&ua=${Uri.encodeComponent(ua)}' : ''}';
  }

  /// Rewrites a video map coming from an extension (url, originalUrl and the
  /// external audio tracks).
  static Map<String, dynamic> wrapVideoJson(Map<String, dynamic> v) {
    final h = (v['headers'] is Map) ? Map<String, dynamic>.from(v['headers']) : null;
    final out = Map<String, dynamic>.from(v);
    if (out['url'] is String) out['url'] = wrap(out['url'], h);
    if (out['originalUrl'] is String) out['originalUrl'] = wrap(out['originalUrl'], h);
    if (out['audios'] is List) {
      out['audios'] = [
        for (final a in out['audios'])
          if (a is Map)
            (Map<String, dynamic>.from(a)..update('file', (f) => f is String ? wrap(f, h) : f, ifAbsent: () => null))
          else
            a,
      ];
    }
    return out;
  }

  static Future<int?> _totalSize(Uri u, String ua) async {
    final clen = int.tryParse(u.queryParameters['clen'] ?? '');
    if (clen != null && clen > 0) return clen;
    try {
      final req = await _client.getUrl(u);
      if (ua.isNotEmpty) req.headers.set(HttpHeaders.userAgentHeader, ua);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      final res = await req.close();
      await res.drain<void>();
      final cr = res.headers.value(HttpHeaders.contentRangeHeader) ?? '';
      return int.tryParse(cr.split('/').last);
    } catch (_) {
      return null;
    }
  }

  static Future<void> handle(HttpRequest request) async {
    final response = request.response;
    try {
      final target = Uri.parse(request.uri.queryParameters['u'] ?? '');
      final ua = request.uri.queryParameters['ua'] ?? '';
      final total = await _totalSize(target, ua);
      if (total == null) {
        response.statusCode = HttpStatus.badGateway;
        await response.close();
        return;
      }
      var start = 0;
      var end = total - 1;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      final m = range == null ? null : RegExp(r'bytes=(\d*)-(\d*)').firstMatch(range);
      if (m != null) {
        if (m.group(1)!.isNotEmpty) start = int.parse(m.group(1)!);
        if (m.group(2)!.isNotEmpty) end = int.parse(m.group(2)!).clamp(0, total - 1);
        if (m.group(1)!.isEmpty && m.group(2)!.isNotEmpty) {
          // suffix range: last N bytes
          start = total - int.parse(m.group(2)!);
          end = total - 1;
        }
      }
      if (start >= total || start > end) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$total');
        await response.close();
        return;
      }
      final mime = target.queryParameters['mime'] ?? 'application/octet-stream';
      response.statusCode = m != null ? HttpStatus.partialContent : HttpStatus.ok;
      response.headers
        ..set(HttpHeaders.contentTypeHeader, mime)
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..contentLength = end - start + 1;
      if (m != null) {
        response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$total');
      }
      if (request.method == 'HEAD') {
        await response.close();
        return;
      }
      var pos = start;
      while (pos <= end) {
        final to = (pos + _chunk - 1) > end ? end : pos + _chunk - 1;
        var ok = false;
        for (var attempt = 0; attempt < 3 && !ok; attempt++) {
          try {
            final req = await _client.getUrl(target);
            if (ua.isNotEmpty) req.headers.set(HttpHeaders.userAgentHeader, ua);
            req.headers.set(HttpHeaders.rangeHeader, 'bytes=$pos-$to');
            final res = await req.close();
            if (res.statusCode != 206 && res.statusCode != 200) {
              await res.drain<void>();
              continue;
            }
            await response.addStream(res);
            ok = true;
          } on HttpException {
            // client went away or upstream hiccup
          } on SocketException {
            return;
          }
        }
        if (!ok) break;
        pos = to + 1;
      }
      await response.close();
    } catch (_) {
      try {
        await response.close();
      } catch (_) {}
    }
  }
}
