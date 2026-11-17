# YomiHub 0.4.3 — Nhật ký thay đổi

**Ngày phát hành:** 28/10/2026 · **Phiên bản nguồn:** `0.4.3+35` · **User-Agent:** `YomiHub/0.4.3`

| Gói | Nền tảng |
|---|---|
| `YomiHub-0.4.3-arm64-v8a.apk`, `-armeabi-v7a.apk`, `-x86_64.apk` | Android 7.0+ (điện thoại, máy tính bảng) |
| `YumiHub-Android-TV-0.4.3-*.apk` (3 ABI) | Android TV 7.0+ — chỉ Phim & Điện ảnh (bỏ Comic, Novel) |
| `YomiHub-0.4.3-windows-x64.appxbundle` (+ `YomiHub-RootCA.cer`, `Install-YomiHub.bat`) | Windows 10/11 x64 — gói cài MSIX/AppX có chữ ký |
| `YomiHub-0.4.3-windows-x64-Setup.exe` | Windows 10/11 x64 — trình cài đặt |
| `YomiHub-0.4.3-windows-x64.zip` / `-full.zip` | Windows 10/11 x64 — bản portable (full: kèm JRE + M-Extension-Server) |

## Tính năng mới so với 0.4.2

1. **Tự chọn tiện ích để hợp nhất** (Thêm › Hợp nhất tiện ích › "Tự chọn tiện ích"): gộp bất kỳ tiện ích cùng loại (kể cả khác tên miền), chọn tiện ích chính, tách nhóm bất cứ lúc nào; nhóm hiển thị "Tự chọn: A + B".
2. **Màn hình loading mới:** chính logo ứng dụng biến từ hình vuông bo góc thành hình tròn, hiện ngay từ khung hình đầu, vẫn 5 giây.
3. **Cập nhật thư viện thông minh:** bỏ qua khi không có mạng; nguồn lỗi 3 lần liên tiếp được tạm bỏ qua trong lần cập nhật; nhật ký ghi tên truyện + nguồn.
4. **Nhật ký ứng dụng chi tiết hơn:** "Video không thoát được", lỗi kho tiện ích (1 dòng/kho), lỗi máy chủ trả trang Cloudflare/HTML thay vì `SyntaxError '<'`, tác vụ đang chạy khi giao diện bị treo.
5. **Lịch sử chỉ mở từ "Thêm"** (không còn là tab riêng), lịch sử trong từng mục Truyện/Phim/Tiểu thuyết đồng bộ thời gian thực.
6. Bổ sung dự án GitHub còn thiếu (`HypertextAssassin0273`); dịch 8 chuỗi mới sang 18 ngôn ngữ.

## Lỗi đã sửa so với 0.4.2

| Lỗi | Sửa |
|---|---|
| Báo "Giao diện bị treo 111 giây" khi máy ngủ | Đo bằng đồng hồ đơn điệu, bỏ qua thời gian máy ngủ |
| Ứng dụng đứng khi mở lúc mất mạng (≈30 kho tiện ích cùng phân giải DNS) | Cache lỗi DNS, gộp truy vấn trùng, timeout DoH 4 s |
| Giật khi tải chỉ mục kho tiện ích lớn | Giải mã JSON trên luồng phụ, bỏ giải mã thừa toàn bộ tệp protobuf |
| 698 dòng "Failed to update Manga" cho một nguồn hỏng | Ngắt mạch theo nguồn, 1 dòng log/truyện |
| Hợp nhất lag (cuộn thư viện, màn Hợp nhất tiện ích, Duyệt) | Cache kết quả, đếm thư viện 1 lần thay vì mỗi dòng/mỗi lần bấm |
| Trình phát web không nhớ vị trí đã xem; đánh dấu "đã xem" sau 3 phút | Đọc vị trí từ CSDL, lưu khi thoát, chỉ đánh dấu khi xem ≥ 85 %, ghi Lịch sử |
| Kiểm tra cập nhật Drive thất bại khi rớt kết nối/1 thư mục con lỗi | 3 lần thử, bỏ qua thư mục con lỗi |
| FikFap lỗi `SyntaxError '<'` khi API trả HTML | Thử API dự phòng, báo rõ lý do |
| Nút "Mở cài đặt Wi‑Fi" không chạy trên Windows 7/8 | Mở `ncpa.cpl` khi không có `ms-settings:` |
| AVSub: tên miền `animevietsub.nl` (sheet) đã ngừng hoạt động | Dùng `animevietsub.sale`, tự chuyển máy đang dùng `.nl` |
| Bản Android TV/Android cài trên 6.0 bị từ chối (minSdk thực tế 24) | Ghi đúng yêu cầu Android 7.0+; xem mục giới hạn |

## Giới hạn đã biết

- **Android 6.0:** engine Flutter 3.47 và phần Java đã được vá chạy trên 6.0 (thử nghiệm trong `audit-0.4.3/compat23`), nhưng CSDL Isar/libmdbx báo `MDBX_INCOMPATIBLE` → bản phát hành vẫn yêu cầu Android 7.0+.
- **Windows 7/8, x86 32‑bit, ARM64:** Flutter Windows chỉ hỗ trợ Windows 10+ x64 (ARM64 cần máy dựng ARM64).
- AirDrop/Quick Share giữa 2 thiết bị thật, Health Connect, tracker có tài khoản, VPN thật: cần thiết bị/tài khoản thật, chưa kiểm thử trong phiên này.
