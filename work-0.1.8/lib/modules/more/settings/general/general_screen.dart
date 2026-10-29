import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper_screen.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/modules/more/settings/general/providers/memory_probe_provider.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/providers/algorithm_weights_state_provider.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/modules/more/settings/general/providers/general_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/modules/more/settings/general/providers/doh_provider_notifier.dart';
import 'package:mangayomi/services/library_updater.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/modules/widgets/tv_escapable_slider.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/modules/onboarding/providers/onboarding_state_provider.dart';

class GeneralScreen extends ConsumerStatefulWidget {
  const GeneralScreen({super.key});

  @override
  ConsumerState<GeneralScreen> createState() => _GeneralStateScreen();
}

class _GeneralStateScreen extends ConsumerState<GeneralScreen> {
  int _genre = 0;
  int _setting = 0;
  int _synopsis = 0;
  int _theme = 0;

  @override
  void initState() {
    super.initState();
    final algorithmWeights = ref.read(algorithmWeightsStateProvider);
    _genre = algorithmWeights.genre!;
    _setting = algorithmWeights.setting!;
    _synopsis = algorithmWeights.synopsis!;
    _theme = algorithmWeights.theme!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context);
    final userAgent = ref.watch(userAgentStateProvider);
    final enableDiscordRpc = ref.watch(enableDiscordRpcStateProvider);
    final hideDiscordRpcInIncognito = ref.watch(
      hideDiscordRpcInIncognitoStateProvider,
    );
    final rpcShowReadingWatchingProgress = ref.watch(
      rpcShowReadingWatchingProgressStateProvider,
    );
    final rpcShowTitleState = ref.watch(rpcShowTitleStateProvider);
    final rpcShowCoverImage = ref.watch(rpcShowCoverImageStateProvider);
    final showNavDoubleTapTooltip = ref.watch(
      showNavDoubleTapTooltipStateProvider,
    );
    final autoUpdateInterval = ref.watch(
      autoLibraryUpdateIntervalStateProvider,
    );
    final autoUpdateWifiOnly = ref.watch(
      autoLibraryUpdateWifiOnlyStateProvider,
    );
    final doHState = ref.watch(doHProviderStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n!.general)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              onTap: () => _showAutoLibraryUpdateDialog(
                context,
                ref,
                autoUpdateInterval,
              ),
              title: Text(l10n.auto_library_update),
              subtitle: Text(
                // When it's off, say what the setting does; the word "Never"
                // on its own doesn't explain what would otherwise happen.
                autoUpdateInterval == 0
                    ? l10n.auto_library_update_subtitle
                    : _autoLibraryUpdateLabel(context, autoUpdateInterval),
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            if (autoUpdateInterval > 0)
              SwitchListTile(
                value: autoUpdateWifiOnly,
                title: Text(l10n.auto_library_update_wifi_only),
                subtitle: Text(
                  l10n.auto_library_update_wifi_only_subtitle,
                  style: TextStyle(fontSize: 11, color: context.secondaryColor),
                ),
                onChanged: (value) => ref
                    .read(autoLibraryUpdateWifiOnlyStateProvider.notifier)
                    .set(value),
              ),
            // YomiHub 0.1.5: DoH + DNS provider moved to "VPN & DNS › DNS".
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(l10n.dns_over_https),
              subtitle: Text(
                '${doHState.enabled ? 'Đang bật' : 'Đang tắt'} · đã chuyển sang VPN & DNS › DNS',
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/vpnDns', extra: 'dns'),
            ),
            ListTile(
              onTap: () => _showDefaultUserAgentDialog(context, ref, userAgent),
              title: Text(context.l10n.default_user_agent),
              subtitle: Text(
                userAgent,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            // A way back to the first-run screen. It is the only way to see it
            // once it has been dismissed, and on a debug build, where a fresh
            // install skips it, the only way to see it at all.
            ListTile(
              onTap: () => ref
                  .read(onboardingCompletedStateProvider.notifier)
                  .showAgain(),
              title: Text(context.l10n.onboarding_replay),
              subtitle: Text(
                context.l10n.onboarding_replay_subtitle,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            // YomiHub 0.1.6: moved into Settings › Cloudflare Bypass Setting.
            ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CloudScraperScreen()),
              ),
              title: const Text('Cloudflare Bypass Setting'),
              subtitle: Text(
                'Đã gộp proxy vượt Cloudflare và CloudScraper',
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(width: 3.0, color: context.primaryColor),
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        context.l10n.recommendations_weights,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      OutlinedButton.icon(
                        onPressed: () {
                          final defaultWeights = AlgorithmWeights();
                          setState(() {
                            _genre = defaultWeights.genre!;
                            _setting = defaultWeights.setting!;
                            _synopsis = defaultWeights.synopsis!;
                            _theme = defaultWeights.theme!;
                          });
                          ref
                              .read(algorithmWeightsStateProvider.notifier)
                              .set(defaultWeights);
                        },
                        label: Text(context.l10n.reset),
                        icon: const Icon(Icons.restore),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.recommendations_weights_genre),
                        Text(
                          (_genre / 100).toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TvEscapableSlider(
                          enabled: isTv,
                          onDecrease: () {
                            setState(() => _genre = (_genre - 1).clamp(0, 100));
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(genre: _genre);
                          },
                          onIncrease: () {
                            setState(() => _genre = (_genre + 1).clamp(0, 100));
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(genre: _genre);
                          },
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 5.0,
                              ),
                            ),
                            child: Slider.adaptive(
                              min: 0,
                              max: 100,
                              value: _genre.toDouble(),
                              onChanged: (value) {
                                HapticFeedback.vibrate();
                                setState(() {
                                  _genre = value.toInt();
                                });
                              },
                              onChangeEnd: (value) => ref
                                  .read(algorithmWeightsStateProvider.notifier)
                                  .setWeights(genre: _genre),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.recommendations_weights_setting),
                        Text(
                          (_setting / 100).toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TvEscapableSlider(
                          enabled: isTv,
                          onDecrease: () {
                            setState(
                              () => _setting = (_setting - 1).clamp(0, 100),
                            );
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(setting: _setting);
                          },
                          onIncrease: () {
                            setState(
                              () => _setting = (_setting + 1).clamp(0, 100),
                            );
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(setting: _setting);
                          },
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 5.0,
                              ),
                            ),
                            child: Slider.adaptive(
                              min: 0,
                              max: 100,
                              value: _setting.toDouble(),
                              onChanged: (value) {
                                HapticFeedback.vibrate();
                                setState(() {
                                  _setting = value.toInt();
                                });
                              },
                              onChangeEnd: (value) => ref
                                  .read(algorithmWeightsStateProvider.notifier)
                                  .setWeights(setting: _setting),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.recommendations_weights_synopsis),
                        Text(
                          (_synopsis / 100).toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TvEscapableSlider(
                          enabled: isTv,
                          onDecrease: () {
                            setState(
                              () => _synopsis = (_synopsis - 1).clamp(0, 100),
                            );
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(synopsis: _synopsis);
                          },
                          onIncrease: () {
                            setState(
                              () => _synopsis = (_synopsis + 1).clamp(0, 100),
                            );
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(synopsis: _synopsis);
                          },
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 5.0,
                              ),
                            ),
                            child: Slider.adaptive(
                              min: 0,
                              max: 100,
                              value: _synopsis.toDouble(),
                              onChanged: (value) {
                                HapticFeedback.vibrate();
                                setState(() {
                                  _synopsis = value.toInt();
                                });
                              },
                              onChangeEnd: (value) => ref
                                  .read(algorithmWeightsStateProvider.notifier)
                                  .setWeights(synopsis: _synopsis),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.recommendations_weights_theme),
                        Text(
                          (_theme / 100).toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TvEscapableSlider(
                          enabled: isTv,
                          onDecrease: () {
                            setState(() => _theme = (_theme - 1).clamp(0, 100));
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(theme: _theme);
                          },
                          onIncrease: () {
                            setState(() => _theme = (_theme + 1).clamp(0, 100));
                            ref
                                .read(algorithmWeightsStateProvider.notifier)
                                .setWeights(theme: _theme);
                          },
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 5.0,
                              ),
                            ),
                            child: Slider.adaptive(
                              min: 0,
                              max: 100,
                              value: _theme.toDouble(),
                              onChanged: (value) {
                                HapticFeedback.vibrate();
                                setState(() {
                                  _theme = value.toInt();
                                });
                              },
                              onChangeEnd: (value) => ref
                                  .read(algorithmWeightsStateProvider.notifier)
                                  .setWeights(theme: _theme),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              value: ref.watch(memoryOverlayVisibleProvider),
              title: Text(l10n.memory_overlay),
              subtitle: Text(l10n.memory_overlay_subtitle),
              onChanged: (value) =>
                  ref.read(memoryOverlayVisibleProvider.notifier).set(value),
            ),
            SwitchListTile(
              value: showNavDoubleTapTooltip,
              title: Text(l10n.show_nav_double_tap_tooltip),
              subtitle: Text(l10n.show_nav_double_tap_tooltip_subtitle),
              onChanged: (value) => ref
                  .read(showNavDoubleTapTooltipStateProvider.notifier)
                  .set(value),
            ),
            SwitchListTile(
              value: enableDiscordRpc,
              title: Text(l10n.enable_discord_rpc),
              onChanged: (value) {
                ref.read(enableDiscordRpcStateProvider.notifier).set(value);
                if (value) {
                  discordRpc?.connect(ref);
                } else {
                  discordRpc?.disconnect();
                }
              },
            ),
            SwitchListTile(
              value: hideDiscordRpcInIncognito,
              title: Text(l10n.hide_discord_rpc_incognito),
              onChanged: (value) {
                ref
                    .read(hideDiscordRpcInIncognitoStateProvider.notifier)
                    .set(value);
              },
            ),
            SwitchListTile(
              value: rpcShowReadingWatchingProgress,
              title: Text(l10n.rpc_show_reading_watching_progress),
              onChanged: (value) {
                ref
                    .read(rpcShowReadingWatchingProgressStateProvider.notifier)
                    .set(value);
              },
            ),
            SwitchListTile(
              value: rpcShowTitleState,
              title: Text(l10n.rpc_show_title),
              onChanged: (value) {
                ref.read(rpcShowTitleStateProvider.notifier).set(value);
              },
            ),
            SwitchListTile(
              value: rpcShowCoverImage,
              title: Text(l10n.rpc_show_cover_image),
              onChanged: (value) {
                ref.read(rpcShowCoverImageStateProvider.notifier).set(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// The label for one of [libraryUpdateIntervals], in hours.
  String _autoLibraryUpdateLabel(BuildContext context, int hours) {
    final l10n = context.l10n;
    return switch (hours) {
      12 => l10n.auto_library_update_12_hours,
      24 => l10n.auto_library_update_daily,
      48 => l10n.auto_library_update_2_days,
      168 => l10n.auto_library_update_weekly,
      _ => l10n.auto_library_update_never,
    };
  }

  void _showAutoLibraryUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.auto_library_update),
        content: SizedBox(
          width: context.width(0.8),
          child: RadioGroup(
            groupValue: current,
            onChanged: (value) {
              Navigator.pop(context);
              if (value == null) return;
              ref
                  .read(autoLibraryUpdateIntervalStateProvider.notifier)
                  .set(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final hours in libraryUpdateIntervals)
                  RadioListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: hours,
                    title: Text(_autoLibraryUpdateLabel(context, hours)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }

}

void _showDefaultUserAgentDialog(
  BuildContext context,
  WidgetRef ref,
  String ua,
) {
  final uaController = TextEditingController(text: ua);
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            context.l10n.default_user_agent,
            style: const TextStyle(fontSize: 30),
          ),
          content: SizedBox(
            width: context.width(0.8),
            height: context.height(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    controller: uaController,
                    autofocus: true,

                    decoration: InputDecoration(
                      hintText: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    width: context.width(1),
                    child: ElevatedButton(
                      onPressed: () async {
                        ref
                            .watch(userAgentStateProvider.notifier)
                            .set(uaController.text);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.dialog_confirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
