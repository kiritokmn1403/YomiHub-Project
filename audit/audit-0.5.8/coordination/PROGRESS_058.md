# YomiHub 0.5.8 — TIẾN ĐỘ & THEO DÕI KIỂM THỬ (17/11/2026)

## Thiết bị & Môi trường kiểm thử
- **Samsung Galaxy Note 9**: model `SM_N960N` (crownlteks), Android 10 (API 29), adb ID `281038ac31217ece`, Pin: 100%, Bộ nhớ trống: 15GB.
- **Windows Desktop**: Windows 11 x64, Flutter stable, MSVC C++ toolchain.
- **Hạ tầng runner**: `jobs/pending_fast/` và `jobs/pending/` đang hoạt động tốt.
- **Thư viện runner 0.5.8**: `jobs/q058_lib.ps1` (hỗ trợ `Sync-Overlay`, `Run-Tests`, `Run-Analyze`).

## Tiến độ xác minh YomiHub 0.5.8

### 1. Nhiệm vụ @core-dev (5 Domains) — ĐÃ XÁC MINH ĐẠT 100%
- [x] 1.1 Sửa lỗi stream ảnh `Cannot add event after closing` & HTTP 403/404/Referer retry (`custom_extended_image_provider.dart`): StreamController close chuyển độc quyền sang `_loadAsync`, kiểm tra `!chunkEvents.isClosed`, thêm root domain referer fallback (e.g. `uploads.mangadex.org` -> `mangadex.org/`).
- [x] 1.2 Giải quyết hiện tượng treo UI (2.6s - 2.9s) khi cập nhật thư viện: Offload ChapterRecognition Identity matching và diffing sang Isolate chạy ngầm qua `computeChapterDiffInIsolate` trong `update_manga_detail_providers.dart`.
- [x] 1.3 Khắc phục phục hồi tiện ích: Cung cấp mirrors mặc định cho Anime47, AVSub, FikFap trong `url_override.dart`; phân loại HTTP 404 trong `ext_errors.dart`; lũy thừa lùi trong `drive_update.dart`; proxy cho luồng HLS bị chặn trong `player_net.dart` và `chunk_proxy.dart`.
- [x] 1.4 Xử lý quyền Health Connect: Dùng reflection kiểm tra `MindfulnessSessionRecord` và action `MANAGE_HEALTH_PERMISSIONS` trong `YomiHealth.kt` & `health_connect_screen.dart`.
- [x] 1.5 Header nhật ký ứng dụng: Thêm thông tin thiết bị (`deviceDescription()`) và phiên bản ứng dụng (`appVersionDescription()`) vào header khởi tạo trong `logger.dart`.
- **Kết quả Unit Test**: `yh_058_core_test.dart` đạt 7/7 tests (100%).
- **Phân tích mã (`dart analyze`)**: Đã phát hiện 3 cảnh báo (`unawaited_return_in_try_block`, `dead_code`), @core-dev đã sửa triệt để; re-analyze đạt 0 lỗi, 0 cảnh báo.

### 2. Nhiệm vụ @ui-features (6 Domains) — ĐÃ XÁC MINH ĐẠT 100%
- [x] 2.1 Hiệu ứng splash loading 5 giây: Duration 5000ms, morph bán kính mượt mà từ vuông (r=0) sang tròn (r=size/2=66) từ t=0.05 đến 0.35 (`Curves.easeInOutCubic`), hàm `YomiSplash.morphRadius`.
- [x] 2.2 Mangayomi New Version theme toggle: Tích hợp Shiori Design System (`ShioriSectionHeader`, `ShioriCard`, `ShioriShape.card`, `ShioriBadge`) thích ứng khi `YomiUi.isModern`, công tắc `YomiUiStyleTile` (Cũ/Mới).
- [x] 2.3 Thư mục tải cục bộ riêng biệt: Xác thực chống trùng lặp và chống lồng nhau trong `local_folders.dart` (`YomiLocalFolders.validateNew`), chuẩn hóa đường dẫn đa hệ điều hành (`localFolderPathKey`).
- [x] 2.4 Booru search history & settings trong Backup/Restore: Lưu trữ đầy đủ trong Hive box `yomihub_booru`, tích hợp hook `BooruStore.instance.onRestored()` trong `YomiBackupExtras.restore()`.
- [x] 2.5 Hợp nhất cấu hình Widget Merging: Gom toàn bộ merge tools vào `ExtensionMergeScreen` (`/mergeExtensions`), giữ 1 lối tắt duy nhất trong Data & Storage.
- [x] 2.6 Đồng bộ i18n trên 18 ngôn ngữ: Đối xứng 100% với đúng 1,657 khóa mỗi tệp json; 1,474 lệnh `tr()` tĩnh đều có trong `en.json`.
- **Kết quả Unit Test**: `yh_058_ui_features_test.dart` đạt 15/15 tests (100%).
- **Phân tích mã (`dart analyze`)**: 0 lỗi, 0 cảnh báo.

### 3. Kiểm thử hồi quy (Regression Test Suite) — ĐÃ ĐẠT 100%
- Chạy qua job `z058_v05_regression.ps1` trên các bộ test:
  - `yh_049_test.dart`: Đạt 56/56 checks (i18n và chuỗi dịch).
  - `yh_057_s1_logs_test.dart`, `yh_057_qa3_test.dart`, `yh_057_p1_test.dart`, `yh_057_p6_test.dart`: Đạt toàn bộ.
- Tổng số test tự động mới + hồi quy: **78/78 tests ĐẠT** (0 trượt).

### 4. Kiểm thử thiết bị Samsung Galaxy Note 9 (SM-N960N, Android 10) — ĐÃ ĐẠT 100%
- [x] Kết nối thiết bị qua adb: Đạt (`281038ac31217ece`, battery 100%, storage 15GB).
- [x] Dựng dev APK `YomiHub-0.5.8-dev-arm64-v8a.apk`: Đạt (dung lượng 168.9 MB, 177,159,850 bytes, BUILD APK EXIT 0).
- [x] Cài đặt APK lên máy thật Note 9: Đạt (`adb install -r -d`, versionName=0.5.8, versionCode=2051).
- [x] Khởi chạy app và kiểm tra tính ổn định: Đạt (chạy thành công qua monkey, không gặp sự cố, IsarCore, media_kit, TTS và LocalLibraryScanner khởi tạo mượt mà).
- [x] Kiểm tra session log header trên máy thật: Đạt (`/sdcard/YomiHub/logs.txt` ghi nhận chính xác: `[17/11/2026 14:16:05][INFO] ===== Logger initialized (phiên mới) • samsung SM-N960N, Android 10 (SDK 29) • YomiHub 0.5.8 (2051) =====`).
- [x] Kiểm tra rate-limiting cảnh báo ảnh: Đạt (`[17/11/2026 14:17:10][WARNING] Tải ảnh từ i.hinhgg.com vẫn lỗi: thêm 3 lần trong 1 phút qua`).
- [x] Chụp ảnh màn hình Note 9 minh chứng: Đạt (`audit-0.5.8/evidence/note9_058_launch.png`, dung lượng 2,050,451 bytes).

### 5. Kiểm thử sức khỏe bản dựng Windows Desktop — ĐÃ ĐẠT 100%
- [x] Đồng bộ overlay mới sang thư mục build Windows (`D:\yh\buildwin\mangayomi`).
- [x] Phân tích tĩnh (`dart analyze`): Đạt 0 lỗi, 0 cảnh báo.
- [x] Tạo mới ephemeral symlinks và nạp nuget vào PATH: Đạt (`flutter pub get --offline` EXIT 0).
- [x] Biên dịch Windows Desktop Release (`flutter build windows --no-pub --release` qua `z058_win_build3.ps1`): Đạt (EXIT 0).
- [x] CppWinRT 2.0.210806 / 2.0.220418 sinh projection headers thành công (`317 winrt headers`).
- [x] `gen_snapshot.exe` biên dịch release kernel AOT `app.so` thành công (`42.4 MB`, `42,369,928 bytes`, thời gian tạo 14:56:52).
- [x] MSVC `cl.exe` và `link.exe` liên kết thành công `YomiHub.exe` tại `D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe`.
- [x] Tập tin tài nguyên `flutter_assets` đóng gói hoàn tất (14:58:23).

## Tổng kết đánh giá Verifier cho YomiHub 0.5.8
- Toàn bộ 11 domains (5 Core-Dev + 6 UI-Features) đã hoàn thiện và kiểm thử thành công 100%.
- Bộ kiểm thử tự động: **78/78 tests ĐẠT** (0 lỗi).
- Kiểm toán mã nguồn `dart analyze`: **0 lỗi, 0 cảnh báo**.
- Thiết bị thật Samsung Galaxy Note 9 (Android 10): Đã cài đặt dev APK 0.5.8, chạy ổn định, session log header ghi nhận chuẩn xác, ảnh minh chứng đã lưu.
- Bản dựng Windows Desktop Release: Biên dịch hoàn tất thành công (EXIT 0), AOT snapshot `app.so` (42.4 MB) và `YomiHub.exe` đã sẵn sàng.
- Trạng thái bàn giao: **ĐẠT TOÀN DIỆN (READY FOR RELEASE / COORDINATOR REVIEW)**.

### 6. Đóng gói phát hành tự động hóa (Release Packaging Pipeline) — ĐÃ ĐẠT 100%
- [x] Soạn thảo bộ kịch bản phát hành v0.5.8: `sync_058.ps1`, `build_058_android.ps1`, `build_058.ps1`, `build_058_android6.ps1`, `make_installer_exe_058.ps1`, `make_appxbundle_058.ps1`, `verify_release_058.ps1`, `run_058_main.ps1`.
- [x] Thực thi trọn vẹn 10 bước của pipeline phát hành qua `run_058_main.ps1` (EXIT 0):
  1. `sync`: EXIT 0 (36 files synced).
  2. `test`: EXIT 0 (899/899 tests PASSED).
  3. `apk`: EXIT 0 (3 APKs chuẩn arm64, armeabi-v7a, x86_64).
  4. `tv`: EXIT 0 (3 APKs Android TV Leanback arm64, armeabi-v7a, x86_64).
  5. `wintest`: EXIT 0 (40/40 tests Windows PASSED).
  6. `win`: EXIT 0 (YomiHub.exe, portable zip 119.5 MB, full zip với MES JRE 247.4 MB).
  7. `pack`: EXIT 0 (Setup.exe CSC 119.6 MB, AppxBundle 251.8 MB, RootCA .cer, install scripts).
  8. `a6build`: EXIT 0 (3 APKs Android 6.0 API 23 biên dịch, desugar, R8 tối ưu, ký số hợp lệ).
  9. `a6copy`: EXIT 0 (Sao chép 3 APKs A6 vào output/0.5.8/).
  10. `verify`: EXIT 0 (Kiểm tra 17 artifacts, PE/Appx headers, tạo SHA256SUMS-0.5.8.txt).
- [x] Bàn giao đầy đủ 18 tệp tại `output/0.5.8/` (17 artifacts + SHA256SUMS-0.5.8.txt).
