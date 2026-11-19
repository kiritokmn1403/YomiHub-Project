// YomiHub 0.6.0 – "Get Video URL & Download Video Project" (sheet YomiHub Update).
//
// Savior (0.1.x) only sees media the page actually requests (fetch/XHR,
// <video>.src, onLoadResource). Ideas from m3u8_StreamSniper, media-extractor
// and video-url-link: read the page source too, so links sitting in a player
// config (jwplayer `sources:[{file:…}]`, `"file":"…"`, `data-src`, og:video,
// JSON-escaped `https:\/\/…`) are found before pressing play, and embedded
// players (<iframe src>) can be opened to look inside them.
//
// Pure Dart, no network: the browser passes `document.documentElement.outerHTML`.

class ExtractedMedia {
  final String url;
  final String kind; // hls | dash | video | audio
  final String via; // where it was found (for the list subtitle)
  const ExtractedMedia(this.url, this.kind, this.via);
  @override
  String toString() => '$kind $url ($via)';
}

class VideoUrlExtractor {
  VideoUrlExtractor._();

  static const _ext = r'm3u8|mpd|mp4|m4v|webm|mkv|mov|flv|mp3|m4a|aac|ogg|opus';

  /// Absolute media URLs anywhere in the text (after unescaping).
  static final _absolute = RegExp(
    r'''(?:https?:)?//[^\s"'<>\\()]+?\.(?:''' + _ext + r''')(?:\?[^\s"'<>\\()]*)?(?=["'\s<>\\),]|$)''',
    caseSensitive: false,
  );

  /// Relative paths inside quoted player/config attributes.
  static final _keyed = RegExp(
    r'''(?:file|src|source|url|video_url|videoUrl|hls|mp4|data-src|content)\s*[:=]\s*["']([^"']+?\.(?:''' + _ext + r''')(?:\?[^"']*)?)["']''',
    caseSensitive: false,
  );

  static final _iframe = RegExp(r'''<iframe[^>]+src\s*=\s*["']([^"']+)["']''', caseSensitive: false);

  static final _ignore = RegExp(
    r'(doubleclick|googlesyndication|google-analytics|/ads?/|vast|preroll|\.ts(\?|$)|\.m4s(\?|$)|seg-\d+|init\.mp4)',
    caseSensitive: false,
  );

  /// Undo the escapes pages use around URLs in inline JSON/JS.
  static String unescape(String s) => s
      .replaceAll(r'\/', '/')
      .replaceAll(r'/', '/')
      .replaceAll(r'/', '/')
      .replaceAll(r'&', '&')
      .replaceAll('&amp;', '&');

  static String kindOf(String url) {
    final l = url.toLowerCase();
    if (l.contains('.m3u8')) return 'hls';
    if (l.contains('.mpd')) return 'dash';
    if (RegExp(r'\.(mp3|m4a|aac|ogg|opus)(\?|$)').hasMatch(l)) return 'audio';
    return 'video';
  }

  static String? _resolve(String raw, Uri base) {
    var u = raw.trim();
    if (u.isEmpty || u.startsWith('blob:') || u.startsWith('data:')) return null;
    if (u.startsWith('//')) u = '${base.scheme}:$u';
    final r = Uri.tryParse(u);
    if (r == null) return null;
    final abs = r.hasScheme ? r : base.resolveUri(r);
    if (abs.scheme != 'http' && abs.scheme != 'https') return null;
    return abs.toString();
  }

  /// Media links in [html] of [pageUrl]: HLS first, then DASH, video, audio.
  static List<ExtractedMedia> extract(String html, String pageUrl) {
    final base = Uri.tryParse(pageUrl) ?? Uri.parse('https://localhost/');
    final text = unescape(html);
    final out = <String, ExtractedMedia>{};
    void add(String raw, String via) {
      final u = _resolve(raw, base);
      if (u == null || _ignore.hasMatch(u) || out.containsKey(u)) return;
      out[u] = ExtractedMedia(u, kindOf(u), via);
    }

    for (final m in _keyed.allMatches(text)) {
      add(m.group(1)!, 'cấu hình trình phát');
    }
    for (final m in _absolute.allMatches(text)) {
      add(m.group(0)!, 'mã trang');
    }
    const order = {'hls': 0, 'dash': 1, 'video': 2, 'audio': 3};
    return out.values.toList()..sort((a, b) => order[a.kind]!.compareTo(order[b.kind]!));
  }

  /// Embedded players (<iframe src>) – opened in a new tab to scan inside.
  static List<String> iframes(String html, String pageUrl) {
    final base = Uri.tryParse(pageUrl) ?? Uri.parse('https://localhost/');
    final seen = <String>{};
    for (final m in _iframe.allMatches(unescape(html))) {
      final u = _resolve(m.group(1)!, base);
      if (u != null && !_ignore.hasMatch(u)) seen.add(u);
    }
    return seen.toList();
  }
}
