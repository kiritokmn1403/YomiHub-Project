import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;
import 'package:mangayomi/yomihub/browser/webview_safe.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/playbooks/playbooks_toggle.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.3.3: "Play Books" – Google Play Books next to Comic,
/// Film & Movie and Novel.
///
/// Features authentic Material 3 UI inspired by the Google Play Books Android app:
/// - Material 3 Top Search Bar ("Tìm kiếm trên Play Sách")
/// - Filter Chips (Ebook, Sách nói, Truyện tranh, Bán chạy, Miễn phí)
/// - Bottom Navigation Bar (Trang chủ, Thư viện, Cửa hàng, Sách nói)
/// - Dedicated Play Books Settings access
/// - Embedded WebView with desktop/mobile toggle, persistent session & safe back navigation.
class PlayBooksScreen extends StatefulWidget {
  const PlayBooksScreen({super.key});

  @override
  State<PlayBooksScreen> createState() => _PlayBooksScreenState();
}

class _PlayBooksScreenState extends State<PlayBooksScreen>
    with AutomaticKeepAliveClientMixin {
  static const _homeUrl = 'https://play.google.com/books';
  static const _libraryUrl = 'https://play.google.com/books';
  static const _shopUrl = 'https://play.google.com/store/books';
  static const _audiobooksUrl =
      'https://play.google.com/store/books/category/audiobooks';
  static const _comicsUrl =
      'https://play.google.com/store/books/category/comics';
  static const _freeUrl = 'https://play.google.com/store/search?q=free&c=books';
  static const _topUrl = 'https://play.google.com/store/books/top';

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';

  InAppWebViewController? _c;
  final TextEditingController _searchCtrl = TextEditingController();
  double _progress = 0;
  bool _desktopMode = YomiPrefs.get<bool>('playBooksDesktop', true);
  late final String _start = YomiPrefs.get<String>('playBooksLast', _homeUrl);
  int _navIndex = 0;
  String _activeChip = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _allowed(Uri? u) {
    final h = u?.host ?? '';
    return h.isEmpty ||
        const [
          'google.com',
          'googleusercontent.com',
          'gstatic.com',
          'googleapis.com',
          'youtube.com',
          'ggpht.com',
        ].any((domain) => h == domain || h.endsWith('.$domain'));
  }

  Future<void> _go(String url) async {
    await _c?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _onSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final searchUrl =
        'https://play.google.com/store/search?q=${Uri.encodeComponent(q)}&c=books';
    _go(searchUrl);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    if (!YomiPlayBooks.enabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Google Play Books')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              tr(
                'Google Play Books đang tắt. Bật lại trong Cài đặt > Google Play Books.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(108),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Material 3 Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: cs.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _onSearch,
                          decoration: InputDecoration(
                            hintText: tr('Tìm kiếm trên Play Sách'),
                            hintStyle: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        ),
                      IconButton(
                        tooltip: tr('Cài đặt Play Books'),
                        icon: const Icon(Icons.tune, size: 20),
                        onPressed: () => context.push('/playBooksSettings'),
                      ),
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (v) async {
                          switch (v) {
                            case 0:
                              await _c?.reload();
                            case 1:
                              if (await _c?.safeCanGoBack() ?? false) {
                                await _c?.safeGoBack();
                              }
                            case 2:
                              setState(() => _desktopMode = !_desktopMode);
                              await YomiPrefs.set(
                                'playBooksDesktop',
                                _desktopMode,
                              );
                              await _c?.setSettings(
                                settings: InAppWebViewSettings(
                                  userAgent: _desktopMode ? _ua : '',
                                  preferredContentMode: _desktopMode
                                      ? UserPreferredContentMode.DESKTOP
                                      : UserPreferredContentMode.RECOMMENDED,
                                ),
                              );
                              await _c?.reload();
                            case 3:
                              final u = await _c?.getUrl();
                              if (u != null) {
                                await launchUrl(
                                  u,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            case 4:
                              if (mounted) context.push('/playBooksSettings');
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 0, child: Text(tr('Tải lại'))),
                          PopupMenuItem(value: 1, child: Text(tr('Quay lại'))),
                          CheckedPopupMenuItem(
                            value: 2,
                            checked: _desktopMode,
                            child: Text(
                              tr('Giao diện máy tính (trình đọc đầy đủ)'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 3,
                            child: Text(tr('Mở bằng trình duyệt ngoài')),
                          ),
                          PopupMenuItem(
                            value: 4,
                            child: Text(tr('Cài đặt Play Books')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips row (Ebook, Sách nói, Truyện tranh, Bán chạy nhất, Miễn phí)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildChip('Ebook', Icons.menu_book, _shopUrl),
                    _buildChip('Sách nói', Icons.headphones, _audiobooksUrl),
                    _buildChip('Truyện tranh', Icons.auto_stories, _comicsUrl),
                    _buildChip('Bán chạy nhất', Icons.trending_up, _topUrl),
                    _buildChip('Miễn phí', Icons.money_off, _freeUrl),
                  ],
                ),
              ),

              if (_progress < 1)
                LinearProgressIndicator(value: _progress, minHeight: 2)
              else
                const SizedBox(height: 2),
            ],
          ),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _c?.safeCanGoBack() ?? false) {
            await _c?.safeGoBack();
          }
        },
        child: InAppWebView(
          webViewEnvironment: Platform.isWindows ? webViewEnvironment : null,
          initialUrlRequest: URLRequest(url: WebUri(_start)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            thirdPartyCookiesEnabled: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            supportZoom: true,
            builtInZoomControls: true,
            displayZoomControls: false,
            userAgent: _desktopMode ? _ua : '',
            preferredContentMode: _desktopMode
                ? UserPreferredContentMode.DESKTOP
                : UserPreferredContentMode.RECOMMENDED,
            useWideViewPort: true,
            loadWithOverviewMode: true,
          ),
          onWebViewCreated: (c) => _c = c,
          onProgressChanged: (_, p) {
            if (mounted) setState(() => _progress = p / 100);
          },
          shouldOverrideUrlLoading: (c, a) async {
            final u = a.request.url;
            if (u == null) return NavigationActionPolicy.ALLOW;
            if (u.scheme == 'intent' || u.scheme == 'market') {
              return NavigationActionPolicy.CANCEL;
            }
            if (!_allowed(u)) {
              await launchUrl(u, mode: LaunchMode.externalApplication);
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (c, u) async {
            final s = u?.toString() ?? '';
            if (s.contains('play.google.com/books') ||
                s.contains('play.google.com/store/books')) {
              await YomiPrefs.set('playBooksLast', s);
            }
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (idx) {
          setState(() {
            _navIndex = idx;
            _activeChip = '';
          });
          switch (idx) {
            case 0:
              _go(_homeUrl);
            case 1:
              _go(_libraryUrl);
            case 2:
              _go(_shopUrl);
            case 3:
              _go(_audiobooksUrl);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: tr('Trang chủ'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_library_outlined),
            selectedIcon: const Icon(Icons.local_library),
            label: tr('Thư viện'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: tr('Cửa hàng'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.headphones_outlined),
            selectedIcon: const Icon(Icons.headphones),
            label: tr('Sách nói'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, String targetUrl) {
    final isSelected = _activeChip == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(icon, size: 16),
        label: Text(tr(label), style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onSelected: (val) {
          setState(() => _activeChip = val ? label : '');
          _go(targetUrl);
        },
      ),
    );
  }
}
