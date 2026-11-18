import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/playbooks/playbooks_toggle.dart';

void main() {
  test('Google Play Books is off on a TV layout regardless of the preference', () {
    debugIsTvOverride = true;
    addTearDown(() => debugIsTvOverride = null);
    expect(YomiPlayBooks.enabled, isFalse);
  });
}
