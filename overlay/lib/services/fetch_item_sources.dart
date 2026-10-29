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
    for (Repo repo in repos) {
      try {
        await fetchSourcesList(
          repo: repo,
          refresh: reFresh,
          id: id,
          androidProxyServer: proxyServer,
          autoUpdateExtensions: autoUpdate,
          itemType: itemType,
        );
      } catch (e, st) {
        if (e is YomiLoggedError) continue; // 0.2.2: logged once already
        // The user just sees no sources for the repo.
        AppLogger.log(
          'fetchItemSources: repo fetch failed: $e\n$st',
          logLevel: LogLevel.error,
        );
      }
    }
  }
}
