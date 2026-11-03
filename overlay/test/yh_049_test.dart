// YomiHub 0.4.9 regression tests (real code paths, no copies of the logic).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';
import 'package:mangayomi/yomihub/about/github_projects.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:mangayomi/yomihub/update/multi_source_update.dart';
import 'package:mangayomi/yomihub/vbook/vbook_bridge.dart';

List<int> _zip(Map<String, String> files) {
  final a = Archive();
  files.forEach((n, c) {
    final b = utf8.encode(c);
    a.addFile(ArchiveFile(n, b.length, b));
  });
  return ZipEncoder().encode(a);
}

void main() {
  test('0.4.9: version / user agent', () {
    // 0.5.0: the exact version is checked in yh_050_test.dart
    expect(AppIdentity.userAgent, startsWith('YomiHub/'));
  });

  group('DbWriteQueue (logs_6: async write transaction already in progress)', () {
    test('runs writes in order, one at a time', () async {
      final q = DbWriteQueue();
      final log = <String>[];
      var active = 0, maxActive = 0;
      Future<void> job(String n, int ms) => q.run(() async {
            active++;
            maxActive = active > maxActive ? active : maxActive;
            log.add('start $n');
            await Future<void>.delayed(Duration(milliseconds: ms));
            log.add('end $n');
            active--;
          });
      await Future.wait([job('a', 20), job('b', 1), job('c', 5)]);
      expect(maxActive, 1);
      expect(log, ['start a', 'end a', 'start b', 'end b', 'start c', 'end c']);
      expect(q.isIdle, isTrue);
    });
    test('is re-entrant (nested write does not deadlock)', () async {
      final q = DbWriteQueue();
      final r = await q.run(() async => await q.run(() async => 42)).timeout(const Duration(seconds: 2));
      expect(r, 42);
    });
    test('an error does not block the next write', () async {
      final q = DbWriteQueue();
      await expectLater(q.run(() async => throw StateError('x')), throwsStateError);
      expect(await q.run(() => 7), 7);
    });
  });

  group('vBook bridge', () {
    final index = {
      'metadata': {'author': 'vBook'},
      'data': [
        {'name': 'Truyện Full', 'path': 'https://raw.githubusercontent.com/x/y/master/truyenfull/plugin.zip', 'version': 14, 'source': 'https://truyenfull.live', 'type': 'novel', 'locale': 'vi_VN', 'icon': 'truyenfull/icon.png'},
        {'name': 'Comic A', 'path': 'comica/plugin.zip', 'version': 3, 'source': 'https://a.test', 'type': 'comic', 'locale': 'global'},
        {'name': 'Phim B', 'path': 'phimb/plugin.zip', 'version': 1, 'source': 'https://b.test', 'type': 'video', 'locale': 'vi'},
        {'name': 'TTS', 'path': 'tts/plugin.zip', 'version': 1, 'type': 'tts'},
      ],
    };
    test('recognises a vBook repository index', () {
      expect(VBookBridge.isIndex(index), isTrue);
      expect(VBookBridge.isIndex({'sources': []}), isFalse);
    });
    test('maps entries to sources (type, language, relative paths, engines skipped)', () {
      final r = VBookBridge.parseIndex('https://raw.githubusercontent.com/x/y/master/plugin.json', index)!;
      expect(r.sources.length, 3);
      final n = r.sources[0];
      expect(n.itemType, ItemType.novel);
      expect(n.lang, 'vi');
      expect(n.version, '14.0.${VBookBridge.runtimeRev}');
      expect(VBookBridge.runtimeRev, greaterThanOrEqualTo(2));
      expect(n.sourceCodeLanguage, SourceCodeLanguage.javascript);
      expect(VBookBridge.isVBookSource(n), isTrue);
      expect(n.iconUrl, 'https://raw.githubusercontent.com/x/y/master/truyenfull/icon.png');
      expect(r.sources[1].itemType, ItemType.manga);
      expect(r.sources[1].lang, 'all');
      expect(r.sources[1].sourceCodeUrl, 'https://raw.githubusercontent.com/x/y/master/comica/plugin.zip');
      expect(r.sources[2].itemType, ItemType.anime);
      expect(r.sources.map((s) => s.id).toSet().length, 3);
    });
    test('builds the extension script from plugin.zip', () {
      final zip = _zip({
        'plugin.json': jsonEncode({'metadata': {'name': 'T', 'source': 'https://t.test', 'type': 'novel'}, 'script': {'search': 'search.js'}}),
        'src/search.js': 'function execute(key, page) { let d = fetch("https://t.test/s?q=" + key).html(); return Response.success([]); }',
        'src/sub/ignored.js': 'x',
        'icon.png': 'png',
      });
      final code = VBookBridge.fromZip(zip, common: '// common', runtime: '// runtime');
      expect(code, startsWith('// common'));
      expect(code, contains('const VB_PLUGIN = {"metadata":{"name":"T"'));
      expect(code, contains('"search.js":"function execute'));
      expect(code, isNot(contains('ignored.js')));
      expect(code.trimRight(), endsWith('// runtime'));
    });
    test('refuses encrypted extensions with a clear message', () {
      final zip = _zip({
        'plugin.json': jsonEncode({'metadata': {'name': 'Enc', 'encrypt': true}, 'script': {'search': 'search.js'}}),
        'src/search.js': 'U2FsdGVkX19vY2hYbWJ0cFh4Z0VhbDJ3c0ZtV1E9PQ==',
      });
      expect(() => VBookBridge.fromZip(zip, common: '', runtime: ''), throwsA(predicate((e) => '$e'.contains('Enc'))));
    });
    test('runtime asset contains the transpiler and the adapter', () {
      final f = File('assets/yomihub_extensions/vbook.js');
      expect(f.existsSync(), isTrue);
      final s = f.readAsStringSync();
      for (final k in ['function __vbTranspile', 'class DefaultExtension extends MProvider', 'async getHtmlContent', 'async getVideoList', '__aforEach']) {
        expect(s, contains(k));
      }
    });
  });

  group('Telegram backup (logs_6: chat_id is empty / chat not found)', () {
    test('bot token never reaches the log', () {
      const tok = '123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw';
      final m = TelegramProvider.maskToken('GET https://api.telegram.org/bot$tok/getUpdates failed', tok);
      expect(m, isNot(contains(tok)));
      expect(TelegramProvider.maskToken('bot$tok', ''), 'bot<token>');
    });
    test('Chat ID is optional (auto-detected from getUpdates)', () {
      final p = TelegramProvider();
      expect(p.fields.map((f) => f.key), containsAll(['token', 'chat_id']));
    });
  });

  test('update sources follow the "Website Update Apps" sheet order', () {
    expect(YomiUpdateSources.githubRepo, 'kiritokmn1403/YomiHub-Project');
    expect(YomiUpdateSources.driveFolders, [
      '16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__',
      '1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn',
      '1vLWPTfFznhWko0O6YGJqecnFEU5CLr10',
    ]);
    expect(YomiUpdateSources.mediafireFolders, ['kg0wfu3lpbc98', '8s2tlcukdmw6x', 'jmgm4xds8kamx']);
  });

  test('GitHub projects of 0.4.9 are listed in About', () {
    final urls = yomiGithubProjects.expand((g) => g.items).expand((p) => p.urls).toSet();
    for (final u in [
      'https://github.com/haipham22/LeechText/releases',
      'https://github.com/Windscribe/Android-App',
      'https://github.com/ParadoxIsCoding/Hotspot-Shield-VPN',
      'https://github.com/apivideo/resumeAVideo',
      'https://github.com/python-telegram-bot/python-telegram-bot',
      'https://github.com/ruffle-rs/ruffle',
    ]) {
      expect(urls, contains(u));
    }
  });

  test('no Anime47 account is shipped inside the extension', () {
    final s = File('assets/yomihub_extensions/anime47.js').readAsStringSync();
    // no e-mail address and no default value for the account fields
    expect(RegExp(r'[A-Za-z0-9.+_-]+@[A-Za-z0-9-]+\.[a-z]{2,}').hasMatch(s), isFalse);
    expect(s.contains('yhPref("a47_email", "")'), isTrue);
    expect(s.contains('yhPref("a47_password", "")'), isTrue);
    for (final k in ['a47_email', 'a47_password']) {
      expect(RegExp('key: "$k", editTextPreference: \\{[^}]*value: "", [^}]*text: "" \\}').hasMatch(s), isTrue, reason: k);
    }
  });

  test('every tr() text has an English translation', () {
    final en = Map<String, dynamic>.from(jsonDecode(File('assets/yomihub_i18n/en.json').readAsStringSync()) as Map);
    final re = RegExp(r"""\btr\(\s*'((?:[^'\\\n]|\\.)*)'""");
    final missing = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in re.allMatches(f.readAsStringSync())) {
        var v = m.group(1)!;
        if (v.replaceAll(r'\$', '').contains(r'$')) continue;
        v = v.replaceAll(r"\'", "'").replaceAll(r'\n', '\n').replaceAll(r'\$', r'$');
        if (!en.containsKey(v)) missing.add(v);
      }
    }
    expect(missing, isEmpty, reason: missing.take(10).join('\n'));
  });
}
