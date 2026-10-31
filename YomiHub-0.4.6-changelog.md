# YomiHub 0.4.6 (0.4.6+38) — 01/11/2026

## Tính năng mới, cải tiến so với 0.4.5
- **VPN riêng theo từng nguồn Booru:**
  - Trong mục **"VPN cho tiện ích, WebView & Trình Duyệt"**, thêm tùy chọn bật/tắt VPN chung cho **"Mọi nguồn Booru"** hoặc chọn riêng từng trang ảnh Booru.
  - Màn hình danh sách chọn nguồn Booru riêng lẻ (`_ScopeBooruScreen`) hỗ trợ 10 trang Booru tích hợp (Danbooru, Safebooru, Gelbooru, Konachan, e926, Yande.re, e621, Rule34, Xbooru...).
  - Tóm tắt phạm vi trên Hub VPN tự động cập nhật động (`mọi Booru`, `2 Booru`, v.v.).
  - Các yêu cầu mạng từ Booru App (`BooruApi`) được định tuyến tự động qua proxy VPN tương ứng của từng nguồn đã chọn.
- **Tự động kích hoạt cầu nối Kotatsu:**
  - `KotatsuBridge.ensureStarted()` tự động kiểm tra và khởi động tiến trình cầu nối loopback (cổng 47350) ngay khi người dùng duyệt tiện ích Kotatsu, không cần đợi thêm nguồn vào thư viện.
  - Bổ sung cơ chế tự thử lại tới 3 lần với backoff 800ms khi gửi request loopback tới Kotatsu bridge.
- **Xử lý URL ảnh tương đối:**
  - Tự động phân giải và ghép host từ header `Referer` hoặc `Origin` cho các URL ảnh có đường dẫn tương đối (dạng `/wp-content/...`).
- **Chuẩn hóa trạng thái truyện/phim an toàn:**
  - Hàm `yhStatus` chuẩn hóa trạng thái trong môi trường JavaScript được viết lại để chấp nhận an toàn mọi kiểu dữ liệu (số nguyên, object, chuỗi, null) mà không văng ngoại lệ.

## Lỗi đã sửa
- **Sửa lỗi `yhStatus` văng `TypeError: not a function`:** Triệt tiêu hoàn toàn lỗi khi các nguồn phim/truyện (như Anime47) trả về `a.status` kiểu số nguyên hoặc object.
- **Sửa lỗi "Cầu nối Kotatsu chưa chạy":** Khắc phục lỗi khi mở các nguồn Kotatsu (như CBHentai) trong chế độ duyệt tiện ích chưa cài đặt.
- **Sửa lỗi crash ảnh đường dẫn tương đối:** Phân loại các lỗi tải ảnh từ xa là lỗi mạng thông thường trong `crash_report.dart`, ngăn ngừa tình trạng báo lỗi `FlutterError` không đáng có.
- **Chuẩn hóa bộ kiểm thử hồi quy:** Sửa điều kiện so khớp phiên bản trong `yh_045_test.dart` và gọi đúng hàm `isExpectedFailure` trong `yh_046_test.dart`. Toàn bộ 51/51 ca kiểm thử đơn vị vượt qua 100%.

## Tệp tải về (10 tệp chính)
- **Android Mobile (Android 7.0+):**
  - `YomiHub-0.4.6-arm64-v8a.apk` (168.7 MB)
  - `YomiHub-0.4.6-armeabi-v7a.apk` (165.5 MB)
  - `YomiHub-0.4.6-x86_64.apk` (178.0 MB)
- **Android TV (YumiHub Android TV, không Comic/Novel):**
  - `YumiHub-Android-TV-0.4.6-arm64-v8a.apk` (168.6 MB)
  - `YumiHub-Android-TV-0.4.6-armeabi-v7a.apk` (165.5 MB)
  - `YumiHub-Android-TV-0.4.6-x86_64.apk` (178.0 MB)
- **Windows (10/11 x64):**
  - `YomiHub-0.4.6-windows-x64-Setup.exe` (138.5 MB) — Bộ cài đặt EXE
  - `YomiHub-0.4.6-windows-x64.appxbundle` (270.8 MB) — Gói cài đặt UWP/MSIX
  - `YomiHub-0.4.6-windows-x64.zip` (138.5 MB) — Bản Portable
  - `YomiHub-0.4.6-windows-x64-full.zip` (266.4 MB) — Bản Portable đầy đủ (kèm MES bundle)
- **Tệp hỗ trợ:** `SHA256SUMS-0.4.6.txt`, `YomiHub-RootCA.cer`, `Install-YomiHub.bat`, `Install-YomiHub.ps1`.

## Giới hạn kỹ thuật
- Android 7.0+ là mức nền tảng tối thiểu do ràng buộc cấu trúc POSIX và memory-mapping của thư viện cơ sở dữ liệu `libmdbx` / Isar v3.
- Windows 10/11 x64 (Flutter Desktop không hỗ trợ Windows 7/x86/ARM).
