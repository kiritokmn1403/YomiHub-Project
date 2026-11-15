import 'package:http/http.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

/// YomiHub 0.5.7 (logs 7, 12/11/2026): "[Kotatsu] Cầu nối không trả lời
/// (… URL: http://127.0.0.1:47350/kotatsu/list?… tcp connect error
/// 127.0.0.1:9 ConnectionRefused)".
///
/// A source routed through Tor / Mihon Proxy / the custom proxy got ONE
/// proxied HTTP client for all of its requests, including the ones to the
/// app's own loopback servers (Kotatsu bridge 47350, IReader 47360, the
/// Cloudflare/WebView helper, the chunk proxy…). Those then went to the
/// proxy – while Tor was still starting that is the kill switch
/// (127.0.0.1:9, refuses everything); with Tor connected, Tor itself
/// refuses to reach 127.0.0.1. The bridge was reported as dead and
/// restarted, which also cut the requests of the other Kotatsu sources.
///
/// This client sends loopback requests through [direct] (never a proxy) and
/// everything else through [proxied].
class YomiLoopbackBypassClient extends BaseClient {
  YomiLoopbackBypassClient(this.proxied, this.direct, {this.proxy});

  final Client proxied;
  final Client direct;

  /// Proxy [proxied] uses (for the leak guard), null = unknown.
  final String? proxy;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (!YomiVpnState.isLoopbackHost(request.url.host)) {
      return proxied.send(request);
    }
    if (YomiVpnState.bridgeWouldLeak(request.url, proxy)) {
      throw YomiRouteBlocked(
        tr('Tiện ích này được đặt đi qua VPN/Tor nhưng chạy bằng cầu nối trong máy (Kotatsu/IReader), cầu nối chỉ đi qua VPN khi phạm vi là "Tất cả tiện ích" trên Android. YomiHub đã chặn yêu cầu để không lộ IP thật: chọn phạm vi "Tất cả tiện ích", bỏ tiện ích này khỏi VPN hoặc dùng WARP/VPN toàn thiết bị.'),
      );
    }
    return direct.send(request);
  }

  @override
  void close() {
    // [direct] is shared; [proxied] is pooled by MClient.
  }
}

/// A request that was stopped on purpose so it cannot leave the device
/// outside the VPN route chosen for its source. Not a dead bridge.
class YomiRouteBlocked implements Exception {
  YomiRouteBlocked(this.message) {
    _lastAt = DateTime.now();
  }
  final String message;

  static DateTime? _lastAt;

  /// True for [e] itself and – in case an HTTP wrapper re-threw it as another
  /// type – for any error caught within two seconds of the guard firing.
  static bool caused(Object e) {
    if (e is YomiRouteBlocked) return true;
    final t = _lastAt;
    return t != null && DateTime.now().difference(t).inSeconds < 2;
  }

  @override
  String toString() => message;
}
