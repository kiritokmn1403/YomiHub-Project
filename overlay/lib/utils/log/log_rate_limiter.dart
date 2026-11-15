import 'dart:async';

/// YomiHub 0.5.7 (S1): collapses a burst of repetitive log lines (cover /
/// page images that fail to load: 164 INFO lines in logs 7, one per host and
/// per session over 19 sessions) into
///   * the first line of the window, written at once (full original text), and
///   * one summary line per window with the number of suppressed events and
///     the hosts they came from (top [maxHostsShown]).
///
/// Nothing is lost silently: every suppressed event is counted and its host
/// is named in the summary.
class LogBurstAggregator {
  LogBurstAggregator({
    required this.emit,
    required this.summary,
    this.window = const Duration(minutes: 1),
    this.maxHostsShown = 5,
    this.useTimer = true,
  });

  /// Writes a line (the first event of a window).
  final void Function(String line) emit;

  /// Builds the summary line from (suppressed count, "host ×n, host ×n" text).
  final String Function(int suppressed, int hostCount, String hosts) summary;
  final Duration window;
  final int maxHostsShown;
  final bool useTimer;

  DateTime? _start;
  final Map<String, int> _hosts = {};
  int _suppressed = 0;
  Timer? _timer;

  int get suppressed => _suppressed;

  void record(String host, String message, {DateTime? now}) {
    now ??= DateTime.now();
    final s = _start;
    if (s != null && now.difference(s) >= window) flush();
    if (_start == null) {
      _start = now;
      emit(message);
      if (useTimer) {
        _timer?.cancel();
        _timer = Timer(window, flush);
      }
      return;
    }
    _suppressed++;
    final h = host.isEmpty ? '?' : host;
    _hosts[h] = (_hosts[h] ?? 0) + 1;
    if (_hosts.length > 200) _hosts.remove(_hosts.keys.first);
  }

  /// Ends the window: writes the summary when anything was suppressed.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_suppressed > 0) {
      final top = _hosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final text = top.take(maxHostsShown).map((e) => '${e.key} ×${e.value}').join(', ') +
          (top.length > maxHostsShown ? ', …' : '');
      emit(summary(_suppressed, _hosts.length, text));
    }
    _start = null;
    _suppressed = 0;
    _hosts.clear();
  }
}
