import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// YomiHub 0.2.2: WebView controller calls that cannot throw.
///
/// logs 3 (08/10): "MissingPluginException(No implementation found for method
/// canGoBack on channel com.pichillilorenzo/flutter_inappwebview_2)" reached
/// runZonedGuarded on /mangaHome – the Back key / a progress callback asked a
/// WebView that had already been disposed (tab switched, screen closed).
extension YomiSafeWebView on InAppWebViewController {
  Future<bool> safeCanGoBack() async {
    try {
      return await canGoBack();
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> safeCanGoForward() async {
    try {
      return await canGoForward();
    } catch (_) {
      return false;
    }
  }

  Future<void> safeGoBack() async {
    try {
      await goBack();
    } catch (_) {}
  }

  Future<String?> safeTitle() async {
    try {
      return await getTitle();
    } catch (_) {
      return null;
    }
  }

  Future<WebUri?> safeUrl() async {
    try {
      return await getUrl();
    } catch (_) {
      return null;
    }
  }
}

/// True for errors of a WebView that no longer exists (harmless).
bool yomiIsDeadWebViewError(Object e) {
  final t = e.toString();
  return e is MissingPluginException && t.contains('flutter_inappwebview');
}
