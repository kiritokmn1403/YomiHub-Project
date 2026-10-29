import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/models/track_search.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/services/trackers/base_tracker.dart';

/// Trackers YomiHub adds on top of Mangayomi's (MAL, AniList, Kitsu, Simkl,
/// Trakt), following the Aniyomi / Nekoyomi / Mihon implementations:
/// MangaUpdates, Shikimori, Bangumi, Kavita and Suwayomi.
///
/// They are plain classes (not Riverpod code-generated notifiers) so no
/// build_runner step is needed; [yomiTracker] hands them to the existing
/// tracking UI through the same [BaseTracker] interface.
class YomiTrackerIds {
  static const mangaUpdates = 6;
  static const shikimori = 7;
  static const bangumi = 8;
  static const kavita = 9;
  static const suwayomi = 10;
  static const all = [mangaUpdates, shikimori, bangumi, kavita, suwayomi];
}

BaseTracker? yomiTracker(int syncId) => switch (syncId) {
  YomiTrackerIds.mangaUpdates => MangaUpdatesTracker(),
  YomiTrackerIds.shikimori => ShikimoriTracker(),
  YomiTrackerIds.bangumi => BangumiTracker(),
  YomiTrackerIds.kavita => KavitaTracker(),
  YomiTrackerIds.suwayomi => SuwayomiTracker(),
  _ => null,
};

/// Credentials/settings of a YomiHub tracker, kept as JSON in
/// [TrackPreference.oAuth].
class YomiTrackerAuth {
  static Map<String, dynamic> read(int syncId) {
    final pref = trackRepository.getPreferenceById(syncId);
    if (pref?.oAuth == null || pref!.oAuth!.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(pref.oAuth!) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(
    int syncId,
    String username,
    Map<String, dynamic> data, {
    String? avatarUrl,
  }) async {
    await trackRepository.savePreference(
      TrackPreference(
        syncId: syncId,
        username: username,
        displayName: username,
        avatarUrl: avatarUrl,
        oAuth: jsonEncode(data),
      ),
    );
  }
}

abstract class _YomiTrackerBase implements BaseTracker {
  int get syncId;
  static final http.Client trackerClient = MClient.init(reqcopyWith: {'useDartHttpClient': true});
  final client = trackerClient;

  Map<String, dynamic> get auth => YomiTrackerAuth.read(syncId);

  Map<String, String> headers() => {
    'User-Agent': 'YomiHub/0.2.7',
    'Accept': 'application/json',
  };

  Future<dynamic> getJson(String url, {Map<String, String>? extra}) async {
    final r = await client.get(
      Uri.parse(url),
      headers: {...headers(), ...?extra},
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 300) {
      throw Exception('${Uri.parse(url).host}: HTTP ${r.statusCode}');
    }
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  Future<dynamic> sendJson(
    String method,
    String url,
    Object? body, {
    Map<String, String>? extra,
    String contentType = 'application/json',
  }) async {
    final req = http.Request(method, Uri.parse(url));
    req.headers.addAll({
      ...headers(),
      'Content-Type': contentType,
      ...?extra,
    });
    if (body != null) req.body = body is String ? body : jsonEncode(body);
    final res = await http.Response.fromStream(await client.send(req));
    if (res.statusCode >= 300) {
      throw Exception(
        '${Uri.parse(url).host}: HTTP ${res.statusCode} ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}',
      );
    }
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return res.body;
    }
  }

  @override
  Future<bool> checkRefresh() async => auth.isNotEmpty;

  @override
  (int, int) getScoreValue() => (10, 1);

  @override
  String displayScore(int score) => '$score';

  @override
  Future<List<TrackSearch>> fetchGeneralData({
    bool isManga = true,
    String rankingType = '',
  }) async => [];

  @override
  Future<List<TrackSearch>> fetchUserData({bool isManga = true}) async => [];
}

// ═════════════════════════════ MangaUpdates ═════════════════════════════

class MangaUpdatesTracker extends _YomiTrackerBase {
  static const _api = 'https://api.mangaupdates.com/v1';
  @override
  int get syncId => YomiTrackerIds.mangaUpdates;

  // list ids
  static const reading = 0, wish = 1, complete = 2, unfinished = 3, onHold = 4;

  @override
  Map<String, String> headers() => {
    ...super.headers(),
    if (auth['token'] != null) 'Authorization': 'Bearer ${auth['token']}',
  };

  static Future<String?> login(String username, String password) async {
    final t = MangaUpdatesTracker();
    try {
      final r = await t.sendJson('PUT', '$_api/account/login', {
        'username': username,
        'password': password,
      });
      final token = r?['context']?['session_token'];
      if (token == null) return tr('Sai tài khoản hoặc mật khẩu');
      await YomiTrackerAuth.save(YomiTrackerIds.mangaUpdates, username, {
        'token': token,
        'uid': r['context']['uid'],
      });
      return null;
    } catch (e) {
      return '$e';
    }
  }

  @override
  List<TrackStatus> statusList(bool isManga) => [
    TrackStatus.reading,
    TrackStatus.completed,
    TrackStatus.onHold,
    TrackStatus.dropped,
    TrackStatus.planToRead,
  ];

  int _toList(TrackStatus s) => switch (s) {
    TrackStatus.completed => complete,
    TrackStatus.onHold => onHold,
    TrackStatus.dropped => unfinished,
    TrackStatus.planToRead || TrackStatus.planToWatch => wish,
    _ => reading,
  };

  TrackStatus _fromList(int? id) => switch (id) {
    complete => TrackStatus.completed,
    onHold => TrackStatus.onHold,
    unfinished => TrackStatus.dropped,
    wish => TrackStatus.planToRead,
    _ => TrackStatus.reading,
  };

  @override
  Future<List<TrackSearch>> search(String query, bool isManga) async {
    final r = await sendJson('POST', '$_api/series/search', {
      'search': query,
      'filter_types': ['drama cd', 'novel'],
      'perpage': 25,
    });
    final results = (r?['results'] as List?) ?? const [];
    return results.map((e) {
      final rec = e['record'] as Map;
      return TrackSearch(
        mediaId: (rec['series_id'] as num?)?.toInt(),
        syncId: syncId,
        title: rec['title'] ?? '',
        coverUrl: rec['image']?['url']?['original'] ?? '',
        summary: _strip(rec['description'] ?? ''),
        totalChapter: (rec['latest_chapter'] as num?)?.toInt() ?? 0,
        score: (rec['bayesian_rating'] as num?)?.toDouble(),
        publishingType: rec['type'] ?? '',
        startDate: '${rec['year'] ?? ''}',
        trackingUrl: rec['url'] ?? '',
      );
    }).toList();
  }

  @override
  Future<Track?> findLibItem(Track track, bool isManga) async {
    try {
      final item = await getJson('$_api/lists/series/${track.mediaId}');
      if (item == null) {
        // not in a list yet: add to "reading" / "wish"
        return await update(track, isManga);
      }
      track.status = _fromList((item['list_id'] as num?)?.toInt());
      track.lastChapterRead =
          (item['status']?['chapter'] as num?)?.toInt() ??
          track.lastChapterRead;
      try {
        final rating = await getJson('$_api/series/${track.mediaId}/rating');
        final v = (rating?['rating'] as num?)?.round();
        if (v != null) track.score = v;
      } catch (_) {}
      return track;
    } catch (_) {
      return await update(track, isManga);
    }
  }

  @override
  Future<Track> update(Track track, bool isManga) async {
    final body = [
      {
        'series': {'id': track.mediaId},
        'list_id': _toList(track.status),
        'status': {'chapter': track.lastChapterRead ?? 0},
      },
    ];
    try {
      await sendJson('POST', '$_api/lists/series/update', body);
    } catch (_) {
      await sendJson('POST', '$_api/lists/series', body);
    }
    final score = track.score ?? 0;
    try {
      if (score > 0) {
        await sendJson('PUT', '$_api/series/${track.mediaId}/rating', {
          'rating': score,
        });
      } else {
        await sendJson('DELETE', '$_api/series/${track.mediaId}/rating', null);
      }
    } catch (_) {}
    return track;
  }

  static String _strip(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '');
}

// ═════════════════════════════ Shikimori ═════════════════════════════

/// Shikimori needs an OAuth application. YomiHub has no registered one, so
/// the user creates their own (redirect `urn:ietf:wg:oauth:2.0:oob`) and
/// pastes its id/secret and the authorization code.
class ShikimoriTracker extends _YomiTrackerBase {
  static const base = 'https://shikimori.one';
  static const _api = '$base/api';
  static const oob = 'urn:ietf:wg:oauth:2.0:oob';
  @override
  int get syncId => YomiTrackerIds.shikimori;

  @override
  Map<String, String> headers() => {
    'User-Agent': 'YomiHub',
    'Accept': 'application/json',
    if (auth['access_token'] != null)
      'Authorization': 'Bearer ${auth['access_token']}',
  };

  static Uri authorizeUrl(String clientId) =>
      Uri.parse('$base/oauth/authorize').replace(
        queryParameters: {
          'client_id': clientId,
          'redirect_uri': oob,
          'response_type': 'code',
          'scope': 'user_rates',
        },
      );

  static Future<String?> login(
    String clientId,
    String clientSecret,
    String code,
  ) async {
    try {
      final res = await _YomiTrackerBase.trackerClient.post(
        Uri.parse('$base/oauth/token'),
        headers: {'User-Agent': 'YomiHub/0.2.7'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code.trim(),
          'redirect_uri': oob,
        },
      );
      if (res.statusCode >= 300) return 'Shikimori: HTTP ${res.statusCode}';
      final tok = jsonDecode(res.body) as Map<String, dynamic>;
      final data = {
        ...tok,
        'client_id': clientId,
        'client_secret': clientSecret,
        'obtained': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      final me = await _YomiTrackerBase.trackerClient.get(
        Uri.parse('$_api/users/whoami'),
        headers: {
          'User-Agent': 'YomiHub/0.2.7',
          'Authorization': 'Bearer ${tok['access_token']}',
        },
      );
      final user = jsonDecode(me.body) as Map<String, dynamic>;
      data['user_id'] = user['id'];
      await YomiTrackerAuth.save(
        YomiTrackerIds.shikimori,
        '${user['nickname'] ?? user['id']}',
        data,
        avatarUrl: user['avatar'] as String?,
      );
      return null;
    } catch (e) {
      return '$e';
    }
  }

  @override
  Future<bool> checkRefresh() async {
    final a = auth;
    if (a.isEmpty) return false;
    final obtained = (a['obtained'] as num?)?.toInt() ?? 0;
    final expires = (a['expires_in'] as num?)?.toInt() ?? 86400;
    if (DateTime.now().millisecondsSinceEpoch ~/ 1000 < obtained + expires - 300) {
      return true;
    }
    try {
      final res = await _YomiTrackerBase.trackerClient.post(
        Uri.parse('$base/oauth/token'),
        headers: {'User-Agent': 'YomiHub/0.2.7'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': a['client_id'],
          'client_secret': a['client_secret'],
          'refresh_token': a['refresh_token'],
        },
      );
      if (res.statusCode >= 300) return false;
      final tok = jsonDecode(res.body) as Map<String, dynamic>;
      final pref = trackRepository.getPreferenceById(syncId);
      await YomiTrackerAuth.save(syncId, pref?.username ?? '', {
        ...a,
        ...tok,
        'obtained': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      }, avatarUrl: pref?.avatarUrl);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  List<TrackStatus> statusList(bool isManga) => isManga
      ? [
          TrackStatus.reading,
          TrackStatus.completed,
          TrackStatus.onHold,
          TrackStatus.dropped,
          TrackStatus.planToRead,
          TrackStatus.reReading,
        ]
      : [
          TrackStatus.watching,
          TrackStatus.completed,
          TrackStatus.onHold,
          TrackStatus.dropped,
          TrackStatus.planToWatch,
          TrackStatus.reWatching,
        ];

  String _toApi(TrackStatus s) => switch (s) {
    TrackStatus.completed => 'completed',
    TrackStatus.onHold => 'on_hold',
    TrackStatus.dropped => 'dropped',
    TrackStatus.planToRead || TrackStatus.planToWatch => 'planned',
    TrackStatus.reReading || TrackStatus.reWatching => 'rewatching',
    _ => 'watching',
  };

  TrackStatus _fromApi(String? s, bool isManga) => switch (s) {
    'completed' => TrackStatus.completed,
    'on_hold' => TrackStatus.onHold,
    'dropped' => TrackStatus.dropped,
    'planned' => isManga ? TrackStatus.planToRead : TrackStatus.planToWatch,
    'rewatching' => isManga ? TrackStatus.reReading : TrackStatus.reWatching,
    _ => isManga ? TrackStatus.reading : TrackStatus.watching,
  };

  @override
  Future<List<TrackSearch>> search(String query, bool isManga) async {
    await checkRefresh();
    final kind = isManga ? 'mangas' : 'animes';
    final list =
        await getJson(
              Uri.parse('$_api/$kind')
                  .replace(queryParameters: {'search': query, 'limit': '20'})
                  .toString(),
            )
            as List? ??
        const [];
    return list.map((e) {
      final img = e['image']?['preview'] as String? ?? '';
      return TrackSearch(
        mediaId: (e['id'] as num?)?.toInt(),
        syncId: syncId,
        title: (e['russian'] as String?)?.isNotEmpty == true
            ? '${e['name']} / ${e['russian']}'
            : e['name'] ?? '',
        coverUrl: img.startsWith('http') ? img : '$base$img',
        totalChapter: ((isManga ? e['chapters'] : e['episodes']) as num?)
                ?.toInt() ??
            0,
        score: double.tryParse('${e['score']}'),
        publishingType: '${e['kind'] ?? ''}',
        publishingStatus: '${e['status'] ?? ''}',
        startDate: '${e['aired_on'] ?? ''}',
        trackingUrl: '$base${e['url'] ?? ''}',
      );
    }).toList();
  }

  @override
  Future<Track?> findLibItem(Track track, bool isManga) async {
    await checkRefresh();
    final type = isManga ? 'Manga' : 'Anime';
    final list =
        await getJson(
              Uri.parse('$_api/v2/user_rates').replace(
                queryParameters: {
                  'user_id': '${auth['user_id']}',
                  'target_id': '${track.mediaId}',
                  'target_type': type,
                },
              ).toString(),
            )
            as List? ??
        const [];
    if (list.isEmpty) return update(track, isManga);
    final r = list.first as Map;
    track.libraryId = (r['id'] as num?)?.toInt();
    track.status = _fromApi(r['status'] as String?, isManga);
    track.score = (r['score'] as num?)?.toInt() ?? 0;
    track.lastChapterRead =
        ((isManga ? r['chapters'] : r['episodes']) as num?)?.toInt() ?? 0;
    return track;
  }

  @override
  Future<Track> update(Track track, bool isManga) async {
    await checkRefresh();
    final body = {
      'user_rate': {
        'user_id': auth['user_id'],
        'target_id': track.mediaId,
        'target_type': isManga ? 'Manga' : 'Anime',
        isManga ? 'chapters' : 'episodes': track.lastChapterRead ?? 0,
        'score': track.score ?? 0,
        'status': _toApi(track.status),
      },
    };
    final r = await sendJson('POST', '$_api/v2/user_rates', body);
    if (r is Map && r['id'] != null) {
      track.libraryId = (r['id'] as num).toInt();
    }
    return track;
  }
}

// ═════════════════════════════ Bangumi ═════════════════════════════

/// Bangumi (bgm.tv). Login with a personal access token from
/// https://next.bgm.tv/demo/access-token.
class BangumiTracker extends _YomiTrackerBase {
  static const _api = 'https://api.bgm.tv';
  @override
  int get syncId => YomiTrackerIds.bangumi;

  @override
  Map<String, String> headers() => {
    'User-Agent': 'yomihub/0.1.4 (https://github.com/kodjodevf/mangayomi)',
    'Accept': 'application/json',
    if (auth['token'] != null) 'Authorization': 'Bearer ${auth['token']}',
  };

  static Future<String?> login(String token) async {
    try {
      final r = await _YomiTrackerBase.trackerClient.get(
        Uri.parse('$_api/v0/me'),
        headers: {
          'User-Agent': 'yomihub/0.2.7',
          'Authorization': 'Bearer ${token.trim()}',
        },
      );
      if (r.statusCode >= 300) return tr('Bangumi: token không hợp lệ (HTTP {p0})', {'p0': r.statusCode});
      final me = jsonDecode(r.body) as Map<String, dynamic>;
      await YomiTrackerAuth.save(
        YomiTrackerIds.bangumi,
        '${me['username'] ?? me['id']}',
        {'token': token.trim(), 'username': me['username']},
        avatarUrl: me['avatar']?['medium'] as String?,
      );
      return null;
    } catch (e) {
      return '$e';
    }
  }

  @override
  List<TrackStatus> statusList(bool isManga) => isManga
      ? [
          TrackStatus.reading,
          TrackStatus.completed,
          TrackStatus.onHold,
          TrackStatus.dropped,
          TrackStatus.planToRead,
        ]
      : [
          TrackStatus.watching,
          TrackStatus.completed,
          TrackStatus.onHold,
          TrackStatus.dropped,
          TrackStatus.planToWatch,
        ];

  int _toApi(TrackStatus s) => switch (s) {
    TrackStatus.planToRead || TrackStatus.planToWatch => 1,
    TrackStatus.completed => 2,
    TrackStatus.onHold => 4,
    TrackStatus.dropped => 5,
    _ => 3,
  };

  TrackStatus _fromApi(int? t, bool isManga) => switch (t) {
    1 => isManga ? TrackStatus.planToRead : TrackStatus.planToWatch,
    2 => TrackStatus.completed,
    4 => TrackStatus.onHold,
    5 => TrackStatus.dropped,
    _ => isManga ? TrackStatus.reading : TrackStatus.watching,
  };

  @override
  Future<List<TrackSearch>> search(String query, bool isManga) async {
    final r = await sendJson('POST', '$_api/v0/search/subjects?limit=20', {
      'keyword': query,
      'sort': 'match',
      'filter': {
        'type': [isManga ? 1 : 2],
      },
    });
    final data = (r?['data'] as List?) ?? const [];
    return data.map((e) {
      final cn = (e['name_cn'] as String?) ?? '';
      return TrackSearch(
        mediaId: (e['id'] as num?)?.toInt(),
        syncId: syncId,
        title: cn.isNotEmpty ? '$cn (${e['name']})' : e['name'] ?? '',
        coverUrl: e['images']?['common'] ?? e['images']?['medium'] ?? '',
        summary: e['summary'] ?? '',
        totalChapter: ((isManga ? e['volumes'] : e['eps']) as num?)?.toInt() ?? 0,
        score: (e['rating']?['score'] as num?)?.toDouble(),
        startDate: e['date'] ?? '',
        publishingType: e['platform'] ?? '',
        trackingUrl: 'https://bgm.tv/subject/${e['id']}',
      );
    }).toList();
  }

  @override
  Future<Track?> findLibItem(Track track, bool isManga) async {
    final user = auth['username'] ?? '-';
    final r = await getJson('$_api/v0/users/$user/collections/${track.mediaId}');
    if (r == null) return update(track, isManga);
    track.status = _fromApi((r['type'] as num?)?.toInt(), isManga);
    track.score = (r['rate'] as num?)?.toInt() ?? 0;
    track.lastChapterRead = (r['ep_status'] as num?)?.toInt() ?? 0;
    return track;
  }

  @override
  Future<Track> update(Track track, bool isManga) async {
    final url = '$_api/v0/users/-/collections/${track.mediaId}';
    await sendJson('POST', url, {
      'type': _toApi(track.status),
      'rate': (track.score ?? 0).clamp(0, 10),
    });
    if (isManga) {
      try {
        await sendJson('PATCH', url, {'ep_status': track.lastChapterRead ?? 0});
      } catch (_) {}
    } else {
      try {
        // legacy endpoint, still the simple way to set watched episodes
        await sendJson(
          'POST',
          '$_api/subject/${track.mediaId}/update/watched_eps?watched_eps=${track.lastChapterRead ?? 0}',
          null,
        );
      } catch (_) {}
    }
    return track;
  }
}

// ═════════════════════════════ Kavita ═════════════════════════════

/// Kavita server tracker (reading progress on your own Kavita server).
class KavitaTracker extends _YomiTrackerBase {
  @override
  int get syncId => YomiTrackerIds.kavita;

  String get _apiUrl {
    var u = '${auth['url'] ?? ''}'.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/api')) return u;
    return '$u/api';
  }

  @override
  Map<String, String> headers() => {
    'Accept': 'application/json',
    'User-Agent': 'YomiHub',
    if (auth['token'] != null) 'Authorization': 'Bearer ${auth['token']}',
  };

  static Future<String?> login(String url, String apiKey) async {
    var api = url.trim();
    while (api.endsWith('/')) {
      api = api.substring(0, api.length - 1);
    }
    // the OPDS url contains the key: …/api/opds/<apiKey>
    final opds = RegExp(r'/api/opds/([^/]+)').firstMatch(api);
    if (apiKey.trim().isEmpty && opds != null) apiKey = opds.group(1)!;
    api = api.split('/api/').first.replaceAll(RegExp(r'/api$'), '');
    try {
      final res = await _YomiTrackerBase.trackerClient.post(
        Uri.parse(
          '$api/api/Plugin/authenticate?apiKey=${Uri.encodeQueryComponent(apiKey.trim())}&pluginName=YomiHub',
        ),
        headers: {'Content-Type': 'application/json', 'User-Agent': 'YomiHub/0.2.7'},
        body: '{}',
      );
      if (res.statusCode >= 300) return 'Kavita: HTTP ${res.statusCode}';
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      await YomiTrackerAuth.save(YomiTrackerIds.kavita, '${d['username'] ?? 'Kavita'}', {
        'url': api,
        'apiKey': apiKey.trim(),
        'token': d['token'],
      });
      return null;
    } catch (e) {
      return '$e';
    }
  }

  @override
  Future<bool> checkRefresh() async {
    final a = auth;
    if (a.isEmpty) return false;
    final err = await login('${a['url']}', '${a['apiKey']}');
    return err == null;
  }

  @override
  List<TrackStatus> statusList(bool isManga) => [
    TrackStatus.reading,
    TrackStatus.completed,
    TrackStatus.planToRead,
  ];

  @override
  Future<List<TrackSearch>> search(String query, bool isManga) async {
    await checkRefresh();
    final r = await getJson(
      '$_apiUrl/Search/search?queryString=${Uri.encodeQueryComponent(query)}',
    );
    final series = (r?['series'] as List?) ?? const [];
    return series.map((e) {
      final id = (e['seriesId'] as num?)?.toInt();
      return TrackSearch(
        mediaId: id,
        syncId: syncId,
        title: e['name'] ?? '',
        coverUrl: '$_apiUrl/image/series-cover?seriesId=$id&apiKey=${auth['apiKey']}',
        trackingUrl: '$_apiUrl/Series/$id',
        publishingType: e['libraryName'] ?? '',
      );
    }).toList();
  }

  Future<int> _latestRead(int seriesId) async {
    try {
      final c = await getJson('$_apiUrl/Tachiyomi/latest-chapter?seriesId=$seriesId');
      return double.tryParse('${c?['number'] ?? 0}'.replaceAll(',', '.'))?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Track?> findLibItem(Track track, bool isManga) async {
    await checkRefresh();
    final s = await getJson('$_apiUrl/Series/${track.mediaId}');
    if (s == null) return null;
    final pages = (s['pages'] as num?)?.toInt() ?? 0;
    final read = (s['pagesRead'] as num?)?.toInt() ?? 0;
    track.status = read == 0
        ? TrackStatus.planToRead
        : read >= pages
        ? TrackStatus.completed
        : TrackStatus.reading;
    track.lastChapterRead = await _latestRead(track.mediaId!);
    return track;
  }

  @override
  Future<Track> update(Track track, bool isManga) async {
    await checkRefresh();
    await sendJson(
      'POST',
      '$_apiUrl/Tachiyomi/mark-chapter-until-as-read?seriesId=${track.mediaId}&chapterNumber=${track.lastChapterRead ?? 0}',
      '{}',
    );
    return (await findLibItem(track, isManga)) ?? track;
  }
}

// ═════════════════════════════ Suwayomi ═════════════════════════════

/// Suwayomi-Server (Tachidesk) tracker: progress on your own server.
class SuwayomiTracker extends _YomiTrackerBase {
  @override
  int get syncId => YomiTrackerIds.suwayomi;

  String get _base {
    var u = '${auth['url'] ?? ''}'.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  @override
  Map<String, String> headers() {
    final a = auth;
    final user = '${a['user'] ?? ''}';
    return {
      'Accept': 'application/json',
      'User-Agent': 'YomiHub',
      if (user.isNotEmpty)
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$user:${a['password'] ?? ''}'))}',
    };
  }

  static Future<String?> login(String url, String user, String password) async {
    var base = url.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    try {
      final res = await _YomiTrackerBase.trackerClient.get(
        Uri.parse('$base/api/v1/settings/about'),
        headers: {
          'User-Agent': 'YomiHub/0.2.7',
          if (user.isNotEmpty)
            'Authorization': 'Basic ${base64Encode(utf8.encode('$user:$password'))}',
        },
      );
      if (res.statusCode >= 300) return 'Suwayomi: HTTP ${res.statusCode}';
      final about = jsonDecode(res.body) as Map<String, dynamic>;
      await YomiTrackerAuth.save(
        YomiTrackerIds.suwayomi,
        '${about['name'] ?? 'Suwayomi'} ${about['version'] ?? ''}'.trim(),
        {'url': base, 'user': user, 'password': password},
      );
      return null;
    } catch (e) {
      return '$e';
    }
  }

  @override
  List<TrackStatus> statusList(bool isManga) => [
    TrackStatus.reading,
    TrackStatus.completed,
    TrackStatus.planToRead,
  ];

  @override
  Future<List<TrackSearch>> search(String query, bool isManga) async {
    final q = query.toLowerCase();
    final cats = await getJson('$_base/api/v1/category') as List? ?? const [];
    final ids = {0, ...cats.map((c) => (c['id'] as num).toInt())};
    final out = <int, TrackSearch>{};
    for (final id in ids) {
      final list = await getJson('$_base/api/v1/category/$id') as List? ?? const [];
      for (final m in list) {
        final title = '${m['title'] ?? ''}';
        if (q.isNotEmpty && !title.toLowerCase().contains(q)) continue;
        final mid = (m['id'] as num).toInt();
        out[mid] = TrackSearch(
          mediaId: mid,
          syncId: syncId,
          title: title,
          coverUrl: '$_base/api/v1/manga/$mid/thumbnail',
          summary: '${m['description'] ?? ''}',
          totalChapter: (m['chapterCount'] as num?)?.toInt() ?? 0,
          trackingUrl: '$_base/api/v1/manga/$mid',
        );
      }
    }
    return out.values.toList();
  }

  @override
  Future<Track?> findLibItem(Track track, bool isManga) async {
    final m = await getJson('$_base/api/v1/manga/${track.mediaId}/full');
    if (m == null) return null;
    final count = (m['chapterCount'] as num?)?.toInt() ?? 0;
    final unread = (m['unreadCount'] as num?)?.toInt() ?? 0;
    track.totalChapter = count;
    track.lastChapterRead =
        (m['lastChapterRead']?['chapterNumber'] as num?)?.toInt() ?? 0;
    track.status = unread == count
        ? TrackStatus.planToRead
        : unread == 0
        ? TrackStatus.completed
        : TrackStatus.reading;
    return track;
  }

  @override
  Future<Track> update(Track track, bool isManga) async {
    final chapters =
        await getJson('$_base/api/v1/manga/${track.mediaId}/chapters') as List? ??
        const [];
    final target = track.lastChapterRead ?? 0;
    Map? hit;
    for (final c in chapters) {
      final n = (c['chapterNumber'] as num?)?.toDouble() ?? -1;
      if (n.floor() == target) hit = c as Map;
    }
    if (hit != null) {
      await sendJson(
        'PUT',
        '$_base/api/v1/manga/${track.mediaId}/chapter/${hit['index']}',
        'markPrevRead=true&read=true',
        contentType: 'application/x-www-form-urlencoded',
      );
    }
    return (await findLibItem(track, isManga)) ?? track;
  }
}
