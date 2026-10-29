import 'dart:io';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/main_view/providers/tv_mode_provider.dart';
import 'package:mangayomi/modules/more/widgets/list_tile_widget.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/platform_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n!.settings)),
      body: LiquidGlassBackdrop(child: SingleChildScrollView(
        padding: tvPageInsets,
        child: Column(
          children: [
            ListTileWidget(
              autofocus: isTv,
              title: l10n.general,
              icon: Icons.settings,
              onTap: () => context.push('/general'),
            ),
            ListTileWidget(
              title: l10n.appearance,
              icon: Icons.color_lens_rounded,
              onTap: () => context.push('/appearance'),
            ),
            // Reader is manga/novel-only — hide it on the anime-only layout.
            Consumer(
              builder: (context, ref, _) {
                if (ref.watch(animeOnlyTvModeProvider)) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    ListTileWidget(
                      title: l10n.reader,
                      icon: Icons.chrome_reader_mode_rounded,
                      onTap: () => context.push('/readerMode'),
                    ),
                    ListTileWidget(
                      title: '${l10n.novel} ${l10n.reader}',
                      icon: Icons.menu_book_rounded,
                      onTap: () => context.push('/novelReaderMode'),
                    ),
                  ],
                );
              },
            ),
            ListTileWidget(
              title: l10n.player,
              icon: Icons.play_circle_outline_outlined,
              onTap: () => context.push('/playerOverview'),
            ),
            ListTileWidget(
              title: l10n.downloads,
              icon: Icons.download_outlined,
              onTap: () => context.push('/downloads'),
            ),
            ListTileWidget(
              title: 'CloudScraper',
              icon: Icons.cloud_sync,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CloudScraperScreen()),
              ),
            ),
            ListTileWidget(
              title: l10n.tracking,
              icon: Icons.sync_outlined,
              onTap: () => context.push('/track'),
            ),
            ListTileWidget(
              title: l10n.syncing,
              icon: Icons.cloud_sync_outlined,
              onTap: () => context.push('/sync'),
            ),
            ListTileWidget(
              title: l10n.browse,
              icon: Icons.explore_rounded,
              onTap: () => context.push('/browseS'),
            ),
            // YomiHub
            ListTileWidget(
              title: 'VPN & DNS',
              subtitle: Platform.isAndroid
                  ? 'Dịch vụ VPN, phạm vi, ứng dụng ngoài, quốc gia, DNS'
                  : 'DNS-over-HTTPS, nhà cung cấp DNS',
              icon: Icons.vpn_lock_outlined,
              onTap: () => context.push('/vpn'),
            ),
            ListTileWidget(
              title: 'AirDrop & Quicksharing',
              subtitle: 'Gửi/nhận tệp với iPhone, Mac, PC, Android qua Wi-Fi, Quick Share',
              icon: Icons.share_outlined,
              onTap: () => context.push('/airdropQuickshare'),
            ),
            ListTileWidget(
              title: 'Hình trong hình (PiP)',
              subtitle: 'PiP hệ thống (Android 8.0+) hoặc cửa sổ nổi (Android 7.x, máy tính)',
              icon: Icons.picture_in_picture_alt_outlined,
              onTap: () => context.push('/pipSettings'),
            ),
            ListTileWidget(
              title: 'Mã QR',
              subtitle: 'Quét mã (camera hoặc ảnh) để thêm kho tiện ích, hồ sơ VPN, mở link; tạo mã QR',
              icon: Icons.qr_code_scanner,
              onTap: () => context.push('/qr'),
            ),
            if (Platform.isAndroid)
              ListTileWidget(
                title: 'microG',
                subtitle: 'Trạng thái và toàn bộ cài đặt microG (GmsCore, tài khoản, thông báo đẩy…)',
                icon: Icons.android,
                onTap: () => context.push('/microg'),
              ),
            ListTileWidget(
              title: 'Sao lưu đám mây',
              subtitle: 'Google Drive, OneDrive, Dropbox, WebDAV, Telegram',
              icon: Icons.cloud_upload_outlined,
              onTap: () => context.push('/cloudBackup'),
            ),
            if (!Platform.isLinux)
              ListTileWidget(
                title: l10n.security,
                icon: Icons.security_rounded,
                onTap: () => context.push('/security'),
              ),
            ListTileWidget(
              title: l10n.about,
              icon: Icons.info_outline,
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      )),
    );
  }
}
