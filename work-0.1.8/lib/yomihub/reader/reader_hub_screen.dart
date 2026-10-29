import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:mangayomi/yomihub/ebook/ebook_converter.dart';
import 'package:mangayomi/yomihub/reader/ebook_reader_screen.dart';
import 'package:mangayomi/yomihub/reader/ilovepdf.dart';
import 'package:mangayomi/yomihub/reader/pdf_reader_screen.dart';

/// More > "Ebook & PDF": open books from the device without adding them to
/// the library (Calibre / Sigil-style formats are converted to EPUB).
class ReaderHubScreen extends StatefulWidget {
  const ReaderHubScreen({super.key});
  @override
  State<ReaderHubScreen> createState() => _ReaderHubScreenState();
}

class _ReaderHubScreenState extends State<ReaderHubScreen> {
  List<String> _recent = [];

  static const ebookExt = ['epub', 'azw3', 'azw', 'mobi', 'kf8', 'prc', 'fb2', 'zip', 'txt', 'html', 'htm', 'xhtml'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await YomiReaderHistory.list();
    if (mounted) setState(() => _recent = r);
  }

  Future<void> _openPath(String path) async {
    if (path.toLowerCase().endsWith('.pdf')) {
      await YomiPdf.open(context, path);
    } else if (YomiEbook.isSupported(path)) {
      await EbookReaderScreen.open(context, path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Định dạng chưa hỗ trợ')));
    }
    _load();
  }

  Future<void> _pick(List<String> ext) async {
    // Android pickers grey out unknown types (.azw3, .fb2…), so ebooks use
    // the "any file" picker and are checked here.
    final f = ext.length == 1
        ? await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ext)
        : await FilePicker.pickFile(type: FileType.any);
    final path = f?.path;
    if (path != null && mounted) await _openPath(path);
  }

  IconData _icon(String f) => f.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.menu_book_outlined;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ebook & PDF')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Mở tệp PDF'),
            subtitle: Text(Platform.isAndroid
                ? 'Cuộn dọc / lật trang, phóng to, chế độ ban đêm, nhớ trang đang đọc'
                : 'Mở bằng trình xem PDF của Windows (Edge)'),
            onTap: () => _pick(['pdf']),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Mở Ebook'),
            subtitle: const Text('EPUB, AZW3, MOBI, AZW, PRC, FB2, TXT, HTML'),
            onTap: () => _pick(ebookExt),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.info_outline, size: 20),
            title: Text(
              'Muốn lưu sách vào Thư viện Novel (đồng bộ, sao lưu)? Vào Thư viện > Novel > ⋮ > Nhập.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (_recent.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Đọc gần đây', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final f in _recent)
              ListTile(
                leading: Icon(_icon(f)),
                title: Text(p.basenameWithoutExtension(f), maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(p.extension(f).replaceAll('.', '').toUpperCase()),
                onTap: () => _openPath(f),
                onLongPress: f.toLowerCase().endsWith('.pdf')
                    ? () => ILovePdfSheet.show(context, f, onOpen: (o) => _openPath(o.path))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await YomiReaderHistory.remove(f);
                    _load();
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
