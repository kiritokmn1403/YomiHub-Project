// YomiHub 0.6.0 – Get Video URL: links from page source / player config.
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/savior/video_url_extractor.dart';

void main() {
  const page = 'https://phim.example.com/xem/tap-1';
  test('jwplayer config with relative and escaped links', () {
    const html = r'''<script>jwplayer("p").setup({sources:[{file:"/hls/abc/master.m3u8?t=1"},
      {"file":"https:\/\/cdn.example.net\/v\/720.mp4","label":"720p"}]});</script>''';
    final r = VideoUrlExtractor.extract(html, page);
    expect(r.map((e) => e.url), containsAll([
      'https://phim.example.com/hls/abc/master.m3u8?t=1',
      'https://cdn.example.net/v/720.mp4',
    ]));
    expect(r.first.kind, 'hls'); // HLS first
  });
  test('og:video, source tag, protocol-relative, &amp;', () {
    const html = '<meta property="og:video" content="//v.example.org/a.mp4?x=1&amp;y=2">'
        '<video><source src="clip.webm"></video>';
    final urls = VideoUrlExtractor.extract(html, page).map((e) => e.url).toList();
    expect(urls, contains('https://v.example.org/a.mp4?x=1&y=2'));
    expect(urls, contains('https://phim.example.com/xem/clip.webm'));
  });
  test('ads, segments and blob are ignored; duplicates once', () {
    const html = '"https://ads.example.com/ads/pre.mp4" "https://c.example/seg-1.ts" '
        '"blob:https://x" "https://c.example/v.mp4" "https://c.example/v.mp4"';
    final urls = VideoUrlExtractor.extract(html, page).map((e) => e.url).toList();
    expect(urls, ['https://c.example/v.mp4']);
  });
  test('iframes are listed for scanning inside', () {
    const html = '<iframe src="https://player.example.tv/e/xyz" allowfullscreen></iframe>';
    expect(VideoUrlExtractor.iframes(html, page), ['https://player.example.tv/e/xyz']);
  });
  test('kinds', () {
    expect(VideoUrlExtractor.kindOf('a.mpd'), 'dash');
    expect(VideoUrlExtractor.kindOf('a.m4a'), 'audio');
  });
}
