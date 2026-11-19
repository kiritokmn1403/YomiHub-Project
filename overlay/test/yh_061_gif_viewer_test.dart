import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/gif/gif_viewer_screen.dart';

const _gif = 'R0lGODlhBAAEAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQABQAAACwAAAAABAAEAAAICQABCBxIsCCAgAAh+QQBAAABACwAAAAABAAEAIEA/wAAAAAAAAAAAAAICQABCBxIsCCAgAAh+QQBFAABACwAAAAABAAEAIEAAP8AAAAAAAAAAAAICQABCBxIsCCAgAA7';

void main() {
  test('YomiHub 0.6.1 GIF Viewer: khung kế tiếp + lặp', () {
    expect(gifNextIndex(0, 3, loop: true), 1);
    expect(gifNextIndex(2, 3, loop: true), 0);
    expect(gifNextIndex(2, 3, loop: false), isNull);
    expect(gifNextIndex(0, 1, loop: true), isNull);
    expect(GifFrames.normalize(Duration.zero).inMilliseconds, 100);
    expect(GifFrames.normalize(const Duration(milliseconds: 50)).inMilliseconds, 50);
  });

  test('giải mã GIF 3 khung, giữ thời lượng từng khung', () async {
    final g = await GifFrames.decode(base64Decode(_gif));
    expect(g.length, 3);
    expect(g.frames.first.width, 4);
    expect(g.durations.map((d) => d.inMilliseconds).toList(), [50, 100, 200]);
    g.dispose();
  });
}
