# Nhật ký phiên làm việc

Mỗi phiên thêm một mục MỚI Ở CUỐI: ngày · phiên bản · tác nhân – yêu cầu – đã làm – kết quả – tiếp theo. Chi tiết kỹ thuật ở `TECHNICAL_UPDATE_NOTES.md`; tệp này chỉ là dòng thời gian ngắn.

## Tóm tắt các phiên trước 18/11/2026 (theo TECHNICAL_UPDATE_NOTES)
- **25–26/10** · 0.3.9–0.4.1 – Tạo ghi chú kỹ thuật + AGENTS.md; sửa lỗi log, Cloudflare, Brotli; đóng gói Windows/Android/TV đầu tiên.
- **28–29/10** · 0.4.3–0.4.4 – Sửa hồi quy DNS, ảnh bìa lịch sử, app tự đóng khi bật Tor; Booru App, Rclone/MediaFire, Health Connect; còn lỗi cửa sổ trắng Windows.
- **30/10–01/11** · 0.4.5–0.4.7 – Telegram chia phần, splash 5 s morph vuông→tròn, tách APK TV; kiểm thử Xiaomi 15T, Note 9.
- **02–03/11** · 0.4.9–0.5.0 – Chạy tiện ích vBook (QuickJS), kiểm tra cập nhật nhiều nguồn; hết cửa sổ trắng; TV bỏ Comic/Novel/Play Books/Booru.
- **03–06/11** · 0.5.1–0.5.3 – Thư mục cục bộ, quyền Android 7–10, sao lưu nhanh; 29 tiện ích chuyển sang Kiritokmn Extension Repo.
- **10–13/11** · 0.5.5–0.5.6.1 – Hàng đợi ghi Isar; Thư viện gộp 4 mục, giao diện Cũ/Mới; sửa VPN V1–V8; APK Android 6.0 riêng.
- **14–15/11** · 0.5.7 – Sửa log 12–14/11 (Null check tab, Tor kẹt snowflake, Cloudflare); Shiori, Yomikiru/Yomihon; tạo Second Brain (14/11); điều phối nhiều tác nhân (bài học hạn mức).
- **17/11** · 0.5.8 – 11 nhóm sửa lỗi/tính năng (MangaDex stream, Isolate diff chương, Health Connect 14+, sao lưu Booru, i18n 18 ngôn ngữ); gom thư mục `audit/`.

## 18/11/2026 · 0.5.9 · Claude Opus 5.5 (Cowork, điều phối) + Google Antigravity
- **Sáng (phiên trước)**: sửa log 16–18/11 (mục 1–11 ghi chú kỹ thuật): Isar unsendable, chọn nhầm APK android6, DNS kiểm tra cập nhật, Tor nhớ cầu nối, Cloudflare cùng đường mạng, treo Thư viện, log video không thoát, nhãn log mỗi dòng, Google Sign-In → Drive, chọn mục sao lưu Booru, +258 liên kết GitHub. Antigravity /swarm 1–2: sửa 7 tiện ích, báo cáo kho/nguồn cập nhật.
- **11:19–12:10**: tiếp tục từ log phiên trước; xin quyền điều khiển máy; giao Antigravity /swarm 3 (README, rà lang/NSFW 196 nguồn, đối chiếu 29 kho). Chủ dự án đăng nhập GitHub/Google Cloud trong trình duyệt tích hợp → bật GitHub Pages (`docs/`), OAuth "In production". Cài bản phát hành 0.5.9 lên Note 9, log sạch lỗi Isar. Bật autosave 3 phút (yêu cầu chủ dự án).
- **12:48**: dây chuyền dựng xong (APK ×3, android6 ×3, TV ×3, Windows ×4, verify). **13:51**: thử Setup.exe cài đè trên Windows 11 – ĐẠT.
- **13:57–14:17**: chủ dự án xác nhận → push Extension Repo (`c919f87`), phát hành **GitHub Release v0.5.9** (19 tệp, khớp kích thước); Antigravity /swarm theo dõi 40 s, Claude 10 phút.
- **14:22–15:05**: cập nhật kiến thức; dừng autosave; gom `build_*.ps1` vào `build/`; tạo `04_cong_cu_su_dung.md`, Second Brain thành thư mục bắt buộc đọc (AGENTS/CLAUDE/GEMINI.md).
- **15:39–16:05**: About GitHub (Website + chính sách); trang chủ Pages viết lại đầy đủ tính năng, favicon = icon app, nút tải từng bản (tự trỏ bản mới nhất).
- **16:12–16:38**: đưa lên **APKPure**: chủ dự án đăng ký "Kiritokmn" (Cốc Cốc, Cloudflare chặn trình duyệt tích hợp); Claude tạo `com.yomihub.app`, mô tả EN + VI, 6 ảnh (2:1), ảnh nổi bật, Mature 17+, tải APK arm64 → gửi duyệt 16:36.
- **21:32–21:50**: tổ chức lại Second Brain 00–10 rồi 00–12 (thêm bàn giao, nhật ký phiên).
- **Tiếp theo**: chờ APKPure duyệt; chuẩn bị 0.6.0 theo mục "Còn mở" ở 11-D.

## 19/11/2026 · 0.6.0 · Claude Opus 5.5 (Cowork 09:02–11:40, rồi claude.ai + máy tính 11:45–) + Google Antigravity
- **Sáng (09:02–11:40)**: đọc log 16–19/11 + 2 Excel; sửa lỗi log (trang Cập nhật treo, CBHentai đổi URL, ảnh Kotatsu 127.0.0.1, Tor, Health Connect, thông báo android6); Sao lưu Google Drive (logo G), Savior quét link video, Short Video +7 trang, kho Salmanbappi/Secozzi, 5 thay đổi Mangayomi v0.9.96, i18n; test 28/28. Máy quá tải (PC Manager, 3 PowerShell quét đệ quy của Antigravity). Bật dây chuyền 11:33.
- **11:45** phiên mới nhận bàn giao: dây chuyền trượt bước test (5 test gắn cứng 0.5.x) → sửa test; sửa regex AppxBundle `0.5.9.0` trong `build_060.ps1`.
- **12:39** chủ dự án yêu cầu: mọi lựa chọn trong bộ lọc tiện ích thành ô chọn → `filter_checkbox.dart`, `FilterWidget` thành StatefulWidget (sửa luôn lỗi "mục bộ lọc không chọn được"), Kotatsu/Aniyomi dùng ô chọn; test 8/8. Dừng bản dựng cũ, dựng lại: test 942/942 → apk 34' → tv 30' → wintest (lần 1 trượt yh_055 chập chờn, lần 2 ĐẠT) → win → pack → a6build → verify XONG 15:04.
- Note 9: bộ lọc ô chọn MangaDex + nguồn APK ĐẠT (ảnh evidence/note9 01–14). Windows portable: mở được, bộ lọc ô chọn ĐẠT.
- **14:08** chủ dự án yêu cầu giao Antigravity qua /swarm: đợt 3 (@device_tester + @doc_writer) – kiểm thử sơ sài → đợt 4 làm lại có ảnh: Kotatsu ô chọn, Cập nhật, Google Drive, gợi ý kho ĐẠT; changelog EN dùng được.
- **15:25** phát hành GitHub Release v0.6.0 (19 tệp).
