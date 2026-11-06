import 'dart:convert';
import 'dart:io';

import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.5.3 (sheet "YomiHub Update" mục 7, from Tankobun's
/// "MyAnimeList-compatible XML export for matched AniList titles"):
/// exports every tracked title as the XML that myanimelist.net/import.php
/// (and AnymeX, Tachiyomi-family apps, Taiga…) can import.
///
/// MyAnimeList entries use their MAL id directly; AniList entries are matched
/// to MAL through AniList's `idMal` (one GraphQL query per 50 titles). Kitsu /
/// Simkl / other entries without a MAL id are counted as skipped.
class YomiMalExport {
  YomiMalExport._();

  static const malSyncId = 1;
  static const aniListSyncId = 2;

  static String _date(int? ms) {
    if (ms == null || ms <= 0) return '0000-00-00';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static String _cdata(String? s) =>
      '<![CDATA[${(s ?? '').replaceAll(']]>', ']]]]><![CDATA[>')}]]>';

  static String statusText(TrackStatus s, {required bool manga}) {
    switch (s) {
      case TrackStatus.reading:
      case TrackStatus.watching:
      case TrackStatus.reReading:
      case TrackStatus.reWatching:
        return manga ? 'Reading' : 'Watching';
      case TrackStatus.completed:
        return 'Completed';
      case TrackStatus.onHold:
        return 'On-Hold';
      case TrackStatus.dropped:
        return 'Dropped';
      case TrackStatus.planToRead:
      case TrackStatus.planToWatch:
        return manga ? 'Plan to Read' : 'Plan to Watch';
    }
  }

  /// MAL score is 0–10; trackers store 0–10 or 0–100.
  static int malScore(int? score) {
    final s = score ?? 0;
    if (s <= 10) return s.clamp(0, 10);
    return (s / 10).round().clamp(0, 10);
  }

  /// One `<anime>` / `<manga>` element.
  static String entryXml(Track t, int malId) {
    final manga = t.isManga ?? false;
    final b = StringBuffer();
    if (manga) {
      b
        ..writeln('  <manga>')
        ..writeln('    <manga_mangadb_id>$malId</manga_mangadb_id>')
        ..writeln('    <manga_title>${_cdata(t.title)}</manga_title>')
        ..writeln('    <my_read_chapters>${t.lastChapterRead ?? 0}</my_read_chapters>')
        ..writeln('    <my_read_volumes>0</my_read_volumes>');
    } else {
      b
        ..writeln('  <anime>')
        ..writeln('    <series_animedb_id>$malId</series_animedb_id>')
        ..writeln('    <series_title>${_cdata(t.title)}</series_title>')
        ..writeln('    <my_watched_episodes>${t.lastChapterRead ?? 0}</my_watched_episodes>');
    }
    b
      ..writeln('    <my_start_date>${_date(t.startedReadingDate)}</my_start_date>')
      ..writeln('    <my_finish_date>${_date(t.finishedReadingDate)}</my_finish_date>')
      ..writeln('    <my_score>${malScore(t.score)}</my_score>')
      ..writeln('    <my_status>${statusText(t.status, manga: manga)}</my_status>')
      ..writeln('    <update_on_import>1</update_on_import>')
      ..writeln(manga ? '  </manga>' : '  </anime>');
    return b.toString();
  }

  static String document(List<String> entries, {required bool manga}) =>
      '<?xml version="1.0" encoding="UTF-8" ?>\n<myanimelist>\n'
      '  <myinfo><user_export_type>${manga ? 2 : 1}</user_export_type></myinfo>\n'
      '${entries.join()}</myanimelist>\n';

  /// AniList id -> MAL id (null when AniList has none).
  static Future<Map<int, int>> _aniListToMal(List<int> ids) async {
    final out = <int, int>{};
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      for (var i = 0; i < ids.length; i += 50) {
        final chunk = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
        final req = await client.postUrl(Uri.parse('https://graphql.anilist.co'));
        req.headers.contentType = ContentType.json;
        req.headers.set('Accept', 'application/json');
        req.write(jsonEncode({
          'query': r'query($ids:[Int]){Page(perPage:50){media(id_in:$ids){id idMal}}}',
          'variables': {'ids': chunk},
        }));
        final res = await req.close().timeout(const Duration(seconds: 30));
        final body = await res.transform(utf8.decoder).join();
        if (res.statusCode != 200) {
          throw HttpException('AniList HTTP ${res.statusCode}');
        }
        final media = (((jsonDecode(body) as Map)['data'] as Map?)?['Page'] as Map?)?['media'] as List? ?? const [];
        for (final m in media) {
          final id = (m as Map)['id'], mal = m['idMal'];
          if (id is int && mal is int) out[id] = mal;
        }
      }
    } finally {
      client.close(force: true);
    }
    return out;
  }

  /// Writes `YomiHub_MAL_anime_<date>.xml` / `…_manga_…` into the backup
  /// folder and returns a summary for the user.
  static Future<String> run() async {
    final all = await trackRepository.getAllAsync();
    final mal = all.where((t) => t.syncId == malSyncId && (t.mediaId ?? 0) > 0).toList();
    final ani = all.where((t) => t.syncId == aniListSyncId && (t.mediaId ?? 0) > 0).toList();
    Map<int, int> map = {};
    var aniError = '';
    if (ani.isNotEmpty) {
      try {
        map = await _aniListToMal(ani.map((t) => t.mediaId!).toSet().toList());
      } catch (e) {
        aniError = '$e';
      }
    }
    final animeXml = <int, String>{}, mangaXml = <int, String>{};
    var skipped = 0;
    void add(Track t, int? malId) {
      if (malId == null || malId <= 0) {
        skipped++;
        return;
      }
      ((t.isManga ?? false) ? mangaXml : animeXml).putIfAbsent(malId, () => entryXml(t, malId));
    }
    for (final t in mal) {
      add(t, t.mediaId);
    }
    for (final t in ani) {
      add(t, map[t.mediaId]);
    }
    skipped += all.where((t) => t.syncId != malSyncId && t.syncId != aniListSyncId).length;
    final dir = Directory(p.join((await StorageProvider().getDefaultDirectory())!.path, 'backup', 'export'));
    await dir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final files = <String>[];
    if (animeXml.isNotEmpty) {
      final f = File(p.join(dir.path, 'YomiHub_MAL_anime_$stamp.xml'));
      await f.writeAsString(document(animeXml.values.toList(), manga: false));
      files.add(f.path);
    }
    if (mangaXml.isNotEmpty) {
      final f = File(p.join(dir.path, 'YomiHub_MAL_manga_$stamp.xml'));
      await f.writeAsString(document(mangaXml.values.toList(), manga: true));
      files.add(f.path);
    }
    final summary = 'anime ${animeXml.length}, manga ${mangaXml.length}, bỏ qua $skipped'
        '${aniError.isEmpty ? '' : ' (AniList: $aniError)'}';
    AppLogger.log('[Tracker] Xuất MyAnimeList XML: $summary → ${files.join(', ')}',
        logLevel: aniError.isEmpty ? LogLevel.info : LogLevel.warning, always: true);
    // empty = nothing tracked on MAL / AniList (Note 9 test: no tracker
    // signed in); the screen says so instead of "exported 0".
    return files.isEmpty ? '' : '$summary\n${files.join('\n')}';
  }
}
