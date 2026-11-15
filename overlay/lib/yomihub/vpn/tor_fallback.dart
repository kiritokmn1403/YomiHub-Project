/// YomiHub 0.5.7 (logs 7, 12–13/11/2026): 10× "Tor chưa kết nối được sau 90
/// giây (dừng ở 45%: Asking for relay descriptors)" with the bridge fixed to
/// "snowflake". Only the "auto" mode tried another transport; a transport
/// chosen by the user was kept for ever, even when its bootstrap did not
/// move at all.
///
/// Pure logic (no Flutter / platform channel) so it can be unit tested:
/// which transports to try and when bootstrap counts as stalled. The stall
/// test is "progress has not increased for [stallLimit]", not a fixed time
/// since the start – a slow but advancing bootstrap is left alone.
class TorBridgeFallback {
  TorBridgeFallback._();

  /// Pluggable transports YomiHub ships bridge lines for (lyrebird).
  static const transports = ['snowflake', 'obfs4', 'meek'];

  /// Whether [chosen] is a fixed transport the fallback applies to.
  /// 'auto' is handled natively (direct → snowflake → obfs4 → meek) and
  /// '' means "no bridge" – both keep their existing behaviour.
  static bool appliesTo(String chosen) => transports.contains(chosen);

  /// Order to try: the user's transport first, then the other transports
  /// that have bridge lines, and a direct connection last.
  static List<String> order(String chosen, Iterable<String> available) {
    if (!appliesTo(chosen)) return [chosen];
    final have = available.toSet();
    return [
      chosen,
      for (final t in transports)
        if (t != chosen && have.contains(t)) t,
      '',
    ];
  }

  /// How long bootstrap may stay at the same percentage. Same limits as the
  /// native "auto" watcher: 40 s direct, 75 s through a transport.
  static Duration stallLimit(String kind) =>
      kind.isEmpty ? const Duration(seconds: 40) : const Duration(seconds: 75);

  /// Name used in the Vietnamese log.
  static String label(String kind) => kind.isEmpty ? 'kết nối thẳng (không cầu nối)' : 'cầu nối "$kind"';

  /// PROGRESS=nn of a `status/bootstrap-phase` line, null when absent.
  static int? progressOf(String bootstrap) {
    final m = RegExp(r'PROGRESS=(\d+)').firstMatch(bootstrap);
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// SUMMARY="…" of a `status/bootstrap-phase` line ('' when absent).
  static String summaryOf(String bootstrap) =>
      RegExp(r'SUMMARY="([^"]*)"').firstMatch(bootstrap)?.group(1) ?? '';
}

enum TorStallKind {
  /// Nothing to do.
  none,

  /// Bootstrap stalled: switch to [TorStallStep.to].
  switchTo,

  /// Every transport stalled: go back to the user's choice and stop.
  exhausted,

  /// Bootstrap reached 100 %.
  done,
}

class TorStallStep {
  const TorStallStep(this.kind, {this.from = '', this.to = '', this.percent = 0, this.stalled = Duration.zero, this.attempt = 0, this.total = 0});
  final TorStallKind kind;
  final String from;
  final String to;
  final int percent;
  final Duration stalled;

  /// 1-based number of the transport being switched to, out of [total].
  final int attempt;
  final int total;
}

/// Feeds on bootstrap percentages and says when to change transport.
class TorStallTracker {
  TorStallTracker(this.order, DateTime start)
      : assert(order.isNotEmpty),
        _since = start;

  final List<String> order;
  int _index = 0;
  int _best = -1;
  DateTime _since;
  bool _finished = false;

  /// Transport currently being tried.
  String get current => order[_index];

  /// True once a fallback transport (not the user's choice) is in use.
  bool get onFallback => _index > 0;

  bool get finished => _finished;

  /// Transports tried so far, in order.
  List<String> get tried => order.sublist(0, _index + 1);

  /// [percent] = bootstrap progress read now (null: control port not
  /// answering yet – that time is not counted as a stall).
  TorStallStep update(int? percent, DateTime now) {
    if (_finished) return const TorStallStep(TorStallKind.none);
    if (percent == null) {
      _since = now;
      return const TorStallStep(TorStallKind.none);
    }
    if (percent >= 100) {
      _finished = true;
      return TorStallStep(TorStallKind.done, from: current, percent: percent);
    }
    if (percent > _best) {
      _best = percent;
      _since = now;
      return const TorStallStep(TorStallKind.none);
    }
    final stalled = now.difference(_since);
    if (stalled < TorBridgeFallback.stallLimit(current)) {
      return const TorStallStep(TorStallKind.none);
    }
    final from = current;
    if (_index + 1 >= order.length) {
      _finished = true;
      return TorStallStep(TorStallKind.exhausted,
          from: from, to: order.first, percent: percent, stalled: stalled, attempt: order.length, total: order.length);
    }
    _index++;
    _best = -1;
    _since = now;
    return TorStallStep(TorStallKind.switchTo,
        from: from, to: current, percent: percent, stalled: stalled, attempt: _index + 1, total: order.length);
  }
}
