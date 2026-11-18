import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/utils/log/logger.dart';

void main() {
  final t = DateTime(2026, 11, 18, 7, 36, 32);
  test('every line carries app version, device and OS after the level', () {
    final tag = AppLogger.buildTag('0.5.9 (2052)', 'Xiaomi 25069PTEBG, Android 16 (SDK 36)');
    final line = AppLogger.formatLine(t, LogLevel.warning, 'Tor kẹt', tag);
    expect(line,
        '[18/11/2026 07:36:32][WARNING][YH 0.5.9 (2052) • Xiaomi 25069PTEBG, Android 16 (SDK 36)] Tor kẹt');
  });
  test('log screen parsing still sees a new entry ([..][ prefix)', () {
    final line = AppLogger.formatLine(t, LogLevel.error, 'x', AppLogger.buildTag('0.5.9 (2052)', 'Windows 11 x64'));
    expect(line.startsWith('[') && line.contains(']['), isTrue);
    expect(line.contains('[ERROR]'), isTrue);
  });
  test('no tag known → old format', () {
    expect(AppLogger.formatLine(t, LogLevel.info, 'a', ''), '[18/11/2026 07:36:32][INFO] a');
  });
}
