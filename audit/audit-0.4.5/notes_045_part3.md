| 8 | Hako (LNReader) sau khi sửa C5, bản 7 (12:42–12:53). | — | Chương chữ "Mở đầu" (nội dung `xor_shuffle`) hiển thị đúng tiếng Việt (`p53_hako_text_b7.png`, video `p045_hako_text.mp4`). Chương "Minh họa" không còn `TypeError`: đọc được 13 ảnh nhưng ảnh đều báo "Không tải được ảnh: default.jpg" (`p52_hako_chapter_b7.png`). Đã giải mã chương `c6764-minh-hoa` bằng Python: ảnh là `https://*.bp.blogspot.com/…/s0/default.jpg`. `curl.exe` có và không có Referer đều trả **403** → ảnh đã bị xoá phía máy chủ Blogspot, không phải lỗi app. |

#### D. Sao lưu Telegram (sheet "YomiHub Update")

Rà mã `TelegramProvider` (`lib/yomihub/cloud/cloud_backup_service.dart`) và đối chiếu dữ liệu thật trên Xiaomi 15T.

Dữ liệu thật trên máy:
- Telegram đang "Đã kết nối", bật "Tự động tải lên khi sao lưu".
- Nút "Khôi phục từ đám mây" (12:27) báo **không có bản sao lưu nào**: lịch sử tải lên rỗng.
- Bản sao lưu YomiHub trong `Backup Yomi Apps/autobackup` nặng **24,6–25,2 MB** (08/10–30/10).
- `api.telegram.org` truy cập được từ mạng hiện tại: điện thoại `ping` + TCP 443 OK, Windows `curl` 302.

Các lỗi trong mã:
1. **Giới hạn Bot API**:
   - `sendDocument` nhận tối đa 50 MB.
   - `getFile` chỉ tải về được tệp tối đa **20 MB**. Bản sao lưu 25 MB của người dùng tải lên được nhưng **không bao giờ khôi phục được** ("file is too big").
2. Dùng `http.Client()` trơn, bỏ qua "VPN & DNS" (Tor/Proxy/DoH). Khi nhà mạng chặn Telegram thì không có đường vòng.
3. Thông báo lỗi chứa URL `…/bot<TOKEN>/…`. Lỗi được ghi vào Nhật ký nên **lộ bot token**.
4. Token/Chat ID không được `trim()`. Không kiểm tra Chat ID khi kết nối, nên lỗi "chat not found" chỉ lộ ra ở lần sao lưu đầu.
5. Không có timeout và không thử lại khi gặp HTTP 429.

Sửa:
- Tệp > 19 MB được gửi thành các phần `…backup.part01ofNN`. Lịch sử lưu `parts:id1,id2,…`. Khôi phục tải từng phần, nối lại và kiểm tra kích thước.
- `getUpdates` nhận ra các phần do người dùng chuyển tiếp cho bot.
- Dùng `MClient` (theo "VPN & DNS"). Lỗi mạng kèm gợi ý bật WARP/Tor/Proxy.
- `maskToken()` che token trong mọi thông báo.
- `completeAuth` gọi `getMe` + `getChat`. Có gợi ý riêng cho 401, chat not found, bot bị chặn, 413, 429.
- Timeout 30 s / 5 phút, thử lại 3 lần.
- 10 chuỗi mới, dịch đủ 18 ngôn ngữ (`audit-0.4.5/tr045.py`; `i18n_scan`: 1.280 chuỗi, 0 thiếu).
- Test `yh_045`: che token, kích thước phần < 20 MB, đặt tên/ghép lại các phần.

**Chưa thử tải lên thật**: thao tác này gửi bản sao lưu vào cuộc trò chuyện Telegram của người dùng, nên cần người dùng đồng ý trước.

#### E. Kiểm thử trên Xiaomi 15T (Android 16, HyperOS 3.0.303) – các bản dựng arm64 trung gian

| Bản | Giờ dựng | Nội dung thêm |
|---|---|---|
| 1 | 10:04 (1.187 s) | Booru Rule34, VTV Go `cache.vtvgo.vn`, version 0.4.5+37 |
| 2 | 10:31 (471 s) | Telegram, splash, bản dịch |
| 3 | 11:01 (359 s) | thông báo "chương không đánh số" |
| 4 | 11:43 (320 s) | trình phát – luồng trực tiếp |
| 5 | 11:55 (377 s) | log lỗi chương tiểu thuyết, màn hình trong log hiệu năng |
| 6 | 12:13 | **lỗi dựng** (C7) |
| 7 | 12:38 (290 s) | cheerio LNReader, WARP gồm YomiHub |

Mọi bản: `dart analyze` trên các tệp đã sửa **0 lỗi** (chỉ còn info/warning có từ trước); `flutter test` yh_040–045 **45/45 đạt**. Cài đè giữ dữ liệu (`adb install -r`, versionCode 2037).

| Hạng mục | Kết quả | Bằng chứng (`output/0.4.5/qa/`) |
|---|---|---|
| Khởi động, loading 5 s | Logo tròn, chữ "Truyện tranh · Phim & Điện ảnh · Tiểu thuyết", không văng. 3 lần khởi động lạnh bản 2 không có dòng "Khung hình chậm" (bản 0.4.4: 421/434 ms). | `p01_splash.png`, `p045_start*.mp4` |
| Booru App – Rule34 chưa có key | Hiện thông báo + nút "Nhập API key" → mở Cài đặt Booru App. Log 1 dòng WARNING thay vì ERROR. Đã chuyển lại Safebooru như trạng thái cũ. | `p05`–`p07`, `p045_booru_rule34.mp4` |
| VTV Go (Phim & Điện ảnh) | Danh sách ~40 kênh. VTV1 phát trực tiếp. Bản 4: không còn ERROR/đổi máy chủ. Thoát trình phát bình thường. | `p10`–`p14`, `p045_vtv1_*.mp4` |
| Chuyển tab (bản 3, 7 lần, cách 62 s) | Không có khung hình chậm. | `phone_logs_b3.txt` |
| Tiểu thuyết Hako (LNReader) | Bản 3/5: `TypeError` → bản 7: đọc được (C3, C5, C8). | `p50`–`p53` |
| Sao lưu đám mây | Màn hình đủ 7 dịch vụ (Google Drive, OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram). | `p40`–`p44` |
| VPN (ngoài ứng dụng) | WARP lên ở mức hệ điều hành; sửa danh sách ứng dụng (C6). | `p60`–`p63`, `p045_warp.mp4` |
| Chạm đầu tiên bị bỏ qua | Lặp lại 2/≈60 lần chạm (10:10 thanh dưới, 12:07 nút "Thêm"); các lần khác đều nhận. Không tái hiện được có chủ đích (thử chờ 70 s, thử khi đang quay màn hình). Còn mở như ghi nhận ở 0.4.4. | `x045_015`, `x045_063` trong `jobs/done` |
