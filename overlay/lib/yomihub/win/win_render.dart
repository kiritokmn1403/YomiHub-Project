// YomiHub 0.5.7 (U14 / R21) – Windows render mode ("cửa sổ trắng").
//
// The native runner (windows/runner/main.cpp, namespace yh_render) reads
// %APPDATA%\YomiHub\win_render.ini before it creates the Flutter engine and
// writes what happened to win_render_state.txt. This file is the Dart side:
// plain dart:io, no plugins, so it can be unit-tested on any platform by
// passing a directory.
import 'dart:io';

class WinRenderConfig {
  const WinRenderConfig({this.mode = 'auto', this.impeller = false, this.autoRecover = false, this.present = 'flip'});

  /// auto | igpu | dgpu
  final String mode;
  final bool impeller;

  /// Relaunch with another mode when the view stays one flat colour.
  /// 0.5.7.1 (R21): off unless asked for (auto=1) – changing GPU / renderer
  /// was measured not to cure the white window; the flip-model swap chain
  /// ([present]) does.
  final bool autoRecover;

  /// flip (default: flip-model swap chain, the R21 fix) | blt (stock Flutter).
  final String present;

  WinRenderConfig copyWith({String? mode, bool? impeller, bool? autoRecover, String? present}) => WinRenderConfig(
        mode: mode ?? this.mode,
        impeller: impeller ?? this.impeller,
        autoRecover: autoRecover ?? this.autoRecover,
        present: present ?? this.present,
      );

  String encode() =>
      'mode=$mode\r\nimpeller=${impeller ? 1 : 0}\r\nauto=${autoRecover ? 1 : 0}\r\npresent=$present\r\n';

  static WinRenderConfig decode(String text) {
    final kv = WinRender.parse(text);
    final m = kv['mode'] ?? 'auto';
    return WinRenderConfig(
      mode: (m == 'igpu' || m == 'dgpu') ? m : 'auto',
      impeller: kv['impeller'] == '1',
      autoRecover: kv['auto'] == '1',
      present: kv['present'] == 'blt' ? 'blt' : 'flip',
    );
  }
}

class WinRender {
  WinRender._();

  static const configName = 'win_render.ini';
  static const stateName = 'win_render_state.txt';

  /// %APPDATA%\YomiHub, or null when APPDATA is not set (not Windows).
  static String? get defaultDir {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) return null;
    return '$appData${Platform.pathSeparator}YomiHub';
  }

  static Map<String, String> parse(String text) {
    final out = <String, String>{};
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      final i = line.indexOf('=');
      if (i <= 0) continue;
      out[line.substring(0, i)] = line.substring(i + 1);
    }
    return out;
  }

  static WinRenderConfig readConfig({String? dir}) {
    final d = dir ?? defaultDir;
    if (d == null) return const WinRenderConfig();
    try {
      final f = File('$d${Platform.pathSeparator}$configName');
      if (!f.existsSync()) return const WinRenderConfig();
      return WinRenderConfig.decode(f.readAsStringSync());
    } catch (_) {
      return const WinRenderConfig();
    }
  }

  static bool writeConfig(WinRenderConfig cfg, {String? dir}) {
    final d = dir ?? defaultDir;
    if (d == null) return false;
    try {
      Directory(d).createSync(recursive: true);
      File('$d${Platform.pathSeparator}$configName').writeAsStringSync(cfg.encode(), flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// What the runner recorded for the last start (empty when never written).
  static Map<String, String> readState({String? dir}) {
    final d = dir ?? defaultDir;
    if (d == null) return const {};
    try {
      final f = File('$d${Platform.pathSeparator}$stateName');
      if (!f.existsSync()) return const {};
      return parse(f.readAsStringSync());
    } catch (_) {
      return const {};
    }
  }

  /// One line for the log / diagnostics screen, e.g.
  /// "ok • attempt 1 • dgpu • impeller 0 • blank 2 • 2026-11-15 01:00:00".
  static String describe(Map<String, String> st) {
    if (st.isEmpty) return '';
    return '${st['result'] ?? '?'} • attempt ${st['attempt'] ?? '?'} • ${st['gpu'] ?? '?'}'
        ' • impeller ${st['impeller'] ?? '?'} • blank ${st['blank_count'] ?? '0'}'
        '${st['present'] == null ? '' : ' • present ${st['present']}'}'
        '${st['time'] == null ? '' : ' • ${st['time']}'}';
  }
}
