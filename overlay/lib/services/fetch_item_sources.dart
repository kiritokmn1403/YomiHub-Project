import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';
import 'package:mangayomi/yomihub/extensions/repo_log_format.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mangayomi/utils/log/logger.dart';
export 'package:mangayomi/yomihub/extensions/repo_log_format.dart';
part 'fetch_item_sources.g.dart';

class RepoRefreshResult {
  final int ok;
  final int failed;
  final List<RepoRefreshFailure> failures;

  const RepoRefreshResult({
    required this.ok,
    required this.failed,
    this.failures = const [],
  });
}

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

Future<RepoRefreshResult> refreshExtensionReposDetailed(
  Iterable<Repo> repos,
  Future<void> Function(Repo) fetch,
) async {
  final repoList = repos.toList();
  final duplicateHosts = findDuplicateRepoHosts(repoList.map((r) => r.jsonUrl));
  var ok = 0;
  final failures = <RepoRefreshFailure>[];
  for (final repo in repoList) {
    try {
      await fetch(repo);
      ok++;
    } catch (e) {
      final cause = e is YomiLoggedError ? e.inner : e;
      final classified = classifyRepoError(cause);
      final cleanUrl = sanitizeRepoUrl(repo.jsonUrl);
      final label = repoDisplayLabel(
        repo.name,
        repo.jsonUrl,
        duplicateHosts: duplicateHosts,
      );
      final failure = RepoRefreshFailure(
        repoLabel: label,
        repoUrl: cleanUrl,
        kind: classified.kind,
        httpStatus: classified.httpStatus,
        shortReason: classified.shortReason,
      );
      failures.add(failure);
      if (e is! YomiLoggedError) {
        AppLogger.log(
          '[Tiện ích] Không cập nhật được kho ${failure.repoLabel} (${failure.shortReason})',
          logLevel: LogLevel.error,
        );
      }
    }
  }
  return RepoRefreshResult(
    ok: ok,
    failed: failures.length,
    failures: List.unmodifiable(failures),
  );
}

Future<({int ok, int failed})> refreshExtensionRepos(
  Iterable<Repo> repos,
  Future<void> Function(Repo) fetch,
) async {
  final r = await refreshExtensionReposDetailed(repos, fetch);
  return (ok: r.ok, failed: r.failed);
}
