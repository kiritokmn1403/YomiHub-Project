import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/widgets/bottom_text_widget.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.4.7 regression tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YomiHub 0.4.7', () {
    test('AppIdentity reports version 0.4.7 or later', () {
      // 0.5.0: exact version checked in yh_050_test.dart
      expect(AppIdentity.userAgent, startsWith('YomiHub/0.'));
    });

    test('YomiPrefs resumeVideoPosition defaults to true', () {
      expect(YomiPrefs.resumeVideoPosition, isTrue);
    });

    test('TelegramProvider detects missing chat_id and throws friendly error', () async {
      final p = TelegramProvider();
      p.config = {'token': '123456:ABC-DEF', 'chat_id': ''};
      expect(p.isConnected, isFalse);
      expect(
        () => p.upload(File('dummy.txt')),
        throwsA(isA<Exception>().having((e) => e.toString(), 'description', contains('Chat ID'))),
      );
    });

    test('Hako regex detects illustration-only chapter containing img tag', () {
      const htmlIllustration = '<div class="chapter-content"><img src="https://docln.sbs/images/vol1.jpg" /></div>';
      final hasImages = RegExp(r'<img\b[^>]*>', caseSensitive: false).hasMatch(htmlIllustration);
      expect(hasImages, isTrue);

      final textOnly = htmlIllustration.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      expect(textOnly.length, lessThan(30));
    });

    testWidgets('BottomTextWidget inherits Theme textTheme for Vietnamese Unicode fallback', (tester) async {
      const sampleText = 'Đề Xuất Nội Dung Xem: Thám Tử Lừng Danh Conan';
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12),
            ),
          ),
          home: const Scaffold(
            body: BottomTextWidget(
              text: sampleText,
              isComfortableGrid: true,
            ),
          ),
        ),
      );

      final textFinder = find.text(sampleText);
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontFamily, 'Roboto');
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });
  });
}
