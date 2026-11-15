import 'dart:convert';

/// YomiHub 0.5.7 (logs 7: CBHentai "đã giải xong Cloudflare trên WebView
/// nhưng vẫn không tải được trang").
///
/// `cf_clearance` is tied to the browser that earned it. Until 0.5.6.1 only
/// the User-Agent of the WebView was copied to the HTTP client; the client
/// hints were then filled in from the CloudScraper profile ("Google Chrome"
/// v140, platform from the settings) – a request that says "Chrome/141 … wv"
/// in User-Agent and "Google Chrome 140" in sec-ch-ua does not look like the
/// browser that passed the challenge. The whole identity of the solving
/// WebView is now kept per host: User-Agent, sec-ch-ua brands / mobile /
/// platform and the language list.
///
/// Pure Dart (no Flutter) so it can be unit tested.
class CfIdentity {
  const CfIdentity({required this.ua, this.brands, this.mobile, this.platform, this.languages = const []});

  final String ua;

  /// `[["Chromium","141"],["Android WebView","141"],…]` as the WebView
  /// reports it (navigator.userAgentData.brands), null when unknown.
  final List<List<String>>? brands;
  final bool? mobile;
  final String? platform;
  final List<String> languages;

  /// From the JSON produced by [captureScript].
  static CfIdentity? parse(String? json, {String fallbackUa = ''}) {
    if (json == null || json.trim().isEmpty) {
      return fallbackUa.isEmpty ? null : CfIdentity(ua: fallbackUa);
    }
    try {
      var d = jsonDecode(json);
      if (d is String) d = jsonDecode(d); // evaluateJavascript may double-encode
      if (d is! Map) throw const FormatException();
      final ua = '${d['ua'] ?? ''}'.trim().isEmpty ? fallbackUa : '${d['ua']}'.trim();
      if (ua.isEmpty) return null;
      List<List<String>>? brands;
      final b = d['brands'];
      if (b is List && b.isNotEmpty) {
        brands = [
          for (final e in b)
            if (e is List && e.length >= 2 && '${e[0]}'.isNotEmpty) ['${e[0]}', '${e[1]}'],
        ];
        if (brands.isEmpty) brands = null;
      }
      final langs = d['langs'];
      return CfIdentity(
        ua: ua,
        brands: brands,
        mobile: d['mobile'] is bool ? d['mobile'] as bool : null,
        platform: d['platform'] is String && (d['platform'] as String).isNotEmpty ? d['platform'] as String : null,
        languages: langs is List ? [for (final l in langs) if ('$l'.trim().isNotEmpty) '$l'.trim()] : const [],
      );
    } catch (_) {
      return fallbackUa.isEmpty ? null : CfIdentity(ua: fallbackUa);
    }
  }

  String encode() => jsonEncode({
        'ua': ua,
        if (brands != null) 'brands': brands,
        if (mobile != null) 'mobile': mobile,
        if (platform != null) 'platform': platform,
        if (languages.isNotEmpty) 'langs': languages,
      });

  bool get isChromium => RegExp(r'Chrome/\d+').hasMatch(ua) && !ua.contains('Firefox/');

  /// `sec-ch-ua`, or null for a browser that does not send client hints
  /// (Firefox, Safari).
  String? get secChUa {
    final b = brands;
    if (b != null && b.isNotEmpty) {
      return b.map((e) => '"${e[0].replaceAll('"', r'\"')}";v="${e[1]}"').join(', ');
    }
    if (!isChromium) return null;
    final major = RegExp(r'Chrome/(\d+)').firstMatch(ua)!.group(1)!;
    final name = RegExp(r';\s*wv\)').hasMatch(ua)
        ? 'Android WebView'
        : (ua.contains('Edg/') ? 'Microsoft Edge' : 'Google Chrome');
    return '"Chromium";v="$major", "$name";v="$major", "Not?A_Brand";v="99"';
  }

  String? get secChUaMobile {
    if (secChUa == null) return null;
    final m = mobile ?? ua.contains('Mobile');
    return m ? '?1' : '?0';
  }

  String? get secChUaPlatform {
    if (secChUa == null) return null;
    var p = platform;
    p ??= ua.contains('Android')
        ? 'Android'
        : ua.contains('Windows')
            ? 'Windows'
            : ua.contains('Mac OS X')
                ? 'macOS'
                : ua.contains('CrOS')
                    ? 'Chrome OS'
                    : 'Linux';
    return '"$p"';
  }

  /// `Accept-Language` the way Chromium builds it from navigator.languages:
  /// "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7". Null when unknown.
  String? get acceptLanguage {
    if (languages.isEmpty) return null;
    final out = <String>[];
    for (var i = 0; i < languages.length && i < 10; i++) {
      final q = 1 - i * 0.1;
      out.add(i == 0 ? languages[i] : '${languages[i]};q=${q.toStringAsFixed(1)}');
    }
    return out.join(',');
  }

  /// Makes [headers] of a request that carries this host's `cf_clearance`
  /// look like the browser that earned it: its User-Agent and matching
  /// client hints always (an extension's own values would contradict the
  /// forced User-Agent); its languages only when the extension set none.
  void applyTo(Map<String, String> headers) {
    void force(String name, String? value) {
      headers.removeWhere((k, _) => k.toLowerCase() == name.toLowerCase());
      if (value != null) headers[name] = value;
    }

    force('user-agent', ua);
    force('sec-ch-ua', secChUa);
    force('sec-ch-ua-mobile', secChUaMobile);
    force('sec-ch-ua-platform', secChUaPlatform);
    // high-entropy hints an extension copied from another browser
    headers.removeWhere((k, _) {
      final l = k.toLowerCase();
      return l.startsWith('sec-ch-ua-') && l != 'sec-ch-ua-mobile' && l != 'sec-ch-ua-platform';
    });
    final al = acceptLanguage;
    if (al != null && !headers.keys.any((k) => k.toLowerCase() == 'accept-language')) {
      headers['accept-language'] = al;
    }
  }

  /// Run in the WebView that passed the challenge.
  static const captureScript = '''
(function(){
  try {
    var d = navigator.userAgentData;
    return JSON.stringify({
      ua: navigator.userAgent,
      brands: d && d.brands ? d.brands.map(function(b){ return [b.brand, b.version]; }) : null,
      mobile: d ? !!d.mobile : null,
      platform: d && d.platform ? d.platform : null,
      langs: (navigator.languages && navigator.languages.length) ? Array.prototype.slice.call(navigator.languages) : [navigator.language || '']
    });
  } catch (e) {
    return JSON.stringify({ua: navigator.userAgent});
  }
})()''';
}

/// What the page in the solving WebView is.
enum CfPageState {
  /// A normal page of the site.
  ok,

  /// Still Cloudflare's challenge ("Just a moment…", Turnstile).
  challenge,

  /// Cloudflare refuses outright (error 1020 / "Attention Required").
  blocked,
}

/// Run in the WebView to read the page state for [cfPageState].
const cfPageProbeScript = '''
(function(){
  try {
    return JSON.stringify({
      t: document.title || '',
      c: (typeof window._cf_chl_opt !== 'undefined') ||
         !!document.querySelector('#challenge-form, #challenge-running, #challenge-stage, #cf-challenge-running'),
      b: !!document.querySelector('#cf-error-details, .cf-error-details')
    });
  } catch (e) { return '{}'; }
})()''';

/// Decides from the probe result ([cfPageProbeScript]) whether the WebView
/// is still on Cloudflare's page. 0.5.6.1 only looked for the cookie: a
/// `cf_clearance` left from an earlier visit (expired, or earned on another
/// IP) made the solver report "solved" while the page was still the
/// challenge, and the extension was retried with a useless cookie.
CfPageState cfPageState(String? probeJson) {
  var title = '';
  var marker = false;
  var blocked = false;
  try {
    var d = jsonDecode(probeJson ?? '{}');
    if (d is String) d = jsonDecode(d);
    if (d is Map) {
      title = '${d['t'] ?? ''}';
      marker = d['c'] == true;
      blocked = d['b'] == true;
    }
  } catch (_) {}
  final t = title.toLowerCase();
  if (marker ||
      t.contains('just a moment') ||
      t.contains('một chút') ||
      t.contains('checking your browser') ||
      t.contains('ddos-guard')) {
    return CfPageState.challenge;
  }
  if (blocked || t.contains('attention required') || t.contains('access denied')) {
    return CfPageState.blocked;
  }
  return CfPageState.ok;
}
