# KẾT QUẢ QA1 (Sonnet) – kiểm lần cuối APK 0.5.7+50 (lastUpdateTime 13:17:18) trên Note 9, 13:18–13:38
Bằng chứng: `audit-0.5.7/evidence/phone/qa1v/` (tiền tố a/b/c/v). Không xóa dữ liệu/gỡ cài/đăng nhập.

| Mục | Kết quả | Bằng chứng | Ghi chú |
|---|---|---|---|
| 1a Reader MangaDex (VI) Shirley Madison Vol.2 Ch.11 | **ĐẠT** | a4_r_t3.png, a4_r_t15.png (trang 1/13), a6_up.png (2/13), a7_p5.png (5/13), c1_reader.png (mở lại: trang 1 hiện) | Trang 1 hiện sau ~3 s (trước đây spinner 95 s+). Reader lật DỌC (vuốt lên); vuốt ngang không đổi trang. Đã xem cả 3 ảnh. |
| 1b Đường lỗi + Thử lại | **ĐẠT** (trên chương Comick) | b8_t10 / ui_b8_t35.txt, b9_retry.png | Chương Comick (DNS api.comick.fun lỗi): sau 10 s đã hiện "Đã xảy ra lỗi" + lý do (Network unreachable) + nút "Thử lại"; bấm Thử lại -> tải lại (spinner). Lỗi hiện nguyên cả stack trace Dart -> nên gọn lại. Không có trang MangaDex nào lỗi nên không thử watchdog 30 s thật. |
| 1c Chương từ nguồn truyện khác | **BLOCKED** | b3/b4/b5 (ui_*.txt), b8, a8_r_t12.png | FoxTruyen, NhatTruyenS "Không có kết quả"; Comick/CoManhua: DNS/mạng lỗi (log: Unable to resolve comanhuavui.com, api.comick.fun). Một mục Lịch sử truyện mở ra "Lỗi: không có trang nào" (không có nút Thử lại) – nguồn không trả trang. Không tải được trang thành công từ nguồn nào ngoài MangaDex. |
| 2 Video "Kungfu Nữ Túc" | **FAIL** | v1_t6.png, v1_tap.png, v1_t27.png, v1_rec.mp4 (+ v1_rec_contact.png), v1_logcat_u8.txt, logs.txt | Điều khiển hiện lúc 6 s nhưng 00:00/00:00, KHÔNG có hình; sau đó màn đen hoàn toàn (kể cả sau chạm). Logcat: AudioTrack stop lặp 13:33:06,08,11,13,16,18,21 (~2,5 s/lần, 9 lần) và logs.txt có thêm dòng "không phát tiếp được tại 42:57 sau 8 lần tua ... phát từ vị trí hiện tại 43:22" lúc 13:33:23 (đếm "sau 8" 5->6). Tức lỗi tua lặp 8 lần VẪN CÒN. Có tiếng (MediaCodec Exynos chạy) nhưng không hình. Không kiểm được toast "Tiếp tục phát từ" (không bắt được), không thể so vị trí reopen. |
| 2b Back trong trình phát | **FAIL** | c1_back.png, log job c1 | Back khi hình đen (không có hình) -> app vào PiP (stack pinned 672x378) và thoát ra launcher thay vì về màn trước. Điều kiện "chỉ PiP khi có hình" chưa hiệu quả (có thể do audio đang phát được coi là đang phát). |
| 3a Sheet Thư viện mở/đóng x5 | **ĐẠT** | c1_libsheet.png, c1_lib_after.png | Sheet Bộ lọc/Sắp xếp/Hiển thị mở đúng, về Thư viện sau 5 lần. |
| 3b Sheet Reader x5 | **ĐẠT** | c1_rsheet.png, c1_reader_after.png | Sheet "Chế độ đọc" mở đúng, sau 5 lần reader vẫn hiện trang 1/ thanh điều khiển bình thường. |
| 3c Logcat | **ĐẠT** | c1_logcat.txt (UTF-16; iconv) | FATAL EXCEPTION: 0; "Null check": 0 (cho đoạn Thư viện + Reader + sheet). |

## Tóm tắt
- Reader (lỗi 1): ĐẠT trên MangaDex; đường lỗi/Thử lại ĐẠT trên Comick.
- Video (lỗi 2): FAIL – vẫn tua 8 lần, không hình, Back -> PiP đen.
- Không có đóng/cài lại; PiP còn treo đã được đóng bằng force-stop ở job kế tiếp.
