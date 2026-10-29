import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;

import 'package:mangayomi/yomihub/ebook/ebook_converter.dart';
import 'package:mangayomi/yomihub/reader/pdf_reader_screen.dart';

/// A parsed EPUB: spine chapters in reading order with titles from the TOC.
class YomiEpub {
  final String title;
  final String author;
  final List<String> titles;
  final List<String> hrefs;
  final Archive _arc;
  final String _opfDir;
  YomiEpub._(this.title, this.author, this.titles, this.hrefs, this._arc, this._opfDir);

  static ArchiveFile? _find(Archive a, String name) {
    final n = Uri.decodeFull(name).replaceAll('\\', '/');
    for (final f in a.files) {
      if (f.name == n || f.name.toLowerCase() == n.toLowerCase()) return f;
    }
    return null;
  }

  static String _str(ArchiveFile f) => utf8.decode(f.content as List<int>, allowMalformed: true);

  static YomiEpub parse(List<int> bytes) {
    final arc = ZipDecoder().decodeBytes(bytes);
    final container = _find(arc, 'META-INF/container.xml');
    var opfPath = 'OEBPS/content.opf';
    if (container != null) {
      final c = xml.XmlDocument.parse(_str(container));
      final rf = c.descendants.whereType<xml.XmlElement>().where((e) => e.localName == 'rootfile');
      if (rf.isNotEmpty) opfPath = rf.first.getAttribute('full-path') ?? opfPath;
    }
    final opfFile = _find(arc, opfPath);
    if (opfFile == null) throw const FormatException('EPUB thiếu content.opf');
    final opf = xml.XmlDocument.parse(_str(opfFile));
    final dir = p.posix.dirname(opfPath) == '.' ? '' : '${p.posix.dirname(opfPath)}/';
    String meta(String n) {
      final e = opf.descendants.whereType<xml.XmlElement>().where((x) => x.localName == n);
      return e.isEmpty ? '' : e.first.innerText.trim();
    }

    final manifest = <String, String>{};
    String? ncx, nav;
    for (final it in opf.descendants.whereType<xml.XmlElement>().where((e) => e.localName == 'item')) {
      final id = it.getAttribute('id') ?? '';
      final href = it.getAttribute('href') ?? '';
      manifest[id] = href;
      if ((it.getAttribute('media-type') ?? '').contains('dtbncx')) ncx = href;
      if ((it.getAttribute('properties') ?? '').contains('nav')) nav = href;
    }
    final hrefs = <String>[];
    for (final ir in opf.descendants.whereType<xml.XmlElement>().where((e) => e.localName == 'itemref')) {
      final h = manifest[ir.getAttribute('idref') ?? ''];
      if (h != null && h != nav) hrefs.add(h);
    }
    // Titles from the NCX / nav TOC.
    final tocTitle = <String, String>{};
    try {
      if (ncx != null) {
        final n = _find(arc, '$dir$ncx');
        if (n != null) {
          for (final np in xml.XmlDocument.parse(_str(n)).descendants.whereType<xml.XmlElement>().where((e) => e.localName == 'navPoint')) {
            final label = np.descendants.whereType<xml.XmlElement>().where((e) => e.localName == 'text');
            final content = np.descendants.whereType<xml.XmlElement>().where((e) => e.localName == 'content');
            if (label.isNotEmpty && content.isNotEmpty) {
              final src = (content.first.getAttribute('src') ?? '').split('#').first;
              tocTitle.putIfAbsent(src, () => label.first.innerText.trim());
            }
          }
        }
      }
    } catch (_) {}
    final titles = <String>[];
    for (var i = 0; i < hrefs.length; i++) {
      titles.add(tocTitle[hrefs[i]] ?? 'Phần ${i + 1}');
    }
    return YomiEpub._(meta('title'), meta('creator'), titles, hrefs, arc, dir);
  }

  /// Chapter [i] as HTML with images inlined as data URIs.
  String chapter(int i) {
    final path = '$_opfDir${hrefs[i]}';
    final f = _find(_arc, path);
    if (f == null) return '<p>(Không tìm thấy $path)</p>';
    var html = _str(f);
    final bodyMatch = RegExp(r'<body[^>]*>([\s\S]*)</body>', caseSensitive: false).firstMatch(html);
    if (bodyMatch != null) html = bodyMatch.group(1)!;
    final base = p.posix.dirname(path);
    html = html.replaceAllMapped(
      RegExp(r'''(<img[^>]+src|<image[^>]+(?:xlink:)?href)\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      (m) {
        final src = m.group(2)!;
        if (src.startsWith('data:') || src.startsWith('http')) return m.group(0)!;
        final ip = p.posix.normalize(p.posix.join(base, src));
        final img = _find(_arc, ip);
        if (img == null) return m.group(0)!;
        final ext = p.extension(ip).toLowerCase().replaceAll('.', '');
        final mime = ext == 'jpg' ? 'jpeg' : (ext == 'svg' ? 'svg+xml' : ext);
        final tag = m.group(1)!.toLowerCase().startsWith('<image') ? '<img src' : m.group(1)!;
        return '$tag="data:image/$mime;base64,${base64Encode(img.content as List<int>)}"';
      },
    );
    return html;
  }
}

class EbookReaderScreen extends StatefulWidget {
  final String path;
  const EbookReaderScreen({super.key, required this.path});

  /// Opens EPUB / AZW3 / MOBI / FB2 / TXT / HTML (converted to EPUB first).
  static Future<void> open(BuildContext context, String path) async {
    await YomiReaderHistory.add(path);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EbookReaderScreen(path: path)));
  }

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  YomiEpub? _book;
  String? _error;
  int _index = 0;
  double _font = 18;
  int _theme = 0; // 0 sáng, 1 sepia, 2 tối
  final _scroll = ScrollController();

  static const _bg = [Color(0xFFFFFFFF), Color(0xFFF4ECD8), Color(0xFF121212)];
  static const _fg = [Color(0xFF1A1A1A), Color(0xFF5B4636), Color(0xFFD6D6D6)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      var path = widget.path;
      if (YomiEbook.isConvertible(path)) {
        final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'yomihub_ebooks'));
        path = await YomiEbook.convertFile(path, dir);
      }
      final book = YomiEpub.parse(await File(path).readAsBytes());
      final b = await YomiPdf.box();
      final pos = await YomiReaderHistory.position(widget.path);
      setState(() {
        _book = book;
        _index = pos.clamp(0, book.hrefs.isEmpty ? 0 : book.hrefs.length - 1);
        _font = (b.get('ebook_font') as num?)?.toDouble() ?? 18;
        _theme = (b.get('ebook_theme') as int?) ?? 0;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  void _go(int i) {
    if (_book == null || i < 0 || i >= _book!.hrefs.length) return;
    setState(() => _index = i);
    YomiReaderHistory.setPosition(widget.path, i);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _settings() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Text('Cỡ chữ'),
                  Expanded(
                    child: Slider(
                      min: 12,
                      max: 34,
                      divisions: 22,
                      value: _font,
                      label: _font.round().toString(),
                      onChanged: (v) {
                        set(() {});
                        setState(() => _font = v);
                        YomiPdf.box().then((b) => b.put('ebook_font', v));
                      },
                    ),
                  ),
                ]),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Sáng')),
                    ButtonSegment(value: 1, label: Text('Sepia')),
                    ButtonSegment(value: 2, label: Text('Tối')),
                  ],
                  selected: {_theme},
                  onSelectionChanged: (s) {
                    set(() {});
                    setState(() => _theme = s.first);
                    YomiPdf.box().then((b) => b.put('ebook_theme', s.first));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return Scaffold(
      backgroundColor: _bg[_theme],
      appBar: AppBar(
        title: Text(
          book == null ? p.basename(widget.path) : (book.title.isEmpty ? p.basenameWithoutExtension(widget.path) : book.title),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.text_fields), tooltip: 'Hiển thị', onPressed: _settings),
        ],
      ),
      drawer: book == null
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView.builder(
                  itemCount: book.titles.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    selected: i == _index,
                    title: Text(book.titles[i]),
                    onTap: () {
                      Navigator.pop(context);
                      _go(i);
                    },
                  ),
                ),
              ),
            ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Không mở được sách:\n$_error')))
          : book == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Html(
                        key: ValueKey('$_index-$_font-$_theme'),
                        data: book.chapter(_index),
                        style: {
                          'body': Style(
                            fontSize: FontSize(_font),
                            color: _fg[_theme],
                            lineHeight: LineHeight.number(1.35),
                          ),
                          'img': Style(width: Width(100, Unit.percent)),
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (_index > 0)
                            OutlinedButton.icon(
                              onPressed: () => _go(_index - 1),
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Trước'),
                            ),
                          const Spacer(),
                          Text('${_index + 1}/${book.hrefs.length}', style: TextStyle(color: _fg[_theme])),
                          const Spacer(),
                          if (_index < book.hrefs.length - 1)
                            FilledButton.icon(
                              onPressed: () => _go(_index + 1),
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Tiếp'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
