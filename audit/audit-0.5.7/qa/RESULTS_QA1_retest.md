# KẾT QUẢ QA1 (Sonnet) – kiểm lại APK 0.5.7+50 (cài 10:42) trên Note 9, 11:44–12:02
Bằng chứng: `audit-0.5.7/evidence/phone/qa1s/` (tiền tố s). Xác nhận: versionName 0.5.7, versionCode 2050, lastUpdateTime 2026-11-15 10:42:32; không cài lại.

| Mục | Kết quả | Bằng chứng | Ghi chú |
|---|---|---|---|
| 4a Reader MangaDex (VI) Shirley Madison Vol.2 Ch.11 | **FAIL** | s4_search.png (bìa tải được, DNS ổn), s6_reader_t10.png, s6_reader_t48.png, s6_reader_t95.png, s9_reload_t12/t52.png | Duyệt/tìm kiếm/chi tiết MangaDex nay chạy, bìa hiện. Reader mở (13 trang) nhưng trang 1 chỉ có spinner ở 10 s, 48 s, 95 s; sau bấm nút tải lại ở thanh trên vẫn spinner đến 52 s. KHÔNG hiện "Không tải được ảnh này", không có dòng lý do, không có nút Thử lại -> không thấy cơ chế timeout 30 s/lỗi/retry của QA3. Điện thoại ping được api.mangadex.org và uploads.mangadex.org (dxlb.mangadex.org 45.129.229.1), nên không phải do DNS. Logcat không có dòng flutter/lỗi ứng dụng. |
| 9 Resume video (Phim & Điện ảnh) | **BLOCKED** | s11_play_t12.png, s11_play_t28.png (Kungfu Nữ Túc), s13_play_t12.png, s13_play_t30.png (Thanh Gươm Diệt Quỷ) | Thử 2 mục lịch sử: màn đen, spinner mờ rồi đen hẳn, không có thanh điều khiển sau chạm. Không phát được nên không so được vị trí, không quay video. Phụ: bấm Back trong trình phát làm app thu nhỏ thành cửa sổ PiP đen ở góc phải và thoát ra launcher (s12_afterback.png) thay vì về Lịch sử -> nên xem lại (có thể do PiP tự động khi trình phát lỗi). Đã đóng PiP bằng force-stop. |
| 3a Giao diện Mới: nhãn "Hoạt động" | PASS | s16_ui_new_home.png | nhãn hiện đủ "Hoạt động" (huy hiệu 123), không bị cắt; các nhãn Thư viện/Booru/Duyệt/Thêm cũng đủ |
| 3b Play Books: nav "Yêu thích" | PASS | s15_playbooks.png | Trang chủ / Thư viện / Yêu thích / Cửa hàng, "Yêu thích" một dòng, không đè icon |
| 3c Khôi phục giao diện Cũ | PASS (theo UI dump) | s17_restored_old.png, s17_old_home.png, ui_s17_old_home.txt | thanh nav quay lại kiểu "Tab n trong tổng số 5"; ảnh s17_old_home chưa xem trực tiếp, chỉ dựa UI dump |
| 4 Logcat | PASS | s17_logcat_full.txt | FATAL EXCEPTION: 0; "Null check": 0; không có dòng flutter/yomihub báo lỗi. Các "Exception" còn lại chỉ là ExifInterface của pid 3321 (hệ thống) và ProcessCpuTracker; "AndroidRuntime" chỉ do uiautomator của bộ test. |

## Việc đã làm trên máy
- Không xóa dữ liệu/gỡ cài/đăng nhập. Chạm nhầm vào thư mục "Appstore" trên launcher (do Back thoát app), không mở ứng dụng nào. Giao diện đã trả về Cũ. Màn hình vẫn mở khóa, stay-awake giữ nguyên.

## Đề xuất
1. (Cao) Reader: spinner trang ảnh MangaDex vẫn không hết hạn sau 95 s dù mạng/DNS ổn -> có thể bản 10:42 chưa có vá QA3 hoặc đường tải ảnh này nằm ngoài chỗ đã vá (kiểm tra bản build đang cài đã gồm timeout/Thử lại, và nút tải lại thanh trên có đi qua đường đó không).
2. (Trung bình) Video: cả 2 mục lịch sử Phim đều đen, không báo lỗi; cân nhắc hiển thị thông báo lỗi tương tự reader.
3. (Thấp) Back trong trình phát -> PiP/thoát app.
