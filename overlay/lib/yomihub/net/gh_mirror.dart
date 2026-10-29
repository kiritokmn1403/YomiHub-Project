import 'dart:async';

import 'package:http/http.dart' as http;

/// YomiHub 0.1.9: GitHub raw files through a CDN mirror.
///
/// logs.txt showed repo refreshes failing with "Failed host lookup:
/// 'raw.githubusercontent.com'" (VN ISPs / DNS / some VPN exits block it).
/// The same file is served by jsDelivr (and statically.io), so a lookup or
/// connection failure on GitHub falls back to those instead of leaving the
/// extension list empty.
class GhMirror {
  /// Mirror URLs for [url] (empty when it is not a GitHub raw URL).
  static List<Uri> mirrorsOf(Uri url) {
    final seg = url.pathSegments.where((e) => e.isNotEmpty).toList();
    String? owner, repo, branch;
    List<String> rest = const [];
    if (url.host == 'raw.githubusercontent.com' && seg.length >= 4) {
      owner = seg[0];
      repo = seg[1];
      if (seg.length >= 6 && seg[2] == 'refs' && (seg[3] == 'heads' || seg[3] == 'tags')) {
        branch = seg[4];
        rest = seg.sublist(5);
      } else {
        branch = seg[2];
        rest = seg.sublist(3);
      }
    } else if (url.host == 'github.com' && seg.length >= 5 && (seg[2] == 'raw' || seg[2] == 'blob')) {
      owner = seg[0];
      repo = seg[1];
      branch = seg[3];
      rest = seg.sublist(4);
    }
    if (owner == null || rest.isEmpty) return const [];
    final path = rest.join('/');
    return [
      Uri.parse('https://cdn.jsdelivr.net/gh/$owner/$repo@$branch/$path'),
      Uri.parse('https://fastly.jsdelivr.net/gh/$owner/$repo@$branch/$path'),
      Uri.parse('https://cdn.statically.io/gh/$owner/$repo/$branch/$path'),
    ];
  }

  static bool _isNetworkError(Object e) {
    final t = e.toString().toLowerCase();
    return t.contains('host lookup') ||
        t.contains('socketexception') ||
        t.contains('connection') ||
        t.contains('handshake') ||
        t.contains('timeout') ||
        t.contains('timed out');
  }

  /// GET [url]; on a network failure or 5xx/403/429 from GitHub, try the
  /// mirrors in turn. Returns the first good response (or rethrows the
  /// original error when every mirror fails too).
  static Future<http.Response> get(
    http.Client client,
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    Object? firstError;
    http.Response? firstResponse;
    try {
      final r = await client.get(url, headers: headers).timeout(timeout);
      if (r.statusCode == 200 ||
          !(r.statusCode >= 500 || r.statusCode == 403 || r.statusCode == 429)) {
        return r;
      }
      firstResponse = r;
    } catch (e) {
      if (!_isNetworkError(e)) rethrow;
      firstError = e;
    }
    for (final m in mirrorsOf(url)) {
      try {
        final r = await client.get(m, headers: headers).timeout(timeout);
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) return r;
      } catch (_) {}
    }
    if (firstResponse != null) return firstResponse;
    throw firstError!;
  }

  /// YomiHub 0.2.2: GET [url] and accept the body only when [isValid] says it
  /// is the expected file. A 200 answer that is not the file (an ISP / DNS
  /// filter page, a one-line redirect script, an empty body) is what made
  /// MangaDex fail with "ReferenceError: 'DefaultExtension' is not defined"
  /// after an update. The mirrors are tried before giving up.
  static Future<http.Response> getValid(
    http.Client client,
    Uri url, {
    required bool Function(http.Response r) isValid,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final first = await get(client, url, headers: headers, timeout: timeout);
    if (first.statusCode == 200 && isValid(first)) return first;
    for (final m in mirrorsOf(url)) {
      try {
        final r = await client.get(m, headers: headers).timeout(timeout);
        if (r.statusCode == 200 && isValid(r)) return r;
      } catch (_) {}
    }
    return first;
  }

  /// Short printable preview of a response body for the app log.
  static String preview(http.Response r, [int max = 120]) {
    try {
      final t = r.body.replaceAll(RegExp(r'\s+'), ' ').trim();
      return t.length > max ? '${t.substring(0, max)}…' : t;
    } catch (_) {
      return '${r.bodyBytes.length} byte';
    }
  }
}
