import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';

/// YomiHub 0.4.5 regression tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YomiHub 0.4.5', () {
    test('AppIdentity reports version 0.4.5', () {
      expect(AppIdentity.userAgent, 'YomiHub/0.4.5');
    });

    test('Website Extension: VTV Go mirrors include cache.vtvgo.vn', () {
      expect(YomiUrlOverride.getMirrorsFor('https://vtvgo.vn/channel/1'), contains('https://cache.vtvgo.vn'));
      expect(YomiUrlOverride.getMirrorsFor('https://cache.vtvgo.vn/'), contains('https://vtvgo.vn'));
    });

    test('Telegram: bot token never appears in error text', () {
      const token = '123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsawQ';
      final err = 'ClientException: Connection reset, uri=https://api.telegram.org/bot$token/sendDocument';
      final masked = TelegramProvider.maskToken(err, token);
      expect(masked.contains(token), isFalse);
      expect(masked, contains('bot<token>/sendDocument'));
      // also masked when the configured token differs (old token in a message)
      expect(TelegramProvider.maskToken('https://api.telegram.org/bot$token/getMe', ''), isNot(contains(token)));
    });

    test('Telegram: parts are ≤ 19 MB (getFile limit 20 MB) and regroup in order', () {
      expect(TelegramProvider.partSize, lessThan(20 * 1024 * 1024));
      final names = [for (var i = 0; i < 3; i++) TelegramProvider.partName('YomiHub_2026-10-30.backup', i, 3)];
      expect(names.first, 'YomiHub_2026-10-30.backup.part01of03');
      final m = TelegramProvider.partRe.firstMatch(names.last)!;
      expect(m[1], 'YomiHub_2026-10-30.backup');
      expect(int.parse(m[2]!), 3);
      expect(int.parse(m[3]!), 3);
      expect(TelegramProvider.partRe.hasMatch('YomiHub_2026-10-30.backup'), isFalse);
    });
  });
}
