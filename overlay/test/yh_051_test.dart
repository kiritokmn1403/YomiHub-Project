// YomiHub 0.5.1 regression tests (real code paths).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/library/providers/file_scanner.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/net/gh_mirror.dart';
import 'package:mangayomi/yomihub/vbook/vbook_bridge.dart';
import 'package:mangayomi/yomihub/apk/axml_decoder.dart';
import 'package:mangayomi/yomihub/apk/dex_reader.dart';
import 'package:mangayomi/yomihub/apk/apk_inspector.dart';
import 'package:mangayomi/yomihub/apk/apk_inspector_screen.dart';
import 'package:mangayomi/yomihub/ui/app_log_screen.dart';
import 'package:archive/archive.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

String _read(String path) => File(path).readAsStringSync();

void _touch(String root, String rel, [String data = 'x']) {
  final f = File(p.join(root, rel));
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(data);
}

void main() {
  group('YomiHub 0.5.1', () {
    test('version / user agent', () {
      expect(AppIdentity.userAgent, 'YomiHub/0.5.1');
      expect(_read('pubspec.yaml'), contains('version: 0.5.1+43'));
    });

    // YomiHub Update: local folder did not see Aniyomi / Nekoyomi / Mangayomi downloads
    test('local scan finds titles stored like Mihon/Aniyomi/Nekoyomi/Mangayomi', () async {
      final root = Directory.systemTemp.createTempSync('yh051_').path;
      try {
        // Mihon / Nekoyomi comic (.cbz) + unfinished download
        _touch(root, 'downloads/CBHentai (VI)/Title A/Chapter 1.cbz');
        _touch(root, 'downloads/CBHentai (VI)/Title A/Chapter 2_tmp/001.jpg');
        // Aniyomi: one folder per episode
        _touch(root, 'downloads/AnimeOnsen (ALL)/Anime B/Episode 3/Episode 3.mkv');
        _touch(root, 'downloads/AnimeOnsen (ALL)/Anime B/Episode 4_tmp/Episode 4.tmp');
        // Mangayomi: downloads/Manga/<Source>/<Title>/<Chapter>/pages
        _touch(root, 'downloads/Manga/FoxTruyen (VI)/Title C/Chap 1/001.jpg');
        _touch(root, 'downloads/Manga/FoxTruyen (VI)/Title C/metadata.json', '{}');
        // copy of the same tree nested inside itself – must not import twice
        _touch(root, 'localnovel/localnovel/downloads/CBHentai (VI)/Title A/Chapter 1.cbz');
        // app data next to downloads – never titles
        _touch(root, 'autobackup/app.nekoyomi_2026.tachibk');
        _touch(root, 'mpv-config/shaders/a.glsl');
        final top = Directory(root).listSync().whereType<Directory>().toList();
        final titles = (await debugCollectTitleFolders(top)).map((d) => p.basename(d.path)).toList();
        expect(titles, containsAll(['Title A', 'Anime B', 'Title C']));
        expect(titles.where((t) => t == 'Title A').length, 1);
        expect(titles, isNot(contains('autobackup')));
        expect(titles, isNot(contains('mpv-config')));
        expect(titles, isNot(contains('Chapter 2_tmp')));
      } finally {
        Directory(root).deleteSync(recursive: true);
      }
    });

    test('Android 7–10 ask READ/WRITE storage (no "all files access" there) + legacy storage', () {
      final s = _read('lib/providers/storage_provider.dart');
      expect(s, contains('>= 30'));
      expect(s, contains('Permission.storage'));
      // background start-up scan must not force the system prompt every launch
      expect(_read('lib/modules/library/providers/local_directory_resolver.dart'),
          contains('await StorageProvider().requestPermission();'));
      expect(_read('lib/modules/more/settings/downloads/downloads_screen.dart'),
          contains('await StorageProvider().requestPermission(force: true);'));
      final m = _read('android/app/src/main/AndroidManifest.xml');
      expect(m, contains('android:requestLegacyExternalStorage="true"'));
      // background callers (Browse tab, start-up scan) ask only once ever
      expect(s, contains("'storagePromptShown'"));
      expect(s, contains('YomiPrefs.ready.timeout'));
    });

    test('logger falls back to the app folder; log screen cannot spin forever', () {
      final s = _read('lib/utils/log/logger.dart');
      expect(s, contains('getApplicationSupportDirectory'));
      expect(s, contains('sw.elapsedMilliseconds < 3000'));
      final ls = _read('lib/yomihub/ui/app_log_screen.dart');
      expect(ls, contains('timeout(const Duration(seconds: 5))'));
      expect(ls, contains('Isolate.run(() => _AppLogScreenState.parseLog(paths))'));
      expect(ls, contains('finally {'));
    });

    test('scanner reads episode folders and skips Kotatsu .bk.zip backups', () {
      final s = _read('lib/modules/library/providers/file_scanner.dart');
      expect(s, contains('episodeVideos'));
      expect(s, contains("n.endsWith('.bk.zip')"));
      expect(s, contains("lower.endsWith('_tmp')"));
      expect(s, contains("'bad-epub:\$chapterPath'"));
    });

    test('vBook runtime retries fetch once and reports the real cause', () {
      final js = _read('assets/yomihub_extensions/vbook.js');
      expect(js, contains('attempt < 2'));
      expect(js, contains('__vbLastFetchError'));
      expect(VBookBridge.runtimeRev, 3);
    });

    test('repo network warnings are per host, not per repository', () {
      expect(_read('lib/services/fetch_sources_list.dart'), contains("'repo-net:\$host'"));
    });

    test('GitHub raw mirrors still cover refs/heads URLs', () {
      final m = GhMirror.mirrorsOf(Uri.parse('https://raw.githubusercontent.com/a/b/refs/heads/main/x/plugin.json'));
      expect(m.first.toString(), 'https://cdn.jsdelivr.net/gh/a/b@main/x/plugin.json');
    });

    test('More screen merge hint no longer loads every source on the UI thread', () {
      final s = _read('lib/yomihub/extensions/merge_screen.dart');
      expect(s, contains('duplicateGroupCountAsync'));
      expect(_read('lib/yomihub/kotatsu/kotatsu_bridge.dart'), contains('anyKotatsuLikeAsync'));
    });

    test('"vBook only" label has its own line', () {
      final s = _read('lib/modules/browse/extension/widgets/extension_list_tile_widget.dart');
      expect(s, contains('_metaRow(context)'));
    });

    test('Project GitHub sheet links added (vBook, LeechText, sherpa-onnx)', () {
      final s = _read('lib/yomihub/about/github_projects.dart');
      for (final u in [
        'https://github.com/kychitoge/vbook-toolkit',
        'https://github.com/Darkrai9x/vbook-settings',
        'https://github.com/hieu45666/vbook_ext',
        'https://github.com/haipham22/LeechText',
        'https://github.com/k2-fsa/sherpa-onnx',
      ]) {
        expect(s, contains(u));
      }
    });

    // 0.5.1: "Decode & Extract" (kiritokmn1403) ported to Dart
    test('AxmlDecoder reads manifest, attributes and UTF-8 strings longer than 127 bytes', () {
      final doc = AxmlDecoder.decode(base64Decode('AwAIALgDAAABABwABAIAABEAAAAAAAAAAAEAAGAAAAAAAAAAAAAAAAoAAAA3AAAAQgAAAEwAAABaAAAAZgAAAG0AAAB1AAAAkQAAAJ0AAADKAAAA0wAAAO4AAADyAAAAAAEAAAgBAAAHB2FuZHJvaWQAKipodHRwOi8vc2NoZW1hcy5hbmRyb2lkLmNvbS9hcGsvcmVzL2FuZHJvaWQACAhtYW5pZmVzdAAHB3BhY2thZ2UACwt2ZXJzaW9uTmFtZQAJCW1ldGEtZGF0YQAEBG5hbWUABQV2YWx1ZQAZGXRhY2hpeW9taS5leHRlbnNpb24uY2xhc3MACQkuTWFuZ2FEZXgAKipldS5rYW5hZGUudGFjaGl5b21pLmV4dGVuc2lvbi5hbGwubWFuZ2FkZXgABgYxLjQuMTIAGBh0YWNoaXlvbWkuZXh0ZW5zaW9uLm5zZncAAQExAAsLYXBwbGljYXRpb24ABQVsYWJlbACAl4CXTG9vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vbwAAARAAGAAAAAEAAAD/////AAAAAAEAAAACARAATAAAAAEAAAD//////////wIAAAAUABQAAgAAAAAAAAD/////AwAAAAoAAAAIAAADCgAAAAEAAAAEAAAACwAAAAgAAAMLAAAAAgEQADgAAAABAAAA//////////8OAAAAFAAUAAEAAAAAAAAAAQAAAA8AAAAQAAAACAAAAxAAAAACARAATAAAAAEAAAD//////////wUAAAAUABQAAgAAAAAAAAABAAAABgAAAAgAAAAIAAADCAAAAAEAAAAHAAAACQAAAAgAAAMJAAAAAwEQABgAAAABAAAA//////////8FAAAAAgEQAEwAAAABAAAA//////////8FAAAAFAAUAAIAAAAAAAAAAQAAAAYAAAAMAAAACAAAAwwAAAABAAAABwAAAA0AAAAIAAADDQAAAAMBEAAYAAAAAQAAAP//////////BQAAAAMBEAAYAAAAAQAAAP//////////DgAAAAMBEAAYAAAAAQAAAP//////////AgAAAAEBEAAYAAAAAQAAAP////8AAAAAAQAAAA=='));
      final root = doc.root!;
      expect(root.name, 'manifest');
      expect(root.attr('package'), 'eu.kanade.tachiyomi.extension.all.mangadex');
      expect(root.attr('versionName'), '1.4.12');
      final app = root.descendants('application').first;
      expect(app.attr('label')!.length, 151); // the JS script cut this to 128
      final md = {for (final m in root.descendants('meta-data')) m.attr('name'): m.attr('value')};
      expect(md['tachiyomi.extension.class'], '.MangaDex');
      expect(doc.xml, contains('xmlns:android="http://schemas.android.com/apk/res/android"'));
    });

    test('ApkInspector + DexReader on a real APK (YomiHub itself, when built)', () {
      final f = [
        'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
        'build/app/outputs/flutter-apk/app-x86_64-release.apk',
      ].map(File.new).where((f) => f.existsSync()).firstOrNull;
      if (f == null) return; // not built in this checkout
      final info = ApkInspector.inspect(f.readAsBytesSync());
      expect(info.package, 'com.yomihub.app');
      expect(info.versionName, startsWith('0.'));
      expect(info.dexFiles, greaterThan(0));
      expect(info.classCount, greaterThan(100));
      expect(info.permissions, contains('android.permission.INTERNET'));
    });

    test('log screen parses in a background isolate (sendable closure), newest first', () async {
      final dir = Directory.systemTemp.createTempSync('yh051log_');
      try {
        final f = File(p.join(dir.path, 'logs.txt'))
          ..writeAsStringSync('[01/01/2026 10:00:00][WARNING] a\n  more a\n[01/01/2026 10:00:01][ERROR] b\n');
        final entries = await parseAppLogInBackground(['${f.path}.old', f.path]);
        expect(entries.length, 2);
        expect(entries.first, contains('[ERROR] b'));
        expect(entries.last, contains('more a'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('APK inspector runs in a background isolate on an APK (zip + AXML manifest)', () async {
      final manifest = base64Decode('AwAIALgDAAABABwABAIAABEAAAAAAAAAAAEAAGAAAAAAAAAAAAAAAAoAAAA3AAAAQgAAAEwAAABaAAAAZgAAAG0AAAB1AAAAkQAAAJ0AAADKAAAA0wAAAO4AAADyAAAAAAEAAAgBAAAHB2FuZHJvaWQAKipodHRwOi8vc2NoZW1hcy5hbmRyb2lkLmNvbS9hcGsvcmVzL2FuZHJvaWQACAhtYW5pZmVzdAAHB3BhY2thZ2UACwt2ZXJzaW9uTmFtZQAJCW1ldGEtZGF0YQAEBG5hbWUABQV2YWx1ZQAZGXRhY2hpeW9taS5leHRlbnNpb24uY2xhc3MACQkuTWFuZ2FEZXgAKipldS5rYW5hZGUudGFjaGl5b21pLmV4dGVuc2lvbi5hbGwubWFuZ2FkZXgABgYxLjQuMTIAGBh0YWNoaXlvbWkuZXh0ZW5zaW9uLm5zZncAAQExAAsLYXBwbGljYXRpb24ABQVsYWJlbACAl4CXTG9vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vbwAAARAAGAAAAAEAAAD/////AAAAAAEAAAACARAATAAAAAEAAAD//////////wIAAAAUABQAAgAAAAAAAAD/////AwAAAAoAAAAIAAADCgAAAAEAAAAEAAAACwAAAAgAAAMLAAAAAgEQADgAAAABAAAA//////////8OAAAAFAAUAAEAAAAAAAAAAQAAAA8AAAAQAAAACAAAAxAAAAACARAATAAAAAEAAAD//////////wUAAAAUABQAAgAAAAAAAAABAAAABgAAAAgAAAAIAAADCAAAAAEAAAAHAAAACQAAAAgAAAMJAAAAAwEQABgAAAABAAAA//////////8FAAAAAgEQAEwAAAABAAAA//////////8FAAAAFAAUAAIAAAAAAAAAAQAAAAYAAAAMAAAACAAAAwwAAAABAAAABwAAAA0AAAAIAAADDQAAAAMBEAAYAAAAAQAAAP//////////BQAAAAMBEAAYAAAAAQAAAP//////////DgAAAAMBEAAYAAAAAQAAAP//////////AgAAAAEBEAAYAAAAAQAAAP////8AAAAAAQAAAA==');
      final a = Archive()..addFile(ArchiveFile('AndroidManifest.xml', manifest.length, manifest));
      final dir = Directory.systemTemp.createTempSync('yh051apk_');
      final apkFile = File(p.join(dir.path, 'x.apk'))..writeAsBytesSync(ZipEncoder().encode(a));
      final info = await inspectApkInBackground(apkFile.path);
      dir.deleteSync(recursive: true);
      expect(info.package, 'eu.kanade.tachiyomi.extension.all.mangadex');
      expect(info.kind, contains('Mihon'));
      expect(info.extensionClasses, ['eu.kanade.tachiyomi.extension.all.mangadex.MangaDex']);
      expect(info.nsfw, isTrue);
      expect(info.libVersion, '1.4');
    });

    test('DexReader rejects non-DEX data', () {
      expect(() => DexReader.read(Uint8List.fromList(List.filled(200, 0))), throwsFormatException);
    });

    test('APK inspector strings translated in all 18 languages', () {
      final files = Directory('assets/yomihub_i18n').listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
      for (final f in files) {
        final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final k in ['Kiểm tra tệp APK tiện ích', 'Chọn tệp APK', 'Lớp nguồn', 'Tiện ích Aniyomi (Phim & Điện ảnh)']) {
          expect((m[k] as String?)?.isNotEmpty, isTrue, reason: '${f.path}: $k');
        }
      }
    });

    test('new string translated in all 18 languages', () {
      const k = 'Kho vBook không còn tệp plugin.zip của tiện ích này (HTTP 404) – tác giả kho đã xóa hoặc đổi đường dẫn.';
      final files = Directory('assets/yomihub_i18n').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files.length, 18);
      for (final f in files) {
        final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect((m[k] as String?)?.isNotEmpty, isTrue, reason: f.path);
      }
    });
  });
}
