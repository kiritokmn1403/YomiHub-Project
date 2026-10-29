import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';

import 'package:media_kit/media_kit.dart';

/// YomiHub 0.1.8: SponsorBlock for the YouTube extension (the "skip
/// sponsor" feature of YouTube Vanced / vancedTube).
///
/// The extension asks sponsor.ajay.app for the segments of the video and
/// passes them along with the stream in the `yh_sb` pseudo-header
/// ("12.0-30.5~sponsor|…"); the player removes that header and skips the
/// segments while playing.
class YomiSponsorBlock {
  static const header = 'yh_sb';

  static const labels = {
    'sponsor': 'Quảng cáo tài trợ',
    'selfpromo': 'Tự quảng bá',
    'interaction': 'Nhắc đăng ký / tương tác',
    'intro': 'Đoạn mở đầu',
    'outro': 'Đoạn kết',
    'preview': 'Đoạn xem trước',
    'music_offtopic': 'Đoạn không phải nhạc',
  };

  /// Headers without the SponsorBlock data.
  static Map<String, String>? clean(Map<String, String>? h) {
    if (h == null || !h.containsKey(header)) return h;
    return Map.of(h)..remove(header);
  }

  static List<(double, double, String)> parse(Map<String, String>? h) {
    final raw = h?[header];
    if (raw == null || raw.isEmpty) return const [];
    final out = <(double, double, String)>[];
    for (final part in raw.split('|')) {
      final m = RegExp(r'^([\d.]+)-([\d.]+)~(.*)$').firstMatch(part.trim());
      if (m == null) continue;
      final a = double.tryParse(m.group(1)!), b = double.tryParse(m.group(2)!);
      if (a == null || b == null || b - a < 1) continue;
      out.add((a, b, m.group(3)!));
    }
    return out;
  }

  /// Skips the segments while [player] plays; [onSkip] gets the label.
  static StreamSubscription<Duration>? attach(
    Player player,
    Map<String, String>? headers,
    void Function(String label) onSkip,
  ) {
    final segs = parse(headers);
    if (segs.isEmpty) return null;
    final done = <int>{};
    return player.stream.position.listen((p) {
      final t = p.inMilliseconds / 1000;
      for (var i = 0; i < segs.length; i++) {
        final s = segs[i];
        if (t >= s.$1 && t < s.$2 - 0.5 && !done.contains(i)) {
          done.add(i);
          player.seek(Duration(milliseconds: (s.$2 * 1000).round()));
          onSkip(tr(labels[s.$3] ?? s.$3));
          break;
        }
        // seeking back before a segment re-arms it
        if (t < s.$1 - 2) done.remove(i);
      }
    });
  }
}
