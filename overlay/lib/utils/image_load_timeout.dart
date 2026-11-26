import 'dart:async';

import 'package:mangayomi/utils/log/log_rate_limiter.dart';

/// YomiHub 0.5.7 (QA3): upper bound for one page/cover image request (connect
/// + headers, and then each gap between body chunks). Before this a page
/// whose host never answered (DNS blackholed, half-open socket) spun forever
/// in the reader: no error, no log, and "Thử lại" joined the same hung
/// in-flight request.
const Duration kImageLoadTimeout = Duration(seconds: 30);

/// Extra slack the reader widgets wait on top of [kImageLoadTimeout] before
/// they give up on the image stream themselves (backstop only: the provider
/// normally reports the timeout first).
const Duration kImageLoadBackstop = Duration(seconds: 45);

/// 0.5.7 (P8F): once the page file is on disk, how long the reader waits for
/// it to be decoded and drawn before it shows "Không tải được ảnh này".
const Duration kImageDecodeBackstop = Duration(seconds: 30);

/// 0.6.2 (log 19/11/2026 20:58, SayHentai Kotatsu): ảnh qua cổng nội bộ
/// Kotatsu (`127.0.0.1/kotatsu/image`) có thể phải chờ giải Cloudflare cho CDN
/// (WebView, tới ~60–150 s) trước khi trả ảnh – hạn 30 s cắt ngang lúc đang giải
/// → "không phản hồi (qua cổng nội bộ)" rồi HTTP 403. Cổng nội bộ được chờ lâu hơn.
const Duration kImageLocalBridgeTimeout = Duration(seconds: 120);

/// Hạn chờ cho một URL ảnh (cổng nội bộ Kotatsu được chờ lâu hơn).
Duration imageTimeoutFor(Uri u) {
  final h = u.host.toLowerCase();
  final local = h == '127.0.0.1' || h == 'localhost' || h == '::1';
  return local && u.path.startsWith('/kotatsu/') ? kImageLocalBridgeTimeout : kImageLoadTimeout;
}

/// Thrown when an image request exceeded [timeout].
class ImageLoadTimeoutException implements TimeoutException {
  ImageLoadTimeoutException(this.host, this.timeout, {this.phase = 'connect'});

  final String host;
  final String phase;
  final Duration timeout;

  @override
  Duration? get duration => timeout;

  @override
  String? get message => toString();

  @override
  String toString() =>
      'ImageLoadTimeout: $host không phản hồi sau ${timeout.inSeconds}s ($phase)';
}

/// Runs [f] with a deadline; throws [ImageLoadTimeoutException] on expiry.
/// (The underlying request is not cancellable, it is just no longer awaited.)
Future<T> withImageTimeout<T>(
  Future<T> f, {
  required String host,
  String phase = 'connect',
  Duration timeout = kImageLoadTimeout,
}) {
  return f.timeout(
    timeout,
    onTimeout: () => throw ImageLoadTimeoutException(host, timeout, phase: phase),
  );
}

/// Whether [e] is a timeout of any kind (ours, dart:async's, or its text).
bool isImageLoadTimeout(Object? e) {
  if (e == null) return false;
  if (e is TimeoutException) return true;
  final s = e.toString();
  return s.contains('ImageLoadTimeout') || s.contains('TimeoutException');
}

enum ImageLoadFailure { timeout, dns, tls, http, other }

/// Classifies an image-load error from its (possibly wrapped) text.
ImageLoadFailure classifyImageLoadError(Object? e) {
  if (e == null) return ImageLoadFailure.other;
  if (isImageLoadTimeout(e)) return ImageLoadFailure.timeout;
  final s = e.toString();
  if (RegExp(r'Failed host lookup|nodename nor servname|No address associated|unknown host|errno = 7\b', caseSensitive: false).hasMatch(s)) {
    return ImageLoadFailure.dns;
  }
  if (RegExp(r'HandshakeException|CERTIFICATE_VERIFY|TlsException', caseSensitive: false).hasMatch(s)) {
    return ImageLoadFailure.tls;
  }
  if (RegExp(r'HTTP \d{3}').hasMatch(s)) return ImageLoadFailure.http;
  return ImageLoadFailure.other;
}

/// First `host` found in [text] ('' when none).
String imageHostOf(String text) {
  final m = RegExp(r'(?:https?:)?//([^/\s:"\x27)]+)').firstMatch(text);
  if (m != null) return m.group(1)!;
  final h = RegExp(r"host(?:name)? '?([A-Za-z0-9.-]+\.[A-Za-z]{2,})").firstMatch(text);
  return h?.group(1) ?? '';
}

/// 0.6.0 (log 19/11/2026 00:44–00:45): images served through a local bridge
/// (Kotatsu `127.0.0.1:<port>/kotatsu/image?page=…`, HLS/chunk proxy `?u=…`)
/// were logged as "Không tải được ảnh từ 127.0.0.1". For the log, name the
/// real image server carried in the query instead.
String logImageHost(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return imageHostOf(url);
  final h = u.host.toLowerCase();
  if (h == '127.0.0.1' || h == 'localhost' || h == '::1') {
    for (final k in const ['page', 'u', 'url', 'src']) {
      final inner = u.queryParameters[k];
      if (inner == null) continue;
      final ih = Uri.tryParse(inner)?.host ?? '';
      if (ih.isNotEmpty) return '$ih (qua cổng nội bộ)';
    }
  }
  return u.host.isNotEmpty ? u.host : imageHostOf(url);
}

/// Short Vietnamese reason shown under "Không tải được ảnh này". [translate]
/// is `tr` in the app (identity in tests).
String describeImageLoadError(
  Object? e, {
  String host = '',
  String Function(String vi, Map<String, Object?>? args)? translate,
}) {
  String t(String vi, [Map<String, Object?>? a]) {
    if (translate != null) return translate(vi, a);
    var s = vi;
    a?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  final h = host.isNotEmpty ? host : imageHostOf(e?.toString() ?? '');
  final args = {'host': h.isEmpty ? '?' : h, 'sec': kImageLoadTimeout.inSeconds};
  switch (classifyImageLoadError(e)) {
    case ImageLoadFailure.timeout:
      return t('Hết thời gian chờ ({sec} giây): máy chủ {host} không phản hồi', args);
    case ImageLoadFailure.dns:
      return t('Không phân giải được tên miền {host} (kiểm tra mạng/DNS)', args);
    case ImageLoadFailure.tls:
      return t('Lỗi chứng chỉ bảo mật khi kết nối {host}', args);
    case ImageLoadFailure.http:
      return t('Máy chủ {host} từ chối hoặc trả lỗi', args);
    case ImageLoadFailure.other:
      return t('Lỗi mạng khi tải ảnh từ {host}', args);
  }
}

/// WARNING-to-log decision: at most one line per host per [window]; the rest
/// are counted into one summary line (built on [LogBurstAggregator]).
class ImageFailWarnLog {
  ImageFailWarnLog({
    required this.emit,
    this.window = const Duration(minutes: 1),
    this.useTimer = true,
  });

  final void Function(String line) emit;
  final Duration window;
  final bool useTimer;
  final Map<String, LogBurstAggregator> _perHost = {};

  void record(String host, Object? error, {DateTime? now}) {
    final h = host.isEmpty ? '?' : host;
    final agg = _perHost.putIfAbsent(
      h,
      () => LogBurstAggregator(
        emit: emit,
        window: window,
        useTimer: useTimer,
        summary: (n, hostCount, hosts) =>
            'Tải ảnh từ $h vẫn lỗi: thêm $n lần trong 1 phút qua',
      ),
    );
    if (_perHost.length > 100) _perHost.remove(_perHost.keys.first);
    agg.record(
      h,
      'Không tải được ảnh từ $h: ${describeImageLoadError(error, host: h)}',
      now: now,
    );
  }
}

/// YomiHub 0.6.7 (log 17 dòng 948: `cdn.donmai.us` lỗi 239 lần/phút, 0.6.5):
/// khi một máy chủ ảnh trả lỗi liên tục (403 Cloudflare, 503, hết giờ), lưới
/// bìa/thu nhỏ vẫn gửi hàng trăm yêu cầu mỗi phút – tốn pin, mạng và làm tràn
/// nhật ký. Sau [threshold] lần lỗi liên tiếp trong [window] mà không có lần
/// nào thành công, host bị "ngắt" [cooldown]: yêu cầu mới trả lỗi ngay. Một
/// lần tải thành công gỡ ngắt. Chỉ áp cho máy chủ mạng (không cổng nội bộ).
class ImageHostBreaker {
  ImageHostBreaker({
    this.threshold = 8,
    this.window = const Duration(seconds: 60),
    this.cooldown = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final int threshold;
  final Duration window;
  final Duration cooldown;
  final DateTime Function() _now;
  final Map<String, ({int fails, DateTime first, DateTime? openUntil})> _s = {};

  static bool _exempt(String host) {
    final h = host.toLowerCase();
    return h.isEmpty || h == '127.0.0.1' || h == 'localhost' || h == '::1';
  }

  /// Còn bao lâu nữa host mới được thử lại (null = được gọi ngay).
  Duration? blockedFor(String host) {
    if (_exempt(host)) return null;
    final st = _s[host.toLowerCase()];
    final until = st?.openUntil;
    if (until == null) return null;
    final left = until.difference(_now());
    if (left <= Duration.zero) {
      // hết thời gian ngắt: cho 1 lượt thử, lỗi tiếp là ngắt lại ngay
      _s[host.toLowerCase()] = (fails: threshold - 1, first: _now(), openUntil: null);
      return null;
    }
    return left;
  }

  /// Trả true khi lần lỗi này vừa làm host bị ngắt.
  bool fail(String host) {
    if (_exempt(host)) return false;
    final k = host.toLowerCase();
    final now = _now();
    final st = _s[k];
    // 0.6.7 (Codex REVIEW_CODE_067 – Cao): một yêu cầu đang bay từ trước khi
    // ngắt báo lỗi muộn không được đóng lại khoảng ngắt đang mở.
    final openUntil = st?.openUntil;
    if (openUntil != null && now.isBefore(openUntil)) return false;
    var fails = 1;
    var first = now;
    if (st != null && st.openUntil == null && now.difference(st.first) <= window) {
      fails = st.fails + 1;
      first = st.first;
    }
    if (fails >= threshold) {
      _s[k] = (fails: fails, first: first, openUntil: now.add(cooldown));
      return true;
    }
    _s[k] = (fails: fails, first: first, openUntil: null);
    if (_s.length > 200) _s.remove(_s.keys.first);
    return false;
  }

  void success(String host) {
    final k = host.toLowerCase();
    final until = _s[k]?.openUntil;
    // một yêu cầu cũ thành công muộn không mở khoá host đang bị ngắt
    if (until != null && _now().isBefore(until)) return;
    _s.remove(k);
  }

  /// 0.6.7: chỉ lỗi phía máy chủ/kết nối mới tính cho bộ ngắt; 404/410/400 là
  /// lỗi của riêng ảnh đó.
  static bool countsAsHostFailure(int? status) =>
      status == null || status == 403 || status == 429 || (status >= 500 && status < 600);
}
