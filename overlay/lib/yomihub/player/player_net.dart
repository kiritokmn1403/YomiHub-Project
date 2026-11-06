import 'package:media_kit/media_kit.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

/// YomiHub 0.5.3 (logs 3: "Shorts FapReel (18+): lỗi phát video: Failed to
/// open https://cdncontent.imctransfer.com/…?token=…").
///
/// Tor, Mihon Proxy (Xray) and the custom proxy route an extension's HTTP
/// requests through a local HTTP proxy, but libmpv connected to the video
/// directly. A CDN token issued to the proxy's exit IP (or a CDN host the
/// network blocks) then failed only in the player. The player now uses the
/// same route as the extension that produced the stream.
class YomiPlayerNet {
  YomiPlayerNet._();

  /// The mpv `http-proxy` value for [sourceId]: an http:// proxy, or '' for
  /// a direct connection (mpv/ffmpeg cannot use SOCKS proxies).
  static String proxyFor(int? sourceId) {
    final p = YomiVpnState.proxyFor(sourceId);
    if (p == null || p.isEmpty) return '';
    final u = Uri.tryParse(p);
    if (u == null || u.scheme != 'http' || u.host.isEmpty) return '';
    return p;
  }

  /// Progressive files (mp4, webm…) only. Note 9 test (06/11/2026): an HLS
  /// stream (HotPhim) through Tor's HTTP tunnel port never started in mpv,
  /// so playlists keep the direct route they always used.
  static bool isProgressive(String url) {
    final path = (Uri.tryParse(url)?.path ?? '').toLowerCase();
    return RegExp(r'\.(mp4|m4v|webm|mkv|mov)$').hasMatch(path);
  }

  /// Applies [proxyFor] to [player] before `open()` and returns true when a
  /// proxy was set; local files and streaming playlists use a direct
  /// connection. Never throws.
  static Future<bool> apply(Player player, int? sourceId, {String? url}) async {
    var proxy = '';
    if (url == null || (url.startsWith('http') && isProgressive(url))) {
      proxy = proxyFor(sourceId);
    }
    try {
      final native = player.platform;
      if (native is NativePlayer) {
        await native.setProperty('http-proxy', proxy);
      }
    } catch (e) {
      AppLogger.logOnce('mpv-proxy:$e', '[Trình phát] Không đặt được proxy cho trình phát: $e',
          logLevel: LogLevel.warning);
      return false;
    }
    return proxy.isNotEmpty;
  }

  /// Back to a direct connection (used to retry a clip that failed through
  /// the proxy).
  static Future<void> clear(Player player) async {
    try {
      final native = player.platform;
      if (native is NativePlayer) await native.setProperty('http-proxy', '');
    } catch (_) {}
  }
}
