import 'package:mangayomi/yomihub/speedtest/speedtest_screen.dart';
import 'package:mangayomi/yomihub/wifi/wifi_settings_screen.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper_screen.dart';
import 'package:mangayomi/yomihub/scanner/web_scanner.dart';
import 'package:mangayomi/yomihub/browser/adblock_settings.dart';
import 'package:mangayomi/yomihub/playbooks/playbooks_toggle.dart';
import 'package:mangayomi/yomihub/booru/booru_settings_screen.dart';
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
              title: 'Cloudflare Bypass Setting',
              icon: Icons.shield_outlined,
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
              subtitle: Platform.isAndroid || Platform.isWindows
                  ? tr('Dịch vụ VPN, phạm vi, {p0}, quốc gia, DNS', {'p0': Platform.isWindows ? tr('toàn máy tính') : tr('ứng dụng ngoài')})
                  : tr('DNS-over-HTTPS, nhà cung cấp DNS'),
              icon: Icons.vpn_lock_outlined,
              onTap: () => context.push('/vpn'),
            ),
            // YomiHub 0.2.0: AdBlock in the app Settings
            ListTileWidget(
              title: tr('Chặn quảng cáo (AdBlock)'),
              subtitle: tr('uBlock Origin, AdGuard, EasyList, ABPVN, Tampermonkey; trình duyệt, WebView, trình phát'),
              icon: Icons.shield_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdBlockSettingsScreen()),
              ),
            ),
            // YomiHub 0.2.2: SpeedTest (LibreSpeed)
            ListTileWidget(
              title: 'SpeedTest',
              subtitle: tr('Đo tốc độ mạng: ping, jitter, tải xuống, tải lên (LibreSpeed)'),
              icon: Icons.speed,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SpeedTestScreen()),
              ),
            ),
            ListTileWidget(
              title: tr('Cài Đặt Wifi'),
              subtitle: tr('Xem lại mật khẩu Wi-Fi đã lưu trên máy, cấu hình hồ sơ mạng NetSetMan'),
              icon: Icons.wifi_find_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WifiSettingsScreen()),
              ),
            ),
            ListTileWidget(
              title: 'AirDrop & Quicksharing',
              subtitle: tr('Gửi/nhận tệp với iPhone, Mac, PC, Android qua Wi-Fi, Quick Share'),
              icon: Icons.share_outlined,
              onTap: () => context.push('/airdropQuickshare'),
            ),
            ListTileWidget(
              title: tr('Hình trong hình (PiP)'),
              subtitle: tr('PiP hệ thống (Android 8.0+) hoặc cửa sổ nổi (Android 7.x, máy tính)'),
              icon: Icons.picture_in_picture_alt_outlined,
              onTap: () => context.push('/pipSettings'),
            ),
            ListTileWidget(
              title: 'Web Scanner',
              subtitle: tr('Kiểm tra độ an toàn của trang web: HTTPS, chuyển hướng, quảng cáo, mã độc, đào coin'),
              icon: Icons.travel_explore,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WebScannerScreen()),
              ),
            ),
            ListTileWidget(
              title: tr('Mã QR'),
              subtitle: tr('Quét mã (camera hoặc ảnh) để thêm kho tiện ích, hồ sơ VPN, mở link; tạo mã QR'),
              icon: Icons.qr_code_scanner,
              onTap: () => context.push('/qr'),
            ),
            if (Platform.isAndroid)
              ListTileWidget(
                title: 'microG',
                subtitle: tr('Trạng thái và toàn bộ cài đặt microG (GmsCore, tài khoản, thông báo đẩy…)'),
                icon: Icons.android,
                onTap: () => context.push('/microg'),
              ),
            // YomiHub 0.3.3: Hợp nhất nội dung & Hợp nhất tiện ích
            ListTileWidget(
              title: tr('Hợp nhất nội dung'),
              subtitle: tr('Hợp nhất truyện tranh, tiểu thuyết, phim ảnh (tự động đề xuất, chọn thủ công, hủy hợp nhất)'),
              icon: Icons.auto_stories_rounded,
              onTap: () => context.push('/contentMerge'),
            ),
            ListTileWidget(
              title: tr('Hợp nhất tiện ích'),
              subtitle: tr('Tự chọn các tiện ích để hợp nhất với nhau vào tiện ích đích'),
              icon: Icons.hub_rounded,
              onTap: () => context.push('/mergeExtensions'),
            ),
            // YomiHub 0.3.0: Health Connect & Digital Wellbeing
            ListTileWidget(
              title: tr('Health Connect & Sức khỏe'),
              subtitle: tr('Thời lượng đọc/xem lành mạnh, nhắc bảo vệ mắt (20-20-20), đồng bộ Android Health Connect'),
              icon: Icons.favorite_border_rounded,
              onTap: () => context.push('/healthConnect'),
            ),
            // YomiHub 0.2.0: Google Play Books on/off
            const PlayBooksSettingTile(),
            const BooruSettingTile(),
            ListTileWidget(
              title: tr('Sao lưu đám mây'),
              subtitle: 'Google Drive, OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram',
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
