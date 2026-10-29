import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mangayomi/services/fetch_sources_list.dart' show compareVersions;

/// YomiHub 0.1.6: "Check for update" reads the shared Google Drive folder
/// instead of the old (upstream GitHub) release channel.
///
/// The folder is public, so it is read through Drive's embeddable folder
/// view (plain HTML, no API key, no sign-in). Layout is free-form: version
/// folders (`Beta/0.1.7/…`) and/or versioned file names
/// (`YomiHub-0.1.7-arm64-v8a.apk`) are both understood. The newest version
/// that actually contains files is offered.
class YomiDriveUpdate {
  YomiDriveUpdate._();

  static const rootFolderId = '16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__';
  static const rootUrl =
      'https://drive.google.com/drive/folders/$rootFolderId?usp=sharing';

  static final _entryRe = RegExp(
    r'<div class="flip-entry" id="entry-([^"]+)".*?<a href="([^"]+)".*?'
    r'<div class="flip-entry-title">([^<]*)</div>.*?'
    r'<div class="flip-entry-last-modified"><div>([^<]*)</div>',
    dotAll: true,
  );
  static final _verRe = RegExp(r'(\d+\.\d+\.\d+)');

  /// Direct download link for a Drive file. `yhname` carries the file name so
  /// the downloader can name the file and pick the right ABI.
  static String downloadUrl(String id, String name) =>
      'https://drive.usercontent.google.com/download?id=$id&export=download'
      '&confirm=t&yhname=${Uri.encodeComponent(name)}';

  /// File name carried by [downloadUrl] (or the last path segment).
  static String fileName(String url) {
    final u = Uri.tryParse(url);
    final n = u?.queryParameters['yhname'];
    if (n != null && n.isNotEmpty) return n;
    return url.split('/').last.split('?').first;
  }

  static Future<List<_Entry>> _list(String folderId) async {
    final r = await http
        .get(
          Uri.parse(
            'https://drive.google.com/embeddedfolderview?id=$folderId#list',
          ),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
            'Accept-Language': 'en',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return const [];
    final body = r.body;
    return [
      for (final m in _entryRe.allMatches(body))
        _Entry(
          id: m.group(1)!,
          folder: m.group(2)!.contains('/folders/'),
          name: _unescape(m.group(3)!.trim()),
          modified: m.group(4)!.trim(),
        ),
    ];
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  /// Walks the folder (max depth 3, max 30 folders) and returns the newest
  /// version above [current] that has files:
  /// (version, notes, folder link, download links).
  static Future<(String, String, String, List<dynamic>)?> check(
    String current,
  ) async {
    final byVersion = <String, List<(_Entry, String)>>{};
    final folderOf = <String, String>{};
    var budget = 30;
    Future<void> walk(String id, String? inherited, int depth) async {
      if (budget-- <= 0) return;
      List<_Entry> entries;
      try {
        entries = await _list(id);
      } catch (_) {
        return;
      }
      for (final e in entries) {
        final v = _verRe.firstMatch(e.name)?.group(1) ?? inherited;
        if (e.folder) {
          if (depth < 3) {
            if (v != null) folderOf.putIfAbsent(v, () => e.id);
            await walk(e.id, v, depth + 1);
          }
        } else if (v != null) {
          (byVersion[v] ??= []).add((e, id));
        }
      }
    }

    await walk(rootFolderId, null, 0);
    if (byVersion.isEmpty) return null;
    final versions = byVersion.keys.toList()
      ..sort((a, b) => compareVersions(b, a));
    final latest = versions.first;
    if (compareVersions(current, latest) >= 0) return null;
    final files = byVersion[latest]!;
    final notes = StringBuffer('Bản YomiHub $latest trên Google Drive:\n');
    for (final (e, _) in files) {
      notes.writeln('- ${e.name}${e.modified.isEmpty ? '' : ' (${e.modified})'}');
    }
    final folder = folderOf[latest] ?? files.first.$2;
    return (
      latest,
      notes.toString(),
      'https://drive.google.com/drive/folders/$folder',
      [for (final (e, _) in files) downloadUrl(e.id, e.name)],
    );
  }
}

class _Entry {
  final String id;
  final bool folder;
  final String name;
  final String modified;
  const _Entry({
    required this.id,
    required this.folder,
    required this.name,
    required this.modified,
  });
}
