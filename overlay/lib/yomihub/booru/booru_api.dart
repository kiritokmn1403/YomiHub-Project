import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/booru/booru_models.dart';

/// YomiHub 0.4.4 – Booru App: one client for the four booru API families.
///
/// Pure Dart (no Flutter) so the parsers are unit-tested
/// (`test/yh_044_test.dart`). The app passes [MClient.init] as [client], so
/// requests follow "VPN & DNS" (Tor/WARP/proxy, DNS-over-HTTPS).
class BooruApi {
  BooruApi(this.client, {this.userAgent = 'YomiHub/0.4.4 (Booru App)'});

  final http.Client client;
  final String userAgent;

  static const pageSize = 40;

  Map<String, String> get _headers => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      };

  /// [safe] = app NSFW setting is off: restrict to general/safe ratings
  /// server-side (and [BooruFilter] drops anything else client-side).
  Uri postsUri(BooruSite s, String tags, int page,
      {bool safe = true, String? login, String? apiKey}) {
    final t = _withRating(s, tags.trim(), safe);
    switch (s.type) {
      case BooruType.danbooru:
        return Uri.parse('${s.baseUrl}/posts.json').replace(queryParameters: {
          'tags': t,
          'page': '$page',
          'limit': '$pageSize',
          if ((login ?? '').isNotEmpty && (apiKey ?? '').isNotEmpty) ...{'login': login!, 'api_key': apiKey!},
        });
      case BooruType.gelbooru:
        return Uri.parse('${s.baseUrl}/index.php').replace(queryParameters: {
          'page': 'dapi',
          's': 'post',
          'q': 'index',
          'json': '1',
          'tags': t,
          'pid': '${page - 1}',
          'limit': '$pageSize',
          if ((login ?? '').isNotEmpty && (apiKey ?? '').isNotEmpty) ...{'user_id': login!, 'api_key': apiKey!},
        });
      case BooruType.moebooru:
        return Uri.parse('${s.baseUrl}/post.json').replace(queryParameters: {
          'tags': t,
          'page': '$page',
          'limit': '$pageSize',
          if ((login ?? '').isNotEmpty && (apiKey ?? '').isNotEmpty) ...{'login': login!, 'password_hash': apiKey!},
        });
      case BooruType.e621:
        return Uri.parse('${s.baseUrl}/posts.json').replace(queryParameters: {
          'tags': t,
          'page': '$page',
          'limit': '$pageSize',
          if ((login ?? '').isNotEmpty && (apiKey ?? '').isNotEmpty) ...{'login': login!, 'api_key': apiKey!},
        });
    }
  }

  static String _withRating(BooruSite s, String tags, bool safe) {
    if (!safe || tags.contains('rating:')) return tags;
    final r = switch (s.type) {
      // Danbooru: g = general (s/q/e are sensitive…explicit)
      BooruType.danbooru => 'rating:g',
      BooruType.gelbooru => s.host.contains('safebooru') ? '' : 'rating:general',
      BooruType.moebooru => 'rating:s',
      BooruType.e621 => 'rating:s',
    };
    return r.isEmpty ? tags : (tags.isEmpty ? r : '$tags $r');
  }

  Future<List<BooruPost>> posts(BooruSite s, String tags, int page,
      {bool safe = true, String? login, String? apiKey}) async {
    final uri = postsUri(s, tags, page, safe: safe, login: login, apiKey: apiKey);
    final res = await client.get(uri, headers: _headers).timeout(const Duration(seconds: 40));
    final body = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
    final lower = body.length > 4000 ? body.substring(0, 4000).toLowerCase() : body.toLowerCase();
    // 0.4.4 (tested 29/10 from the owner's network): Danbooru and konachan.com
    // answer 403 "Just a moment..." (Cloudflare), Gelbooru 401, Rule34 200
    // with the JSON string "Missing authentication…".
    final isCf = lower.contains('just a moment') || lower.contains('cf-chl') || lower.contains('cloudflare');
    if (isCf && (res.statusCode == 403 || res.statusCode == 503 || res.statusCode == 429 || body.startsWith('<'))) {
      throw BooruException(s, 'Cloudflare (HTTP ${res.statusCode})', BooruError.cloudflare);
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw BooruException(s, 'HTTP ${res.statusCode}',
          s.needsKey || res.statusCode == 401 ? BooruError.needsKey : BooruError.blocked);
    }
    if (res.statusCode != 200) {
      throw BooruException(s, 'HTTP ${res.statusCode}', BooruError.http);
    }
    if (body.isEmpty) return const [];
    if (body.startsWith('"') && lower.contains('authentication')) {
      throw BooruException(s, 'missing authentication', BooruError.needsKey);
    }
    if (body.startsWith('<')) {
      // HTML error page / Gelbooru XML "missing authentication"
      throw BooruException(
          s,
          lower.contains('authentication') || lower.contains('api key') ? 'missing authentication' : 'HTML thay vì JSON',
          lower.contains('authentication') || lower.contains('api key')
              ? BooruError.needsKey
              : (lower.contains('cloudflare') ? BooruError.cloudflare : BooruError.format));
    }
    return parsePosts(s, jsonDecode(body));
  }

  /// Parses a posts response of any family. Entries without a usable image
  /// URL (deleted, banned, gold-only on Danbooru) are skipped.
  static List<BooruPost> parsePosts(BooruSite s, dynamic json) {
    List list;
    if (json is List) {
      list = json;
    } else if (json is Map && json['posts'] is List) {
      list = json['posts'];
    } else if (json is Map && json['post'] is List) {
      list = json['post'];
    } else if (json is Map && json['post'] is Map) {
      list = [json['post']];
    } else {
      list = const [];
    }
    final out = <BooruPost>[];
    for (final e in list) {
      if (e is! Map) continue;
      final p = switch (s.type) {
        BooruType.danbooru => _danbooru(s, e),
        BooruType.gelbooru => _gelbooru(s, e),
        BooruType.moebooru => _moebooru(s, e),
        BooruType.e621 => _e621(s, e),
      };
      if (p != null && p.fileUrl.isNotEmpty) out.add(p);
    }
    return out;
  }

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
  static String _str(dynamic v) => v == null ? '' : '$v';

  static String _abs(BooruSite s, String u) {
    if (u.isEmpty) return u;
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) return '${s.baseUrl}$u';
    return u;
  }

  static BooruPost? _danbooru(BooruSite s, Map e) {
    final id = _int(e['id']);
    final file = _str(e['file_url']);
    if (id == 0 || file.isEmpty) return null;
    return BooruPost(
      siteId: s.id,
      id: id,
      previewUrl: _abs(s, _str(e['preview_file_url']).isEmpty ? file : _str(e['preview_file_url'])),
      sampleUrl: _abs(s, _str(e['large_file_url']).isEmpty ? file : _str(e['large_file_url'])),
      fileUrl: _abs(s, file),
      tags: _str(e['tag_string']).split(' ').where((t) => t.isNotEmpty).toList(),
      rating: parseBooruRating(_str(e['rating'])),
      score: _int(e['score']),
      width: _int(e['image_width']),
      height: _int(e['image_height']),
      source: _str(e['source']),
      postUrl: '${s.baseUrl}/posts/$id',
    );
  }

  static BooruPost? _gelbooru(BooruSite s, Map e) {
    final id = _int(e['id']);
    if (id == 0) return null;
    var file = _str(e['file_url']);
    var preview = _str(e['preview_url']);
    var sample = _str(e['sample_url']);
    // safebooru.org / older Gelbooru JSON: only directory + image + hash
    final dir = _str(e['directory']);
    final image = _str(e['image']);
    if (file.isEmpty && dir.isNotEmpty && image.isNotEmpty) {
      file = '${s.baseUrl}/images/$dir/$image';
    }
    if (preview.isEmpty && dir.isNotEmpty && image.isNotEmpty) {
      final base = image.contains('.') ? image.substring(0, image.lastIndexOf('.')) : image;
      preview = '${s.baseUrl}/thumbnails/$dir/thumbnail_$base.jpg';
    }
    if (sample.isEmpty) sample = file;
    if (file.isEmpty) return null;
    final web = s.baseUrl.replaceFirst('://api.', '://');
    return BooruPost(
      siteId: s.id,
      id: id,
      previewUrl: _abs(s, preview.isEmpty ? sample : preview),
      sampleUrl: _abs(s, sample),
      fileUrl: _abs(s, file),
      tags: _str(e['tags']).split(' ').where((t) => t.isNotEmpty).toList(),
      rating: parseBooruRating(_str(e['rating'])),
      score: _int(e['score']),
      width: _int(e['width']),
      height: _int(e['height']),
      source: _str(e['source']),
      postUrl: '$web/index.php?page=post&s=view&id=$id',
    );
  }

  static BooruPost? _moebooru(BooruSite s, Map e) {
    final id = _int(e['id']);
    final file = _str(e['file_url']);
    if (id == 0 || file.isEmpty) return null;
    final sample = _str(e['jpeg_url']).isNotEmpty ? _str(e['jpeg_url']) : _str(e['sample_url']);
    return BooruPost(
      siteId: s.id,
      id: id,
      previewUrl: _abs(s, _str(e['preview_url']).isEmpty ? (sample.isEmpty ? file : sample) : _str(e['preview_url'])),
      sampleUrl: _abs(s, sample.isEmpty ? file : sample),
      fileUrl: _abs(s, file),
      tags: _str(e['tags']).split(' ').where((t) => t.isNotEmpty).toList(),
      rating: parseBooruRating(_str(e['rating'])),
      score: _int(e['score']),
      width: _int(e['width']),
      height: _int(e['height']),
      source: _str(e['source']),
      postUrl: '${s.baseUrl}/post/show/$id',
    );
  }

  static BooruPost? _e621(BooruSite s, Map e) {
    final id = _int(e['id']);
    final file = e['file'] is Map ? _str((e['file'] as Map)['url']) : '';
    if (id == 0 || file.isEmpty) return null;
    final f = e['file'] as Map;
    final sample = e['sample'] is Map ? _str((e['sample'] as Map)['url']) : '';
    final preview = e['preview'] is Map ? _str((e['preview'] as Map)['url']) : '';
    final tags = <String>[];
    if (e['tags'] is Map) {
      for (final v in (e['tags'] as Map).values) {
        if (v is List) tags.addAll(v.map((t) => '$t'));
      }
    }
    final score = e['score'] is Map ? _int((e['score'] as Map)['total']) : _int(e['score']);
    final sources = e['sources'] is List ? (e['sources'] as List).map((x) => '$x').toList() : const <String>[];
    return BooruPost(
      siteId: s.id,
      id: id,
      previewUrl: preview.isEmpty ? (sample.isEmpty ? file : sample) : preview,
      sampleUrl: sample.isEmpty ? file : sample,
      fileUrl: file,
      tags: tags,
      rating: parseBooruRating(_str(e['rating'])),
      score: score,
      width: _int(f['width']),
      height: _int(f['height']),
      source: sources.isEmpty ? '' : sources.first,
      postUrl: '${s.baseUrl}/posts/$id',
    );
  }

  /// Tag suggestions for the search box (most used first).
  Future<List<BooruTag>> autocomplete(BooruSite s, String q) async {
    q = q.trim();
    if (q.length < 2) return const [];
    late Uri uri;
    switch (s.type) {
      case BooruType.danbooru:
        uri = Uri.parse('${s.baseUrl}/autocomplete.json').replace(queryParameters: {
          'search[query]': q,
          'search[type]': 'tag_query',
          'limit': '12',
        });
      case BooruType.gelbooru:
        // 0.4.4 (tested 29/10): the tag dapi answers XML even with json=1;
        // safebooru.org / xbooru.com have autocomplete.php (JSON), gelbooru.com
        // has page=autocomplete2.
        uri = s.host.contains('gelbooru.com')
            ? Uri.parse('${s.baseUrl}/index.php').replace(queryParameters: {
                'page': 'autocomplete2',
                'term': q,
                'type': 'tag_query',
                'limit': '12',
              })
            : Uri.parse('${s.baseUrl}/autocomplete.php').replace(queryParameters: {'q': q});
      case BooruType.moebooru:
        uri = Uri.parse('${s.baseUrl}/tag.json').replace(queryParameters: {
          'name': '$q*',
          'order': 'count',
          'limit': '12',
        });
      case BooruType.e621:
        uri = Uri.parse('${s.baseUrl}/tags/autocomplete.json').replace(queryParameters: {
          'search[name_matches]': q,
          'expiry': '7',
        });
    }
    final res = await client.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return const [];
    final body = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
    if (body.isEmpty || body.startsWith('<')) return const [];
    return parseTags(jsonDecode(body));
  }

  static List<BooruTag> parseTags(dynamic json) {
    List list = json is List
        ? json
        : (json is Map && json['tag'] is List ? json['tag'] : const []);
    final out = <BooruTag>[];
    for (final e in list) {
      if (e is! Map) continue;
      final name = _str(e['value'] ?? e['name']);
      if (name.isEmpty) continue;
      var count = _int(e['post_count'] ?? e['count']);
      if (count == 0) {
        // autocomplete.php: {"label": "scenery (65943)", "value": "scenery"}
        count = int.tryParse(RegExp(r'\((\d+)\)\s*$').firstMatch(_str(e['label']))?.group(1) ?? '') ?? 0;
      }
      out.add(BooruTag(name, count));
    }
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }
}

enum BooruError { http, needsKey, blocked, cloudflare, format }

class BooruException implements Exception {
  final BooruSite site;
  final String message;
  final BooruError kind;
  BooruException(this.site, this.message, this.kind);
  @override
  String toString() => '${site.name}: $message';
}

/// Client-side rules applied to every result list.
class BooruFilter {
  static List<BooruPost> apply(List<BooruPost> posts,
      {required bool showNsfw, required Set<String> blacklist}) {
    return posts.where((p) {
      if (!showNsfw && p.isNsfw) return false;
      if (blacklist.isNotEmpty && p.tags.any(blacklist.contains)) return false;
      return true;
    }).toList();
  }
}
