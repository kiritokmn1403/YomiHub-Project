import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/library/providers/file_scanner.dart';
import 'package:mangayomi/modules/library/providers/local_directory_resolver.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.1.7 – "Thư mục cục bộ" (Cài đặt › Tải xuống), reworked after
/// Kotatsu's storage manager and Aniyomi/Nekoyomi's local source:
///  * any number of folders, duplicates / nested folders refused,
///  * picking an Aniyomi / Mihon / Nekoyomi storage root offers its
///    `local`, `localanime`, `localnovel` sub-folders instead,
///  * free / total space per folder, number of titles,
///  * rename (library links are migrated), rescan one folder,
///  * remove a folder optionally together with its titles.
class YomiLocalFolders {
  YomiLocalFolders._();

  static const _tools = MethodChannel('com.yomihub/tools');

  /// Sub-folders that Tachiyomi-family apps use for their local source.
  static const knownLocalSubdirs = ['local', 'localanime', 'localnovel', 'localmanga'];

  /// Returns an error text when [path] can't be added, or null.
  static String? validateNew(String path, List<LocalFolder> existing, {LocalFolder? defaultFolder}) {
    final key = localFolderPathKey(path);
    for (final f in [?defaultFolder, ...existing]) {
      final other = f.path;
      if (other == null || other.isEmpty) continue;
      final o = localFolderPathKey(other);
      if (o == key) return 'Thư mục này đã có trong danh sách (${f.name}).';
      if (key.startsWith('$o/')) {
        return 'Thư mục này nằm bên trong “${f.name}” – các truyện/phim trong đó đã được quét.';
      }
      if (o.startsWith('$key/')) {
        return 'Thư mục này chứa “${f.name}” đã có trong danh sách. Hãy gỡ “${f.name}” trước hoặc chọn thư mục khác.';
      }
    }
    return null;
  }

  /// Aniyomi/Mihon/Nekoyomi storage roots: the local-source sub-folders.
  static Future<List<String>> localSubfolders(String path) async {
    final out = <String>[];
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return out;
      await for (final e in dir.list(followLinks: false)) {
        if (e is Directory && knownLocalSubdirs.contains(p.basename(e.path).toLowerCase())) {
          out.add(e.path);
        }
      }
    } catch (_) {}
    out.sort();
    return out;
  }

  /// (free, total) bytes of the volume holding [path], or null.
  static Future<(int, int)?> diskSpace(String path) async {
    try {
      if (Platform.isAndroid) {
        final r = await _tools.invokeMapMethod<String, dynamic>('diskSpace', {'path': path});
        if (r == null) return null;
        return ((r['free'] as num).toInt(), (r['total'] as num).toInt());
      }
      if (Platform.isWindows) return _winDiskSpace(path);
      final res = await Process.run('df', ['-Pk', path]);
      final lines = '${res.stdout}'.trim().split('\n');
      if (lines.length < 2) return null;
      final f = lines.last.split(RegExp(r'\s+'));
      return (int.parse(f[3]) * 1024, int.parse(f[1]) * 1024);
    } catch (_) {
      return null;
    }
  }

  static (int, int)? _winDiskSpace(String path) {
    final k32 = DynamicLibrary.open('kernel32.dll');
    final fn = k32.lookupFunction<
        Int32 Function(Pointer<Utf16>, Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>),
        int Function(Pointer<Utf16>, Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>)>(
      'GetDiskFreeSpaceExW',
    );
    var dir = path;
    // the folder may not exist yet: walk up to an existing parent
    while (!Directory(dir).existsSync() && p.dirname(dir) != dir) {
      dir = p.dirname(dir);
    }
    final name = dir.toNativeUtf16();
    final free = calloc<Uint64>(), total = calloc<Uint64>(), totalFree = calloc<Uint64>();
    try {
      if (fn(name, free, total, totalFree) == 0) return null;
      return (free.value, total.value);
    } finally {
      calloc.free(name);
      calloc.free(free);
      calloc.free(total);
      calloc.free(totalFree);
    }
  }

  static String formatBytes(int b) {
    const u = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = b.toDouble();
    var i = 0;
    while (v >= 1024 && i < u.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v >= 100 || i == 0 ? 0 : 1)} ${u[i]}';
  }

  static bool _inFolder(String? link, String name) {
    if (link == null) return false;
    final n = normalizePath(link);
    return n == name || n.startsWith('$name/');
  }

  /// Library titles imported from the folder called [name].
  static Future<List<Manga>> titlesOf(String name) async {
    final all = await mangaRepository.getAllLocal();
    return all.where((m) => _inFolder(m.link, name)).toList();
  }

  /// Titles per item type, e.g. {manga: 3, anime: 1}.
  static Future<Map<ItemType, int>> countTitles(String name) async {
    final out = <ItemType, int>{};
    for (final m in await titlesOf(name)) {
      out[m.itemType] = (out[m.itemType] ?? 0) + 1;
    }
    return out;
  }

  /// Renames a folder and rewrites the virtual paths stored in the library
  /// (`<name>/Title/Chapter…`), so nothing has to be re-imported.
  static Future<String?> rename(WidgetRef ref, LocalFolder folder, String newName) async {
    final oldName = folder.name ?? '';
    newName = newName.trim().replaceAll('/', '_').replaceAll('\\', '_');
    if (newName.isEmpty) return 'Tên không được để trống';
    if (newName == oldName) return null;
    final folders = ref.read(localFoldersStateProvider);
    if (newName.toLowerCase() == 'local' || folders.any((f) => f.name == newName)) {
      return 'Đã có thư mục tên “$newName”';
    }
    String move(String v) => newName + normalizePath(v).substring(oldName.length);
    final titles = await titlesOf(oldName);
    final chapters = await chapterRepository.getAllByMangaIds(titles.map((m) => m.id));
    final changedChapters = chapters.where((c) => _inFolder(c.archivePath, oldName)).toList();
    for (final c in changedChapters) {
      c.archivePath = move(c.archivePath!);
    }
    for (final m in titles) {
      m.link = move(m.link!);
    }
    await mangaRepository.putAll(titles);
    if (changedChapters.isNotEmpty) await chapterRepository.putAll(changedChapters);
    ref.read(localFoldersStateProvider.notifier).set([
      for (final f in folders)
        f.name == oldName && f.path == folder.path ? LocalFolder(name: newName, path: f.path) : f,
    ]);
    return null;
  }

  /// Removes [folder] from the list; with [purge] its titles leave the
  /// library too (files on disk are never touched).
  static Future<int> remove(WidgetRef ref, LocalFolder folder, {bool purge = false}) async {
    var removed = 0;
    if (purge && (folder.name ?? '').isNotEmpty) {
      final titles = await titlesOf(folder.name!);
      removed = titles.length;
      if (titles.isNotEmpty) await mangaRepository.wipeMangas(ref, titles);
    }
    final temp = ref.read(localFoldersStateProvider).toList()
      ..removeWhere((e) => e.name == folder.name && e.path == folder.path);
    ref.read(localFoldersStateProvider.notifier).set(temp);
    return removed;
  }

  /// Opens the folder in the system file manager (desktop).
  static Future<void> reveal(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.start('explorer.exe', [path], mode: ProcessStartMode.detached);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path], mode: ProcessStartMode.detached);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [path], mode: ProcessStartMode.detached);
      }
    } catch (_) {}
  }
}
