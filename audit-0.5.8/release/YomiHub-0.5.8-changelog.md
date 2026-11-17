# YomiHub 0.5.8 (0.5.8+51)

> Ngày phát hành: 17/11/2026 · Android 7.0+ (Điện thoại/Máy tính bảng và "YumiHub Android TV") · Android 6.0 (APK riêng) · Windows 10/11 x64

Giữ nền Mangayomi hiện tại; hoàn thiện 11 nhóm tính năng & sửa lỗi cốt lõi (5 nhóm Core-Dev + 6 nhóm UI-Features), kiểm thử thành công trên Samsung Galaxy Note 9 (Android 10) và Windows Desktop.

---

## 1. Sửa lỗi cốt lõi & Tối ưu hiệu năng (Core Fixes & Performance)
1. **Lỗi luồng tải ảnh MangaDex `Cannot add event after closing` (`uploads.mangadex.org`):**
   - Chuyển quyền sở hữu đóng `StreamController` (`chunkEvents`) độc quyền sang `_loadAsync`, không đóng luồng non trong `_loadNetwork` khi gặp lỗi thử lại.
   - Thêm cơ chế tự động thử lại với Referer tên miền gốc (ví dụ: `https://mangadex.org/` cho `uploads.mangadex.org`) và biến thể không Referer khi máy chủ trả về mã HTTP 401, 403, 404 hoặc 500+.
   - Đã kiểm chứng trên Samsung Galaxy Note 9: luồng tải ảnh ổn định, cơ chế rate-limiting chống tràn log hoạt động chuẩn xác (`Tải ảnh từ X vẫn lỗi: thêm N lần trong 1 phút qua`).
2. **Triệt tiêu hiện tượng treo luồng giao diện 2,6s – 2,9s khi cập nhật thư viện:**
   - Bóc tách cấu trúc dữ liệu DTO thuần (`ChapterDiffInput`, `ChapterDiffResult`) và đẩy toàn bộ việc tính toán biểu thức chính quy (RegExp) trong `ChapterRecognition().chapterIdentityKey()` sang luồng nền qua `Isolate.run()`.
   - Giao dịch ghi cơ sở dữ liệu Isar (`writeTransactionAsync`) chỉ thực hiện lưu và cập nhật các danh sách đã tính toán sẵn mà không chiếm giữ luồng UI, giao diện duy trì 60 FPS mượt mà ngay cả khi cập nhật hàng ngàn chương.
3. **Tăng cường khả năng phục hồi nguồn tiện ích (Extension Resilience):**
   - Bổ sung danh sách tên miền gương mặc định cho Anime47 (`anime47.best`, `anime47.tv`, `anime47.net`), AVSub (`animevietsub.best`), FikFap (`fikfap.com`, `fikfap.net`, `fikfap.org`) trong `url_override.dart`.
   - Phân loại lỗi HTTP 404 thành lỗi dữ liệu nguồn với thông báo tiếng Việt trực quan, không ghi stack trace thừa.
   - Google Drive 500: áp dụng backoff lũy thừa cho các lần thử lại và bắt lỗi an toàn ở thư mục gốc (`depth == 0`), không làm ngắt tiến trình kiểm tra cập nhật của các nguồn khác.
   - Shorts Pornhub: phát hiện luồng HLS (.m3u8) bị nhà mạng chặn và định tuyến qua proxy (`needsProxyForHls`), tự động tích hợp qua `YomiVpnState.activeProxy()`.
4. **Hỗ trợ quyền Health Connect trên Android 14+ (API 34+):**
   - Chuyển sang kiểm tra tính năng ghi `MindfulnessSessionRecord` bằng reflection `Class.forName` thay vì phụ thuộc cứng vào `SdkExtensions >= 15`.
   - Khởi chạy Intent `android.health.connect.action.MANAGE_HEALTH_PERMISSIONS` kèm tên gói ứng dụng để xin quyền theo chuẩn Android 14+.
   - Màn hình Health Connect hỗ trợ bấm để yêu cầu cấp quyền trực tiếp.
5. **Tiêu đề khởi tạo nhật ký ứng dụng (AppLogger):**
   - Tự động lấy định danh thiết bị (`deviceDescription()`), phiên bản hệ điều hành và phiên bản ứng dụng (`appVersionDescription()`) đưa vào tiêu đề phiên:
     `===== Logger initialized (phiên mới) • samsung SM-N960N, Android 10 (SDK 29) • YomiHub 0.5.8 (2051) =====`.

---

## 2. Tính năng giao diện & Hệ thống (UI Features & System)
6. **Màn hình khởi động (Splash Screen Animation):**
   - Chuẩn hóa thời lượng khởi động chính xác 5 giây (`Duration(milliseconds: 5000)`).
   - Hiệu ứng chuyển hình thái (morph animation) mượt mà từ hình vuông bo góc sang hình tròn hoàn chỉnh (`r = size / 2 = 66.0px`) từ t=0.05 đến t=0.35 qua `Curves.easeInOutCubic`.
   - Giữ nguyên hình tròn cho đến khi hiệu ứng lỗ tròn thoát màn hình hoàn tất (`t = 0.90..1.00`).
   - Cung cấp hàm public `YomiSplash.morphRadius(double t, [double size = 132.0])` phục vụ kiểm thử và đồng bộ hoạt họa.
7. **Tích hợp giao diện Mangayomi New Version (Shiori Design System) & Công tắc Cũ/Mới:**
   - Tích hợp các thành phần Shiori (`ShioriSectionHeader`, `ShioriCard`, `ShioriShape.card`, `ShioriElevation`) vào màn hình Hợp Nhất Tiện Ích (`ExtensionMergeScreen`) khi kích hoạt chế độ Hiện Đại (`YomiUi.isModern`).
   - Cung cấp công tắc `YomiUiStyleTile` tại mục Cài Đặt giúp người dùng chuyển đổi linh hoạt giữa Giao Diện Cũ (Classic) và Giao Diện Mới (Modern).
8. **Quản lý đa thư mục tải cục bộ trong Tải Xuống (Local Folders in Downloads):**
   - Hỗ trợ quản lý nhiều thư mục cục bộ riêng biệt, ngăn chặn hoàn toàn việc chọn trùng lặp hoặc thư mục cha/con lồng nhau (`YomiLocalFolders.validateNew`).
   - Chuẩn hóa đường dẫn theo từng hệ điều hành (`localFolderPathKey`).
   - Hiển thị dung lượng đĩa thực tế và số lượng đầu truyện/phim của từng thư mục.
9. **Lịch sử tìm kiếm & Cài đặt Booru App trong Sao Lưu & Khôi Phục:**
   - Lưu trữ toàn diện lịch sử tìm kiếm, mục yêu thích, số cột hiển thị, chất lượng ảnh, tự động phát video và danh sách đen trong hộp Hive `yomihub_booru`.
   - Tích hợp hook phản ứng `BooruStore.instance.onRestored()` trong `YomiBackupExtras.restore()`, phát `notifyListeners()` cập nhật giao diện tức thì sau khi khôi phục sao lưu.
   - Bổ sung cơ chế phòng vệ null-safety cho CSDL Isar khi chạy sao lưu/khôi phục.
10. **Hợp nhất cấu hình Gom/Trộn Tiện Ích (Widget Merging Consolidation):**
    - Quy tụ toàn bộ 4 công cụ hợp nhất nguồn: Gộp nguồn tùy chỉnh (`CustomMergeSourcesTile`), Gộp truyện trùng (`MergeDuplicateMangaTile`), Gộp thủ công (`ManualMergeTile`), và Gộp nội dung (`MergedContentTile`) vào màn hình `/mergeExtensions` (`ExtensionMergeScreen`).
    - Giữ 1 lối tắt duy nhất trong mục Cài Đặt › Dữ Liệu & Bộ Nhớ.
11. **Kiểm toán đa ngôn ngữ 18 ngôn ngữ (i18n Audit):**
    - Toàn bộ 18 tệp ngôn ngữ (`assets/yomihub_i18n/*.json`) đạt đối xứng 100% với đúng 1.657 khóa mỗi tệp.
    - Quét toàn bộ 1.474 lệnh gọi tĩnh `tr()` trong `overlay/lib/`, xác nhận 100% đều có mặt trong `en.json` (0 khóa thiếu).

---

## 3. Kết quả kiểm thử & Sức khỏe bản dựng
- **Bộ kiểm thử tự động:** ĐẠT 78/78 tests (7 Core + 15 UI Features + 56 Regression checks), Exit Code 0.
- **Phân tích tĩnh (`dart analyze`):** 0 lỗi, 0 cảnh báo.
- **Samsung Galaxy Note 9 (Android 10):** Cài đặt dev APK 0.5.8 thành công, khởi chạy không lỗi, logcat header và throttled image warnings hoạt động chuẩn xác, ảnh minh chứng tại `audit-0.5.8/evidence/note9_058_launch.png`.
- **Windows Desktop Release:** Biên dịch thành công qua `flutter build windows --no-pub --release`, AOT snapshot `app.so` (42.4 MB) và `YomiHub.exe` (143 KB) sẵn sàng.

---

## 4. Số phiên bản & Định danh phát hành
- **Phiên bản:** `0.5.8`
- **Mã phiên bản cơ sở (versionCode):** `51`
  - `arm64-v8a`: `2051`
  - `armeabi-v7a`: `1051`
  - `x86_64`: `4051`
- **Windows:** ProductVersion `0.5.8+51`, FileVersion `0.5.8+51`, Appx Version `0.5.8.0`.
- **Cài đặt đè:** Giữ nguyên toàn bộ dữ liệu người dùng từ các phiên bản 0.5.6.1 và 0.5.7.
