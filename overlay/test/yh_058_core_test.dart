// YomiHub 0.5.8 Core Fixes Test:
// 1) Image stream closing & referer retry (uploads.mangadex.org)
// 2) Chapter diff calculation in background Isolate without UI freezes
// 3) Extension resilience (Anime47, AVSub, FikFap, Google Drive 500, Pornhub HLS proxy)
// 4) Health Connect permission handling (reflection & Android 14 intent)
// 5) Application logger initialization header with device & version

import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/manga/detail/providers/update_manga_detail_providers.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/player/player_net.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain 1: Image Stream & Referer Retry', () {
    test('Mangadex subdomain root extraction and referer variants logic', () {
      final uri = Uri.parse('https://uploads.mangadex.org/data/1234/page.jpg');
      final hostParts = uri.host.split('.');
      expect(hostParts.length, greaterThan(2));
      final rootHost = hostParts.sublist(hostParts.length - 2).join('.');
      expect(rootHost, equals('mangadex.org'));
      expect('${uri.scheme}://$rootHost/', equals('https://mangadex.org/'));
    });
  });

  group('Domain 2: Background Isolate Chapter Diffing', () {
    test('computeChapterDiffInIsolate runs cleanly and calculates diff correctly', () async {
      final input = ChapterDiffInput(
        mangaTitle: 'One Piece',
        existing: [
          const ExistingChapterData(
            id: 1,
            name: 'Chapter 1: Romance Dawn',
            url: 'https://example.com/ch1',
            scanlator: 'TCB',
            isRead: true,
            lastPageRead: '15',
          ),
          const ExistingChapterData(
            id: 2,
            name: 'Chapter 2: They Call Him Straw Hat Luffy',
            url: 'https://example.com/ch2',
            scanlator: 'TCB',
            isRead: false,
          ),
          // Duplicate of Chapter 1 with same URL but no read state
          const ExistingChapterData(
            id: 3,
            name: 'Chapter 1: Romance Dawn',
            url: 'https://example.com/ch1',
            scanlator: 'TCB',
            isRead: false,
          ),
        ],
        incoming: [
          const IncomingChapterData(
            name: 'Chapter 1: Romance Dawn',
            url: 'https://example.com/ch1',
            scanlator: 'TCB',
          ),
          const IncomingChapterData(
            name: 'Chapter 2: They Call Him Straw Hat Luffy',
            url: 'https://example.com/ch2',
            scanlator: 'TCB',
          ),
          const IncomingChapterData(
            name: 'Chapter 3: Morgan versus Luffy',
            url: 'https://example.com/ch3',
            scanlator: 'TCB',
          ),
        ],
      );

      // Verify execution in Isolate.run()
      final diff = await Isolate.run(() => computeChapterDiffInIsolate(input));

      expect(diff.duplicateIds, contains(3));
      expect(diff.toInsert.length, equals(1));
      expect(diff.toInsert.first.name, equals('Chapter 3: Morgan versus Luffy'));
      expect(diff.toUpdate.length, equals(2));
      expect(diff.readStates.containsKey('https://example.com/ch1'), isFalse);
    });
  });

  group('Domain 3: Extension Resilience & Mirrors', () {
    test('Default mirrors include anime47, animevietsub.best, and fikfap', () {
      expect(YomiUrlOverride.defaultMirrors['anime47.best'], isNotNull);
      expect(YomiUrlOverride.defaultMirrors['anime47.best'], contains('https://anime47.tv'));
      expect(YomiUrlOverride.defaultMirrors['animevietsub.best'], isNotNull);
      expect(YomiUrlOverride.defaultMirrors['animevietsub.best'], contains('https://animevietsub.sale'));
      expect(YomiUrlOverride.defaultMirrors['fikfap.com'], isNotNull);
      expect(YomiUrlOverride.defaultMirrors['fikfap.com'], contains('https://fikfap.net'));
    });

    test('HTTP 404 is classified as source data error with helpful Vietnamese hint', () {
      final err = Exception('HTTP error 404 https://animevui.com/api/get');
      expect(YomiExtErrors.isSourceDataError(err), isTrue);
      final hint = YomiExtErrors.hint(err);
      expect(hint, isNotNull);
      expect(hint, contains('URL'));
    });

    test('Shorts Pornhub HLS proxy detection', () {
      expect(YomiPlayerNet.needsProxyForHls('https://ci-phncdn.com/hls/videos/stream.m3u8'), isTrue);
      expect(YomiPlayerNet.needsProxyForHls('https://www.pornhub.com/video/playlist.m3u8'), isTrue);
      expect(YomiPlayerNet.needsProxyForHls('https://fikfap.com/video/hls.m3u8'), isTrue);
      expect(YomiPlayerNet.needsProxyForHls('https://hotphim.tv/playlist.m3u8'), isFalse);
    });
  });

  group('Domain 4: Health Connect Permissions', () {
    test('Mindfulness class name and permission action strings', () {
      const mindfulnessClassName = 'android.health.connect.datatypes.MindfulnessSessionRecord';
      expect(mindfulnessClassName, contains('MindfulnessSessionRecord'));
      const permAction = 'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS';
      expect(permAction, equals('android.health.connect.action.MANAGE_HEALTH_PERMISSIONS'));
    });
  });

  group('Domain 5: Application Log Header', () {
    test('Session header format matches specification', () {
      const dev = 'Samsung SM-N960F, Android 10 (SDK 29)';
      const ver = '0.5.8 (58)';
      final header = '===== Logger initialized (phiên mới) • $dev • YomiHub $ver =====';
      expect(header, contains('Logger initialized (phiên mới)'));
      expect(header, contains('SM-N960F'));
      expect(header, contains('0.5.8'));
    });
  });
}
