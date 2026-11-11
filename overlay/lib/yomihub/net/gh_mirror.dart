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
    int branchIndex;
    if (url.host == 'raw.githubusercontent.com' && seg.length >= 4) {
      branchIndex = 2;
    } else if (url.host == 'github.com' && seg.length >= 5 && (seg[2] == 'raw' || seg[2] == 'blob')) {
      branchIndex = 3;
    } else {
      return const [];
    }
    if (seg[branchIndex] == 'refs' &&
        {'heads', 'tags'}.contains(seg[branchIndex + 1])) {
      branchIndex += 2;
    }
    if (branchIndex + 1 >= seg.length) return const [];
    final owner = Uri.encodeComponent(seg[0]);
    final repo = Uri.encodeComponent(seg[1]);
    final branch = Uri.encodeComponent(seg[branchIndex]);
    final path = seg.skip(branchIndex + 1).map(Uri.encodeComponent).join('/');
    return [
      Uri.parse('https://cdn.jsdelivr.net/gh/$owner/$repo@$branch/$path'),
      Uri.parse('https://fastly.jsdelivr.net/gh/$owner/$repo@$branch/$path'),
      Uri.parse('https://cdn.statically.io/gh/$owner/$repo/$branch/$path'),
    ];
  }

  static Map<String, String>? _mirrorHeaders(Map<String, String>? headers) =>
      headers == null ? null : Map.fromEntries(headers.entries.where(
        (e) => {'accept', 'user-agent', 'range'}.contains(e.key.toLowerCase()),
      ));

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
        final r = await client.get(m, headers: _mirrorHeaders(headers)).timeout(timeout);
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
        final r = await client.get(m, headers: _mirrorHeaders(headers)).timeout(timeout);
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
