import sys; sys.path.insert(0,'.')
from edit import edit
R='lib/modules/more/data_and_storage/providers/restore.dart'
edit(R,"""  // YomiHub: bring the other app's extension repositories along.
  try {
    final repos = YomiRepoImporter.fromTachiBk(Uint8List.fromList(content));
    if (repos.isNotEmpty) await YomiRepoImporter.addAll(ref, repos);
  } catch (_) {}""","""  // YomiHub: bring the other app's extension repositories along.
  // 0.5.2: in the background - addAll() fetches every repository index, and
  // one unreachable repo (kohiden.xyz, TLS error) kept the restore dialog
  // open ~40 s on the Note 9 before the library was even written.
  var repoImport = Future<void>.value();
  try {
    final repos = YomiRepoImporter.fromTachiBk(Uint8List.fromList(content));
    if (repos.isNotEmpty) {
      repoImport = () async {
        try {
          await YomiRepoImporter.addAll(ref, repos);
        } catch (_) {}
      }();
    }
  } catch (_) {}""")
edit(R,"""      trackRepository.clearPreferencesSync();
    }
  });
  keepAlive.close(); // 0.5.2: screens refreshed by doRestore
}""","""      trackRepository.clearPreferencesSync();
    }
  });
  // 0.5.2: screens refreshed by doRestore; kept alive until the repository
  // import started above has finished.
  unawaited(repoImport.whenComplete(keepAlive.close));
}""")
