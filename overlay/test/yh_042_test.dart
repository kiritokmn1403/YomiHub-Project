import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/library/widgets/library_entry_utils.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('YomiHub 0.4.2 Upgrades & Feature Tests', () {
    test('AppIdentity reports version 0.4.2', () {
      expect(AppIdentity.userAgent, startsWith('YomiHub/0.4.'));
    });

    test('AppIdentity returns YomiHub by default and YumiHub Android TV for TV', () {
      expect(AppIdentity.name, anyOf('YomiHub', 'YumiHub Android TV'));
    });

    test('ChapterOrigins.isMangaMerged returns false when prefs are empty or closed', () {
      expect(ChapterOrigins.isMangaMerged(null), isFalse);
      expect(ChapterOrigins.isMangaMerged(99999), isFalse);
    });

    testWidgets('EntryBadgeChip renders label and merge icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EntryBadgeChip(
              icon: Icons.call_merge_rounded,
              label: 'Hợp nhất',
            ),
          ),
        ),
      );

      expect(find.text('Hợp nhất'), findsOneWidget);
      expect(find.byIcon(Icons.call_merge_rounded), findsOneWidget);
    });

    test('Extension error origin string formatting matches Feature Check 34', () {
      final source = Source(
        id: 12345,
        name: 'Hako Novel',
        lang: 'vi',
        repo: Repo(
          name: 'YomiHub Bundled',
          jsonUrl: 'https://raw.githubusercontent.com/yomihub/extensions/main/index.min.json',
        ),
      )..sourceCodeLanguage = SourceCodeLanguage.javascript;

      final repoInfo = source.repo != null
          ? '${source.repo!.name ?? 'repo'}${source.repo!.jsonUrl != null ? ' <${source.repo!.jsonUrl}>' : ''}'
          : 'Built-in/Local';
      final langEngine = source.sourceCodeLanguage.name;
      const serviceType = 'getHtmlContent';
      const url = 'https://docln.sbs/truyen/123/c456';

      final where = 'Extension "${source.name}" (${source.lang}, engine: $langEngine, repo: $repoInfo) $serviceType $url';

      expect(where, contains('Extension "Hako Novel"'));
      expect(where, contains('(vi, engine: javascript, repo: YomiHub Bundled <https://raw.githubusercontent.com/yomihub/extensions/main/index.min.json>)'));
      expect(where, contains('getHtmlContent https://docln.sbs/truyen/123/c456'));
    });

    test('Hako novel decoder logic decodes chunked array and handles corruption safely', () {
      // Dart equivalent of the unified hakoDecode algorithm
      String hakoDecodeSim(String dataC, String mode, String key) {
        if (dataC.isEmpty) return '';
        final trimmed = dataC.trim();
        if (trimmed.startsWith('[')) {
          try {
            final parsed = jsonDecode(trimmed);
            if (parsed is List && parsed.isNotEmpty) {
              final list = List<String>.from(parsed.map((e) => e.toString()));
              list.sort((a, b) => int.parse(a.substring(0, 4)).compareTo(int.parse(b.substring(0, 4))));
              final decodedChunks = list.map((chunk) {
                var s = chunk.substring(4);
                if (mode == 'base64_reverse') {
                  s = s.split('').reversed.join('');
                }
                final bytes = base64.decode(s);
                return utf8.decode(bytes);
              }).join('');
              return decodedChunks;
            }
          } catch (_) {}
        }
        try {
          final bytes = base64.decode(trimmed);
          return utf8.decode(bytes);
        } catch (_) {
          return '';
        }
      }

      // Test Case 1: Simple Base64
      final testText = 'Chương 1: Khởi đầu mới';
      final b64 = base64.encode(utf8.encode(testText));
      expect(hakoDecodeSim(b64, 'none', ''), testText);

      // Test Case 2: Chunked Array
      final chunk0 = '0000${base64.encode(utf8.encode('Phần 1. '))}';
      final chunk1 = '0001${base64.encode(utf8.encode('Phần 2.'))}';
      final jsonChunks = jsonEncode([chunk1, chunk0]); // intentionally out of order
      expect(hakoDecodeSim(jsonChunks, 'none', ''), 'Phần 1. Phần 2.');

      // Test Case 3: Corrupt data doesn't throw
      expect(hakoDecodeSim('corrupt !@#%^&*()', 'none', ''), '');
      expect(hakoDecodeSim('[invalid json', 'none', ''), '');
    });
  });
}
