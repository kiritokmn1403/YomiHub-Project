# NOTES P5 - Sức khỏe, nhật ký tải, chia sẻ, Telegram, Booru (YomiHub 0.5.7)
Bắt đầu lượt 2: 14/11/2026 15:11 (Asia/Saigon)

## Yêu cầu
FC35 Health Connect; FC32 log tải/chia sẻ/Bluetooth; FC24 AirDrop & Quicksharing; FC42 Telegram backup; FC40 Booru (Dart); FC25 Tracker (chỉ test, không sửa).

## Lượt 1 (bị dừng ~10:53, không để ghi chú)
Đã sửa: chapter_controller_mixin.dart, health_connect_service.dart, 18 i18n JSON (sao lưu backup/src_0571/assets/yomihub_i18n_P5/), tạo test/yh_057_p5_test.dart (33/33 theo jobs/done/x1_p5_test1.log).

## Tiến trình lượt 2
- [ ] Rà diff lượt 1
- [ ] FC35 hoàn thiện
- [ ] FC32
- [ ] FC24
- [ ] FC42
- [ ] FC40
- [ ] Test + analyze
- [ ] Snippet cho P3 (player)

## Nhật ký

## Lượt P5b (Sonnet)
Bắt đầu 14/11/2026 (Asia/Saigon). Phạm vi: FC24/FC32 share, FC42 Telegram, FC40 Booru, download_provider (log lỗi).
- [ ] share  - [ ] Telegram  - [ ] Booru  - [ ] download  - [ ] test/analyze

### Kết quả P5b (14/11/2026, Asia/Saigon)
Yêu cầu: FC24/FC32 (AirDrop & Quick Share), FC42 (Telegram), FC40 (Booru), tải xuống – mọi nhánh lỗi phải vào Nhật Ký Ứng Dụng, không lộ token.
Tệp sửa (sao lưu ở backup/src_0571/):
- share/share_log.dart: thêm `YomiShareLog.warn()` (WARNING, 1 dòng).
- share/lan_share.dart: ghi log các nhánh trước đây nuốt lỗi (đọc IP, thư mục nhận, tên thiết bị/multicast, lỗi server, cổng UDP, gói dò không hợp lệ, phát dò, tắt multicast); không tìm thấy thiết bị nào -> WARNING gợi ý (cùng Wi-Fi/AP isolation); yêu cầu có mã sai/hết hạn -> WARNING; LỖI LOGIC: nhận tệp bị ngắt giữa chừng để lại tệp hỏng -> nay xóa tệp dở, kiểm dung lượng so với Content-Length (nếu có) và ghi ERROR.
- share/bluetooth_share.dart: log khi refresh lỗi, xin quyền/bật Bluetooth thất bại hoặc bị từ chối, danh sách ghép đôi lỗi/rỗng, listen lỗi (không văng ra UI), mở cài đặt Windows lỗi.
- share/share_screen.dart: log lỗi bật chế độ nhận (kể cả khi bấm chia sẻ tệp: trước đây văng chưa bắt), lỗi đọc ứng dụng Quick Share.
- cloud/cloud_backup_service.dart (TelegramProvider): log (đều qua `_mask`) khi kết nối thất bại (chat_id/token sai, chặn mạng), lịch sử hỏng, getUpdates lỗi/HTTP khác 200, tải/khôi phục thất bại hoặc thiếu dung lượng. Phần chia mảnh 19 MB, thử lại, nhắn nhà mạng chặn đã có từ 0.4.5 – giữ nguyên.
- booru/booru_api.dart: JSON hỏng -> `BooruException(format)` thay vì FormatException thô (cả autocomplete); booru_viewer.dart: log khi mở bài/chia sẻ lỗi (launchUrl false/URL sai). booru_screen/store đã log đủ, không sửa.
- modules/manga/download/providers/download_provider.dart: thêm log WARNING khi "chỉ tải qua Wi-Fi" chặn, và khi loadSync chương trong hàng chờ lỗi. Mọi lỗi tải khác đã qua markDownloadFailed/yomiLogDownloadError; catch rỗng dòng ~417 (xóa tệp thừa) chấp nhận được.
- Không thêm chuỗi tr() mới -> không cần i18n_P5b.json / i18n_merge.
Test: overlay/test/yh_057_p5b_test.dart (logic thuần + đọc mã).
Kết quả thật: job p5b_a analyze 5 mục: 0 error, 0 warning, chỉ 2 info có sẵn (booru_screen:37 use_null_aware_elements; bluetooth_share:205 allowMultiple deprecated). Lần test đầu trượt 1 (kỳ vọng 0 catch rỗng, thực tế còn 2 ở dọn phản hồi HTTP) -> chỉnh test; job p5b_b: `+26: All tests passed!` (p5b + yh_049, TEST EXIT 0).
Cần thiết bị thật: gửi/nhận LAN giữa 2 máy (ngắt giữa chừng, AP isolation), Bluetooth quyền/ghép đôi, Quick Share; Telegram thật (token sai, chat_id trống, >50MB chia mảnh, mạng chặn api.telegram.org); Booru từng site; tải xuống khi tắt Wi-Fi.
