# Kế hoạch triển khai nâng cấp YomiHub 0.5.4+46

> **Mục tiêu:** Nâng cấp YomiHub lên 0.5.4 (0.5.4+46), tối ưu hiệu năng, sửa lỗi Isar write transaction, lỗi Resume Video (VOD/Live), phân loại lỗi nguồn vs lỗi ứng dụng, kiểm thử thực tế trên Android / Android TV / Windows và phát hành lên GitHub.

---

## 1. Mục tiêu và Tiêu chí hoàn thành (DoD)
- [ ] Số phiên bản: `0.5.4+46` trong `pubspec.yaml`, `app_identity.dart`, `Runner.rc`, `Package.appxmanifest`.
- [ ] Sửa lỗi Resume Video / Seek: Phân biệt chính xác VOD (seekable) và Live stream (non-seekable); không truyền `start` vào `_player.open` đối với live stream; không gọi `seek()` gây `Cannot seek in this stream`; bọc thao tác lưu mốc phát vào hàng đợi để tránh `IsarError: An async write transaction is already in progress`.
- [ ] Sửa lỗi Resume sau khi thoát hẳn ứng dụng: Timestamp vị trí xem được ghi bền vững vào cơ sở dữ liệu Isar qua `dbWriteQueue.flush()`.
- [ ] Sửa lỗi Null check operator và unmounted widget ref.
- [ ] Phân loại rõ ràng nguồn lỗi trong log: `[Lỗi Nguồn 404]`, `[Lỗi Nguồn 403 / Cloudflare]`, `[Lỗi Mạng / Tor Timeout]`, `[Lỗi Ứng Dụng]`.
- [ ] Bổ sung chẩn đoán và tương thích AMD Ryzen trên Windows trong `win_diag.dart` kèm đường fallback giải mã phần mềm CPU.
- [ ] Đồng bộ toàn bộ thay đổi từ `overlay/` sang `D:\yh\build\mangayomi` và `D:\yh\buildwin\mangayomi`.
- [ ] Vượt qua 100% unit/regression tests (`dart analyze` 0 lỗi, `flutter test` đạt tất cả các bộ test bao gồm `yh_054_test.dart`).
- [ ] Đóng gói bộ cài trong `output/0.5.4`:
  - 3 APK Mobile (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
  - 3 APK TV (`YumiHub Android TV`, bỏ Comic/Novel/Play Books/Booru)
  - 3 gói Windows (`.appxbundle`, `Setup.exe` gói đầy đủ, `portable .zip` và `-full.zip`)
- [ ] Kiểm thử thực tế:
  - Kiểm thử nâng cấp từ 0.5.3 giữ thư viện và sao lưu.
  - Kiểm thử Android TV trên máy ảo AVD `YomiHub_TV_API34`.
  - Kiểm thử Windows: cài đặt Setup.exe, mở bản portable, kiểm tra chẩn đoán CPU.
  - Chụp ảnh màn hình và quay video clip minh chứng quá trình kiểm thử.
- [ ] Cập nhật `TECHNICAL_UPDATE_NOTES.md` và `README.md`.
- [ ] Đẩy commit lên GitHub và tạo Release `v0.5.4`.

---

## 2. Danh sách tệp đã cập nhật trong `overlay/`
1. `overlay/pubspec.yaml`: Nâng phiên bản `0.5.4+46`.
2. `overlay/lib/yomihub/app_identity.dart`: User agent `YomiHub/0.5.4`.
3. `overlay/lib/repositories/db_write_queue.dart`: FIFO queue serialization, `flush()`, loại bỏ `delayed(30ms)` detached, ghi log lỗi.
4. `overlay/lib/repositories/chapter_repository.dart`: Fallback log khi lưu đồng bộ thất bại, tích hợp `dbWriteQueue`.
5. `overlay/lib/modules/anime/providers/anime_player_controller_provider.dart`: Import `dart:async`, xử lý lỗi lưu vị trí tập, `await dbWriteQueue.flush()`.
6. `overlay/lib/modules/anime/anime_player_view.dart`:
   - Bỏ ép `force-seekable=yes` toàn cục trong `PlayerConfiguration.options`.
   - `openStart` chỉ áp dụng cho file local; network stream luôn mở ở `Duration.zero` rồi mới seek sau khi xác minh demuxer.
   - Hàm `querySeekable` không mặc định 'yes' khi lỗi; kiểm tra lại `seekable` sau vòng lặp chờ.
   - Thêm `_mediaSessionId` chặn callback cũ khi đổi tập hoặc dispose.
   - Thông báo botToast và log tiếp tục phát chỉ kích hoạt sau khi đã xác minh vị trí phát thực tế đạt mốc.
   - Tự động hủy cờ `_yhLiveStream` khi nhận duration > 0s (VOD khởi tạo chậm).
   - Gọi `dbWriteQueue.flush()` khi dispose.
7. `overlay/lib/utils/log/logger.dart`: Phân loại lỗi ưu tiên `[Lỗi Ứng Dụng]`, regex từ nguyên cho `\btor\b`, regex status code cho 404/403.
8. `overlay/lib/yomihub/win/win_diag.dart`: Thông tin chính xác về AMD Ryzen và cơ chế fallback giải mã CPU đa luồng.
9. `overlay/test/yh_054_test.dart`: Bộ test hồi quy toàn diện cho tất cả các điểm sửa đổi 0.5.4.

---

## 3. Kế hoạch QA và Kiểm thử chi tiết (Bổ sung theo yêu cầu)

### Ca QA 1: Cài đặt và kiểm thử gói Windows `.appxbundle`
- **Mục tiêu:** Xác minh tính năng đóng gói UWP/MSIX `.appxbundle` hoạt động trơn tru.
- **Quy trình:**
  1. Tạo chứng chỉ tự ký `YomiHub-RootCA.cer` và script cài đặt `Install.ps1`.
  2. Đóng gói `YomiHub-0.5.4-windows-x64.appxbundle`.
  3. Cài đặt thử nghiệm bằng `Add-AppxPackage` qua PowerShell trên Windows 10/11.
  4. Khởi chạy ứng dụng từ Start Menu, kiểm tra WebView2 và tính năng đọc/xem.

### Ca QA 2: Kiểm thử tương thích Android 6.0 (API 23)
- **Mục tiêu:** Xác nhận ứng dụng cài đặt và chạy tốt trên hệ điều hành Android 6.0 cũ (Marshmallow).
- **Môi trường:** Máy ảo Android Emulator `OOS_Android6_API23` (API 23).
- **Quy trình:**
  1. Khởi động AVD `OOS_Android6_API23` qua `emulator.exe`.
  2. Cài đặt APK `app-armeabi-v7a-release.apk` hoặc `app-x86_64-release.apk`.
  3. Kiểm tra cấp quyền lưu trữ ngoài `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`.
  4. Kiểm tra kết nối mạng TLS 1.2 qua Conscrypt / Rust core.
  5. Mở và phát thử video anime, kiểm tra không bị lỗi crash `IsarError` hoặc `MediaCodec`.

### Ca QA 3: Kiểm thử Windows ARM
- **Mục tiêu:** Kiểm tra khả năng tương thích với Windows trên kiến trúc ARM (Snapdragon X Elite / ARM64).
- **Quy trình:**
  1. Kiểm tra cấu hình build và thư viện DLL trong bản portable/setup (đảm bảo kiến trúc x64/x86 có thể chạy thông qua trình dịch mã Prism trên Windows 11 ARM64).
  2. Ghi nhận tình trạng thiết bị: Do môi trường máy chủ hiện tại là Intel Core i5 x64, không có thiết bị Windows ARM vật lý kết nối trực tiếp, ghi rõ trạng thái kiểm thử giả lập/cấu trúc và đánh dấu "chưa kiểm thử thiết bị ARM vật lý do thiếu thiết bị" theo đúng quy định.

### Ca QA 4: Đo khung hình chậm qua `perf_watchdog.dart:98`
- **Mục tiêu:** Giám sát khung hình dựng và vẽ (build & raster timing), đảm bảo không bị giật lag trên giao diện.
- **Phương pháp:**
  - `perf_watchdog.dart:98` đăng ký `SchedulerBinding.instance.addTimingsCallback(_onTimings)`.
  - Ghi nhận raster > 40ms và build + raster > 700ms vào log `[Hiệu năng] Khung hình chậm`.
  - Tự động kích hoạt chế độ giảm hiệu ứng `Liquid Glass` khi GPU quá tải (≥60 khung hình chậm trong 10 giây).

### Ca QA 5: Thử nghiệm VOD khởi tạo chậm và Live stream có mốc cũ
- **Mục tiêu:**
  - VOD khởi tạo chậm: Kiểm tra trường hợp demuxer mất 3-5 giây để tải playlist, duration ban đầu là 0s nhưng sau đó cập nhật > 0s -> không bị đánh dấu nhầm là live stream vĩnh viễn, vẫn tua tới mốc và lưu mốc bình thường.
  - Live stream có mốc cũ: Stream trực tiếp (không cho tua, seekable = no), có mốc phát cũ (ví dụ 45s từ trước) -> không gọi mpv seek gây lỗi `Cannot seek in this stream`, không toast sai thông tin, phát từ đầu luồng live và chỉ ghi nhận thời gian xem thực tế.
