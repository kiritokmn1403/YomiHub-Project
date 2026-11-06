// YomiHub 0.5.3 regression tests (real code paths).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/yomihub/player/player_net.dart';
import 'package:mangayomi/yomihub/trackers/mal_export.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:path/path.dart' as p;

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('YomiHub 0.5.3', () {
    test('version / user agent', () {
      expect(AppIdentity.userAgent, 'YomiHub/0.5.3');
      expect(_read('pubspec.yaml'), contains('version: 0.5.3+45'));
    });

    test('player uses the same http proxy as the source (FapReel CDN token)', () {
      YomiVpnState.torEnabled = true;
      YomiVpnState.torRunning = true;
      YomiVpnState.torHttpPort = 8118;
      YomiVpnState.scopeAllSources = false;
      YomiVpnState.scopeSources = {920260016};
      expect(YomiPlayerNet.proxyFor(920260016), 'http://127.0.0.1:8118');
      expect(YomiPlayerNet.proxyFor(1), '');
      // SOCKS proxies cannot be used by mpv → direct
      YomiVpnState.torEnabled = false;
      YomiVpnState.proxyEnabled = true;
      YomiVpnState.proxyUrl = 'socks5://10.0.0.1:1080';
      expect(YomiPlayerNet.proxyFor(920260016), '');
      YomiVpnState.proxyEnabled = false;
      YomiVpnState.scopeAllSources = true;
      // only progressive files go through the proxy (HLS stalled via Tor)
      expect(YomiPlayerNet.isProgressive('https://cdn.x/a/b.mp4?token=1'), isTrue);
      expect(YomiPlayerNet.isProgressive('https://cdn.x/a/index.m3u8'), isFalse);
      final shorts = _read('lib/yomihub/player/yomi_shorts.dart');
      expect(shorts, contains('await YomiPlayerNet.apply(p, widget.source.id, url: v.url);'));
      expect(shorts, contains('_proxiedMedia.remove(p)'));
      expect(_read('lib/modules/anime/anime_player_view.dart'), contains('YomiPlayerNet.apply('));
    });

    test('website extensions moved to the Kiritokmn Extension Repo', () {
      // runtimes stay bundled, website extensions are gone from the APK
      for (final f in ['_common.js', 'vbook.js', 'kotatsu.js', 'ireader.js']) {
        expect(File('assets/yomihub_extensions/$f').existsSync(), isTrue, reason: f);
      }
      for (final e in BuiltinExtensions.all) {
        expect(File('assets/yomihub_extensions/${e.asset}').existsSync(), isFalse, reason: e.asset);
      }
      expect(BuiltinExtensions.repoJson,
          'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json');
      // the repo is added once, never twice
      final once = BuiltinExtensions.withRepo([Repo(name: 'x', jsonUrl: 'https://a/index.json')]);
      expect(once.length, 2);
      expect(BuiltinExtensions.withRepo(once).length, 2);
      expect(BuiltinExtensions.withRepo([Repo(jsonUrl: '${BuiltinExtensions.repoJson.toUpperCase()}/')]).length, 1);
      // ids are kept so installed copies update from the repo
      expect(BuiltinExtensions.all.map((e) => e.id).toSet().length, BuiltinExtensions.all.length);
      expect(_read('lib/main.dart'), contains('if (startupError == null) await BuiltinExtensions.install();'));
    });

    test('MyAnimeList XML export', () {
      final t = Track(
        mediaId: 21,
        syncId: 1,
        title: 'One <Piece> ]]> x',
        lastChapterRead: 1100,
        score: 85,
        status: TrackStatus.watching,
        startedReadingDate: DateTime(2024, 3, 5).millisecondsSinceEpoch,
        isManga: false,
      );
      final x = YomiMalExport.entryXml(t, 21);
      expect(x, contains('<series_animedb_id>21</series_animedb_id>'));
      expect(x, contains('<my_watched_episodes>1100</my_watched_episodes>'));
      expect(x, contains('<my_status>Watching</my_status>'));
      expect(x, contains('<my_score>9</my_score>'));
      expect(x, contains('<my_start_date>2024-03-05</my_start_date>'));
      expect(x, contains('<my_finish_date>0000-00-00</my_finish_date>'));
      expect(x, contains('<![CDATA[One <Piece> ]]]]><![CDATA[> x]]>'));
      expect(YomiMalExport.statusText(TrackStatus.planToRead, manga: true), 'Plan to Read');
      expect(YomiMalExport.statusText(TrackStatus.onHold, manga: false), 'On-Hold');
      expect(YomiMalExport.malScore(7), 7);
      final doc = YomiMalExport.document([x], manga: false);
      expect(doc, startsWith('<?xml'));
      expect(doc, contains('<user_export_type>1</user_export_type>'));
    });

    test('Backup & Sync section in Settings and More, toggles in feature screen', () {
      expect(_read('lib/router/router.dart'), contains('child: const DataAndStorage(backupSync: true)'));
      expect(_read('lib/modules/more/settings/settings_screen.dart'), contains("context.push('/backupSync')"));
      expect(_read('lib/modules/more/more_screen.dart'), contains("context.push('/backupSync')"));
      expect(_read('lib/modules/more/settings/settings_screen.dart'), isNot(contains('PlayBooksSettingTile')));
      final ft = _read('lib/yomihub/features/feature_toggle_screen.dart');
      expect(ft, contains('PlayBooksSettingTile()'));
      expect(ft, contains('BooruSettingTile()'));
      expect(_read('lib/yomihub/backup/yomi_backup_extras.dart'), contains("YomiPrefs.get<bool>('backupBooru', true)"));
    });

    test('logs 3 fixes: backup off the UI thread, EPUB list, logger marker, auto-backup path', () {
      expect(_read('lib/modules/more/data_and_storage/providers/backup.dart'), contains('_toJsonInBatches'));
      expect(_read('lib/modules/library/providers/file_scanner.dart'), contains('await YomiPrefs.ready.timeout('));
      expect(_read('lib/utils/log/logger.dart'), contains('Logger initialized'));
      expect(_read('lib/modules/more/data_and_storage/providers/auto_backup.dart'), contains('_isUsableBackupLocation'));
    });

    test('tracker sheets keep clear of the system bars', () {
      final s = _read('lib/modules/manga/detail/widgets/tracker_search_widget.dart');
      expect(s, contains('useSafeArea: false'));
      expect(s, contains('height: box.maxHeight'));
      expect(_read('lib/modules/manga/detail/widgets/tracking_menu.dart'), contains('outerBottom'));
    });

    test('new strings translated into every language', () {
      const keys = [
        'Sao Lưu & Đồng Bộ',
        'Sao lưu dữ liệu Booru App',
        'Xuất danh sách MyAnimeList (XML)',
        'Chẩn đoán Windows',
        'Mở thư mục cài đặt',
      ];
      final files = Directory('assets/yomihub_i18n').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files.length, 18);
      for (final f in files) {
        final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final k in keys) {
          expect('${d[k] ?? ''}'.trim(), isNotEmpty, reason: '${p.basename(f.path)} misses "$k"');
        }
      }
    });
  });
}
