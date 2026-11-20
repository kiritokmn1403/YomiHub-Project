import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

/// YomiHub 0.6.3 (log 16–20/11/2026): many extensions failed with
/// "tls handshake eof", "connection closed", "HandshakeException: Connection
/// terminated during handshake" or "Unable to resolve host" (DamCoNuong,
/// Hako, AVSub, Phimmoi, HentaiVN, ViHentai, Rule34Video…) – the ISP blocks
/// those sites – while Tor was running, but only for the extensions picked
/// in VPN & DNS › Phạm vi. A request that the network blocks is now retried
/// once through Tor (when Tor is connected) and the host is remembered for
/// the session, so the next requests go through Tor straight away.
/// Setting: VPN & DNS › "Tự chuyển qua Tor khi trang bị chặn" (default on).
class YomiAutoTor {
  YomiAutoTor._();

  static const prefKey = 'autoTorOnBlock';
  static final Set<String> _routed = {};

  /// Set in worker isolates (no Hive there) from the main isolate's value.
  static bool? enabledOverride;

  static bool get enabled {
    final o = enabledOverride;
    if (o != null) return o;
    try {
      return !YomiPrefs.isOpen || YomiPrefs.get<bool>(prefKey, true);
    } catch (_) {
      return true;
    }
  }

  /// 0.6.3: state for a worker isolate (see [YomiVpnState.snapshot]).
  static Map<String, dynamic> snapshot() => {'enabled': enabled, 'routed': _routed.toList()};

  /// Applies [snapshot] in a worker isolate (hosts are added silently).
  static void applySnapshot(Map<dynamic, dynamic>? m) {
    if (m == null) return;
    final e = m['enabled'];
    if (e is bool) enabledOverride = e;
    final r = m['routed'];
    // (review Codex) the snapshot replaces the worker's set – an empty list
    // after "forget" must clear hosts a reused worker learnt earlier
    if (r is List) {
      _routed
        ..clear()
        ..addAll(r.whereType<String>().map((h) => h.toLowerCase()));
    }
  }

  /// Tor's local HTTP proxy when Tor is really connected (never the kill
  /// switch's dead port 9), else null.
  static String? torProxy() =>
      YomiVpnState.torEnabled && YomiVpnState.torRunning && YomiVpnState.torHttpPort > 0
          ? 'http://127.0.0.1:${YomiVpnState.torHttpPort}'
          : null;

  static bool isRouted(String host) => _routed.contains(host.toLowerCase());

  static Iterable<String> get routedHosts => _routed;

  static void forget() => _routed.clear();

  static void remember(String host, Object cause) {
    final h = host.toLowerCase();
    if (_routed.add(h)) {
      AppLogger.log(
        '[VPN] $h bị chặn khi đi thẳng (${cause is String ? cause : shortCause(cause)}) – tự chuyển các yêu cầu tới trang này qua Tor trong phiên này',
        logLevel: LogLevel.info,
      );
    }
  }

  /// Network-level failures typical of ISP blocking (TLS reset, DNS
  /// hijack/refusal, connection torn down mid-handshake). HTTP errors,
  /// Cloudflare pages and timeouts of slow servers are NOT blocks.
  static bool looksBlocked(Object e) {
    final m = e.toString().toLowerCase();
    const needles = [
      'tls handshake eof',
      'unexpectedeof',
      'connection terminated during handshake',
      'handshakeexception: connection terminated',
      'connection closed before',
      'connection closed',
      'connectionaborted',
      'connection reset',
      'failed host lookup',
      'unable to resolve host',
      'no address associated',
      'dns error',
    ];
    if (m.contains('certificate')) return false; // a broken certificate stays broken through Tor
    return needles.any(m.contains);
  }

  /// Failures that happen BEFORE the request reaches the server (DNS
  /// refusal, TLS torn down during the handshake) – safe to resend any
  /// method through Tor.
  static bool failedBeforeSend(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('certificate')) return false;
    const needles = [
      'tls handshake eof',
      'connection terminated during handshake',
      'handshakeexception: connection terminated',
      'failed host lookup',
      'unable to resolve host',
      'no address associated',
      'dns error',
    ];
    return needles.any(m.contains);
  }

  /// 0.6.3 (review Codex): resend through Tor only when that cannot repeat a
  /// write – idempotent reads always, other methods only when the request
  /// never reached the server.
  static bool safeToResend(String method, Object e) =>
      isIdempotent(method) ? looksBlocked(e) : failedBeforeSend(e);

  static bool isIdempotent(String method) {
    final m = method.toUpperCase();
    return m == 'GET' || m == 'HEAD' || m == 'OPTIONS';
  }

  static String shortCause(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('lookup') || m.contains('resolve') || m.contains('dns')) return 'DNS';
    if (m.contains('handshake')) return 'TLS';
    if (m.contains('reset') || m.contains('closed') || m.contains('abort')) return 'kết nối bị ngắt';
    return 'mạng';
  }
}
