import sys,os,re; sys.path.insert(0,os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/audit-0.5.3')); from edit import edit, ROOT
F='lib/yomihub/extensions/builtin_extensions.dart'
p=os.path.join(ROOT,'overlay',F); s=open(p,encoding='utf-8').read()
start=s.index('  static Future<String> _code(BuiltinExtension e) async {')
end=s.index('/// Groups of installed sources that point at the same website.')
old=s[start:end]
new='''  // ── 0.5.3 (sheet "YomiHub Update" mục 2) ────────────────────────────
  // The website extensions above are no longer bundled in the app: their
  // code moved to github.com/kiritokmn1403/Kiritokmn---Extension-Repo
  // (repo/yomihub/<asset>, same ids). The list stays for the ids (Shorts
  // feed, domain mirrors). On the first start of 0.5.3 the repo is added to
  // the Comic / Film & Movie / Novel repo lists (the user chose "only add the
  // repo": nothing is installed automatically), and copies that are already
  // installed are re-linked to the repo so they keep working and receive
  // updates from it (repo version 0.5.3 > bundled versions).
  static const repoName = 'Kiritokmn Extension Repo';
  static const repoBase =
      'https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main';
  static const repoJson = '$repoBase/repo/index.json';
  static const repoWebsite =
      'https://github.com/kiritokmn1403/Kiritokmn---Extension-Repo';

  static Repo get repo =>
      Repo(name: repoName, website: repoWebsite, jsonUrl: repoJson);

  /// Adds [repoJson] to a repo list unless it is there already.
  static List<Repo> withRepo(List<Repo>? current) {
    final list = List<Repo>.from(current ?? const <Repo>[]);
    final key = repoJson.toLowerCase();
    final has = list.any((r) {
      final u = (r.jsonUrl ?? '').trim().toLowerCase();
      return u == key || u == '$key/';
    });
    if (!has) list.add(repo);
    return list;
  }

  /// Runs once (before the first frame, right after the database opens).
  static Future<void> install() async {
    try {
      final box = await YomiHive.open(_box);
      if (box.get('repo_migrated_053') == true) return;
      await settingsRepository.update((s) {
        s.mangaExtensionsRepo = withRepo(s.mangaExtensionsRepo);
        s.animeExtensionsRepo = withRepo(s.animeExtensionsRepo);
        s.novelExtensionsRepo = withRepo(s.novelExtensionsRepo);
      });
      var moved = 0;
      for (final e in all) {
        final src = sourceRepository.getById(e.id);
        if (src == null) continue;
        src
          ..isLocal = false
          ..repo = repo
          ..sourceCodeUrl = '$repoBase/repo/yomihub/${e.asset}';
        await sourceRepository.save(src);
        moved++;
      }
      await box.put('repo_migrated_053', true);
      AppLogger.log(
        '[Tiện ích] 0.5.3: tiện ích website không còn tích hợp sẵn – đã thêm '
        'kho "$repoName" vào Truyện tranh / Phim & Điện ảnh / Tiểu thuyết; '
        '$moved tiện ích đã cài được chuyển sang nhận cập nhật từ kho này.',
        always: true,
      );
    } catch (error, st) {
      AppLogger.log(
        '[Tiện ích] Chuyển tiện ích tích hợp sang kho Kiritokmn thất bại: '
        '$error\\n$st',
        logLevel: LogLevel.error,
      );
      // never block startup because of this
    }
  }
}

'''
open(p,'w',encoding='utf-8',newline='').write(s)  # ensure backup via edit()
edit(F,old,new)
edit(F,"import 'package:flutter/services.dart';\n","import 'package:mangayomi/models/settings.dart';\nimport 'package:mangayomi/repositories/settings_repository.dart';\n")
edit(F,"/// Installs / updates the extensions bundled with YomiHub.\n///\n/// They are ordinary JavaScript sources (same engine as repository\n/// extensions), so filters, per-source settings (including the domain),\n/// downloads, migration and backup all work the same way.\n","/// Metadata of the extensions that were bundled with YomiHub up to 0.5.2.\n/// Since 0.5.3 their code lives in the Kiritokmn Extension Repo.\n")
M='lib/main.dart'
edit(M,"  unawaited(BuiltinExtensions.install());\n","")
edit(M,"""        isar = await storage.initDB(null, inspector: kDebugMode);
      } catch (e, st) {
        AppLogger.log('DB init failed: $e\\n$st', logLevel: LogLevel.error);
        startupError = e;
      }
""","""        isar = await storage.initDB(null, inspector: kDebugMode);
      } catch (e, st) {
        AppLogger.log('DB init failed: $e\\n$st', logLevel: LogLevel.error);
        startupError = e;
      }
      // 0.5.3: bundled website extensions -> Kiritokmn Extension Repo
      // (before the first frame, so the repo lists the UI reads include it)
      if (startupError == null) await BuiltinExtensions.install();
""")
