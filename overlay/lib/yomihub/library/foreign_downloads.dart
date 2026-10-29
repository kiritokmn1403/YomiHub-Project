import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/library/providers/file_scanner.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// One download folder of another reader app, at "source" level: its
/// children are titles, their children chapters / episodes – exactly what
/// YomiHub's local-library scanner reads.
class ForeignDownloadDir {
  final String app;
  final String path;
  final int titles;
  const ForeignDownloadDir(this.app, this.path, this.titles);
}

/// YomiHub 0.1.5: recognises chapters/episodes already downloaded by
/// Mangayomi, Mihon/Tachiyomi (+ forks), Aniyomi, Nekoyomi, Komikku, Anikku,
/// Kotatsu and LNReader, and adds them to the local library.
///
/// Layouts (from each app's DownloadProvider / storage code):
///  - Mihon, Tachiyomi, TachiyomiSY, Komikku, Yokai, Mangayomi(manga):
///      <root>/downloads/<Source (LANG)>/<Title>/<Chapter>(.cbz)
///  - Aniyomi, Anikku, Nekoyomi, Kuukiyomi:
///      <root>/downloads/<Source (LANG)>/<Title>/…   (manga)
///      <root>/downloads/anime/<Source (LANG)>/<Title>/<Episode>.mp4 (newer)
///  - Mangayomi: <root>/downloads/{Manga,Anime,Novel}/<Source (LANG)>/<Title>/…
///  - Kotatsu: <root>/<Title>.cbz or <root>/<Title>/… (folder "Kotatsu")
///  - LNReader: <root>/Novels/<plugin>/<novel>/… (only when stored outside
///      Android/data – Android 11+ hides other apps' private folders)
class ForeignDownloads {
  ForeignDownloads._();

  static const _apps = <String, List<String>>{
    'Mangayomi': ['Mangayomi'],
    'Mihon': ['Mihon'],
    'Tachiyomi': ['Tachiyomi', 'TachiyomiSY', 'TachiyomiJ2K'],
    'Komikku': ['Komikku'],
    'Yokai': ['Yokai'],
    'Aniyomi': ['Aniyomi'],
    'Anikku': ['Anikku'],
    'Nekoyomi': ['Nekoyomi', 'NekoYomi'],
    'Kuukiyomi': ['Kuukiyomi'],
    'Kotatsu': ['Kotatsu', 'Download/Kotatsu', 'Documents/Kotatsu'],
    'LNReader': ['LNReader', 'Download/LNReader', 'Documents/LNReader'],
  };

  static Future<List<Directory>> _roots() async {
    final roots = <Directory>[];
    if (Platform.isAndroid) {
      roots.add(Directory('/storage/emulated/0'));
    } else {
      final docs = await getApplicationDocumentsDirectory();
      roots.add(docs);
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (home != null) roots.add(Directory(home));
    }
    return roots;
  }

  static Future<bool> _isDir(String path) async {
    try {
      return await Directory(path).exists();
    } catch (_) {
      return false;
    }
  }

  static Future<List<Directory>> _subDirs(String path) async {
    try {
      return await Directory(path)
          .list(followLinks: false)
          .where((e) => e is Directory && !p.basename(e.path).startsWith('.'))
          .cast<Directory>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> _count(String path) async {
    try {
      return await Directory(path)
          .list(followLinks: false)
          .where((e) => !p.basename(e.path).startsWith('.'))
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// "source level" folders under a downloads folder.
  static Future<List<String>> _sourceDirs(String downloads) async {
    final out = <String>[];
    for (final d in await _subDirs(downloads)) {
      final name = p.basename(d.path);
      // Mangayomi groups by type, newer Aniyomi keeps anime under /anime.
      if (const ['Manga', 'Anime', 'Novel', 'anime', 'manga'].contains(name)) {
        out.addAll((await _subDirs(d.path)).map((e) => e.path));
      } else {
        out.add(d.path);
      }
    }
    return out;
  }

  static Future<List<ForeignDownloadDir>> scan() async {
    if (Platform.isAndroid) await StorageProvider().requestPermission();
    final found = <ForeignDownloadDir>[];
    final seen = <String>{};
    for (final root in await _roots()) {
      for (final e in _apps.entries) {
        for (final rel in e.value) {
          final base = p.join(root.path, rel);
          if (!await _isDir(base)) continue;
          final candidates = <String>[];
          if (e.key == 'Kotatsu') {
            candidates.add(base);
          } else if (e.key == 'LNReader') {
            final novels = p.join(base, 'Novels');
            candidates.addAll(
              (await _subDirs(await _isDir(novels) ? novels : base)).map((d) => d.path),
            );
          } else {
            final dl = p.join(base, 'downloads');
            if (await _isDir(dl)) candidates.addAll(await _sourceDirs(dl));
            final local = p.join(base, 'local');
            if (await _isDir(local)) candidates.add(local);
          }
          for (final c in candidates) {
            final key = p.normalize(c).toLowerCase();
            if (!seen.add(key)) continue;
            final n = await _count(c);
            if (n > 0) found.add(ForeignDownloadDir(e.key, c, n));
          }
        }
      }
    }
    return found;
  }
}

class ForeignDownloadsScreen extends ConsumerStatefulWidget {
  const ForeignDownloadsScreen({super.key});

  @override
  ConsumerState<ForeignDownloadsScreen> createState() =>
      _ForeignDownloadsScreenState();
}

class _ForeignDownloadsScreenState extends ConsumerState<ForeignDownloadsScreen> {
  List<ForeignDownloadDir>? _dirs;
  final _sel = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _dirs = null);
    final d = await ForeignDownloads.scan();
    final known = ref.read(localFoldersStateProvider).map((f) => f.path).toSet();
    if (!mounted) return;
    setState(() {
      _dirs = d;
      _sel
        ..clear()
        ..addAll(d.where((x) => !known.contains(x.path)).map((x) => x.path));
    });
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    final current = [...ref.read(localFoldersStateProvider)];
    final known = current.map((f) => f.path).toSet();
    for (final d in _dirs!.where((d) => _sel.contains(d.path))) {
      if (known.contains(d.path)) continue;
      current.add(
        LocalFolder.fromPath(
          path: d.path,
          name: '${d.app} · ${p.basename(d.path)}',
        ),
      );
    }
    ref.read(localFoldersStateProvider.notifier).set(current);
    try {
      await ref.read(scanLocalLibraryProvider.future);
    } catch (_) {}
    // Local items normally only show under Browse › Local: put the titles of
    // the folders just added straight into the Comic / Film / Novel library.
    final names = ref
        .read(localFoldersStateProvider)
        .where((f) => _sel.contains(f.path))
        .map((f) => '${f.name}/')
        .toSet();
    var added = 0;
    for (final m in await mangaRepository.getAllLocal()) {
      final link = (m.link ?? '').replaceAll('\\', '/');
      if (m.favorite == true || !names.any(link.startsWith)) continue;
      m.favorite = true;
      m.dateAdded = DateTime.now().millisecondsSinceEpoch;
      await mangaRepository.save(m);
      added++;
    }
    debugPrint('[ForeignDownloads] added $added titles to the library');
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Đã thêm vào thư viện (nguồn "Local")'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final known = ref.watch(localFoldersStateProvider).map((f) => f.path).toSet();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Chương đã tải từ ứng dụng khác')),
        actions: [IconButton(onPressed: _scan, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: (_dirs?.isNotEmpty ?? false) && _sel.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _add,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.library_add),
              label: Text(tr('Thêm {p0} thư mục', {'p0': _sel.length})),
            )
          : null,
      body: _dirs == null
          ? const Center(child: CircularProgressIndicator())
          : _dirs!.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  tr('Không tìm thấy thư mục tải xuống của Mangayomi, Mihon/Tachiyomi, Aniyomi, Nekoyomi, Komikku, Kotatsu hay LNReader trong bộ nhớ máy.\n\nNếu ứng dụng đó lưu ở nơi khác, thêm thư mục ấy trong Cài đặt › Tải xuống › Thư mục cục bộ.'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    tr('Chọn thư mục để YomiHub đọc trực tiếp (không sao chép, không xoá). Truyện/phim/novel sẽ hiện trong thư viện Comic, Film & Movie, Novel với nguồn "Local" và đọc/xem được ngoại tuyến.'),
                  ),
                ),
                for (final d in _dirs!)
                  CheckboxListTile(
                    value: known.contains(d.path) || _sel.contains(d.path),
                    onChanged: known.contains(d.path)
                        ? null
                        : (v) => setState(() => v == true ? _sel.add(d.path) : _sel.remove(d.path)),
                    title: Text('${d.app} · ${p.basename(d.path)}'),
                    subtitle: Text(
                      tr('{p0}{p1} mục\n{p2}', {'p0': known.contains(d.path) ? '${tr('Đã có trong thư viện')} • ' : '', 'p1': d.titles, 'p2': d.path}),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
    );
  }
}
