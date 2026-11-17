
#### G. Tiếp tục sau khi khởi động lại (28/10/2026 14:40–16:40)

- Dựng lại: APK mobile 3 ABI (15:09; kiểm: `libflutter.so` gốc, không có `libyhcompat`, `avsub.js` dùng `animevietsub.sale`); APK TV 3 ABI (16:26, gồm 2 sửa TV bên dưới); đóng gói lại `Setup.exe`, `.appxbundle` (270,5 MB), `SHA256SUMS-0.4.3.txt` (16:30).
- Kiểm thử tự động sau sửa (16:39): `dart analyze` 17 tệp đã sửa — 0 lỗi (27 cảnh báo/info có sẵn từ trước, ví dụ `unnecessary_non_null_assertion` trong onboarding, `deprecated_member_use` Radio); `flutter test` yh_040–043: **26/26 đạt**.
- Sửa ghi chép mục B: AVSub — sheet ghi `.nl` nhưng tên miền chết (curl 000, 28/10/2026) → mặc định `animevietsub.sale`, tự chuyển `.nl`→`.sale`.
- Kiểm thử TV (AVD `YomiHub_TV_API34`, ảnh hệ thống x86 + dịch ARM `libndk_translation` → cài APK `armeabi-v7a`; APK `x86_64` báo `INSTALL_FAILED_NO_MATCHING_ABIS` vì ảnh TV chỉ có x86 32-bit):
  - Lần đầu mở: hệ thống mở trang "Allow access to manage all files" (quyền `MANAGE_EXTERNAL_STORAGE`, `storage_provider.dart`); bấm Back → ứng dụng tiếp tục bình thường.
  - **Lỗi 1 (đã sửa):** màn "Thêm nguồn" tự đặt tiêu điểm vào ô "URL kho" trên TV; phím D-pad Xuống không rời ô (kết nối IME giữ phím) → người dùng chỉ có remote bị kẹt. Sửa `lib/modules/onboarding/onboarding_screen.dart`: bỏ `autofocus` của ô nhập trên TV, nút "Để sau" nhận tiêu điểm ban đầu (Lên → ô nhập, OK → bàn phím); ẩn câu "Truyện tranh, Phim & Điện ảnh và Tiểu thuyết đều được hỗ trợ…" trên TV.
  - **Lỗi 2 (đã sửa):** màn hình chính TV còn chữ tiếng Anh cứng ("Your anime library is empty", "Add anime from Browse…", "Browse anime", "Continue", "Hidden categories", "New category", "Close/Cancel/Add", 2 thông báo lọc/ẩn). Sửa `lib/modules/library/tv_home/tv_anime_home_view.dart` dùng `tr()` tiếng Việt; thêm 8 khoá vào 18 tệp `assets/yomihub_i18n/*.json` (bản trước: `audit-0.4.3/before/i18n_tv`).
  - Xác nhận: thanh điều hướng TV chỉ có Phim & Điện ảnh, Play Books, Cập nhật, Duyệt, Thêm — **không có Comic/Novel**.
  - Ảnh: `output/0.4.3/qa/tv1_*`–`tv8_*` (bản trước sửa), `tv2x_*` (bản sau sửa); video `qa/tv043_walk1.mp4`, `qa/tv043_walk2.mp4`.
- `build_043.ps1`: bỏ cờ `--no-fatal-infos` (Dart 3.13 không nhận → analyze lỗi exit 64), thêm 2 tệp mới vào danh sách analyze.
- Windows: sau khi khởi động lại, bản portable 0.4.3 hiển thị bình thường; sau khi bật ghi màn hình ffmpeg gdigrab + phóng to cửa sổ thì ngừng vẽ; mở lại cả 0.4.3 lẫn 0.4.2 đều ra cửa sổ trắng dù tiến trình phản hồi (`Responding=True`) và vẫn ghi log. Lúc đó RAM trống chỉ ~0,9–1 GB/16 GB (Gradle 3,5 GB + VM phiên làm việc 4 GB + ứng dụng khác) → nghi thiếu bộ nhớ đồ hoạ dùng chung (Iris Xe) hoặc driver hybrid; chưa kết luận. Không dùng ffmpeg gdigrab khi kiểm thử Flutter Windows nữa.
- Máy người dùng mất kết nối với phiên làm việc ~16:20–16:50 (job runner vẫn chạy và hoàn tất các bước trên).
