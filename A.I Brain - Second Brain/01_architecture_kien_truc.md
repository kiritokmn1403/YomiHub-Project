# Kiến trúc dự án YomiHub

## Tổng quan
- **YomiHub** (Android: "YomiHub"; Android TV: "YumiHub Android TV"; Windows: "YomiHub") là ứng dụng Flutter đọc truyện tranh, xem phim/anime, đọc tiểu thuyết, Google Play Sách nhúng và Booru, xây dựng trên nhân **Mangayomi** (kodjodevf/mangayomi).
- Package Android `com.yomihub.app` (activity gốc vẫn là `com.kodjodevf.mangayomi.MainActivity`). Phiên bản: `pubspec.yaml` `x.y.z+N` (0.5.9+52); APK tách ABI có versionCode = 2000 + N (0.5.9 → 2052).
- Nền tảng: Android 7.0+ (APK thường), Android 6.0 (APK `android6` riêng, dựng ở `build23`, minSdk 23), Android TV (cờ `IS_TV_BUILD=true`, bỏ Comic/Novel/Google Play Books/Booru), Windows 10/11 x64. Windows 7/8/x86 không khả thi với Flutter/Isar hiện tại.

## Mã nguồn: nền + overlay
| Lớp | Vị trí | Vai trò |
|---|---|---|
| Nền upstream | `src/mangayomi` (+ `src/mangayomi-0.9.95`, `src/v0.9.7`, `src/BASE_VERSION.txt`) | Mã Mangayomi gốc, chỉ để đối chiếu |
| Thay đổi riêng | `overlay/` (cùng cây với dự án Flutter: `lib/`, `android/`, `windows/`, `assets/`, `test/`, `pubspec.yaml`, `rust_builder/`, `packages/`) | **Nguồn duy nhất được sửa** |
| Bản dựng | `D:\yh\build\mangayomi` (Android/TV), `D:\yh\buildwin\mangayomi` (Windows), `D:\yh\build23\mangayomi` (Android 6) | Nền + overlay đồng bộ bằng `sync_<ver>.ps1` / `Sync-Overlay`; không sửa trực tiếp |

## Các khối chính trong `overlay/lib`
- `main.dart`, `router/`, `providers/`, `models/` (Isar: `Manga`, `Chapter`, `Settings`… – `settings.dart` có `showNSFW=false` mặc định), `repositories/`, `services/` (`http/m_client.dart` – HTTP qua rhttp, proxy VPN, giải Cloudflare), `eval/` (bộ chạy tiện ích: `mihon/` (APK qua JVM bridge/ApkBridge), JavaScript (QuickJS), Dart, Kotatsu, vBook, LNReader, IReader, Aidoku), `modules/` (anime, manga, novel, library, browse, updates, history, more, webview, tracker_library…), `utils/log/logger.dart` (Nhật ký ứng dụng – nhãn `[YH ver (build) • thiết bị, Android x (SDK n)]`), `l10n/`.
- `lib/yomihub/` – toàn bộ tính năng riêng YomiHub: `vpn/` (Tor, WARP, WireGuard, VPN Gate, DoH, fallback cầu nối), `cloudflare/`, `cloudscraper/`, `browser/`, `scanner/` (Web Scanner), `repos/` (kho tiện ích, `repo_discovery.dart` gợi ý kho), `extensions/`, `kotatsu/`, `vbook/`, `ireader/`, `merge/` (Hợp nhất tiện ích), `backup/` + `cloud/` (sao lưu, Google Drive OAuth `google_oauth_config.dart`, OneDrive, Dropbox, Telegram, Rclone), `booru/`, `playbooks/` (Google Play Sách), `player/`, `reader/`, `ebook/`, `library/` (`library_chapter_stats.dart`), `share/` (AirDrop & Quick Share), `health/` (Health Connect), `trackers/`, `update/` (kiểm tra cập nhật nhiều nguồn, `apk_variant_picker.dart`), `splash/`, `ui/` (giao diện Cũ/Mới, Shiori, Liquid Glass), `i18n/`, `perf/`, `a6/` (vá Android 6), `win/` (chẩn đoán Windows), `about/` (`github_projects.dart`), `features/` (bật/tắt nhóm tính năng)…
- Native Android (Kotlin) trong `overlay/android/app/src/main/kotlin/com/kodjodevf/mangayomi/` (`MainActivity.kt`, `YomiVpn.kt`, `YomiTunnels.kt`…); Windows runner trong `overlay/windows/`.
- Bản dịch: `overlay/assets/yomihub_i18n/*.json` – 18 ngôn ngữ (ar, as, de, en, es, es_419, fr, hi, id, it, ja, ko, pt, pt_BR, ru, th, tr, zh), mỗi chuỗi `tr()` mới phải có đủ 18 tệp.
- Lưu trữ: CSDL **Isar** (ghi qua hàng đợi `db_write_queue.dart`), Hive (`yomihub_prefs`, `yomihub_booru`…).

## Hệ sinh thái liên quan
- **Kiritokmn Extension Repo** (`D:\A.I Project\A.I Project - Extension Repo\Kiritokmn - Extension Repo`, GitHub `kiritokmn1403/Kiritokmn---Extension-Repo`): 196 nguồn JS trong `sources/`, dựng `npm run build` → `repo/index.json` + bản mangayomi/vbook/lnreader/yomihub; test `node .build/test/<nguồn>.mjs`. YomiHub chỉ tự thêm kho, tiện ích cập nhật từ kho.
- Trang chủ + chính sách quyền riêng tư: GitHub Pages `docs/` → https://kiritokmn1403.github.io/YomiHub-Project/.
- Google Cloud project `yomihub` (OAuth Desktop + TV/Limited Input, Drive API, "In production").
- Kênh phát hành: GitHub Releases (chính), Google Drive ×3, MediaFire ×3 (phụ – trình kiểm tra cập nhật đọc lần lượt), APKPure (`com.yomihub.app`).
