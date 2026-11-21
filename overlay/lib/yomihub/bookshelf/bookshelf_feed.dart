/// YomiHub 0.6.4 – Tủ Sách Cá Nhân, FN-16 + FN-29 (sheet Tinh_Nang_Chi_Tiet of
/// `Ke_Hoach_App_Quan_Ly_Tu_Sach_Ca_Nhan.xlsx`, group "6. Tin Tức & Gợi Ý NXB").
///
/// FN-16: a horizontal banner "Ấn phẩm liên quan tủ sách của bạn" – new books
///   of NXB Kim Đồng, Trẻ, IPM, AMAK, Hikari whose title matches a series in
///   the user's shelf (keyword matching, no server).
/// FN-29: settings – per-publisher on/off (+ editable address), kinds of news
///   (Limited, Artbook, Poster, ColorWalk, DataBook, Boxset), "Ẩn tin này",
///   "Không quan tâm bộ này", and a maximum number of banners.
///
/// The plan suggested a backend cron job; YomiHub has no server, so the app
/// reads the publishers' "new books" pages itself at most once a day (or when
/// the user taps refresh) and filters on the device. Pages are RSS/Atom or
/// plain HTML (the publishers' sites have no feeds – 21/11/2026), so both are
/// parsed. Everything is stored in the bookshelf box (in backups).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';
import 'package:xml/xml.dart';

class BsFeedSource {
  final String id;
  final String name;
  String url;
  bool enabled;
  BsFeedSource(this.id, this.name, this.url, {this.enabled = true});

  Map<String, Object> toJson() => {'id': id, 'name': name, 'url': url, 'enabled': enabled};
  factory BsFeedSource.fromJson(Map m) => BsFeedSource('${m['id']}', '${m['name']}', '${m['url'] ?? ''}',
      enabled: m['enabled'] != false);
}

/// Kinds of news the user can pick (FN-29). Detected from the title.
enum BsFeedKind { limited, artbook, poster, colorwalk, databook, boxset, regular }

class BsFeedItem {
  final String title;
  final String link;
  final String sourceId;
  final String image;
  const BsFeedItem({required this.title, required this.link, required this.sourceId, this.image = ''});

  String get key => link.isNotEmpty ? link : '$sourceId|$title';

  Map<String, Object> toJson() => {'title': title, 'link': link, 'source': sourceId, 'image': image};
  factory BsFeedItem.fromJson(Map m) => BsFeedItem(
      title: '${m['title'] ?? ''}', link: '${m['link'] ?? ''}', sourceId: '${m['source'] ?? ''}', image: '${m['image'] ?? ''}');
}

/// A feed item matched to a series of the shelf.
class BsFeedMatch {
  final BsFeedItem item;
  final BsSeries series;
  final Set<BsFeedKind> kinds;
  const BsFeedMatch(this.item, this.series, this.kinds);
}

class BookshelfFeed extends ChangeNotifier {
  BookshelfFeed._();
  static final BookshelfFeed instance = BookshelfFeed._();

  static const refreshEvery = Duration(hours: 24);

  /// Defaults – addresses checked 21/11/2026 (Kim Đồng, IPM, AMAK); NXB Trẻ
  /// and Hikari can be edited by the user (Hikari has no default address).
  static List<BsFeedSource> defaults() => [
        BsFeedSource('kimdong', 'NXB Kim Đồng', 'https://nxbkimdong.com.vn/sach-moi-phat-hanh'),
        BsFeedSource('tre', 'NXB Trẻ', 'https://www.nxbtre.com.vn/'),
        BsFeedSource('ipm', 'IPM', 'https://ipm.vn/collections/sach-moi'),
        BsFeedSource('amak', 'AMAK', 'https://amak.vn/book_cat/sach-moi/'),
        BsFeedSource('hikari', 'Hikari', '', enabled: false),
      ];

  BookshelfStore get _store => BookshelfStore.instance;

  // ── settings (FN-29) ──
  bool get enabled => _settings['enabled'] != false;
  int get maxBanners => (_settings['max'] as num?)?.toInt().clamp(1, 20) ?? 5;
  Set<BsFeedKind> get kinds => {
        for (final k in (_settings['kinds'] as List? ?? const []))
          for (final e in BsFeedKind.values)
            if (e.name == k) e
      };
  Set<String> get dismissed => {for (final d in (_settings['dismissed'] as List? ?? const [])) '$d'};
  Set<String> get mutedSeries => {for (final d in (_settings['muted'] as List? ?? const [])) '$d'};

  List<BsFeedSource> get sources {
    final saved = [for (final s in (_settings['sources'] as List? ?? const [])) if (s is Map) BsFeedSource.fromJson(s)];
    if (saved.isEmpty) return defaults();
    // keep publishers added in later versions
    final ids = saved.map((s) => s.id).toSet();
    return [...saved, ...defaults().where((d) => !ids.contains(d.id))];
  }

  Map get _settings => (_store.raw('feedSettings') as Map?) ?? const {};

  Future<void> _put(String k, Object v) async {
    final m = Map<String, Object?>.from(_settings)..[k] = v;
    await _store.putRaw('feedSettings', m);
    notifyListeners();
  }

  Future<void> setEnabled(bool v) => _put('enabled', v);
  Future<void> setMaxBanners(int v) => _put('max', v.clamp(1, 20));
  Future<void> setKinds(Set<BsFeedKind> v) => _put('kinds', [for (final k in v) k.name]);
  Future<void> setSources(List<BsFeedSource> v) => _put('sources', [for (final s in v) s.toJson()]);

  /// "Ẩn tin này".
  Future<void> dismiss(BsFeedItem i) {
    final d = dismissed.toList()..add(i.key);
    // keep the list bounded
    return _put('dismissed', d.length > 500 ? d.sublist(d.length - 500) : d);
  }

  /// "Không quan tâm bộ này".
  Future<void> muteSeries(String seriesId) => _put('muted', (mutedSeries..add(seriesId)).toList());
  Future<void> unmuteAll() async {
    await _put('muted', <String>[]);
    await _put('dismissed', <String>[]);
  }

  // ── cache ──
  List<BsFeedItem> get cached => [
        for (final e in (_store.raw('feedCache') as List? ?? const []))
          if (e is Map) BsFeedItem.fromJson(e)
      ];
  DateTime? get fetchedAt {
    final v = _store.raw('feedFetchedAt');
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
  }

  bool _busy = false;
  bool get busy => _busy;
  String? lastError;

  /// Matches for the banner (FN-16), filtered by the settings (FN-29).
  List<BsFeedMatch> get banners {
    if (!enabled) return const [];
    return filterMatches(
      items: cached,
      series: _store.series,
      enabledSources: {for (final s in sources) if (s.enabled) s.id},
      kinds: kinds,
      dismissed: dismissed,
      muted: mutedSeries,
      max: maxBanners,
    );
  }

  /// Fetches the publishers' pages when the cache is older than a day.
  Future<void> refresh({bool force = false, http.Client? client}) async {
    if (_busy || !enabled) return;
    final last = fetchedAt;
    if (!force && last != null && DateTime.now().difference(last) < refreshEvery) return;
    if (_store.series.isEmpty) return; // nothing to match
    _busy = true;
    lastError = null;
    notifyListeners();
    final c = client ?? http.Client();
    final out = <BsFeedItem>[];
    final failed = <String>[];
    try {
      for (final s in sources.where((s) => s.enabled && s.url.trim().isNotEmpty)) {
        try {
          final uri = Uri.parse(s.url.trim());
          final r = await c.get(uri, headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Mobile Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/rss+xml,application/atom+xml;q=0.9,*/*;q=0.8',
          }).timeout(const Duration(seconds: 20));
          if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
          final body = utf8.decode(r.bodyBytes, allowMalformed: true);
          out.addAll(parseFeed(body, uri, s.id));
        } catch (e) {
          failed.add('${s.name}: $e');
        }
      }
      if (out.isNotEmpty || failed.isEmpty) {
        await _store.putRaw('feedCache', [for (final i in out.take(400)) i.toJson()]);
        await _store.putRaw('feedFetchedAt', DateTime.now().millisecondsSinceEpoch);
      }
      if (failed.isNotEmpty) {
        lastError = failed.join(' · ');
        AppLogger.log('[Tủ Sách] Không đọc được tin phát hành của NXB: $lastError', logLevel: LogLevel.warning);
      }
    } finally {
      if (client == null) c.close();
      _busy = false;
      notifyListeners();
    }
  }

  // ───────────── pure helpers (public for tests) ─────────────

  /// Reads RSS 2.0 / Atom, or the product links of an HTML "new books" page
  /// (same host, readable text, not navigation).
  static List<BsFeedItem> parseFeed(String body, Uri base, String sourceId) {
    final head = body.trimLeft();
    if (head.startsWith('<?xml') || head.startsWith('<rss') || head.startsWith('<feed')) {
      try {
        final doc = XmlDocument.parse(body);
        final items = <BsFeedItem>[];
        for (final it in doc.findAllElements('item')) {
          final t = it.getElement('title')?.innerText.trim() ?? '';
          final l = it.getElement('link')?.innerText.trim() ?? '';
          if (t.isNotEmpty) items.add(BsFeedItem(title: t, link: _abs(base, l), sourceId: sourceId));
        }
        for (final it in doc.findAllElements('entry')) {
          final t = it.getElement('title')?.innerText.trim() ?? '';
          final l = it.getElement('link')?.getAttribute('href') ?? '';
          if (t.isNotEmpty) items.add(BsFeedItem(title: t, link: _abs(base, l), sourceId: sourceId));
        }
        if (items.isNotEmpty) return _dedupe(items);
      } catch (_) {}
    }
    final doc = html_parser.parse(body);
    final items = <BsFeedItem>[];
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      if (href.startsWith('#') || href.startsWith('javascript') || href.startsWith('mailto')) continue;
      final link = _abs(base, href);
      final u = Uri.tryParse(link);
      if (u == null || u.host.replaceFirst('www.', '') != base.host.replaceFirst('www.', '')) continue;
      if (u.path.length < 4 || u.path == base.path) continue;
      final img = a.querySelector('img');
      var title = a.attributes['title']?.trim() ?? '';
      if (title.isEmpty) title = a.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (title.isEmpty) title = img?.attributes['alt']?.trim() ?? '';
      if (title.length < 6 || title.length > 180) continue;
      if (_navWord.hasMatch(bsNormalize(title))) continue;
      final src = img?.attributes['data-src'] ?? img?.attributes['src'] ?? '';
      items.add(BsFeedItem(title: title, link: link, sourceId: sourceId, image: src.isEmpty ? '' : _abs(base, src)));
    }
    return _dedupe(items);
  }

  static final _navWord = RegExp(
      r'^(trang chu|gioi thieu|lien he|dang nhap|dang ky|gio hang|xem them|tat ca|tin tuc|chinh sach|huong dan|tai khoan|tim kiem|home|login|cart|contact)\b');

  static String _abs(Uri base, String href) {
    try {
      return base.resolve(href.trim()).toString();
    } catch (_) {
      return href;
    }
  }

  static List<BsFeedItem> _dedupe(List<BsFeedItem> items) {
    final seen = <String>{};
    return [for (final i in items) if (seen.add(i.link.isEmpty ? i.title : i.link)) i];
  }

  /// Kinds of an item, from its title (FN-29 "loại tin").
  static Set<BsFeedKind> kindsOf(String title) {
    final t = bsNormalize(title);
    final k = <BsFeedKind>{};
    if (RegExp(r'\b(limited|gioi han|dac biet|special|ban dac biet)\b').hasMatch(t)) k.add(BsFeedKind.limited);
    if (RegExp(r'\b(artbook|art book|illustration|tranh minh hoa)\b').hasMatch(t)) k.add(BsFeedKind.artbook);
    if (RegExp(r'\bposter\b').hasMatch(t)) k.add(BsFeedKind.poster);
    if (RegExp(r'\b(colorwalk|color walk)\b').hasMatch(t)) k.add(BsFeedKind.colorwalk);
    if (RegExp(r'\b(databook|data book|fanbook|fan book|guidebook)\b').hasMatch(t)) k.add(BsFeedKind.databook);
    if (RegExp(r'\b(boxset|box set|tron bo|tron bo hop)\b').hasMatch(t)) k.add(BsFeedKind.boxset);
    if (k.isEmpty) k.add(BsFeedKind.regular);
    return k;
  }

  /// Series of the shelf whose title / original title / alias appears in the
  /// item's title (whole words, accent-insensitive; ≥ 4 characters so very
  /// short names such as "Tôi" do not match every title).
  static BsSeries? matchOf(String title, Iterable<BsSeries> series) {
    final t = ' ${bsNormalize(title)} ';
    BsSeries? best;
    var bestLen = 0;
    for (final s in series) {
      for (final cand in [s.title, s.original, ...s.aliases]) {
        final c = bsNormalize(cand);
        if (c.replaceAll(' ', '').length < 4) continue;
        if (t.contains(' $c ') && c.length > bestLen) {
          best = s;
          bestLen = c.length;
        }
      }
    }
    return best;
  }

  static List<BsFeedMatch> filterMatches({
    required List<BsFeedItem> items,
    required Iterable<BsSeries> series,
    required Set<String> enabledSources,
    required Set<BsFeedKind> kinds,
    required Set<String> dismissed,
    required Set<String> muted,
    required int max,
  }) {
    final out = <BsFeedMatch>[];
    for (final i in items) {
      if (!enabledSources.contains(i.sourceId) || dismissed.contains(i.key)) continue;
      final s = matchOf(i.title, series);
      if (s == null || muted.contains(s.id)) continue;
      final k = kindsOf(i.title);
      if (kinds.isNotEmpty && k.intersection(kinds).isEmpty) continue;
      out.add(BsFeedMatch(i, s, k));
      if (out.length >= max) break;
    }
    return out;
  }
}
