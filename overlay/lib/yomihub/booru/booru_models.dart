/// YomiHub 0.4.4 – Booru App (sheet "YomiHub Update", nhóm "Booru Project").
///
/// Data model shared by the four API families the Booru projects of the
/// sheet talk to (BooruHub, Boorusama, Boorusphere, Booru-Studio, Rule-34
/// App, Hybooru, monbooru, danbooru):
///   * Danbooru 2   – danbooru.donmai.us, safebooru.donmai.us
///   * Gelbooru 0.2 – gelbooru.com, safebooru.org, rule34.xxx, xbooru.com
///   * Moebooru     – yande.re, konachan.com / konachan.net
///   * e621         – e621.net / e926.net
library;

enum BooruType { danbooru, gelbooru, moebooru, e621 }

enum BooruRating { general, sensitive, questionable, explicit, unknown }

BooruRating parseBooruRating(String? r) {
  switch ((r ?? '').toLowerCase()) {
    case 'g':
    case 'general':
      return BooruRating.general;
    case 's':
    case 'safe':
    case 'sensitive':
      return BooruRating.sensitive;
    case 'q':
    case 'questionable':
      return BooruRating.questionable;
    case 'e':
    case 'explicit':
      return BooruRating.explicit;
    default:
      return BooruRating.unknown;
  }
}

class BooruSite {
  final String id;
  final String name;
  final BooruType type;
  final String baseUrl;

  /// Every post on the site is 18+ (hidden while the app's NSFW setting is off).
  final bool nsfwOnly;

  /// Site added by the user in Booru App settings.
  final bool custom;

  /// Site needs `api_key` + `user_id` (Gelbooru, Rule34 since 2025).
  final bool needsKey;

  const BooruSite({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    this.nsfwOnly = false,
    this.custom = false,
    this.needsKey = false,
  });

  String get host => Uri.tryParse(baseUrl)?.host ?? baseUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'baseUrl': baseUrl,
        'nsfwOnly': nsfwOnly,
        'needsKey': needsKey,
      };

  static BooruSite? fromJson(Map m) {
    final t = BooruType.values.where((e) => e.name == m['type']).firstOrNull;
    final url = '${m['baseUrl'] ?? ''}'.trim();
    if (t == null || url.isEmpty) return null;
    return BooruSite(
      id: '${m['id'] ?? url}',
      name: '${m['name'] ?? Uri.tryParse(url)?.host ?? url}',
      type: t,
      baseUrl: url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      nsfwOnly: m['nsfwOnly'] == true,
      needsKey: m['needsKey'] == true,
      custom: true,
    );
  }

  /// Built-in sites. Safe-capable sites first so a fresh install (NSFW off)
  /// lands on a general-audience board.
  static const builtIn = <BooruSite>[
    BooruSite(id: 'safebooru_org', name: 'Safebooru', type: BooruType.gelbooru, baseUrl: 'https://safebooru.org'),
    BooruSite(id: 'danbooru', name: 'Danbooru', type: BooruType.danbooru, baseUrl: 'https://danbooru.donmai.us'),
    BooruSite(id: 'konachan_net', name: 'Konachan (an toàn)', type: BooruType.moebooru, baseUrl: 'https://konachan.net'),
    BooruSite(id: 'e926', name: 'e926', type: BooruType.e621, baseUrl: 'https://e926.net'),
    BooruSite(id: 'yandere', name: 'Yande.re', type: BooruType.moebooru, baseUrl: 'https://yande.re'),
    BooruSite(id: 'gelbooru', name: 'Gelbooru', type: BooruType.gelbooru, baseUrl: 'https://gelbooru.com', needsKey: true),
    BooruSite(id: 'konachan_com', name: 'Konachan', type: BooruType.moebooru, baseUrl: 'https://konachan.com', nsfwOnly: true),
    BooruSite(id: 'e621', name: 'e621', type: BooruType.e621, baseUrl: 'https://e621.net', nsfwOnly: true),
    BooruSite(id: 'rule34', name: 'Rule34', type: BooruType.gelbooru, baseUrl: 'https://api.rule34.xxx', nsfwOnly: true, needsKey: true),
    BooruSite(id: 'xbooru', name: 'Xbooru', type: BooruType.gelbooru, baseUrl: 'https://xbooru.com', nsfwOnly: true),
  ];
}

class BooruPost {
  final String siteId;
  final int id;
  final String previewUrl;
  final String sampleUrl;
  final String fileUrl;
  final List<String> tags;
  final BooruRating rating;
  final int score;
  final int width;
  final int height;
  final String source;
  final String postUrl;

  const BooruPost({
    required this.siteId,
    required this.id,
    required this.previewUrl,
    required this.sampleUrl,
    required this.fileUrl,
    required this.tags,
    required this.rating,
    required this.score,
    required this.width,
    required this.height,
    required this.source,
    required this.postUrl,
  });

  String get ext {
    final p = Uri.tryParse(fileUrl)?.path ?? fileUrl;
    final i = p.lastIndexOf('.');
    return i < 0 ? '' : p.substring(i + 1).toLowerCase();
  }

  bool get isVideo => const {'mp4', 'webm', 'mkv', 'mov', 'm4v'}.contains(ext);
  bool get isGif => ext == 'gif';
  double get aspect => (width > 0 && height > 0) ? width / height : 0.75;

  bool get isNsfw =>
      rating == BooruRating.questionable || rating == BooruRating.explicit;

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'id': id,
        'previewUrl': previewUrl,
        'sampleUrl': sampleUrl,
        'fileUrl': fileUrl,
        'tags': tags.join(' '),
        'rating': rating.name,
        'score': score,
        'width': width,
        'height': height,
        'source': source,
        'postUrl': postUrl,
      };

  static BooruPost fromJson(Map m) => BooruPost(
        siteId: '${m['siteId'] ?? ''}',
        id: (m['id'] as num?)?.toInt() ?? 0,
        previewUrl: '${m['previewUrl'] ?? ''}',
        sampleUrl: '${m['sampleUrl'] ?? ''}',
        fileUrl: '${m['fileUrl'] ?? ''}',
        tags: '${m['tags'] ?? ''}'.split(' ').where((e) => e.isNotEmpty).toList(),
        rating: BooruRating.values.where((e) => e.name == m['rating']).firstOrNull ?? BooruRating.unknown,
        score: (m['score'] as num?)?.toInt() ?? 0,
        width: (m['width'] as num?)?.toInt() ?? 0,
        height: (m['height'] as num?)?.toInt() ?? 0,
        source: '${m['source'] ?? ''}',
        postUrl: '${m['postUrl'] ?? ''}',
      );
}

class BooruTag {
  final String name;
  final int count;
  const BooruTag(this.name, this.count);
}
