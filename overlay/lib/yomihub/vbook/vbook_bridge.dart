import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/services/extension_store_service.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/net/gh_mirror.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.4.9 (sheet "YomiHub Update": "Quét toàn bộ mã nguồn của các
/// project vBook, vBook 2, LeechText … sao cho nó hoạt động đối với các
/// extension repo của vBook").
///
/// A vBook repository (`plugin.json` = `{metadata, data: [{path: …/plugin.zip,
/// type, locale, version, …}]}`, e.g. Darkrai9x/vbook-extensions,
/// duongden/vbook and every repo of vbookext.me) is read like any other
/// extension repository. Installing an entry downloads its plugin.zip and turns
/// it into a JavaScript source: `_common.js` + `VB_PLUGIN` (plugin.json) +
/// `VB_SCRIPTS` (src/*.js) + `assets/yomihub_extensions/vbook.js`, the
/// runtime that rewrites the synchronous Rhino scripts for QuickJS and maps
/// home/search/detail/toc/chap/track onto popular/search/detail/pages/video.
///
/// novel / chinese_novel → Tiểu thuyết, comic → Truyện tranh, video → Phim.
/// tts / translate / ai / audio engines are not content sources and are
/// skipped. Encrypted extensions (`metadata.encrypt` with ciphertext scripts)
/// only run inside the vBook app: they are reported, never installed broken.
class VBookBridge {
  VBookBridge._();
  static const marker = 'vbook:';

  /// Revision of the bundled runtime (vbook.js). The runtime is baked into
  /// each installed source, so it is the last part of the version: a runtime
  /// fix then shows up as an extension update and reinstalls the source.
  /// 1: first 0.4.9 build · 2: Document.text / description fix (03/11/2026).
  /// 3: 0.5.1 – fetch retries once on a network error and the error names
  ///    the real cause (URL + exception / HTTP status).
  /// 4: 0.5.2 – a list/search script returning nothing is an empty page,
  ///    not an error.
  static const runtimeRev = 4;

  static bool isVBookSource(Source s) => (s.additionalParams ?? '').startsWith(marker);

  // ---- 0.5.0: encrypted plugins (logs 03/11 10:36–11:08: the same 16
  // encrypted plugins were "reinstalled" again and again, each try an ERROR
  // with a stack trace). Once a plugin.zip turns out to be encrypted, its
  // URL + version is remembered: the row shows "vBook only", the install
  // button is locked and the log gets one warning instead of an error.
  static const _encKey = 'vbookEncrypted';
  static Set<String> _enc() =>
      {for (final e in YomiPrefs.get<List>(_encKey, const [])) '$e'};
  static String _encId(String? url, String? ver) => '${url ?? ''}@${ver ?? ''}';

  /// True when this repo entry was already found to be encrypted.
  static bool isKnownEncrypted(Source s) {
    if (!isVBookSource(s) || !YomiPrefs.isOpen) return false;
    final e = _enc();
    return e.contains(_encId(s.sourceCodeUrl, s.versionLast)) ||
        e.contains(_encId(s.sourceCodeUrl, s.version));
  }

  static Future<void> markEncrypted(Source s) async {
    if (!YomiPrefs.isOpen) return;
    final e = _enc()..add(_encId(s.sourceCodeUrl, s.version));
    // keep the list small: newest 500 entries
    final list = e.toList();
    await YomiPrefs.set(_encKey, list.length > 500 ? list.sublist(list.length - 500) : list);
  }

  static bool isIndex(Map<String, dynamic> j) =>
      j['data'] is List &&
      (j['data'] as List).any((e) => e is Map && '${e['path'] ?? ''}'.toLowerCase().split('?').first.endsWith('.zip'));

  static ItemType? itemTypeOf(String? type) {
    final t = (type ?? 'novel').toLowerCase().trim();
    if (t.isEmpty || t == 'novel' || t.contains('novel')) return ItemType.novel;
    if (t.contains('comic') || t.contains('manga')) return ItemType.manga;
    if (t.contains('video') || t.contains('anime') || t.contains('movie')) return ItemType.anime;
    return null; // tts, translate, ai, audio
  }

  static String langOf(String? locale) {
    final l = (locale ?? '').toLowerCase().replaceAll('-', '_');
    if (l.isEmpty || l == 'global' || l == 'all') return 'all';
    final p = l.split('_').first;
    return p.isEmpty ? 'all' : p;
  }

  static ExtensionStoreFetchResult? parseIndex(String indexUrl, Map<String, dynamic> j) {
    final meta = j['metadata'] is Map ? j['metadata'] as Map : const {};
    final sources = <Source>[];
    for (final raw in (j['data'] as List)) {
      if (raw is! Map) continue;
      final e = Map<String, dynamic>.from(raw);
      final path = '${e['path'] ?? ''}'.trim();
      if (!path.toLowerCase().split('?').first.endsWith('.zip')) continue;
      final type = itemTypeOf('${e['type'] ?? ''}');
      if (type == null) continue;
      final zipUrl = Uri.parse(indexUrl).resolve(path).toString();
      final ver = int.tryParse('${e['version'] ?? 0}') ?? 0;
      final name = '${e['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final nsfw = e['nsfw'] == true || '${e['tag'] ?? ''}'.toLowerCase() == 'nsfw';
      final src = Source()
        ..id = stableSourceId('vbook-$zipUrl')
        ..name = name
        ..lang = langOf('${e['locale'] ?? ''}')
        ..baseUrl = '${e['source'] ?? ''}'
        ..apiUrl = ''
        ..appMinVerReq = ''
        ..dateFormat = ''
        ..dateFormatLocale = ''
        ..hasCloudflare = false
        ..headers = ''
        ..isActive = true
        ..isAdded = false
        ..isFullData = false
        ..isNsfw = nsfw
        ..isPinned = false
        ..lastUsed = false
        ..sourceCode = ''
        ..sourceCodeUrl = zipUrl
        ..typeSource = 'single'
        ..version = '$ver.0.$runtimeRev'
        ..versionLast = '$ver.0.$runtimeRev'
        ..isObsolete = false
        ..isLocal = false
        ..iconUrl = e['icon'] == null ? '' : Uri.parse(indexUrl).resolve('${e['icon']}').toString()
        ..additionalParams = '$marker$zipUrl'
        ..notes = 'vBook • ${e['author'] ?? meta['author'] ?? ''} • ${e['description'] ?? ''}'
        ..sourceCodeLanguage = SourceCodeLanguage.javascript
        ..itemType = type;
      sources.add(src);
    }
    if (sources.isEmpty) return null;
    return ExtensionStoreFetchResult(
      name: '${meta['author'] ?? meta['name'] ?? 'vBook'} (vBook)',
      website: null,
      indexUrl: indexUrl,
      sources: sources,
    );
  }

  /// Downloads plugin.zip of [source] and returns the generated script.
  static Future<String> buildSourceCode(Source source, http.Client client) async {
    final url = source.sourceCodeUrl ?? '';
    final r = await GhMirror.get(client, Uri.parse(url), timeout: const Duration(seconds: 60));
    final b = r.bodyBytes;
    if (r.statusCode == 404) {
      // 0.5.1: 7 of 554 entries in the 18 known vBook repos point to a
      // plugin.zip that is not in the repo (scan 03/11/2026) – say so.
      throw Exception(tr('Kho vBook không còn tệp plugin.zip của tiện ích này (HTTP 404) – tác giả kho đã xóa hoặc đổi đường dẫn.'));
    }
    if (r.statusCode != 200 || b.length < 4 || b[0] != 0x50 || b[1] != 0x4b) {
      throw Exception(tr('Tải gói tiện ích vBook thất bại (HTTP {p0}, {p1} byte)', {'p0': r.statusCode, 'p1': b.length}));
    }
    return fromZip(b, common: await rootBundle.loadString('assets/yomihub_extensions/_common.js'),
        runtime: await rootBundle.loadString('assets/yomihub_extensions/vbook.js'));
  }

  /// Pure part of [buildSourceCode] (unit-tested).
  static String fromZip(List<int> zip, {required String common, required String runtime}) {
    final archive = ZipDecoder().decodeBytes(zip);
    Map<String, dynamic>? plugin;
    final scripts = <String, String>{};
    String prefix = '';
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final n = f.name.replaceAll('\\', '/');
      if (n.endsWith('plugin.json') && (plugin == null || n.length < prefix.length + 12)) {
        try {
          plugin = Map<String, dynamic>.from(jsonDecode(utf8.decode(f.content as List<int>, allowMalformed: true)) as Map);
          prefix = n.substring(0, n.length - 'plugin.json'.length);
        } catch (_) {}
      }
    }
    if (plugin == null) throw Exception(tr('Gói vBook không có plugin.json'));
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final n = f.name.replaceAll('\\', '/');
      if (!n.startsWith('${prefix}src/')) continue;
      final rel = n.substring('${prefix}src/'.length);
      if (rel.contains('/') || !rel.endsWith('.js')) continue; // top level of src/ only
      final bytes = f.content as List<int>;
      if (bytes.length > 10 * 1024 * 1024) continue;
      scripts[rel] = utf8.decode(bytes, allowMalformed: true);
    }
    if (scripts.isEmpty) throw Exception(tr('Gói vBook không có script trong src/'));
    final meta = plugin['metadata'] is Map ? plugin['metadata'] as Map : const {};
    if (meta['encrypt'] == true && scripts.values.every((s) => !looksLikeScript(s))) {
      throw VBookEncryptedException('${meta['name'] ?? ''}');
    }
    return '$common\n'
        'const VB_PLUGIN = ${jsonEncode(plugin)};\n'
        'const VB_SCRIPTS = ${jsonEncode(scripts)};\n'
        '$runtime';
  }

  /// Plain JavaScript (not vBook ciphertext).
  static bool looksLikeScript(String s) =>
      RegExp(r'\bfunction\b|=>|\bvar\b|\blet\b|\bconst\b').hasMatch(s) && s.contains('execute');
}

/// 0.5.0: a vBook plugin whose scripts are encrypted by its author (runs only
/// inside the closed-source vBook app). Not an app error.
class VBookEncryptedException implements Exception {
  final String name;
  VBookEncryptedException(this.name);
  @override
  String toString() => tr('Tiện ích vBook "{p0}" được tác giả mã hóa – chỉ chạy được trong ứng dụng vBook.', {'p0': name});
}
