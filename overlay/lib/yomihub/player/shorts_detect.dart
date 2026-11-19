import 'package:mangayomi/eval/model/filter.dart';

/// YomiHub 0.5.7 (U9 / FC26): does an extension offer short-form video?
///
/// Up to 0.5.6 the Short button only appeared for bundled extensions and for
/// external ones whose *SelectFilter* had an option literally named
/// "Shorts". Extensions declare it in many other ways; this file recognises
/// them without running any extension code (pure Dart, unit-tested):
///
///  1. a per-extension override ("Ép chế độ Short");
///  2. any filter – select option, check box, tri-state, sort entry, also
///     inside groups – whose name or value is a short-form word;
///  3. a capability flag in the source's `additionalParams` / `notes`;
///  4. known short-form sites by extension name or base URL (TikTok, Douyin,
///     Kuaishou, Instagram Reels, YouTube Shorts, FikFap…).
///
/// The feed itself follows the "Video Short Scroll" projects of the sheet
/// (ShortStream, Auto-Youtube-Shorts-Scroller, VideoShorts): one clip per
/// page, autoplay when in view, next clip preloaded, auto-advance at the end
/// – see `yomi_shorts.dart`.
class ShortsDetect {
  ShortsDetect._();

  /// Whole words / phrases that mean "short-form feed". A bare "short" is
  /// deliberately absent: "Short (< 4 min)" is a duration filter and
  /// "TV Short" an anime format, neither is a vertical feed.
  static const words = <String>{
    'shorts',
    'short video',
    'short videos',
    'short-form',
    'short form',
    'shortform',
    'shorties',
    'reels',
    'reel',
    'tiktok',
    'tiktoks',
    'douyin',
    'video ngắn',
    'video ngan',
    'clip ngắn',
    '短视频',
    '短影片',
    '抖音',
    'ショート',
    '쇼츠',
    'шортс',
  };

  /// Substrings of an extension name or host that identify a short-form site.
  static const sitePatterns = <String>[
    'tiktok',
    'douyin',
    'kuaishou',
    'tikwm',
    'fikfap',
    'youtube',
    'youtu.be',
    'instagram',
    'likee',
    'snackvideo',
    'triller',
    'tikporn',
    'fapreel',
    'shorties',
    'shorts',
    'reels',
    // 0.6.0 (YomiHub Update – Video Short Scroll): more short-form hosts
    'kwai',
    'redgifs',
    'xfree',
    'kwiky',
    'facebook.com/reel',
    'spotlight',
    'moj.app',
  ];

  static const _negations = <String>{
    'no', 'not', 'non', 'without', 'exclude', 'excluding', 'hide', 'hidden',
    'ẩn', 'không', 'bỏ', 'loại',
  };

  static final _split = RegExp(r'[\s_/|,;:()\[\]#]+');

  /// True when [text] is, or contains as whole words, a short-form word.
  static bool isShortWord(String? text) {
    if (text == null) return false;
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (words.contains(t)) return true;
    final tokens = t.split(_split).where((e) => e.isNotEmpty).toList();
    // "No shorts" / "Hide shorts" switch the feed OFF: applying such a
    // filter would remove exactly what we want, so it never counts.
    if (tokens.any(_negations.contains)) return false;
    for (var i = 0; i < tokens.length; i++) {
      if (words.contains(tokens[i])) return true;
      if (i + 1 < tokens.length && words.contains('${tokens[i]} ${tokens[i + 1]}')) {
        return true;
      }
    }
    // scripts without spaces
    for (final w in const ['短视频', '短影片', '抖音', 'ショート', '쇼츠']) {
      if (t.contains(w)) return true;
    }
    return false;
  }

  static int _optionIndex(List<dynamic> values) => values.indexWhere(
    (o) => o is SelectFilterOption && (isShortWord(o.value) || isShortWord(o.name)),
  );

  /// Index of the short-form option of a select filter, -1 when none.
  static int selectOption(SelectFilter filter) => _optionIndex(filter.values);

  /// Walks the filter tree. With [apply] the matching filters are switched
  /// to their short-form state (select → that option, check box → on,
  /// tri-state → include, sort → that entry). Returns how they were found.
  static List<String> scanFilters(List<dynamic> filters, {bool apply = false}) {
    final found = <String>[];
    void walk(List<dynamic> list) {
      for (final f in list) {
        if (f is GroupFilter) {
          walk(f.state);
        } else if (f is SelectFilter) {
          final i = _optionIndex(f.values);
          if (i >= 0) {
            found.add('select:${f.name}');
            if (apply) f.state = i;
          }
        } else if (f is SortFilter) {
          final i = _optionIndex(f.values);
          if (i >= 0) {
            found.add('sort:${f.name}');
            if (apply) f.state.index = i;
          }
        } else if (f is CheckBoxFilter) {
          if (isShortWord(f.name) || isShortWord(f.value)) {
            found.add('checkbox:${f.name}');
            if (apply) f.state = true;
          }
        } else if (f is TriStateFilter) {
          if (isShortWord(f.name) || isShortWord(f.value)) {
            found.add('tristate:${f.name}');
            if (apply) f.state = 1;
          }
        }
      }
    }

    walk(filters);
    return found;
  }

  static final _flag = RegExp(
    r'''["']?(?:supports?_?|has_?|is_?)?(?:shorts?|short_?videos?|reels)["']?\s*[:=]\s*["']?(?:true|1|yes)\b''',
    caseSensitive: false,
  );
  static final _tag = RegExp(r'(?:#|\[)\s*(?:shorts|short video|reels)\s*\]?', caseSensitive: false);

  /// Capability declared by the extension itself (`additionalParams` JSON
  /// such as `{"shorts": true}`, or a `#shorts` / `[shorts]` tag in `notes`).
  static bool declaresCapability({String? additionalParams, String? notes}) {
    if (additionalParams != null && _flag.hasMatch(additionalParams)) return true;
    if (notes != null && (_tag.hasMatch(notes) || _flag.hasMatch(notes))) return true;
    return false;
  }

  static bool isKnownSite({String? name, String? baseUrl}) {
    final n = (name ?? '').toLowerCase();
    var host = (baseUrl ?? '').toLowerCase();
    final parsed = Uri.tryParse(host);
    if (parsed != null && parsed.host.isNotEmpty) host = parsed.host;
    for (final p in sitePatterns) {
      if (n.contains(p) || host.contains(p)) return true;
    }
    return false;
  }

  /// Why the extension counts as a Short source: `forced`, `builtin`,
  /// `filter`, `capability`, `site`, `all` (0.6.1) – or null when it does not.
  static String? reason({
    required bool isVideoSource,
    bool forced = false,
    bool builtin = false,
    String? name,
    String? baseUrl,
    String? additionalParams,
    String? notes,
    List<dynamic> filters = const [],
    bool allSources = false,
  }) {
    if (!isVideoSource) return null;
    if (forced) return 'forced';
    if (builtin) return 'builtin';
    if (scanFilters(filters).isNotEmpty) return 'filter';
    if (declaresCapability(additionalParams: additionalParams, notes: notes)) {
      return 'capability';
    }
    if (isKnownSite(name: name, baseUrl: baseUrl)) return 'site';
    // 0.6.1: công tắc chung "Short Video cho mọi tiện ích video"
    if (allSources) return 'all';
    return null;
  }
}
