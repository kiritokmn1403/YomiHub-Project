import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/reader/ebook_reader_screen.dart';

List<int> book({required String navigation, bool epub3 = true}) {
  final archive = Archive();
  void add(String path, String text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add('OEBPS/content.opf', '''<package><metadata><title>Test</title></metadata>
    <manifest><item id="chapter" href="text/chapter.xhtml"/>
    <item id="nav" href="navigation/${epub3 ? 'nav.xhtml' : 'toc.ncx'}"
      media-type="${epub3 ? 'application/xhtml+xml' : 'application/x-dtbncx+xml'}"
      properties="${epub3 ? 'nav' : ''}"/></manifest>
    <spine><itemref idref="chapter"/></spine></package>''');
  add('OEBPS/navigation/${epub3 ? 'nav.xhtml' : 'toc.ncx'}', navigation);
  add(
    'OEBPS/text/chapter.xhtml',
    '<html><body><p>Chapter content</p></body></html>',
  );
  return ZipEncoder().encode(archive);
}

void main() {
  testWidgets('new bookmark appears without reopening the book', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('yomi-epub-bookmark-');
      Hive.init(temp.path);
      final box = await Hive.openBox('yomihub_reader');
      final file = File('${temp.path}/test.epub');
      await file.writeAsBytes(
        book(
          epub3: false,
          navigation: '''
        <ncx><navMap><navPoint><navLabel><text>First chapter</text></navLabel>
        <content src="../text/chapter.xhtml"/></navPoint></navMap></ncx>''',
        ),
      );
      Future<void> waitFor(bool Function() ready) async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (!ready() && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        expect(ready(), isTrue);
      }

      try {
        await tester.pumpWidget(
          MaterialApp(home: EbookReaderScreen(path: file.path)),
        );
        await waitFor(() => find.text('Test').evaluate().isNotEmpty);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(tr('Thêm dấu trang')));
        await waitFor(
          () => (box.get('ebook_bm_${file.path}') as List?)?.length == 1,
        );
        // Hive updates its in-memory value before its disk write completes.
        // Wait for the same success feedback a user sees before opening the drawer.
        await waitFor(
          () => find.text(tr('Đã thêm dấu trang')).evaluate().isNotEmpty,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(tr('Mục lục')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tr('Dấu trang')));
        await tester.pumpAndSettle();
        expect(find.text('First chapter • 0%'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await box.close();
        await temp.delete(recursive: true);
      }
    });
  });

  test('EPUB 3 resolves titles relative to navigation document', () {
    final parsed = YomiEpub.parse(
      book(
        navigation: '''
      <html xmlns:epub="http://www.idpf.org/2007/ops"><body>
      <nav epub:type="landmarks"><a href="../text/chapter.xhtml">Wrong</a></nav>
      <nav epub:type="toc"><a href="../text/chapter.xhtml#heading">Chương một</a></nav>
      </body></html>''',
      ),
    );
    expect(parsed.titles, ['Chương một']);
    expect(parsed.chapter(0), contains('Chapter content'));
  });

  test('EPUB 2 resolves NCX paths and fragments', () {
    final parsed = YomiEpub.parse(
      book(
        epub3: false,
        navigation: '''
      <ncx><navMap><navPoint><navLabel><text>First chapter</text></navLabel>
      <content src="../text/chapter.xhtml#heading"/></navPoint></navMap></ncx>''',
      ),
    );
    expect(parsed.titles, ['First chapter']);
  });
}
