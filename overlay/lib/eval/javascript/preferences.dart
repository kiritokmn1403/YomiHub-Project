import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/browse/extension/providers/extension_preferences_providers.dart';

class JsPreferences {
  late JavascriptRuntime runtime;
  late Source? source;
  JsPreferences(this.runtime, this.source);

  void init() {
    // YomiHub 0.5.0 (logs 03/11 11:09 "MangaDex (unlocked) … getHeaders …
    // TypeError: not a function"): kegareta-sauces scripts read keys that are
    // not in their own getSourcePreferences() (custom_user_agent,
    // original_languages) and pass a default (`get(key, [])`). The Dart side
    // threw "Error when getting source preference", which QuickJS surfaced as
    // a TypeError and the source could not even be installed. A missing key
    // (or a source not saved yet) now answers null and the script's default
    // is used.
    runtime.onMessage('get', (dynamic args) {
      try {
        return getPreferenceValue(source!.id!, args[0]);
      } catch (_) {
        return null;
      }
    });
    runtime.onMessage('getString', (dynamic args) {
      try {
        return getSourcePreferenceStringValue(source!.id!, args[0], args[1]);
      } catch (_) {
        return args.length > 1 ? args[1] : null;
      }
    });
    runtime.onMessage('setString', (dynamic args) {
      return setSourcePreferenceStringValue(source!.id!, args[0], args[1]);
    });

    runtime.evaluate('''
class SharedPreferences {
    get(key, defaultValue) {
        const v = sendMessage(
            "get",
            JSON.stringify([key])
        );
        return (v === null || v === undefined) && defaultValue !== undefined ? defaultValue : v;
    }
    getString(key, defaultValue) {
        return sendMessage(
            "getString",
            JSON.stringify([key, defaultValue])
        );
    }
    setString(key, defaultValue) {
        return sendMessage(
            "setString",
            JSON.stringify([key, defaultValue])
        );
    }
}
''');
  }
}
