import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/utils/item_type_filters.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/repos/repo_discovery.dart';

int testYhStatus(dynamic t) {
  try {
    if (t == null) return 5;
    if (t is num) {
      if (t >= 0 && t <= 5) return t.toInt();
      t = t.toString();
    } else if (t is Map) {
      t = (t['name'] ?? t['status'] ?? t['title'] ?? t['label'] ?? '').toString();
    } else {
      t = t.toString();
    }
    final s = (t as String).toLowerCase();
    if (RegExp(r'hoàn|complete|full|finished|đã kết thúc').hasMatch(s)) return 1;
    if (RegExp(r'tạm ngưng|hiatus|drop').hasMatch(s)) return 2;
    if (RegExp(r'đang|ongoing|airing|updating|cập nhật').hasMatch(s)) return 0;
    return 5;
  } catch (_) {
    return 5;
  }
}

String resolveImageUrl(String url, Map<String, String>? headers) {
  var resolvedUrl = url.trim();
  if (resolvedUrl.startsWith('//')) {
    resolvedUrl = 'https:$resolvedUrl';
  } else if (resolvedUrl.startsWith('/') || (!resolvedUrl.startsWith('http://') && !resolvedUrl.startsWith('https://'))) {
    final ref = headers?['Referer'] ?? headers?['referer'] ?? headers?['Origin'] ?? headers?['origin'];
    if (ref != null && ref.isNotEmpty) {
      final refUri = Uri.tryParse(ref);
      if (refUri != null && refUri.hasScheme && refUri.hasAuthority) {
        final slash = resolvedUrl.startsWith('/') ? '' : '/';
        resolvedUrl = '${refUri.scheme}://${refUri.authority}$slash$resolvedUrl';
      }
    }
  }
  return resolvedUrl;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('YomiHub 0.4.8', () {
    test('AppIdentity reports version 0.4.8', () {
      expect(AppIdentity.userAgent, 'YomiHub/0.4.8');
    });

    test('yhStatus handles diverse inputs without throwing', () {
      expect(testYhStatus(null), 5);
      expect(testYhStatus(0), 0);
      expect(testYhStatus(1), 1);
      expect(testYhStatus('Đang phát sóng'), 0);
      expect(testYhStatus('Hoàn thành'), 1);
      expect(testYhStatus('Tạm ngưng'), 2);
      expect(testYhStatus({'status': 'Complete'}), 1);
      expect(testYhStatus({'label': 'Ongoing'}), 0);
      expect(testYhStatus(['unexpected', 'array']), 5);
      expect(testYhStatus(Object()), 5);
    });

    test('Relative image URLs resolve correctly against Referer / Origin', () {
      expect(resolveImageUrl('//cdn.example.com/img.jpg', null), 'https://cdn.example.com/img.jpg');
      expect(
        resolveImageUrl('/media/poster.png', {'Referer': 'https://phim.example.com/watch/1'}),
        'https://phim.example.com/media/poster.png',
      );
      expect(
        resolveImageUrl('thumbnails/vol1.jpg', {'Origin': 'https://truyen.example.org'}),
        'https://truyen.example.org/thumbnails/vol1.jpg',
      );
    });

    test('RepoDiscovery contains vBook extension repositories', () {
      expect(YomiRepoDiscovery.sites.values, contains('vBook Extensions'));
      expect(YomiRepoDiscovery.sites.values, contains('vBook Community Plugins'));
    });

    test('hiddenItemTypes correctly hides Comic, Anime, and Novel case-insensitively', () {
      expect(hiddenItemTypes([]), [ItemType.manga, ItemType.anime, ItemType.novel]);
      expect(hiddenItemTypes(['/MangaLibrary']), [ItemType.anime, ItemType.novel]);
      expect(hiddenItemTypes(['/mangaLibrary']), [ItemType.anime, ItemType.novel]);
      expect(hiddenItemTypes(['/AnimeLibrary']), [ItemType.manga, ItemType.novel]);
      expect(hiddenItemTypes(['/animeLibrary']), [ItemType.manga, ItemType.novel]);
      expect(hiddenItemTypes(['/NovelLibrary']), [ItemType.manga, ItemType.anime]);
      expect(hiddenItemTypes(['/novelLibrary']), [ItemType.manga, ItemType.anime]);
      expect(hiddenItemTypes(['/MangaLibrary', '/NovelLibrary']), [ItemType.anime]);
    });
  });
}
