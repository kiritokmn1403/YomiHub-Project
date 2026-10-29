import 'dart:convert';

import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:mangayomi/eval/lnreader/http.dart';
import 'package:mangayomi/eval/lnreader/m_plugin.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_chapter.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/eval/model/source_preference.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/page.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/models/video.dart';
import 'package:mangayomi/modules/browse/extension/providers/extension_preferences_providers.dart';

import '../interface.dart';
import 'js_cheerio.dart';
import 'js_htmlparser.dart';
import 'js_libs.dart';
import 'js_polyfills.dart';

JavascriptRuntime getJavascriptRuntime({
  Map<String, dynamic>? extraArgs = const {},
}) {
  JavascriptRuntime runtime;
  runtime = QuickJsRuntime2(stackSize: 1024 * 1024 * 4);
  runtime.enableHandlePromises();
  return runtime;
}

/// LNReader plugin engine (YomiHub 0.1.4).
///
/// Fixes over the engine inherited from Mangayomi:
///  * `@libs/storage` really stores values and returns the plugin settings the
///    user picked (it always returned null, so plugins reading a setting such
///    as the site mirror or "hide locked chapters" broke);
///  * filters are shown and the selected values are passed to the plugin
///    (before, the plugin's default filter definitions were passed back);
///  * plugin settings are shown as extension preferences;
///  * `imageRequestInit` headers and a Referer are used for covers, and
///    relative cover / image URLs are made absolute;
///  * novels whose chapter list is split in pages (`totalPages`) load every
///    page instead of only the first one;
///  * `fetchText`, Headers, `setTimeout`, `atob`, `TextDecoder`… exist.
class LNReaderExtensionService implements ExtensionService {
  late JavascriptRuntime runtime;
  @override
  late Source source;
  bool _isInitialized = false;
  late JsCheerio _jsCheerio;

  LNReaderExtensionService(this.source);

  String get _site {
    final s = source.baseUrl ?? '';
    return s;
  }

  void _init() {
    if (_isInitialized) return;
    runtime = getJavascriptRuntime();
    runtime.evaluate('''
module={},exports=Function("return this")(),Object.defineProperties(module,{namespace:{set:function(a){exports=a}},exports:{set:function(a){for(var b in a)a.hasOwnProperty(b)&&(exports[b]=a[b])},get:function(){return exports}}});
''');
    JsPolyfills(runtime).init();
    JsHttpClient(runtime, sourceId: source.id, site: _site).init();
    JsLibs(runtime).init();
    JsHtmlParser(runtime).init();
    _jsCheerio = JsCheerio(runtime)..init();
    _initStorage();
    runtime.evaluate('''
const __yhDefaultCover = 'https://raw.githubusercontent.com/LNReader/lnreader-plugins/master/public/static/coverNotAvailable.webp';
const require = (package) => {
  switch (package) {
    case "htmlparser2":
        return {Parser: Parser};
    case "cheerio":
        return {load: load};
    case "dayjs":
        return module.exports.dayjs;
    case "urlencode":
        return {encode: urlencode, decode: urldecode};
    case "@libs/fetch":
        return {fetchApi: fetchApi, fetchText: fetchText, fetchProto: fetchProto, fetchFile: fetchApi};
    case "@libs/novelStatus":
        return {NovelStatus: NovelStatus};
    case "@libs/isAbsoluteUrl":
        return {isUrlAbsolute: isUrlAbsolute};
    case "@libs/filterInputs":
        return {
          FilterTypes: FilterTypes,
          isPickerValue: isPickerValue,
          isCheckboxValue: isCheckboxValue,
          isSwitchValue: isSwitchValue,
          isTextValue: isTextValue,
          isXCheckboxValue: isXCheckboxValue
        };
    case "@libs/defaultCover":
        return {defaultCover: __yhDefaultCover};
    case "@libs/storage":
        return {storage: storage, localStorage: localStorage, sessionStorage: sessionStorage};
    case "@/types/constants":
        return {defaultCover: __yhDefaultCover, NovelStatus: NovelStatus};
    case "@libs/aes":
        return {};
    default:
        return {};
  }
};
''');
    runtime.evaluate('''
${source.sourceCode}
const extension = exports.default;
''');
    _isInitialized = true;
  }

  /// Plugin storage. Keys declared in `pluginSettings` read the value the
  /// user chose in the extension preferences; anything else the plugin
  /// stores (tokens, cookies, cached ids) is kept per source.
  void _initStorage() {
    final id = source.id ?? 0;
    runtime.onMessage('lnr_storage_get', (dynamic args) {
      final key = '${args[0]}';
      try {
        final v = getPreferenceValue(id, key);
        return jsonEncode({'v': v});
      } catch (_) {}
      try {
        final raw = getSourcePreferenceStringValue(id, 'lnr_$key', '');
        if (raw.isEmpty) return jsonEncode({'v': null});
        final decoded = jsonDecode(raw) as Map;
        final exp = decoded['e'];
        if (exp is num && exp > 0 && DateTime.now().millisecondsSinceEpoch > exp) {
          setSourcePreferenceStringValue(id, 'lnr_$key', '');
          return jsonEncode({'v': null});
        }
        return jsonEncode({'v': decoded['v']});
      } catch (_) {
        return jsonEncode({'v': null});
      }
    });
    runtime.onMessage('lnr_storage_set', (dynamic args) {
      final key = '${args[0]}';
      final value = args.length > 1 ? args[1] : null;
      final expires = args.length > 2 ? args[2] : null;
      int? exp;
      if (expires is num) exp = expires.toInt();
      setSourcePreferenceStringValue(
        id,
        'lnr_$key',
        jsonEncode({'v': value, 'e': exp}),
      );
      return true;
    });
    runtime.onMessage('lnr_storage_del', (dynamic args) {
      setSourcePreferenceStringValue(id, 'lnr_${args[0]}', '');
      return true;
    });
    runtime.evaluate('''
const storage = {
  get(key, raw) {
    const r = JSON.parse(sendMessage("lnr_storage_get", JSON.stringify([key])));
    return raw ? { value: r.v } : r.v;
  },
  set(key, value, expires) {
    let e = null;
    if (expires instanceof Date) e = expires.getTime();
    else if (typeof expires === 'number') e = expires;
    sendMessage("lnr_storage_set", JSON.stringify([key, value === undefined ? null : value, e]));
  },
  delete(key) { sendMessage("lnr_storage_del", JSON.stringify([key])); },
  clearAll() {},
  getAllKeys() { return []; },
};
const localStorage = { get() { return {}; } };
const sessionStorage = { get() { return {}; } };
''');
  }

  @override
  void dispose() {
    if (!_isInitialized) return;
    _jsCheerio.dispose();
    _isInitialized = false;
  }

  Map<String, String>? _headersCache;

  /// Headers for covers and chapter images: the plugin's `imageRequestInit`
  /// plus a Referer on the site, which most novel sites check.
  @override
  Map<String, String> getHeaders() {
    if (_headersCache != null) return _headersCache!;
    final headers = <String, String>{};
    if (_site.isNotEmpty) headers['Referer'] = _site;
    try {
      final init = _extensionCall<dynamic>('imageRequestInit', null);
      if (init is Map && init['headers'] is Map) {
        (init['headers'] as Map).forEach((k, v) {
          if (k != null && v != null) headers['$k'] = '$v';
        });
      }
    } catch (_) {}
    return _headersCache = headers;
  }

  @override
  bool get supportsLatest {
    return true;
  }

  @override
  String get sourceBaseUrl {
    return source.baseUrl!;
  }

  String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('data:')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(url)) {
      return url;
    }
    final base = Uri.tryParse(_site);
    if (base == null) return url;
    try {
      return base.resolve(url).toString();
    } catch (_) {
      return url;
    }
  }

  List<MManga> _toMangaList(dynamic items) {
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => NovelItem.fromJson(Map<String, dynamic>.from(e)))
        .map(
          (e) => MManga(
            name: e.name,
            imageUrl: _abs(e.cover),
            link: e.path,
            chapters: [],
          ),
        )
        .toList();
  }

  @override
  Future<MPages> getPopular(int page) async {
    final items = _toMangaList(
      await _extensionCallAsync(
        'popularNovels($page, {showLatestNovels: false, filters: ${jsonEncode(_defaultFilterValues())}})',
        [],
      ),
    );
    return MPages(list: items, hasNextPage: items.isNotEmpty);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final items = _toMangaList(
      await _extensionCallAsync(
        'popularNovels($page, {showLatestNovels: true, filters: ${jsonEncode(_defaultFilterValues())}})',
        [],
      ),
    );
    return MPages(list: items, hasNextPage: items.isNotEmpty);
  }

  @override
  Future<MPages> search(String query, int page, List<dynamic> filters) async {
    final List<MManga> items;
    if (query.trim().isEmpty && _definedFilters().isNotEmpty) {
      // LNReader has no "search with filters": browsing with filters is
      // popularNovels() with the chosen values.
      items = _toMangaList(
        await _extensionCallAsync(
          'popularNovels($page, {showLatestNovels: false, filters: ${jsonEncode(_filterValues(filters))}})',
          [],
        ),
      );
    } else {
      items = _toMangaList(
        await _extensionCallAsync(
          'searchNovels(${jsonEncode(query)},$page)',
          [],
        ),
      );
    }
    return MPages(list: items, hasNextPage: items.isNotEmpty);
  }

  Status _status(String? s) {
    switch ((s ?? '').toLowerCase().trim()) {
      case 'ongoing':
        return Status.ongoing;
      case 'completed':
        return Status.completed;
      case 'publishing finished':
        return Status.publishingFinished;
      case 'on hiatus':
        return Status.onHiatus;
      case 'cancelled':
      case 'canceled':
        return Status.canceled;
      default:
        return Status.unknown;
    }
  }

  @override
  Future<MManga> getDetail(String url) async {
    final raw = await _extensionCallAsync<dynamic>(
      'parseNovel(${jsonEncode(url)})',
      <String, dynamic>{},
    );
    final json = Map<String, dynamic>.from(raw as Map);
    final item = SourceNovel.fromJson(json);
    final chapters = <ChapterItem>[...?item.chapters];
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final hasParsePage = _hasFunction('parsePage');
    if (hasParsePage && (chapters.isEmpty || totalPages > 1)) {
      final pages = totalPages > 0 ? totalPages : 1;
      final start = chapters.isEmpty ? 1 : 2;
      for (var p = start; p <= pages && p <= 500; p++) {
        try {
          final page = SourcePage.fromJson(
            Map<String, dynamic>.from(
              await _extensionCallAsync<dynamic>(
                'parsePage(${jsonEncode(item.path)}, ${jsonEncode('$p')})',
                <String, dynamic>{},
              ) as Map,
            ),
          );
          if (page.chapters.isEmpty) break;
          chapters.addAll(page.chapters);
        } catch (_) {
          break;
        }
      }
    }

    String date(String? t) {
      if (t == null || t.isEmpty) {
        return DateTime.now().millisecondsSinceEpoch.toString();
      }
      return DateTime.tryParse(t)?.millisecondsSinceEpoch.toString() ??
          int.tryParse(t)?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
    }

    final seen = <String>{};
    final chaps = chapters
        .where((e) => seen.add(e.path))
        .map(
          (e) => MChapter(
            name: e.name,
            url: e.path,
            dateUpload: date(e.releaseTime),
          ),
        )
        .toList();
    return MManga(
      name: item.name,
      imageUrl: _abs(item.cover),
      link: item.path,
      artist: item.artist,
      author: item.author,
      description: item.summary,
      status: _status(item.status),
      genre: item.genres
          ?.split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      chapters: chaps.reversed.toList(),
    );
  }

  @override
  Future<List<PageUrl>> getPageList(String url) async {
    return [];
  }

  @override
  Future<List<Video>> getVideoList(String url) async {
    return [];
  }

  @override
  Future<String> getHtmlContent(String name, String url) async {
    _init();
    final res = (await runtime.handlePromise(
      await runtime.evaluateAsync(
        'jsonStringify(() => extension.parseChapter(${jsonEncode(url)}))',
      ),
    )).stringResult;
    // Make relative image / link URLs absolute so the reader can load them.
    try {
      final decoded = jsonDecode(res);
      if (decoded is String) {
        return jsonEncode(absolutizeHtml(decoded, _site));
      }
    } catch (_) {}
    return res;
  }

  @override
  Future<String> cleanHtmlContent(String html) async {
    return html;
  }

  // ───────────── filters ─────────────

  Map<String, dynamic> _definedFilters() {
    try {
      final f = _extensionCall<dynamic>('filters', null);
      if (f is Map) return Map<String, dynamic>.from(f);
    } catch (_) {}
    return {};
  }

  Map<String, dynamic> _defaultFilterValues() {
    final out = <String, dynamic>{};
    _definedFilters().forEach((k, v) {
      if (v is Map) out[k] = {'type': v['type'], 'value': v['value']};
    });
    return out;
  }

  /// YomiHub filter widgets → LNReader `{key: {type, value}}`.
  Map<String, dynamic> _filterValues(List<dynamic> filters) {
    final out = _defaultFilterValues();
    for (final f in filters) {
      if (f is SelectFilter && f.type != null) {
        final opt = f.state >= 0 && f.state < f.values.length
            ? f.values[f.state]
            : null;
        out[f.type!] = {
          'type': 'Picker',
          'value': opt is SelectFilterOption ? opt.value : '',
        };
      } else if (f is TextFilter && f.type != null) {
        out[f.type!] = {'type': 'Text', 'value': f.state};
      } else if (f is CheckBoxFilter && f.type != null) {
        out[f.type!] = {'type': 'Switch', 'value': f.state};
      } else if (f is GroupFilter && f.type != null) {
        final items = f.state;
        if (items.isNotEmpty && items.first is TriStateFilter) {
          final include = <String>[], exclude = <String>[];
          for (final t in items.whereType<TriStateFilter>()) {
            if (t.state == 1) include.add(t.value);
            if (t.state == 2) exclude.add(t.value);
          }
          out[f.type!] = {
            'type': 'XCheckbox',
            'value': {'include': include, 'exclude': exclude},
          };
        } else {
          out[f.type!] = {
            'type': 'Checkbox',
            'value': items
                .whereType<CheckBoxFilter>()
                .where((c) => c.state)
                .map((c) => c.value)
                .toList(),
          };
        }
      }
    }
    return out;
  }

  /// LNReader filter definitions → YomiHub filter widgets.
  @override
  FilterList getFilterList() {
    final list = <dynamic>[];
    try {
      _definedFilters().forEach((key, raw) {
        if (raw is! Map) return;
        final type = '${raw['type']}';
        final label = '${raw['label'] ?? key}';
        final value = raw['value'];
        final options = (raw['options'] as List? ?? const [])
            .whereType<Map>()
            .map((o) => (label: '${o['label'] ?? o['value']}', value: '${o['value']}'))
            .toList();
        switch (type) {
          case 'Picker':
            final idx = options.indexWhere((o) => o.value == '$value');
            list.add(
              SelectFilter(
                key,
                label,
                idx < 0 ? 0 : idx,
                options
                    .map((o) => SelectFilterOption(o.label, o.value, null))
                    .toList(),
                'SelectFilter',
              ),
            );
          case 'Text':
            list.add(TextFilter(key, label, 'TextFilter', state: '${value ?? ''}'));
          case 'Switch':
            list.add(
              CheckBoxFilter(key, label, key, 'CheckBox', state: value == true),
            );
          case 'Checkbox':
            final sel = (value is List ? value : const []).map((e) => '$e').toSet();
            list.add(
              GroupFilter(
                key,
                label,
                options
                    .map(
                      (o) => CheckBoxFilter(
                        key,
                        o.label,
                        o.value,
                        'CheckBox',
                        state: sel.contains(o.value),
                      ),
                    )
                    .toList(),
                'GroupFilter',
              ),
            );
          case 'XCheckbox':
            final inc = <String>{}, exc = <String>{};
            if (value is Map) {
              inc.addAll(((value['include'] as List?) ?? const []).map((e) => '$e'));
              exc.addAll(((value['exclude'] as List?) ?? const []).map((e) => '$e'));
            }
            list.add(
              GroupFilter(
                key,
                label,
                options
                    .map(
                      (o) => TriStateFilter(
                        key,
                        o.label,
                        o.value,
                        'TriState',
                        state: inc.contains(o.value)
                            ? 1
                            : exc.contains(o.value)
                            ? 2
                            : 0,
                      ),
                    )
                    .toList(),
                'GroupFilter',
              ),
            );
        }
      });
    } catch (_) {}
    return FilterList(list);
  }

  // ───────────── plugin settings ─────────────

  @override
  List<SourcePreference> getSourcePreferences() {
    final out = <SourcePreference>[];
    try {
      final raw = _extensionCall<dynamic>('pluginSettings', null);
      if (raw is! Map) return out;
      raw.forEach((key, def) {
        if (def is! Map) return;
        final label = '${def['label'] ?? key}';
        final value = def['value'];
        final type = '${def['type'] ?? ''}';
        final options = (def['options'] as List? ?? const [])
            .whereType<Map>()
            .toList();
        final pref = SourcePreference(key: '$key', sourceId: source.id);
        if (type == 'Select' || type == 'Picker' || options.isNotEmpty) {
          final values = options.map((o) => '${o['value']}').toList();
          final idx = values.indexOf('$value');
          pref.listPreference = ListPreference(
            title: label,
            summary: '',
            valueIndex: idx < 0 ? 0 : idx,
            entries: options.map((o) => '${o['label'] ?? o['value']}').toList(),
            entryValues: values,
          );
        } else if (type == 'Switch' || value is bool) {
          pref.switchPreferenceCompat = SwitchPreferenceCompat(
            title: label,
            summary: '',
            value: value == true,
          );
        } else {
          pref.editTextPreference = EditTextPreference(
            title: label,
            summary: '',
            value: value == null ? '' : '$value',
            dialogTitle: label,
            dialogMessage: '',
            text: value == null ? '' : '$value',
          );
        }
        out.add(pref);
      });
    } catch (_) {}
    return out;
  }

  // ───────────── helpers ─────────────

  bool _hasFunction(String name) {
    _init();
    try {
      return runtime
              .evaluate('typeof extension.$name === "function"')
              .stringResult ==
          'true';
    } catch (_) {
      return false;
    }
  }

  T _extensionCall<T>(String call, T def) {
    _init();

    try {
      final res = runtime.evaluate('JSON.stringify(extension.$call)');
      if (res.stringResult == 'undefined' || res.stringResult.isEmpty) {
        return def;
      }
      return jsonDecode(res.stringResult) as T;
    } catch (_) {
      if (def != null) {
        return def;
      }
      rethrow;
    }
  }

  Future<T> _extensionCallAsync<T>(String call, T def) async {
    _init();
    final promised = await runtime.handlePromise(
      await runtime.evaluateAsync('jsonStringify(() => extension.$call)'),
    );
    final text = promised.stringResult;
    if (text.isEmpty || text == 'undefined') return def;
    return jsonDecode(text) as T;
  }
}

/// Makes `src`, `data-src`, `srcset` and `href` absolute against [site] and
/// promotes lazy-load attributes to `src`, so chapter images load in the
/// novel reader.
String absolutizeHtml(String html, String site) {
  final base = Uri.tryParse(site);
  String fix(String u) {
    final v = u.trim();
    if (v.isEmpty || v.startsWith('data:') || v.startsWith('#')) return v;
    if (v.startsWith('//')) return 'https:$v';
    if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(v)) {
      return v;
    }
    if (base == null) return v;
    try {
      return base.resolve(v).toString();
    } catch (_) {
      return v;
    }
  }

  // Lazy images: <img data-src="real" src="placeholder.gif">
  var out = html.replaceAllMapped(
    RegExp(r'<img\b[^>]*>', caseSensitive: false),
    (m) {
      var tag = m.group(0)!;
      final lazy = RegExp(
        r'''\s(?:data-src|data-lazy-src|data-original|data-url|data-cfsrc)\s*=\s*(["'])(.*?)\1''',
        caseSensitive: false,
      ).firstMatch(tag);
      if (lazy != null) {
        final real = lazy.group(2)!;
        if (RegExp(r'''\ssrc\s*=''', caseSensitive: false).hasMatch(tag)) {
          tag = tag.replaceFirst(
            RegExp(r'''\ssrc\s*=\s*(["']).*?\1''', caseSensitive: false),
            ' src="$real"',
          );
        } else {
          tag = tag.replaceFirst(RegExp(r'<img', caseSensitive: false), '<img src="$real"');
        }
      }
      return tag;
    },
  );
  out = out.replaceAllMapped(
    RegExp(r'''(\s(?:src|href)\s*=\s*)(["'])(.*?)\2''', caseSensitive: false),
    (m) => '${m.group(1)}${m.group(2)}${fix(m.group(3)!)}${m.group(2)}',
  );
  return out;
}
