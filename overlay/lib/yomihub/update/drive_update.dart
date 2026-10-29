import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:html/parser.dart' as html;
import 'package:mangayomi/services/fetch_sources_list.dart'
    show compareVersions;

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

  static Future<List<_Entry>> _list(String folderId, http.Client client) async {
    http.Response? r;
    Object? lastErr;
    // 0.4.3: 3 attempts with growing pauses – "Software caused connection
    // abort" (Android dropping the socket when the network switches) used to
    // fail the whole check after one retry.
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        r = await client
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
        if (r.statusCode == 200) break;
      } catch (e) {
        lastErr = e;
        final dns = '$e'.contains('Failed host lookup');
        if (dns) break; // no network: retrying cannot help
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 600 * (attempt + 1) * (attempt + 1)));
        }
      }
    }
    if (r == null || r.statusCode != 200) {
      if (lastErr != null) throw lastErr;
      throw http.ClientException('Drive HTTP ${r?.statusCode ?? 0}', r?.request?.url);
    }
    final document = html.parse(r.body);
    if (document.querySelector('.flip-entries') == null &&
        document.querySelector('.flip-entry') == null) {
      throw const FormatException('Drive folder listing unavailable');
    }
    return [
      for (final entry in document.querySelectorAll('.flip-entry'))
        _Entry(
          id: entry.id.replaceFirst('entry-', ''),
          folder: (entry.querySelector('a')?.attributes['href'] ?? '').contains(
            '/folders/',
          ),
          name: entry.querySelector('.flip-entry-title')?.text.trim() ?? '',
          modified:
              entry.querySelector('.flip-entry-last-modified')?.text.trim() ??
              '',
        ),
    ];
  }

  /// Walks the folder (max depth 3, max 30 folders) and returns the newest
  /// version above [current] that has files:
  /// (version, notes, folder link, download links).
  static Future<(String, String, String, List<dynamic>)?> check(
    String current, {
    http.Client? client,
    bool Function(String name)? acceptsFile,
  }) async {
    final ownsClient = client == null;
    final transport = client ?? IOClient(yomiDartHttpClient());
    final byVersion = <String, List<(_Entry, String)>>{};
    final folderOf = <String, String>{};
    var budget = 30;
    final visited = <String>{};
    Future<void> walk(String id, String? inherited, int depth) async {
      if (!visited.add(id) || budget-- <= 0) return;
      final List<_Entry> entries;
      try {
        entries = await _list(id, transport);
      } catch (e) {
        // 0.4.3: one unreadable sub-folder no longer fails the whole check
        if (depth == 0) rethrow;
        AppLogger.logOnce(
          'drive-sub:$id',
          '[Kiểm tra cập nhật] Bỏ qua thư mục con Google Drive $id: $e',
          logLevel: LogLevel.warning,
        );
        return;
      }
      entries.sort(
        (a, b) => compareVersions(
          _verRe.firstMatch(b.name)?.group(1) ?? '0.0.0',
          _verRe.firstMatch(a.name)?.group(1) ?? '0.0.0',
        ),
      );
      for (final e in entries) {
        final v = _verRe.firstMatch(e.name)?.group(1) ?? inherited;
        if (e.folder) {
          // 0.4.3: folders are visited newest first; once a newer version
          // with installers was found, older version folders are skipped.
          if (v != null &&
              byVersion.keys.any((k) => compareVersions(k, v) > 0)) {
            continue;
          }
          if (depth < 3) {
            if (v != null) folderOf.putIfAbsent(v, () => e.id);
            await walk(e.id, v, depth + 1);
          }
        } else if (v != null &&
            RegExp(
              r'\.(apk|exe|msix|msixbundle|appx|appxbundle|zip|ipa|dmg|pkg|appimage|deb|rpm)$',
              caseSensitive: false,
            ).hasMatch(e.name) &&
            (acceptsFile == null || acceptsFile(e.name))) {
          (byVersion[v] ??= []).add((e, id));
        }
      }
    }

    try {
      await walk(rootFolderId, null, 0).timeout(const Duration(seconds: 60));
    } finally {
      if (ownsClient) transport.close();
    }
    if (byVersion.isEmpty) return null;
    final versions = byVersion.keys.toList()
      ..sort((a, b) => compareVersions(b, a));
    final latest = versions.first;
    if (compareVersions(current, latest) >= 0) return null;
    final files = byVersion[latest]!;
    final notes = StringBuffer(
      tr('Bản YomiHub {p0} trên Google Drive:\n', {'p0': latest}),
    );
    for (final (e, _) in files) {
      notes.writeln(
        '- ${e.name}${e.modified.isEmpty ? '' : ' (${e.modified})'}',
      );
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
