import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.1.5: "Play Books" – Google Play Books next to Comic,
/// Film & Movie and Novel.
///
/// Same idea as Google-Play-Books-Desktop (TheLox95), which wraps
/// play.google.com/books in an Electron window: here the web app runs in an
/// embedded WebView (Chromium on Android, WebView2 on Windows) with a
/// persistent Google sign-in, a desktop-class user agent so the full web
/// reader (EPUB/PDF, highlights, bookmarks, sync) is served, quick tabs for
/// Library / Shop / Reading now, and the last opened page restored.
class PlayBooksScreen extends StatefulWidget {
  const PlayBooksScreen({super.key});

  @override
  State<PlayBooksScreen> createState() => _PlayBooksScreenState();
}

class _PlayBooksScreenState extends State<PlayBooksScreen>
    with AutomaticKeepAliveClientMixin {
  static const _library = 'https://play.google.com/books';
  static const _shop = 'https://play.google.com/store/books';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';
  InAppWebViewController? _c;
  double _progress = 0;
  bool _desktopMode = YomiPrefs.get<bool>('playBooksDesktop', true);
  late String _start = YomiPrefs.get<String>('playBooksLast', _library);

  @override
  bool get wantKeepAlive => true;

  bool _allowed(Uri? u) {
    final h = u?.host ?? '';
    return h.endsWith('google.com') ||
        h.endsWith('googleusercontent.com') ||
        h.endsWith('gstatic.com') ||
        h.endsWith('googleapis.com') ||
        h.endsWith('youtube.com') ||
        h.endsWith('ggpht.com') ||
        h.isEmpty;
  }

  Future<void> _go(String url) async =>
      _c?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Play Books'),
        actions: [
          IconButton(
            tooltip: 'Thư viện',
            icon: const Icon(Icons.local_library_outlined),
            onPressed: () => _go(_library),
          ),
          IconButton(
            tooltip: 'Cửa hàng sách',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => _go(_shop),
          ),
          PopupMenuButton<int>(
            onSelected: (v) async {
              switch (v) {
                case 0:
                  await _c?.reload();
                case 1:
                  if (await _c?.canGoBack() ?? false) await _c?.goBack();
                case 2:
                  setState(() => _desktopMode = !_desktopMode);
                  await YomiPrefs.set('playBooksDesktop', _desktopMode);
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
                    await launchUrl(u, mode: LaunchMode.externalApplication);
                  }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 0, child: Text('Tải lại')),
              const PopupMenuItem(value: 1, child: Text('Quay lại')),
              CheckedPopupMenuItem(
                value: 2,
                checked: _desktopMode,
                child: const Text('Giao diện máy tính (trình đọc đầy đủ)'),
              ),
              const PopupMenuItem(value: 3, child: Text('Mở bằng trình duyệt ngoài')),
            ],
          ),
        ],
        bottom: _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress, minHeight: 2),
              )
            : null,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _c?.canGoBack() ?? false) {
            await _c?.goBack();
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
    );
  }
}
