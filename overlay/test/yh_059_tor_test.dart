import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/vpn/tor_fallback.dart';

void main() {
  const avail = ['snowflake', 'obfs4', 'meek'];
  test('no remembered transport: user choice first (unchanged behaviour)', () {
    expect(TorBridgeFallback.order('snowflake', avail), ['snowflake', 'obfs4', 'meek', '']);
  });
  test('obfs4 rescued last session → tried first, snowflake second (log 17/11)', () {
    expect(TorBridgeFallback.order('snowflake', avail, lastGood: 'obfs4'), ['obfs4', 'snowflake', 'meek', '']);
  });
  test('remembered transport without bridge lines is ignored', () {
    expect(TorBridgeFallback.order('snowflake', ['snowflake'], lastGood: 'obfs4'), ['snowflake', '']);
  });
  final now = DateTime(2026, 11, 18, 8);
  test('validLastGood: fresh entry for same choice', () {
    expect(TorBridgeFallback.validLastGood({'kind': 'obfs4', 'chosen': 'snowflake', 'at': now.subtract(const Duration(hours: 5)).toIso8601String()}, 'snowflake', now), 'obfs4');
  });
  test('validLastGood: stale (>3 days) or other choice → null', () {
    expect(TorBridgeFallback.validLastGood({'kind': 'obfs4', 'chosen': 'snowflake', 'at': now.subtract(const Duration(days: 4)).toIso8601String()}, 'snowflake', now), isNull);
    expect(TorBridgeFallback.validLastGood({'kind': 'obfs4', 'chosen': 'meek', 'at': now.toIso8601String()}, 'snowflake', now), isNull);
    expect(TorBridgeFallback.validLastGood(null, 'snowflake', now), isNull);
  });
}
