import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

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
  YomiEpub._(
    this.title,
    this.author,
    this.titles,
    this.hrefs,
    this._arc,
    this._opfDir,
  );

  static ArchiveFile? _find(Archive a, String name) {
    final n = Uri.decodeFull(name).replaceAll('\\', '/');
    for (final f in a.files) {
      if (f.name == n || f.name.toLowerCase() == n.toLowerCase()) return f;
    }
    return null;
  }

  static String _str(ArchiveFile f) =>
      utf8.decode(f.content as List<int>, allowMalformed: true);

  static YomiEpub parse(List<int> bytes) {
    final arc = ZipDecoder().decodeBytes(bytes);
    final container = _find(arc, 'META-INF/container.xml');
    var opfPath = 'OEBPS/content.opf';
    if (container != null) {
      final c = xml.XmlDocument.parse(_str(container));
      final rf = c.descendants.whereType<xml.XmlElement>().where(
        (e) => e.localName == 'rootfile',
      );
      if (rf.isNotEmpty)
        opfPath = rf.first.getAttribute('full-path') ?? opfPath;
    }
    final opfFile = _find(arc, opfPath);
    if (opfFile == null) throw FormatException(tr('EPUB thiếu content.opf'));
    final opf = xml.XmlDocument.parse(_str(opfFile));
    final dir = p.posix.dirname(opfPath) == '.'
        ? ''
        : '${p.posix.dirname(opfPath)}/';
    String meta(String n) {
      final e = opf.descendants.whereType<xml.XmlElement>().where(
        (x) => x.localName == n,
      );
      return e.isEmpty ? '' : e.first.innerText.trim();
    }

    final manifest = <String, String>{};
    String? ncx, nav;
    for (final it in opf.descendants.whereType<xml.XmlElement>().where(
      (e) => e.localName == 'item',
    )) {
      final id = it.getAttribute('id') ?? '';
      final href = it.getAttribute('href') ?? '';
      manifest[id] = href;
      if ((it.getAttribute('media-type') ?? '').contains('dtbncx')) ncx = href;
      if ((it.getAttribute('properties') ?? '').contains('nav')) nav = href;
    }
    final hrefs = <String>[];
    for (final ir in opf.descendants.whereType<xml.XmlElement>().where(
      (e) => e.localName == 'itemref',
    )) {
      final h = manifest[ir.getAttribute('idref') ?? ''];
      if (h != null && h != nav) hrefs.add(h);
    }
    // Titles from the NCX / nav TOC.
    final tocTitle = <String, String>{};
    String tocPath(String document, String href) => p.posix.normalize(
      p.posix.join(
        p.posix.dirname(document),
        Uri.decodeFull(href.split('#').first),
      ),
    );
    try {
      if (ncx != null) {
        final n = _find(arc, '$dir$ncx');
        if (n != null) {
          for (final np
              in xml.XmlDocument.parse(_str(n)).descendants
                  .whereType<xml.XmlElement>()
                  .where((e) => e.localName == 'navPoint')) {
            final label = np.descendants.whereType<xml.XmlElement>().where(
              (e) => e.localName == 'text',
            );
            final content = np.descendants.whereType<xml.XmlElement>().where(
              (e) => e.localName == 'content',
            );
            if (label.isNotEmpty && content.isNotEmpty) {
              final src = tocPath(ncx, content.first.getAttribute('src') ?? '');
              tocTitle.putIfAbsent(src, () => label.first.innerText.trim());
            }
          }
        }
      }
    } catch (_) {}
    // EPUB 3 uses a navigation document instead of the EPUB 2 NCX.
    if (nav != null) {
      try {
        final file = _find(arc, '$dir$nav');
        if (file != null) {
          final document = xml.XmlDocument.parse(_str(file));
          for (final section
              in document.descendants.whereType<xml.XmlElement>().where(
                (e) => e.localName == 'nav',
              )) {
            final isToc = section.attributes.any(
              (a) =>
                  a.localName == 'type' &&
                  a.value.split(RegExp(r'\s+')).contains('toc'),
            );
            if (!isToc) continue;
            for (final link
                in section.descendants.whereType<xml.XmlElement>().where(
                  (e) => e.localName == 'a',
                )) {
              final href = link.getAttribute('href');
              final title = link.innerText.trim();
              if (href != null && title.isNotEmpty) {
                tocTitle[tocPath(nav, href)] = title;
              }
            }
          }
        }
      } catch (_) {}
    }
    final titles = <String>[];
    for (var i = 0; i < hrefs.length; i++) {
      titles.add(
        tocTitle[p.posix.normalize(Uri.decodeFull(hrefs[i]))] ??
            tr('Phần {p0}', {'p0': i + 1}),
      );
    }
    return YomiEpub._(meta('title'), meta('creator'), titles, hrefs, arc, dir);
  }

  /// Chapter [i] as HTML with images inlined as data URIs.
  String chapter(int i) {
    final path = '$_opfDir${hrefs[i]}';
    final f = _find(_arc, path);
    if (f == null) return tr('<p>(Không tìm thấy {p0})</p>', {'p0': path});
    var html = _str(f);
    final bodyMatch = RegExp(
      r'<body[^>]*>([\s\S]*)</body>',
      caseSensitive: false,
    ).firstMatch(html);
    if (bodyMatch != null) html = bodyMatch.group(1)!;
    final base = p.posix.dirname(path);
    html = html.replaceAllMapped(
      RegExp(
        r'''(<img[^>]+src|<image[^>]+(?:xlink:)?href)\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
      ),
      (m) {
        final src = m.group(2)!;
        if (src.startsWith('data:') || src.startsWith('http'))
          return m.group(0)!;
        final ip = p.posix.normalize(p.posix.join(base, src));
        final img = _find(_arc, ip);
        if (img == null) return m.group(0)!;
        final ext = p.extension(ip).toLowerCase().replaceAll('.', '');
        final mime = ext == 'jpg' ? 'jpeg' : (ext == 'svg' ? 'svg+xml' : ext);
        final tag = m.group(1)!.toLowerCase().startsWith('<image')
            ? '<img src'
            : m.group(1)!;
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
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => EbookReaderScreen(path: path)));
  }

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  YomiEpub? _book;
  String? _error;
  int _index = 0;
  double _font = 18;
  double _line = 1.45;
  double _margin = 16;
  int _theme = 0; // 0 sáng, 1 sepia, 2 tối, 3 đen (AMOLED), 4 xanh dịu
  String _family = '';
  bool _justify = true;
  bool _ui = true;
  final _scroll = ScrollController();
  final Map<int, String> _plain = {};
  double _restore = 0;

  // FBReader-style colour schemes
  static const _bg = [
    Color(0xFFFFFFFF),
    Color(0xFFF4ECD8),
    Color(0xFF1E1E1E),
    Color(0xFF000000),
    Color(0xFFDCEBDD),
  ];
  static const _fg = [
    Color(0xFF1A1A1A),
    Color(0xFF5B4636),
    Color(0xFFD6D6D6),
    Color(0xFFBDBDBD),
    Color(0xFF243B28),
  ];
  static const _families = {
    '': 'Mặc định',
    'serif': 'Có chân (Serif)',
    'sans-serif': 'Không chân (Sans)',
    'monospace': 'Đơn cách (Mono)',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_savePos);
  }

  Future<void> _load() async {
    try {
      var path = widget.path;
      if (YomiEbook.isConvertible(path)) {
        final dir = Directory(
          p.join(
            (await getApplicationSupportDirectory()).path,
            'yomihub_ebooks',
          ),
        );
        path = await YomiEbook.convertFile(path, dir);
      }
      final book = YomiEpub.parse(await File(path).readAsBytes());
      final b = await YomiPdf.box();
      final pos = await YomiReaderHistory.position(widget.path);
      if (!mounted) return;
      setState(() {
        _book = book;
        _index = pos.clamp(0, book.hrefs.isEmpty ? 0 : book.hrefs.length - 1);
        _font = (b.get('ebook_font') as num?)?.toDouble() ?? 18;
        _line = (b.get('ebook_line') as num?)?.toDouble() ?? 1.45;
        _margin = (b.get('ebook_margin') as num?)?.toDouble() ?? 16;
        _theme = ((b.get('ebook_theme') as int?) ?? 0).clamp(0, _bg.length - 1);
        _family = (b.get('ebook_family') as String?) ?? '';
        _justify = (b.get('ebook_justify') as bool?) ?? true;
        _restore = (b.get('ebook_off_${widget.path}') as num?)?.toDouble() ?? 0;
      });
      _restoreOffset();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  void _restoreOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var i = 0; i < 6 && _restore > 0; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (_scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
          _scroll.jumpTo(_restore * _scroll.position.maxScrollExtent);
          break;
        }
      }
      _restore = 0;
    });
  }

  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  void _savePos() {
    if (!_scroll.hasClients ||
        DateTime.now().difference(_lastSave).inMilliseconds < 800)
      return;
    _lastSave = DateTime.now();
    final max = _scroll.position.maxScrollExtent;
    final f = max <= 0 ? 0.0 : _scroll.offset / max;
    YomiPdf.box().then((b) => b.put('ebook_off_${widget.path}', f));
    if (mounted) setState(() {});
  }

  void _go(int i, {double offset = 0}) {
    if (_book == null || i < 0 || i >= _book!.hrefs.length) return;
    setState(() => _index = i);
    YomiReaderHistory.setPosition(widget.path, i);
    YomiPdf.box().then((b) => b.put('ebook_off_${widget.path}', offset));
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _restore = offset;
    if (offset > 0) _restoreOffset();
  }

  /// One screen down/up (tap zones, volume-key style paging).
  void _page(int dir) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final h = pos.viewportDimension * 0.9;
    final target = pos.pixels + dir * h;
    if (dir > 0 && pos.pixels >= pos.maxScrollExtent - 2) {
      _go(_index + 1);
      return;
    }
    if (dir < 0 && pos.pixels <= 0) {
      if (_index > 0) _go(_index - 1, offset: 1);
      return;
    }
    _scroll.animateTo(
      target.clamp(0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _put(String k, Object v) async =>
      (await YomiPdf.box()).put(k, v);

  Future<void> _settings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Widget slider(
            String label,
            double v,
            double min,
            double max,
            int div,
            void Function(double) f,
          ) => Row(
            children: [
              SizedBox(width: 92, child: Text(label)),
              Expanded(
                child: Slider(
                  min: min,
                  max: max,
                  divisions: div,
                  value: v.clamp(min, max),
                  label: v.toStringAsFixed(v < 5 ? 2 : 0),
                  onChanged: (x) {
                    set(() {});
                    f(x);
                  },
                ),
              ),
            ],
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  slider(tr('Cỡ chữ'), _font, 12, 36, 24, (v) {
                    setState(() => _font = v);
                    _put('ebook_font', v);
                  }),
                  slider(tr('Giãn dòng'), _line, 1.0, 2.2, 12, (v) {
                    setState(() => _line = v);
                    _put('ebook_line', v);
                  }),
                  slider(tr('Lề'), _margin, 4, 48, 11, (v) {
                    setState(() => _margin = v);
                    _put('ebook_margin', v);
                  }),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var t = 0; t < _bg.length; t++)
                        ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: _bg[t],
                            radius: 8,
                          ),
                          label: Text(
                            [
                              tr('Sáng'),
                              'Sepia',
                              tr('Tối'),
                              tr('Đen'),
                              tr('Xanh dịu'),
                            ][t],
                          ),
                          selected: _theme == t,
                          onSelected: (_) {
                            set(() {});
                            setState(() => _theme = t);
                            _put('ebook_theme', t);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(width: 92, child: Text(tr('Phông chữ'))),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _family,
                          items: [
                            for (final e in _families.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(tr(e.value)),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            set(() {});
                            setState(() => _family = v);
                            _put('ebook_family', v);
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Căn đều hai bên')),
                    value: _justify,
                    onChanged: (v) {
                      set(() {});
                      setState(() => _justify = v);
                      _put('ebook_justify', v);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _plainOf(int i) => _plain.putIfAbsent(i, () {
    final h = _book!.chapter(i);
    return h
        .replaceAll(
          RegExp(r'<(script|style)[\s\S]*?</\1>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  });

  /// Search the whole book (FBReader "Tìm trong sách").
  Future<void> _search() async {
    final q = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(tr('Tìm trong sách')),
          content: TextField(
            controller: c,
            autofocus: true,
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: Text(tr('Tìm')),
            ),
          ],
        );
      },
    );
    if (q == null || q.trim().length < 2 || _book == null || !mounted) return;
    final needle = q.trim().toLowerCase();
    final hits = <(int, double, String)>[];
    for (var i = 0; i < _book!.hrefs.length && hits.length < 200; i++) {
      final t = _plainOf(i);
      final low = t.toLowerCase();
      var from = 0;
      while (hits.length < 200) {
        final k = low.indexOf(needle, from);
        if (k < 0) break;
        final a = (k - 40).clamp(0, t.length),
            b = (k + needle.length + 60).clamp(0, t.length);
        hits.add((i, t.isEmpty ? 0 : k / t.length, '…${t.substring(a, b)}…'));
        from = k + needle.length;
      }
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: hits.isEmpty
            ? Center(child: Text(tr('Không tìm thấy')))
            : ListView.builder(
                itemCount: hits.length,
                itemBuilder: (_, k) => ListTile(
                  dense: true,
                  title: Text(_book!.titles[hits[k].$1]),
                  subtitle: Text(hits[k].$3),
                  onTap: () {
                    Navigator.pop(ctx);
                    _go(hits[k].$1, offset: hits[k].$2);
                  },
                ),
              ),
      ),
    );
  }

  Future<List<Map>> _bookmarks() async =>
      ((await YomiPdf.box()).get('ebook_bm_${widget.path}') as List?)
          ?.cast<Map>() ??
      <Map>[];

  Future<void> _addBookmark() async {
    final max = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    final off = max <= 0 ? 0.0 : _scroll.offset / max;
    final list = await _bookmarks();
    list.add({
      'i': _index,
      'o': off,
      't': '${_book!.titles[_index]} • ${(off * 100).round()}%',
    });
    await _put('ebook_bm_${widget.path}', list);
    if (!mounted) return;
    // Refresh the drawer's FutureBuilder even when it was built before the
    // bookmark was added. Opening the drawer alone does not rebuild this State.
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('Đã thêm dấu trang'))));
  }

  double get _chapterProgress {
    if (!_scroll.hasClients || _scroll.position.maxScrollExtent <= 0) return 0;
    return (_scroll.offset / _scroll.position.maxScrollExtent).clamp(0, 1);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final total = book == null || book.hrefs.isEmpty
        ? 0.0
        : (_index + _chapterProgress) / book.hrefs.length;
    return Scaffold(
      backgroundColor: _bg[_theme],
      appBar: _ui
          ? AppBar(
              leading: const BackButton(),
              title: Text(
                book == null
                    ? p.basename(widget.path)
                    : (book.title.isEmpty
                          ? p.basenameWithoutExtension(widget.path)
                          : book.title),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (book != null)
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_book),
                      tooltip: tr('Mục lục'),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: tr('Tìm trong sách'),
                  onPressed: _search,
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: tr('Thêm dấu trang'),
                  onPressed: book == null ? null : _addBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  tooltip: tr('Hiển thị'),
                  onPressed: _settings,
                ),
              ],
            )
          : null,
      drawer: book == null
          ? null
          : Drawer(
              child: SafeArea(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: tr('Mục lục')),
                          Tab(text: tr('Dấu trang')),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView.builder(
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
                            FutureBuilder<List<Map>>(
                              future: _bookmarks(),
                              builder: (c, s) {
                                final l = s.data ?? const <Map>[];
                                if (l.isEmpty)
                                  return Center(
                                    child: Text(tr('Chưa có dấu trang')),
                                  );
                                return ListView.builder(
                                  itemCount: l.length,
                                  itemBuilder: (_, k) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.bookmark_outline),
                                    title: Text('${l[k]['t']}'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _go(
                                        l[k]['i'] as int,
                                        offset: (l[k]['o'] as num).toDouble(),
                                      );
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () async {
                                        final all = await _bookmarks();
                                        all.removeAt(k);
                                        await _put(
                                          'ebook_bm_${widget.path}',
                                          all,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tr('Không mở được sách:\n{p0}', {'p0': _error})),
              ),
            )
          : book == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    _margin,
                    _ui ? 8 : 28,
                    _margin,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Html(
                        key: ValueKey(
                          '$_index-$_font-$_theme-$_line-$_family-$_justify',
                        ),
                        data: book.chapter(_index),
                        style: {
                          'body': Style(
                            fontSize: FontSize(_font),
                            color: _fg[_theme],
                            lineHeight: LineHeight.number(_line),
                            fontFamily: _family.isEmpty ? null : _family,
                            textAlign: _justify
                                ? TextAlign.justify
                                : TextAlign.start,
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
                              label: Text(tr('Trước')),
                            ),
                          const Spacer(),
                          Text(
                            '${_index + 1}/${book.hrefs.length}',
                            style: TextStyle(color: _fg[_theme]),
                          ),
                          const Spacer(),
                          if (_index < book.hrefs.length - 1)
                            FilledButton.icon(
                              onPressed: () => _go(_index + 1),
                              icon: const Icon(Icons.chevron_right),
                              label: Text(tr('Tiếp')),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // FBReader tap zones: top third = back, bottom third =
                // forward, middle = show/hide the bars
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (c, box) => GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (d) {
                        final y = d.localPosition.dy / box.maxHeight;
                        if (y < 0.3) {
                          _page(-1);
                        } else if (y > 0.7) {
                          _page(1);
                        } else {
                          setState(() => _ui = !_ui);
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      color: _bg[_theme].withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              book.titles.isEmpty ? '' : book.titles[_index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _fg[_theme].withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '${(total * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _fg[_theme].withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
