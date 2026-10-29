import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/modules/manga/reader/u_chap_data_preload.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/reader/novel_translate.dart';
import 'package:path_provider/path_provider.dart';

/// One recognised text block of a page (image pixels).
class OcrBlock {
  final String text;
  final Rect box;
  final List<Rect> lines;
  OcrBlock(this.text, this.box, this.lines);
}

/// YomiHub 0.1.9: "Dịch ảnh" – translates the text of comic pages.
///
/// The image-translation projects of the sheet (pix2pix, CHAN…) transform
/// pictures (sketch → photo, colour…), they don't read or translate words,
/// so the pipeline follows the manga-translator approach instead:
///   1. text detection + recognition (OCR): ML Kit on Android (Latin,
///      Japanese, Chinese, Korean), Windows.Media.Ocr on Windows;
///   2. the blocks are translated (Google, same engine and cache as the
///      novel translator);
///   3. each block is painted over with the colour around it and the
///      translation is written in, fitted to the block.
/// The result is cached as a PNG per page and target language, and the
/// reader shows it instead of the original page.
class YomiImageTranslate {
  YomiImageTranslate._();
  static const _ocr = MethodChannel('yomihub/ocr');

  static bool get enabled => YomiPrefs.get<bool>('imgTranslate', false);
  static String get target => YomiPrefs.get<String>('imgTranslateTo', 'vi');
  static String get script => YomiPrefs.get<String>('imgTranslateFrom', 'auto');

  /// Bumped every time a page finishes (readers rebuild their page).
  static final version = ValueNotifier<int>(0);

  static final Map<String, String> _done = {};
  static final Map<String, Future<String?>> _running = {};
  static final Set<String> _failed = {};
  static int _active = 0;
  static final List<Completer<void>> _waiters = [];

  static bool get supported => Platform.isAndroid || Platform.isWindows;

  static String keyOf(UChapDataPreload d) {
    final src = d.pageUrl?.url ??
        d.localImagePath ??
        '${d.chapter?.id}|${d.directory?.path}|${d.index}|${d.pageIndex}';
    return md5.convert(utf8.encode('$src|$target|$script')).toString();
  }

  static Directory? _dir;
  static Future<Directory> _cache() async {
    if (_dir != null) return _dir!;
    final d = Directory('${(await getTemporaryDirectory()).path}/yomihub_imgtr');
    await d.create(recursive: true);
    return _dir = d;
  }

  /// Translated file of [d], if it is ready (no work started).
  static String? ready(UChapDataPreload d) {
    if (!enabled || d.isTransitionPage) return null;
    return _done[keyOf(d)];
  }

  /// Starts translating [d] in the background (at most 2 pages at a time).
  static void request(UChapDataPreload d, Future<Uint8List?> Function() bytes) {
    if (!enabled || !supported || d.isTransitionPage) return;
    final k = keyOf(d);
    if (_done.containsKey(k) || _running.containsKey(k) || _failed.contains(k)) return;
    _running[k] = _run(k, bytes).then((p) {
      _running.remove(k);
      if (p == '') {
        // no text on this page: nothing to do
        _failed.add(k);
        return null;
      }
      if (p != null) {
        _done[k] = p;
        d.decodedImage?.dispose();
        d.decodedImage = null;
        d.resolvedFilePath = null;
        version.value++;
      } else {
        // OCR / network error (e.g. the OCR model is still downloading):
        // allow another try in a while
        _failed.add(k);
        Future.delayed(const Duration(seconds: 30), () => _failed.remove(k));
      }
      return p;
    });
  }

  static Future<void> _slot() async {
    if (_active < 2) {
      _active++;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future;
    _active++;
  }

  static void _release() {
    _active--;
    if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
  }

  static Future<String?> _run(String k, Future<Uint8List?> Function() bytesOf) async {
    final dir = await _cache();
    final out = File('${dir.path}/$k.png');
    if (await out.exists() && await out.length() > 0) return out.path;
    await _slot();
    try {
      Uint8List? bytes;
      for (var i = 0; i < 6 && bytes == null; i++) {
        bytes = await bytesOf();
        if (bytes == null) await Future.delayed(const Duration(seconds: 2));
      }
      if (bytes == null) return null;
      final blocks = await recognize(bytes);
      final useful = blocks.where((b) => _worth(b.text)).toList();
      debugPrint('YomiImageTranslate: ${blocks.length} blocks, ${useful.length} with text');
      if (useful.isEmpty) return '';
      final translated = await YomiNovelTranslate.translateAllTo(
        useful.map((b) => b.text.replaceAll('\n', ' ')).toList(),
        target,
      );
      final png = await _paint(bytes, useful, translated);
      if (png == null) return '';
      await out.writeAsBytes(png, flush: true);
      return out.path;
    } catch (e) {
      AppLogger.logOnce('imgtr:$e', 'Dịch ảnh: $e');
      debugPrint('YomiImageTranslate: $e');
      return null;
    } finally {
      _release();
    }
  }

  static bool _worth(String t) {
    final s = t.replaceAll(RegExp(r'[\s\p{P}\p{S}\d]', unicode: true), '');
    return s.length >= 2;
  }

  // ───────────── OCR ─────────────

  static Future<List<OcrBlock>> recognize(Uint8List bytes) async {
    if (Platform.isAndroid) {
      final raw = await _ocr.invokeMethod<String>('recognize', {'bytes': bytes, 'script': script});
      return _parse(raw ?? '{}');
    }
    if (Platform.isWindows) return _windowsOcr(bytes);
    return const [];
  }

  static List<OcrBlock> _parse(String raw) {
    final j = jsonDecode(raw) as Map;
    if (j['error'] != null) throw Exception(j['error']);
    Rect r(Map m) => Rect.fromLTRB(
          (m['l'] as num).toDouble(),
          (m['t'] as num).toDouble(),
          (m['r'] as num).toDouble(),
          (m['b'] as num).toDouble(),
        );
    return [
      for (final b in (j['blocks'] as List? ?? const []))
        OcrBlock(
          '${(b as Map)['text']}',
          r(b),
          [for (final l in (b['lines'] as List? ?? const [])) if ((l as Map)['l'] != null) r(l)],
        ),
    ];
  }

  /// Windows 10/11: Windows.Media.Ocr through PowerShell (no native code
  /// in the app). Uses the OCR languages installed in Windows.
  static Future<List<OcrBlock>> _windowsOcr(Uint8List bytes) async {
    final dir = await _cache();
    final img = File('${dir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await img.writeAsBytes(bytes, flush: true);
    final lang = switch (script) {
      'ja' => 'ja',
      'zh' => 'zh-Hans',
      'ko' => 'ko',
      'en' => 'en-US',
      _ => '',
    };
    final ps = r'''
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, $type) { $t = $asTask.MakeGenericMethod($type).Invoke($null, @($op)); $t.Wait(-1) | Out-Null; $t.Result }
$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($env:YH_IMG)) ([Windows.Storage.StorageFile])
$stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
$dec = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
$bmp = Await ($dec.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
$engine = $null
if ($env:YH_LANG) { try { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new($env:YH_LANG)) } catch {} }
if (-not $engine) { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages() }
$res = Await ($engine.RecognizeAsync($bmp)) ([Windows.Media.Ocr.OcrResult])
$lines = @()
foreach ($l in $res.Lines) {
  $x1 = 1e9; $y1 = 1e9; $x2 = 0; $y2 = 0
  foreach ($w in $l.Words) { $r = $w.BoundingRect; $x1 = [Math]::Min($x1, $r.X); $y1 = [Math]::Min($y1, $r.Y); $x2 = [Math]::Max($x2, $r.X + $r.Width); $y2 = [Math]::Max($y2, $r.Y + $r.Height) }
  $lines += @{ text = $l.Text; l = $x1; t = $y1; r = $x2; b = $y2 }
}
[Console]::OutputEncoding = [Text.Encoding]::UTF8
@{ lines = $lines } | ConvertTo-Json -Depth 4 -Compress
''';
    try {
      final r = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', ps],
        environment: {'YH_IMG': img.path, 'YH_LANG': lang},
        stdoutEncoding: utf8,
      ).timeout(const Duration(seconds: 60));
      final txt = '${r.stdout}'.trim();
      if (txt.isEmpty) return const [];
      final j = jsonDecode(txt.substring(txt.indexOf('{'))) as Map;
      var raw = j['lines'];
      if (raw is Map) raw = [raw];
      final lines = [
        for (final l in (raw as List? ?? const []))
          OcrBlock(
            '${(l as Map)['text']}',
            Rect.fromLTRB((l['l'] as num).toDouble(), (l['t'] as num).toDouble(), (l['r'] as num).toDouble(), (l['b'] as num).toDouble()),
            const [],
          ),
      ];
      return _group(lines);
    } finally {
      try {
        await img.delete();
      } catch (_) {}
    }
  }

  /// Windows OCR returns lines: lines close to each other form a bubble.
  static List<OcrBlock> _group(List<OcrBlock> lines) {
    final out = <List<OcrBlock>>[];
    for (final l in lines) {
      final h = l.box.height;
      List<OcrBlock>? hit;
      for (final g in out) {
        final last = g.last.box;
        final near = (l.box.top - last.bottom).abs() < h * 1.2 &&
            l.box.left < last.right + h * 2 &&
            l.box.right > last.left - h * 2;
        if (near) {
          hit = g;
          break;
        }
      }
      hit == null ? out.add([l]) : hit.add(l);
    }
    return [
      for (final g in out)
        OcrBlock(
          g.map((e) => e.text).join(' '),
          g.map((e) => e.box).reduce((a, b) => a.expandToInclude(b)),
          g.map((e) => e.box).toList(),
        ),
    ];
  }

  // ───────────── painting ─────────────

  static Future<Uint8List?> _paint(Uint8List bytes, List<OcrBlock> blocks, List<String> texts) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final w = img.width, h = img.height;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawImage(img, Offset.zero, Paint());
    for (var i = 0; i < blocks.length && i < texts.length; i++) {
      final t = texts[i].trim();
      if (t.isEmpty) continue;
      final b = blocks[i];
      final pad = math.max(3.0, b.box.height * 0.04);
      final box = b.box.inflate(pad).intersect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
      final bg = _borderColor(rgba, w, h, box);
      final dark = bg.computeLuminance() < 0.45;
      final paint = Paint()..color = bg;
      if (b.lines.isNotEmpty) {
        for (final l in b.lines) {
          c.drawRRect(RRect.fromRectAndRadius(l.inflate(pad), Radius.circular(pad)), paint);
        }
        c.drawRect(box.deflate(pad * 0.5), paint);
      } else {
        c.drawRRect(RRect.fromRectAndRadius(box, Radius.circular(pad * 2)), paint);
      }
      _fitText(c, t, box.deflate(pad * 0.6), dark ? Colors.white : Colors.black);
    }
    final pic = rec.endRecording();
    final outImg = await pic.toImage(w, h);
    final png = await outImg.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    outImg.dispose();
    return png?.buffer.asUint8List();
  }

  /// Average colour of the pixels around [r] (the bubble's paper).
  static Color _borderColor(ByteData rgba, int w, int h, Rect r) {
    var rs = 0, gs = 0, bs = 0, n = 0;
    void add(int x, int y) {
      if (x < 0 || y < 0 || x >= w || y >= h) return;
      final o = (y * w + x) * 4;
      rs += rgba.getUint8(o);
      gs += rgba.getUint8(o + 1);
      bs += rgba.getUint8(o + 2);
      n++;
    }

    final l = r.left.floor() - 2, t = r.top.floor() - 2, rr = r.right.ceil() + 2, b = r.bottom.ceil() + 2;
    final stepX = math.max(1, (rr - l) ~/ 24), stepY = math.max(1, (b - t) ~/ 24);
    for (var x = l; x <= rr; x += stepX) {
      add(x, t);
      add(x, b);
    }
    for (var y = t; y <= b; y += stepY) {
      add(l, y);
      add(rr, y);
    }
    if (n == 0) return Colors.white;
    return Color.fromARGB(255, rs ~/ n, gs ~/ n, bs ~/ n);
  }

  static void _fitText(Canvas c, String text, Rect box, Color color) {
    var size = math.min(box.height * 0.8, math.max(10.0, box.width / 3));
    TextPainter tp;
    while (true) {
      tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: size, height: 1.15, fontWeight: FontWeight.w600),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(10, box.width));
      if ((tp.height <= box.height && tp.width <= box.width + 1) || size <= 7) break;
      size *= 0.9;
    }
    final dy = box.top + (box.height - tp.height) / 2;
    final dx = box.left + (box.width - tp.width) / 2;
    tp.paint(c, Offset(math.max(box.left, dx), math.max(box.top, dy)));
  }

  /// Clears the cached translated pages (settings changed).
  static Future<void> clear() async {
    _done.clear();
    _failed.clear();
    try {
      final d = await _cache();
      await d.delete(recursive: true);
      _dir = null;
    } catch (_) {}
    version.value++;
  }

  static const sources = {
    'auto': 'Tự nhận (Nhật/Hàn/Trung/Latin)',
    'ja': 'Tiếng Nhật',
    'ko': 'Tiếng Hàn',
    'zh': 'Tiếng Trung',
    'en': 'Tiếng Anh / chữ Latin',
  };

  /// Settings sheet opened from the reader menu.
  static Future<void> showSettings(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(tr('Dịch ảnh'), style: const TextStyle(fontWeight: FontWeight.bold))),
              SwitchListTile(
                title: Text(tr('Dịch chữ trong ảnh')),
                subtitle: Text(
                  supported
                      ? tr('Nhận dạng chữ trong trang truyện, dịch rồi viết đè lên ảnh')
                      : tr('Chỉ có trên Android và Windows 10/11'),
                ),
                value: enabled,
                onChanged: supported
                    ? (v) async {
                        await YomiPrefs.set('imgTranslate', v);
                        version.value++;
                        set(() {});
                      }
                    : null,
              ),
              ListTile(
                title: Text(tr('Ngôn ngữ trong ảnh')),
                trailing: DropdownButton<String>(
                  value: script,
                  items: [for (final e in sources.entries) DropdownMenuItem(value: e.key, child: Text(tr(e.value)))],
                  onChanged: (v) async {
                    await YomiPrefs.set('imgTranslateFrom', v);
                    await clear();
                    set(() {});
                  },
                ),
              ),
              ListTile(
                title: Text(tr('Dịch sang')),
                trailing: DropdownButton<String>(
                  value: YomiNovelTranslate.languages.containsKey(target) ? target : 'vi',
                  items: [
                    for (final e in YomiNovelTranslate.languages.entries)
                      DropdownMenuItem(value: e.key, child: Text(tr(e.value))),
                  ],
                  onChanged: (v) async {
                    await YomiPrefs.set('imgTranslateTo', v);
                    await clear();
                    set(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
