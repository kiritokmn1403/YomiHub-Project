import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/repos/extensions_repo_screen.dart'
    show YomiSuggestedRepo;

/// YomiHub 0.1.6: extension repos listed on wotaku.wiki and miyomi.app.
///
/// Once a day (first app start after 24 h) both directories are read in the
/// background:
///  * miyomi.app – its public directory API (the same read-only query the
///    website makes; the public key is read from the site's own script so a
///    key rotation does not break it);
///  * wotaku.wiki – the extension guide pages link each repo's GitHub
///    project; the usual index locations are probed and only URLs that
///    answer with a repo index are kept.
/// Results are cached and shown in Extensions Repo › "Kho đề xuất".
class YomiRepoDiscovery {
  YomiRepoDiscovery._();
  static const _boxName = 'yomihub_repo_discovery';
  static const _ua =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Mobile Safari/537.36';
  static Box? _box;
  static List<YomiSuggestedRepo> _items = const [];
  static DateTime? lastScan;
  static bool _running = false;

  static List<YomiSuggestedRepo> get items => _items;

  static const _apps = {
    'mihon', 'tachiyomi', 'tachiyomi sy', 'tachiyomi j2k', 'tachiyomi az',
    'tachiyomi at', 'aniyomi', 'nekoyomi', 'komikku', 'anikku', 'mangayomi',
    'lnreader', 'aidoku', 'yokai', 'animetail', 'kuukiyomi',
  };

  static Future<void> open() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox(_boxName);
      final at = _box!.get('at') as int?;
      if (at != null) lastScan = DateTime.fromMillisecondsSinceEpoch(at);
      final raw = _box!.get('items') as String?;
      if (raw != null) _items = _decode(raw);
    } catch (_) {}
  }

  /// 0.1.7: runs when the app opens (Feature Check: "khi mở ứng dụng"),
  /// at most once an hour so quick restarts don't re-download everything.
  static Future<void> dailyScan() async {
    await open();
    final at = lastScan;
    if (at != null && DateTime.now().difference(at).inMinutes < 60) return;
    await scan();
  }

  /// The "Website Scan - Extension Repo" list (besides wotaku / miyomi).
  static const sites = <String, String>{
    'https://bio.link/iitachiyomi': 'Tachiyomi & Mihon community',
    'https://mikkiio.github.io/repos/': 'MIYOMI (mikkiio)',
    'https://tachiyomitips.com/tachiyomi-extension-repo/': 'Tachiyomi Tips',
    'https://observeroftime.frama.io/tachiyomi-extensions/': 'Tachiyomi Extensions (frama.io)',
    'https://everythingmoe.com/post/aniyomirepo.html': 'EverythingMoe',
    'https://x.noz.one/': 'Mihon & Aniyomi Extensions (x.noz.one)',
  };

  /// Result of the last scan per website (shown in Extensions Repo).
  static Map<String, String> siteStatus = {};

  static Future<int> scan() async {
    if (_running) return _items.length;
    _running = true;
    try {
      final found = <String, YomiSuggestedRepo>{};
      final results = await Future.wait([
        _miyomi().catchError((_) => <YomiSuggestedRepo>[]),
        _wotaku().catchError((_) => <YomiSuggestedRepo>[]),
        for (final e in sites.entries)
          _generic(e.key, e.value).catchError((Object err) {
            siteStatus[e.value] = 'lỗi: $err';
            return <YomiSuggestedRepo>[];
          }),
      ]);
      for (final list in results) {
        for (final r in list) {
          found.putIfAbsent(_key(r.url), () => r);
        }
      }
      if (found.isNotEmpty) {
        _items = found.values.toList()..sort((a, b) => a.name.compareTo(b.name));
        await _box?.put('items', _encode(_items));
      }
      lastScan = DateTime.now();
      await _box?.put('at', lastScan!.millisecondsSinceEpoch);
      return _items.length;
    } finally {
      _running = false;
    }
  }

  static String _key(String u) {
    var s = u.trim().toLowerCase().replaceFirst('/refs/heads/', '/');
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static Future<http.Response> _get(String url, {Map<String, String>? h}) =>
      http
          .get(Uri.parse(url), headers: {'User-Agent': _ua, ...?h})
          .timeout(const Duration(seconds: 20));

  // ───────────── any repo list page (0.1.7) ─────────────

  static String _unescape(String s) => s
      .replaceAll('&quot;', '"')
      .replaceAll('&#x26;', '&')
      .replaceAll('&#38;', '&')
      .replaceAll('&#038;', '&')
      .replaceAll('&amp;', '&')
      .replaceAll(r'\/', '/');

  /// Reads a page that lists repos: one-click links
  /// (`tachiyomi://add-repo?url=…`, aniyomi/mihon/mangayomi/…), plain index
  /// URLs, x.noz.one-style mirror data, and GitHub projects (probed).
  static Future<List<YomiSuggestedRepo>> _generic(String page, String label) async {
    final r = await _get(page);
    if (r.statusCode != 200) {
      siteStatus[label] = 'HTTP ${r.statusCode}';
      return const [];
    }
    final html = _unescape(r.body);
    final origin = Uri.parse(page).origin;
    final cands = <String, String>{}; // url → name
    void add(String url, [String name = '']) {
      url = url.trim().replaceAll(RegExp(r'[.,;)]+$'), '');
      if (!_looksLikeIndex(url)) return;
      cands.putIfAbsent(url, () => name);
    }

    for (final m in RegExp(r'[a-z]+://add-repo\?url=([^"\s<>&]+)').allMatches(html)) {
      add(Uri.decodeComponent(m.group(1)!));
    }
    for (final m in RegExp(
      r'https://[^"\s<>]+?(?:index\.min\.json|index\.json|index\.pb|plugins\.min\.json|anime_index\.json|novel_index\.json)',
    ).allMatches(html)) {
      add(m.group(0)!);
    }
    // x.noz.one (Astro props): "name":[0,"Keiyoushi"],"path":[0,"/keiyoushi/index.pb"]
    for (final m in RegExp(r'"name":\[0,"([^"]+)"\],"path":\[0,"(/[^"]+)"\]').allMatches(html)) {
      add('$origin${m.group(2)}', m.group(1)!);
    }
    // GitHub projects of extension repos
    final gh = <String>{
      for (final m in RegExp(r'https://github\.com/([\w.\-]+)/([\w.\-]+)').allMatches(html))
        if (RegExp(r'ext|repo|yomi|sauce|source', caseSensitive: false).hasMatch(m.group(2)!))
          'https://github.com/${m.group(1)}/${m.group(2)}',
    };
    final out = <YomiSuggestedRepo>[];
    Future<void> verify(String url, String name) async {
      try {
        final res = await _get(url);
        if (res.statusCode != 200) return;
        final b = res.body.trimLeft();
        if (!(url.endsWith('.pb') || b.startsWith('[') || b.startsWith('{'))) return;
        out.add(YomiSuggestedRepo(url, name.isNotEmpty ? name : _nameOf(url), note: label));
      } catch (_) {}
    }

    await Future.wait([for (final e in cands.entries) verify(e.key, e.value)]);
    final known = out.map((e) => _key(e.url)).toSet();
    await Future.wait([
      for (final g in gh.take(25))
        _probe(g).then((url) {
          if (url == null || known.contains(_key(url))) return;
          out.add(YomiSuggestedRepo(url, Uri.parse(g).pathSegments.join('/'), note: label));
        }),
    ]);
    siteStatus[label] = '${out.length} kho';
    return out;
  }

  /// For tests / the repo screen: scan one listing page.
  static Future<List<YomiSuggestedRepo>> scanSite(String page, String label) => _generic(page, label);

  static String _nameOf(String url) {
    final u = Uri.parse(url);
    if (u.host == 'raw.githubusercontent.com' && u.pathSegments.length >= 2) {
      return '${u.pathSegments[0]}/${u.pathSegments[1]}';
    }
    final segs = u.pathSegments.where((e) => e.isNotEmpty).toList();
    return segs.length >= 2 ? '${u.host} • ${segs[segs.length - 2]}' : u.host;
  }

  // ───────────── miyomi.app ─────────────

  static Future<List<YomiSuggestedRepo>> _miyomi() async {
    var key = _box?.get('miyomiKey') as String? ?? '';
    var api = _box?.get('miyomiApi') as String? ?? 'https://miyomi-api.supabase.co';
    Future<http.Response> query() => _get(
      '$api/rest/v1/extensions?select=name,manual_url,types,compatible_with,'
      'language,short_description&status=eq.approved&order=name',
      h: {'apikey': key, 'Authorization': 'Bearer $key'},
    );
    http.Response? r;
    if (key.isNotEmpty) r = await query();
    if (r == null || r.statusCode != 200) {
      // Read the public key and API host from the site's own script.
      final page = await _get('https://miyomi.app/');
      final js = RegExp(r'src="(/assets/index-[^"]+\.js)"').firstMatch(page.body);
      if (js == null) return const [];
      final code = (await _get('https://miyomi.app${js.group(1)}')).body;
      final k = RegExp(
        r'eyJ[A-Za-z0-9_\-]+\.eyJ[A-Za-z0-9_\-]*cm9sZSI6ImFub24i[A-Za-z0-9_\-]*\.[A-Za-z0-9_\-]+',
      ).firstMatch(code);
      if (k == null) return const [];
      key = k.group(0)!;
      final host = RegExp(r'https://[a-z0-9\-]+\.supabase\.co').firstMatch(code);
      if (host != null) api = host.group(0)!;
      await _box?.put('miyomiKey', key);
      await _box?.put('miyomiApi', api);
      r = await query();
      if (r.statusCode != 200) return const [];
    }
    final out = <YomiSuggestedRepo>[];
    for (final e in (jsonDecode(r.body) as List).whereType<Map>()) {
      final url = '${e['manual_url'] ?? ''}'.trim();
      if (!_looksLikeIndex(url)) continue;
      final apps = [
        for (final a in (e['compatible_with'] as List? ?? const []))
          '$a'.toLowerCase(),
      ];
      if (apps.isNotEmpty && !apps.any(_apps.contains)) continue;
      final types = [for (final t in (e['types'] as List? ?? const [])) _type('$t')];
      out.add(
        YomiSuggestedRepo(
          url,
          '${e['name']}',
          note: 'miyomi.app • ${types.where((t) => t.isNotEmpty).join(', ')}'
              '${e['language'] != null ? ' • ${e['language']}' : ''}',
        ),
      );
    }
    return out;
  }

  static String _type(String t) => switch (t.toLowerCase()) {
    'manga' || 'comic' || 'manhwa' => 'Comic',
    'anime' || 'movie' || 'tv' => 'Film & Movie',
    'light novel' || 'novel' => 'Novel',
    _ => t,
  };

  static bool _looksLikeIndex(String url) {
    final u = url.toLowerCase().split('?').first;
    return u.startsWith('https://') &&
        (u.endsWith('.json') || u.endsWith('.pb'));
  }

  // ───────────── wotaku.wiki ─────────────

  static const _wotakuPages = [
    'https://wotaku.wiki/guides/ext/mihon',
    'https://wotaku.wiki/guides/ext/aniyomi',
    'https://wotaku.wiki/guides/ext/mangayomi',
    'https://wotaku.wiki/guides/ext/lnreader',
    'https://wotaku.wiki/ext',
  ];

  static Future<List<YomiSuggestedRepo>> _wotaku() async {
    final repos = <String, String>{}; // github owner/repo or github.io → name
    for (final p in _wotakuPages) {
      http.Response r;
      try {
        r = await _get(p);
      } catch (_) {
        continue;
      }
      if (r.statusCode != 200) continue;
      final kind = p.split('/').last;
      for (final m in RegExp(
        r'href="(https://(?:github\.com/[\w.\-]+/[\w.\-]+|[\w\-]+\.github\.io)/?)"[^>]*>([^<]*)<',
      ).allMatches(r.body)) {
        final link = m.group(1)!;
        if (link.contains('wotakumoe') || link.contains('/kodjodevf/mangayomi')) continue;
        repos.putIfAbsent(link, () => '${m.group(2)!.trim()}|$kind');
      }
    }
    final out = <YomiSuggestedRepo>[];
    await Future.wait([
      for (final e in repos.entries)
        _probe(e.key).then((url) {
          if (url == null) return;
          final parts = e.value.split('|');
          final name = parts.first.isNotEmpty ? parts.first : Uri.parse(e.key).pathSegments.last;
          out.add(YomiSuggestedRepo(url, name, note: 'wotaku.wiki • ${parts.last}'));
        }),
    ]);
    return out;
  }

  /// Usual index locations for a repo's GitHub project / Pages site.
  static Future<String?> _probe(String link) async {
    final u = Uri.parse(link);
    final cands = <String>[];
    if (u.host == 'github.com' && u.pathSegments.length >= 2) {
      final o = u.pathSegments[0], r = u.pathSegments[1];
      final base = r.replaceAll(RegExp(r'-source$'), '');
      for (final repo in {r, base, '$base-repo', 'extensions'}) {
        cands.addAll([
          'https://raw.githubusercontent.com/$o/$repo/repo/index.min.json',
          'https://raw.githubusercontent.com/$o/$repo/main/index.json',
        ]);
      }
    } else if (u.host.endsWith('.github.io')) {
      final o = u.host.split('.').first;
      cands.addAll([
        'https://${u.host}/index.min.json',
        'https://raw.githubusercontent.com/$o/extensions/repo/index.min.json',
      ]);
    }
    for (final c in cands) {
      try {
        final r = await _get(c);
        if (r.statusCode != 200) continue;
        final b = r.body.trimLeft();
        if (b.startsWith('[') || b.startsWith('{')) return c;
      } catch (_) {}
    }
    return null;
  }

  static String _encode(List<YomiSuggestedRepo> l) => jsonEncode([
    for (final r in l) {'u': r.url, 'n': r.name, 'd': r.note},
  ]);

  static List<YomiSuggestedRepo> _decode(String s) {
    try {
      return [
        for (final m in (jsonDecode(s) as List).whereType<Map>())
          YomiSuggestedRepo('${m['u']}', '${m['n']}', note: '${m['d'] ?? ''}'),
      ];
    } catch (_) {
      return const [];
    }
  }
}
