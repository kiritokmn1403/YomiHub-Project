import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/trackers/yomi_tracker_login.dart';
import 'package:mangayomi/yomihub/trackers/mal_export.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:mangayomi/modules/more/settings/track/providers/track_providers.dart';
import 'package:mangayomi/modules/more/settings/track/widgets/track_listile.dart';
import 'package:mangayomi/modules/more/widgets/list_tile_widget.dart';
import 'package:mangayomi/modules/tracker_library/tracker_library_screen.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/trackers/anilist.dart';
import 'package:mangayomi/services/trackers/kitsu.dart';
import 'package:mangayomi/services/trackers/myanimelist.dart';
import 'package:mangayomi/services/trackers/simkl.dart';
import 'package:mangayomi/services/trackers/trakt_tv.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateProgressAfterReading = ref.watch(
      updateProgressAfterReadingStateProvider,
    );
    final l10n = l10nLocalizations(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10nLocalizations(context)!.tracking)),
      // 0.5.3: the last tracker rows stayed under the navigation bar
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom + 16),
        child: StreamBuilder(
          stream: trackRepository.watchAllWithSyncId(),
          builder: (context, snapshot) {
            List<TrackPreference>? entries = snapshot.hasData
                ? snapshot.data
                : [];
            return Column(
              children: [
                SwitchListTile(
                  value: updateProgressAfterReading,
                  title: Text(context.l10n.updateProgressAfterReading),
                  onChanged: (value) {
                    ref
                        .read(updateProgressAfterReadingStateProvider.notifier)
                        .set(value);
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: YomiPrefs.changes,
                  builder: (context, _, __) {
                    final autoJump = YomiPrefs.get('trackerAutoJump', true);
                    return SwitchListTile(
                      value: autoJump,
                      title: Text(tr('Tự động nhảy đến các chương đang đọc')),
                      subtitle: Text(tr('Tự động định vị và chọn chương/tập theo tiến độ đang theo dõi')),
                      onChanged: (value) async {
                        await YomiPrefs.set('trackerAutoJump', value);
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    bottom: 10,
                    top: 5,
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.services,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TrackListile(
                  onTap: () async {
                    await ref
                        .read(
                          anilistProvider(
                            syncId: TrackerProviders.anilist.syncId,
                            widgetRef: ref,
                          ).notifier,
                        )
                        .login();
                  },
                  id: TrackerProviders.anilist.syncId,
                  entries: entries!,
                ),
                TrackListile(
                  onTap: () => _showDialogLogin(context, ref),
                  id: TrackerProviders.kitsu.syncId,
                  entries: entries,
                ),
                TrackListile(
                  onTap: () async {
                    await ref
                        .read(
                          myAnimeListProvider(
                            syncId: TrackerProviders.myAnimeList.syncId,
                            itemType: null,
                            widgetRef: ref,
                          ).notifier,
                        )
                        .login();
                  },
                  id: TrackerProviders.myAnimeList.syncId,
                  entries: entries,
                ),
                TrackListile(
                  onTap: () async {
                    await ref
                        .read(
                          simklProvider(
                            syncId: TrackerProviders.simkl.syncId,
                            itemType: null,
                            widgetRef: ref,
                          ).notifier,
                        )
                        .login();
                  },
                  id: TrackerProviders.simkl.syncId,
                  entries: entries,
                ),
                TrackListile(
                  onTap: () async {
                    await ref
                        .read(
                          traktTvProvider(
                            syncId: TrackerProviders.trakt.syncId,
                            itemType: null,
                            widgetRef: ref,
                          ).notifier,
                        )
                        .login();
                  },
                  id: TrackerProviders.trakt.syncId,
                  entries: entries,
                ),
                ...yomiTrackerTiles(context, ref, entries),
                ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.secondaryColor,
                        ),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    l10n.tracking_warning_info,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.secondaryColor,
                    ),
                  ),
                ),
                ListTileWidget(
                  title: l10n.manage_trackers,
                  icon: Icons.settings,
                  onTap: () => context.push('/manageTrackers'),
                ),
                // 0.5.3 (Tankobun / AnymeX): export the tracked lists in the
                // MyAnimeList XML format (MyAnimeList + AniList via idMal)
                ListTileWidget(
                  title: tr('Xuất danh sách MyAnimeList (XML)'),
                  subtitle: tr('Truyện/phim đang theo dõi trên MyAnimeList và AniList → tệp XML nhập được vào MyAnimeList, AnymeX, Taiga'),
                  icon: Icons.ios_share,
                  onTap: () async {
                    BotToast.showText(text: tr('Đang xuất danh sách…'));
                    try {
                      final r = await YomiMalExport.run();
                      BotToast.showText(
                        text: r.isEmpty
                            ? tr('Không có mục nào đang theo dõi trên MyAnimeList hoặc AniList để xuất')
                            : '${tr('Đã xuất')}: $r',
                        duration: const Duration(seconds: 8),
                      );
                    } catch (e) {
                      BotToast.showText(text: '${tr('Xuất thất bại')}: $e');
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showDialogLogin(BuildContext context, WidgetRef ref) async {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  bool canLogin = false;
  String errorMessage = "";
  bool isLoading = false;
  bool obscureText = true;
  final l10n = l10nLocalizations(context)!;
  void updateCanLogin() {
    canLogin =
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void doLogin() async {
          setState(() {
            isLoading = true;
            errorMessage = "";
          });
          final email = emailController.text.trim();
          final password = passwordController.text;
          final res = await ref
              .read(
                kitsuProvider(
                  syncId: TrackerProviders.kitsu.syncId,
                  widgetRef: ref,
                ).notifier,
              )
              .login(email, password);
          if (!res.$1) {
            setState(() {
              isLoading = false;
              errorMessage = res.$2;
            });
          } else {
            TextInput.finishAutofillContext();
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        }

        return AlertDialog(
          // 0.5.3: the e-mail / password fields were pushed under the
          // keyboard (fixed 300 px content)
          scrollable: true,
          title: Text(
            l10n.login_into("Kitsu"),
            style: const TextStyle(fontSize: 30),
          ),
          content: SizedBox(
            height: 300,
            width: MediaQuery.of(context).size.width,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: emailController,
                      focusNode: emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      autofocus: !isTv,
                      onChanged: (_) => setState(updateCanLogin),
                      onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: l10n.email_adress,
                        filled: false,
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 0.4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      obscureText: obscureText,
                      onChanged: (_) => setState(updateCanLogin),
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (canLogin && !isLoading) doLogin();
                      },
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: l10n.password,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            obscureText = !obscureText;
                          }),
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 0.4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(errorMessage, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                      width: context.width(1),
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (!canLogin || isLoading) ? null : doLogin,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : Text(l10n.login),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  emailController.dispose();
  passwordController.dispose();
  emailFocusNode.dispose();
  passwordFocusNode.dispose();
}
