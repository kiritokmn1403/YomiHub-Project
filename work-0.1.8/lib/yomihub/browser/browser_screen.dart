import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/scanner/web_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';
import 'package:mangayomi/yomihub/browser/userscripts_screen.dart';
import 'package:mangayomi/yomihub/browser/gecko_view.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';
import 'package:mangayomi/yomihub/vpn/vpn_service.dart';
import 'package:mangayomi/yomihub/savior/savior.dart';
import 'package:mangayomi/yomihub/savior/savior_screen.dart';

/// YomiHub: stand-alone in-app web browser (address bar, back/forward,
/// history). History lives in the Hive box [BrowserHistory.boxName] so it can
/// be cleared from here and exported with the app data.
class BrowserHistory {
  static const boxName = 'yomihub_browser_history';
  static const _max = 500;

  static Future<Box<String>> _box() => Hive.isBoxOpen(boxName)
      ? Future.value(Hive.box<String>(boxName))
      : Hive.openBox<String>(boxName);

  static Future<void> add(String url, String title) async {
    if (url.isEmpty || url == 'about:blank') return;
    try {
      final b = await _box();
      await b.add(jsonEncode({
        'url': url,
        'title': title,
        'time': DateTime.now().millisecondsSinceEpoch,
      }));
      if (b.length > _max) {
        await b.deleteAll(b.keys.take(b.length - _max).toList());
      }
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> all() async {
    try {
      final b = await _box();
      return b.values
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Restores history from a backup ([items] newest first, as [all] returns).
  static Future<void> replaceAll(
    List<Map<String, dynamic>> items, {
    bool merge = false,
  }) async {
    try {
      final b = await _box();
      final existing = merge ? await all() : <Map<String, dynamic>>[];
      final seen = <String>{};
      final combined = [...items, ...existing]
          .where((e) => seen.add('${e['url']}|${e['time']}'))
          .toList()
        ..sort((a, c) => ((c['time'] ?? 0) as num).compareTo((a['time'] ?? 0) as num));
      await b.clear();
      for (final e in combined.take(_max).toList().reversed) {
        await b.add(jsonEncode(e));
      }
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await (await _box()).clear();
    } catch (_) {}
  }
}

class _Tab {
  static int _seq = 0;
  final int id = ++_seq;
  String url;
  String title = '';
  double progress = 0;
  bool canBack = false, canForward = false;
  bool desktop = false;
  int adsBlocked = 0;
  final int? windowId;
  InAppWebViewController? c;
  /// YomiHub 0.1.4: this tab uses the Firefox (Gecko) engine.
  bool gecko;
  GeckoController? g;
  /// YomiHub 0.1.5 Savior: media found on the current page (url → info).
  final media = <String, SaviorMedia>{};
  _Tab(this.url, {this.windowId, this.gecko = false});
}

/// YomiHub browser: tabs, ad blocking (network + cosmetic + pop-ups),
/// history, desktop mode, cookie sharing with extensions.
class BrowserScreen extends StatefulWidget {
  final String? initialUrl;
  const BrowserScreen({super.key, this.initialUrl});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  static const _home = 'https://www.google.com/';
  static const _maxTabs = 12;
  static const _desktopUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';
  final _address = TextEditingController();
  final _focus = FocusNode();
  final List<_Tab> _tabs = [];
  int _cur = 0;
  bool _ready = false;

  _Tab get _tab => _tabs[_cur];

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool _geckoOk = false;
  bool get _defaultGecko => _geckoOk && YomiPrefs.get('browserEngine', 'chromium') == 'gecko';

  // engine-neutral navigation
  void _load(_Tab t, Uri uri) {
    if (t.gecko) {
      t.g?.load(uri.toString());
    } else {
      t.c?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
    }
  }

  void _back(_Tab t) => t.gecko ? t.g?.back() : t.c?.goBack();
  void _forward(_Tab t) => t.gecko ? t.g?.forward() : t.c?.goForward();
  void _reload(_Tab t) => t.gecko ? t.g?.reload() : t.c?.reload();

  Future<void> _init() async {
    // VPN & DNS: the browser's own scope applies while it is on screen.
    await YomiVpnService.instance.setBrowserForeground(true);
    _geckoOk = await GeckoController.supported();
    await YomiAdBlock.load();
    YomiAdBlock.autoUpdate();
    List<String> saved = [];
    int savedCur = 0;
    try {
      final b = Hive.isBoxOpen('yomihub_browser')
          ? Hive.box('yomihub_browser')
          : await Hive.openBox('yomihub_browser');
      saved = (b.get('tabs', defaultValue: <String>[]) as List).cast<String>();
      savedCur = b.get('cur', defaultValue: 0) as int;
    } catch (_) {}
    for (final u in saved.take(_maxTabs)) {
      _tabs.add(_Tab(u, gecko: _defaultGecko));
    }
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _tabs.add(_Tab(_toUri(widget.initialUrl!).toString(), gecko: _defaultGecko));
      savedCur = _tabs.length - 1;
    }
    if (_tabs.isEmpty) _tabs.add(_Tab(_home, gecko: _defaultGecko));
    _cur = savedCur.clamp(0, _tabs.length - 1);
    _address.text = _tab.url;
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _saveTabs() async {
    try {
      final b = Hive.isBoxOpen('yomihub_browser')
          ? Hive.box('yomihub_browser')
          : await Hive.openBox('yomihub_browser');
      await b.put('tabs', _tabs.map((t) => t.url).where((u) => u.startsWith('http')).toList());
      await b.put('cur', _cur);
    } catch (_) {}
  }

  @override
  void dispose() {
    YomiVpnService.instance.setBrowserForeground(false);
    _saveTabs();
    _address.dispose();
    _focus.dispose();
    super.dispose();
  }

  Uri _toUri(String input) {
    final t = input.trim();
    final looksLikeUrl = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(t) ||
        (!t.contains(' ') && t.contains('.'));
    if (looksLikeUrl) {
      return Uri.parse(t.contains('://') ? t : 'https://$t');
    }
    return Uri.https('www.google.com', '/search', {'q': t});
  }

  void _go(String input) {
    _focus.unfocus();
    final uri = _toUri(input);
    _tab.url = uri.toString();
    _load(_tab, uri);
  }

  void _openTab(String url, {bool background = false, int? windowId}) {
    if (_tabs.length >= _maxTabs) {
      _toast('Tối đa $_maxTabs tab – hãy đóng bớt tab');
      return;
    }
    setState(() {
      _tabs.add(_Tab(url, windowId: windowId, gecko: windowId == null && _defaultGecko));
      if (!background) {
        _cur = _tabs.length - 1;
        _address.text = url;
      }
    });
    _saveTabs();
    if (background) _toast('Đã mở trong tab mới');
  }

  void _closeTab(int i) {
    setState(() {
      _tabs.removeAt(i);
      if (_tabs.isEmpty) _tabs.add(_Tab(_home, gecko: _defaultGecko));
      if (_cur >= _tabs.length) _cur = _tabs.length - 1;
      if (i < _cur) _cur--;
      _address.text = _tab.url;
    });
    _saveTabs();
  }

  void _select(int i) {
    setState(() {
      _cur = i;
      _address.text = _tab.url;
    });
    _saveTabs();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  InAppWebViewSettings _settings(_Tab t) => InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        supportMultipleWindows: true,
        javaScriptCanOpenWindowsAutomatically: !YomiAdBlock.activeFor(t.url),
        mediaPlaybackRequiresUserGesture: true,
        useWideViewPort: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        userAgent: t.desktop ? _desktopUa : '',
        preferredContentMode:
            t.desktop ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.RECOMMENDED,
        contentBlockers: YomiAdBlock.activeFor(t.url) ? YomiAdBlock.contentBlockers() : [],
        // Savior: see media requests and file downloads
        useOnLoadResource: true,
        useOnDownloadStart: true,
      );

  // ───────────── Savior (Cốc Cốc-style media download) ─────────────

  static const _saviorJs = r'''
(function(){
  if (window.__yhSavior) return; window.__yhSavior = 1;
  var seen = {};
  var rep = function(u){ try { if (!u || typeof u !== 'string' || u.indexOf('blob:') === 0 || seen[u]) return; seen[u]=1;
    window.flutter_inappwebview.callHandler('yhSavior', new URL(u, location.href).href, location.href); } catch(e){} };
  var scan = function(){ try { document.querySelectorAll('video, audio, video source, audio source, a[href]').forEach(function(v){
      if (v.tagName === 'A') { var h = v.getAttribute('href') || ''; if (/\.(mp4|webm|mkv|mp3|m4a|m3u8)(\?|$)/i.test(h)) rep(h); return; }
      rep(v.currentSrc || v.src); }); } catch(e){} };
  try { var _f = window.fetch; window.fetch = function(i){ try { rep(typeof i === 'string' ? i : (i && i.url)); } catch(e){} return _f.apply(this, arguments); }; } catch(e){}
  try { var _o = XMLHttpRequest.prototype.open; XMLHttpRequest.prototype.open = function(m, u){ try { rep('' + u); } catch(e){} return _o.apply(this, arguments); }; } catch(e){}
  scan(); var tmr = null; try { new MutationObserver(function(){ if (tmr) return; tmr = setTimeout(function(){ tmr = null; scan(); }, 800); }).observe(document.documentElement, {childList:true, subtree:true}); } catch(e){}
  document.addEventListener('play', function(e){ try { rep(e.target.currentSrc || e.target.src); } catch(x){} }, true);
})();
''';

  void _saviorSeen(_Tab t, String url, String page) {
    final m = SaviorMedia.classify(url, page);
    if (m == null || t.media.containsKey(url)) return;
    t.media[url] = m;
    if (mounted && t == _tab) setState(() {});
  }

  Future<void> _saviorSheet(_Tab t) async {
    final items = t.media.values.toList().reversed.toList();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.download_for_offline, color: Colors.green),
                title: const Text('Savior'),
                subtitle: Text('${items.length} tệp media trên trang này'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SaviorScreen()));
                  },
                  child: const Text('Danh sách tải'),
                ),
              ),
              for (final m in items)
                ListTile(
                  leading: Icon(m.kind == SaviorKind.hls ? Icons.stream : m.label.startsWith('Âm') ? Icons.audiotrack : Icons.movie_outlined),
                  title: Text(m.label),
                  subtitle: Text(m.url, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: m.kind == SaviorKind.dash
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _saviorDownload(t, m);
                          },
                        ),
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: m.url));
                    _toast('Đã sao chép link');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saviorDownload(_Tab t, SaviorMedia m) async {
    await Savior.instance.init();
    var url = m.url;
    final title = t.title.trim().isEmpty ? YomiAdBlock.hostOf(t.url) : t.title.trim();
    if (m.kind == SaviorKind.hls) {
      List<SaviorVariant> vs = [];
      try {
        vs = await Savior.instance.variants(url, {'Referer': t.url});
      } catch (_) {}
      if (vs.length > 1 && mounted) {
        final pick = await showDialog<SaviorVariant>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Chọn chất lượng'),
            children: [
              for (final v in vs)
                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, v), child: Text(v.label)),
            ],
          ),
        );
        if (pick == null) return;
        url = pick.url;
      }
    }
    Savior.instance.add(url: url, title: title, kind: m.kind, page: t.url);
    _toast('Savior: đang tải "$title"');
  }

  Future<void> _applySettings(_Tab t, {bool reload = true}) async {
    if (t.gecko) {
      await t.g?.desktop(t.desktop);
      return;
    }
    await t.c?.setSettings(settings: _settings(t));
    if (reload) await t.c?.reload();
  }

  Widget _geckoView(_Tab t) {
    return GeckoBrowserView(
      key: ValueKey('g${t.id}'),
      url: t.url,
      desktop: t.desktop,
      adblock: YomiAdBlock.enabled,
      onCreated: (g) => t.g = g,
      onProgress: (p) {
        if (mounted) setState(() => t.progress = p / 100);
      },
      onUrl: (u) {
        if (!mounted || u.isEmpty) return;
        setState(() {
          t.url = u;
          if (t == _tab && !_focus.hasFocus) _address.text = u;
        });
      },
      onTitle: (title) => t.title = title,
      onCanBack: (v) {
        if (mounted) setState(() => t.canBack = v);
      },
      onCanForward: (v) {
        if (mounted) setState(() => t.canForward = v);
      },
      onNewWindow: (u) {
        if (YomiAdBlock.activeFor(t.url) && YomiAdBlock.isAd(u)) {
          t.adsBlocked++;
          _toast('Đã chặn cửa sổ bật lên');
          return;
        }
        _openTab(u);
      },
      onPageStop: () async {
        if (t.url.startsWith('http')) {
          await BrowserHistory.add(t.url, t.title);
          _saveTabs();
        }
      },
    );
  }

  Widget _webView(_Tab t) {
    if (t.gecko) return _geckoView(t);
    return InAppWebView(
      key: ValueKey(t.id),
      windowId: t.windowId,
      initialUrlRequest: t.windowId == null ? URLRequest(url: WebUri(t.url)) : null,
      initialSettings: _settings(t),
      onWebViewCreated: (c) {
        t.c = c;
        c.addJavaScriptHandler(
          handlerName: 'yhSavior',
          callback: (a) {
            if (a.isNotEmpty) _saviorSeen(t, '${a[0]}', a.length > 1 ? '${a[1]}' : t.url);
          },
        );
      },
      onLoadResource: (c, r) => _saviorSeen(t, r.url.toString(), t.url),
      onDownloadStartRequest: (c, req) async {
        // Ordinary file downloads go through Savior too.
        final u = req.url.toString();
        if (!u.startsWith('http')) return;
        final name = (req.suggestedFilename ?? Uri.tryParse(u)?.pathSegments.lastOrNull ?? 'tep')
            .replaceAll(RegExp(r'\.[A-Za-z0-9]{2,4}$'), '');
        await Savior.instance.init();
        Savior.instance.add(url: u, title: name, kind: u.contains('.m3u8') ? SaviorKind.hls : SaviorKind.file, page: t.url);
        _toast('Savior: đang tải "$name"');
      },
      onProgressChanged: (_, p) {
        if (!mounted) return;
        setState(() => t.progress = p / 100);
      },
      onCreateWindow: (controller, action) async {
        final url = action.request.url?.toString() ?? '';
        if (YomiAdBlock.activeFor(t.url)) {
          if (action.hasGesture != true || (url.isNotEmpty && YomiAdBlock.isAd(url))) {
            t.adsBlocked++;
            _toast('Đã chặn cửa sổ bật lên');
            return false;
          }
        }
        _openTab(url.isEmpty ? 'about:blank' : url, windowId: action.windowId);
        return true;
      },
      onCloseWindow: (controller) {
        final i = _tabs.indexWhere((x) => x.c == controller);
        if (i >= 0 && _tabs.length > 1) _closeTab(i);
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final uri = action.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;
        final s = uri.toString();
        if (YomiAdBlock.activeFor(t.url) && YomiAdBlock.isAd(s)) {
          t.adsBlocked++;
          _toast('Đã chặn chuyển hướng quảng cáo');
          return NavigationActionPolicy.CANCEL;
        }
        if (!['http', 'https', 'about', 'data', 'javascript', 'blob'].contains(uri.scheme)) {
          // intent:// and market:// are mostly ad redirects; only follow on tap
          if (action.hasGesture == true && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onLongPressHitTestResult: (controller, hit) async {
        final link = hit.extra;
        if (link == null || link.isEmpty) return;
        if (hit.type != InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE &&
            hit.type != InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE &&
            hit.type != InAppWebViewHitTestResultType.IMAGE_TYPE) {
          return;
        }
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text(link, maxLines: 2, overflow: TextOverflow.ellipsis)),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Mở trong tab mới'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openTab(link);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tab_unselected),
                  title: const Text('Mở trong tab nền'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openTab(link, background: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Sao chép liên kết'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
      onUpdateVisitedHistory: (controller, url, isReload) async {
        final u = url?.toString() ?? '';
        final back = await controller.canGoBack();
        final fwd = await controller.canGoForward();
        if (!mounted) return;
        final hostChanged = YomiAdBlock.hostOf(u) != YomiAdBlock.hostOf(t.url);
        setState(() {
          t.url = u.isEmpty ? t.url : u;
          t.canBack = back;
          t.canForward = fwd;
          if (t == _tab && !_focus.hasFocus) _address.text = t.url;
        });
        if (hostChanged) {
          // whitelist / blocking state depends on the site
          await controller.setSettings(settings: _settings(t));
        }
        try {
          final ua = await controller.evaluateJavascript(source: 'navigator.userAgent') ?? '';
          await MClient.setCookie(u, ua, controller);
        } catch (_) {}
      },
      onLoadStart: (controller, url) {
        // new page: forget the previous page's media
        if (t.media.isNotEmpty) {
          t.media.clear();
          if (mounted && t == _tab) setState(() {});
        }
      },
      onLoadStop: (controller, url) async {
        t.title = await controller.getTitle() ?? '';
        try {
          await controller.evaluateJavascript(source: _saviorJs);
        } catch (_) {}
        if (url != null && YomiAdBlock.activeFor(url.toString())) {
          try {
            await controller.evaluateJavascript(
                source: YomiAdBlock.pageScript(YomiAdBlock.hostOf(url.toString())));
          } catch (_) {}
        }
        final us = url == null ? '' : YomiAdBlock.userScriptsFor(url.toString());
        if (us.isNotEmpty) {
          try {
            await controller.evaluateJavascript(source: us);
          } catch (_) {}
        }
        if (url != null && (url.scheme == 'http' || url.scheme == 'https')) {
          await BrowserHistory.add(url.toString(), t.title);
          _saveTabs();
        }
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _showTabs() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                ListTile(
                  title: Text('${_tabs.length} tab', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Wrap(spacing: 4, children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close_fullscreen),
                      label: const Text('Đóng tất cả'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _tabs
                            ..clear()
                            ..add(_Tab(_home));
                          _cur = 0;
                          _address.text = _home;
                        });
                        _saveTabs();
                      },
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tab mới'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openTab(_home);
                      },
                    ),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (_, i) {
                      final t = _tabs[i];
                      return ListTile(
                        selected: i == _cur,
                        leading: Icon(i == _cur ? Icons.tab : Icons.tab_unselected),
                        title: Text(t.title.isNotEmpty ? t.title : t.url,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(t.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _closeTab(i);
                            setSheet(() {});
                          },
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _select(i);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _adblockSettings() async {
    final rules = TextEditingController(text: YomiAdBlock.userRules.join('\n'));
    bool on = YomiAdBlock.enabled;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Chặn quảng cáo'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: on,
                    title: const Text('Bật chặn quảng cáo'),
                    subtitle: Text('${YomiAdBlock.hosts.length + YomiAdBlock.listHosts.length} tên miền quảng cáo/theo dõi, chặn cửa sổ bật lên và lớp phủ'),
                    onChanged: (v) => set(() => on = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.update),
                    title: const Text('Cập nhật bộ lọc'),
                    subtitle: Text('${YomiAdBlock.lists.keys.join(', ')}\n'
                        '${YomiAdBlock.listUpdated == 0 ? 'Chưa tải' : 'Lần cuối: ${DateTime.fromMillisecondsSinceEpoch(YomiAdBlock.listUpdated).toString().substring(0, 16)}'}'),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tải bộ lọc…')));
                      final n = await YomiAdBlock.updateLists();
                      set(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật: $n tên miền')));
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code),
                    title: const Text('Tampermonkey AdBlock & Userscript'),
                    subtitle: Text(YomiAdBlock.tampermonkey
                        ? 'Đang bật • ${YomiAdBlock.tmSites.length} cấu hình trang • ${YomiAdBlock.userScripts.length} userscript'
                        : 'Đang tắt'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserScriptsScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Quy tắc riêng (cú pháp uBlock / Adblock Plus):\n'
                      '||ads.example.com^  – chặn tên miền\n'
                      'example.com##.banner  – ẩn phần tử trên trang\n'
                      '##.quang-cao  – ẩn trên mọi trang',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rules,
                    maxLines: 8,
                    minLines: 4,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  if (YomiAdBlock.allowed.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Trang được bỏ qua: ${YomiAdBlock.allowed.join(', ')}',
                        style: const TextStyle(fontSize: 12)),
                    TextButton(
                      onPressed: () => set(() => YomiAdBlock.allowed.clear()),
                      child: const Text('Xóa danh sách bỏ qua'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (saved == true) {
      YomiAdBlock.enabled = on;
      YomiAdBlock.userRules =
          rules.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty && !e.startsWith('!')).toList();
      await YomiAdBlock.save();
      for (final t in _tabs) {
        await _applySettings(t, reload: t == _tab);
      }
    }
  }

  Future<void> _showHistory() async {
    final l10n = context.l10n;
    final items = await BrowserHistory.all();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.browser_history,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n.clear_browser_history),
                  onPressed: () async {
                    await BrowserHistory.clear();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(l10n.no_result))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final e = items[i];
                          final t = DateTime.fromMillisecondsSinceEpoch(e['time'] as int);
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.public),
                            title: Text(
                                (e['title'] as String?)?.isNotEmpty == true ? e['title'] : e['url'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                '${t.day}/${t.month}/${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}  •  ${e['url']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            onTap: () => Navigator.pop(ctx, e['url'] as String),
                            onLongPress: () {
                              Navigator.pop(ctx);
                              _openTab(e['url'] as String);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) _go(picked);
  }

  /// Shows which Chromium (Android System WebView / Edge WebView2) build
  /// renders pages. The engine is updated by the system, so security fixes
  /// arrive without a YomiHub update.
  Future<void> _engineInfo() async {
    String name = 'Không rõ', version = '';
    try {
      final pkg = await InAppWebViewController.getCurrentWebViewPackage();
      name = pkg?.packageName ?? name;
      version = pkg?.versionName ?? '';
    } catch (_) {}
    final major = int.tryParse(version.split('.').first) ?? 0;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhân trình duyệt'),
        content: Text(
          'Gói: $name\nPhiên bản Chromium: ${version.isEmpty ? '?' : version}\n\n'
          '${major > 0 && major < 120 ? '⚠️ Bản WebView đã cũ, nhiều trang có thể lỗi. Hãy cập nhật Android System WebView hoặc Chrome.\n\n' : ''}'
          'Chromium: nhân WebView của hệ thống, cập nhật qua CH Play.\n'
          'Firefox: nhân Gecko ${_geckoOk ? '157 tích hợp sẵn (chặn theo dõi chặt + uBlock Origin)' : 'cần Android 8.0+'}.\n'
          'Nhân mặc định cho tab mới: ${YomiPrefs.get('browserEngine', 'chromium') == 'gecko' ? 'Firefox (Gecko)' : 'Chromium'}.',
        ),
        actions: [
          if (_geckoOk)
            TextButton(
              onPressed: () async {
                final gecko = YomiPrefs.get('browserEngine', 'chromium') == 'gecko';
                await YomiPrefs.set('browserEngine', gecko ? 'chromium' : 'gecko');
                if (ctx.mounted) Navigator.pop(ctx);
                _toast(gecko
                    ? 'Tab mới sẽ dùng nhân Chromium'
                    : 'Tab mới sẽ dùng nhân Firefox (Gecko)');
              },
              child: Text(YomiPrefs.get('browserEngine', 'chromium') == 'gecko'
                  ? 'Mặc định: Chromium'
                  : 'Mặc định: Firefox'),
            ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.webview'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Cập nhật WebView'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  bool get _glass =>
      YomiPrefs.get<bool>('liquidGlass', false) &&
      YomiPrefs.get<bool>('liquidGlassBrowser', true);

  /// Address bar as a rounded glass pill when Liquid Glass is on.
  Widget _glassPill(Widget field) {
    if (!_glass) return field;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          YomiPrefs.get<double>('liquidGlassRadius', 20),
        ),
        color: Colors.white.withValues(alpha: dark ? 0.08 : 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.18 : 0.6)),
      ),
      alignment: Alignment.centerLeft,
      child: field,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_ready) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final t = _tab;
    final siteAllowed = YomiAdBlock.allowed.contains(YomiAdBlock.hostOf(t.url));
    return PopScope(
      canPop: !t.canBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(t);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          // YomiHub 0.1.6: Liquid Glass for the browser toolbar.
          backgroundColor: _glass ? Colors.transparent : null,
          flexibleSpace: _glass
              ? LiquidGlassBar(
                  area: 'browser',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                )
              : null,
          title: _glassPill(TextField(
            controller: _address,
            focusNode: _focus,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: _go,
            onTap: () => _address.selection =
                TextSelection(baseOffset: 0, extentOffset: _address.text.length),
            decoration: InputDecoration(
              hintText: l10n.browser_search_hint,
              isDense: true,
              border: InputBorder.none,
              prefixIcon: Icon(
                YomiAdBlock.activeFor(t.url) ? Icons.shield : Icons.shield_outlined,
                size: 18,
                color: YomiAdBlock.activeFor(t.url) ? Colors.green : null,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 28),
            ),
          )),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: t.canBack ? () => _back(t) : null,
            ),
            IconButton(
              tooltip: 'Tab',
              onPressed: _showTabs,
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('${_tabs.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            PopupMenuButton<int>(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 10, child: Text('Tab mới')),
                PopupMenuItem(value: 11, enabled: t.canForward, child: const Text('Tiến')),
                PopupMenuItem(value: 0, child: Text(l10n.refresh)),
                PopupMenuItem(value: 1, child: Text(l10n.browser_history)),
                CheckedPopupMenuItem(value: 12, checked: t.desktop, child: const Text('Chế độ máy tính')),
                CheckedPopupMenuItem(
                    value: 13,
                    checked: !siteAllowed && YomiAdBlock.enabled,
                    enabled: YomiAdBlock.enabled,
                    child: const Text('Chặn quảng cáo trang này')),
                const PopupMenuItem(value: 14, child: Text('Cài đặt chặn quảng cáo')),
                PopupMenuItem(value: 2, child: Text(l10n.open_in_browser)),
                PopupMenuItem(value: 3, child: Text(l10n.clear_cookie)),
                PopupMenuItem(value: 4, child: Text(l10n.clear_browser_history)),
                if (_geckoOk)
                  CheckedPopupMenuItem(
                    value: 17,
                    checked: t.gecko,
                    child: const Text('Tab này dùng nhân Firefox (Gecko)'),
                  ),
                const PopupMenuItem(value: 18, child: Text('Savior – danh sách tải')),
                const PopupMenuItem(value: 30, child: Text('Web Scanner – kiểm tra trang này')),
                const PopupMenuItem(value: 15, child: Text('Nhân trình duyệt')),
                const PopupMenuItem(value: 16, child: Text('Mở bằng Firefox')),
              ],
              onSelected: (v) async {
                switch (v) {
                  case 10:
                    _openTab(_home);
                  case 11:
                    _forward(t);
                  case 0:
                    _reload(t);
                  case 17:
                    setState(() {
                      t.gecko = !t.gecko;
                      t.c = null;
                      t.g = null;
                      t.canBack = false;
                      t.canForward = false;
                    });
                  case 1:
                    _showHistory();
                  case 12:
                    t.desktop = !t.desktop;
                    await _applySettings(t);
                    setState(() {});
                  case 13:
                    final h = YomiAdBlock.hostOf(t.url);
                    if (siteAllowed) {
                      YomiAdBlock.allowed.remove(h);
                    } else {
                      YomiAdBlock.allowed.add(h);
                    }
                    await YomiAdBlock.save();
                    await _applySettings(t);
                    setState(() {});
                  case 14:
                    _adblockSettings();
                  case 2:
                    launchUrl(_toUri(t.url), mode: LaunchMode.externalApplication);
                  case 3:
                    await CookieManager.instance().deleteAllCookies();
                    MClient.deleteAllCookies(t.url);
                  case 4:
                    await BrowserHistory.clear();
                    if (t.gecko) {
                      await t.g?.clearHistory();
                    } else {
                      await t.c?.clearHistory();
                    }
                  case 18:
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SaviorScreen()));
                  case 30:
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => WebScannerScreen(initialUrl: t.url)));
                  case 15:
                    _engineInfo();
                  case 16:
                    // Firefox for Android registers this scheme.
                    final ok = await launchUrl(Uri.parse('firefox://open-url?url=${Uri.encodeComponent(t.url)}'),
                        mode: LaunchMode.externalApplication).catchError((_) => false);
                    if (!ok) {
                      launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=org.mozilla.firefox'),
                          mode: LaunchMode.externalApplication);
                    }
                }
              },
            ),
          ],
          bottom: t.progress < 1
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(value: t.progress, minHeight: 2),
                )
              : null,
        ),
        body: IndexedStack(
          index: _cur,
          children: [for (final x in _tabs) _webView(x)],
        ),
        floatingActionButton: t.media.isEmpty
            ? null
            : FloatingActionButton.small(
                tooltip: 'Savior – tải media trên trang',
                onPressed: () => _saviorSheet(t),
                child: Badge(
                  label: Text('${t.media.length}'),
                  child: const Icon(Icons.download),
                ),
              ),
      ),
    );
  }
}
