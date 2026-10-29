import 'dart:collection';
import 'package:mangayomi/utils/log/logger.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/video.dart' as vid;
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';

/// YomiHub 0.1.4: plays a server through the site's own web player.
///
/// Some servers only exist as an embedded player page (encrypted MSE
/// players such as AnimeVietsub "DU", Abyss/Hydrax…), so their stream can't
/// be handed to mpv. Extensions return those as videos whose url starts with
/// `yhweb:`; YomiHub opens them here, full screen, with pop-ups and ad
/// redirects blocked.
class YomiWebPlayer extends StatefulWidget {
  static const prefix = 'yhweb:';
  final Chapter episode;
  final List<vid.Video> servers;
  const YomiWebPlayer({super.key, required this.episode, required this.servers});

  static bool isWeb(vid.Video v) => v.url.startsWith(prefix);

  /// Web-only servers of the episode being played, for the automatic
  /// server switch to fall back on.
  static List<vid.Video> pending = [];

  @override
  State<YomiWebPlayer> createState() => _YomiWebPlayerState();
}

class _YomiWebPlayerState extends State<YomiWebPlayer> {
  int _i = 0;
  bool _ui = true;
  final _watch = Stopwatch()..start();

  vid.Video get _cur => widget.servers[_i];
  String get _url => _cur.url.substring(YomiWebPlayer.prefix.length);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _ui = false);
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_watch.elapsed.inMinutes >= 3) {
      final ep = widget.episode;
      ep.isRead = true;
      chapterRepository.save(ep);
    }
    super.dispose();
  }

  // Attempt once per video source; never restart playback after the user pauses.
  static const _autoplayScript = r"""
(() => {
  if (window.__yhAutoplay) return;
  window.__yhAutoplay = true;
  const attempted = new WeakMap();
  function start() {
    document.querySelectorAll('video').forEach(video => {
      const source = video.currentSrc || video.src;
      if (!source || video.readyState < 2 || attempted.get(video) === source) return;
      attempted.set(video, source);
      video.playsInline = true;
      const result = video.play();
      if (result && result.catch) result.catch(() => {});
    });
  }
  document.addEventListener('loadeddata', start, true);
  document.addEventListener('canplay', start, true);
  start();
})();
""";

  bool _sameSite(String a, String b) {
    String root(String u) {
      final h = Uri.tryParse(u)?.host ?? '';
      final p = h.split('.');
      return p.length >= 2 ? p.sublist(p.length - 2).join('.') : h;
    }

    return root(a) == root(b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InAppWebView(
            key: ValueKey(_i),
            initialUrlRequest: URLRequest(
              url: WebUri(_url),
              headers: _cur.headers,
            ),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              javaScriptCanOpenWindowsAutomatically: false,
              supportMultipleWindows: true,
              useWideViewPort: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              useShouldInterceptRequest: true,
              contentBlockers: YomiAdBlock.activeFor(_url)
                  ? YomiAdBlock.contentBlockers()
                  : [],
            ),
            initialUserScripts: UnmodifiableListView([
              UserScript(
                source: _autoplayScript,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                forMainFrameOnly: false,
              ),
              if (YomiAdBlock.activeFor(_url))
                UserScript(
                  source: YomiAdBlock.pageScript(YomiAdBlock.hostOf(_url)),
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                  forMainFrameOnly: false,
                ),
            ]),
            shouldInterceptRequest: (controller, request) async {
              if (YomiAdBlock.activeFor(_url) && YomiAdBlock.isAd(request.url.toString())) {
                return WebResourceResponse(data: Uint8List(0), statusCode: 200,
                    reasonPhrase: 'OK', contentType: 'text/plain');
              }
              return null;
            },
            onCreateWindow: (c, a) async => false, // no pop-ups
            shouldOverrideUrlLoading: (c, a) async {
              final u = a.request.url?.toString() ?? '';
              if (!a.isForMainFrame) return NavigationActionPolicy.ALLOW;
              if ((YomiAdBlock.activeFor(_url) && YomiAdBlock.isAd(u)) || !_sameSite(u, _url)) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStop: (c, u) async {
              try {
                await c.evaluateJavascript(source: _autoplayScript);
                if (YomiAdBlock.activeFor(_url)) {
                  await c.evaluateJavascript(source: YomiAdBlock.pageScript(YomiAdBlock.hostOf(_url)));
                }
              } catch (error) {
                AppLogger.log('Web player script failed: $error', logLevel: LogLevel.warning);
              }
            },
          ),
          // tap strip at the top toggles the overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 36,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _ui = !_ui),
            ),
          ),
          if (_ui)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.episode.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                    for (var k = 0; k < widget.servers.length; k++)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(widget.servers[k].quality),
                          selected: k == _i,
                          onSelected: (_) => setState(() => _i = k),
                        ),
                      ),
                      ]),
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
