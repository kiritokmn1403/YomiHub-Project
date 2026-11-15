# KẾT QUẢ QA1 (Sonnet) – APK phát hành YomiHub 0.5.7+50 (arm64-v8a) trên Note 9 (Android 10)
Cài đè giữ dữ liệu: versionName 0.5.7, versionCode 2050, lastUpdateTime 2026-11-15 07:55. Bằng chứng: `audit-0.5.7/evidence/phone/qa1r/`.

| Flow | Kết quả | Bằng chứng | Ghi chú |
|---|---|---|---|
| 1 Cài đặt + khởi động | PASS | 01_launch.mp4, 01_timeline.png | splash -> màn tải YomiHub -> Thư viện (~6 s) |
| 4a Reader: ảnh trang MangaDex (VI) Shirley Madison Vol.2 Ch.11 | **FAIL / chưa đạt** | r04m_reader_a.png, r04n_wait.png (spinner >40 s), r04o_reload.png | Reader mở được (13 trang, thanh menu hiện khi chạm giữa). Trang 1 quay spinner mãi, KHÔNG còn báo "Không tải được ảnh này" nhưng cũng không hiện ảnh; nhấn tải lại vẫn treo. Logcat không có dòng flutter/lỗi. Điện thoại: `ping api.mangadex.org` = unknown host (DNS hệ thống), ping google/8.8.8.8 OK. Booru (r16_booru_small.png) tải ảnh bình thường -> pipeline ảnh chung hoạt động, lỗi riêng host MangaDex/CDN. Không thể phân biệt lỗi mạng/DNS với lỗi ứng dụng (spinner treo không hết hạn/không báo lỗi là điểm đáng sửa). Bìa thư viện/lịch sử vẫn hiện icon ảnh hỏng. |
| 4b Sheet cài đặt reader mở/đóng x10 | PASS | r04q_settings_open1.png, r04q_settings_open10.png | sheet Chế độ đọc/Chung/Bộ lọc tùy chỉnh hiện đủ cả lần 1 và lần 10; logcat r04q_logcat.txt: 0 dòng Null check/FATAL (chỉ ExifInterface của tiến trình hệ thống 3321, không phải app) |
| 9 Resume video | BLOCKED | r09g_t22.png, 09c_tl.png | Lịch sử Phim "Goblin Tập 04 (13:08)": sau 22 s màn đen + spinner mờ, không thanh điều khiển, không phát (nguồn phim không phát được, giống bản dev). Không so được thời gian. Lần đầu màn đen do điện thoại tắt màn hình (timeout), đã xử lý. |
| 2 Giao diện Cũ/Mới | PASS | r02_montage.png | Mới: thẻ kiểu Shiori + nav nổi (nhãn "Hoạt độ..." bị cắt – lỗi nhỏ). Đã khôi phục Cũ (r02_ui_old_home.png) |
| 3 Sheet Bộ lọc thư viện x10 | PASS | r03_sheet_open_10.png | không sập; logcat 0 Null check/FATAL |
| 7 Cài đặt: Sao Lưu & Đồng Bộ | PASS | r07c_backup.png | cảnh báo đỏ "Thư mục sao lưu không còn tồn tại" (đúng hành vi, thẻ SD) |
| 7 Cài đặt: Bật/Tắt tính năng & Nguồn mở rộng | PASS | r07g_features_bottom.png, ui_r07f_features.txt | công tắc Google Play Books + Booru App đang bật; Truyện tranh 10/10, Phim 8/8, Tiểu thuyết 3/3 kho. Tiêu đề phụ ở trang Cài đặt chỉ ghi 3 loại, không nhắc Play Books/Booru (nhỏ) |
| 7 Hợp Nhất Tiện Ích | PASS | r07c_merge.png | banner "9 tiện ích đang bị tắt – Bật lại", nhóm chưa hợp nhất (21), nút Hợp nhất/Tự chọn |
| 15 Play Books | PASS | r15_pb.png | tab Play Books: Sách điện tử/Sách nói, nav Trang chủ/Thư viện/Danh sách yêu thích/Cửa hàng; lỗi nhỏ: nhãn "Danh sách yêu thích" xuống dòng và đè icon |
| 13 Nhật ký ứng dụng | PASS | r13c_applog.png, ui_r13c_bugreports.txt | màn mở được; lặp WARNING tải kho kohiden.xyz: CERTIFICATE_VERIFY_FAILED (Android 10). Báo cáo lỗi 2 mục cũ (08/11, 06/11). Không có dòng nào về lỗi tải ảnh reader |
| 12 VPN & DNS (chỉ mở) | PASS | r12_vpn_dns.png | VPN đang tắt, 5 mục: Dịch vụ VPN, VPN cho tiện ích, VPN ứng dụng ngoài, Quốc gia đích, DNS |

## Logcat
- Reader settings x10: 0 Null check/FATAL. Thư viện sheet x10: 0 Null check/FATAL.
- Chỉ có ExifInterface "Invalid byte order" từ pid 3321 (hệ thống Samsung, do ảnh chụp màn hình), không liên quan.

## Lỗi/đề xuất
1. (Cao) Ảnh trang reader MangaDex treo spinner vô hạn, không timeout/không thông báo; kiểm tra lại fallback Dart khi DNS hệ thống không phân giải được host CDN (app gọi API được nhưng ảnh không).
2. (Thấp) Nhãn nav mới "Hoạt độ..." bị cắt; nhãn "Danh sách yêu thích" (Play Books) xuống dòng đè icon.
3. Cảnh báo TLS kohiden.xyz CERTIFICATE_VERIFY_FAILED trên Android 10.
4. Việc đã làm trên máy: bật stayon + screen_off_timeout 600000 trong lúc test, sau đó trả stayon=false và timeout=30000 (giá trị gốc không đọc được, đoán 30 s).
