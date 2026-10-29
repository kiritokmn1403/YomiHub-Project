import 'package:bot_toast/bot_toast.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mangayomi/modules/widgets/custom_extended_image_provider.dart';
import 'package:mangayomi/yomihub/booru/booru_api.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/booru/booru_screen.dart';
import 'package:mangayomi/yomihub/booru/booru_store.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.4.4 – Booru App viewer: swipe between posts, pinch / double-tap
/// zoom, video & GIF playback, favourite, download, share, tags.
class BooruViewer extends StatefulWidget {
  const BooruViewer({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.api,
    required this.onTag,
  });

  final List<BooruPost> posts;
  final int initialIndex;
  final BooruApi api;
  final void Function(String tag) onTag;

  @override
  State<BooruViewer> createState() => _BooruViewerState();
}

class _BooruViewerState extends State<BooruViewer> {
  final store = BooruStore.instance;
  late int _index = widget.initialIndex;
  late final ExtendedPageController _pages = ExtendedPageController(initialPage: widget.initialIndex);
  bool _chrome = true;
  static final Set<String> _failedLogged = {};

  BooruPost get _post => widget.posts[_index];

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _pages.dispose();
    super.dispose();
  }

  Map<String, String> _headers(BooruPost p) {
    final s = store.siteById(p.siteId);
    return {
      'User-Agent': 'YomiHub/0.4.4 (Booru App)',
      if (s != null) 'Referer': '${s.baseUrl}/',
    };
  }

  String _url(BooruPost p) => store.fullQuality ? p.fileUrl : p.sampleUrl;

  Future<void> _download() async {
    final path = await store.download(_post, booruClient());
    BotToast.showText(text: path == null ? tr('Tải xuống thất bại – xem Nhật ký ứng dụng') : tr('Đã lưu: {p0}', {'p0': path}));
  }

  void _share() {
    SharePlus.instance.share(ShareParams(uri: Uri.parse(_post.postUrl), subject: 'Booru #${_post.id}'));
  }

  Future<void> _openPost() async {
    final u = Uri.tryParse(_post.postUrl);
    if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  void _tags() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
          Text('#${_post.id} · ${_post.width}×${_post.height} · ${tr('Điểm')}: ${_post.score} · ${_ratingLabel(_post.rating)}',
              style: Theme.of(ctx).textTheme.titleSmall),
          if (_post.source.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                final u = Uri.tryParse(_post.source);
                if (u != null && u.hasScheme) launchUrl(u, mode: LaunchMode.externalApplication);
              },
              child: Text('${tr('Nguồn')}: ${_post.source}', style: const TextStyle(decoration: TextDecoration.underline)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in _post.tags)
              ActionChip(
                label: Text(t.replaceAll('_', ' ')),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onTag(t);
                },
              ),
          ]),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(tr('Chép liên kết')),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _post.fileUrl));
              Navigator.of(ctx).pop();
              BotToast.showText(text: tr('Đã chép'));
            },
          ),
        ]),
      ),
    );
  }

  static String _ratingLabel(BooruRating r) => switch (r) {
        BooruRating.general => tr('Phổ thông'),
        BooruRating.sensitive => tr('Nhạy cảm nhẹ'),
        BooruRating.questionable => '18+ (Q)',
        BooruRating.explicit => '18+ (E)',
        BooruRating.unknown => '?',
      };

  @override
  Widget build(BuildContext context) {
    final fav = store.isFavourite(_post);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _chrome
          ? AppBar(
              backgroundColor: Colors.black45,
              foregroundColor: Colors.white,
              title: Text('${_index + 1}/${widget.posts.length} · #${_post.id}'),
              actions: [
                IconButton(
                  tooltip: tr('Yêu thích'),
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.pinkAccent : null),
                  onPressed: () => store.toggleFavourite(_post),
                ),
                IconButton(tooltip: tr('Tải xuống'), icon: const Icon(Icons.download_outlined), onPressed: _download),
                IconButton(tooltip: tr('Chia sẻ'), icon: const Icon(Icons.share_outlined), onPressed: _share),
                PopupMenuButton<int>(
                  onSelected: (v) {
                    if (v == 0) _tags();
                    if (v == 1) _openPost();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(tr('Thẻ & thông tin'))),
                    PopupMenuItem(value: 1, child: Text(tr('Mở trang bài đăng'))),
                  ],
                ),
              ],
            )
          : null,
      body: ExtendedImageGesturePageView.builder(
        controller: _pages,
        itemCount: widget.posts.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final p = widget.posts[i];
          if (p.isVideo) {
            return _BooruVideo(
              key: ValueKey('v${p.siteId}${p.id}'),
              url: p.fileUrl,
              headers: _headers(p),
              active: i == _index,
              autoplay: store.autoplayVideo,
            );
          }
          return GestureDetector(
            onTap: () => setState(() => _chrome = !_chrome),
            child: ExtendedImage(
              image: CustomExtendedNetworkImageProvider(p.isGif ? p.fileUrl : _url(p), headers: _headers(p)),
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              initGestureConfigHandler: (_) => GestureConfig(
                minScale: 1,
                maxScale: 5,
                animationMaxScale: 6,
                inPageView: true,
              ),
              onDoubleTap: (state) {
                final s = state.gestureDetails?.totalScale ?? 1;
                state.handleDoubleTap(scale: s > 1.2 ? 1 : 2.5, doubleTapPosition: state.pointerDownPosition);
              },
              loadStateChanged: (st) {
                if (st.extendedImageLoadState == LoadState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (st.extendedImageLoadState == LoadState.failed) {
                  if (_failedLogged.add('${p.siteId}:${p.id}')) {
                    booruLog('Không tải được ảnh #${p.id}', st.lastException ?? 'unknown', site: store.siteById(p.siteId));
                  }
                  return Center(
                    child: TextButton.icon(
                      onPressed: st.reLoadImage,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(tr('Thử lại'), style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }
                return null;
              },
            ),
          );
        },
      ),
    );
  }
}

class _BooruVideo extends StatefulWidget {
  const _BooruVideo({super.key, required this.url, required this.headers, required this.active, required this.autoplay});
  final String url;
  final Map<String, String> headers;
  final bool active;
  final bool autoplay;

  @override
  State<_BooruVideo> createState() => _BooruVideoState();
}

class _BooruVideoState extends State<_BooruVideo> {
  Player? _player;
  VideoController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  void _start() {
    if (_player != null) return;
    final p = Player();
    _player = p;
    _ctrl = VideoController(p);
    p.setPlaylistMode(PlaylistMode.single);
    p.stream.error.listen((e) => booruLog('Không phát được video', e));
    p.open(Media(widget.url, httpHeaders: widget.headers), play: widget.autoplay);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _BooruVideo old) {
    super.didUpdateWidget(old);
    if (widget.active && _player == null) _start();
    if (!widget.active) _player?.pause();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    if (c == null) return const Center(child: CircularProgressIndicator());
    return Video(controller: c, controls: MaterialVideoControls);
  }
}
