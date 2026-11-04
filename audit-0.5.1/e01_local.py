import sys; sys.path.insert(0,'audit-0.5.1'); from edit import edit
F='lib/modules/library/providers/file_scanner.dart'
edit(F, """bool _isIgnoredLocalSubDirectory(Directory dir) {
  final name = p.basename(dir.path);
  return name.startsWith('.') || name.endsWith('_subtitles');
}""", """/// 0.5.1: app data folders that sit next to downloads in a shared
/// Mihon/Aniyomi/Nekoyomi/Mangayomi storage folder (never titles).
const _yhAppDataDirs = {
  'autobackup', 'mpv-config', 'fonts', 'shaders', 'scripts', 'script-opts',
  '.thumbnails', 'cache', 'logs',
};

bool _isIgnoredLocalSubDirectory(Directory dir) {
  final name = p.basename(dir.path);
  final lower = name.toLowerCase();
  // 0.5.1: "<chapter>_tmp" = unfinished download of Mihon/Aniyomi/Mangayomi
  return name.startsWith('.') ||
      name.endsWith('_subtitles') ||
      lower.endsWith('_tmp') ||
      _yhAppDataDirs.contains(lower);
}

/// 0.5.1: backups of other apps are not comics (Kotatsu `*.bk.zip`).
bool _isForeignBackupFile(String path) {
  final n = p.basename(path).toLowerCase();
  return n.endsWith('.bk.zip') || n.endsWith('.tachibk') || n.endsWith('.backup');
}

Future<File?> _firstVideoFileInDirectory(Directory dir) async {
  try {
    final entities = await listLocalDirectory(dir, logContext: '_firstVideoFileInDirectory');
    final videos = (await localFiles(entities, logContext: '_firstVideoFileInDirectory'))
        .where((f) => isVideoFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return videos.firstOrNull;
  } catch (_) {
    return null;
  }
}

/// 0.5.1 (YomiHub Update: "thư mục cục bộ không nhận diện được các tệp đã
/// tải của Aniyomi, Nekoyomi, Mangayomi"). Those apps keep titles 2–3 levels
/// below the folder the user picks:
///   Mihon/Aniyomi/Nekoyomi: downloads/<Source (LANG)>/<Title>/<Chapter>.cbz
///                           downloads/<Source (LANG)>/<Title>/<Episode>/<Episode>.mkv
///   Mangayomi:              downloads/Manga|Anime|Novel/<Source (LANG)>/<Title>/…
/// The scanner treated every first-level folder ("downloads", "local", …) as
/// a title and found nothing. Walk down until a folder holds chapter content
/// itself (archive / video / epub file, or a sub folder with images or a
/// video); that folder is a title. Copies of the same tree nested inside
/// each other ("localnovel/localnovel/downloads/…") import once.
Future<List<Directory>> _collectTitleFolders(List<Directory> top) async {
  final out = <Directory>[];
  final seen = <String>{};
  var visited = 0;
  Future<void> visit(Directory d, int depth) async {
    if (visited++ > 20000) return;
    if (_isIgnoredLocalSubDirectory(d)) return;
    final children = await listLocalDirectory(d, logContext: '_collectTitleFolders');
    final files = await localFiles(children, logContext: '_collectTitleFolders');
    final subs = (await localDirectories(children, logContext: '_collectTitleFolders'))
        .where((s) => !_isIgnoredLocalSubDirectory(s))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    var isTitle = depth >= 4 ||
        subs.isEmpty ||
        files.any((f) =>
            !_isForeignBackupFile(f.path) &&
            (isArchiveFile(f.path) || isVideoFile(f.path) || isEpubFile(f.path)));
    if (!isTitle) {
      for (final s in subs) {
        if (await _firstImageFileInDirectory(s) != null ||
            await _firstVideoFileInDirectory(s) != null) {
          isTitle = true;
          break;
        }
      }
    }
    if (isTitle) {
      final key = '${p.basename(d.parent.path)}/${p.basename(d.path)}'.toLowerCase();
      if (depth == 0 || seen.add(key)) out.add(d);
      return;
    }
    for (final s in subs) {
      await visit(s, depth + 1);
    }
  }
  final sortedTop = [...top]..sort((a, b) => a.path.compareTo(b.path));
  for (final d in sortedTop) {
    await visit(d, 0);
  }
  return out;
}""")
edit(F, """  // Iterate over each sub-directory (each representing a title, Manga or Anime)
  for (final folder in titleFolders) {""", """  // Iterate over each sub-directory (each representing a title, Manga or Anime)
  // 0.5.1: titles may sit deeper (downloads/<Source>/<Title>), see
  // _collectTitleFolders.
  final scanTitleFolders = await _collectTitleFolders(titleFolders);
  debugPrint('[LocalLibraryScanner] title folders: top=${titleFolders.length}, titles=${scanTitleFolders.length}');
  for (final folder in scanTitleFolders) {""")
edit(F, """  )).where((f) => !isHiddenSystemFile(f.path)).toList();""", """  )).where((f) => !isHiddenSystemFile(f.path) && !_isForeignBackupFile(f.path)).toList();""")
edit(F, """    final hasImagesFolders = imageChapterDirs.isNotEmpty;
    final hasArchives = files.any((f) => isArchiveFile(f.path));
    final hasVideos = files.any((f) => isVideoFile(f.path));""", """    // 0.5.1: Aniyomi/Nekoyomi/Mangayomi keep each episode in its own folder
    // ("Episode 3/Episode 3.mkv", "Video/Video.mkv").
    final episodeVideos = <File>[];
    for (final subDir in subDirs) {
      if (_isIgnoredLocalSubDirectory(subDir) || imageChapterDirs.contains(subDir)) continue;
      final v = await _firstVideoFileInDirectory(subDir);
      if (v != null) episodeVideos.add(v);
    }
    final hasImagesFolders = imageChapterDirs.isNotEmpty;
    final hasArchives = files.any((f) => isArchiveFile(f.path) && !_isForeignBackupFile(f.path));
    final hasVideos = files.any((f) => isVideoFile(f.path)) || episodeVideos.isNotEmpty;""")
edit(F, """      final videos = files.where((f) => isVideoFile(f.path)).toList();
      addNewChapters(videos, false);""", """      final videos = files.where((f) => isVideoFile(f.path)).toList();
      addNewChapters(videos, false, relativePath);
      // 0.5.1: episode folders – the folder name is the episode name
      // (the file inside is often just "Video.mkv" / "Episode.mkv").
      for (final v in episodeVideos) {
        addNewChapters([v], false, relativePath, p.basename(p.dirname(v.path)));
      }""")
edit(F, """      final archives = files.where((f) => isArchiveFile(f.path)).toList();""", """      final archives = files.where((f) => isArchiveFile(f.path) && !_isForeignBackupFile(f.path)).toList();""")
edit(F, """  void addNewChapters(
    List<FileSystemEntity> items,
    bool imageFolder, [
    String? mangaKey,
  ]) {""", """  void addNewChapters(
    List<FileSystemEntity> items,
    bool imageFolder, [
    String? mangaKey,
    String? nameOverride,
  ]) {""")
edit(F, """          mangaKey ?? p.posix.dirname(relPath),
        ]);""", """          mangaKey ?? p.posix.dirname(relPath),
          nameOverride,
        ]);""")
edit(F, """          name:
              pathBool[1] // If Chapter is an image folder or archive/video
              ? p.basename(chapterPath)
              : p.basenameWithoutExtension(chapterPath),""", """          name: (pathBool.length > 4 && pathBool[4] != null)
              ? pathBool[4] as String
              : pathBool[1] // If Chapter is an image folder or archive/video
              ? p.basename(chapterPath)
              : p.basenameWithoutExtension(chapterPath),""")
