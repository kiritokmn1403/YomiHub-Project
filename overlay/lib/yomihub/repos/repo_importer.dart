import 'dart:convert';
import 'dart:typed_data';

import 'package:mangayomi/yomihub/kotatsu/kotatsu_bridge.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/services/extension_store_service.dart';
import 'package:mangayomi/services/http/m_client.dart';

/// One repository found in another app's backup or deep link.
class ImportedRepo {
  final String url;
  final String name;
  final String website;
  final ItemType? type; // null = detect from the repository content
  const ImportedRepo(this.url, {this.name = '', this.website = '', this.type});
}

/// YomiHub: brings extension repositories over from Mihon, Aniyomi, Nekoyomi,
/// Komikku, Anikku… (deep links and .tachibk backups).
///
/// Mangayomi only understood its own `mangayomi://add-repo?manga_url=…`
/// links and ignored the repository list stored in Tachiyomi-family backups,
/// so repos from Aniyomi/Nekoyomi never showed up.
class YomiRepoImporter {
  static String _norm(String u) {
    var s = u.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Candidate index URLs for what the user (or the other app) gave us.
  static List<String> candidates(String url) {
    var u = _norm(url);
    // 0.2.1: codeKK mirror page of a GitHub project → the GitHub project
    final ck = RegExp(r'p\.codekk\.com/detail/Android/([\w.\-]+)/([\w.\-]+)', caseSensitive: false).firstMatch(u);
    if (ck != null) u = 'https://github.com/${ck.group(1)}/${ck.group(2)}';
    // LNReader plugin repository given as the GitHub project page.
    if (RegExp(r'github\.com/LNReader/lnreader-plugins', caseSensitive: false).hasMatch(u) && !u.endsWith('.json')) {
      return ['https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json', u];
    }
    // github.com/<owner>/<repo>[/tree/<branch>] → raw index files
    // (keiyoushi / Yūzōnō / Kohi-den style repos publish on the "repo" branch).
    final gh = RegExp(r'^https?://github\.com/([^/]+)/([^/]+)(?:/tree/([^/]+))?', caseSensitive: false).firstMatch(u);
    if (gh != null && !u.endsWith('.json')) {
      final o = gh.group(1), r = gh.group(2)!.replaceAll(RegExp(r'\.git$'), '');
      // IReader-extensions publishes on "repov2"
      final branches = [if (gh.group(3) != null) gh.group(3)!, 'repo', 'repov2', 'main', 'master'];
      return [
        for (final b in branches) ...[
          'https://raw.githubusercontent.com/$o/$r/$b/index.min.json',
          'https://raw.githubusercontent.com/$o/$r/$b/index.pb',
        ],
        u,
      ];
    }
    if (u.endsWith('.json') || u.endsWith('.pb')) return [u];
    return ['$u/index.min.json', '$u/repo.json', '$u/index.pb', '$u/plugins.min.json', u];
  }

  /// Fetches the repository and splits it per item type it really contains.
  /// 0.2.1: Kotatsu Multi Parsers has no index file – its parsers come from
  /// the built-in Kotatsu bridge, so "adding" it refreshes that catalog.
  static bool isKotatsu(String url) =>
      RegExp(r'kotatsu-multi-parsers|kotatsu-parsers|KotatsuApp', caseSensitive: false).hasMatch(url);

  static Future<Map<ItemType, Repo>> resolve(ImportedRepo r) async {
    if (isKotatsu(r.url)) {
      try {
        await KotatsuBridge.syncCatalog();
      } catch (_) {}
      return {};
    }
    final http = MClient.init(reqcopyWith: {'useDartHttpClient': true});
    for (final url in candidates(r.url)) {
      try {
        final res = await ExtensionStoreService.fetchStore(url, http);
        if (res == null || res.sources.isEmpty) continue;
        final types = res.sources.map((s) => s.itemType).toSet();
        final name = r.name.isNotEmpty
            ? r.name
            : (res.name.isNotEmpty ? res.name : Uri.parse(url).host);
        return {
          for (final t in types)
            t: Repo(
              name: name,
              website: r.website.isNotEmpty ? r.website : (res.website ?? url),
              jsonUrl: res.indexUrl.isNotEmpty ? res.indexUrl : url,
            ),
        };
      } catch (_) {}
    }
    // Unreachable right now: keep it anyway under the type we were told,
    // the extension list retries later.
    if (r.type != null) {
      return {
        r.type!: Repo(
          name: r.name.isNotEmpty ? r.name : Uri.tryParse(r.url)?.host,
          website: r.website,
          jsonUrl: '${_norm(r.url)}${_norm(r.url).endsWith('.json') || _norm(r.url).endsWith('.pb') ? '' : '/index.min.json'}',
        ),
      };
    }
    return {};
  }

  /// Adds the repositories to YomiHub. [ref] is a WidgetRef or Ref.
  /// Returns how many repository entries were added.
  static Future<int> addAll(dynamic ref, List<ImportedRepo> repos) async {
    var added = 0;
    final pending = <ItemType, List<Repo>>{};
    for (final r in repos) {
      final resolved = await resolve(r);
      resolved.forEach((t, repo) => pending.putIfAbsent(t, () => []).add(repo));
    }
    for (final entry in pending.entries) {
      final List<Repo> current = List<Repo>.from(
        ref.read(extensionsRepoStateProvider(entry.key)) as List<Repo>,
      );
      final known = current
          .map((e) => _norm(e.jsonUrl ?? '').toLowerCase())
          .toSet();
      for (final repo in entry.value) {
        final key = _norm(repo.jsonUrl ?? '').toLowerCase();
        if (key.isEmpty || known.contains(key)) continue;
        known.add(key);
        current.add(repo);
        added++;
      }
      await ref.read(extensionsRepoStateProvider(entry.key).notifier).set(current);
    }
    return added;
  }

  /// Repositories from a deep link such as `aniyomi://add-repo?url=…`,
  /// `tachiyomi://add-repo?url=…`, `aniyomi://extension-store?url=…`.
  static List<ImportedRepo> fromDeepLink(Uri uri) {
    final urls = <String>[
      ...uri.queryParametersAll['url'] ?? const [],
      ...uri.queryParametersAll['repo'] ?? const [],
      ...uri.queryParametersAll['index'] ?? const [],
    ];
    final scheme = uri.scheme.toLowerCase();
    ItemType? hint;
    if (const ['aniyomi', 'anikku', 'animetail', 'kuukiyomi', 'nekoyomi'].contains(scheme)) {
      hint = ItemType.anime;
    } else if (const ['tachiyomi', 'mihon', 'komikku', 'tachiyomisy', 'yokai'].contains(scheme)) {
      hint = ItemType.manga;
    } else if (scheme == 'lnreader') {
      hint = ItemType.novel;
    }
    return [
      for (final u in urls)
        if (u.trim().isNotEmpty) ImportedRepo(u, type: hint, name: uri.queryParameters['name'] ?? ''),
    ];
  }

  // ---------------------------------------------------------------------
  // .tachibk (protobuf) reading. Field numbers, from the apps' Backup.kt:
  //  Mihon:    106 = extension stores (manga)
  //  Aniyomi:  106 = manga repos, 505 = anime stores (legacy: 108 manga, 107 anime)
  //  Nekoyomi: 106 = manga repos, 505 = anime repos (legacy: 108 manga, 107 anime)
  // Every repo/store message has: 1 = url, 2 = name, 4 = website.
  // ---------------------------------------------------------------------

  /// True when the (gunzipped) backup uses Aniyomi's anime fields (500+),
  /// which covers Aniyomi, Nekoyomi, Anikku and friends regardless of the
  /// file name.
  static bool isAniyomiFlavour(Uint8List data) {
    for (final f in _fields(data)) {
      if (f.number >= 500 && f.number <= 510) return true;
      if (f.number == 3 || f.number == 4 || f.number == 103) return true; // legacy anime fields
    }
    return false;
  }

  static List<ImportedRepo> fromTachiBk(Uint8List data) {
    final fields = _fields(data).toList();
    final aniyomi = isAniyomiFlavour(data);
    final legacy = aniyomi && !fields.any((f) => f.number == 500 || f.number == 501);
    final out = <ImportedRepo>[];
    for (final f in fields) {
      if (f.wireType != 2) continue;
      ItemType? type;
      if (!aniyomi) {
        if (f.number == 106) type = ItemType.manga;
      } else if (legacy) {
        if (f.number == 108) type = ItemType.manga;
        if (f.number == 107) type = ItemType.anime;
      } else {
        if (f.number == 106) type = ItemType.manga;
        if (f.number == 505) type = ItemType.anime;
      }
      if (type == null) continue;
      String url = '', name = '', website = '';
      for (final sub in _fields(f.bytes!)) {
        if (sub.wireType != 2) continue;
        if (sub.number == 1) url = _utf8(sub.bytes!);
        if (sub.number == 2) name = _utf8(sub.bytes!);
        if (sub.number == 4) website = _utf8(sub.bytes!);
      }
      if (url.startsWith('http')) {
        out.add(ImportedRepo(url, name: name, website: website, type: type));
      }
    }
    return out;
  }

  static String _utf8(Uint8List b) {
    try {
      return const Utf8Codec().decode(b);
    } catch (_) {
      return String.fromCharCodes(b);
    }
  }

  static Iterable<_PbField> _fields(Uint8List d) sync* {
    var i = 0;
    int varint() {
      var result = 0, shift = 0;
      while (i < d.length) {
        final b = d[i++];
        result |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) break;
        shift += 7;
        if (shift > 63) break;
      }
      return result;
    }

    while (i < d.length) {
      final key = varint();
      final number = key >> 3, wire = key & 7;
      if (number == 0) return;
      switch (wire) {
        case 0:
          varint();
          yield _PbField(number, wire, null);
        case 1:
          i += 8;
          yield _PbField(number, wire, null);
        case 2:
          final len = varint();
          if (len < 0 || i + len > d.length) return;
          yield _PbField(number, wire, Uint8List.sublistView(d, i, i + len));
          i += len;
        case 5:
          i += 4;
          yield _PbField(number, wire, null);
        default:
          return; // groups / garbage: stop scanning
      }
    }
  }
}

class _PbField {
  final int number;
  final int wireType;
  final Uint8List? bytes;
  _PbField(this.number, this.wireType, this.bytes);
}
