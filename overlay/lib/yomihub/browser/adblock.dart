import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// YomiHub ad blocker for the built-in browser.
///
/// Three layers, in the spirit of uBlock Origin / Adblock Plus:
///  1. network filter: requests to known ad / tracker / pop-under hosts are
///     cancelled (one combined regex, cheap enough to run on every request);
///  2. cosmetic filter: common ad containers are hidden with CSS;
///  3. a small script (like the Tampermonkey ad-block gist) that keeps
///     removing ad nodes added later, plus the user's own rules
///     (`example.com##.banner` to hide, `||ads.example.com^` to block).
class YomiAdBlock {
  static const _box = 'yomihub_browser';

  /// Ad, tracker and pop-under networks (incl. ones common on Vietnamese
  /// streaming / reading sites).
  static const List<String> hosts = [
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'google-analytics.com', 'googletagmanager.com', 'googletagservices.com',
    'adservice.google.com', 'pagead2.googlesyndication.com', 'imasdk.googleapis.com',
    'adnxs.com', 'adsrvr.org', 'amazon-adsystem.com', 'criteo.com', 'criteo.net',
    'taboola.com', 'outbrain.com', 'pubmatic.com', 'rubiconproject.com', 'openx.net',
    'casalemedia.com', 'smartadserver.com', 'scorecardresearch.com', 'quantserve.com',
    'moatads.com', 'adform.net', 'yieldmo.com', 'teads.tv', 'media.net', 'zedo.com',
    'popads.net', 'popcash.net', 'propellerads.com', 'propellerclick.com',
    'adsterra.com', 'adsterratools.com', 'highperformanceformat.com', 'profitablecpmrate.com',
    'exoclick.com', 'exosrv.com', 'juicyads.com', 'trafficjunky.net', 'trafficjunky.com',
    'trafficstars.com', 'tsyndicate.com', 'hilltopads.net', 'adcash.com', 'clickadu.com',
    'onclickads.net', 'onclkds.com', 'popunder.net', 'popmyads.com', 'mgid.com',
    'revcontent.com', 'yllix.com', 'a-ads.com', 'coinzilla.com', 'bidvertiser.com',
    'admicro.vn', 'adtima.vn', 'eclick.vn', 'adnet.vn', 'ambient.vn', 'vcmedia.vn/ads',
    'adx.vn', 'yomedia.vn', 'adsota.com', 'adpia.vn', 'admatic.com.tr', 'blueseed.tv',
    'ads.yahoo.com', 'advertising.com', 'adtech.de', 'serving-sys.com', 'sharethrough.com',
    'spotxchange.com', 'springserve.com', 'undertone.com', 'zergnet.com', 'adskeeper.com',
    'realsrv.com', 'magsrv.com', 'adspyglass.com', 'dtscout.com', 'vidoomy.com',
    'pushnami.com', 'onesignal.com/sdks', 'push.express', 'notix.io', 'richpush.co',
    'facebook.com/tr', 'connect.facebook.net/en_US/fbevents', 'hotjar.com', 'clarity.ms',
  ];

  static final RegExp hostRegex = RegExp(
    r'^https?://([a-z0-9-]+\.)*(' +
        hosts.map(RegExp.escape).join('|') +
        r')([/:?#]|$)',
    caseSensitive: false,
  );

  static const String cosmeticCss =
      '.adsbygoogle,ins.adsbygoogle,[id^="google_ads_"],[id^="div-gpt-ad"],'
      'iframe[src*="doubleclick"],iframe[src*="googlesyndication"],iframe[id^="google_ads"],'
      '.ad-banner,.ads-banner,.banner-ads,.adsbox,.ad-container,.ads-container,'
      '.advertisement,.advertising,[class*="ad-slot"],[id*="ad-slot"],'
      '[class^="popup-ad"],[id^="popup-ad"],.catfish,.catfish-ads,#catfish,'
      '.balloon-ads,.float-ads,.floating-ads,.sticky-ads,#sticky-ads,'
      'a[href*="//ad."][target="_blank"] > img,div[data-ad],div[data-ad-slot]';

  static Future<Box> _open() => Hive.isBoxOpen(_box)
      ? Future.value(Hive.box(_box))
      : YomiHive.open(_box);

  static bool enabled = true;
  static Set<String> allowed = {};
  static List<String> userRules = [];

  // ───────── Tampermonkey AdBlock (gist DerFichtl/af462414…) ─────────
  /// The "mf-adblock" Tampermonkey script: per-site config of elements to
  /// hide (`remove`), to click away (`click`, cookie banners), a fake mouse
  /// move (`interaction`), delay (`timeout`), repeat (`interval`) and a
  /// page `background` for full-page ad skins. It only hides elements, so
  /// anti-adblock detectors don't trigger.
  static bool tampermonkey = true;
  static Map<String, dynamic> tmSites = Map.of(tmDefaultSites);

  /// Starter configs for sites YomiHub has extensions for.
  static const Map<String, dynamic> tmDefaultSites = {
    '*': {
      'remove': [
        '#preload-ads', '.preload-ads', '#ads-preload', '.ads-preload',
        '.banner-catfish', '#banner-catfish', '.catfish-bottom', '#catfish-bottom',
        '.float-left-ads', '.float-right-ads', '.ads-left', '.ads-right',
        'div[id^="adm-"]', 'div[class^="adm-"]', 'a[href*="bet"][target="_blank"] img',
      ],
      'click': ['#close-catfish', '.close-catfish', '.btn-close-ads', '#btn-close-ads'],
      'interval': 4000,
    },
    'animevietsub.nl': {
      'remove': ['#ads_location', '.ads_location', '#Ads', '.Ads', '#ads-player', '.ad-floater'],
      'click': ['#close-ads', '.close-ads', '#skip-ads', '.skip-ads'],
      'interval': 3000,
    },
    'rophimhd.com': {'remove': ['.ads', '#ads', '.banner-ads'], 'interval': 4000},
    'hotphim.org': {'remove': ['.ads', '#ads', '.ads-banner'], 'interval': 4000},
    'anime47.best': {'remove': ['.ads', '#ads'], 'interval': 4000},
    'animevn.net': {'remove': ['.ads', '#ads', '.banner'], 'interval': 4000},
    'ln.hako.vn': {'remove': ['.ads', '#ads'], 'interval': 5000},
    'docln.sbs': {'remove': ['.ads', '#ads'], 'interval': 5000},
  };

  /// User scripts (Tampermonkey style): {name, match: [patterns], code, enabled}.
  static List<Map<String, dynamic>> userScripts = [];

  /// Filter-list subscriptions (uBlock Origin / Adblock Plus syntax). Only
  /// whole-domain network rules (`||host^`) and hosts-file lines are used,
  /// so tens of thousands of domains stay a cheap Set lookup.
  static const lists = <String, String>{
    'EasyList': 'https://easylist.to/easylist/easylist.txt',
    'EasyPrivacy': 'https://easylist.to/easylist/easyprivacy.txt',
    'ABPVN (Việt Nam)': 'https://abpvn.com/filter/abpvn-IPl6HE.txt',
    'uBlock – Badware risks': 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt',
    'uBlock – Quick fixes': 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/quick-fixes.txt',
    // 0.1.7: uBlock's own list + AdGuard (AdguardTeam/FiltersRegistry)
    'uBlock filters': 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
    'AdGuard Base': 'https://filters.adtidy.org/extension/ublock/filters/2.txt',
    'AdGuard Mobile Ads': 'https://filters.adtidy.org/extension/ublock/filters/11.txt',
    'AdGuard Tracking Protection': 'https://filters.adtidy.org/extension/ublock/filters/3.txt',
    "Peter Lowe's list": 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext',
    // 0.1.8: AdGuard's DNS filter (host rules) and Annoyances (pop-ups,
    // cookie walls, "please disable AdBlock" banners), as in AdGuard apps
    'AdGuard DNS filter': 'https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt',
    'AdGuard Annoyances': 'https://filters.adtidy.org/extension/ublock/filters/14.txt',
  };
  static Set<String> listHosts = {};

  /// 0.1.8: element hiding from the lists (AdGuard / EasyList / ABPVN
  /// `##selector` rules): generic ones and per-site ones.
  static List<String> listGeneric = [];
  static Map<String, List<String>> listSite = {};
  static int listUpdated = 0;

  static final _netRule = RegExp(r'^\|\|([a-z0-9.-]+\.[a-z]{2,})\^(?:\$(.*))?$');
  static final _hostsLine = RegExp(r'^(?:0\.0\.0\.0|127\.0\.0\.1)\s+([a-z0-9.-]+\.[a-z]{2,})\s*$');

  /// Downloads the subscribed lists. Returns the number of blocked domains.
  /// 0.1.7: lists download in parallel and are parsed off the UI isolate
  /// (≈10 lists, a few hundred thousand lines – parsing on the UI thread
  /// froze the browser for seconds).
  static Future<int> updateLists() async {
    final bodies = await Future.wait([
      for (final url in lists.values)
        http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 40))
            .then((r) => r.statusCode == 200 ? utf8.decode(r.bodyBytes, allowMalformed: true) : '')
            .catchError((_) => ''),
    ]);
    final parsed = await Isolate.run(() => _parseAll(bodies));
    final out = parsed.$1;
    if (out.isEmpty) return listHosts.length;
    listHosts = out;
    listGeneric = parsed.$2;
    listSite = parsed.$3;
    listUpdated = DateTime.now().millisecondsSinceEpoch;
    try {
      final b = await _open();
      await b.put('adblock_list_hosts', out.toList());
      await b.put('adblock_list_generic', listGeneric);
      await b.put('adblock_list_site', jsonEncode(listSite));
      await b.put('adblock_list_updated', listUpdated);
    } catch (_) {}
    return out.length;
  }

  static final _simpleSel = RegExp(r'^[#.]?[a-z0-9_\-]+(?:\[[a-z\-]+(?:[*^$]?="[^"]*")?\])?(?:[#.][a-z0-9_\-]+)*$', caseSensitive: false);

  /// Parses filter lists: blocked hosts, generic and per-site element hiding.
  static (Set<String>, List<String>, Map<String, List<String>>) _parseAll(List<String> bodies) {
    final out = <String>{};
    final generic = <String>{};
    final site = <String, Set<String>>{};
    for (final body in bodies) {
      for (var raw in const LineSplitter().convert(body)) {
        raw = raw.trim();
        if (raw.isEmpty || raw.startsWith('!') || raw.startsWith('[')) continue;
        final hide = raw.indexOf('##');
        if (hide >= 0 && !raw.contains('#@#') && !raw.contains('#?#') && !raw.contains('#\$#') && !raw.contains('#%#')) {
          final sel = raw.substring(hide + 2).trim();
          // only plain CSS selectors (no :has-text, :-abp-, :style… extensions)
          if (sel.isEmpty || sel.length > 160 || sel.contains(':-abp') || sel.contains(':has-text') ||
              sel.contains(':matches') || sel.contains(':xpath') || sel.contains(':style') ||
              sel.contains(':upward') || sel.contains(':remove') || sel.contains('+js(')) {
            continue;
          }
          final doms = raw.substring(0, hide).trim();
          if (doms.isEmpty) {
            if (_simpleSel.hasMatch(sel)) generic.add(sel);
          } else {
            for (final d in doms.split(',')) {
              final dd = d.trim().toLowerCase();
              if (dd.isEmpty || dd.startsWith('~') || dd.contains('*')) continue;
              site.putIfAbsent(dd, () => <String>{}).add(sel);
            }
          }
          continue;
        }
        final line = raw.toLowerCase();
        if (line.startsWith('#') || line.startsWith('@@')) continue;
        final m = _netRule.firstMatch(line);
        if (m != null) {
          final opts = m.group(2) ?? '';
          // skip rules restricted to some sites or to non-blocking types
          if (opts.contains('domain=') || opts.contains('redirect') || opts.contains('removeparam') ||
              opts.contains('csp') || opts.contains('~third-party') || opts.contains('important,')) {
            continue;
          }
          out.add(m.group(1)!);
          continue;
        }
        final h = _hostsLine.firstMatch(line);
        if (h != null) out.add(h.group(1)!);
      }
    }
    // keep the generic stylesheet small: it goes into every page
    final g = generic.toList()..sort((a, b) => a.length.compareTo(b.length));
    return (
      out,
      g.take(4000).toList(),
      {for (final e in site.entries) e.key: e.value.take(200).toList()},
    );
  }

  /// Refreshes the lists in the background once a week.
  static void autoUpdate() {
    final age = DateTime.now().millisecondsSinceEpoch - listUpdated;
    if (enabled && (listHosts.isEmpty || age > const Duration(days: 7).inMilliseconds)) {
      updateLists();
    }
  }

  static bool _inLists(String host) {
    if (listHosts.isEmpty || host.isEmpty) return false;
    var h = host;
    while (true) {
      if (listHosts.contains(h)) return true;
      final i = h.indexOf('.');
      if (i < 0 || h.indexOf('.', i + 1) < 0) return false;
      h = h.substring(i + 1);
    }
  }

  static Future<void> load() async {
    try {
      final b = await _open();
      listHosts = Set<String>.from((b.get('adblock_list_hosts', defaultValue: <String>[]) as List).cast<String>());
      listUpdated = (b.get('adblock_list_updated', defaultValue: 0) as int);
      listGeneric = (b.get('adblock_list_generic', defaultValue: <String>[]) as List).cast<String>();
      final ls = b.get('adblock_list_site') as String?;
      if (ls != null && ls.isNotEmpty) {
        listSite = {
          for (final e in (jsonDecode(ls) as Map).entries)
            '${e.key}': (e.value as List).cast<String>(),
        };
      }
      // lists saved by 0.1.7 have no element-hiding part yet: refresh once
      if (listHosts.isNotEmpty && listGeneric.isEmpty) listUpdated = 0;
      enabled = b.get('adblock', defaultValue: true) as bool;
      allowed = Set<String>.from((b.get('adblock_allow', defaultValue: <String>[]) as List).cast<String>());
      userRules = (b.get('adblock_rules', defaultValue: <String>[]) as List).cast<String>();
      tampermonkey = b.get('adblock_tm', defaultValue: true) as bool;
      final tm = b.get('adblock_tm_sites') as String?;
      if (tm != null && tm.isNotEmpty) {
        tmSites = Map<String, dynamic>.from(jsonDecode(tm) as Map);
      }
      final us = b.get('userscripts') as String?;
      if (us != null && us.isNotEmpty) {
        userScripts = (jsonDecode(us) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final b = await _open();
      await b.put('adblock', enabled);
      await b.put('adblock_allow', allowed.toList());
      await b.put('adblock_rules', userRules);
      await b.put('adblock_tm', tampermonkey);
      await b.put('adblock_tm_sites', jsonEncode(tmSites));
      await b.put('userscripts', jsonEncode(userScripts));
    } catch (_) {}
  }

  /// Config of the Tampermonkey AdBlock script for [host] (site entry merged
  /// over the `*` entry), or null when nothing applies.
  static Map<String, dynamic>? tmConfigFor(String host) {
    if (!tampermonkey) return null;
    Map<String, dynamic>? site;
    for (final e in tmSites.entries) {
      if (e.key == '*') continue;
      final k = e.key.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
      if (host == k || host.endsWith('.$k')) site = Map<String, dynamic>.from(e.value as Map);
    }
    final all = tmSites['*'] is Map ? Map<String, dynamic>.from(tmSites['*'] as Map) : null;
    if (site == null && all == null) return null;
    final out = <String, dynamic>{...?all};
    site?.forEach((k, v) {
      if (v is List && out[k] is List) {
        out[k] = [...(out[k] as List), ...v];
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  /// The Tampermonkey AdBlock userscript, configured for [host].
  static String tampermonkeyScript(String host) {
    final cfg = tmConfigFor(host);
    if (cfg == null) return '';
    return '''
(function() {
  'use strict';
  if (window.__yhTm) return; window.__yhTm = true;
  var site = ${jsonEncode(cfg)};
  function cleanup() {
    try {
      if (site.interaction && document.body) document.body.dispatchEvent(new MouseEvent('mousemove'));
      (site.remove || []).forEach(function(selector) {
        try {
          document.querySelectorAll(selector).forEach(function(elem) {
            elem.style.visibility = 'hidden';
            elem.style.width = '1px';
            elem.style.height = '1px';
            elem.style.overflow = 'hidden';
            elem.style.opacity = 0;
          });
        } catch (e) {}
      });
      if (site.background && document.body) {
        document.body.style.background = site.background;
        document.body.style.overflow = 'scroll';
        document.body.style.position = 'static';
      }
      (site.click || []).forEach(function(selector) {
        try { var el = document.querySelector(selector); if (el !== null) el.click(); } catch (e) {}
      });
    } catch (e) {}
  }
  window.setTimeout(cleanup, site.timeout || 0);
  if (site.interval) window.setInterval(cleanup, site.interval);
})();
''';
  }

  /// `@match`-style test: `*://*.example.com/*`, `https://site/*`, `*`.
  static bool _matches(String pattern, String url) {
    pattern = pattern.trim();
    if (pattern.isEmpty || pattern == '*' || pattern == '<all_urls>') return true;
    final re = RegExp(
      '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$',
      caseSensitive: false,
    );
    return re.hasMatch(url);
  }

  /// Enabled user scripts whose @match patterns cover [url].
  static String userScriptsFor(String url) {
    final b = StringBuffer();
    for (final sc in userScripts) {
      if (sc['enabled'] == false) continue;
      final match = (sc['match'] as List?)?.cast<String>() ?? const ['*'];
      if (match.any((m) => _matches(m, url))) {
        b.writeln('try {\n${sc['code']}\n} catch (e) { console.log("userscript ${sc['name']}: " + e); }');
      }
    }
    return b.toString();
  }

  /// Reads a Tampermonkey metadata block (`// @name`, `// @match`).
  static Map<String, dynamic> parseUserScript(String code) {
    String name = 'Userscript';
    final match = <String>[];
    for (final m in RegExp(r'^//\s*@(\w+)\s+(.+)$', multiLine: true).allMatches(code)) {
      final k = m.group(1)!, v = m.group(2)!.trim();
      if (k == 'name') name = v;
      if (k == 'match' || k == 'include') match.add(v);
    }
    return {'name': name, 'match': match.isEmpty ? ['*'] : match, 'code': code, 'enabled': true};
  }

  static String hostOf(String url) {
    try {
      return Uri.parse(url).host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return '';
    }
  }

  static bool activeFor(String pageUrl) =>
      enabled && !allowed.contains(hostOf(pageUrl));

  static Iterable<String> get _userHosts => userRules
      .map((r) => r.trim())
      .where((r) => r.startsWith('||'))
      .map((r) => r.substring(2).replaceAll(RegExp(r'[\^/*].*$'), ''))
      .where((h) => h.isNotEmpty);

  /// Should a request / navigation to [url] be dropped?
  static bool isAd(String url) {
    if (hostRegex.hasMatch(url)) return true;
    final h = hostOf(url);
    if (_inLists(h)) return true;
    for (final u in _userHosts) {
      if (h == u || h.endsWith('.$u')) return true;
    }
    return false;
  }

  /// 0.1.8: blocks sub-resources (scripts, images, XHR, iframes…) of the
  /// subscribed lists (AdGuard, EasyList, ABPVN…), not only navigations.
  static WebResourceResponse? intercept(String pageUrl, String url) {
    if (!activeFor(pageUrl) || !isAd(url)) return null;
    blockedCount++;
    return WebResourceResponse(
      data: Uint8List(0),
      statusCode: 204,
      reasonPhrase: 'No Content',
      contentType: 'text/plain',
    );
  }

  static int blockedCount = 0;

  /// Native content blockers for the WebView settings.
  static List<ContentBlocker> contentBlockers() {
    final extra = _userHosts.map(RegExp.escape).toList();
    return [
      ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: hostRegex.pattern),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      ),
      if (extra.isNotEmpty)
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: r'^https?://([a-z0-9-]+\.)*(' + extra.join('|') + r')([/:?#]|$)',
          ),
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        ),
      ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: '.*'),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: cosmeticCss,
        ),
      ),
    ];
  }

  /// Cosmetic selectors from the user's `domain##selector` rules for [host].
  static List<String> selectorsFor(String host) {
    final out = <String>[];
    // 0.1.8: per-site rules of the subscribed lists
    var h = host;
    while (h.contains('.')) {
      final r = listSite[h];
      if (r != null) out.addAll(r);
      h = h.substring(h.indexOf('.') + 1);
    }
    for (final r in userRules) {
      final i = r.indexOf('##');
      if (i < 0) continue;
      final domains = r.substring(0, i).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      final sel = r.substring(i + 2).trim();
      if (sel.isEmpty) continue;
      if (domains.isEmpty || domains.any((d) => host == d || host.endsWith('.$d'))) out.add(sel);
    }
    return out;
  }

  /// Script run in each page: removes ads that show up late (interval), like
  /// the Tampermonkey ad-block script, and kills pop-under helpers.
  static String pageScript(String host) {
    final siteSel = selectorsFor(host);
    // one rule per selector: an invalid one must not cancel the others
    final css = jsonEncode([
      for (final x in [...siteSel, ...listGeneric]) '$x{display:none!important}',
    ].join('\n'));
    final custom = siteSel.where((x) => !x.contains(':')).take(300).join(', ');
    final sel = jsonEncode(cosmeticCss + (custom.isNotEmpty ? ', $custom' : ''));
    final popHosts = jsonEncode(hosts.take(60).toList());
    return '''
(function(){
  if (window.__yhAdblock) return; window.__yhAdblock = true;
  var SEL = $sel;
  var POP = $popHosts;
  try {
    if (window === window.top) {
      var st = document.createElement('style');
      st.textContent = $css;
      (document.head || document.documentElement).appendChild(st);
    }
  } catch (e) {}
  function clean(){
    try {
      document.querySelectorAll(SEL).forEach(function(e){ e.remove(); });
      document.querySelectorAll('iframe').forEach(function(f){
        var s = (f.getAttribute('src')||'');
        if (/doubleclick|googlesyndication|adsterra|exoclick|popads|propeller|juicyads|trafficjunky/i.test(s)) f.remove();
      });
      // full-screen click-jacking overlays used by many streaming sites
      document.querySelectorAll('body > div, body > a').forEach(function(e){
        var st = getComputedStyle(e);
        if ((st.position==='fixed'||st.position==='absolute') && parseInt(st.zIndex||'0') > 99990 &&
            e.offsetWidth >= innerWidth*0.9 && e.offsetHeight >= innerHeight*0.9 &&
            !e.querySelector('video,iframe[src*="player"],input,form') &&
            (e.tagName==='A' || e.querySelector('a[target="_blank"]')) && (e.innerText||'').trim().length < 20) e.remove();
      });
    } catch(err) {}
  }
  var open = window.open;
  window.open = function(u){ try { var s = String(u||''); for (var i=0;i<POP.length;i++){ if (s.indexOf(POP[i])>=0) return null; } } catch(e){} return open.apply(window, arguments); };
  clean();
  setTimeout(clean, 1200);
  setInterval(clean, 3500);
})();
${tampermonkeyScript(host)}
''';
  }
}
