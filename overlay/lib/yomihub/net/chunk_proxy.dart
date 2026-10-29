import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

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
    if (YomiHlsAdFilter.needs(url)) return YomiHlsAdFilter.wrap(url, headers);
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

/// YomiHub 0.1.8: AdBlock for video streams.
///
/// Vietnamese film sites (phimapi/kkphim, ophim, HotPhim…) splice their own
/// ads into the HLS playlist, between #EXT-X-DISCONTINUITY tags, so the
/// browser-style AdBlock never sees them. The player gets the playlist
/// through this loopback endpoint, which drops those blocks: segments that
/// come from another host / folder than the film itself, or whose path says
/// "ad". Segment and key URIs are made absolute so they still go straight to
/// the CDN (with the extension's headers, as before).
class YomiHlsAdFilter {
  /// AdBlock on + "Lọc quảng cáo trong video" (default on).
  static bool get enabled =>
      YomiAdBlock.enabled && YomiPrefs.get<bool>('hlsAdFilter', true);
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 30);

  static final _adWord = RegExp(
    r'adjump|/ads?/|[/_-]ads?[_-]|quangcao|qc_|advert|/promo/|doubleclick',
    caseSensitive: false,
  );

  static bool needs(String url) {
    if (!enabled || cfPort == 0) return false;
    final u = url.toLowerCase();
    return u.startsWith('http') &&
        u.contains('.m3u8') &&
        !u.contains('127.0.0.1') &&
        !u.contains('googlevideo.com');
  }

  static String wrap(String url, Map<String, dynamic>? headers) {
    if (!needs(url)) return url;
    final h = <String, String>{};
    headers?.forEach((k, v) => h[k] = '$v');
    final enc = base64Url.encode(utf8.encode(jsonEncode(h)));
    return 'http://127.0.0.1:$cfPort/yh_hls?u=${Uri.encodeComponent(url)}&h=$enc';
  }

  static Map<String, String> _headers(String? enc) {
    if (enc == null || enc.isEmpty) return {};
    try {
      return Map<String, String>.from(
        jsonDecode(utf8.decode(base64Url.decode(enc))) as Map,
      );
    } catch (_) {
      return {};
    }
  }

  static Future<String?> _fetch(Uri u, Map<String, String> h) async {
    final req = await _client.getUrl(u);
    h.forEach((k, v) {
      if (k.toLowerCase() != 'host') req.headers.set(k, v);
    });
    final res = await req.close();
    if (res.statusCode >= 400) {
      await res.drain<void>();
      return null;
    }
    return utf8.decode(await res.fold<List<int>>([], (a, b) => a..addAll(b)),
        allowMalformed: true);
  }

  static String _sig(Uri seg) {
    final dir = seg.path.contains('/')
        ? seg.path.substring(0, seg.path.lastIndexOf('/'))
        : '';
    return '${seg.host}|${dir.replaceAll(RegExp(r'\d+'), '#')}';
  }

  /// Removes spliced-in ad blocks from a media playlist. Public for tests.
  static String filterPlaylist(String body, Uri base, {String Function(Uri)? proxify}) {
    final lines = const LineSplitter().convert(body);
    if (lines.any((l) => l.startsWith('#EXT-X-STREAM-INF'))) {
      // master playlist: send the variants through the filter too
      final out = <String>[];
      var nextIsVariant = false;
      for (final l in lines) {
        if (l.startsWith('#EXT-X-STREAM-INF')) {
          nextIsVariant = true;
          out.add(l);
        } else if (nextIsVariant && l.isNotEmpty && !l.startsWith('#')) {
          final abs = base.resolve(l.trim());
          out.add(proxify != null ? proxify(abs) : abs.toString());
          nextIsVariant = false;
        } else {
          out.add(_absUriAttr(l, base));
        }
      }
      return out.join('\n');
    }
    // media playlist: blocks between discontinuities
    final header = <String>[];
    final blocks = <List<String>>[[]];
    final blockSegs = <List<Uri>>[[]];
    final blockDur = <double>[0];
    var pending = <String>[];
    var inSegs = false;
    double dur = 0;
    for (final raw in lines) {
      final l = raw.trimRight();
      if (l.isEmpty) continue;
      if (l.startsWith('#EXTINF')) {
        inSegs = true;
        dur = double.tryParse(l.substring(8).split(',').first.trim()) ?? 0;
        pending.add(l);
      } else if (l.startsWith('#EXT-X-DISCONTINUITY') && !l.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE')) {
        if (blocks.last.isNotEmpty) {
          blocks.add([]);
          blockSegs.add([]);
          blockDur.add(0);
        }
        inSegs = true;
      } else if (l.startsWith('#')) {
        if (!inSegs && pending.isEmpty && !l.startsWith('#EXT-X-KEY') && !l.startsWith('#EXT-X-MAP')) {
          header.add(l);
        } else {
          pending.add(_absUriAttr(l, base));
        }
      } else {
        final abs = base.resolve(l.trim());
        blocks.last.addAll(pending);
        blocks.last.add(abs.toString());
        blockSegs.last.add(abs);
        blockDur[blockDur.length - 1] += dur;
        pending = [];
        dur = 0;
      }
    }
    final tail = pending; // e.g. #EXT-X-ENDLIST
    var keep = List<bool>.filled(blocks.length, true);
    if (blocks.length > 1) {
      final total = blockDur.fold<double>(0, (a, b) => a + b);
      final bySig = <String, double>{};
      for (var i = 0; i < blocks.length; i++) {
        for (final s in blockSegs[i]) {
          bySig[_sig(s)] = (bySig[_sig(s)] ?? 0) + blockDur[i] / (blockSegs[i].isEmpty ? 1 : blockSegs[i].length);
        }
      }
      final main = bySig.entries.isEmpty
          ? ''
          : (bySig.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
      for (var i = 0; i < blocks.length; i++) {
        final segs = blockSegs[i];
        if (segs.isEmpty) continue;
        final adWord = segs.every((s) => _adWord.hasMatch(s.toString()));
        final foreign = segs.every((s) => _sig(s) != main);
        final short = blockDur[i] <= 120 && blockDur[i] < total * 0.25;
        if (adWord || (foreign && short)) keep[i] = false;
      }
      if (!keep.contains(true)) keep = List<bool>.filled(blocks.length, true);
    }
    final out = <String>[...header];
    var first = true;
    for (var i = 0; i < blocks.length; i++) {
      if (!keep[i] || blocks[i].isEmpty) continue;
      if (!first) out.add('#EXT-X-DISCONTINUITY');
      out.addAll(blocks[i]);
      first = false;
    }
    out.addAll(tail);
    return out.join('\n');
  }

  static String _absUriAttr(String l, Uri base) {
    if (!l.startsWith('#') || !l.contains('URI="')) return l;
    return l.replaceAllMapped(RegExp(r'URI="([^"]+)"'),
        (m) => 'URI="${base.resolve(m.group(1)!)}"');
  }

  static Future<void> handle(HttpRequest request) async {
    final response = request.response;
    try {
      final target = Uri.parse(request.uri.queryParameters['u'] ?? '');
      final enc = request.uri.queryParameters['h'];
      final h = _headers(enc);
      final body = await _fetch(target, h);
      if (body == null || !body.trimLeft().startsWith('#EXTM3U')) {
        // not a playlist (or refused): let the player go to the origin
        response.statusCode = HttpStatus.found;
        response.headers.set(HttpHeaders.locationHeader, target.toString());
        await response.close();
        return;
      }
      final text = filterPlaylist(
        body,
        target,
        proxify: (u) =>
            'http://127.0.0.1:$cfPort/yh_hls?u=${Uri.encodeComponent(u.toString())}&h=${enc ?? ''}',
      );
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentTypeHeader, 'application/vnd.apple.mpegurl');
      response.write(text);
      await response.close();
    } catch (_) {
      try {
        response.statusCode = HttpStatus.badGateway;
        await response.close();
      } catch (_) {}
    }
  }
}
