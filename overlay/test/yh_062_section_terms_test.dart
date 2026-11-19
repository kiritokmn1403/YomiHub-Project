// YomiHub 0.6.2: every app language (19 old + 48 new) has the three section
// names (Comic / Film & Movie / Novel) and the three "extension settings"
// phrases, so no language falls back to English in the Browse tabs.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

void main() {
  test('terms + sectionSettings cover every YomiTr language', () {
    for (final code in YomiTr.languages) {
      // English keeps the YomiHub names through term()'s fallback.
      final t = code == 'en'
          ? const ['Comic', 'Film & Movie', 'Novel']
          : YomiTr.terms[code];
      final s = YomiTr.sectionSettings[code];
      expect(t, isNotNull, reason: 'terms thiếu $code');
      expect(s, isNotNull, reason: 'sectionSettings thiếu $code');
      expect(t!.length, 3, reason: code);
      expect(s!.length, 3, reason: code);
      expect(t.every((x) => x.trim().isNotEmpty), isTrue, reason: code);
      expect(s.every((x) => x.trim().isNotEmpty), isTrue, reason: code);
    }
  });

  test('every YomiTr language has its yomihub_i18n json', () {
    for (final code in YomiTr.languages) {
      final f = File('assets/yomihub_i18n/$code.json');
      expect(f.existsSync(), isTrue, reason: f.path);
      expect(jsonDecode(f.readAsStringSync()), isA<Map>());
    }
  });

  test('sections() rewrites names for a new language (pl)', () {
    final old = YomiTr.lang;
    YomiTr.lang = 'pl';
    expect(YomiTr.sections('Comic'), 'Komiksy');
    expect(YomiTr.sections('Film & Movie'), 'Filmy i kino');
    expect(YomiTr.sectionSetting(2), 'Ustawienia rozszerzeń powieści');
    YomiTr.lang = old;
  });
}
