import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';

/// YomiHub 0.1.7 – Web Scanner (Sucuri SiteCheck / "website scanner" style,
/// passive only): looks at what a site sends to a normal visitor and
/// reports the risks that matter for a reading / streaming app:
///  * HTTPS, certificate, redirect chain (and redirects to other domains),
///  * security headers (HSTS, CSP, X-Frame-Options, nosniff, Referrer-Policy,
///    Permissions-Policy) and server version disclosure,
///  * cookies without Secure / HttpOnly / SameSite,
///  * scripts, iframes and links from ad / tracker / badware hosts (the
///    browser's AdBlock lists), crypto-miners, pop-unders, obfuscated
///    `eval(atob(…))` loaders, forced redirects, mixed content,
///  * outdated jQuery, Cloudflare protection.
/// It never sends attack payloads – only one ordinary page request.
enum ScanLevel { ok, info, warn, bad }

class ScanFinding {
  final ScanLevel level;
  final String title;
  final String detail;
  ScanFinding(this.level, this.title, [this.detail = '']);
}

class ScanReport {
  final String url;
  String finalUrl = '';
  int status = 0;
  String server = '';
  final List<String> redirects = [];
  final List<ScanFinding> findings = [];
  int scriptHosts = 0;
  Duration took = Duration.zero;

  int get score {
    var s = 100;
    for (final f in findings) {
      s -= switch (f.level) {
        ScanLevel.bad => 20,
        ScanLevel.warn => 7,
        ScanLevel.info => 1,
        ScanLevel.ok => 0,
      };
    }
    return s.clamp(0, 100);
  }

  String get verdict => score >= 85
      ? 'An toàn'
      : score >= 60
      ? 'Cần chú ý'
      : 'Rủi ro cao';

  ScanReport(this.url);
}

class YomiWebScanner {
  YomiWebScanner._();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36';

  static const _miners = [
    'coinhive', 'coin-hive', 'cryptoloot', 'crypto-loot', 'coinimp', 'webminepool', 'jsecoin',
    'minero.cc', 'webmine.cz', 'cryptonight', 'monerominer', 'deepminer', 'authedmine',
  ];

  static Future<ScanReport> scan(String input) async {
    var url = input.trim();
    if (!url.contains('://')) url = 'https://$url';
    final rep = ScanReport(url);
    final sw = Stopwatch()..start();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = _ua;
    X509Certificate? cert;
    String body = '';
    HttpClientResponse? res;
    try {
      var u = Uri.parse(url);
      for (var hop = 0; hop < 8; hop++) {
        final req = await client.getUrl(u);
        req.followRedirects = false;
        req.headers.set('Accept', 'text/html,*/*');
        res = await req.close().timeout(const Duration(seconds: 25));
        cert ??= res.certificate;
        if (res.isRedirect || (res.statusCode >= 300 && res.statusCode < 400)) {
          final loc = res.headers.value(HttpHeaders.locationHeader);
          await res.drain<void>();
          if (loc == null) break;
          final next = u.resolve(loc);
          rep.redirects.add(next.toString());
          u = next;
          continue;
        }
        break;
      }
      rep.finalUrl = u.toString();
      rep.status = res?.statusCode ?? 0;
      if (res != null) {
        final bytes = <int>[];
        await for (final c in res.timeout(const Duration(seconds: 25))) {
          bytes.addAll(c);
          if (bytes.length > 3 << 20) break; // 3 MB is plenty for a page
        }
        body = String.fromCharCodes(bytes);
      }
    } on HandshakeException catch (e) {
      rep.findings.add(ScanFinding(ScanLevel.bad, 'Chứng chỉ HTTPS không hợp lệ', '$e'));
    } catch (e) {
      rep.findings.add(ScanFinding(ScanLevel.bad, 'Không tải được trang', '$e'));
    } finally {
      client.close(force: true);
    }
    if (res != null) _analyse(rep, res, cert, body);
    rep.took = sw.elapsed;
    return rep;
  }

  static void _analyse(ScanReport rep, HttpClientResponse res, X509Certificate? cert, String body) {
    final f = rep.findings;
    final start = Uri.parse(rep.url);
    final end = Uri.parse(rep.finalUrl);
    final h = res.headers;
    String? hv(String n) => h.value(n);

    // ── transport ──
    if (end.scheme != 'https') {
      f.add(ScanFinding(ScanLevel.bad, 'Không dùng HTTPS', 'Dữ liệu (kể cả mật khẩu) đi dạng rõ.'));
    } else if (cert != null) {
      final left = cert.endValidity.difference(DateTime.now()).inDays;
      f.add(left < 0
          ? ScanFinding(ScanLevel.bad, 'Chứng chỉ đã hết hạn', cert.issuer)
          : left < 10
          ? ScanFinding(ScanLevel.warn, 'Chứng chỉ sắp hết hạn ($left ngày)', cert.issuer)
          : ScanFinding(ScanLevel.ok, 'HTTPS hợp lệ', 'Cấp bởi ${cert.issuer} • còn $left ngày'));
    }
    if (rep.redirects.length > 3) {
      f.add(ScanFinding(ScanLevel.warn, 'Chuyển hướng nhiều lần (${rep.redirects.length})', rep.redirects.join('\n')));
    }
    final startBase = _base(start.host), endBase = _base(end.host);
    if (startBase != endBase) {
      f.add(ScanFinding(
        YomiAdBlock.isAd(rep.finalUrl) ? ScanLevel.bad : ScanLevel.warn,
        'Chuyển sang tên miền khác',
        '${start.host} → ${end.host} (trang có thể đã đổi tên miền – dùng “Đổi URL” trong tiện ích)',
      ));
    }
    if (rep.status >= 400) {
      final cf = (hv('server') ?? '').toLowerCase().contains('cloudflare') || hv('cf-mitigated') != null;
      f.add(ScanFinding(cf ? ScanLevel.info : ScanLevel.warn, 'Trang trả HTTP ${rep.status}',
          cf ? 'Cloudflare chặn yêu cầu tự động – dùng Cloudflare Bypass / WebView.' : ''));
    }

    // ── headers ──
    final missing = <String>[
      if (end.scheme == 'https' && hv('strict-transport-security') == null) 'Strict-Transport-Security',
      if (hv('content-security-policy') == null) 'Content-Security-Policy',
      if (hv('x-frame-options') == null && !(hv('content-security-policy') ?? '').contains('frame-ancestors'))
        'X-Frame-Options',
      if ((hv('x-content-type-options') ?? '').toLowerCase() != 'nosniff') 'X-Content-Type-Options',
      if (hv('referrer-policy') == null) 'Referrer-Policy',
    ];
    if (missing.isNotEmpty) {
      f.add(ScanFinding(missing.length >= 4 ? ScanLevel.warn : ScanLevel.info,
          'Thiếu ${missing.length} header bảo mật', missing.join(', ')));
    } else {
      f.add(ScanFinding(ScanLevel.ok, 'Header bảo mật đầy đủ'));
    }
    rep.server = [hv('server'), hv('x-powered-by')].whereType<String>().join(' • ');
    if (RegExp(r'\d+\.\d+').hasMatch(rep.server)) {
      f.add(ScanFinding(ScanLevel.info, 'Lộ phiên bản máy chủ', rep.server));
    }
    if ((hv('server') ?? '').toLowerCase().contains('cloudflare')) {
      f.add(ScanFinding(ScanLevel.ok, 'Được Cloudflare bảo vệ', 'Có thể gặp xác minh “Đang kiểm tra trình duyệt”'));
    }
    final weakCookies = <String>[];
    List<Cookie> cookies;
    try {
      cookies = res.cookies;
    } catch (_) {
      cookies = const [];
    }
    for (final c in cookies) {
      final miss = [if (!c.secure) 'Secure', if (!c.httpOnly) 'HttpOnly', if (c.sameSite == null) 'SameSite'];
      if (miss.isNotEmpty) weakCookies.add('${c.name} (${miss.join('/')})');
    }
    if (weakCookies.isNotEmpty) {
      f.add(ScanFinding(ScanLevel.info, 'Cookie thiếu cờ bảo vệ', weakCookies.join(', ')));
    }

    // ── content ──
    final lower = body.toLowerCase();
    final srcs = <String>{
      for (final m in RegExp(r'''<(?:script|iframe)[^>]+src\s*=\s*["']([^"']+)["']''', caseSensitive: false).allMatches(body))
        end.resolve(m.group(1)!.trim()).toString(),
    };
    final hosts = srcs.map((s) => Uri.tryParse(s)?.host ?? '').where((e) => e.isNotEmpty).toSet();
    rep.scriptHosts = hosts.length;
    final adHosts = srcs.where(YomiAdBlock.isAd).map((s) => Uri.parse(s).host).toSet();
    if (adHosts.isNotEmpty) {
      f.add(ScanFinding(adHosts.length > 4 ? ScanLevel.warn : ScanLevel.info,
          'Script / iframe quảng cáo – theo dõi (${adHosts.length})', adHosts.join(', ')));
    }
    final miners = _miners.where(lower.contains).toList();
    if (miners.isNotEmpty) {
      f.add(ScanFinding(ScanLevel.bad, 'Phát hiện mã đào tiền ảo', miners.join(', ')));
    }
    if (RegExp(r'eval\s*\(\s*(atob|unescape|decodeURIComponent)\s*\(', caseSensitive: false).hasMatch(body) ||
        RegExp(r'eval\s*\(\s*function\s*\(\s*p\s*,\s*a\s*,\s*c\s*,\s*k\s*,\s*e', caseSensitive: false).hasMatch(body)) {
      f.add(ScanFinding(ScanLevel.warn, 'JavaScript bị làm rối (eval/packer)',
          'Thường dùng để giấu quảng cáo pop-up hoặc mã độc; cũng có ở trình phát video.'));
    }
    final popunder = ['popunder', 'onclick=window.open', 'pop_under', 'popads', 'clickunder', 'propellerads', 'adsterra'];
    final pop = popunder.where(lower.contains).toList();
    if (pop.isNotEmpty) f.add(ScanFinding(ScanLevel.warn, 'Có quảng cáo bật cửa sổ (pop-under)', pop.join(', ')));
    if (RegExp(r'''(window|document|top)\.location(\.href)?\s*=\s*["']https?://''').hasMatch(body) ||
        RegExp(r'''<meta[^>]+http-equiv\s*=\s*["']refresh''', caseSensitive: false).hasMatch(body)) {
      f.add(ScanFinding(ScanLevel.info, 'Trang tự chuyển hướng bằng script/meta refresh'));
    }
    if (end.scheme == 'https') {
      final mixed = RegExp(r'''<(?:script|iframe|link)[^>]+(?:src|href)\s*=\s*["']http://''', caseSensitive: false)
          .allMatches(body)
          .length;
      if (mixed > 0) f.add(ScanFinding(ScanLevel.warn, 'Nội dung hỗn hợp (HTTP trong trang HTTPS): $mixed'));
    }
    final jq = RegExp(r'jquery[.-]?(\d)\.(\d+)(?:\.(\d+))?(?:\.min)?\.js', caseSensitive: false).firstMatch(body);
    if (jq != null) {
      final major = int.parse(jq.group(1)!), minor = int.parse(jq.group(2)!);
      if (major < 3 || (major == 3 && minor < 5)) {
        f.add(ScanFinding(ScanLevel.warn, 'jQuery cũ $major.$minor', 'Có lỗ hổng XSS đã biết (khuyên dùng ≥ 3.5).'));
      }
    }
    if (RegExp(r'<input[^>]+type\s*=\s*["\x27]password', caseSensitive: false).hasMatch(body) && end.scheme != 'https') {
      f.add(ScanFinding(ScanLevel.bad, 'Ô mật khẩu trên trang không mã hoá'));
    }
    if (YomiAdBlock.isAd(rep.finalUrl)) {
      f.add(ScanFinding(ScanLevel.bad, 'Tên miền nằm trong danh sách chặn quảng cáo / độc hại'));
    }
    if (f.where((e) => e.level == ScanLevel.bad || e.level == ScanLevel.warn).isEmpty) {
      f.add(ScanFinding(ScanLevel.ok, 'Không thấy dấu hiệu nguy hiểm'));
    }
    f.sort((a, b) => b.level.index.compareTo(a.level.index));
  }

  static String _base(String host) {
    final p = host.split('.');
    return p.length <= 2 ? host : p.sublist(p.length - 2).join('.');
  }
}

/// Settings › Web Scanner, and "Kiểm tra trang" in the browser menu.
class WebScannerScreen extends StatefulWidget {
  final String? initialUrl;
  const WebScannerScreen({super.key, this.initialUrl});

  @override
  State<WebScannerScreen> createState() => _WebScannerScreenState();
}

class _WebScannerScreenState extends State<WebScannerScreen> {
  late final _ctrl = TextEditingController(text: widget.initialUrl ?? '');
  ScanReport? _rep;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialUrl ?? '').isNotEmpty) _scan();
  }

  Future<void> _scan() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _rep = null;
    });
    final r = await YomiWebScanner.scan(_ctrl.text);
    if (mounted) {
      setState(() {
        _busy = false;
        _rep = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = _rep;
    Color colorOf(ScanLevel l) => switch (l) {
          ScanLevel.ok => Colors.green,
          ScanLevel.info => Colors.blueGrey,
          ScanLevel.warn => Colors.orange,
          ScanLevel.bad => Colors.red,
        };
    IconData iconOf(ScanLevel l) => switch (l) {
          ScanLevel.ok => Icons.check_circle,
          ScanLevel.info => Icons.info_outline,
          ScanLevel.warn => Icons.warning_amber_rounded,
          ScanLevel.bad => Icons.dangerous_outlined,
        };
    return Scaffold(
      appBar: AppBar(title: const Text('Web Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _scan(),
            decoration: InputDecoration(
              labelText: 'Địa chỉ trang web',
              hintText: 'https://…',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.radar), onPressed: _busy ? null : _scan),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kiểm tra thụ động như SiteCheck: HTTPS, chuyển hướng, header bảo mật, cookie, script quảng cáo / '
            'theo dõi / đào coin, mã làm rối, pop-under. Chỉ gửi một lượt tải trang bình thường.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (r != null) ...[
            const SizedBox(height: 12),
            Card(
              color: r.score >= 85
                  ? Colors.green.withValues(alpha: 0.12)
                  : r.score >= 60
                  ? Colors.orange.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              child: ListTile(
                leading: CircleAvatar(child: Text('${r.score}')),
                title: Text(r.verdict, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${r.finalUrl}\nHTTP ${r.status} • ${r.scriptHosts} nguồn script'
                  '${r.server.isEmpty ? '' : ' • ${r.server}'} • ${r.took.inMilliseconds} ms',
                ),
                isThreeLine: true,
              ),
            ),
            for (final f in r.findings)
              ListTile(
                dense: true,
                leading: Icon(iconOf(f.level), color: colorOf(f.level)),
                title: Text(f.title),
                subtitle: f.detail.isEmpty ? null : Text(f.detail, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }
}
