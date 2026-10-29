import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/models/category.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/category_repository.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.1.9: state of the Short Video feed.
///
///  * every clip shown is remembered (last 5 000), so the feed is random and
///    a clip already watched comes back only 5 % of the time;
///  * "Yêu thích" puts the clip in its own library category
///    ([favouriteCategoryName]) and in a quick list for the feed;
///  * "Thêm vào thư viện" asks for the categories;
///  * "Tải xuống" stores the clip as an episode of the title, so it goes
///    through the normal download queue and shows in Downloads.
class ShortsStore {
  ShortsStore._();
  static const _boxName = 'yomihub_shorts';
  static const replayRate = 0.05;
  static const _maxSeen = 5000;
  static Box? _box;
  static final _rnd = Random();

  static Future<Box> _open() async =>
      _box ??= Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await YomiHive.open(_boxName);

  static String _key(Source s, String link) => '${s.id}|$link';

  // ───────── seen / random ─────────

  static Future<Set<String>> _seen() async {
    final b = await _open();
    return Set<String>.from((b.get('seen') as List?) ?? const []);
  }

  static Future<void> markSeen(Source s, String? link) async {
    if (link == null) return;
    final b = await _open();
    final list = List<String>.from((b.get('seen') as List?) ?? const []);
    final k = _key(s, link);
    list.remove(k);
    list.add(k);
    if (list.length > _maxSeen) list.removeRange(0, list.length - _maxSeen);
    await b.put('seen', list);
  }

  /// Random order; clips already watched survive with [replayRate].
  static Future<List<MManga>> shuffleFresh(Source s, List<MManga> batch) async {
    final seen = await _seen();
    final out = <MManga>[];
    for (final m in batch) {
      final link = m.link;
      if (link == null) continue;
      if (seen.contains(_key(s, link)) && _rnd.nextDouble() >= replayRate) continue;
      out.add(m);
    }
    out.shuffle(_rnd);
    return out;
  }

  static int randomStartPage() => 1 + _rnd.nextInt(3);

  // ───────── favourites ─────────

  static String get favouriteCategoryName => tr('Yêu thích (Short Video)');

  static Future<List<Map<String, dynamic>>> favourites() async {
    final b = await _open();
    return [
      for (final e in (b.get('favs') as List?) ?? const []) Map<String, dynamic>.from(e as Map),
    ];
  }

  static Future<bool> isFavourite(Source s, String? link) async {
    if (link == null) return false;
    return (await favourites()).any((e) => e['k'] == _key(s, link));
  }

  /// Toggles the favourite; returns the new state.
  static Future<bool> toggleFavourite(Source s, MManga m) async {
    final b = await _open();
    final list = await favourites();
    final k = _key(s, m.link ?? '');
    final cat = await _category(favouriteCategoryName, s.itemType);
    final manga = await ensureManga(s, m);
    final prev = list.where((e) => e['k'] == k).firstOrNull;
    final was = prev != null;
    if (was) {
      list.removeWhere((e) => e['k'] == k);
      final cats = [...?manga.categories]..remove(cat.id);
      manga.categories = cats;
      // only undo the library entry this button created
      if (cats.isEmpty && prev['owned'] == true) manga.favorite = false;
    } else {
      list.add({
        'k': k,
        'name': m.name,
        'link': m.link,
        'img': m.imageUrl,
        'src': s.id,
        'owned': !(manga.favorite ?? false),
      });
      manga
        ..favorite = true
        ..dateAdded ??= DateTime.now().millisecondsSinceEpoch
        ..categories = {...?manga.categories, cat.id!}.toList();
    }
    await mangaRepository.save(manga);
    await b.put('favs', list);
    return !was;
  }

  // ───────── library ─────────

  static Future<Category> _category(String name, ItemType type) async {
    final all = categoryRepository.getByItemType(type);
    final hit = all.where((c) => c.name == name).firstOrNull;
    if (hit != null) return hit;
    final c = Category(
      name: name,
      forItemType: type,
      pos: all.length,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await categoryRepository.save(c);
    return categoryRepository.getByItemType(type).firstWhere((e) => e.name == name);
  }

  /// The library row of clip [m] (created when missing, not favourite).
  static Future<Manga> ensureManga(Source s, MManga m) async {
    final name = (m.name ?? '').trim();
    final found = await mangaRepository.findAllByLangNameSource(s.lang!, name, s.name!);
    final hit = found.where((e) => e.sourceId == null || e.sourceId == s.id).firstOrNull;
    if (hit != null) return hit;
    final manga = Manga(
      imageUrl: m.imageUrl,
      name: name,
      genre: m.genre?.map((e) => e.toString()).toList() ?? [],
      author: m.author ?? '',
      status: m.status ?? Status.unknown,
      description: m.description ?? '',
      link: m.link,
      source: s.name,
      lang: s.lang,
      lastUpdate: 0,
      itemType: s.itemType,
      artist: m.artist ?? '',
      sourceId: s.id,
    );
    await mangaRepository.save(manga);
    return (await mangaRepository.findAllByLangNameSource(s.lang!, name, s.name!))
        .firstWhere((e) => e.sourceId == s.id, orElse: () => manga);
  }

  /// "Thêm vào thư viện": category picker, then favourite with them.
  static Future<bool> addToLibrary(BuildContext context, Source s, MManga m) async {
    final cats = categoryRepository.getByItemType(s.itemType);
    final manga = await ensureManga(s, m);
    final chosen = <int>{...?manga.categories};
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(tr('Thêm vào thư viện')),
          content: SizedBox(
            width: 320,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (cats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(tr('Chưa có danh mục: sẽ thêm vào danh mục Mặc định.')),
                  ),
                for (final c in cats)
                  CheckboxListTile(
                    dense: true,
                    value: chosen.contains(c.id),
                    title: Text(c.name ?? ''),
                    onChanged: (v) => set(() => v == true ? chosen.add(c.id!) : chosen.remove(c.id)),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(tr('Danh mục mới…')),
                  onPressed: () async {
                    final ctrl = TextEditingController();
                    final n = await showDialog<String>(
                      context: ctx,
                      builder: (c2) => AlertDialog(
                        title: Text(tr('Tên danh mục')),
                        content: TextField(controller: ctrl, autofocus: true),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c2), child: Text(tr('Hủy'))),
                          FilledButton(onPressed: () => Navigator.pop(c2, ctrl.text.trim()), child: Text(tr('Tạo'))),
                        ],
                      ),
                    );
                    if (n == null || n.isEmpty) return;
                    final c = await _category(n, s.itemType);
                    cats.add(c);
                    set(() => chosen.add(c.id!));
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Hủy'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Thêm'))),
          ],
        ),
      ),
    );
    if (ok != true) return false;
    manga
      ..favorite = true
      ..dateAdded ??= DateTime.now().millisecondsSinceEpoch
      ..categories = chosen.toList();
    await mangaRepository.save(manga);
    return true;
  }

  /// The episode to download for clip [m] (created when missing).
  static Future<Chapter> episodeFor(Source s, MManga m) async {
    final manga = await ensureManga(s, m);
    final name = (m.name ?? 'Video').trim();
    final existing = (await chapterRepository.findByMangaIdAndNameAsync(manga.id, name));
    if (existing != null) return existing;
    final ch = Chapter(mangaId: manga.id, name: name, url: m.link ?? '', dateUpload: '${DateTime.now().millisecondsSinceEpoch}')
      ..manga.value = manga;
    await chapterRepository.save(ch);
    return (await chapterRepository.findByMangaIdAndNameAsync(manga.id, name)) ?? ch;
  }
}
