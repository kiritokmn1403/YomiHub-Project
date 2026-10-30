import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/eval/model/source_preference.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/browse/extension/providers/extension_preferences_providers.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/kotatsu/kotatsu_bridge.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';

/// YomiHub 0.1.7 – "Đổi URL" / "Cưỡng chế đổi URL" for any extension.
///
/// * **Đổi URL**: writes the new address into the extension's own domain
///   setting when it has one (Mihon "Override BaseUrl", Mangayomi
///   "domain_url"…), and into the source's base URL – kept across extension
///   updates.
/// * **Cưỡng chế đổi URL**: on top of that, every request YomiHub makes to
///   the old host (pages, covers, chapter links already saved in the
///   library, downloads) is sent to the new host instead – for extensions
///   that hard-code their domain.
class YomiUrlOverride {
  YomiUrlOverride._();

  static const _key = 'urlOverrides';
  static Map<String, dynamic>? _cache;

  /// sourceId → {from, to, force}
  static Map<String, dynamic> get _all {
    _ensureLoaded();
    return _cache ?? <String, dynamic>{};
  }

  static void _ensureLoaded() {
    if (_cache != null) return;
    if (!YomiPrefs.isOpen) return; // not ready yet: try again next time
    try {
      final raw = YomiPrefs.get<String>(_key, '');
      _cache = raw.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      _cache = <String, dynamic>{};
    }
    _rebuild();
  }

  static Map<String, Uri> _forced = {};

  static void _rebuild() {
    final m = <String, Uri>{};
    for (final v in (_cache ?? const {}).values) {
      if (v is! Map || v['force'] != true) continue;
      final from = Uri.tryParse('${v['from']}');
      final to = Uri.tryParse('${v['to']}');
      if (from == null || to == null || from.host.isEmpty || to.host.isEmpty)
        continue;
      m[from.host.toLowerCase()] = to;
    }
    _forced = m;
    pushNative();
  }

  /// YomiHub 0.2.1: the forced host map (and the DNS-over-HTTPS fallback
  /// mode) also go to the JVM extension runtimes on Android – Mihon/Aniyomi
  /// APKs, Kotatsu and IReader – which use their own OkHttp clients.
  static Future<void> pushNative() async {
    if (!Platform.isAndroid) return;
    try {
      await const MethodChannel('com.yomihub/tools').invokeMethod('netConfig', {
        'rewrites': {
          for (final e in _forced.entries)
            e.key:
                '${e.value.scheme}://${e.value.host}${e.value.hasPort ? ':${e.value.port}' : ''}',
        },
        'doh': YomiPrefs.isOpen
            ? YomiPrefs.get<String>('nativeDoh', 'auto')
            : 'auto',
      });
    } catch (_) {}
  }

  /// Called once the prefs are open (start-up).
  static void init() => _ensureLoaded();

  static Future<void> _save() async {
    _rebuild();
    await YomiPrefs.set(_key, jsonEncode(_cache));
  }

  static Map<String, dynamic>? of(int? sourceId) {
    if (sourceId == null) return null;
    final v = _all['$sourceId'];
    if (v is Map) return Map<String, dynamic>.from(v);
    // Check if source belongs to a merge group and shares an override
    final group = YomiMerge.groupOf(sourceId);
    // 0.4.3: hand-picked groups mix different websites – never share domains
    if (group != null && !YomiMerge.isCustom(group.$1)) {
      final primaryId = group.$2['primary'] as int?;
      if (primaryId != null && primaryId != sourceId) {
        final pv = _all['$primaryId'];
        if (pv is Map) return Map<String, dynamic>.from(pv);
      }
      for (final m in (group.$2['members'] as List? ?? const [])) {
        if (m is int && m != sourceId) {
          final mv = _all['$m'];
          if (mv is Map) return Map<String, dynamic>.from(mv);
        }
      }
    }
    return null;
  }

  /// Base URL to keep for [sourceId] after an extension update.
  static String? baseUrlFor(int? sourceId, String? fromRepo) {
    final o = of(sourceId);
    return o == null ? fromRepo : '${o['to']}';
  }

  static const Map<String, List<String>> defaultMirrors = {
    'ln.hako.vn': [
      'https://ln.hako.vn',
      'https://docln.sbs',
      'https://docln.net',
    ],
    'docln.sbs': [
      'https://ln.hako.vn',
      'https://docln.sbs',
      'https://docln.net',
    ],
    'animevietsub.news': [
      'https://animevietsub.news',
      'https://animevietsub.nl',
      'https://animevietsub.sale',
    ],
    'animevietsub.sale': [
      'https://animevietsub.news',
      'https://animevietsub.sale',
      'https://animevietsub.nl',
    ],
    'animevietsub.nl': [
      'https://animevietsub.news',
      'https://animevietsub.nl',
      'https://animevietsub.tv',
      'https://animevietsub.moe',
    ],
    'animevn.net': [
      'https://animevn.net',
      'https://animevn.tv',
      'https://animevn.vip',
    ],
    'rophimhd.com': [
      'https://www.rophimhd.com',
      'https://rophim.me',
      'https://rophim.net',
    ],
    'hotphim.org': [
      'https://hotphim.org',
      'https://hotphim.net',
      'https://hotphim.tv',
    ],
    'haychill.tv': ['https://phimhaychill.org', 'https://phimhaychill.top'],
    'phimhaychill.org': [
      'https://phimhaychill.org',
      'https://phimhaychill.top',
    ],
    'xemphimgi.net': [
      'https://xemphimgi.net',
      'https://xemphimgi.com',
      'https://xemphimgi.tv',
    ],
    'hihiphim.com': ['https://hihiphim.com', 'https://hihiphim.co'],
    'hihiphim.co': ['https://hihiphim.com', 'https://hihiphim.co'],
    'nextphim.com': [
      'https://nextphim.com',
      'https://nextphim.net',
      'https://nextphim.tv',
    ],
    'vfilm.tv': ['http://vfilm.vn'],
    'vfilm.vn': ['http://vfilm.vn'],
    'top1sexvn.com': ['https://top1sexvn.com', 'https://sexviettop.com'],
    'cbhentai.com': ['https://cbhentai.com', 'https://cbhentai.biz'],
    'hentaicube.xyz': ['https://hentaicube.xyz', 'https://2tencb.pro'],
    '2tencb.pro': ['https://hentaicube.xyz', 'https://2tencb.pro'],
    'damconuong.pet': ['https://damconuong.pet', 'https://damconuong.name'],
    'damconuong.name': ['https://damconuong.pet', 'https://damconuong.name'],
    'sayhentai.cx': [
      'https://sayhentai.cx',
      'https://sayhentais.com',
      'https://sayhentaii.art',
    ],
    'sayhentais.com': [
      'https://sayhentai.cx',
      'https://sayhentais.com',
      'https://sayhentaii.art',
    ],
    'sayhentaii.art': [
      'https://sayhentai.cx',
      'https://sayhentais.com',
      'https://sayhentaii.art',
    ],
    'xoilacxxi.cc': [
      'https://xoilacxxi.cc',
      'https://xoilacvb.cc',
      'https://xoilac32.org',
    ],
    'xoilacvb.cc': [
      'https://xoilacxxi.cc',
      'https://xoilacvb.cc',
      'https://xoilac32.org',
    ],
    'xoilac32.org': [
      'https://xoilacxxi.cc',
      'https://xoilacvb.cc',
      'https://xoilac32.org',
    ],
    'nhentai.net': ['https://nhentai.net', 'https://nhentai.xxx'],
    // 0.4.4 (sheet "Website Extension"): every URL listed for the source
    'xemphimgi.com': ['https://xemphimgi.com', 'https://xemphimgi.net', 'https://xemphimgi.tv'],
    'nextphim.net': ['https://nextphim.net', 'https://nextphim.com', 'https://nextphim.tv'],
    'phimmoii.mom': ['https://phimmoii.mom', 'https://messiahelartista.com', 'https://phimmois.sh'],
    'messiahelartista.com': ['https://phimmoii.mom', 'https://messiahelartista.com', 'https://phimmois.sh'],
    'phimmois.sh': ['https://phimmoii.mom', 'https://messiahelartista.com', 'https://phimmois.sh'],
    'motphimc.my': ['https://motphimc.my', 'https://motphim.website', 'https://motchill10.io'],
    'motphim.website': ['https://motphimc.my', 'https://motphim.website', 'https://motchill10.io'],
    'motchill10.io': ['https://motphimc.my', 'https://motphim.website', 'https://motchill10.io'],
    // 0.4.5 (sheet "Website Extension"): VTV Go also served from cache.vtvgo.vn (same API/Origin accepted)
    'vtvgo.vn': ['https://vtvgo.vn', 'https://cache.vtvgo.vn'],
    'cache.vtvgo.vn': ['https://vtvgo.vn', 'https://cache.vtvgo.vn'],
  };

  static List<String> getCustomMirrors(int? sourceId, String? host) {
    if (!YomiPrefs.isOpen) return const [];
    try {
      final raw = YomiPrefs.get<Map>('customMirrors', const {});
      final list = <String>[];
      if (sourceId != null && raw.containsKey('$sourceId')) {
        list.addAll((raw['$sourceId'] as List).cast<String>());
      }
      if (host != null && raw.containsKey(host)) {
        list.addAll((raw[host] as List).cast<String>());
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> addCustomMirror(
    int? sourceId,
    String? host,
    String mirrorUrl,
  ) async {
    if (!YomiPrefs.isOpen) return;
    final norm = normalise(mirrorUrl);
    if (norm == null) return;
    final raw = Map<String, dynamic>.from(
      YomiPrefs.get<Map>('customMirrors', const {}),
    );
    final key = sourceId != null ? '$sourceId' : (host ?? '');
    if (key.isEmpty) return;
    final list = List<String>.from((raw[key] as List? ?? const []));
    if (!list.contains(norm)) {
      list.add(norm);
      raw[key] = list;
      await YomiPrefs.set('customMirrors', raw);
    }
  }

  static Future<void> removeCustomMirror(
    int? sourceId,
    String? host,
    String mirrorUrl,
  ) async {
    if (!YomiPrefs.isOpen) return;
    final norm = normalise(mirrorUrl);
    if (norm == null) return;
    final raw = Map<String, dynamic>.from(
      YomiPrefs.get<Map>('customMirrors', const {}),
    );
    final key = sourceId != null ? '$sourceId' : (host ?? '');
    if (key.isEmpty) return;
    final list = List<String>.from((raw[key] as List? ?? const []));
    list.remove(norm);
    raw[key] = list;
    await YomiPrefs.set('customMirrors', raw);
  }

  static List<String> getMirrorsFor(String? url, [int? sourceId]) {
    if (url == null || url.isEmpty) return const [];
    final host =
        Uri.tryParse(url)?.host.toLowerCase().replaceAll('www.', '') ?? '';
    final results = <String>{};
    if (host.isNotEmpty) {
      for (final entry in defaultMirrors.entries) {
        final k = entry.key.toLowerCase().replaceAll('www.', '');
        if (host == k || host.contains(k) || k.contains(host)) {
          results.addAll(entry.value);
        }
      }
    }
    results.addAll(getCustomMirrors(sourceId, host));
    return results.toList();
  }

  /// YomiHub 0.4.1: Universal URL sanitizer and base resolver.
  /// Fixes missing domain slashes (e.g. mimihentai.net24403), double protocols,
  /// encoded concatenated URLs (e.g. sayhentaii.art/https%3A...), Kotatsu local bridge images,
  /// protocol-relative URLs, and relative paths without base URL.
  static String sanitizeUrl(
    String raw, {
    String? baseUrl,
    Map<dynamic, dynamic>? headers,
  }) {
    var url = raw.trim();
    if (url.isEmpty) return baseUrl ?? '';

    // If the entire string is URL-encoded http/https
    if (url.startsWith('http%3A') || url.startsWith('https%3A') || url.startsWith('http%3a') || url.startsWith('https%3a')) {
      url = Uri.decodeFull(url);
    }

    // Fix concatenated encoded URLs e.g. "https://sayhentaii.art/https%3A%2F%2F..." or "page=https%3A%2F%2F..."
    final encHttpMatch = RegExp(r'(?:/|=)(https?%3A%2F%2F.*)$', caseSensitive: false).firstMatch(url);
    if (encHttpMatch != null) {
      final decoded = Uri.decodeFull(encHttpMatch.group(1)!);
      if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
        url = decoded;
      }
    }

    // Strip accidental concatenated unencoded protocols e.g. "https://vi-hentai.moehttps://2tencb.top/..."
    final secondHttp = url.indexOf('http://', 7) != -1
        ? url.indexOf('http://', 7)
        : url.indexOf('https://', 7);
    if (secondHttp != -1) {
      url = url.substring(secondHttp);
    }

    // Fix protocol-relative URLs e.g. "//images.com/pic.jpg"
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Fix missing slash between domain TLD and numeric ID e.g. "mimihentai.net24403" -> "mimihentai.net/24403"
    url = url.replaceFirstMapped(
      RegExp(
        r'^(https?://[^/\s:]+?\.(?:online|store|hentai|gold|shop|info|live|site|club|help|moe|xyz|art|pro|top|org|net|com|dev|app|biz|fun|to|co|vn|ru|cc|is|pw|ws|tv|me))([0-9]+.*)$',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}/${m.group(2)}',
    );

    // If still missing scheme, resolve with baseUrl, headers, or heuristic fallback
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      String? base = baseUrl;
      if ((base == null || base.isEmpty) && headers != null) {
        for (final entry in headers.entries) {
          final k = entry.key?.toString().toLowerCase();
          if (k == 'referer' && entry.value != null && entry.value.toString().startsWith('http')) {
            final refUri = Uri.tryParse(entry.value.toString());
            if (refUri != null && refUri.hasScheme && refUri.host.isNotEmpty) {
              base = '${refUri.scheme}://${refUri.host}';
              break;
            }
          }
        }
      }
      if ((base == null || base.isEmpty) && headers != null) {
        for (final entry in headers.entries) {
          final k = entry.key?.toString().toLowerCase();
          if (k == 'host' && entry.value != null && entry.value.toString().isNotEmpty) {
            base = 'https://${entry.value}';
            break;
          }
        }
      }
      if (base == null || base.isEmpty) {
        if (url.contains('hentai') || url.contains('sono-bisque')) {
          base = 'https://hentaivn.gold';
        } else if (url.contains('truyen')) {
          base = 'https://truyenvn.shop';
        } else if (url.contains('phim') || url.contains('anime')) {
          base = 'https://ophim1.com';
        } else {
          base = 'https://hentaivn.gold';
        }
      }
      final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      final cleanPath = url.startsWith('/') ? url : '/$url';
      url = '$cleanBase$cleanPath';
    }

    return url;
  }

  /// "https://example.org/" → "https://example.org"; null when invalid.
  static String? normalise(String input) {
    var t = input.trim();
    if (t.isEmpty) return null;
    if (!t.contains('://')) t = 'https://$t';
    final u = Uri.tryParse(t);
    if (u == null ||
        u.host.isEmpty ||
        !(u.scheme == 'http' || u.scheme == 'https'))
      return null;
    var s = '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}${u.path}';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Preferences that look like the extension's own domain setting.
  static List<SourcePreference> domainPrefs(List<SourcePreference>? prefs) {
    if (prefs == null) return const [];
    final re = RegExp(
      r'domain|base_?url|baseurl|mirror|tên miền|url',
      caseSensitive: false,
    );
    return prefs.where((p) {
      final t = p.editTextPreference?.title ?? p.listPreference?.title ?? '';
      return (p.editTextPreference != null || p.listPreference != null) &&
          (re.hasMatch(p.key ?? '') || re.hasMatch(t));
    }).toList();
  }

  static Future<void> apply(
    Source source,
    String newUrl, {
    required bool force,
    List<SourcePreference>? prefs,
  }) async {
    _ensureLoaded();
    _cache ??= <String, dynamic>{};
    final to = normalise(newUrl)!;
    final previous = of(source.id);
    final from = '${previous?['from'] ?? source.baseUrl ?? ''}';
    _all['${source.id}'] = {'from': from, 'to': to, 'force': force};
    await _save();
    // the extension's own setting
    for (final p in domainPrefs(prefs)) {
      if (p.editTextPreference != null) {
        p.editTextPreference!.value = to;
        p.editTextPreference!.text = to;
        setPreferenceSetting(p, source);
      } else if (p.listPreference != null) {
        final vals = p.listPreference!.entryValues ?? const [];
        final i = vals.indexWhere((v) => normalise(v) == to);
        if (i >= 0) {
          p.listPreference!.valueIndex = i;
          setPreferenceSetting(p, source);
        }
      }
    }
    source.baseUrl = to;
    await sourceRepository.save(source);
    if (KotatsuBridge.isKotatsuSource(source)) {
      await KotatsuBridge.setDomain(source, to);
    }
    // Propagate URL override to all other members in the merge group
    final group = YomiMerge.groupOf(source.id);
    if (group != null && !YomiMerge.isCustom(group.$1)) {
      final members = (group.$2['members'] as List? ?? const []).cast<int>();
      for (final mId in members) {
        if (mId != source.id) {
          final mSource = sourceRepository.getById(mId);
          if (mSource != null) {
            _all['$mId'] = {
              'from': mSource.baseUrl ?? '',
              'to': to,
              'force': force,
            };
            mSource.baseUrl = to;
            await sourceRepository.save(mSource);
          }
        }
      }
    }
  }

  static Future<void> clear(Source source) async {
    final o = of(source.id);
    if (o == null) return;
    _all.remove('${source.id}');
    await _save();
    final from = '${o['from']}';
    if (from.isNotEmpty) {
      source.baseUrl = from;
      await sourceRepository.save(source);
    }
    if (KotatsuBridge.isKotatsuSource(source)) {
      await KotatsuBridge.setDomain(source, null);
    }
    final group = YomiMerge.groupOf(source.id);
    if (group != null && !YomiMerge.isCustom(group.$1)) {
      final members = (group.$2['members'] as List? ?? const []).cast<int>();
      for (final mId in members) {
        if (mId != source.id) {
          final mo = of(mId);
          _all.remove('$mId');
          final mSource = sourceRepository.getById(mId);
          if (mSource != null && mo != null && '${mo['from']}'.isNotEmpty) {
            mSource.baseUrl = '${mo['from']}';
            await sourceRepository.save(mSource);
          }
        }
      }
    }
  }

  /// Forced rewrite of [url] (old host → new host), or null.
  static Uri? rewrite(Uri url) {
    _ensureLoaded();
    if (_forced.isEmpty) return null;
    final to = _forced[url.host.toLowerCase()];
    if (to == null) return null;
    return url.replace(
      scheme: to.scheme,
      host: to.host,
      port: to.hasPort ? to.port : null,
    );
  }

  /// Quick check that the new address answers.
  static Future<String> test(String url) async {
    try {
      final r = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      return r.statusCode < 400
          ? tr('Trang trả lời HTTP {p0} – dùng được', {'p0': r.statusCode})
          : (r.statusCode == 403 || r.statusCode == 503
                ? tr(
                    'HTTP {p0} – có thể là Cloudflare (dùng Cloudflare Bypass hoặc WebView)',
                    {'p0': r.statusCode},
                  )
                : 'HTTP ${r.statusCode}');
    } catch (e) {
      return tr('Không kết nối được: {p0}', {'p0': e});
    }
  }
}

/// MClient interceptor for "Cưỡng chế đổi URL".
class YomiUrlRewriteInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final to = YomiUrlOverride.rewrite(request.url);
    if (to == null || request is! Request) return request;
    final r = Request(request.method, to)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
    if (request.bodyBytes.isNotEmpty) r.bodyBytes = request.bodyBytes;
    // the Host / Referer headers of the old domain would be rejected
    r.headers.removeWhere((k, _) => k.toLowerCase() == 'host');
    for (final h in ['referer', 'origin']) {
      final k = r.headers.keys.where((e) => e.toLowerCase() == h).firstOrNull;
      if (k != null) {
        final u = Uri.tryParse(r.headers[k]!);
        if (u != null && YomiUrlOverride.rewrite(u) != null) {
          r.headers[k] = YomiUrlOverride.rewrite(u).toString();
        }
      }
    }
    return r;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async => response;
}

/// Card on the extension detail page.
class YomiUrlOverrideCard extends StatefulWidget {
  final Source source;
  final List<SourcePreference>? prefs;
  final VoidCallback? onChanged;
  const YomiUrlOverrideCard({
    super.key,
    required this.source,
    this.prefs,
    this.onChanged,
  });

  @override
  State<YomiUrlOverrideCard> createState() => _YomiUrlOverrideCardState();
}

class _YomiUrlOverrideCardState extends State<YomiUrlOverrideCard> {
  Future<void> _edit({required bool force}) async {
    final o = YomiUrlOverride.of(widget.source.id);
    final ctrl = TextEditingController(
      text: '${o?['to'] ?? widget.source.baseUrl ?? ''}',
    );
    var mirrors = YomiUrlOverride.getMirrorsFor(
      widget.source.baseUrl,
      widget.source.id,
    );
    String? err;
    String? test;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(force ? tr('Cưỡng chế đổi URL') : tr('Đổi URL')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: tr('Địa chỉ mới'),
                  hintText: 'https://ten-mien-moi.com',
                  errorText: err,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Máy chủ dự phòng / URL phụ:'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...mirrors.map((m) {
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(m, style: const TextStyle(fontSize: 11)),
                      onPressed: () => set(() => ctrl.text = m),
                    );
                  }),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.add, size: 14),
                    label: Text(
                      tr('+ Thêm URL phụ'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      final addCtrl = TextEditingController();
                      final added = await showDialog<String>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text(tr('Thêm URL phụ')),
                          content: TextField(
                            controller: addCtrl,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'URL máy chủ mới',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: Text(tr('Huỷ')),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(c, addCtrl.text.trim()),
                              child: Text(tr('Thêm')),
                            ),
                          ],
                        ),
                      );
                      if (added != null && added.isNotEmpty) {
                        final norm = YomiUrlOverride.normalise(added);
                        if (norm != null) {
                          final host = Uri.tryParse(widget.source.baseUrl ?? '')
                              ?.host
                              .toLowerCase();
                          await YomiUrlOverride.addCustomMirror(
                            widget.source.id,
                            host,
                            norm,
                          );
                          set(() {
                            mirrors = YomiUrlOverride.getMirrorsFor(
                              widget.source.baseUrl,
                              widget.source.id,
                            );
                            ctrl.text = norm;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                force
                    ? tr(
                        'Mọi request tới “{p0}” (trang, ảnh, chương đã lưu, tải xuống) đều được chuyển sang địa chỉ mới – dùng khi tiện ích ghi cứng tên miền. Áp dụng cả cho tiện ích APK Mihon/Aniyomi, Kotatsu và IReader.',
                        {
                          'p0':
                              Uri.tryParse(
                                '${o?['from'] ?? widget.source.baseUrl}',
                              )?.host ??
                              '',
                        },
                      )
                    : tr(
                        'Ghi vào cài đặt tên miền của tiện ích (nếu có) và URL gốc của nguồn; giữ nguyên khi tiện ích cập nhật.',
                      ),
                style: const TextStyle(fontSize: 12),
              ),
              if (test != null) ...[
                const SizedBox(height: 8),
                Text(
                  test!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final n = YomiUrlOverride.normalise(ctrl.text);
                if (n == null) {
                  set(() => err = tr('URL không hợp lệ'));
                  return;
                }
                set(() => test = tr('Đang kiểm tra…'));
                final t = await YomiUrlOverride.test(n);
                set(() => test = t);
              },
              child: Text(tr('Kiểm tra')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Huỷ')),
            ),
            FilledButton(
              onPressed: () {
                if (YomiUrlOverride.normalise(ctrl.text) == null) {
                  set(() => err = tr('URL không hợp lệ'));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(tr('Lưu')),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await YomiUrlOverride.apply(
      widget.source,
      ctrl.text,
      force: force,
      prefs: widget.prefs,
    );
    if (!mounted) return;
    widget.onChanged?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final o = YomiUrlOverride.of(widget.source.id);
    final cs = Theme.of(context).colorScheme;
    final hasPref = YomiUrlOverride.domainPrefs(widget.prefs).isNotEmpty;
    final mirrors = YomiUrlOverride.getMirrorsFor(widget.source.baseUrl);
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('URL của tiện ích'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (o != null)
                  Chip(
                    label: Text(
                      o['force'] == true ? tr('Cưỡng chế') : tr('Đã đổi'),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              widget.source.baseUrl ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            if (o != null)
              Text(
                tr('Gốc: {p0}', {'p0': o['from']}),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            if (hasPref)
              Text(
                tr(
                  'Tiện ích có cài đặt tên miền riêng – sẽ được cập nhật cùng.',
                ),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            if (mirrors.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tr('Máy chủ dự phòng (Mirrors):'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: mirrors.map((m) {
                  final cur = (widget.source.baseUrl ?? '').replaceAll(
                    RegExp(r'/+$'),
                    '',
                  );
                  final isCurrent = cur == m.replaceAll(RegExp(r'/+$'), '');
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: isCurrent
                        ? const Icon(Icons.check, size: 14)
                        : null,
                    label: Text(m, style: const TextStyle(fontSize: 11)),
                    onPressed: isCurrent
                        ? null
                        : () async {
                            await YomiUrlOverride.apply(
                              widget.source,
                              m,
                              force: false,
                              prefs: widget.prefs,
                            );
                            if (!mounted) return;
                            widget.onChanged?.call();
                            setState(() {});
                          },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _edit(force: false),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(tr('Đổi URL')),
                ),
                TextButton.icon(
                  onPressed: () => _edit(force: true),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(tr('Cưỡng chế đổi URL')),
                ),
                if (o != null)
                  TextButton.icon(
                    onPressed: () async {
                      await YomiUrlOverride.clear(widget.source);
                      if (!mounted) return;
                      widget.onChanged?.call();
                      setState(() {});
                    },
                    icon: const Icon(Icons.undo),
                    label: Text(tr('Khôi phục')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
