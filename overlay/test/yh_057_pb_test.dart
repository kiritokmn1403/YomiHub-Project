// YomiHub 0.5.7 – gói PB: Feature Check 36 (Google Play Books đối chiếu 21 ảnh mẫu).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String p) => File(p).readAsStringSync();

void main() {
  final src = _read('lib/yomihub/playbooks/play_books_screen.dart');

  test('thanh điều hướng theo ảnh mẫu: Trang chủ, Thư viện, Danh sách yêu thích, Cửa hàng', () {
    final i1 = src.indexOf("tr('Trang chủ')");
    final i2 = src.indexOf("tr('Thư viện')");
    final i3 = src.indexOf("tr('Danh sách yêu thích')");
    final i4 = src.indexOf("tr('Cửa hàng')");
    expect(i1, greaterThan(0));
    expect(i2, greaterThan(i1));
    expect(i3, greaterThan(i2));
    expect(i4, greaterThan(i3));
    expect(src.contains('Icons.headphones_outlined'), isFalse,
        reason: 'Sách nói không còn là mục thanh dưới');
    expect(src.contains('_wishlistUrl'), isTrue);
  });

  test('Trang chủ có hai tab Sách điện tử | Sách nói', () {
    expect(src.contains('_homeTabs(cs)'), isTrue);
    expect(src.contains("'Sách điện tử'"), isTrue);
    expect(src.contains("tab(1, 'Sách nói', _audiobooksUrl)"), isTrue);
  });

  test('ô tìm kiếm "Tìm kiếm trên Play Sách" và Android TV vẫn gỡ Play Books', () {
    expect(src.contains("tr('Tìm kiếm trên Play Sách')"), isTrue);
    final router = _read('lib/router/router.dart');
    expect(router.contains('_TvRemovedScreen'), isTrue);
  });

  test('khóa mới có đủ 18 ngôn ngữ', () {
    for (final l in ['ar','as','de','en','es','es_419','fr','hi','id','it',
        'ja','ko','pt','pt_BR','ru','th','tr','zh']) {
      final m = jsonDecode(_read('assets/yomihub_i18n/$l.json')) as Map;
      expect(m['Sách điện tử'], isNotNull, reason: l);
      expect(m['Danh sách yêu thích'], isNotNull, reason: l);
    }
  });
}
