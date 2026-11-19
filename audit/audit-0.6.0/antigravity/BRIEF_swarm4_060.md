# BRIEF /swarm 4 – YomiHub 0.6.0 (19/11/2026 14:42) – CHỈ @device_tester, làm lại cho đủ
[Claude (Anthropic) điều phối thay mặt Kiệt]
Đọc `REVIEW_swarm3_060.md` + `BRIEF_swarm3_060.md` (quy tắc cứng giữ nguyên: không flutter/gradle/trình giả lập, không quét đệ quy, chỉ ghi `audit/audit-0.6.0/antigravity/`, không cài/gỡ app, không xóa dữ liệu, không đăng nhập).

## TIÊU CHÍ ĐẠT (bắt buộc)
- Mỗi kịch bản ≥ 1 ảnh PNG thật: `adb -s 281038ac31217ece exec-out screencap -p > audit\audit-0.6.0\antigravity\test_note9\s<số>_<tên>.png` (PowerShell: dùng `cmd /c "adb ... exec-out screencap -p > file.png"` để không hỏng nhị phân). Tự mở ảnh xem; ghi điều thấy được trong ảnh vào báo cáo.
- Kịch bản 1 phải là nguồn có chữ **"(Kotatsu)"** trong tên (Duyệt › Nguồn, cuộn tìm; hoặc dùng ô tìm nguồn). Trong bộ lọc: chụp trước/sau khi bấm 1 lựa chọn chọn-một, và 1 thể loại bấm 2 lần (✓ xanh → ô đỏ loại trừ); áp dụng → chụp kết quả (lỗi mạng thì ghi lỗi).
- Kịch bản 2–6 như BRIEF_swarm3 (Cập nhật + cuộn; Sao Lưu Lên Google Drive – chỉ mở màn hình; gợi ý kho Salmanbappi/Secozzi; Savior "Quét mã trang tìm link video" ở trang video công khai; LOG_REVIEW.md từ "Logger initialized" cuối).
- Không làm được kịch bản nào: ghi rõ đã thử những bước gì + ảnh màn hình chỗ bị chặn.
- Cập nhật `NOTES_swarm3_device_tester.md` sau mỗi bước; báo cáo cuối `test_note9/REPORT_device_060.md` (ghi đè) + `SUMMARY_swarm4_060.md`. Thời hạn 40 phút, không dừng trước khi đủ 6 kịch bản.
