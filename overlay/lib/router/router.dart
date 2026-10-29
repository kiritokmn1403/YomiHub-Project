import 'package:mangayomi/utils/platform_utils.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:mangayomi/yomihub/repos/extensions_repo_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/models/track_search.dart';
import 'package:mangayomi/modules/anime/anime_player_view.dart';
import 'package:mangayomi/modules/browse/extension/edit_code.dart';
import 'package:mangayomi/modules/browse/extension/extension_detail.dart';
import 'package:mangayomi/modules/browse/extension/widgets/create_extension.dart';
import 'package:mangayomi/modules/browse/sources/sources_filter_screen.dart';
import 'package:mangayomi/modules/calendar/calendar_screen.dart';
import 'package:mangayomi/modules/manga/detail/widgets/migrate_screen.dart';
import 'package:mangayomi/modules/mass_migration/mass_migration_source_selection_screen.dart';
import 'package:mangayomi/modules/manga/detail/widgets/recommendation_screen.dart';
import 'package:mangayomi/modules/manga/detail/widgets/related_screen.dart';
import 'package:mangayomi/modules/manga/detail/widgets/watch_order_screen.dart';
import 'package:mangayomi/modules/more/data_and_storage/create_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/data_and_storage.dart';
import 'package:mangayomi/modules/more/settings/appearance/custom_navigation_settings.dart';
import 'package:mangayomi/modules/more/settings/browse/source_repositories.dart';
import 'package:mangayomi/modules/more/settings/player/custom_button_screen.dart';
import 'package:mangayomi/modules/more/settings/player/player_advanced_screen.dart';
import 'package:mangayomi/modules/more/settings/player/player_audio_screen.dart';
import 'package:mangayomi/modules/more/settings/player/player_decoder_screen.dart';
import 'package:mangayomi/modules/more/settings/player/player_overview_screen.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/modules/more/statistics/statistics_screen.dart';
import 'package:mangayomi/modules/novel/novel_reader_view.dart';
import 'package:mangayomi/modules/tracker_library/tracker_library_screen.dart';
import 'package:mangayomi/modules/updates/updates_screen.dart';
import 'package:mangayomi/modules/more/categories/categories_screen.dart';
import 'package:mangayomi/modules/more/settings/downloads/downloads_screen.dart';
import 'package:mangayomi/modules/more/settings/player/player_screen.dart';
import 'package:mangayomi/modules/more/settings/sync/sync.dart';
import 'package:mangayomi/modules/more/settings/track/track.dart';
import 'package:mangayomi/modules/more/settings/track/manage_trackers/manage_trackers.dart';
import 'package:mangayomi/modules/more/settings/track/manage_trackers/tracking_detail.dart';
import 'package:mangayomi/modules/webview/webview.dart';
import 'package:mangayomi/yomihub/browser/browser_screen.dart';
import 'package:mangayomi/yomihub/vpn/vpn_screen.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_screen.dart';
import 'package:mangayomi/yomihub/extensions/merge_screen.dart';
import 'package:mangayomi/yomihub/share/share_screen.dart';
import 'package:mangayomi/yomihub/reader/reader_hub_screen.dart';
import 'package:mangayomi/yomihub/player/yomi_pip.dart';
import 'package:mangayomi/yomihub/ui/app_log_screen.dart';
import 'package:mangayomi/yomihub/qr/qr_screen.dart';
import 'package:mangayomi/yomihub/playbooks/play_books_screen.dart';
import 'package:mangayomi/yomihub/booru/booru_screen.dart';
import 'package:mangayomi/yomihub/booru/booru_settings_screen.dart';
import 'package:mangayomi/yomihub/playbooks/playbooks_settings_screen.dart';
import 'package:mangayomi/yomihub/microg/microg_screen.dart';
import 'package:mangayomi/yomihub/health/health_connect_screen.dart';
import 'package:mangayomi/yomihub/merge/content_merge_screen.dart';
import 'package:mangayomi/modules/browse/browse_screen.dart';
import 'package:mangayomi/modules/browse/extension/extension_lang.dart';
import 'package:mangayomi/modules/browse/global_search/global_search_screen.dart';
import 'package:mangayomi/modules/main_view/main_screen.dart';
import 'package:mangayomi/modules/history/history_screen.dart';
import 'package:mangayomi/modules/library/library_screen.dart';
import 'package:mangayomi/modules/manga/detail/manga_detail_main.dart';
import 'package:mangayomi/modules/manga/home/manga_home_screen.dart';
import 'package:mangayomi/modules/manga/reader/reader_view.dart';
import 'package:mangayomi/modules/more/about/about_screen.dart';
import 'package:mangayomi/modules/more/about/error_reports_screen.dart';
import 'package:mangayomi/modules/more/download_queue/download_queue_screen.dart';
import 'package:mangayomi/modules/more/more_screen.dart';
import 'package:mangayomi/modules/more/settings/appearance/appearance_screen.dart';
import 'package:mangayomi/modules/more/settings/browse/browse_screen.dart';
import 'package:mangayomi/modules/more/settings/browse/extension_server_screen.dart';
import 'package:mangayomi/modules/more/settings/general/general_screen.dart';
import 'package:mangayomi/modules/more/settings/reader/novel_reader_screen.dart';
import 'package:mangayomi/modules/more/settings/reader/reader_screen.dart';
import 'package:mangayomi/modules/more/settings/settings_screen.dart';
import 'package:mangayomi/modules/more/settings/security/security_screen.dart';
import 'package:mangayomi/services/crash_route_observer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
part 'router.g.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
@riverpod
GoRouter router(Ref ref) {
  final router = RouterNotifier();
  final hiddenItems = ref.read(hideItemsStateProvider);
  final initLocation = ref
      .watch(navigationOrderStateProvider)
      .where((e) => !hiddenItems.contains(e))
      .first;

  return GoRouter(
    observers: [BotToastNavigatorObserver(), CrashRouteObserver()],
    initialLocation: initLocation,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: router,
    routes: router._routes,
    navigatorKey: navigatorKey,
    onException: (context, state, router) => router.go(initLocation),
  );
}

@riverpod
class RouterCurrentLocationState extends _$RouterCurrentLocationState {
  bool _didSubscribe = false;
  @override
  String? build() {
    ref.keepAlive();
    // Delay listener‐registration until after the first frame.
    if (!_didSubscribe) {
      _didSubscribe = true;
      // Schedule the registration to run after the first build/frame:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _listener();
      });
    }
    return null;
  }

  void _listener() {
    final router = ref.read(routerProvider);
    router.routerDelegate.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final RouteMatchList matches =
            router.routerDelegate.currentConfiguration;
        final RouteMatch lastMatch = matches.last;
        final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
            ? lastMatch.matches
            : matches;
        state = matchList.uri.toString();
      });
    });
  }

  void refresh() {
    _listener();
  }
}

class RouterNotifier extends ChangeNotifier {
  List<RouteBase> get _routes => [
    // Each tab lives in its own StatefulShellBranch so switching tabs keeps
    // the other screens mounted (scroll position, queries, images preserved).
    //
    // Except on a television, where that retention is not affordable. Measured
    // on a Fire TV: every branch left mounted holds roughly 14 MB of GPU
    // surfaces, three tabs took Graphics from 27 MB to 69 MB, and the box has
    // around 300 MB free with most of its swap already spent. Off TV the
    // trade is the other way round and IndexedStack stays.
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          MainScreen(child: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) => isTv
          ? children[navigationShell.currentIndex]
          : IndexedStack(
              index: navigationShell.currentIndex,
              children: children,
            ),
      branches: [
        _branch(
          _genericRoute<String?>(
            name: "MangaLibrary",
            builder: (id) =>
                LibraryScreen(itemType: ItemType.manga, presetInput: id),
          ),
        ),
        _branch(
          _genericRoute<String?>(
            name: "AnimeLibrary",
            builder: (id) =>
                LibraryScreen(itemType: ItemType.anime, presetInput: id),
          ),
        ),
        _branch(
          _genericRoute<String?>(
            name: "NovelLibrary",
            builder: (id) =>
                LibraryScreen(itemType: ItemType.novel, presetInput: id),
          ),
        ),
        // YomiHub 0.1.5: Google Play Books beside Comic / Film / Novel.
        _branch(_genericRoute(name: "playBooks", child: const PlayBooksScreen())),
        // YomiHub 0.4.4: Booru App, right of Play Books.
        _branch(_genericRoute(name: "booru", child: const BooruScreen())),
        _branch(
          _genericRoute<String?>(
            name: "trackerLibrary",
            builder: (id) => TrackerLibraryScreen(presetInput: id),
          ),
        ),
        _branch(_genericRoute(name: "history", child: const HistoryScreen())),
        _branch(_genericRoute(name: "updates", child: const UpdatesScreen())),
        _branch(_genericRoute(name: "browse", child: const BrowseScreen())),
        _branch(_genericRoute(name: "more", child: const MoreScreen())),
      ],
    ),
    _genericRoute<(Source?, bool)>(
      name: "mangaHome",
      builder: (id) => MangaHomeScreen(source: id.$1!, isLatest: id.$2),
    ),
    _genericRoute<int>(
      path: "/manga-reader/detail",
      builder: (id) => MangaReaderDetail(mangaId: id),
    ),
    _genericRoute<int>(
      name: "mangaReaderView",
      // Keyed by chapter id so a chapter-to-chapter pushReplacement fully
      // remounts instead of reusing the Element and going stale.
      builder: (id) =>
          MangaReaderView(key: ValueKey('mangaReader-$id'), chapterId: id),
    ),
    _genericRoute<int>(
      name: "animePlayerView",
      builder: (id) =>
          AnimePlayerView(key: ValueKey('animePlayer-$id'), episodeId: id),
    ),
    _genericRoute<int>(
      name: "novelReaderView",
      builder: (id) =>
          NovelReaderView(key: ValueKey('novelReader-$id'), chapterId: id),
    ),
    _genericRoute<ItemType>(
      name: "ExtensionLang",
      builder: (itemType) => ExtensionsLang(itemType: itemType),
    ),
    _genericRoute(name: "settings", child: const SettingsScreen()),
    _genericRoute(name: "appearance", child: const AppearanceScreen()),
    _genericRoute<Source>(
      name: "extension_detail",
      builder: (source) => ExtensionDetail(source: source),
    ),
    _genericRoute<(String?, ItemType)>(
      name: "globalSearch",
      builder: (data) => GlobalSearchScreen(search: data.$1, itemType: data.$2),
    ),
    _genericRoute(name: "about", child: const AboutScreen()),
    _genericRoute(name: "browser", child: const BrowserScreen()),
    _genericRoute(name: "vpn", child: const VpnScreen()),
    _genericRoute<String?>(
      name: "vpnDns",
      builder: (page) => VpnScreen(page: page ?? 'hub'),
    ),
    _genericRoute(name: "cloudBackup", child: const CloudBackupScreen()),
    _genericRoute(name: "contentMerge", child: const ContentMergeScreen()),
    _genericRoute(name: "mergeExtensions", child: const ExtensionMergeScreen()),
    _genericRoute(name: "airdropQuickshare", child: const AirDropQuickShareScreen()),
    _genericRoute(name: "ebookPdf", child: const ReaderHubScreen()),
    _genericRoute(name: "pipSettings", child: const PipSettingsScreen()),
    _genericRoute(name: "appLog", child: const AppLogScreen()),
    _genericRoute(name: "qr", child: const YomiQrScreen()),
    _genericRoute(name: "microg", child: const MicroGScreen()),
    _genericRoute(name: "healthConnect", child: const HealthConnectScreen()),
    _genericRoute(name: "playBooksSettings", child: const PlayBooksSettingsScreen()),
    _genericRoute(name: "booruSettings", child: const BooruSettingsScreen()),
    _genericRoute(name: "errorReports", child: const ErrorReportsScreen()),
    _genericRoute(name: "track", child: const TrackScreen()),
    _genericRoute(name: "sync", child: const SyncScreen()),
    _genericRoute<ItemType>(
      name: "sourceFilter",
      builder: (itemType) => SourcesFilterScreen(itemType: itemType),
    ),
    _genericRoute(name: "downloadQueue", child: const DownloadQueueScreen()),
    _genericRoute<Map<String, dynamic>>(
      name: "mangawebview",
      builder: (data) => MangaWebView(url: data["url"]!, title: data['title']!),
    ),
    _genericRoute<(bool, int)>(
      name: "categories",
      builder: (data) => CategoriesScreen(data: data),
    ),
    _genericRoute(name: "statistics", child: const StatisticsScreen()),
    _genericRoute(name: "general", child: const GeneralScreen()),
    _genericRoute(name: "readerMode", child: const ReaderScreen()),
    _genericRoute(name: "novelReaderMode", child: const NovelReaderScreen()),
    _genericRoute(name: "browseS", child: const BrowseSScreen()),
    _genericRoute(
      name: "extensionServer",
      child: const ExtensionServerScreen(),
    ),
    _genericRoute(
      name: "extensionsRepo",
      child: const ExtensionsRepoScreen(),
    ),
    _genericRoute<ItemType>(
      name: "SourceRepositories",
      builder: (itemType) => SourceRepositories(itemType: itemType),
    ),
    _genericRoute(name: "downloads", child: const DownloadsScreen()),
    _genericRoute(name: "dataAndStorage", child: const DataAndStorage()),
    _genericRoute(name: "security", child: const SecurityScreen()),
    _genericRoute(name: "manageTrackers", child: const ManageTrackersScreen()),
    _genericRoute<TrackPreference>(
      name: "trackingDetail",
      builder: (trackerPref) => TrackingDetail(trackerPref: trackerPref),
    ),
    _genericRoute(name: "playerOverview", child: const PlayerOverviewScreen()),
    _genericRoute(name: "playerMode", child: const PlayerScreen()),
    _genericRoute<int>(
      name: "codeEditor",
      builder: (sourceId) => CodeEditorPage(sourceId: sourceId),
    ),
    _genericRoute<Source?>(
      name: "createExtension",
      builder: (source) => CreateExtension(editSource: source),
    ),
    _genericRoute(name: "createBackup", child: const CreateBackup()),
    _genericRoute(
      name: "customNavigationSettings",
      child: const CustomNavigationSettings(),
    ),
    _genericRoute(
      name: "customButtonScreen",
      child: const CustomButtonScreen(),
    ),
    _genericRoute(
      name: "playerDecoderScreen",
      child: const PlayerDecoderScreen(),
    ),
    _genericRoute(name: "playerAudioScreen", child: const PlayerAudioScreen()),
    _genericRoute(
      name: "playerAdvancedScreen",
      child: const PlayerAdvancedScreen(),
    ),
    _genericRoute<ItemType?>(
      name: "calendarScreen",
      builder: (itemType) => CalendarScreen(itemType: itemType),
    ),
    _genericRoute<Manga>(
      name: "migrate",
      builder: (manga) => MigrationScreen(manga: manga),
    ),
    _genericRoute<dynamic>(
      name: "massMigration",
      builder: (data) {
        if (data is (ItemType, Manga?, List<Manga>?)) {
          return MassMigrationSourceSelectionScreen(
            itemType: data.$1,
            prioritizedManga: data.$2,
            selectedMangas: data.$3,
          );
        }
        if (data is (ItemType, Manga?)) {
          return MassMigrationSourceSelectionScreen(
            itemType: data.$1,
            prioritizedManga: data.$2,
          );
        }
        return MassMigrationSourceSelectionScreen(itemType: data as ItemType);
      },
    ),
    _genericRoute<(Manga, TrackSearch)>(
      name: "migrate/tracker",
      builder: (data) => MigrationScreen(manga: data.$1, trackSearch: data.$2),
    ),
    _genericRoute<(String, ItemType)>(
      name: "related",
      builder: (data) => RelatedScreen(name: data.$1, itemType: data.$2),
    ),
    _genericRoute<(String, ItemType, AlgorithmWeights)>(
      name: "recommendations",
      builder: (data) => RecommendationScreen(
        name: data.$1,
        itemType: data.$2,
        algorithmWeights: data.$3,
      ),
    ),
    _genericRoute<(String, Track?)>(
      name: "watchOrder",
      builder: (data) => WatchOrderScreen(name: data.$1, track: data.$2),
    ),
  ];

  StatefulShellBranch _branch(GoRoute route) =>
      StatefulShellBranch(routes: [route]);

  /// YomiHub 0.1.8: go_router can rebuild a page with `extra == null`
  /// (e.g. when a screen is pushed on top with Navigator.push – Short Video,
  /// web player…), which threw "type 'Null' is not a subtype of …". The last
  /// extra of each page is remembered and reused.
  static final Map<String, Object?> _extras = {};
  static T _extraOf<T>(GoRouterState state) {
    final key = state.pageKey.value;
    final extra = state.extra;
    // YomiHub 0.1.9: after a restore (app sent to background / Android
    // killed the activity) go_router hands back the extra decoded from JSON,
    // i.e. a Map instead of the Source/Manga object: "_Map<String, dynamic>
    // is not a subtype of type 'Source'" (13x in logs.txt).
    if (extra is T) {
      _extras[key] = extra;
      if (_extras.length > 64) _extras.remove(_extras.keys.first);
      return extra;
    }
    final cached = _extras[key];
    if (cached is T) return cached;
    if (extra is Map) {
      final m = Map<String, dynamic>.from(extra);
      if (T == Source || T.toString() == 'Source?') {
        final id = m['id'];
        final byId = id is int ? sourceRepository.getById(id) : null;
        return (byId ?? Source.fromJson(m)) as T;
      }
    }
    throw _MissingExtra(T.toString());
  }

  GoRoute _genericRoute<T>({
    String? name,
    String? path,
    Widget Function(T extra)? builder,
    Widget? child,
  }) {
    return GoRoute(
      path: path ?? (name != null ? "/$name" : "/"),
      name: name,
      builder: (context, state) {
        if (builder != null) {
          try {
            return builder(_extraOf<T>(state));
          } on _MissingExtra {
            return const _LostPage();
          }
        } else {
          return child!;
        }
      },
      pageBuilder: isApple
          ? (context, state) {
              final pageChild = builder != null
                  ? builder(_extraOf<T>(state))
                  : child!;
              return transitionPage(key: state.pageKey, child: pageChild);
            }
          : null,
    );
  }
}

Page transitionPage({required LocalKey key, required child}) {
  return CupertinoPage(key: key, child: child);
}

Route createRoute({required Widget page}) {
  return isApple
      ? CupertinoPageRoute(builder: (context) => page)
      : MaterialPageRoute(builder: (context) => page);
}

class _MissingExtra implements Exception {
  final String type;
  const _MissingExtra(this.type);
}

/// Shown instead of a crash when a page was restored without its data.
class _LostPage extends StatelessWidget {
  const _LostPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off, size: 48),
              const SizedBox(height: 12),
              Text(tr('Trang này không còn dữ liệu sau khi ứng dụng được mở lại. Hãy quay lại và mở lại.'), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(tr('Quay lại')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
