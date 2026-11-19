import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.6.1 (sheet YomiHub Update: "bộ project GIF Viewer" – gifiddle,
/// GifView, gif-viewer, voidImageViewer, gif-player): trình xem ảnh động
/// GIF / WebP / APNG có điều khiển từng khung hình.
///
///  * giải mã một lần toàn bộ khung (`ui.instantiateImageCodec`), giữ thời
///    lượng gốc của từng khung;
///  * phát / dừng, khung trước / sau, kéo thanh trượt tới khung bất kỳ;
///  * tốc độ 0,25× – 4×, lặp / phát một lần, phóng to (InteractiveViewer);
///  * phím tắt (Windows / Android TV): Space phát/dừng, ←/→ khung, ↑/↓ tốc độ.
/// Ảnh rất lớn (> 600 khung) chỉ giữ 600 khung đầu để tránh hết bộ nhớ.
class GifFrames {
  final List<ui.Image> frames;
  final List<Duration> durations;
  GifFrames(this.frames, this.durations);

  int get length => frames.length;
  Duration get total => durations.fold(Duration.zero, (a, b) => a + b);

  /// Khung tối đa được giữ trong bộ nhớ.
  static const int maxFrames = 600;

  /// GIF ghi thời lượng 0 / 10 ms nghĩa là "nhanh nhất" – trình duyệt dùng 100 ms.
  static Duration normalize(Duration d) => d.inMilliseconds <= 10 ? const Duration(milliseconds: 100) : d;

  static Future<GifFrames> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final n = codec.frameCount <= 0 ? 1 : codec.frameCount.clamp(1, maxFrames);
    final frames = <ui.Image>[];
    final durs = <Duration>[];
    for (var i = 0; i < n; i++) {
      final f = await codec.getNextFrame();
      frames.add(f.image);
      durs.add(normalize(f.duration));
    }
    codec.dispose();
    return GifFrames(frames, durs);
  }

  void dispose() {
    for (final f in frames) {
      f.dispose();
    }
  }
}

/// Khung kế tiếp (lặp hoặc dừng ở cuối). null = hết (không lặp).
int? gifNextIndex(int i, int length, {required bool loop}) {
  if (length <= 1) return null;
  if (i + 1 < length) return i + 1;
  return loop ? 0 : null;
}

class GifViewerScreen extends StatefulWidget {
  /// Mở sẵn một tệp (đường dẫn) hoặc dữ liệu; cả hai null → chọn tệp.
  final String? path;
  final Uint8List? bytes;
  final String? title;
  const GifViewerScreen({super.key, this.path, this.bytes, this.title});

  @override
  State<GifViewerScreen> createState() => _GifViewerScreenState();
}

class _GifViewerScreenState extends State<GifViewerScreen> {
  GifFrames? _g;
  String? _name;
  String? _error;
  bool _loading = false;
  int _i = 0;
  bool _playing = true;
  bool _loop = true;
  double _speed = 1.0;
  Timer? _t;
  final _focus = FocusNode();

  static const _speeds = [0.25, 0.5, 1.0, 1.5, 2.0, 4.0];

  @override
  void initState() {
    super.initState();
    if (widget.bytes != null) {
      _open(widget.bytes!, widget.title ?? 'GIF');
    } else if (widget.path != null) {
      _openPath(widget.path!);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _g?.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gif', 'webp', 'png', 'apng'],
    );
    final f = res.firstOrNull; // file_picker 12: trả List<PlatformFile>
    if (f == null) return;
    try {
      await _open(await f.readAsBytes(), f.name);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _openPath(String p) async {
    try {
      await _open(await File(p).readAsBytes(), p.split(RegExp(r'[\\/]')).last);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _open(Uint8List bytes, String name) async {
    _t?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final g = await GifFrames.decode(bytes);
      if (!mounted) {
        g.dispose();
        return;
      }
      _g?.dispose();
      setState(() {
        _g = g;
        _name = name;
        _i = 0;
        _loading = false;
        _playing = g.length > 1;
      });
      _schedule();
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    AppLogger.log('[GIF Viewer] Không mở được ảnh: $e', logLevel: LogLevel.warning);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = tr('Không mở được ảnh động: {p0}', {'p0': '$e'});
      });
    }
  }

  void _schedule() {
    _t?.cancel();
    final g = _g;
    if (g == null || !_playing || g.length <= 1) return;
    final d = g.durations[_i];
    _t = Timer(Duration(microseconds: (d.inMicroseconds / _speed).round()), () {
      if (!mounted) return;
      final n = gifNextIndex(_i, g.length, loop: _loop);
      setState(() {
        if (n == null) {
          _playing = false;
        } else {
          _i = n;
        }
      });
      _schedule();
    });
  }

  void _toggle() {
    setState(() => _playing = !_playing);
    _schedule();
  }

  void _step(int d) {
    final g = _g;
    if (g == null) return;
    _t?.cancel();
    setState(() {
      _playing = false;
      _i = (_i + d) % g.length;
      if (_i < 0) _i += g.length;
    });
  }

  void _speedBy(int d) {
    final k = (_speeds.indexOf(_speed) + d).clamp(0, _speeds.length - 1);
    setState(() => _speed = _speeds[k]);
    _schedule();
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.mediaPlayPause) {
      _toggle();
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _step(1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _speedBy(1);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _speedBy(-1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _ms(Duration d) => '${d.inMilliseconds} ms';

  @override
  Widget build(BuildContext context) {
    final g = _g;
    return Scaffold(
      appBar: AppBar(
        title: Text(_name ?? 'GIF Viewer', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: tr('Mở tệp ảnh động'),
            icon: const Icon(Icons.folder_open),
            onPressed: _pick,
          ),
        ],
      ),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : g == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_error!, textAlign: TextAlign.center),
                          ),
                        FilledButton.icon(
                          icon: const Icon(Icons.gif_box_outlined),
                          label: Text(tr('Chọn ảnh GIF / WebP / APNG')),
                          onPressed: _pick,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          maxScale: 8,
                          child: Center(
                            child: RawImage(image: g.frames[_i], filterQuality: FilterQuality.medium),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text('${_i + 1}/${g.length}'),
                            Expanded(
                              child: Slider(
                                value: _i.toDouble(),
                                max: (g.length - 1).toDouble().clamp(0, double.infinity),
                                divisions: g.length > 1 ? g.length - 1 : null,
                                onChanged: g.length > 1
                                    ? (v) {
                                        _t?.cancel();
                                        setState(() {
                                          _playing = false;
                                          _i = v.round();
                                        });
                                      }
                                    : null,
                              ),
                            ),
                            Text(_ms(g.durations[_i])),
                          ],
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(tooltip: tr('Khung trước'), icon: const Icon(Icons.skip_previous), onPressed: () => _step(-1)),
                          IconButton(
                            tooltip: _playing ? tr('Tạm dừng') : tr('Phát'),
                            icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle, size: 36),
                            onPressed: g.length > 1 ? _toggle : null,
                          ),
                          IconButton(tooltip: tr('Khung sau'), icon: const Icon(Icons.skip_next), onPressed: () => _step(1)),
                          IconButton(
                            tooltip: tr('Lặp lại'),
                            icon: Icon(_loop ? Icons.repeat_on : Icons.repeat),
                            onPressed: () => setState(() => _loop = !_loop),
                          ),
                          PopupMenuButton<double>(
                            tooltip: tr('Tốc độ'),
                            initialValue: _speed,
                            onSelected: (v) {
                              setState(() => _speed = v);
                              _schedule();
                            },
                            itemBuilder: (_) => [for (final s in _speeds) PopupMenuItem(value: s, child: Text('${s}x'))],
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${_speed}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${g.frames[_i].width}×${g.frames[_i].height} • ${tr('{p0} khung', {'p0': '${g.length}'})} • ${(g.total.inMilliseconds / 1000).toStringAsFixed(1)} s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
      ),
    );
  }
}
