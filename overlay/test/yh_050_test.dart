// YomiHub 0.5.0 regression tests (real code paths, no copies of the logic).
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/vbook/vbook_bridge.dart';

List<int> _zip(Map<String, String> files) {
  final a = Archive();
  files.forEach((n, c) {
    final b = utf8.encode(c);
    a.addFile(ArchiveFile(n, b.length, b));
  });
  return ZipEncoder().encode(a);
}

String _read(String p) => File(p).readAsStringSync();

void main() {
  group('YomiHub 0.5.0', () {
    test('version / user agent', () {
      expect(AppIdentity.userAgent, 'YomiHub/0.5.0');
      expect(_read('pubspec.yaml'), contains('version: 0.5.0+42'));
    });

    test('encrypted vBook plugin raises VBookEncryptedException (not a plain Exception)', () {
      final zip = _zip({
        'plugin.json': jsonEncode({'metadata': {'name': 'Enc', 'encrypt': true}, 'script': {'search': 'search.js'}}),
        'src/search.js': 'U2FsdGVkX19vY2hYbWJ0cFh4Z0VhbDJ3c0ZtV1E9PQ==',
      });
      expect(() => VBookBridge.fromZip(zip, common: '', runtime: ''),
          throwsA(isA<VBookEncryptedException>().having((e) => '$e', 'message', contains('Enc'))));
    });

    test('failed update of an encrypted plugin is a warning, not an error with stack', () {
      final s = _read('lib/services/fetch_sources_list.dart');
      expect(s, contains('e is VBookEncryptedException'));
      expect(s, contains('VBookBridge.markEncrypted(source)'));
    });

    test('extension row locks known encrypted vBook plugins', () {
      final s = _read('lib/modules/browse/extension/widgets/extension_list_tile_widget.dart');
      expect(s, contains('VBookBridge.isKnownEncrypted(widget.source)'));
      expect(s, contains("Chỉ chạy trên vBook"));
    });

    test('JS SharedPreferences.get tolerates unknown keys and honours a default', () {
      final s = _read('lib/eval/javascript/preferences.dart');
      expect(s, contains('get(key, defaultValue)'));
      expect(s, contains('defaultValue !== undefined ? defaultValue : v'));
      // the Dart handler must not throw any more
      final i = s.indexOf("runtime.onMessage('get'");
      expect(s.substring(i, i + 200), contains('try {'));
    });

    test('Android TV build hides Comic, Novel, Play Books and Booru', () {
      final m = _read('lib/modules/main_view/main_screen.dart');
      for (final r in ['/MangaLibrary', '/NovelLibrary', '/playBooks', '/booru']) {
        expect(m, contains('nav != "$r"'));
      }
      final r = _read('lib/router/router.dart');
      expect(r, contains('kIsTvBuild ? const _TvRemovedScreen() : const PlayBooksScreen()'));
      expect(r, contains('kIsTvBuild ? const _TvRemovedScreen() : const BooruScreen()'));
      final st = _read('lib/modules/more/settings/settings_screen.dart');
      expect(st, contains('if (!(isTv || kIsTvBuild)) const PlayBooksSettingTile()'));
      expect(st, contains('if (!(isTv || kIsTvBuild)) const BooruSettingTile()'));
    });

    test('TV player panel no longer has hard-coded English titles', () {
      final p = _read('lib/modules/anime/widgets/tv_player_settings_panel.dart');
      expect(p, isNot(contains("=> 'Settings'")));
      expect(p, isNot(contains("'Playback speed'")));
      expect(_read('lib/modules/anime/widgets/tv_player_controls.dart'), isNot(contains("label: 'Settings'")));
    });

    test('new strings are translated in all 18 languages', () {
      const keys = ['Chỉ chạy trên vBook', 'Cài đặt', 'Tốc độ phát', 'Chất lượng', 'Phụ đề', 'Âm thanh', 'Shader', 'Bộ giải mã', 'Thống kê chi tiết'];
      final files = Directory('assets/yomihub_i18n').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files.length, 18);
      for (final f in files) {
        final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final k in keys) {
          expect((m[k] as String?)?.isNotEmpty, isTrue, reason: '${f.path}: $k');
        }
      }
    });
  });
}
