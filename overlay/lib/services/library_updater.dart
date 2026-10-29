import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/modules/manga/detail/providers/update_manga_detail_providers.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/theme_mode_state_provider.dart';
import 'package:mangayomi/modules/more/settings/security/providers/security_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/services/update_errors_provider.dart';
import 'package:mangayomi/yomihub/perf/perf_watchdog.dart';

/// Tracks whether a library update is running and lets the UI request its
/// cancellation. The update loop checks [LibraryUpdateState.cancelRequested]
/// between entries and stops early.
class LibraryUpdateState {
  final bool running;
  final bool cancelRequested;
  const LibraryUpdateState({
    this.running = false,
    this.cancelRequested = false,
  });
  LibraryUpdateState copyWith({bool? running, bool? cancelRequested}) =>
      LibraryUpdateState(
        running: running ?? this.running,
        cancelRequested: cancelRequested ?? this.cancelRequested,
      );
}

class LibraryUpdateNotifier extends Notifier<LibraryUpdateState> {
  @override
  LibraryUpdateState build() => const LibraryUpdateState();
  void begin() => state = const LibraryUpdateState(running: true);
  void requestCancel() {
    if (state.running) state = state.copyWith(cancelRequested: true);
  }

  void end() => state = const LibraryUpdateState();
}

final libraryUpdateProvider =
    NotifierProvider<LibraryUpdateNotifier, LibraryUpdateState>(
      LibraryUpdateNotifier.new,
    );

/// Refreshes every entry in [mangaList], reporting progress through
/// [onProgress] rather than touching the UI, so the same loop can run both
/// behind the library's update button and unattended on launch.
///
/// Returns the entries that failed. Honours the Stop button: the caller has
/// already marked the run as started, and this checks for a cancellation
/// between entries.
Future<List<UpdateError>> _runUpdate({
  required WidgetRef ref,
  required List<Manga> mangaList,
  required String itemtype,
  void Function(int done, int failed, int total)? onProgress,
}) async {
  final failures = <UpdateError>[];
  // 0.4.3: no network at all → don't hit every source (each would fail with
  // a DNS error and fill the log, see logs 22: 698 × "Failed to update").
  try {
    final c = await Connectivity().checkConnectivity();
    if (c.isEmpty || c.every((r) => r == ConnectivityResult.none)) {
      AppLogger.log(
        '[Cập nhật thư viện] Bỏ qua: thiết bị không có kết nối mạng',
        logLevel: LogLevel.warning,
      );
      return failures;
    }
  } catch (_) {}
  YomiPerf.activity('cập nhật thư viện');
  // 0.4.3: a source that keeps failing (Cloudflare, site moved, Madara
  // redirect broken…) is skipped for the rest of the run after 3 failures in
  // a row instead of being retried for every entry.
  final strikes = <String, int>{};
  final skipped = <String>{};
  for (var i = 0; i < mangaList.length; i++) {
    // Stop early if the user pressed Stop.
    if (ref.read(libraryUpdateProvider).cancelRequested) break;
    final manga = mangaList[i];
    final key = '${manga.source}|${manga.lang}';
    if (skipped.contains(key)) {
      failures.add(
        UpdateError(
          mangaId: manga.id ?? 0,
          name: manga.name ?? "Unknown $itemtype",
          error:
              'Bỏ qua: nguồn "${manga.source}" lỗi liên tiếp trong lần cập nhật này',
        ),
      );
      onProgress?.call(i + 1, failures.length, mangaList.length);
      continue;
    }
    try {
      await ref.read(
        updateMangaDetailProvider(
          mangaId: manga.id,
          isInit: false,
          showToast: false,
        ).future,
      );
      strikes.remove(key);
    } catch (e) {
      final msg = _shortError(e);
      AppLogger.log(
        '[Cập nhật thư viện] Không cập nhật được $itemtype "${manga.name}" • '
        'nguồn: ${manga.source} (${manga.lang}) • lỗi: $msg',
        logLevel: LogLevel.error,
      );
      failures.add(
        UpdateError(
          mangaId: manga.id ?? 0,
          name: manga.name ?? "Unknown $itemtype",
          error: msg,
        ),
      );
      final n = (strikes[key] ?? 0) + 1;
      strikes[key] = n;
      if (n >= 3) {
        skipped.add(key);
        AppLogger.log(
          '[Cập nhật thư viện] Nguồn "${manga.source}" (${manga.lang}) lỗi $n lần '
          'liên tiếp – tạm bỏ qua các mục còn lại của nguồn này trong lần cập nhật này',
          logLevel: LogLevel.warning,
        );
      }
    }
    onProgress?.call(i + 1, failures.length, mangaList.length);
    // YomiHub 0.4.1: Cooperative delay to prevent UI freezing during library update
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  YomiPerf.activityDone('cập nhật thư viện');
  return failures;
}

/// First meaningful line of an error, without Dart/native stack dumps.
String _shortError(Object e) {
  final lines = e
      .toString()
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('***') && !l.startsWith('#') && !l.startsWith('<asynchronous'))
      .toList();
  final text = lines.take(2).join(' ');
  return text.length > 300 ? '${text.substring(0, 300)}…' : text;
}

Future<void> updateLibrary({
  required WidgetRef ref,
  required BuildContext context,
  required List<Manga> mangaList,
  required ItemType itemType,
}) async {
  final itemtype = itemType.name[0].toUpperCase() + itemType.name.substring(1);
  AppLogger.log("Starting $itemtype library update...");
  if (mangaList.isEmpty) {
    AppLogger.log("$itemtype library is empty. Nothing to update.");
    return;
  }
  // Don't start a second concurrent run.
  if (ref.read(libraryUpdateProvider).running) return;
  ref.read(libraryUpdateProvider.notifier).begin();
  bool isDark = ref.read(themeModeStateProvider);
  botToast(
    context.l10n.updating_library("0", "0", "0"),
    fontSize: 13,
    second: 30,
    alignY: !context.isTablet ? 0.85 : 1,
    themeDark: isDark,
  );
  final failures = await _runUpdate(
    ref: ref,
    mangaList: mangaList,
    itemtype: itemtype,
    onProgress: (done, failed, total) {
      if (!context.mounted) return;
      botToast(
        context.l10n.updating_library(done, failed, total),
        fontSize: 13,
        second: 10,
        alignY: !context.isTablet ? 0.85 : 1,
        animationDuration: 0,
        dismissDirections: [DismissDirection.none],
        onlyOne: false,
        themeDark: isDark,
      );
    },
  );
  final failed = failures.length;
  ref.read(libraryUpdateProvider.notifier).end();
  await Future.delayed(const Duration(seconds: 1));
  BotToast.cleanAll();
  // Persist this run's failures (empty list clears any previous ones) so they
  // can be reviewed and migrated away later from the Updates tab's error
  // screen, in addition to the dialog below.
  ref.read(updateErrorsProvider.notifier).set(failures);
  if (context.mounted && failures.isNotEmpty) {
    final plural = failed == 1 ? itemtype : "${itemtype}s";
    // Show the failures in a dismissible dialog rather than a transient toast,
    // so the list can be reviewed at the user's pace and isn't missed when many
    // entries fail. See #623.
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Failed to update $failed $plural"),
        content: SizedBox(
          width: context.width(0.8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.height(0.5)),
            // ListView.builder so rows are built lazily - a large library with
            // many failed updates won't build one widget per entry up front.
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: failures.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text("• ${failures[index].name}"),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }
}

/// The refresh intervals offered in settings, in hours. 0 means never.
const libraryUpdateIntervals = <int>[0, 12, 24, 48, 168];

/// Whether a scheduled refresh is due, given the configured [intervalHours]
/// (0 meaning never), when the last one started, and the current time. All
/// times are epoch milliseconds.
///
/// A library that has never refreshed automatically counts as due, so turning
/// the setting on runs one at the next opportunity rather than a day later.
bool isLibraryUpdateDue({
  required int intervalHours,
  required int? lastRun,
  required int now,
}) {
  if (intervalHours <= 0) return false;
  return now - (lastRun ?? 0) >= intervalHours * Duration.millisecondsPerHour;
}

/// Runs the scheduled library refresh when one is due, then records when it
/// started so the next launch knows to leave it alone.
///
/// This is deliberately quiet: it runs on launch, without anyone watching, so
/// it shows no progress toast and no failure dialog. What it does surface is
/// the same Stop button the manual update uses, and its failures land in the
/// Updates tab's error screen like any other run's.
Future<void> autoUpdateLibraryIfDue(WidgetRef ref) async {
  // Behind the app lock, nothing should be happening yet. Checked before the
  // timestamp below is written, so a launch that stops at the lock screen
  // leaves the refresh due rather than burning the interval on it.
  if (!ref.read(appUnlockedStateProvider)) return;

  final settings = settingsRepository.current;
  if (!isLibraryUpdateDue(
    intervalHours: settings.autoLibraryUpdateInterval ?? 0,
    lastRun: settings.lastAutoLibraryUpdate,
    now: DateTime.now().millisecondsSinceEpoch,
  )) {
    return;
  }

  // Never fight a run the user started themselves. Claimed here, before the
  // first await, so that a launch and a resume arriving together can't both
  // get past this check and start a run each.
  if (ref.read(libraryUpdateProvider).running) return;
  ref.read(libraryUpdateProvider.notifier).begin();

  try {
    if (settings.autoLibraryUpdateWifiOnly ?? true) {
      final connectivity = await Connectivity().checkConnectivity();
      final unmetered =
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);
      if (!unmetered) {
        AppLogger.log("Scheduled library update skipped: metered connection.");
        return;
      }
    }

    // Local archives have no source to refresh from, so they're left out.
    final entries = <Manga>[];
    for (final itemType in ItemType.values) {
      entries.addAll(
        await mangaRepository.getFavoritesNonLocalArchiveByItemType(itemType),
      );
    }
    if (entries.isEmpty) return;

    // Stamped before the run rather than after: a run cut short by the app
    // closing shouldn't make every following launch start over. Nothing above
    // stamps, so a run that never starts stays due.
    await settingsRepository.update(
      (s) => s.lastAutoLibraryUpdate = DateTime.now().millisecondsSinceEpoch,
    );

    AppLogger.log(
      "Starting scheduled library update (${entries.length} entries)...",
    );
    final failures = await _runUpdate(
      ref: ref,
      mangaList: entries,
      itemtype: "Library",
    );
    ref.read(updateErrorsProvider.notifier).set(failures);
    AppLogger.log(
      "Scheduled library update finished, ${failures.length} of "
      "${entries.length} failed.",
    );
  } finally {
    ref.read(libraryUpdateProvider.notifier).end();
  }
}
