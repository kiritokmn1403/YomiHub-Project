import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/library/widgets/library_entry_utils.dart';
import 'package:mangayomi/modules/widgets/cover_view_widget.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_badge.dart';
import 'package:mangayomi/yomihub/ui/ui_style.dart';

String _src(String p) => File(p).readAsStringSync();

Widget _wrap(Widget c) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: 120, height: 180, child: c),
  ),
);

void main() {
  tearDown(() => YomiUi.debugOverride = null);

  group('U11 - o bia & huy hieu theo giao dien', () {
    testWidgets('EntryBadgeChip: Cu giu chip cu, Moi dung ShioriBadge', (t) async {
      YomiUi.debugOverride = YomiUiStyle.classic;
      await t.pumpWidget(_wrap(const EntryBadgeChip(label: 'Local')));
      expect(find.byType(ShioriBadge), findsNothing);
      expect(find.text('Local'), findsOneWidget);

      YomiUi.debugOverride = YomiUiStyle.modern;
      await t.pumpWidget(_wrap(const EntryBadgeChip(label: 'Local')));
      expect(find.byType(ShioriBadge), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
    });

    testWidgets('CoverViewWidget: chạm / giữ giữ nguyên ở cả hai giao diện', (t) async {
      for (final s in YomiUiStyle.values) {
        YomiUi.debugOverride = s;
        var taps = 0, longs = 0;
        await t.pumpWidget(
          _wrap(
            CoverViewWidget(
              children: const [],
              onTap: () => taps++,
              onLongPress: () => longs++,
            ),
          ),
        );
        await t.tap(find.byType(CoverViewWidget));
        await t.pump();
        expect(taps, 1, reason: '$s');
        await t.longPress(find.byType(CoverViewWidget));
        await t.pump();
        expect(longs, 1, reason: '$s');
      }
    });

    testWidgets('CoverViewWidget: Moi có bóng Shiori, Cũ không', (t) async {
      int shadowed() => t
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) {
            final d = c.decoration;
            return d is BoxDecoration && d.boxShadow != null;
          })
          .length;
      YomiUi.debugOverride = YomiUiStyle.classic;
      await t.pumpWidget(_wrap(CoverViewWidget(children: const [], onTap: () {})));
      expect(shadowed(), 0);
      YomiUi.debugOverride = YomiUiStyle.modern;
      await t.pumpWidget(_wrap(CoverViewWidget(children: const [], onTap: () {})));
      // _modern is read in initState: rebuild a fresh state
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(_wrap(CoverViewWidget(children: const [], onTap: () {})));
      expect(shadowed(), 1);
    });
  });

  group('U11 - nối mã nguồn', () {
    test('LibraryBadgeWidget có nhánh Shiori cho Mới, chip Hợp nhất giữ', () {
      final s = _src('lib/modules/library/widgets/library_entry_utils.dart');
      expect(s, contains('ShioriBadge'));
      expect(s, contains("'Hợp nhất'"));
      expect(s, contains('!isTv && YomiUi.isModern'));
    });
    test('ô "gộp thư viện" ẩn khi Mới', () {
      final s = _src(
        'lib/modules/more/settings/appearance/custom_navigation_settings.dart',
      );
      expect(s, contains('if (!YomiUi.isModern)'));
      expect(s.indexOf('if (!YomiUi.isModern)'),
          lessThan(s.indexOf('merge_library_nav_mobile')));
    });
    test('router dùng ShioriPageTransition chỉ khi Mới, không Apple/TV', () {
      final s = _src('lib/router/router.dart');
      expect(s, contains('ShioriPageTransition('));
      expect(s, contains('!isApple && !isTv && YomiUi.isModern'));
    });
    test('CoverViewWidget không đổi TV: Shiori gated bởi !isTv', () {
      final s = _src('lib/modules/widgets/cover_view_widget.dart');
      expect(s, contains('!isTv && YomiUi.isModern'));
    });
  });
}
