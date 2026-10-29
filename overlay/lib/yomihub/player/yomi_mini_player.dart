import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mangayomi/router/router.dart' show navigatorKey;
import 'package:mangayomi/modules/anime/anime_player_view.dart';

/// YomiHub 0.1.5: floating mini player ("cửa sổ nổi") – Picture-in-Picture
/// for Android 7.x (the system PiP API only exists from Android 8.0, see the
/// Android 6.0/7.0 notes and the floating-window approach in the jianshu /
/// aliyun articles) and an optional in-app PiP on every platform.
///
/// The player screen hands its running [Player] over instead of disposing
/// it, then closes; the mini window keeps playing on top of the whole app
/// (library, browse, detail pages stay usable), can be dragged to any
/// corner, paused, expanded back to full screen or closed.
class YomiMiniPlayer {
  YomiMiniPlayer._();

  /// The floating window lives in its own layer above the router (see
  /// [YomiMiniPlayerLayer] in main.dart), so route changes never cover it.
  static final current = ValueNotifier<(VideoController, String)?>(null);
  static Player? _player;
  static int? _episodeId;

  static bool get active => current.value != null;

  /// Position to resume at when the full player reopens [episodeId].
  static (int, Duration)? _resume;

  static Duration? takeResume(int? episodeId) {
    final r = _resume;
    if (r == null || r.$1 != episodeId) return null;
    _resume = null;
    return r.$2;
  }

  /// Takes ownership of [player]; the caller must not dispose it.
  static void show({
    required Player player,
    required VideoController controller,
    required int episodeId,
    required String title,
  }) {
    final old = _player;
    if (old != null && old != player) unawaited(_dispose(old));
    _player = player;
    _episodeId = episodeId;
    current.value = (controller, title);
  }

  static Future<void> expand() async {
    final p = _player, id = _episodeId;
    if (p == null || id == null) return close();
    _resume = (id, p.state.position);
    // Don't wait for the native player teardown (it can take a while or
    // never complete on some devices); give it a moment, then reopen.
    unawaited(close());
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final ctx = navigatorKey.currentContext;
    debugPrint('[YomiMiniPlayer] expand episode $id at ${_resume?.$2} ctx=${ctx != null}');
    if (ctx == null || !ctx.mounted) return;
    try {
      unawaited(GoRouter.of(ctx).push('/animePlayerView', extra: id));
    } catch (e) {
      debugPrint('[YomiMiniPlayer] router push failed ($e), using Navigator');
      unawaited(
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => AnimePlayerView(episodeId: id)),
        ),
      );
    }
  }

  static Future<void> close() async {
    current.value = null;
    final p = _player;
    _player = null;
    _episodeId = null;
    if (p != null) await _dispose(p);
  }

  static Future<void> _dispose(Player p) async {
    try {
      await p.pause();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      await p.dispose();
    } catch (_) {}
  }

  static Player? get player => _player;
}

/// Put above the app content (MaterialApp.builder): draws the mini window.
class YomiMiniPlayerLayer extends StatelessWidget {
  final Widget child;
  const YomiMiniPlayerLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<(VideoController, String)?>(
      valueListenable: YomiMiniPlayer.current,
      builder: (context, v, _) => v == null
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                child,
                _MiniWindow(key: ValueKey(v.$1), controller: v.$1, title: v.$2),
              ],
            ),
    );
  }
}

class _MiniWindow extends StatefulWidget {
  final VideoController controller;
  final String title;
  const _MiniWindow({super.key, required this.controller, required this.title});

  @override
  State<_MiniWindow> createState() => _MiniWindowState();
}

class _MiniWindowState extends State<_MiniWindow> {
  Offset? _pos;
  bool _controls = true;
  Timer? _hide;
  double _w = 256;

  @override
  void initState() {
    super.initState();
    _autoHide();
  }

  void _autoHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final h = _w * 9 / 16;
    final pos = _pos ??
        Offset(size.width - _w - 12, size.height - h - pad.bottom - 96);
    final player = YomiMiniPlayer.player;
    return Positioned(
      left: pos.dx.clamp(0, (size.width - _w).clamp(0, double.infinity)),
      top: pos.dy.clamp(pad.top, (size.height - h).clamp(pad.top, double.infinity)),
      width: _w,
      height: h,
      child: GestureDetector(
        onTap: () {
          setState(() => _controls = !_controls);
          if (_controls) _autoHide();
        },
        onDoubleTap: YomiMiniPlayer.expand,
        onPanUpdate: (d) => setState(() => _pos = pos + d.delta),
        onPanEnd: (_) {
          // snap to the nearest side
          final p = _pos ?? pos;
          setState(() => _pos = Offset(
                p.dx + _w / 2 < size.width / 2 ? 12 : size.width - _w - 12,
                p.dy,
              ));
        },
        child: Material(
          elevation: 12,
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(controller: widget.controller, controls: NoVideoControls),
              if (_controls && player != null)
                ColoredBox(
                  color: Colors.black45,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 8,
                        right: 72,
                        top: 6,
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Row(
                          children: [
                            _btn(Icons.open_in_full, tr('Mở lớn'), YomiMiniPlayer.expand),
                            _btn(Icons.close, tr('Đóng'), YomiMiniPlayer.close),
                          ],
                        ),
                      ),
                      Center(
                        child: StreamBuilder<bool>(
                          stream: player.stream.playing,
                          initialData: player.state.playing,
                          builder: (_, s) => _btn(
                            s.data == true ? Icons.pause : Icons.play_arrow,
                            s.data == true ? tr('Tạm dừng') : tr('Phát'),
                            () {
                              player.playOrPause();
                              _autoHide();
                            },
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        bottom: 0,
                        child: Row(
                          children: [
                            _btn(Icons.replay_10, tr('Lùi 10 giây'), () {
                              player.seek(player.state.position - const Duration(seconds: 10));
                            }),
                            _btn(Icons.forward_10, tr('Tới 10 giây'), () {
                              player.seek(player.state.position + const Duration(seconds: 10));
                            }),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 0,
                        child: _btn(
                          _w < 300 ? Icons.zoom_out_map : Icons.zoom_in_map,
                          tr('Đổi cỡ'),
                          () => setState(() => _w = _w < 300 ? 340 : 256),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData i, String tip, VoidCallback onTap, {double size = 22}) =>
      // No tooltip: this layer sits above the Navigator's Overlay.
      Semantics(
        label: tip,
        button: true,
        child: IconButton(
          iconSize: size,
          color: Colors.white,
          icon: Icon(i),
          onPressed: onTap,
        ),
      );
}
