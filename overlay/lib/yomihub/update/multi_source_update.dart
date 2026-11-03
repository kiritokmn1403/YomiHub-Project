import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mangayomi/services/fetch_sources_list.dart'
    show compareVersions;
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/update/drive_update.dart';

/// YomiHub 0.4.9: "Check for update" walks every source of the
/// "Website Update Apps" sheet in its listed order and offers the first
/// source that has a newer version with installers for this platform:
///
///  I.  GitHub kiritokmn1403/YomiHub-Project (repo + Releases)
///  II. Google Drive ×3, MediaFire ×3 (YomiHub, Alpha, Beta)
class YomiUpdateSources {
  YomiUpdateSources._();

  static const githubRepo = 'kiritokmn1403/YomiHub-Project';
  static const driveFolders = [
    '16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__',
    '1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn',
    '1vLWPTfFznhWko0O6YGJqecnFEU5CLr10',
  ];
  static const mediafireFolders = ['kg0wfu3lpbc98', '8s2tlcukdmw6x', 'jmgm4xds8kamx'];

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';
  static final _verRe = RegExp(r'(\d+\.\d+\.\d+)');
  static final _installerRe = RegExp(
    r'\.(apk|exe|msix|msixbundle|appx|appxbundle|zip|ipa|dmg|pkg|appimage|deb|rpm)$',
    caseSensitive: false,
  );

  /// Returns (version, notes, page link, download links) or null.
  static Future<(String, String, String, List<dynamic>)?> check(
    String current, {
    required bool Function(String name) acceptsFile,
    http.Client? client,
  }) async {
    final ownsClient = client == null;
    final c = client ?? IOClient(yomiDartHttpClient());
    final errors = <String>[];
    try {
      final steps = <(String, Future<(String, String, String, List<dynamic>)?> Function())>[
        ('GitHub Releases', () => _github(c, acceptsFile)),
        for (final id in driveFolders)
          ('Google Drive $id', () => YomiDriveUpdate.check(current, client: c, acceptsFile: acceptsFile, folderId: id)),
        for (final key in mediafireFolders)
          ('MediaFire $key', () => _mediafire(c, key, acceptsFile)),
      ];
      for (final (label, run) in steps) {
        try {
          final r = await run().timeout(const Duration(seconds: 75));
          if (r != null && r.$4.isNotEmpty && compareVersions(current, r.$1) < 0) {
            AppLogger.log('[Kiểm tra cập nhật] Có bản ${r.$1} trên $label');
            return r;
          }
        } catch (e) {
          errors.add('$label: $e');
          AppLogger.logOnce(
            'upd-src:$label',
            '[Kiểm tra cập nhật] Không đọc được nguồn $label: $e',
            logLevel: LogLevel.warning,
          );
        }
      }
      if (errors.length == steps.length) {
        throw Exception('Không nguồn cập nhật nào trả lời (${errors.first})');
      }
      return null;
    } finally {
      if (ownsClient) c.close();
    }
  }

  // ---------------------------------------------------------------- GitHub
  static Future<(String, String, String, List<dynamic>)?> _github(
    http.Client c,
    bool Function(String) accepts,
  ) async {
    final api = await c.get(
      Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
      headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'YomiHub'},
    ).timeout(const Duration(seconds: 25));
    if (api.statusCode == 200) {
      final j = jsonDecode(api.body) as Map<String, dynamic>;
      final ver = _clean((j['tag_name'] ?? j['name'] ?? '').toString());
      final assets = [
        for (final a in (j['assets'] as List? ?? const []))
          (a as Map)['browser_download_url']?.toString() ?? '',
      ].where((u) => u.isNotEmpty && accepts(Uri.decodeComponent(u.split('/').last))).toList();
      if (ver.isEmpty) return null;
      return (ver, (j['body'] ?? '').toString(), (j['html_url'] ?? '').toString(), assets);
    }
    // 403/429 = anonymous API rate limit (60/h): read the public pages instead.
    final latest = http.Request('GET', Uri.parse('https://github.com/$githubRepo/releases/latest'))
      ..followRedirects = false
      ..headers['User-Agent'] = _ua;
    final res = await c.send(latest).timeout(const Duration(seconds: 25));
    final loc = res.headers['location'] ?? '';
    await res.stream.drain<void>();
    final tag = loc.split('/tag/').length > 1 ? Uri.decodeComponent(loc.split('/tag/').last) : '';
    final ver = _clean(tag);
    if (ver.isEmpty) return null;
    final page = await c.get(
      Uri.parse('https://github.com/$githubRepo/releases/expanded_assets/$tag'),
      headers: {'User-Agent': _ua},
    ).timeout(const Duration(seconds: 25));
    final links = RegExp(r'href="(/' + RegExp.escape(githubRepo) + r'/releases/download/[^"]+)"')
        .allMatches(page.body)
        .map((m) => 'https://github.com${m.group(1)}')
        .where((u) => accepts(Uri.decodeComponent(u.split('/').last)))
        .toSet()
        .toList();
    return (ver, 'YomiHub $ver (GitHub Releases)', 'https://github.com/$githubRepo/releases/tag/$tag', links);
  }

  static String _clean(String tag) =>
      tag.trim().replaceFirst(RegExp(r'^[vV]'), '').split(RegExp(r'[-+ ]')).first;

  // ------------------------------------------------------------- MediaFire
  static Future<(String, String, String, List<dynamic>)?> _mediafire(
    http.Client c,
    String rootKey,
    bool Function(String) accepts,
  ) async {
    final files = <(String, String, String)>[]; // (name, version, page link)
    var budget = 20;
    Future<void> walk(String key, String? inherited, int depth) async {
      if (budget-- <= 0) return;
      for (final type in ['files', 'folders']) {
        final r = await c.get(
          Uri.parse(
            'https://www.mediafire.com/api/1.5/folder/get_content.php'
            '?folder_key=$key&content_type=$type&response_format=json&chunk_size=200',
          ),
          headers: {'User-Agent': _ua},
        ).timeout(const Duration(seconds: 20));
        if (r.statusCode != 200) throw http.ClientException('MediaFire HTTP ${r.statusCode}');
        final content = ((jsonDecode(r.body) as Map)['response']?['folder_content'] ?? {}) as Map;
        if (type == 'files') {
          for (final f in (content['files'] as List? ?? const [])) {
            final name = (f['filename'] ?? '').toString();
            final v = _verRe.firstMatch(name)?.group(1) ?? inherited;
            final link = (f['links']?['normal_download'] ?? '').toString();
            if (v != null && link.isNotEmpty && _installerRe.hasMatch(name) && accepts(name)) {
              files.add((name, v, link));
            }
          }
        } else if (depth < 2) {
          final subs = [...(content['folders'] as List? ?? const [])]
            ..sort((a, b) => compareVersions(
                  _verRe.firstMatch('${b['name']}')?.group(1) ?? '0.0.0',
                  _verRe.firstMatch('${a['name']}')?.group(1) ?? '0.0.0',
                ));
          for (final f in subs.take(6)) {
            await walk('${f['folderkey']}', _verRe.firstMatch('${f['name']}')?.group(1) ?? inherited, depth + 1);
          }
        }
      }
    }

    await walk(rootKey, null, 0);
    if (files.isEmpty) return null;
    files.sort((a, b) => compareVersions(b.$2, a.$2));
    final latest = files.first.$2;
    final chosen = files.where((f) => f.$2 == latest).toList();
    final direct = <String>[];
    for (final (name, _, page) in chosen) {
      try {
        final p = await c.get(Uri.parse(page), headers: {'User-Agent': _ua}).timeout(const Duration(seconds: 20));
        final m = RegExp(r'href="(https://download[0-9]*\.mediafire\.com/[^"]+)"').firstMatch(p.body);
        if (m != null) direct.add('${m.group(1)}${m.group(1)!.contains('?') ? '&' : '?'}yhname=${Uri.encodeComponent(name)}');
      } catch (_) {}
    }
    final notes = StringBuffer('Bản YomiHub $latest trên MediaFire:\n');
    for (final f in chosen) {
      notes.writeln('- ${f.$1}');
    }
    return (latest, notes.toString(), 'https://www.mediafire.com/folder/$rootKey', direct);
  }
}
