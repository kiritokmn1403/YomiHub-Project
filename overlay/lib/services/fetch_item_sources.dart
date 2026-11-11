import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mangayomi/utils/log/logger.dart';
part 'fetch_item_sources.g.dart';

@Riverpod(keepAlive: true)
Future<void> fetchItemSourcesList(
  Ref ref, {
  int? id,
  required bool reFresh,
  required ItemType itemType,
}) async {
  if (ref.watch(checkForExtensionsUpdateStateProvider) || reFresh) {
    final repos = ref.watch(extensionsRepoStateProvider(itemType));
    final proxyServer = ref.watch(androidProxyServerStateProvider);
    final autoUpdate = ref.watch(autoUpdateExtensionsStateProvider);
    await refreshExtensionRepos(repos, (repo) => fetchSourcesList(
      repo: repo, refresh: reFresh, id: id, androidProxyServer: proxyServer,
      autoUpdateExtensions: autoUpdate, itemType: itemType,
    ));
  }
}

Future<({int ok, int failed})> refreshExtensionRepos(
  Iterable<Repo> repos, Future<void> Function(Repo) fetch,
) async {
  var ok = 0;
  var failed = 0;
  for (final repo in repos) {
    try {
      await fetch(repo);
      ok++;
    } catch (e) {
      failed++;
      if (e is! YomiLoggedError) {
        final host = Uri.tryParse(repo.jsonUrl ?? '')?.host ?? '';
        AppLogger.log('[Tiện ích] Không cập nhật được kho $host (${e.runtimeType})', logLevel: LogLevel.error);
      }
    }
  }
  return (ok: ok, failed: failed);
}
