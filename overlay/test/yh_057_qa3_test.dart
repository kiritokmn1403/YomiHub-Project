// YomiHub 0.5.7 QA3: reader image timeout/error decision + nav label layout.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/utils/image_load_timeout.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_nav_bar.dart';

String _read(String p) => File(p).readAsStringSync();

void main() {
  group('image load timeout', () {
    test('a request that never answers fails with ImageLoadTimeoutException', () async {
      final never = Completer<int>().future;
      await expectLater(
        withImageTimeout(never,
            host: 'api.mangadex.org', timeout: const Duration(milliseconds: 40)),
        throwsA(isA<ImageLoadTimeoutException>()
            .having((e) => e.host, 'host', 'api.mangadex.org')),
      );
    });

    test('a fast request is not affected', () async {
      expect(
        await withImageTimeout(Future.value(7),
            host: 'h', timeout: const Duration(milliseconds: 40)),
        7,
      );
    });

    test('default bound is 30 s and the widget backstop is longer', () {
      expect(kImageLoadTimeout, const Duration(seconds: 30));
      expect(kImageLoadBackstop > kImageLoadTimeout, isTrue);
    });

    test('classification', () {
      expect(isImageLoadTimeout(ImageLoadTimeoutException('h', kImageLoadTimeout)), isTrue);
      expect(isImageLoadTimeout(TimeoutException('x')), isTrue);
      expect(isImageLoadTimeout(StateError('boom')), isFalse);
      expect(
          classifyImageLoadError(
              const SocketException("Failed host lookup: 'uploads.mangadex.org'")),
          ImageLoadFailure.dns);
      expect(classifyImageLoadError(const HandshakeException('CERTIFICATE_VERIFY_FAILED')),
          ImageLoadFailure.tls);
      expect(classifyImageLoadError('HTTP 403'), ImageLoadFailure.http);
      expect(classifyImageLoadError(StateError('x')), ImageLoadFailure.other);
    });

    test('reason text names the host and the limit', () {
      final r = describeImageLoadError(StateError(
          'Failed to load https://uploads.mangadex.org/data/a/1.png. Cause: ImageLoadTimeout: uploads.mangadex.org không phản hồi sau 30s (connect)'));
      expect(r, contains('uploads.mangadex.org'));
      expect(r, contains('30'));
      final dns = describeImageLoadError(
          const SocketException("Failed host lookup: 'api.mangadex.org'"),
          host: 'api.mangadex.org');
      expect(dns, contains('api.mangadex.org'));
      expect(dns, contains('DNS'));
    });

    test('imageHostOf', () {
      expect(imageHostOf('Failed to load https://a.b.c/x/y.png. Cause'), 'a.b.c');
      expect(imageHostOf('no url'), '');
    });

    test('warning logged once per host per minute, summarised after', () {
      final out = <String>[];
      final log = ImageFailWarnLog(emit: out.add, useTimer: false);
      final t0 = DateTime(2026, 11, 15, 9, 0, 0);
      for (var i = 0; i < 5; i++) {
        log.record('api.mangadex.org', StateError('x'), now: t0.add(Duration(seconds: i)));
      }
      log.record('uploads.mangadex.org', StateError('x'), now: t0);
      expect(out.length, 2, reason: 'one per host');
      expect(out[0], contains('api.mangadex.org'));
      // next window: previous burst summarised, then a fresh line.
      log.record('api.mangadex.org', StateError('x'), now: t0.add(const Duration(seconds: 61)));
      expect(out.length, 4);
      expect(out[2], contains('thêm 4 lần'));
    });
  });

  group('wiring (source)', () {
    final prov = _read('lib/modules/widgets/custom_extended_image_provider.dart');
    test('provider bounds connect and receive and logs a warning', () {
      expect(prov, contains('withImageTimeout('));
      expect(prov, contains('response.stream.timeout('));
      expect(prov, contains('kImageLoadTimeout'));
      expect(prov, contains('LogLevel.warning'));
      expect(prov, contains('isImageLoadTimeout(lastError)'));
    });
    test('readers show the reason and have a backstop', () {
      for (final f in [
        'lib/modules/manga/reader/subsampling_scale_image_view/src/subsampling_scale_image_view.dart',
        'lib/modules/manga/reader/subsampling_scale_image_view/src/min_subsampling_image_view.dart',
      ]) {
        final s = _read(f);
        expect(s, contains('kImageLoadBackstop'), reason: f);
        expect(s, contains('describeImageLoadError('), reason: f);
      }
      expect(_read('lib/modules/manga/reader/widgets/reader_page_content.dart'),
          contains('state.errorMessage'));
      expect(_read('lib/modules/manga/reader/widgets/double_page_view.dart'),
          contains('state.errorMessage'));
    });
    test('Play Books uses the short label with the long one as tooltip', () {
      final pb = _read('lib/yomihub/playbooks/play_books_screen.dart');
      expect(pb, contains("label: tr('Yêu thích')"));
      expect(pb, contains("tooltip: tr('Danh sách yêu thích')"));
    });
  });

  testWidgets('Shiori nav labels shrink instead of truncating on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(720, 1280); // 360 dp wide
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final labels = ['Thư Viện', 'Hoạt động', 'Duyệt', 'Lịch sử', 'Thêm'];
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      home: Scaffold(
        bottomNavigationBar: ShioriFloatingNavBar(
          selectedIndex: 1,
          onDestinationSelected: (_) {},
          destinations: [
            for (final l in labels)
              ShioriNavDestination(icon: const Icon(Icons.circle), label: l),
          ],
        ),
      ),
    )));
    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text('Hoạt động'));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(text.softWrap, isFalse);
    // the label (after FittedBox scaling) fits inside its cell.
    final box = tester.getRect(find.text('Hoạt động'));
    final cell = tester.getRect(find.byKey(const ValueKey('shioriNav_Hoạt động')));
    expect(box.width, lessThanOrEqualTo(cell.width));
  });
}
