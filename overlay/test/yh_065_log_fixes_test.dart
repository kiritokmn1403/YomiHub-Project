// YomiHub 0.6.5 – fixes for logs 14/15 (YH 0.6.4 on Windows 26H2 and Xiaomi
// Android 16, 22–24/11/2026).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/perf/updates_preload.dart';
import 'package:mangayomi/yomihub/repos/repo_importer.dart';
import 'package:mangayomi/yomihub/update/multi_source_update.dart';

void main() {
  group('Kiritokmn repo moved to the YomiHub-Project organisation', () {
    const newIndex =
        'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/index.json';

    test('the built-in repo points at the new owner', () {
      expect(BuiltinExtensions.repoJson, newIndex);
      expect(BuiltinExtensions.repoWebsite,
          'https://github.com/YomiHub-Project/Kiritokmn---Extension-Repo');
    });

    test('old kiritokmn1403 addresses are rewritten', () {
      expect(
        BuiltinExtensions.migrateUrl(
            'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json'),
        newIndex,
      );
      expect(
        BuiltinExtensions.migrateUrl(
            'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/mangayomi/07br.js'),
        'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/mangayomi/07br.js',
      );
    });

    test('per-type mangayomi/<type>.json (does not exist) maps to repo/index.json', () {
      for (final t in ['anime', 'manga', 'novel', 'anime_index']) {
        expect(
          BuiltinExtensions.migrateUrl(
              'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/mangayomi/$t.json'),
          newIndex,
          reason: t,
        );
      }
    });

    test('other repositories are untouched', () {
      const k = 'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json';
      expect(BuiltinExtensions.migrateUrl(k), k);
      const m =
          'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json';
      expect(BuiltinExtensions.migrateUrl(m), m);
    });

    test('withRepo does not add a second copy next to the old address', () {
      final list = BuiltinExtensions.withRepo([
        Repo(
          name: 'Kiritokmn Extension Repo',
          jsonUrl:
              'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json',
        ),
      ]);
      expect(list.length, 1);
    });

    test('migrateRepos rewrites and removes the duplicate created by the move', () {
      final (out, changed) = BuiltinExtensions.migrateRepos([
        Repo(
          name: 'Kiritokmn Extension Repo',
          website: 'https://github.com/kiritokmn1403/Kiritokmn---Extension-Repo',
          jsonUrl:
              'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json',
        ),
        Repo(name: 'Kiritokmn (new)', jsonUrl: newIndex),
        Repo(name: 'Keiyoushi', jsonUrl: 'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb'),
      ]);
      expect(out.length, 2);
      expect(out.first.jsonUrl, newIndex);
      expect(out.first.website, 'https://github.com/YomiHub-Project/Kiritokmn---Extension-Repo');
      expect(changed, 2);
    });
  });

  group('Several repository links pasted in one box (log 14)', () {
    test('splits the "·" list and expands ".../x.json" from the previous link', () {
      final urls = YomiRepoImporter.splitInput(
        'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/mangayomi/anime.json'
        ' · .../manga.json · .../novel.json',
      );
      // all three map to the same repo/index.json → one entry
      expect(urls, [
        'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/index.json',
      ]);
    });

    test('different repositories on separate lines stay separate', () {
      final urls = YomiRepoImporter.splitInput(
        'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json\n'
        'raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json, nonsense',
      );
      expect(urls, [
        'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json',
        'https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json',
      ]);
    });
  });

  group('Log labels (Codex LOG_COVERAGE_065)', () {
    test('lost network without Tor is "[Lỗi Mạng]", with Tor keeps the Tor label', () {
      expect(
        AppLogger.classifyMessage(
            "[Kiểm tra cập nhật] Không đọc được nguồn GitHub Releases: ClientException with SocketException: Failed host lookup",
            LogLevel.warning),
        startsWith('[Lỗi Mạng] '),
      );
      expect(
        AppLogger.classifyMessage('Tor chưa kết nối được sau 90 giây (timeout)', LogLevel.warning),
        startsWith('[Lỗi Mạng / Tor Timeout]'),
      );
    });

    test('JVM VerifyError of an APK extension is a source error', () {
      const m = 'Extension "CBHentai" (vi, engine: mihon) getPopular 1: Bad type on operand stack in putfield';
      expect(AppLogger.classifyMessage(m, LogLevel.error), startsWith('[Lỗi Nguồn] '));
      expect(YomiExtErrors.isIncompatible(Exception('java.lang.VerifyError: Bad type on operand stack')), isTrue);
    });
  });

  group('Updates provider no longer nests async* generators', () {
    test('yomiSwitchMap follows the newest inner stream', () async {
      final outer = StreamController<int>();
      final inners = <int, StreamController<String>>{};
      final got = <String>[];
      final sub = yomiSwitchMap<int, String>(outer.stream, (i) {
        final c = StreamController<String>();
        inners[i] = c;
        return c.stream;
      }).listen(got.add);
      outer.add(1);
      await pumpEventQueue();
      inners[1]!.add('a1');
      outer.add(2);
      await pumpEventQueue();
      inners[1]!.add('late1'); // cancelled – must not arrive
      inners[2]!.add('b2');
      await pumpEventQueue();
      expect(got, ['a1', 'b2']);
      await sub.cancel();
    });

    test('thousands of outer events do not overflow the stack', () async {
      final outer = StreamController<int>(sync: true);
      var last = -1;
      final sub = yomiSwitchMap<int, int>(outer.stream, (i) => Stream<int>.value(i)).listen((v) => last = v);
      for (var i = 0; i < 5000; i++) {
        outer.add(i);
      }
      await pumpEventQueue();
      expect(last, 4999);
      await sub.cancel();
    });
  });

  group('Check for update reads the new GitHub organisation first', () {
    test('primary and legacy GitHub repositories', () {
      expect(YomiUpdateSources.githubRepo, 'YomiHub-Project/YomiHub-Project');
      expect(YomiUpdateSources.legacyGithubRepo, 'kiritokmn1403/YomiHub-Project');
    });
  });

  group('0.6.5 redactSecrets', () {
    test('masks api_key / login / token in URLs, keeps the rest', () {
      final out = AppLogger.redactSecrets(
        'HTTP 403 https://danbooru.donmai.us/posts.json?login=abc&api_key=SECRET123&page=2 '
        'and https://saucenao.com/search.php?output_type=2&api_key=K9 token=t0k',
      );
      expect(out.contains('SECRET123'), isFalse);
      expect(out.contains('K9'), isFalse);
      expect(out.contains('t0k'), isFalse);
      expect(out, contains('api_key=***'));
      expect(out, contains('login=***'));
      expect(out, contains('page=2'));
      expect(out, contains('output_type=2'));
    });
  });
}
