import sys; sys.path.insert(0,'.')
from edit import edit
B='lib/modules/more/data_and_storage/providers/backup_format.dart'
edit(B,"""        newChapters += a.episodes.length;
      }
    }
  }

  return TachiBkImportPreview(""","""        newChapters += a.episodes.length;
      }
    }
  }

  AppLogger.log(
    '[Sao lưu] Xem trước ${p.basename(path)}: $newSeries bộ mới, $updatedSeries cập nhật, $newChapters chương mới (${(swPreview.elapsedMilliseconds / 1000).toStringAsFixed(1)} s)',
    logLevel: LogLevel.info,
  );
  return TachiBkImportPreview(""")
edit(B,"""BackupType? _sniffTachiBk(String path) {""","""/// Chapter URLs of the given series, read in batches of 200 ids with
/// asynchronous Isar queries (0.5.2).
Future<Map<int, Set<String>>> _chapterUrlsFor(Iterable<int?> ids) async {
  final wanted = ids.whereType<int>().toSet().toList();
  final out = <int, Set<String>>{};
  for (var i = 0; i < wanted.length; i += 200) {
    final part = wanted.sublist(i, i + 200 > wanted.length ? wanted.length : i + 200);
    for (final c in await chapterRepository.getAllByMangaIds(part)) {
      final id = c.mangaId, url = c.url;
      if (id != null && url != null) (out[id] ??= <String>{}).add(url);
    }
  }
  return out;
}

BackupType? _sniffTachiBk(String path) {""")
edit(B,"""import 'package:mangayomi/yomihub/backup/lnreader_backup.dart';
""","""import 'package:mangayomi/yomihub/backup/lnreader_backup.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:path/path.dart' as p;
""")
