import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
// YomiHub 0.2.0: classify extension errors so logs.txt only keeps real faults.
//
// * "needs setup" errors (Jellyfin without a library, Google Drive without a
//   path, login required…) are user configuration, not crashes: logged once
//   per source as a warning, and the source is skipped by background
//   features (suggestions) for the rest of the session.
// * the same error from the same source within 60 s is written once
//   (logs.txt 07/10 had AVSub's error 13 times in 12 s, each with a stack).
class YomiExtErrors {
  static final RegExp _setup = RegExp(
    r'(in (the )?extension settings|select (a )?library|enter (drive )?path|'
    r'set (up|the) (server|url|address)|api key|login required|please log ?in|'
    r'not configured|chưa cấu hình|trong cài đặt (của )?tiện ích|đăng nhập)',
    caseSensitive: false,
  );
  static final Set<String> _needsSetup = {};
  static final Map<String, DateTime> _recent = {};
  static final Map<String, DateTime> _slow = {};

  static String _key(String? name, String? lang) => '${name ?? ''}|${lang ?? ''}';

  static bool isSetupError(Object e) => _setup.hasMatch(e.toString());

  /// true when this source told us it needs configuration this session.
  static bool needsSetup(String? name, String? lang) =>
      _needsSetup.contains(_key(name, lang));

  static void markSetup(String? name, String? lang) =>
      _needsSetup.add(_key(name, lang));

  /// Clear after the user edits the extension's settings.
  static void clear(String? name, String? lang) {
    final k = _key(name, lang);
    _needsSetup.remove(k);
    _slow.remove(k);
  }

  /// Sources that timed out are skipped by background work for 30 minutes.
  static void markSlow(String? name, String? lang) =>
      _slow[_key(name, lang)] = DateTime.now();
  static bool isSlow(String? name, String? lang) {
    final t = _slow[_key(name, lang)];
    return t != null && DateTime.now().difference(t) < const Duration(minutes: 30);
  }

  /// Whether an occurrence should be written to the log (dedupe 60 s).
  static bool shouldLog(String? name, String? lang, String? service, Object e) {
    final msg = e.toString();
    final k = '${_key(name, lang)}|$service|${msg.length > 160 ? msg.substring(0, 160) : msg}';
    final now = DateTime.now();
    final last = _recent[k];
    if (last != null && now.difference(last) < const Duration(seconds: 60)) return false;
    _recent[k] = now;
    if (_recent.length > 400) {
      _recent.removeWhere((_, t) => now.difference(t) > const Duration(minutes: 2));
    }
    return true;
  }

  /// YomiHub 0.2.1: site / network problems (dead or ISP-blocked domain,
  /// dropped connection, Cloudflare "origin down" 52x, MangaDex "network
  /// error"). Not app faults: logged as a one-line warning without a stack,
  /// and the source is skipped by Suggestions for 30 minutes.
  static final RegExp _net = RegExp(
    r'(unable to resolve host|no address associated|failed host lookup|'
    r'unknownhost|connection (closed|reset|refused|abort)|software caused connection abort|'
    r'socketexception|handshakeexception|network (error|is unreachable)|timed? ?out|'
    r'http error 5(2[0-9]|0[234])|status(code)?[=: ]+5(2[0-9]|0[234])\b|'
    r'failed to bypass cloudflare|cloudflare|certpathvalidatorexception|trust anchor|'
    r'missing madara post id|brotli stream decoding|sourceerror: network|'
    // 0.4.4: rhttp (Rust client) wording - "Connection error", proxy tunnel
    // refused, connect failed (logs 1.txt 28-29/10: Pornhub via Tor/proxy)
    r'rhttpconnectionexception|connection error|tunnelunsuccessful|connectfailed|'
    r'connection timed out)',
    caseSensitive: false,
  );

  static bool isNetworkError(Object e) => _net.hasMatch(e.toString());

  /// Vietnamese hint shown next to a DNS / network / Cloudflare failure.
  static String? hint(Object e) {
    final s = e.toString().toLowerCase();
    // 0.4.4: VPN kill switch (Tor on but not connected) routes requests to
    // 127.0.0.1:9 on purpose so nothing leaks - say so instead of a bare
    // "Connection refused 127.0.0.1:9".
    if (s.contains('127.0.0.1:9,') || s.contains('127.0.0.1:9)') || s.contains('127.0.0.1:9 ')) {
      return tr('Tor đang bật nhưng chưa kết nối, "Kill switch" (VPN & DNS) đang chặn tiện ích này. Chờ Tor kết nối, tắt Tor hoặc tắt Kill switch.');
    }
    if (s.contains('tunnelunsuccessful')) {
      return tr('Máy chủ proxy/VPN từ chối kết nối tới trang này: đổi máy chủ VPN, tắt proxy cho tiện ích hoặc thử lại sau.');
    }
    if (s.contains('madara post id')) {
      return tr('Nguồn truyện đổi định dạng hoặc URL: mở bằng WebView hoặc chuyển sang nguồn phụ.');
    }
    if (s.contains('brotli')) {
      return tr('Lỗi nén luồng từ máy chủ nguồn: thử lại sau hoặc chuyển sang nguồn phụ.');
    }
    if (s.contains('cloudflare') || s.contains('bypass cloudflare')) {
      return tr('Trang được bảo vệ bởi Cloudflare: mở bằng WebView hoặc bật VPN/WARP trong "VPN & DNS".');
    }
    if (s.contains('certpathvalidator') || s.contains('trust anchor')) {
      return tr('Lỗi chứng chỉ SSL của máy chủ trang web.');
    }
    if (s.contains('resolve host') || s.contains('no address associated') || s.contains('failed host lookup')) {
      return tr('Tên miền không phân giải được: trang có thể đã đổi tên miền hoặc bị nhà mạng chặn. '
          'Thử bật DNS/VPN trong "VPN & DNS", hoặc dùng "Đổi URL" trong trang tiện ích.');
    }
    if (RegExp(r'\b52[0-9]\b').hasMatch(s)) {
      return tr('Máy chủ của trang đang lỗi (Cloudflare 52x) – thử lại sau.');
    }
    return null;
  }

  /// One-line, user-readable form of an extension error (no stack, no
  /// "statusCode: 500" padding added by the APK bridge).
  static String short(Object e) {
    var s = e.toString();
    // 0.4.4: some exceptions (rhttp) embed the native Dart stack dump
    // ("*** *** ***", pid:, build_id:, #00 abs …) in toString(): cut it off.
    final cut = RegExp(r'\n\s*(\*\*\* \*\*\*|pid: \d+|#00 abs |<asynchronous suspension>)').firstMatch(s);
    if (cut != null) s = s.substring(0, cut.start);
    s = s.replaceAll(RegExp(r'\n{2,}'), '\n').trim();
    s = s.replaceAll(RegExp(r'\s*statusCode:\s*\d+\s*$'), '');
    s = s.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
    return s.trim();
  }
}
