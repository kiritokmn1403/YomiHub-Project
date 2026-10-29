import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:mangayomi/models/category.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/category_repository.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/history_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/restore_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/services/extension_store_service.dart';
import 'package:mangayomi/yomihub/repos/repo_importer.dart';

/// YomiHub 0.1.7 – restore an LNReader backup (`.zip` with Version.json,
/// Category.json, Plugins.json, NovelAndChapters/<id>.json).
///
/// LNReader plugins are the same JavaScript plugins YomiHub's Novel tab
/// runs, so every novel is bound to the matching source (same id formula as
/// the extension store), with chapters, read / bookmark state, categories
/// and the last read chapter (history). The plugin repositories are worked
/// out from the installed plugins' download URLs and added to Novel ›
/// Extensions Repo. Merges into the library – nothing is deleted.
bool isLnReaderBackup(Archive a) =>
    a.files.any((f) => f.name == 'Version.json') &&
    a.files.any((f) =>
        f.name.startsWith('NovelAndChapters/') || f.name == 'Category.json' || f.name == 'Plugins.json');

class LnReaderImportResult {
  int novels = 0, chapters = 0, categories = 0, repos = 0;
  @override
  String toString() => 'LNReader: $novels truyện, $chapters chương, $categories danh mục, $repos kho';
}

dynamic _json(Archive a, bool Function(String) test) {
  final f = a.files.firstWhereOrNull((e) => e.isFile && test(e.name));
  if (f == null) return null;
  try {
    return jsonDecode(utf8.decode(f.content as List<int>, allowMalformed: true));
  } catch (_) {
    return null;
  }
}

/// `…/plugins/v3.0.0/.js/src/plugins/english/foo.js` →
/// `…/plugins/v3.0.0/.dist/plugins.min.json`.
String? lnReaderRepoFromPluginUrl(String url) {
  final i = url.indexOf('/.js/');
  if (i > 0) return '${url.substring(0, i)}/.dist/plugins.min.json';
  return null;
}

Status _status(Object? s) {
  final t = '${s ?? ''}'.toLowerCase();
  if (t.contains('ongoing')) return Status.ongoing;
  if (t.contains('complete')) return Status.completed;
  if (t.contains('hiatus')) return Status.onHiatus;
  if (t.contains('cancel')) return Status.canceled;
  return Status.unknown;
}

int? _ms(Object? v) {
  if (v == null) return null;
  final d = DateTime.tryParse('$v');
  return d?.millisecondsSinceEpoch;
}

Future<LnReaderImportResult> importLnReaderBackup(dynamic ref, Archive archive) async {
  final res = LnReaderImportResult();
  final plugins = <String, Map>{};
  final pl = _json(archive, (n) => n == 'Plugins.json');
  if (pl is List) {
    for (final p in pl.whereType<Map>()) {
      plugins['${p['id']}'] = p;
    }
  }
  // repositories first, so the sources exist when novels are bound
  final repoUrls = <String>{
    for (final p in plugins.values)
      if (lnReaderRepoFromPluginUrl('${p['url'] ?? ''}') != null) lnReaderRepoFromPluginUrl('${p['url']}')!,
  };
  if (repoUrls.isNotEmpty) {
    try {
      res.repos = await YomiRepoImporter.addAll(ref, [for (final u in repoUrls) ImportedRepo(u)]);
    } catch (_) {}
  }

  final novels = <Map>[
    for (final f in archive.files)
      if (f.isFile && f.name.startsWith('NovelAndChapters/') && f.name.endsWith('.json'))
        if (_json(archive, (n) => n == f.name) case final Map m) m,
  ];
  final cats = _json(archive, (n) => n == 'Category.json');

  final sources = sourceRepository.getAll();
  await restoreRepository.run(() {
    // categories (LNReader's built-in "Default" is skipped)
    final catByLnId = <int, int>{};
    final existing = categoryRepository.getByItemType(ItemType.novel);
    if (cats is List) {
      for (final c in cats.whereType<Map>()) {
        final name = '${c['name'] ?? ''}'.trim();
        final id = (c['id'] as num?)?.toInt();
        if (name.isEmpty || id == null || name == 'Default' || id == 1) continue;
        var cat = existing.firstWhereOrNull((e) => e.name == name);
        if (cat == null) {
          cat = Category(name: name, forItemType: ItemType.novel, pos: (c['sort'] as num?)?.toInt() ?? id);
          categoryRepository.putSync(cat);
          res.categories++;
        }
        if (cat.id != null) catByLnId[id] = cat.id!;
      }
    }
    final novelCats = <int, List<int>>{};
    if (cats is List) {
      for (final c in cats.whereType<Map>()) {
        final cid = catByLnId[(c['id'] as num?)?.toInt() ?? -1];
        if (cid == null) continue;
        for (final n in (c['novelIds'] as List? ?? const [])) {
          novelCats.putIfAbsent((n as num).toInt(), () => []).add(cid);
        }
      }
    }

    final byLink = {
      for (final m in mangaRepository.getByItemType(ItemType.novel))
        if (m.link != null) '${m.source}|${m.link}': m,
    };
    for (final n in novels) {
      final plugin = plugins['${n['pluginId']}'];
      final pluginName = '${plugin?['name'] ?? n['pluginId'] ?? 'LNReader'}';
      final lang = plugin == null ? 'en' : ExtensionStoreService.convertLnreaderLang(plugin['lang']);
      final sid = 'lnreader-plugin-"$pluginName"."$lang"'.hashCode;
      final src = sources.firstWhereOrNull((s) => s.id == sid) ??
          sources.firstWhereOrNull((s) => s.itemType == ItemType.novel && s.name?.toLowerCase() == pluginName.toLowerCase());
      final sourceName = src?.name ?? pluginName;
      final link = '${n['path'] ?? ''}';
      if (link.isEmpty) continue;
      final lnId = (n['id'] as num?)?.toInt() ?? -1;
      var manga = byLink['$sourceName|$link'];
      final isNew = manga == null;
      final cover = '${n['cover'] ?? ''}';
      manga ??= Manga(
        source: sourceName,
        author: '${n['author'] ?? ''}',
        artist: '${n['artist'] ?? ''}',
        genre: '${n['genres'] ?? ''}'.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        imageUrl: cover.startsWith('http') ? cover : '',
        lang: src?.lang ?? lang,
        link: link,
        name: '${n['name'] ?? ''}',
        status: _status(n['status']),
        description: '${n['summary'] ?? ''}',
        categories: novelCats[lnId] ?? [],
        itemType: ItemType.novel,
        favorite: n['inLibrary'] != false,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
        sourceId: src?.id,
      );
      if (!isNew) {
        manga.favorite = manga.favorite == true || n['inLibrary'] != false;
        manga.categories = {...?manga.categories, ...?novelCats[lnId]}.toList();
      }
      mangaRepository.putSync(manga);
      if (isNew) res.novels++;
      final have = isNew
          ? <String, Chapter>{}
          : {for (final c in chapterRepository.getAllByMangaId(manga.id)) if (c.url != null) c.url!: c};
      History? history;
      int lastRead = 0;
      for (final c in (n['chapters'] as List? ?? const []).whereType<Map>()) {
        final url = '${c['path'] ?? ''}';
        if (url.isEmpty) continue;
        final read = c['unread'] == false;
        final old = have[url];
        if (old != null) {
          // merge read / bookmark state
          if (read && old.isRead != true || (c['bookmark'] == true && old.isBookmarked != true)) {
            old.isRead = old.isRead == true || read;
            old.isBookmarked = old.isBookmarked == true || c['bookmark'] == true;
            chapterRepository.putSync(old);
          }
          continue;
        }
        final chapter = Chapter(
          mangaId: manga.id!,
          name: '${c['name'] ?? ''}',
          url: url,
          dateUpload: '${_ms(c['releaseTime']) ?? ''}',
          isRead: read,
          isBookmarked: c['bookmark'] == true,
          scanlator: '${c['scanlator'] ?? ''}',
          lastPageRead: c['progress'] is num && (c['progress'] as num) > 0 ? '${c['progress']}' : '',
        );
        chapterRepository.putSync(chapter..manga.value = manga);
        chapter.manga.saveSync();
        res.chapters++;
        final rt = _ms(c['readTime']) ?? 0;
        if (rt > lastRead) {
          lastRead = rt;
          history = History(
            mangaId: manga.id,
            date: '$rt',
            itemType: ItemType.novel,
            chapterId: chapter.id,
          )..chapter.value = chapter;
        }
      }
      if (history != null && historyRepository.findFirstByMangaId(manga.id) == null) {
        historyRepository.putSync(history);
        history.chapter.saveSync();
      }
    }
  });
  return res;
}
