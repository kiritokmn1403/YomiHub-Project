import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/services/library_updater.dart'
edit(F,"""Future<List<UpdateError>> _runUpdate({
  required WidgetRef ref,""","""// 0.5.2: takes a plain provider reader instead of a WidgetRef. A library
// update runs for minutes; the pull-to-refresh caller's WidgetRef died when
// the user left the Library tab ("Using \\"ref\\" when a widget is about to or
// has been unmounted is unsafe", logs 2 04/11 09:50:39) and the whole run was
// aborted. Callers pass `ProviderContainer.read` (or a long-lived ref's read).
typedef YhProviderRead = T Function<T>(ProviderListenable<T> provider);

Future<List<UpdateError>> _runUpdate({
  required YhProviderRead read,""")
edit(F,"    if (ref.read(libraryUpdateProvider).cancelRequested) break;","    if (read(libraryUpdateProvider).cancelRequested) break;")
edit(F,"""      await ref.read(
        updateMangaDetailProvider(""","""      await read(
        updateMangaDetailProvider(""")
edit(F,"""  // Don't start a second concurrent run.
  if (ref.read(libraryUpdateProvider).running) return;
  ref.read(libraryUpdateProvider.notifier).begin();
  bool isDark = ref.read(themeModeStateProvider);""","""  // 0.5.2: everything after the first await goes through the app-wide
  // container, which outlives the Library screen that started the run.
  final container = ProviderScope.containerOf(context, listen: false);
  // Don't start a second concurrent run.
  if (container.read(libraryUpdateProvider).running) return;
  container.read(libraryUpdateProvider.notifier).begin();
  bool isDark = container.read(themeModeStateProvider);""")
edit(F,"""  final failures = await _runUpdate(
    ref: ref,
    mangaList: mangaList,
    itemtype: itemtype,
    onProgress:""","""  final List<UpdateError> failures;
  try {
  failures = await _runUpdate(
    read: container.read,
    mangaList: mangaList,
    itemtype: itemtype,
    onProgress:""")
edit(F,"""  );
  final failed = failures.length;
  ref.read(libraryUpdateProvider.notifier).end();""","""  );
  } catch (e) {
    container.read(libraryUpdateProvider.notifier).end();
    AppLogger.log('[Cập nhật thư viện] Dừng giữa chừng: ${_shortError(e)}',
        logLevel: LogLevel.error);
    BotToast.cleanAll();
    return;
  }
  final failed = failures.length;
  container.read(libraryUpdateProvider.notifier).end();""")
edit(F,"  ref.read(updateErrorsProvider.notifier).set(failures);\n  if (context.mounted","  container.read(updateErrorsProvider.notifier).set(failures);\n  if (context.mounted")
edit(F,"""    final failures = await _runUpdate(
      ref: ref,
      mangaList: entries,""","""    final failures = await _runUpdate(
      read: ref.read,
      mangaList: entries,""")
