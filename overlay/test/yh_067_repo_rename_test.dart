import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';

void main() {
  group('0.6.7 kho tiện ích đổi tên YomiHub-Extension-Repo (Issue #2)', () {
    const idx = 'https://raw.githubusercontent.com/YomiHub-Project/YomiHub-Extension-Repo/main/repo/index.json';

    test('địa chỉ mặc định dùng tên mới', () {
      expect(BuiltinExtensions.repoJson, idx);
      expect(BuiltinExtensions.repoWebsite, 'https://github.com/YomiHub-Project/YomiHub-Extension-Repo');
      expect(BuiltinExtensions.repoName, 'YomiHub Extension Repo');
    });

    test('migrateUrl nhận cả 2 tên cũ (kiritokmn1403 và YomiHub-Project/Kiritokmn)', () {
      for (final old in [
        'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json',
        'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/index.json',
        'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/mangayomi/anime.json',
      ]) {
        expect(BuiltinExtensions.migrateUrl(old), idx, reason: old);
      }
      expect(
        BuiltinExtensions.migrateUrl('https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/yomihub/avsub.js'),
        'https://raw.githubusercontent.com/YomiHub-Project/YomiHub-Extension-Repo/main/repo/yomihub/avsub.js',
      );
      // kho khác giữ nguyên
      const kei = 'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb';
      expect(BuiltinExtensions.migrateUrl(kei), kei);
    });

    test('migrateRepos đổi cả địa chỉ lẫn tên mặc định, giữ tên người dùng tự đặt', () {
      final (out, changed) = BuiltinExtensions.migrateRepos([
        Repo(
          name: 'Kiritokmn Extension Repo',
          jsonUrl: 'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/index.json',
          hidden: true,
        ),
      ]);
      expect(changed, 1);
      expect(out.single.jsonUrl, idx);
      expect(out.single.name, 'YomiHub Extension Repo');
      expect(out.single.hidden, isTrue);

      final (out2, changed2) = BuiltinExtensions.migrateRepos([
        Repo(name: 'Kho của tôi', jsonUrl: 'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/index.json'),
      ]);
      expect(changed2, 1);
      expect(out2.single.name, 'Kho của tôi');

      // đã đúng địa chỉ mới + tên đã đổi: không còn gì để sửa
      final (_, changed3) = BuiltinExtensions.migrateRepos([Repo(name: 'YomiHub Extension Repo', jsonUrl: idx)]);
      expect(changed3, 0);
    });

    test('withRepo không thêm bản thứ hai cạnh địa chỉ tên cũ', () {
      final list = BuiltinExtensions.withRepo([
        Repo(name: 'Kiritokmn Extension Repo', jsonUrl: 'https://raw.githubusercontent.com/YomiHub-Project/Kiritokmn---Extension-Repo/main/repo/index.json'),
      ]);
      expect(list.length, 1);
    });
  });
}
