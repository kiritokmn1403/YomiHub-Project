import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';

/// One extension that ships inside the YomiHub APK.
class BuiltinExtension {
  final int id;
  final String name;
  final String asset;
  final String baseUrl;
  final ItemType itemType;
  final String version;
  final bool nsfw;
  final String iconUrl;
  final String notes;
  const BuiltinExtension({
    required this.id,
    required this.name,
    required this.asset,
    required this.baseUrl,
    required this.itemType,
    required this.version,
    this.nsfw = false,
    this.iconUrl = '',
    this.notes = '',
  });
}

/// Installs / updates the extensions bundled with YomiHub.
///
/// They are ordinary JavaScript sources (same engine as repository
/// extensions), so filters, per-source settings (including the domain),
/// downloads, migration and backup all work the same way.
class BuiltinExtensions {
  static const _box = 'yomihub_builtin_ext';

  static const all = <BuiltinExtension>[
    BuiltinExtension(
      id: 920260001,
      name: 'Hako (Light Novel)',
      asset: 'hako.js',
      baseUrl: 'https://ln.hako.vn',
      itemType: ItemType.novel,
      version: '0.1.5',
      iconUrl: 'https://docln.sbs/img/favicon.png',
      notes: 'Hai địa chỉ: ln.hako.vn và docln.sbs. Mặc định tự chuyển sang docln.sbs khi ln.hako.vn bị chặn (đổi trong cài đặt tiện ích).',
    ),
    BuiltinExtension(
      id: 920260012,
      name: 'Sonako (Light Novel)',
      asset: 'sonako.js',
      baseUrl: 'https://sonako.fandom.com',
      itemType: ItemType.novel,
      version: '0.1.6',
      iconUrl: 'https://static.wikia.nocookie.net/sonako/images/e/e6/Site-logo.png',
      notes: 'Wiki light novel tiếng Việt trên Fandom. Lần đầu có thể phải mở WebView của tiện ích để vượt kiểm tra Cloudflare.',
    ),
    BuiltinExtension(
      id: 920260009,
      name: 'AnimeVN',
      asset: 'animevn.js',
      baseUrl: 'https://animevn.net',
      itemType: ItemType.anime,
      version: '0.1.6',
      iconUrl: 'https://animevn.net/favicon.ico',
      notes: 'Anime & hoạt hình 3D Trung Quốc Vietsub. Máy chủ nhúng (Hydrax/Abyss) được bắt luồng qua WebView ẩn; nếu không được sẽ tự chuyển sang trình phát web của trang.',
    ),
    BuiltinExtension(
      id: 920260010,
      name: 'AVSub – AnimeVietsub',
      asset: 'avsub.js',
      baseUrl: 'https://animevietsub.nl',
      itemType: ItemType.anime,
      version: '0.1.6',
      iconUrl: 'https://animevietsub.nl/favicon.ico',
      notes: 'Anime Vietsub. Máy chủ DU/HDX phát bằng trình phát web của trang (mã hoá phía trang); tự chuyển máy chủ khi lỗi. Đổi tên miền trong cài đặt tiện ích nếu trang đổi địa chỉ.',
    ),
    BuiltinExtension(
      id: 920260002,
      name: 'RoPhim',
      asset: 'rophim.js',
      baseUrl: 'https://www.rophimhd.com',
      itemType: ItemType.anime,
      version: '0.1.4',
      iconUrl: 'https://www.rophimhd.com/images/favicon.ico',
    ),
    BuiltinExtension(
      id: 920260003,
      name: 'HotPhim',
      asset: 'hotphim.js',
      baseUrl: 'https://hotphim.org',
      itemType: ItemType.anime,
      version: '0.1.4',
      iconUrl: 'https://hotphim.org/wp-content/uploads/2025/12/hotphim-favicon-1-280x420.png',
    ),
    BuiltinExtension(
      id: 920260004,
      name: 'Anime47',
      asset: 'anime47.js',
      baseUrl: 'https://anime47.best',
      itemType: ItemType.anime,
      version: '0.1.4',
      iconUrl: 'https://anime47.best/icons/favicon-128x128.png',
      notes: 'Xem tập phim cần đăng nhập: mở một phim, bấm Webview và đăng nhập Anime47 như trên trình duyệt.',
    ),
    BuiltinExtension(
      id: 920260005,
      name: 'VTVgo – Truyền hình',
      asset: 'vtvgo.js',
      baseUrl: 'https://vtvgo.vn',
      itemType: ItemType.anime,
      version: '0.1.4',
      iconUrl: 'https://vtvgo.vn/favicon.ico',
    ),
    BuiltinExtension(
      id: 920260006,
      name: 'YouTube (NewPipe · Pure Tuber)',
      asset: 'youtube.js',
      baseUrl: 'https://www.youtube.com',
      itemType: ItemType.anime,
      version: '0.1.4',
      iconUrl: 'https://www.gstatic.com/youtube/img/branding/favicon/favicon_144x144.png',
      notes: 'Xem YouTube không quảng cáo, không cần đăng nhập; hỗ trợ kênh, danh sách phát, phụ đề và tải xuống.',
    ),
    BuiltinExtension(
      id: 920260007,
      name: 'Pornhub (18+)',
      asset: 'pornhub.js',
      baseUrl: 'https://www.pornhub.com',
      itemType: ItemType.anime,
      version: '0.1.4',
      nsfw: true,
      notes: 'Bị nhà mạng chặn ở Việt Nam: bật DNS-over-HTTPS hoặc VPN.',
    ),
    BuiltinExtension(
      id: 920260008,
      name: 'FikFap (18+)',
      asset: 'fikfap.js',
      baseUrl: 'https://fikfap.com',
      itemType: ItemType.anime,
      version: '0.1.4',
      nsfw: true,
      notes: 'Bị nhà mạng chặn ở Việt Nam: bật DNS-over-HTTPS hoặc VPN.',
    ),
    BuiltinExtension(
      id: 920260011,
      name: 'HihiSex (18+)',
      asset: 'hihisex.js',
      baseUrl: 'https://hihisex.men',
      itemType: ItemType.anime,
      version: '0.1.4',
      nsfw: true,
      iconUrl: 'https://hihisex.men/favicon.ico',
      notes: 'Nội dung người lớn (18+). Khi luồng HLS không phát được, YomiHub tự chuyển sang trình phát của trang.',
    ),
  ];

  static Future<String> _code(BuiltinExtension e) async {
    final common = await rootBundle.loadString('assets/yomihub_extensions/_common.js');
    final body = await rootBundle.loadString('assets/yomihub_extensions/${e.asset}');
    return '$common\n$body';
  }

  /// Adds missing bundled extensions and updates outdated ones. An extension
  /// the user removed stays removed.
  static Future<void> install() async {
    try {
      final box = await Hive.openBox(_box);
      for (final e in all) {
        final existing = sourceRepository.getById(e.id);
        final seenVersion = box.get('v_${e.id}') as String?;
        if (existing == null && seenVersion != null) continue; // user uninstalled it
        if (existing != null && seenVersion == e.version && (existing.sourceCode ?? '').isNotEmpty) {
          continue;
        }
        final code = await _code(e);
        final src = existing ??
            (Source(
              id: e.id,
              name: e.name,
              lang: 'vi',
              baseUrl: e.baseUrl,
              iconUrl: e.iconUrl,
              typeSource: 'single',
              itemType: e.itemType,
              isAdded: true,
              isActive: true,
              isNsfw: e.nsfw,
              version: e.version,
              notes: e.notes,
            )..sourceCodeLanguage = SourceCodeLanguage.javascript);
        src
          ..sourceCode = code
          ..version = e.version
          ..versionLast = e.version
          ..isLocal = true
          ..notes = e.notes
          ..iconUrl = e.iconUrl
          ..isNsfw = e.nsfw
          ..sourceCodeLanguage = SourceCodeLanguage.javascript;
        await sourceRepository.save(src);
        await box.put('v_${e.id}', e.version);
      }
    } catch (_) {
      // never block startup because of a bundled extension
    }
  }
}

/// Groups of installed sources that point at the same website.
class ExtensionMergeHelper {
  static String hostOf(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      var h = Uri.parse(url.contains('://') ? url : 'https://$url').host.toLowerCase();
      for (final p in ['www.', 'm.', 'v2.', 'api.']) {
        if (h.startsWith(p)) h = h.substring(p.length);
      }
      return h;
    } catch (_) {
      return '';
    }
  }

  static String keyOf(Source s) => '${s.itemType.index}|${hostOf(s.baseUrl)}';

  /// Installed sources sharing a website, merged or not.
  static List<List<Source>> allGroups({bool includeInactive = false}) {
    final byKey = <String, List<Source>>{};
    for (final s in sourceRepository.getAll()) {
      if (!(s.isAdded ?? false)) continue;
      if (!includeInactive && !(s.isActive ?? true)) continue;
      final h = hostOf(s.baseUrl);
      if (h.isEmpty) continue;
      byKey.putIfAbsent(keyOf(s), () => []).add(s);
    }
    return byKey.values.where((g) => g.length > 1).toList();
  }

  /// Duplicate groups the user has not merged yet.
  static List<List<Source>> duplicateGroups() =>
      allGroups().where((g) => !YomiMerge.isMerged(keyOf(g.first))).toList();
}

/// YomiHub 0.1.5: non-destructive extension merging.
///
/// A merge only records which installed extension is the *primary* one for a
/// website. Every merged extension stays installed and enabled (library
/// entries, history, downloads and global search keep working); the others
/// are just folded under the primary in Browse › Sources. Merges can be
/// changed (another primary, members added/removed) or undone at any time.
class YomiMerge {
  YomiMerge._();
  static const _key = 'mergeGroups';

  /// group key ("itemType|host") → {'primary': id, 'members': [ids]}
  static Map<String, Map<String, dynamic>> get groups {
    final raw = YomiPrefs.get<Map>(_key, const {});
    return {
      for (final e in raw.entries)
        '${e.key}': Map<String, dynamic>.from(e.value as Map),
    };
  }

  static bool isMerged(String key) => groups.containsKey(key);

  static Future<void> merge(String key, int primary, List<int> members) async {
    final g = groups;
    g[key] = {'primary': primary, 'members': members};
    await YomiPrefs.set(_key, g);
  }

  static Future<void> unmerge(String key) async {
    final g = groups..remove(key);
    await YomiPrefs.set(_key, g);
  }

  /// Source ids folded under another (hidden from the Sources list only).
  static Set<int> hiddenSecondaries() {
    final out = <int>{};
    for (final g in groups.values) {
      final p = g['primary'];
      for (final m in (g['members'] as List? ?? const [])) {
        if (m != p) out.add(m as int);
      }
    }
    return out;
  }

  /// Number of extensions folded under [sourceId] (0 if not a primary).
  static int foldedUnder(int? sourceId) {
    for (final g in groups.values) {
      if (g['primary'] == sourceId) {
        return ((g['members'] as List?)?.length ?? 1) - 1;
      }
    }
    return 0;
  }
}
