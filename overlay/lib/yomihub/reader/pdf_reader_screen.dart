import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/yomihub/reader/ilovepdf.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;

/// YomiHub PDF reader.
///
/// Android renders pages with the system PdfRenderer (no extra native
/// library). On Windows the file opens in the
/// built-in Edge PDF viewer / default PDF app.
class YomiPdf {
  static const channel = MethodChannel('com.yomihub/tools');
  static const _box = 'yomihub_reader';

  static Future<Box> box() async =>
      Hive.isBoxOpen(_box) ? Hive.box(_box) : await YomiHive.open(_box);

  static Future<void> open(BuildContext context, String path) async {
    await YomiReaderHistory.add(path);
    if (Platform.isWindows && webViewEnvironment != null) {
      // 0.1.7: read inside YomiHub like on Android (WebView2's PDF viewer:
      // zoom, search, page thumbnails) instead of leaving the app.
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _WinPdfScreen(path: path)),
      );
      return;
    }
    if (!Platform.isAndroid) {
      await launchUrl(Uri.file(path));
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfReaderScreen(path: path)),
    );
  }
}

/// Recently opened books (PDF + ebooks).
class YomiReaderHistory {
  static Future<List<String>> list() async {
    final b = await YomiPdf.box();
    final l = (b.get('recent') as List?)?.cast<String>() ?? <String>[];
    return l.where((e) => File(e).existsSync()).toList();
  }

  static Future<void> add(String path) async {
    final b = await YomiPdf.box();
    final l = (b.get('recent') as List?)?.cast<String>().toList() ?? <String>[];
    l.remove(path);
    l.insert(0, path);
    await b.put('recent', l.take(30).toList());
  }

  static Future<void> remove(String path) async {
    final b = await YomiPdf.box();
    final l = (b.get('recent') as List?)?.cast<String>().toList() ?? <String>[];
    l.remove(path);
    await b.put('recent', l);
  }

  static Future<int> position(String path) async =>
      ((await YomiPdf.box()).get('pos_$path') as int?) ?? 0;
  static Future<void> setPosition(String path, int v) async =>
      (await YomiPdf.box()).put('pos_$path', v);
}

class PdfReaderScreen extends StatefulWidget {
  final String path;
  const PdfReaderScreen({super.key, required this.path});
  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  int? _id;
  int _pages = 0;
  List<double> _ratio = const [];
  String? _error;
  final _cache = <int, Uint8List>{};
  final _order = <int>[];
  final _loading = <int>{};
  final _scroll = ScrollController();
  int _current = 0;
  bool _night = false;
  bool _ui = true;
  bool _horizontal = false;
  late final PageController _pageCtrl = PageController();
  int _renderWidth = 1080;

  @override
  void initState() {
    super.initState();
    _open();
    _scroll.addListener(_onScroll);
  }

  Future<void> _open() async {
    try {
      final r = await YomiPdf.channel.invokeMapMethod<String, dynamic>('pdfOpen', {'path': widget.path});
      final sizes = (r!['sizes'] as List).cast<double>();
      final ratio = <double>[];
      for (var i = 0; i + 1 < sizes.length; i += 2) {
        ratio.add(sizes[i] <= 0 ? 1.41 : sizes[i + 1] / sizes[i]);
      }
      final b = await YomiPdf.box();
      final start = await YomiReaderHistory.position(widget.path);
      setState(() {
        _id = r['id'] as int;
        _pages = r['pages'] as int;
        _ratio = ratio;
        _night = (b.get('pdf_night') as bool?) ?? false;
        _horizontal = (b.get('pdf_horizontal') as bool?) ?? false;
        _current = start.clamp(0, _pages == 0 ? 0 : _pages - 1);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _jump(_current));
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  double _offsetOf(int page, double w) {
    var y = 0.0;
    for (var i = 0; i < page && i < _ratio.length; i++) {
      y += w * _ratio[i] + 8;
    }
    return y;
  }

  void _jump(int page) {
    if (_horizontal) {
      if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(page);
    } else if (_scroll.hasClients) {
      final w = MediaQuery.of(context).size.width;
      _scroll.jumpTo(_offsetOf(page, w).clamp(0, _scroll.position.maxScrollExtent));
    }
    setState(() => _current = page);
  }

  void _onScroll() {
    final w = MediaQuery.of(context).size.width;
    var y = 0.0;
    final top = _scroll.offset + 40;
    for (var i = 0; i < _ratio.length; i++) {
      y += w * _ratio[i] + 8;
      if (y > top) {
        if (i != _current) {
          setState(() => _current = i);
          YomiReaderHistory.setPosition(widget.path, i);
        }
        break;
      }
    }
  }

  Future<void> _render(int i) async {
    if (_id == null || _cache.containsKey(i) || _loading.contains(i)) return;
    _loading.add(i);
    try {
      final bytes = await YomiPdf.channel.invokeMethod<Uint8List>(
        'pdfRender',
        {'id': _id, 'page': i, 'width': _renderWidth},
      );
      if (bytes != null && mounted) {
        setState(() {
          _cache[i] = bytes;
          _order.add(i);
          // keep memory bounded on low-end phones
          while (_order.length > 14) {
            _cache.remove(_order.removeAt(0));
          }
        });
      }
    } catch (_) {
    } finally {
      _loading.remove(i);
    }
  }

  @override
  void dispose() {
    if (_id != null) YomiPdf.channel.invokeMethod('pdfClose', {'id': _id});
    _scroll.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Widget _page(int i, double w) {
    final img = _cache[i];
    if (img == null) _render(i);
    final h = w * (i < _ratio.length ? _ratio[i] : 1.41);
    Widget child = img == null
        ? Container(
            width: w,
            height: h,
            color: _night ? Colors.black : Colors.white,
            alignment: Alignment.center,
            child: Text('${i + 1}', style: const TextStyle(color: Colors.grey)),
          )
        : Image.memory(img, width: w, height: h, fit: BoxFit.fill, gaplessPlayback: true);
    if (_night) {
      child = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    return child;
  }

  Future<void> _goto() async {
    final c = TextEditingController(text: '${_current + 1}');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Đến trang (1–{p0})', {'p0': _pages})),
        content: TextField(controller: c, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Hủy'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)), child: Text(tr('Đi'))),
        ],
      ),
    );
    if (v != null && v >= 1 && v <= _pages) _jump(v - 1);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    _renderWidth = (mq.size.width * mq.devicePixelRatio).round().clamp(600, 2400);
    final name = p.basenameWithoutExtension(widget.path);
    return Scaffold(
      backgroundColor: _night ? const Color(0xFF111111) : const Color(0xFFE0E0E0),
      appBar: _ui
          ? AppBar(
              title: Text(name, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: tr('Đổi chiều đọc'),
                  icon: Icon(_horizontal ? Icons.swap_vert : Icons.swap_horiz),
                  onPressed: () async {
                    final page = _current;
                    setState(() => _horizontal = !_horizontal);
                    (await YomiPdf.box()).put('pdf_horizontal', _horizontal);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _jump(page));
                  },
                ),
                IconButton(
                  tooltip: tr('Chế độ ban đêm'),
                  icon: Icon(_night ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  onPressed: () async {
                    setState(() => _night = !_night);
                    (await YomiPdf.box()).put('pdf_night', _night);
                  },
                ),
                IconButton(tooltip: tr('Đến trang'), icon: const Icon(Icons.numbers), onPressed: _goto),
                IconButton(
                  tooltip: tr('Công cụ iLovePDF'),
                  icon: const Icon(Icons.handyman_outlined),
                  onPressed: () => ILovePdfSheet.show(
                    context,
                    widget.path,
                    onOpen: (f) => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => PdfReaderScreen(path: f.path)),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tr('Không mở được PDF:\n{p0}', {'p0': _error}))))
          : _id == null
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTap: () => setState(() => _ui = !_ui),
                  child: Stack(
                    children: [
                      LayoutBuilder(builder: (ctx, box) {
                        final w = box.maxWidth;
                        if (_horizontal) {
                          return PageView.builder(
                            controller: _pageCtrl,
                            itemCount: _pages,
                            onPageChanged: (i) {
                              setState(() => _current = i);
                              YomiReaderHistory.setPosition(widget.path, i);
                            },
                            itemBuilder: (_, i) => InteractiveViewer(
                              maxScale: 5,
                              child: Center(child: SingleChildScrollView(child: _page(i, w))),
                            ),
                          );
                        }
                        return InteractiveViewer(
                          maxScale: 5,
                          child: ListView.builder(
                            controller: _scroll,
                            itemCount: _pages,
                            cacheExtent: mq.size.height * 2,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _page(i, w),
                            ),
                          ),
                        );
                      }),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                          child: Text('${_current + 1} / $_pages', style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}


/// Windows: PDF inside YomiHub through WebView2's built-in viewer.
class _WinPdfScreen extends StatelessWidget {
  final String path;
  const _WinPdfScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(path)),
        actions: [
          IconButton(
            tooltip: tr('Mở bằng ứng dụng khác'),
            icon: const Icon(Icons.open_in_new),
            onPressed: () => launchUrl(Uri.file(path)),
          ),
        ],
      ),
      body: InAppWebView(
        webViewEnvironment: webViewEnvironment,
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.file(path))),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
      ),
    );
  }
}
