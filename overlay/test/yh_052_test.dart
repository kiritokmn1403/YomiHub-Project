// YomiHub 0.5.2 regression tests (real code paths).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup_format.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/vbook/vbook_bridge.dart';
import 'package:mangayomi/yomihub/win/win_diag.dart';
import 'package:mangayomi/services/crash_report.dart';
import 'package:path/path.dart' as p;

String _read(String path) => File(path).readAsStringSync();

// 0.5.3: the website extensions moved to the Kiritokmn Extension Repo
// (sources-yomihub/); older checkouts still have them in assets/.
String _extSource(String f) {
  for (final d in const [
    'assets/yomihub_extensions',
    r'D:\A.I Project\A.I Project - Extension Repo\Kiritokmn - Extension Repo\sources-yomihub',
  ]) {
    final x = File('$d/$f');
    if (x.existsSync()) return x.readAsStringSync();
  }
  throw StateError('extension source $f not found');
}

void main() {
  group('YomiHub 0.5.2', () {
    test('version / user agent', () {
      // 0.5.3: still a 0.5.x build (exact version checked in yh_053_test)
      expect(AppIdentity.userAgent, startsWith('YomiHub/0.5.'));
      expect(_read('pubspec.yaml'), contains('version: 0.5.'));
    });

    test('tachibk: platform gunzip, cached per file', () async {
      final dir = Directory.systemTemp.createTempSync('yh052');
      final f = File(p.join(dir.path, 'x.tachibk'));
      final payload = List<int>.generate(200000, (i) => i % 251);
      f.writeAsBytesSync(gzip.encode(payload));
      expect(yhGunzip(f.readAsBytesSync()), payload);
      clearTachiBkCache();
      await warmTachiBk(f.path); // background isolate
      final a = tachiBkBytes(f.path);
      final b = tachiBkBytes(f.path);
      expect(identical(a, b), isTrue, reason: 'second read must come from the cache');
      expect(a, payload);
      clearTachiBkCache();
      dir.deleteSync(recursive: true);
    });

    test('merge restore: extensions carried by a backup', () {
      final backup = <String, dynamic>{
        'extensions': [
          {'name': 'FoxTruyen', 'lang': 'vi', 'isAdded': true, 'sourceCode': 'x', 'itemType': 0},
          {'name': 'MangaDex', 'lang': 'ro', 'isAdded': false, 'sourceCode': ''},
          {'name': 'NoCode', 'lang': 'vi', 'isAdded': true, 'sourceCode': ''},
        ],
        'yomihub': {
          'extensions': [
            {'name': 'Anime47', 'lang': 'vi', 'isAdded': true, 'sourceCode': 'y', 'itemType': 1},
          ],
        },
      };
      final names = backupInstalledExtensions(backup).map((e) => e['name']).toList();
      expect(names, ['FoxTruyen', 'Anime47']);
    });

    test('hint: host glued to an id (old extension data)', () {
      final e = Exception('Unable to resolve host "mimihentai.moe24403" (system DNS and DNS-over-HTTPS)');
      expect(YomiExtErrors.hint(e), contains('phiên bản cũ'));
      final dns = Exception('Unable to resolve host "api.example.com"');
      expect(YomiExtErrors.hint(dns), contains('Tên miền không phân giải'));
    });

    test('vBook runtime revision bumped (empty search = empty page)', () {
      expect(VBookBridge.runtimeRev, greaterThanOrEqualTo(4));
      expect(_read('assets/yomihub_extensions/vbook.js'), contains('trả về kết quả rỗng") >= 0) return { list: [], hasNextPage: false }'));
    });

    test('bundled extensions: FikFap / Anime47 links survive a refresh', () {
      final ff = _extSource('fikfap.js');
      expect(ff, contains('postId(url)'));
      expect(ff, isNot(contains('const o = JSON.parse(url);')));
      final a47 = _extSource('anime47.js');
      expect(a47, contains('async resolveId(url)'));
      expect(a47, contains('/m\${id}.html'));
    });

    test('Windows diagnostics name the features a missing file disables', () {
      final dir = Directory.systemTemp.createTempSync('yh052w');
      final miss = WinDiag.checkFiles(dir.path).join('\n');
      expect(miss, contains('xray.exe'));
      expect(miss, contains('tor.exe'));
      expect(miss, contains('bridge'));
      expect(miss, contains('libmpv-2.dll'));
      dir.deleteSync(recursive: true);
    });

    test('packaging: Setup.exe uses the full package, VC++ runtime bundled', () {
      final b = File('../../../A.I Project/A.I Project - YomiHub Project/YomiHub-Project/build_052.ps1');
      if (!b.existsSync()) return; // only on the build PC
      final s = b.readAsStringSync();
      expect(s, contains('vcruntime140_1.dll'));
      expect(s, contains('windows-x64-full.zip'));
    });

    test('source faults are logged as warnings, backup results always', () {
      final r = CrashReport(
        time: DateTime(2026, 11, 6),
        source: 'updateMangaDetail',
        error: 'Error: Anime47 cần đăng nhập: bấm nút Webview',
      );
      expect(isReportableFailure(r), isFalse);
      expect(_read('lib/services/crash_report.dart'),
          contains('isReportableFailure(report) ? LogLevel.error : LogLevel.warning'));
      expect(_read('lib/utils/log/logger.dart'), contains('!always && !verbose'));
      final fmt = _read('lib/modules/more/data_and_storage/providers/backup_format.dart');
      expect(fmt, contains('_chapterUrlsFor('));
      expect(fmt, isNot(contains('.getAllByMangaId(existing.id)')));
      expect(_read('lib/yomihub/win/win_diag.dart'), contains('always: true'));
    });

    test('merge restores add missing chapters to series already present', () {
      final r = _read('lib/modules/more/data_and_storage/providers/restore.dart');
      expect(r, isNot(contains('if (!newMangaIds.contains(newMangaId)) continue;')));
      expect(r, contains('preChapterUrls: preChapterUrls'));
      expect(r, contains('if (!changed && freshChapters.isEmpty) continue;'));
    });

    test('WARP: handshake checked, other UDP ports tried, dead tunnel taken down', () {
      final v = _read('lib/yomihub/vpn/vpn_service.dart');
      expect(v, contains('<int?>{saved, null, 500, 4500, 1701, 854}'));
      expect(v, contains('cdn-cgi/trace'));
      expect(v, contains("await _channel.invokeMethod('warpDown');"));
    });

    test('new strings translated into every language', () {
      final keys = _read('test/yh_052_strings.txt')
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      final dir = Directory('assets/yomihub_i18n');
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files.length, greaterThanOrEqualTo(18));
      for (final f in files) {
        final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final k in keys) {
          expect(d.containsKey(k), isTrue, reason: '${p.basename(f.path)} misses "$k"');
          expect('${d[k]}'.trim(), isNotEmpty);
        }
      }
    });
  });
}
