import 'dart:convert';

// 0.5.9: built-in "Sign in with Google" for Drive backup (Google Cloud project
// `yomihub`). Values are injected at build time from secrets/google_oauth.json
// (git-ignored) via --dart-define, so they never live in the public source.
// Installed-app client secrets are not confidential per Google's OAuth guide
// for native apps; PKCE is used on the loopback flow anyway.
class YomiGoogleOAuth {
  static const tvClientId = String.fromEnvironment('YH_GOOGLE_TV_CLIENT_ID');
  static const tvClientSecret = String.fromEnvironment('YH_GOOGLE_TV_CLIENT_SECRET');
  static const desktopClientId = String.fromEnvironment('YH_GOOGLE_DESKTOP_CLIENT_ID');
  static const desktopClientSecret = String.fromEnvironment('YH_GOOGLE_DESKTOP_CLIENT_SECRET');

  static bool get hasDeviceClient => tvClientId.isNotEmpty;
  static bool get hasDesktopClient => desktopClientId.isNotEmpty;

  /// drive.file = only files/folders this app created; openid+email to show
  /// which Google account is signed in. All three are allowed for the device
  /// flow and are non-sensitive (no Google verification needed).
  static const scopes = 'openid email https://www.googleapis.com/auth/drive.file';

  /// Reads the `email` claim from a Google id_token (no signature check: the
  /// token came straight from oauth2.googleapis.com over TLS).
  static String? emailFromIdToken(String? idToken) {
    if (idToken == null) return null;
    final parts = idToken.split('.');
    if (parts.length < 2) return null;
    try {
      final norm = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final pad = norm.padRight(norm.length + (4 - norm.length % 4) % 4, '=');
      final json = utf8.decode(base64.decode(pad));
      final m = RegExp(r'"email"\s*:\s*"([^"]+)"').firstMatch(json);
      return m?.group(1);
    } catch (_) {
      return null;
    }
  }

}
