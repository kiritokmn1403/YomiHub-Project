import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/models/video.dart' as vid;
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/modules/widgets/manga_image_card_widget.dart';
import 'package:mangayomi/services/get_filter_list.dart';
import 'package:mangayomi/services/isolate_service.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/player/sponsorblock.dart';
import 'package:mangayomi/yomihub/player/shorts_store.dart';
import 'package:mangayomi/modules/manga/download/providers/download_provider.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:mangayomi/yomihub/share/share_link.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';

/// YomiHub 0.1.8: "Short Video" – full-screen vertical feed (swipe up for
/// the next clip) for the YouTube and FikFap extensions.
///
/// Rewritten from the Video Short Scroll projects of the sheet (ShortStream,
/// VideoShorts, Video-Scrolling, Auto-Youtube-Shorts-Scroller): one clip per
/// page, it starts when it is in view and loops, the next clip is
/// pre-loaded in a second player so swiping is instant, tap = pause,
/// double tap = open the details, optional auto-scroll to the next clip at
/// the end. Only two players exist at any time, so long sessions stay light.
class YomiShorts {
  static const youtubeId = 920260006;
  static const fikfapId = 920260008;

  // YomiHub 0.2.0: every bundled extension flagged `shorts` (Pornhub
  // Shorties, Tik.Porn, Kwiky, xFree, FapReel…), plus YouTube / FikFap
  // copies from repositories.
  static bool supports(Source s) {
    if (BuiltinExtensions.shortsIds.contains(s.id)) return true;
    final n = (s.name ?? '').toLowerCase();
    return n.startsWith('youtube') || n.startsWith('fikfap');
  }

  static bool isYouTube(Source s) => s.id == youtubeId || (s.name ?? '').toLowerCase().startsWith('youtube');
}

class YomiShortsScreen extends ConsumerStatefulWidget {
  final Source source;
  final String query;
  const YomiShortsScreen({super.key, required this.source, this.query = ''});

  @override
  ConsumerState<YomiShortsScreen> createState() => _YomiShortsScreenState();
}

class _Clip {
  final MManga item;
  vid.Video? video;
  String? error;
  _Clip(this.item);
}

class _YomiShortsScreenState extends ConsumerState<YomiShortsScreen> {
  final _pages = PageController();
  final List<_Clip> _clips = [];
  // YomiHub 0.1.9: random feed - starts on a random page of the source
  int _page = ShortsStore.randomStartPage();
  bool _retriedFirst = false;
  final Set<String> _favs = {};
  bool _hasNext = true;
  bool _loading = false;
  int _index = 0;
  bool _muted = false;
  bool _autoNext = true;
  String? _error;

  // two players: [0] plays the current clip, [1] pre-loads the next one
  final List<Player> _players = [];
  final List<VideoController> _controllers = [];
  final List<int> _loaded = [-1, -1];
  StreamSubscription<bool>? _completed;

  String get _proxy => ref.read(androidProxyServerStateProvider);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    for (var i = 0; i < 2; i++) {
      final p = Player(configuration: const PlayerConfiguration(bufferSize: 16 * 1024 * 1024));
      p.setPlaylistMode(PlaylistMode.single);
      // 0.4.5: playback errors of a short (HLS 403/410, timeout) are logged
      p.stream.error.listen((e) {
        if (e.trim().isEmpty) return;
        AppLogger.logOnce('shorts-err:${widget.source.id}:$e', 'Shorts ${widget.source.name}: lỗi phát video: $e',
            logLevel: LogLevel.warning);
      });
      _players.add(p);
      _controllers.add(VideoController(p));
    }
    _more().then((_) => _show(0));
  }

  @override
  void dispose() {
    _completed?.cancel();
    for (final p in _players) {
      p.dispose();
    }
    _pages.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  List<dynamic> _shortsFilters() {
    List<dynamic> f = const [];
    try {
      f = FilterList.fromJson(FilterList(getFilterList(source: widget.source)).toJson()).filters;
    } catch (_) {}
    // 0.2.0: any select filter offering a "shorts" option (YouTube cat,
    // Pornhub/Tik.Porn/xFree… "feed") switches the source to its vertical feed
    var picked = false;
    for (final x in f) {
      if (x is SelectFilter) {
        final i = x.values.indexWhere((o) => o is SelectFilterOption && o.value == 'shorts');
        if (i >= 0) {
          x.state = i;
          picked = true;
        }
      }
    }
    if (!picked && !YomiShorts.isYouTube(widget.source)) {
      for (final x in f) {
        if (x is SelectFilter && x.type == 'sort') {
          final i = x.values.indexWhere((o) => o is SelectFilterOption && o.value == 'trending');
          if (i >= 0) x.state = i;
        }
      }
    }
    return f;
  }

  Future<void> _more() async {
    if (_loading || !_hasNext) return;
    _loading = true;
    try {
      final MPages? r = await getIsolateService.get<MPages?>(
        query: widget.query,
        filterList: _shortsFilters(),
        source: widget.source,
        page: _page,
        serviceType: 'search',
        proxyServer: _proxy,
      );
      final list = r?.list ?? const <MManga>[];
      if (list.isEmpty && _page > 1 && _clips.isEmpty && !_retriedFirst) {
        // the random start page was past the end of the source
        _retriedFirst = true;
        _page = 1;
        _loading = false;
        await _more();
        return;
      }
      final inFeed = _clips.map((c) => c.item.link).toSet();
      // YomiHub 0.1.9: random order, a clip already watched comes back 5 %
      // of the time
      var fresh = await ShortsStore.shuffleFresh(
        widget.source,
        list.where((m) => m.link != null && !inFeed.contains(m.link)).toList(),
      );
      if (fresh.isEmpty && list.isNotEmpty && _clips.length < 3) {
        // everything here was watched: show it anyway rather than nothing
        fresh = list.where((m) => m.link != null && !inFeed.contains(m.link)).toList()..shuffle();
      }
      for (final m in fresh) {
        if (await ShortsStore.isFavourite(widget.source, m.link)) _favs.add(m.link!);
      }
      if (!mounted) return;
      setState(() {
        _clips.addAll(fresh.map(_Clip.new));
        _hasNext = (r?.hasNextPage ?? false) && list.isNotEmpty;
        _page++;
        _error = null;
      });
      if (fresh.isEmpty && _hasNext) {
        _loading = false;
        await _more();
        return;
      }
    } catch (e) {
      // 0.4.5: the feed opens on a random page 1–3; a source whose later pages
      // depend on a session (Pornhub Shorties token) can fail there – start
      // over from page 1 once before showing an error.
      if (_clips.isEmpty && _page > 1 && !_retriedFirst) {
        _retriedFirst = true;
        _page = 1;
        _loading = false;
        await _more();
        return;
      }
      // 0.4.4: network / proxy failures are a warning without the stack dump
      final net = YomiExtErrors.isNetworkError(e);
      final h = net ? YomiExtErrors.hint(e) : null;
      AppLogger.log('Shorts ${widget.source.name}: ${YomiExtErrors.short(e)}${h == null ? '' : ' – $h'}',
          logLevel: net ? LogLevel.warning : LogLevel.error);
      if (mounted) setState(() => _error = '$e');
    } finally {
      _loading = false;
    }
  }

  /// Picks the stream for a short: muxed (audio + video) up to 720p first,
  /// HLS next; adaptive video gets its audio track attached.
  vid.Video? _pick(List<vid.Video> v) {
    if (v.isEmpty) return null;
    int q(vid.Video x) => int.tryParse(RegExp(r'(\d{3,4})p').firstMatch(x.quality)?.group(1) ?? '') ?? 0;
    final muxed = v.where((x) => x.quality.contains('có tiếng') || x.url.contains('.m3u8') || x.url.contains('yh_hls')).toList();
    if (muxed.isNotEmpty) {
      // 0.4.5 (Pornhub Shorties, kiểm thử máy ảo 30/10): sources list their
      // HLS variants best-first, so a short always opened at 1080p and stalled
      // on a slow CDN. Short clips use the best variant ≤ 720p.
      final ok = muxed.where((x) => q(x) > 0 && q(x) <= 720).toList()..sort((a, b) => q(b).compareTo(q(a)));
      if (ok.isNotEmpty) return ok.first;
      final known = muxed.where((x) => q(x) > 0).toList()..sort((a, b) => q(a).compareTo(q(b)));
      return known.isNotEmpty ? known.first : muxed.first;
    }
    final fit = v.where((x) => q(x) > 0 && q(x) <= 720).toList()..sort((a, b) => q(b).compareTo(q(a)));
    return fit.isNotEmpty ? fit.first : v.first;
  }

  Future<vid.Video?> _resolve(_Clip c) async {
    if (c.video != null || c.error != null) return c.video;
    try {
      final link = c.item.link!;
      final list = await getIsolateService.get<List<vid.Video>>(
        url: link,
        source: widget.source,
        serviceType: 'getVideoList',
        proxyServer: _proxy,
      );
      c.video = _pick(list);
      if (c.video == null) c.error = tr('Không có luồng phát');
    } catch (e) {
      c.error = '$e';
    }
    // 0.4.5 (Feature Check 34): a clip that cannot be played goes to the log
    if (c.error != null) {
      final net = YomiExtErrors.isNetworkError(c.error!);
      AppLogger.log('Shorts ${widget.source.name}: không phát được "${c.item.name}": ${YomiExtErrors.short(c.error!)}',
          logLevel: net ? LogLevel.warning : LogLevel.error);
    }
    return c.video;
  }

  Future<void> _load(int slot, int index) async {
    if (index < 0 || index >= _clips.length) return;
    if (_loaded[slot] == index) return;
    _loaded[slot] = index;
    final v = await _resolve(_clips[index]);
    if (v == null || _loaded[slot] != index) return;
    final p = _players[slot];
    await p.open(Media(v.url, httpHeaders: YomiSponsorBlock.clean(v.headers)), play: false);
    final audios = v.audios ?? const [];
    if (audios.isNotEmpty) {
      await p.setAudioTrack(AudioTrack.uri(audios.first.file!, title: audios.first.label));
    }
    await p.setVolume(_muted ? 0 : 100);
  }

  Future<void> _show(int index) async {
    if (_clips.isEmpty) return;
    _index = index;
    unawaited(ShortsStore.markSeen(widget.source, _clips[index].item.link));
    // the slot that already holds this clip becomes the current one
    final held = _loaded.indexOf(index);
    final cur = held >= 0 ? held : 0;
    if (cur != 0) {
      _players.insert(0, _players.removeAt(1));
      _controllers.insert(0, _controllers.removeAt(1));
      _loaded.insert(0, _loaded.removeAt(1));
    }
    await _players[1].pause();
    await _load(0, index);
    await _players[0].seek(Duration.zero);
    await _players[0].play();
    unawaited(_audioCheck(index));
    _completed?.cancel();
    _completed = _players[0].stream.completed.listen((done) {
      if (done && _autoNext && mounted && _index + 1 < _clips.length) {
        _pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      } else if (done) {
        _players[0].seek(Duration.zero).then((_) => _players[0].play());
      }
    });
    if (mounted) setState(() {});
    unawaited(_load(1, index + 1).catchError((_) {}));
    if (index + 4 >= _clips.length) unawaited(_more());
  }

  /// YomiHub 0.1.9: a clip with separate audio (YouTube adaptive streams)
  /// that is silent after a few seconds gets its audio track added again.
  Future<void> _audioCheck(int index) async {
    final v = _clips[index].video;
    final audios = v?.audios ?? const [];
    if (audios.isEmpty) return;
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted || _index != index || !_players[0].state.playing) return;
    final p = _players[0];
    final real = p.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no');
    if (p.state.track.audio.id != 'no' && real.isNotEmpty) return;
    try {
      await p.setAudioTrack(AudioTrack.uri(audios.first.file!, title: audios.first.label));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_clips.isEmpty)
            Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    )
                  : const CircularProgressIndicator(),
            )
          else
            PageView.builder(
              controller: _pages,
              scrollDirection: Axis.vertical,
              itemCount: _clips.length,
              onPageChanged: _show,
              itemBuilder: (context, i) => _clipView(i),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Short Video · ${widget.source.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Tự chuyển clip khi hết'),
                    icon: Icon(_autoNext ? Icons.repeat_on_outlined : Icons.repeat_one, color: Colors.white),
                    onPressed: () => setState(() => _autoNext = !_autoNext),
                  ),
                  IconButton(
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      for (final p in _players) {
                        p.setVolume(_muted ? 0 : 100);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clipView(int i) {
    final c = _clips[i];
    final slot = _loaded.indexOf(i);
    final playing = i == _index && slot >= 0;
    return GestureDetector(
      onTap: () {
        if (i != _index) return;
        final p = _players[0];
        p.state.playing ? p.pause() : p.play();
        setState(() {});
      },
      onDoubleTap: () => pushToMangaReaderDetail(
        ref: ref,
        context: context,
        getManga: c.item,
        lang: widget.source.lang!,
        itemType: widget.source.itemType,
        source: widget.source.name!,
        sourceId: widget.source.id,
        useMaterialRoute: true,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((c.item.imageUrl ?? '').isNotEmpty)
            Opacity(
              opacity: 0.35,
              child: Image.network(c.item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
            ),
          if (playing)
            Video(
              controller: _controllers[slot],
              controls: NoVideoControls,
              fit: BoxFit.contain,
              fill: Colors.transparent,
            ),
          if (c.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(c.error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              ),
            ),
          if (playing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StreamBuilder<Duration>(
                stream: _players[slot].stream.position,
                builder: (_, s) {
                  final d = _players[slot].state.duration.inMilliseconds;
                  final v = d == 0 ? 0.0 : (s.data?.inMilliseconds ?? 0) / d;
                  return LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 2, backgroundColor: Colors.white12);
                },
              ),
            ),
          Positioned(
            left: 14,
            right: 80,
            bottom: 24,
            child: Text(
              c.item.name ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15, shadows: [Shadow(blurRadius: 6)]),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 24,
            child: Column(
              children: [
                _side(Icons.info_outline, tr('Chi tiết'), () => pushToMangaReaderDetail(
                      ref: ref,
                      context: context,
                      getManga: c.item,
                      lang: widget.source.lang!,
                      itemType: widget.source.itemType,
                      source: widget.source.name!,
                      sourceId: widget.source.id,
                      useMaterialRoute: true,
                    )),
                // YomiHub 0.1.9: Yêu thích (own category), Thêm vào thư viện
                // (category picker), Tải xuống (right below it)
                _side(
                  _favs.contains(c.item.link) ? Icons.favorite : Icons.favorite_border,
                  tr('Yêu thích'),
                  () => _toggleFav(c),
                  color: _favs.contains(c.item.link) ? Colors.pinkAccent : Colors.white,
                ),
                _side(Icons.library_add_outlined, tr('Thư viện'), () => _addLibrary(c)),
                // YomiHub 0.2.0: share the clip's link, right below
                // "Thêm vào thư viện"
                _side(Icons.share_outlined, tr('Chia sẻ'), () => YomiShareLink.share(
                      context,
                      YomiShareLink.webUrl(widget.source, c.item.link),
                      title: c.item.name,
                    )),
                _side(Icons.download_outlined, tr('Tải xuống'), () => _download(c)),
                _side(Icons.keyboard_arrow_down, tr('Tiếp'), () => _pages.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFav(_Clip c) async {
    try {
      final on = await ShortsStore.toggleFavourite(widget.source, c.item);
      setState(() => on ? _favs.add(c.item.link!) : _favs.remove(c.item.link));
      BotToast.showText(
        text: on
            ? tr('Đã lưu vào {p0}', {'p0': ShortsStore.favouriteCategoryName})
            : tr('Đã bỏ khỏi {p0}', {'p0': ShortsStore.favouriteCategoryName}),
      );
    } catch (e) {
      BotToast.showText(text: '$e');
    }
  }

  Future<void> _addLibrary(_Clip c) async {
    try {
      if (await ShortsStore.addToLibrary(context, widget.source, c.item)) {
        BotToast.showText(text: tr('Đã thêm vào thư viện'));
      }
    } catch (e) {
      BotToast.showText(text: '$e');
    }
  }

  Future<void> _download(_Clip c) async {
    try {
      final ch = await ShortsStore.episodeFor(widget.source, c.item);
      ref.invalidate(downloadChapterProvider(chapter: ch));
      ref.read(downloadChapterProvider(chapter: ch));
      BotToast.showText(text: tr('Đã thêm vào hàng tải xuống'));
    } catch (e) {
      BotToast.showText(text: '$e');
    }
  }

  Widget _side(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Icon(icon, color: color, size: 30, shadows: const [Shadow(blurRadius: 6)]),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      );
}
