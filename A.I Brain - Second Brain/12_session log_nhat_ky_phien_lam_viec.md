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
- **15:29** Release `v0.6.0` 19/19 asset khớp; bàn giao (11-E), dừng autosave.
- **15:38–16:12** theo yêu cầu chủ dự án: README viết lại theo mẫu Standard (The Documentation Compendium); sắp xếp toàn bộ `.ps1` → `scripts/{lib,runner,setup,pipeline,sync,build,packaging,release,autosave}` (sửa đường dẫn, tác vụ Windows runners, kiểm verify + khởi động lại runner); gỡ `scripts/lib/yh_defines.ps1` khỏi GitHub (giữ cục bộ, `.gitignore`); logo/ảnh → `assets/logo`, `assets/screenshots`, icon trang chủ → `docs/assets`; `.bat` → `scripts/setup`, `scripts/build`, `scripts/runner`. Lưu toàn bộ vào Second Brain (00, 03, 04, 05, 06, 08, 09, 10, 11, 12).
- **Tiếp theo (0.6.1)**: xem 11-E.

## 19/11/2026 tối · 0.6.1 · Claude Opus 5.5 (claude.ai + máy tính, 17:08–) + Google Antigravity
- **17:12** yêu cầu 0.6.1 (2 Excel + tệp đánh giá repo). Tóm tắt yêu cầu, hỏi 4 câu → chủ dự án chọn: Windows "tùy bạn" (→ Win 10/11 x64), 3 APK như 0.6.0, dọn thư mục + BUILDING.md, giao diện Mangayomi mới trên nhánh riêng.
- **17:18** chủ dự án: xin đủ quyền (đã cấp), giao Antigravity /swarm, tự lưu 5 phút → autosave_progress_061 (lần đầu không chạy vì Start-Process không bọc ngoặc kép đường dẫn).
- **17:25** /swarm 1 (kho tiện ích + nguồn cập nhật) – xong ~17:40, có mã HTTP thật.
- **17:27** dọn repo `git rm --cached` (6.136 → 2.500 tệp theo dõi), BUILDING.md.
- **17:29** chủ dự án bổ sung: bộ lọc ô chọn chọn nhiều + Thể loại DamCoNuong → sửa MihonInvoker.kt (KeiSource), `_convertFilters`, `multi_select_search.dart`.
- 17:45–18:09: chứng chỉ Let's Encrypt (kohiden), Google Drive 2 tùy chọn, Short cho mọi tiện ích, GIF Viewer, i18n 324 bản dịch, trang chủ ↔ chính sách, README nháp, 5 kho gợi ý; mọi test ĐẠT.
- **18:10–18:11** dây chuyền 0.6.1 (lần 1 lỗi sync do tag v0.6.1) → lần 2 chạy: test 950/950, apk, tv, win, pack, a6build…
- **18:40–18:56** Note 9 mất adb → chủ dự án cắm lại, `adb kill-server` mới thấy. Kiểm Note 9 (Short-all, Drive 2 tùy chọn, GIF Viewer, DamCoNuong qua Tor) ĐẠT; trang DamCoNuong bị nhà mạng chặn.
- **20:03** chủ dự án: giao thêm /swarm 2 (kiểm README/changelog/link bằng mã). Windows Setup.exe cài đè 0.5.9 → 0.6.1 ĐẠT, GIF Viewer + Drive trên Windows ĐẠT.
- **20:08** chủ dự án: tự lưu 3 phút/lần.

- **20:31** phiên mới nhận bàn giao (đọc Second Brain 00→12, AGENTS, ghi chú 0.6.1): dây chuyền xong 20:20, /swarm 2 ĐẠT; so 43 tệp overlay ↔ bản dựng giống hệt.
- **20:36–20:53** AVD Android 6.0: 2 lần hết giờ do `ANDROID_SDK_ROOT` sai SDK → sửa, máy ảo lên 41 s; APK android6 cài + chạy ĐẠT (ảnh evidence/avd6).
- **20:38** chủ dự án: xin đủ quyền (máy tính + phát hành GitHub), giao Antigravity /swarm 3 (theo dõi Release + kiểm link sau phát hành).
- **20:43** README + trang chủ sang v0.6.1 (autosave đẩy `37771d5`). **20:54–21:05** phát hành GitHub Release v0.6.1: 19/19 tệp khớp; xác minh API độc lập.
- **20:55–21:05** APK TV x86_64 trên AVD API 34 (dọn 4 emulator thừa): chỉ Phim & Điện ảnh – ĐẠT (ảnh evidence/avdtv).
- **21:10** ghi chú kỹ thuật mục 16–21, Second Brain 03/04/05/11/12; dừng autosave 0.6.1.
- **Tiếp theo (0.6.2)**: xem 11-F.
