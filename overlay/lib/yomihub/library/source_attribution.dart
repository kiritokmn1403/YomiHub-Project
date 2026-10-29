import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/library/providers/library_filter_provider.dart';
import 'package:mangayomi/modules/widgets/manga_image_card_widget.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';

/// Which extension a local / downloaded title came from.
class YomiOrigin {
  final String name;
  final String lang;
  final int? sourceId;
  const YomiOrigin(this.name, this.lang, this.sourceId);

  String get label => lang.isEmpty || lang == 'all' ? name : '$name · ${lang.toUpperCase()}';
  String encode() => '$name\u0001$lang\u0001${sourceId ?? ''}';
  static YomiOrigin? decode(Object? v) {
    if (v is! String) return null;
    final p = v.split('\u0001');
    if (p.length < 3) return null;
    return YomiOrigin(p[0], p[1], int.tryParse(p[2]));
  }
}

/// YomiHub 0.2.2 – YomiHub Update: "Thêm tính năng xem trong các nguồn cục
/// bộ và tải xuống, bộ truyện nào, phim nào thuộc nguồn nào thì tích hợp nó
/// vào bộ extension đó" + "Khi tải truyện/phim xuống nhớ gắn nhãn
/// nguồn/extension của bộ truyện/phim đó bên cạnh".
///
/// Local titles (Thư mục cục bộ, downloads of Mihon / Aniyomi / Mangayomi /
/// Kotatsu found on the device) are matched to the extension they came from:
///  1. the folder layout `<Source (LANG)>/<Title>` used by Mihon, Aniyomi,
///     Nekoyomi, Mangayomi and YomiHub's own download folder;
///  2. a folder named exactly like an installed extension;
///  3. a title of the same name already in the library from an extension.
/// Every extension page then has "Đã tải & cục bộ" (its downloaded and
/// local titles), and download / library badges carry the source label.
class YomiSourceAttribution {
  YomiSourceAttribution._();
  static const _boxName = 'yomihub_local_origin';
  static Box? _box;
  static final Map<int, YomiOrigin> _map = {};
  static final ValueNotifier<int> changes = ValueNotifier(0);
  static bool _running = false;

  static final RegExp _srcLang = RegExp(r'^(.+?)\s*\(([A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,4})?|all|ALL)\)$');

  static Future<void> open() async {
    if (_box != null) return;
    try {
      _box = await YomiHive.open(_boxName);
      for (final k in _box!.keys) {
        final o = YomiOrigin.decode(_box!.get(k));
        final id = k is int ? k : int.tryParse('$k');
        if (o != null && id != null) _map[id] = o;
      }
      changes.value++;
    } catch (_) {}
  }

  /// Origin of [m]: its own extension, or the matched one for local titles.
  static YomiOrigin? of(Manga m) {
    final src = m.source ?? '';
    if (src.isNotEmpty && src != 'local' && !(m.isLocalArchive ?? false)) {
      return YomiOrigin(src, m.lang ?? '', m.sourceId);
    }
    return m.id == null ? null : _map[m.id!];
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9À-ỹ]+'), '');

  /// Matches every local title (background, after start-up / a local scan).
  static Future<int> refresh() async {
    if (_running) return 0;
    _running = true;
    var found = 0;
    try {
      await open();
      final installed = sourceRepository.getInstalled();
      final byName = <String, List<Source>>{};
      for (final s in installed) {
        byName.putIfAbsent(_norm(s.name ?? ''), () => []).add(s);
      }
      final locals = await mangaRepository.getAllLocal();
      // titles from real extensions, by normalised name + type
      final online = <String, Manga>{};
      for (final m in isar.mangas.filter().not().sourceEqualTo('local').findAllSync()) {
        if (m.isLocalArchive ?? false) continue;
        online.putIfAbsent('${m.itemType.index}|${_norm(m.name ?? '')}', () => m);
      }
      for (final m in locals) {
        if (m.id == null) continue;
        YomiOrigin? o;
        final segs = (m.link ?? '').replaceAll('\\', '/').split('/').where((e) => e.isNotEmpty).toList();
        // walk the parent folders from the title upwards
        for (var i = segs.length - 2; i >= 0 && o == null; i--) {
          final seg = segs[i];
          final mm = _srcLang.firstMatch(seg);
          final name = mm?.group(1) ?? seg;
          final lang = (mm?.group(2) ?? '').toLowerCase();
          final cands = byName[_norm(name)];
          if (cands != null && cands.isNotEmpty) {
            final s = cands.firstWhere(
              (c) => lang.isEmpty || (c.lang ?? '').toLowerCase() == lang && c.itemType == m.itemType,
              orElse: () => cands.firstWhere((c) => c.itemType == m.itemType, orElse: () => cands.first),
            );
            o = YomiOrigin(s.name ?? name, s.lang ?? lang, s.id);
          } else if (mm != null) {
            // "<Source (LANG)>" of an extension that is not installed here
            o = YomiOrigin(name, lang, null);
          }
        }
        if (o == null) {
          final hit = online['${m.itemType.index}|${_norm(m.name ?? '')}'];
          if (hit != null) o = YomiOrigin(hit.source ?? '', hit.lang ?? '', hit.sourceId);
        }
        final old = _map[m.id!];
        if (o != null && (old == null || old.encode() != o.encode())) {
          _map[m.id!] = o;
          await _box?.put(m.id!, o.encode());
          found++;
        }
      }
      if (found > 0) changes.value++;
    } catch (e) {
      AppLogger.logOnce('origin', 'Gắn nguồn cho thư viện cục bộ thất bại: $e');
    } finally {
      _running = false;
    }
    return found;
  }

  /// Local + downloaded titles that belong to [source].
  static List<Manga> titlesOf(Source source, Set<int> downloadedChapterIds) {
    final out = <int, Manga>{};
    for (final m in isar.mangas
        .filter()
        .sourceEqualTo(source.name)
        .langEqualTo(source.lang)
        .findAllSync()) {
      if (m.id == null || m.itemType != source.itemType) continue;
      if (m.chapters.any((c) => c.id != null && downloadedChapterIds.contains(c.id))) out[m.id!] = m;
    }
    for (final e in _map.entries) {
      final o = e.value;
      final match = (o.sourceId != null && o.sourceId == source.id) ||
          (_norm(o.name) == _norm(source.name ?? '') &&
              (o.lang.isEmpty || o.lang == (source.lang ?? '').toLowerCase()));
      if (!match || out.containsKey(e.key)) continue;
      final m = isar.mangas.getSync(e.key);
      if (m != null && m.itemType == source.itemType) out[e.key] = m;
    }
    final l = out.values.toList()
      ..sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
    return l;
  }
}

/// Small "source" chip (download queue, library badges, offline list).
class YomiSourceLabel extends StatelessWidget {
  final Manga manga;
  final bool dense;
  const YomiSourceLabel(this.manga, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: YomiSourceAttribution.changes,
      builder: (context, _, _) {
        final o = YomiSourceAttribution.of(manga);
        final local = (manga.source ?? '') == 'local' || (manga.isLocalArchive ?? false);
        if (o == null && !local) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        final text = o == null ? tr('Cục bộ') : (local ? '${tr('Cục bộ')} · ${o.label}' : o.label);
        return Container(
          margin: const EdgeInsets.only(left: 4),
          padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 6, vertical: dense ? 0 : 1),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: dense ? 9 : 10, color: cs.onSecondaryContainer),
          ),
        );
      },
    );
  }
}

/// "Đã tải & cục bộ" of one extension.
class YomiSourceOfflineScreen extends ConsumerStatefulWidget {
  final Source source;
  const YomiSourceOfflineScreen({super.key, required this.source});
  @override
  ConsumerState<YomiSourceOfflineScreen> createState() => _YomiSourceOfflineScreenState();
}

class _YomiSourceOfflineScreenState extends ConsumerState<YomiSourceOfflineScreen> {
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _rescan();
  }

  Future<void> _rescan() async {
    setState(() => _scanning = true);
    await YomiSourceAttribution.refresh();
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(downloadedChapterIdsProvider).asData?.value ?? const <int>{};
    return ValueListenableBuilder<int>(
      valueListenable: YomiSourceAttribution.changes,
      builder: (context, _, _) {
        final items = YomiSourceAttribution.titlesOf(widget.source, ids);
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('Đã tải & cục bộ · {p0}', {'p0': widget.source.name})),
            bottom: _scanning
                ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
                : null,
            actions: [
              IconButton(tooltip: tr('Quét lại'), icon: const Icon(Icons.refresh), onPressed: _scanning ? null : _rescan),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr('Chưa có bộ nào của tiện ích này được tải xuống hoặc nằm trong thư mục cục bộ.'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final local = (m.source ?? '') == 'local' || (m.isLocalArchive ?? false);
                    final dl = m.chapters.where((c) => c.id != null && ids.contains(c.id)).length;
                    return ListTile(
                      leading: Icon(local ? Icons.folder_outlined : Icons.download_done_outlined),
                      title: Text(m.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Row(
                        children: [
                          Flexible(
                            child: Text(
                              local
                                  ? tr('Cục bộ • {p0} chương/tập', {'p0': m.chapters.length})
                                  : tr('Đã tải {p0} chương/tập', {'p0': dl}),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          YomiSourceLabel(m, dense: true),
                        ],
                      ),
                      onTap: () => pushToMangaReaderDetail(
                        ref: ref,
                        context: context,
                        archiveId: local ? m.id : null,
                        lang: m.lang ?? '',
                        mangaM: m,
                        source: m.source ?? '',
                        sourceId: m.sourceId,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
