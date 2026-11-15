// YomiHub 0.5.7 – gói P4: công tắc "Bảo vệ dấu vân tay" của trình duyệt trong
// ứng dụng (trước 0.5.7 chỉ lưu khóa, không nơi nào đọc).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/browser/anti_fingerprint.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('script covers canvas, audio, WebGL, navigator; keeps the User-Agent', () {
    final js = YomiAntiFingerprint.script(12345);
    for (final w in [
      'getImageData', 'toDataURL', 'toBlob', 'getChannelData', 'getFloatFrequencyData',
      '37445', '37446', "'hardwareConcurrency'", "'webdriver', false", 'location.hostname',
      'window.__yhAfp',
    ]) {
      expect(js, contains(w), reason: w);
    }
    expect(js, isNot(contains('userAgent')));
    expect(js, isNot(contains('languages')));
    expect(js, contains('2166136261 ^ 12345'));
    // balanced braces / parentheses (a broken script fails silently in a page)
    int count(String c) => c.allMatches(js).length;
    expect(count('{'), count('}'));
    expect(count('('), count(')'));
    expect(count('['), count(']'));
  });

  test('one seed per app run', () {
    expect(YomiAntiFingerprint.sessionSeed, YomiAntiFingerprint.sessionSeed);
    expect(YomiAntiFingerprint.script(1), isNot(YomiAntiFingerprint.script(2)));
  });

  test('browser tabs inject it at document start; the switch uses the same key', () {
    final b = _read('lib/yomihub/browser/browser_screen.dart');
    expect(b, contains('initialUserScripts: UnmodifiableListView(['));
    expect(b, contains('source: YomiAntiFingerprint.scriptOrEmpty(),'));
    expect(b, contains('injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START'));
    expect(b, contains('await YomiPrefs.set(YomiAntiFingerprint.prefKey, v);'));
    expect(YomiAntiFingerprint.prefKey, 'browser_fingerprint_protection');
    // the Cloudflare solver must not get it (cookie bound to the real browser)
    expect(_read('lib/yomihub/cloudflare/cf_challenge.dart'), isNot(contains('YomiAntiFingerprint')));
  });
}
