// YomiHub 0.5.7 P2: U5 phần trình đọc (Yomikiru / Yomihon) – logic thuần + kiểm điểm nối.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/manga/reader/mixins/reader_gestures.dart';
import 'package:mangayomi/yomihub/integrations/yomi_integrations.dart';

KeyDownEvent _down(LogicalKeyboardKey k) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: k,
  timeStamp: Duration.zero,
);

String _src(String rel) {
  for (final p in [rel, 'overlay/$rel']) {
    final f = File(p);
    if (f.existsSync()) return f.readAsStringSync();
  }
  fail('Không thấy $rel');
}

void main() {
  group('Yomikiru: phím tắt mở rộng', () {
    test('extraKeyAction ánh xạ đúng', () {
      expect(YomikiruReaderEnhancer.extraKeyAction(LogicalKeyboardKey.keyD), 'next');
      expect(YomikiruReaderEnhancer.extraKeyAction(LogicalKeyboardKey.space), 'next');
      expect(YomikiruReaderEnhancer.extraKeyAction(LogicalKeyboardKey.keyA), 'prev');
      expect(YomikiruReaderEnhancer.extraKeyAction(LogicalKeyboardKey.home), 'first');
      expect(YomikiruReaderEnhancer.extraKeyAction(LogicalKeyboardKey.end), 'last');
      expect(YomikiruReaderEnhancer.extraKeyAction(LogicalKeyboardKey.keyZ), isNull);
    });

    test('mặc định tắt: phím mới bị bỏ qua, phím cũ giữ nguyên', () {
      expect(YomikiruReaderEnhancer.extraKeysEnabled, isFalse);
      var next = 0;
      final h = ReaderKeyboardHandler(onNextPage: () => next++);
      expect(h.handleKeyEvent(_down(LogicalKeyboardKey.keyD)), isFalse);
      expect(h.handleKeyEvent(_down(LogicalKeyboardKey.space)), isFalse);
      expect(h.handleKeyEvent(_down(LogicalKeyboardKey.arrowDown)), isTrue);
      expect(next, 1);
    });

    test('bật: A/D/Space/Home/End hoạt động, RTL đảo A/D', () {
      final log = <String>[];
      final h = ReaderKeyboardHandler(
        extraKeys: true,
        onNextPage: () => log.add('n'),
        onPreviousPage: () => log.add('p'),
        onFirstPage: () => log.add('f'),
        onLastPage: () => log.add('l'),
      );
      h.handleKeyEvent(_down(LogicalKeyboardKey.keyD));
      h.handleKeyEvent(_down(LogicalKeyboardKey.keyA));
      h.handleKeyEvent(_down(LogicalKeyboardKey.space));
      h.handleKeyEvent(_down(LogicalKeyboardKey.home));
      h.handleKeyEvent(_down(LogicalKeyboardKey.end));
      h.handleKeyEvent(_down(LogicalKeyboardKey.keyD), isReverseHorizontal: true);
      h.handleKeyEvent(_down(LogicalKeyboardKey.space), isReverseHorizontal: true);
      expect(log, ['n', 'p', 'n', 'f', 'l', 'p', 'n']);
      // Phím cũ (PageDown = chương kế) không bị thay đổi
      var ch = 0;
      final h2 = ReaderKeyboardHandler(extraKeys: true, onNextChapter: () => ch++);
      expect(h2.handleKeyEvent(_down(LogicalKeyboardKey.pageDown)), isTrue);
      expect(ch, 1);
    });
  });

  group('Yomihon: preset + thời gian đọc', () {
    test('mặc định không đổi giãn dòng', () {
      expect(YomihonNovelEnhancer.typographyEnabled, isFalse);
      expect(YomihonNovelEnhancer.showReadingTime, isFalse);
      expect(YomihonNovelEnhancer.effectiveLineHeight(1.5), 1.5);
    });

    test('presetLineHeight', () {
      expect(YomihonNovelEnhancer.presetLineHeight('compact'), 1.4);
      expect(YomihonNovelEnhancer.presetLineHeight('standard'), 1.65);
      expect(YomihonNovelEnhancer.presetLineHeight('relaxed'), 2.0);
    });

    test('plainTextFromHtml bóc thẻ, script, style', () {
      final t = YomihonNovelEnhancer.plainTextFromHtml(
        '<p>Xin <b>chào</b></p><script>var a=1;</script><style>p{}</style>&nbsp;thế giới',
      );
      expect(t.contains('<'), isFalse);
      expect(t.contains('var a'), isFalse);
      expect(t.contains('p{}'), isFalse);
      expect(RegExp(r'\S+').allMatches(t).length, 4);
      // Tiếng Việt có dấu không bị tách đôi khi đếm từ
      expect(YomihonNovelEnhancer.estimateReadingTime(List.filled(500, 'thế giới').join(' '), wpm: 250).inMinutes, 4);
    });

    test('ước tính + định dạng', () {
      final words = List.generate(600, (i) => 'w$i').join(' ');
      final d = YomihonNovelEnhancer.estimateReadingTime(words, wpm: 300);
      expect(d.inMinutes, 2);
      expect(YomihonNovelEnhancer.formatReadingTime(d), '2 phút');
      expect(YomihonNovelEnhancer.formatReadingTime(const Duration(minutes: 125)), '2 giờ 5 phút');
      expect(YomihonNovelEnhancer.formatReadingTime(const Duration(minutes: 60)), '1 giờ');
      expect(YomihonNovelEnhancer.formatReadingTime(Duration.zero), '< 1 phút');
    });
  });

  group('Bảng tích hợp + điểm nối', () {
    test('trạng thái khớp sự thật', () {
      String st(String p) => YomiIntegrations.integrationAuditTable
          .firstWhere((e) => e['project'] == p)['status']!;
      expect(st('Yomikiru'), startsWith('Đã tích hợp'));
      expect(st('Yomihon'), startsWith('Đã tích hợp'));
      expect(st('Nyora'), startsWith('Không tích hợp'));
      expect(st('GIF Viewer'), startsWith('Không tích hợp'));
    });

    test('mã nguồn thật sự gọi mô-đun', () {
      final rv = _src('lib/modules/manga/reader/reader_view.dart');
      expect(rv, contains('YomikiruReaderEnhancer.extraKeysEnabled'));
      expect(rv, contains('_yhJumpEdgePage'));
      final nv = _src('lib/modules/novel/novel_reader_view.dart');
      expect(nv, contains('YomihonNovelEnhancer.effectiveLineHeight'));
      expect(nv, contains('YomihonNovelEnhancer.showReadingTime'));
      expect(_src('lib/modules/more/settings/reader/reader_screen.dart'),
          contains('YomikiruSettingsSection'));
      expect(_src('lib/modules/more/settings/reader/novel_reader_screen.dart'),
          contains('YomihonSettingsSection'));
    });
  });
}
