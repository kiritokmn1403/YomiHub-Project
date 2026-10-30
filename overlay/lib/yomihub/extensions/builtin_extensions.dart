import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/utils/log/logger.dart';

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

  /// 0.2.0: language from the "Website Extension" sheet ('vi' or 'all').
  final String lang;

  /// 0.2.0: has a vertical feed for the Short Video screen.
  final bool shorts;
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
    this.lang = 'vi',
    this.shorts = false,
  });
}

/// Installs / updates the extensions bundled with YomiHub.
///
/// They are ordinary JavaScript sources (same engine as repository
/// extensions), so filters, per-source settings (including the domain),
/// downloads, migration and backup all work the same way.
class BuiltinExtensions {
  static const _box = 'yomihub_builtin_ext';

  /// 0.2.0: ids of bundled extensions with a Short Video feed.
  static final Set<int> shortsIds = {
    for (final e in all)
      if (e.shorts) e.id,
  };

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
      iconUrl:
          'https://static.wikia.nocookie.net/sonako/images/e/e6/Site-logo.png',
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
      baseUrl: 'https://animevietsub.news',
      itemType: ItemType.anime,
      version: '0.4.3',
      iconUrl: 'https://animevietsub.news/favicon.ico',
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
      version: '0.2.0',
      iconUrl: 'https://www.gstatic.com/youtube/img/branding/favicon/favicon_144x144.png',
      lang: 'all',
      shorts: true,
      notes: 'Xem YouTube không quảng cáo, không cần đăng nhập; hỗ trợ kênh, danh sách phát, phụ đề và tải xuống.',
    ),
    BuiltinExtension(
      id: 920260007,
      name: 'Pornhub (18+)',
      asset: 'pornhub.js',
      baseUrl: 'https://www.pornhub.com',
      itemType: ItemType.anime,
      version: '0.2.1',
      nsfw: true,
      lang: 'all',
      shorts: true,
      notes: 'Bị nhà mạng chặn ở Việt Nam: bật DNS-over-HTTPS hoặc VPN. Có Short Video: Shorties (pornhub.com/shorties).',
    ),
    BuiltinExtension(
      id: 920260008,
      name: 'FikFap (18+)',
      asset: 'fikfap.js',
      baseUrl: 'https://fikfap.com',
      itemType: ItemType.anime,
      version: '0.4.3',
      nsfw: true,
      lang: 'all',
      shorts: true,
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
    // YomiHub 0.2.0 – sheet "Website Extension": vertical-video sites with
    // the Short Video feed. All 18+ (hidden while NSFW is off).
    BuiltinExtension(
      id: 920260013,
      name: 'Tik.Porn (18+)',
      asset: 'tikporn.js',
      baseUrl: 'https://tik.porn',
      itemType: ItemType.anime,
      version: '0.2.0',
      nsfw: true,
      lang: 'all',
      shorts: true,
      iconUrl: 'https://tik.porn/favicon.ico',
      notes: 'Video dọc kiểu TikTok. Có Short Video. Bị chặn thì bật DoH hoặc VPN.',
    ),
    BuiltinExtension(
      id: 920260014,
      name: 'Kwiky (18+)',
      asset: 'kwiky.js',
      baseUrl: 'https://kwiky.com',
      itemType: ItemType.anime,
      version: '0.2.0',
      nsfw: true,
      lang: 'all',
      shorts: true,
      iconUrl: 'https://kwiky.com/assets/img/logo64.png',
      notes: 'Clip ngắn dọc của các cam model (kwiky.com/cams). Có Short Video; lọc theo giới tính và thẻ.',
    ),
    BuiltinExtension(
      id: 920260015,
      name: 'xFree (18+)',
      asset: 'xfree.js',
      baseUrl: 'https://www.xfree.com',
      itemType: ItemType.anime,
      version: '0.2.0',
      nsfw: true,
      lang: 'all',
      shorts: true,
      iconUrl: 'https://static.xfree.com/icons/icon_64x64.757e1c.png',
      notes: 'Porn reels dọc. Có Short Video.',
    ),
    BuiltinExtension(
      id: 920260016,
      name: 'FapReel (18+)',
      asset: 'fapreel.js',
      baseUrl: 'https://fapreel.com',
      itemType: ItemType.anime,
      version: '0.2.0',
      nsfw: true,
      lang: 'all',
      shorts: true,
      iconUrl: 'https://fapreel.com/assets/favicon-32x32.png',
      notes: 'Porn reels dọc theo chủ đề. Có Short Video.',
    ),
    BuiltinExtension(
      id: 920260017,
      name: 'SexVietTop (18+)',
      asset: 'sexviettop.js',
      baseUrl: 'https://top1sexvn.com',
      itemType: ItemType.anime,
      version: '0.2.5',
      nsfw: true,
      lang: 'vi',
      shorts: true,
      iconUrl: 'https://top1sexvn.com/favicon.ico',
      notes: 'Phim sex Việt Nam, clip ngắn nóng bỏng. Có Short Video. Cần bật DNS hoặc VPN nếu bị nhà mạng chặn.',
    ),
    BuiltinExtension(
      id: 920260018,
      name: 'HayChill',
      asset: 'haychill.js',
      baseUrl: 'https://phimhaychill.org',
      itemType: ItemType.anime,
      version: '0.2.7',
      iconUrl: 'https://haychill.tv/favicon.ico',
      notes: 'Kho phim bom tấn, phim bộ, phim lẻ Vietsub cập nhật nhanh.',
    ),
    BuiltinExtension(
      id: 920260019,
      name: 'XemPhimGi',
      asset: 'xemphimgi.js',
      baseUrl: 'https://xemphimgi.com',
      itemType: ItemType.anime,
      version: '0.2.7',
      iconUrl: 'https://xemphimgi.net/favicon.ico',
      notes: 'Phim truyền hình, phim chiếu rạp và hoạt hình chất lượng cao.',
    ),
    BuiltinExtension(
      id: 920260020,
      name: 'NextPhim',
      asset: 'nextphim.js',
      baseUrl: 'https://nextphim.net',
      itemType: ItemType.anime,
      version: '0.2.7',
      iconUrl: 'https://nextphim.com/favicon.ico',
      notes: 'Tổng hợp phim bộ, phim lẻ Châu Á và Âu Mỹ mới nhất.',
    ),
    BuiltinExtension(
      id: 920260021,
      name: 'Vfilm',
      asset: 'vfilm.js',
      baseUrl: 'http://vfilm.vn',
      itemType: ItemType.anime,
      version: '0.2.7',
      iconUrl: 'https://vfilm.tv/favicon.ico',
      notes: 'Phim HD vietsub, lồng tiếng đa dạng thể loại.',
    ),
    BuiltinExtension(
      id: 920260022,
      name: 'CBHentai (18+)',
      asset: 'cbhentai.js',
      baseUrl: 'https://hentaicube.xyz',
      itemType: ItemType.manga,
      version: '0.2.8',
      nsfw: true,
      lang: 'vi',
      iconUrl: 'https://hentaicube.xyz/favicon.ico',
      notes: 'Kho truyện tranh Hentai, Manga 18+ Vietsub. Địa chỉ phụ: 2tencb.pro.',
    ),
    BuiltinExtension(
      id: 920260023,
      name: 'Dâm Cô Nương (18+)',
      asset: 'damconuong.js',
      baseUrl: 'https://damconuong.pet',
      itemType: ItemType.manga,
      version: '0.2.8',
      nsfw: true,
      lang: 'vi',
      iconUrl: 'https://damconuong.pet/favicon.ico',
      notes: 'Truyện tranh 18+ sắc hiệp, manhwa 18+ Vietsub. Địa chỉ phụ: damconuong.name.',
    ),
    BuiltinExtension(
      id: 920260024,
      name: 'SayHentai (18+)',
      asset: 'sayhentai.js',
      baseUrl: 'https://sayhentai.cx',
      itemType: ItemType.manga,
      version: '0.2.8',
      nsfw: true,
      lang: 'vi',
      iconUrl: 'https://sayhentai.cx/favicon.ico',
      notes: 'Đọc truyện tranh hentai, manga 18+ Vietsub online. Địa chỉ phụ: sayhentais.com, sayhentaii.art.',
    ),
    BuiltinExtension(
      id: 920260025,
      name: 'Xôi Lạc TV',
      asset: 'xoilac.js',
      baseUrl: 'https://xoilacxxi.cc',
      itemType: ItemType.anime,
      version: '0.2.8',
      nsfw: false,
      lang: 'vi',
      iconUrl: 'https://xoilacxxi.cc/favicon.ico',
      notes: 'Xem trực tiếp bóng đá, thể thao, phát lại video HD. Địa chỉ phụ: xoilacvb.cc, xoilac32.org.',
    ),
    BuiltinExtension(
      id: 920260026,
      name: 'Phimmoi',
      asset: 'phimmoi.js',
      baseUrl: 'https://phimmoii.mom',
      itemType: ItemType.anime,
      version: '0.3.8',
      nsfw: false,
      lang: 'vi',
      iconUrl: 'https://phimmoii.mom/favicon.ico',
      notes: 'Kho phim bộ, phim lẻ, phim chiếu rạp Phimmoi Vietsub. Tên miền dự phòng: messiahelartista.com, phimmois.sh.',
    ),
    BuiltinExtension(
      id: 920260027,
      name: 'MotPhim',
      asset: 'motphim.js',
      baseUrl: 'https://motphimc.my',
      itemType: ItemType.anime,
      version: '0.3.8',
      nsfw: false,
      lang: 'vi',
      iconUrl: 'https://motphimc.my/favicon.ico',
      notes: 'Kho phim MotPhim / MotChill Vietsub. Tên miền dự phòng: motphim.website, motchill10.io.',
    ),
    BuiltinExtension(
      id: 920260028,
      name: 'HiHiPhim',
      asset: 'hihiphim.js',
      baseUrl: 'https://hihiphim.com',
      itemType: ItemType.anime,
      version: '0.3.8',
      nsfw: false,
      lang: 'vi',
      iconUrl: 'https://hihiphim.com/favicon.ico',
      notes: 'Phim bộ, phim lẻ, anime vietsub online HD trên HiHiPhim.',
    ),
    BuiltinExtension(
      id: 920260029,
      name: 'PhimMoiHD',
      asset: 'phimmoihd.js',
      baseUrl: 'https://phimmoihd.online',
      itemType: ItemType.anime,
      version: '0.3.8',
      nsfw: false,
      lang: 'vi',
      iconUrl: 'https://phimmoihd.online/favicon.ico',
      notes: 'Xem phim HD online Vietsub thuyết minh chất lượng cao trên PhimMoiHD.',
    ),
  ];

  static Future<String> _code(BuiltinExtension e) async {
    final common = await rootBundle.loadString(
      'assets/yomihub_extensions/_common.js',
    );
    final body = await rootBundle.loadString(
      'assets/yomihub_extensions/${e.asset}',
    );
    return '$common\n$body';
  }

  /// Adds missing bundled extensions and updates outdated ones. An extension
  /// the user removed stays removed.
  static Future<void> install() async {
    try {
      final box = await YomiHive.open(_box);
      for (final e in all) {
        final existing = sourceRepository.getById(e.id);
        const legacyDomains = {
          'haychill.js': 'https://haychill.tv',
          'xemphimgi.js': 'https://xemphimgi.net',
          'nextphim.js': 'https://nextphim.com',
          'vfilm.js': 'https://vfilm.tv',
          // 0.4.3: animevietsub.nl (sheet) and .sale both 301 to
          // animevietsub.news (checked from Windows 28/10/2026 20:38)
          'avsub.js': 'https://animevietsub.nl',
        };
        const extraLegacy = {
          'avsub.js': ['https://animevietsub.sale'],
        };
        final migrateDomain =
            existing != null &&
            ((legacyDomains[e.asset] != null &&
                    existing.baseUrl == legacyDomains[e.asset]) ||
                (extraLegacy[e.asset]?.contains(existing.baseUrl) ?? false));
        final seenVersion = box.get('v_${e.id}') as String?;
        if (existing == null && seenVersion != null)
          continue; // user uninstalled it
        // 0.2.0: also refresh when the bundled code changed without a
        // version bump (fixes shipped in an app update reach everyone)
        final code = await _code(e);
        if (existing != null &&
            seenVersion == e.version &&
            existing.sourceCode == code &&
            existing.lang == e.lang &&
            existing.name == e.name &&
            !migrateDomain &&
            (existing.isNsfw ?? false) == e.nsfw) {
          continue;
        }
        final src =
            existing ??
            (Source(
              id: e.id,
              name: e.name,
              lang: e.lang,
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
          ..name = e.name
          ..baseUrl = migrateDomain ? e.baseUrl : src.baseUrl
          ..sourceCode = code
          ..version = e.version
          ..versionLast = e.version
          ..isLocal = true
          ..notes = e.notes
          ..iconUrl = e.iconUrl
          ..isNsfw = e.nsfw
          ..lang = e.lang
          ..sourceCodeLanguage = SourceCodeLanguage.javascript;
        await sourceRepository.save(src);
        await box.put('v_${e.id}', e.version);
      }
    } catch (error) {
      AppLogger.log(
        'Bundled extension update failed: $error',
        logLevel: LogLevel.error,
      );
      // never block startup because of a bundled extension
    }
  }
}

/// Groups of installed sources that point at the same website.
class ExtensionMergeHelper {
  static String hostOf(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      var h = Uri.parse(url.contains('://') ? url : 'https://$url').host
          .toLowerCase();
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
    for (final s in sourceRepository.getInstalled()) {
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

  /// group key ("itemType|host") â†’ {'primary': id, 'members': [ids]}
  ///
  /// 0.4.3: the parsed copy is cached until the stored map changes. It was
  /// rebuilt for every HTTP request (domain override lookup) and for every
  /// source row in Browse, which made browsing with merges slow.
  static Map<String, Map<String, dynamic>> get groups {
    final raw = YomiPrefs.get<Map>(_key, const {});
    if (!identical(raw, _rawCache) || _parsed == null) {
      _rawCache = raw;
      _parsed = {
        for (final e in raw.entries)
          '${e.key}': Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(e.value as Map),
          ),
      };
    }
    // callers may edit the outer map (merge/unmerge), never the inner ones
    return Map<String, Map<String, dynamic>>.of(_parsed!);
  }

  static Object? _rawCache;
  static Map<String, Map<String, dynamic>>? _parsed;

  /// 0.4.3: groups the user built by hand from any extensions (different
  /// websites, e.g. the same comic on two sites) use this key prefix.
  static const customPrefix = 'custom|';
  static bool isCustom(String key) => key.startsWith(customPrefix);

  static bool isMerged(String key) => groups.containsKey(key);

  static Future<void> merge(String key, int primary, List<int> members) async {
    final g = groups;
    final ids = {...members, primary};
    // A source can belong to only one group; overlapping groups can hide
    // each other's primary and leave no source visible in Browse.
    for (final oldKey in g.keys.toList()) {
      final old = g[oldKey]!;
      final remaining = (old['members'] as List? ?? const [])
          .whereType<int>()
          .where((id) => !ids.contains(id))
          .toList();
      if (remaining.length < 2) {
        g.remove(oldKey);
      } else {
        g[oldKey] = {
          'primary': remaining.contains(old['primary'])
              ? old['primary']
              : remaining.first,
          'members': remaining,
          if (remaining.contains(old['active'])) 'active': old['active'],
        };
      }
    }
    g[key] = {'primary': primary, 'members': ids.toList()};
    await YomiPrefs.set(_key, g);
  }

  static Future<void> unmerge(String key) async {
    final g = groups..remove(key);
    await YomiPrefs.set(_key, g);
  }

  /// The member shown for a group: the language picked by the user
  /// (0.1.8), otherwise the primary.
  static int? visibleOf(Map<String, dynamic> g) {
    final members = (g['members'] as List? ?? const []).cast<int>();
    final a = g['active'];
    if (a is int && members.contains(a)) return a;
    return g['primary'] as int?;
  }

  /// Source ids folded under another (hidden from the Sources list only).
  static Set<int> hiddenSecondaries() {
    final out = <int>{};
    for (final g in groups.values) {
      final p = visibleOf(g);
      for (final m in (g['members'] as List? ?? const [])) {
        if (m != p) out.add(m as int);
      }
    }
    return out;
  }

  /// The merge group a source belongs to (key, data), if any.
  static (String, Map<String, dynamic>)? groupOf(int? sourceId) {
    if (sourceId == null) return null;
    for (final e in groups.entries) {
      final members = (e.value['members'] as List? ?? const []);
      if (members.contains(sourceId) || e.value['primary'] == sourceId) {
        return (e.key, e.value);
      }
    }
    return null;
  }

  /// YomiHub 0.1.8: the languages of a merged extension, when its members
  /// are in more than one language (each entry: language â†’ source).
  static Map<String, Source> languagesOf(int? sourceId) {
    final g = groupOf(sourceId);
    if (g == null) return const {};
    final out = <String, Source>{};
    for (final id in (g.$2['members'] as List? ?? const []).cast<int>()) {
      final s = sourceRepository.getById(id);
      if (s == null || !(s.isAdded ?? false)) continue;
      final lang = (s.lang ?? '').isEmpty ? 'all' : s.lang!;
      out.putIfAbsent(lang, () => s);
    }
    return out.length > 1 ? out : const {};
  }

  /// Shows [sourceId]'s member in [lang] in place of the current one.
  static Future<void> setLanguage(int? sourceId, String lang) async {
    final g = groupOf(sourceId);
    if (g == null) return;
    final target = languagesOf(sourceId)[lang];
    if (target == null) return;
    final all = groups;
    all[g.$1] = {...g.$2, 'active': target.id};
    await YomiPrefs.set(_key, all);
  }

  /// Number of extensions folded under [sourceId] (0 if not a primary).
  static int foldedUnder(int? sourceId) {
    for (final g in groups.values) {
      if (visibleOf(g) == sourceId) {
        return ((g['members'] as List?)?.length ?? 1) - 1;
      }
    }
    return 0;
  }
}
