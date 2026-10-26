// YomiHub 0.1.5: checks every repository from "YomiHub - Extension Repo.docx".
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/services/extension_store_service.dart';

void main() {
  const urls = [
    'https://aidoku-community.github.io/sources/index.min.json',
    'https://raw.githubusercontent.com/Kareadita/tach-extension/repo/index.min.json',
    'https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json',
    'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/index.json',
    'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json',
    'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/novel_index.json',
    'https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json',
    'https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json',
    'https://raw.githubusercontent.com/gato404/kegareta-sauces/main/index.json',
    'https://raw.githubusercontent.com/FelipeGFA/extensoes/repo/index.min.json',
    'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb',
    'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json',
  ];
  test('repos', () async {
    final client = InterceptedClient.build(interceptors: [], client: http.Client());
    for (final u in urls) {
      try {
        final r = await ExtensionStoreService.fetchStore(u, client);
        if (r == null) {
          print('YH| NULL | $u');
          continue;
        }
        final by = <String, int>{};
        final lang = <String, int>{};
        for (final s in r.sources) {
          by['${s.itemType.name}/${s.sourceCodeLanguage.name}'] = (by['${s.itemType.name}/${s.sourceCodeLanguage.name}'] ?? 0) + 1;
          lang[s.lang ?? '?'] = (lang[s.lang ?? '?'] ?? 0) + 1;
        }
        final first = r.sources.take(2).map((s) => '${s.name} [${s.version}] ${s.sourceCodeUrl ?? ''}').join(' ; ');
        print('YH| ${r.sources.length} | ${r.name} | idx=${r.indexUrl} | $by | vi=${lang['vi'] ?? 0} | $first | $u');
      } catch (e) {
        print('YH| ERR $e | $u');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
