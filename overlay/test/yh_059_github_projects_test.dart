import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/about/github_projects.dart';

void main() {
  final urls = [for (final g in yomiGithubProjects) for (final p in g.items) ...p.urls];
  test('0.5.9: projects from the Project GitHub sheet are listed', () {
    for (final u in [
      'https://github.com/Evil0ctal/Douyin_TikTok_Download_API',
      'https://github.com/abrahamjuliot/creepjs',
      'https://github.com/khoadng/Boorusama',
      'https://github.com/pratikkarbhal/m3u8_StreamSniper',
    ]) {
      expect(urls, contains(u));
    }
  });
  test('every entry is an http(s) link; the 0.5.9 additions contain no attack-tool links', () {
    expect(urls.every((u) => u.startsWith('http')), isTrue);
    final added = [
      for (final g in yomiGithubProjects)
        if (g.title.endsWith('bổ sung 0.5.9')) for (final p in g.items) ...p.urls
    ];
    expect(added.length, 258);
    expect(added.where((u) => RegExp('hacking|0DAY|amsi_bypass', caseSensitive: false).hasMatch(u)), isEmpty);
  });
}
