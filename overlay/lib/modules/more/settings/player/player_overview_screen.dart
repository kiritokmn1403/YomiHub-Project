import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/main_view/providers/tv_mode_provider.dart';
import 'package:mangayomi/modules/more/widgets/list_tile_widget.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/platform_utils.dart';

class PlayerOverviewScreen extends StatelessWidget {
  const PlayerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n!.player)),
      body: SingleChildScrollView(
        padding: tvPageInsets,
        child: Column(
          children: [
            // On TV, choose between the dedicated TV player and the original
            // desktop player. Not shown on phones/desktops.
            if (isTv)
              Consumer(
                builder: (context, ref, _) {
                  final useTvPlayer = ref.watch(tvPlayerStyleProvider);
                  return SwitchListTile(
                    secondary: const Icon(Icons.smart_display_outlined),
                    title: const Text('TV player (beta)'),
                    subtitle: const Text(
                      'On: dedicated TV player.  Off: original (desktop) player.',
                    ),
                    value: useTvPlayer,
                    onChanged: (v) =>
                        ref.read(tvPlayerStyleProvider.notifier).set(v),
                  );
                },
              ),
            // YomiHub 0.1.4: automatic server switching
            ValueListenableBuilder<int>(
              valueListenable: YomiPrefs.changes,
              builder: (context, _, _) => Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.swap_horiz),
                    title: Text(tr('Tự động chuyển server')),
                    subtitle: Text(
                      tr('Khi server đang phát bị lỗi hoặc tải quá lâu, tự chuyển sang server/chất lượng kế tiếp của tập (mọi tiện ích Film & Movie)'),
                    ),
                    value: YomiPrefs.autoServerSwitch,
                    onChanged: (v) => YomiPrefs.autoServerSwitch = v,
                  ),
                  if (YomiPrefs.autoServerSwitch)
                    ListTile(
                      title: Text(
                        tr('Chuyển khi tải quá {p0} giây', {'p0': YomiPrefs.serverStallSeconds}),
                      ),
                      subtitle: Slider(
                        value: YomiPrefs.serverStallSeconds.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '${YomiPrefs.serverStallSeconds}s',
                        onChanged: (v) =>
                            YomiPrefs.serverStallSeconds = v.round(),
                      ),
                    ),
                  SwitchListTile(
                    secondary: const Icon(Icons.block),
                    title: Text(tr('Chặn quảng cáo mạng trong trình phát web')),
                    subtitle: Text(
                      tr('Tắt (mặc định): chỉ ẩn quảng cáo và chặn pop-up, để trang không phát hiện trình chặn quảng cáo'),
                    ),
                    value: YomiPrefs.get<bool>('webPlayerNetBlock', false),
                    onChanged: (v) => YomiPrefs.set('webPlayerNetBlock', v),
                  ),
                ],
              ),
            ),
            ListTileWidget(
              title: l10n.internal_player,
              subtitle: l10n.internal_player_info,
              icon: Icons.play_circle_outline_outlined,
              onTap: () => context.push('/playerMode'),
            ),
            ListTileWidget(
              title: l10n.decoder,
              subtitle: l10n.decoder_info,
              icon: Icons.memory_outlined,
              onTap: () => context.push('/playerDecoderScreen'),
            ),
            ListTileWidget(
              title: l10n.video_audio,
              subtitle: l10n.video_audio_info,
              icon: Icons.audiotrack_outlined,
              onTap: () => context.push('/playerAudioScreen'),
            ),
            ListTileWidget(
              title: l10n.custom_buttons,
              subtitle: l10n.custom_buttons_info,
              icon: Icons.terminal_outlined,
              onTap: () => context.push('/customButtonScreen'),
            ),
            ListTileWidget(
              title: l10n.advanced,
              subtitle: l10n.advanced_info,
              icon: Icons.code_outlined,
              onTap: () => context.push('/playerAdvancedScreen'),
            ),
          ],
        ),
      ),
    );
  }
}
