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

## 19–20/11/2026 · 0.6.2 · Claude Opus 5.5 (claude.ai + máy tính, 22:05–) + Google Antigravity
- **22:05** yêu cầu 0.6.2 (log 16–19/11 + 2 Excel). Tóm tắt, chủ dự án 22:11 "Đồng ý toàn bộ" (Windows 10/11 x64), giao Antigravity /swarm, tự lưu 5 phút.
- **22:12–22:16** quyền máy tính; script `*_062`, `pubspec 0.6.2+55`, autosave_062 (5 phút).
- **22:16** /swarm 1 (giao diện Mangayomi 0.9.96 + bộ lọc mới) – dừng lượt phân tích cũ của Antigravity rồi "Send Now"; xong 22:32.
- **22:20–22:35** giải stack log bằng symbols_061 → lỗi văng bool→double (PageStorage ExpansionTile) – sửa `YomiFilterStorageScope`, test + đối chứng mã cũ tái hiện lỗi. Sửa bộ lọc không tải, Kotatsu CDN Cloudflare, nhãn log, pending_062.
- **22:35–22:50** tích hợp bộ lọc mới (sửa classifier 4 ca trượt), giao diện YomiHub New Version (theme, nav nổi, thẻ bìa); i18n 35 chuỗi × 18.
- **22:43** chủ dự án: /swarm 2 dịch theo ngôn ngữ Aniyomi/Nekoyomi/Kotatsu → 52 mã xong 00:04; Claude tích hợp 48 (bỏ ceb, eo, jv, nn).
- **22:57** dây chuyền lần 1 (test 979/982 – 3 test nhãn cũ) → sửa → 23:16 lần 2 (test 981/982, yh_017 mạng) → 23:24 chạy tiếp từ apk; apk xong 00:05, tv đang chạy.
- **23:13** chủ dự án cho phép tự đẩy GitHub + Release khi xong. **23:19** lịch kiểm tra 1h31. **00:03** giao thêm /swarm 3 (Feature Check, README/changelog, tên mục 48 ngôn ngữ).
- **00:08** chủ dự án: lưu tiến độ ngay → commit + push.
- **Tiếp theo**: kiểm Note 9 với APK arm64; tích hợp /swarm 3; dựng lại lần cuối (có 48 ngôn ngữ); kiểm Windows/AVD 6/TV; phát hành v0.6.2.

## 20/11/2026 · 0.6.2 (tiếp) · Claude Opus 5.5 (claude.ai + máy tính, 00:21–06:50) + Google Antigravity
- **00:21** chủ dự án: kiểm tiến độ, xin đủ quyền (máy tính + GitHub), giao Antigravity /swarm, tiếp tục. Đọc Second Brain 00→12, AGENTS, mục 0.6.2; cấp quyền computer use 00:26.
- **00:22–00:28** duyệt /swarm 3; giao /swarm 4 (Note 9 + đối chiếu log). **00:29** tên 3 mục cho 48 ngôn ngữ + test. **00:30** dừng dây chuyền cũ (chưa có 48 ngôn ngữ), **00:40** dựng lại lần cuối.
- **00:42** Antigravity hết AI credits (Argon) → đổi Gemini 3.8 Flash, gửi lại 00:44; worker hết credits lần 2 ~01:05 sau kịch bản 4; @log_analyst xong (25 nhóm lỗi, không còn lỗi mã cần sửa ngay).
- **00:46 / 01:53 / 02:39** dây chuyền dừng 3 lần (test gắn cứng 18 ngôn ngữ; `yh_055` chập chờn; thiếu changelog) → sửa, chạy tiếp từng phần; verify XONG 03:34.
- **01:52–02:24** Claude kiểm APK cuối trên Note 9 (bộ lọc cũ/mới, hồi quy văng, Polski, Drive). **03:07** Windows Setup.exe cài đè ĐẠT. (Máy không phản hồi ~03:10–06:00.)
- **06:04–06:30** AVD Android 6 ĐẠT; AVD TV cài + màn hình chờ (máy ảo mất do xung đột adb). **06:38–06:45** phát hành **GitHub Release v0.6.2** (19/19 tệp), `latest` = v0.6.2.
- **Tiếp theo (0.6.3)**: xem 11-G và ghi chú 0.6.2 › 18.

## 20/11/2026 · 0.6.3 · phiên 2 · Claude Opus 5.5 (claude.ai + máy tính, 10:29–) + Google Antigravity
- **10:29** chủ dự án gửi `logs (12).txt` + 3 Excel (thêm `Ke_Hoach_App_Quan_Ly_Tu_Sach_Ca_Nhan.xlsx`): kiểm tiến độ, xin đủ quyền (máy + GitHub), /swarm cho Antigravity, tiếp tục. Đọc Second Brain 00→12, AGENTS, ghi chú 0.6.2, `PROGRESS_063.md` (phiên 1 sáng nay đã làm Tủ Sách, auto-Tor, giao diện thích ứng, dây chuyền lần 2 đang chạy).
- **10:33** quyền computer use; **10:37** /swarm 3 (log + Feature Check + sửa tiện ích). Note 9 adb offline → **10:46** chủ dự án: kiểm thử trên Xiaomi 15T qua Phone Link; **11:17** dùng Phone Link gửi file.
- **10:58–11:20** sửa 4 lỗi app theo `LOG_COVERAGE_063.md` + test; dừng dây chuyền lần 2, dựng lần 3.
- **11:20–11:45** Xiaomi: gửi APK qua Chia sẻ → Xiaomi 15T, cài đè, kiểm Tủ Sách, DamCoNuong, VPN, nhật ký ĐẠT.
- **11:28/11:53/12:24** chủ dự án báo Thể Loại vẫn ⓘ → sửa chuyển đổi TriState (dựng lần 4) → phát hiện bộ lọc đã lưu trong Isar → tự sửa khi đọc (dựng lần 5, 12:36).
- **11:55–12:38** repo tiện ích: Anime47 (`?genres=<id>`), commit cục bộ cùng Hako/FikFap/Phimmoi; AVSub bị chặn DNS.
- **13:04** chủ dự án: lưu tiến độ → commit + push.
- **Tiếp theo**: xem `audit/audit-0.6.3/notes/PROGRESS_063.md` mục "Còn lại".

## 20/11/2026 · 0.6.3 · phiên 3 · Claude Opus 5.5 (claude.ai + máy tính, 13:15–) + ChatGPT Codex
- **13:15** chủ dự án: phân tích tiến độ các phiên trước, xin đủ quyền (máy + GitHub), giao ChatGPT Desktop – Codex bằng /swarm. Đọc Second Brain 00/07/08/09/11/12 + PROGRESS; quyền computer use 13:17.
- **13:20** Codex /swarm 1 (rà mã, nháp ghi chú, thống kê, kiểm duyệt) – xong 13:24. **13:28–13:40** sửa 9 lỗi theo REVIEW_CODE (Tủ Sách, auto-Tor, trang Cập nhật), test 23/23. **13:30** dừng dây chuyền lần 5 (bước tv), **13:44** dựng lần 6 (bản phát hành).
- **13:38–13:50** Xiaomi 15T (APK lần 5) ĐẠT: Thể Loại DamCoNuong, Hako, trang Cập nhật, nhật ký. **13:52** đẩy Extension Repo `9d4b588`.
- **14:26** APK lần 6 xong; Phone Link đòi cấp lại quyền chiếu màn hình (chưa cấp). **14:51** Note 9 vào lại adb → kiểm APK lần 6 (Tủ Sách hàng loạt + Cần mua, công tắc Tor, nhật ký 0 ERROR) có ảnh + 2 video.
- **15:04–15:25** tv/wintest/win/pack xong; Windows Setup.exe cài đè 0.6.2 → 0.6.3+56, Tủ Sách có trên Windows ĐẠT. TECHNICAL_UPDATE_NOTES mục 0.6.3 thêm Phiên 3 + Tổng hợp; Second Brain 04/06/09/11/12.
- **15:55–16:05** dây chuyền lần 6 XONG → commit `1cb297d` (README ← README_063) → **GitHub Release v0.6.3** 19/19 asset (kiểm API + tải APK 200 + Pages) → Second Brain 11 mục I, `6bc0b13`.
- **19:23** chủ dự án: thêm tính năng mới lên Trang Chủ → mục "Có gì mới trong 0.6.3" (`3f7b5a6`).
- **20:07–20:44** website: 20:07 thêm trang Hướng Dẫn + menu chuyển liền mạch 3 trang, nền tảng logo + banner; 20:12 chia việc Antigravity (thiết kế) + Codex (nội dung 17 chương, soát Trang Chủ); 20:29 thêm trang Tải Về chỉ chứa link bản cài (Antigravity khung + menu 4 mấu, Codex nội dung 18 tệp + đối chiếu Release). Claude ghép, sửa SHA mẫu giả, nút Chép, tràn ngang; Playwright kiểm; `80c0b8e`; Pages 200 cả 4 trang.
- **20:46** chủ dự án: cập nhật A.I Brain → 03, 04, 06, 07 (quy tắc website 22–26), 09, 10, 11, 12.
- **Tiếp theo (0.6.4)**: xem `TECHNICAL_UPDATE_NOTES.md` 0.6.3 › 4 "Còn mở"; mỗi bản mới cập nhật `download.html` (href, dung lượng, SHA) + "Có gì mới" trên Trang Chủ.

- **20:50–21:20** chủ dự án: website song ngữ Việt / Anh cho 4 trang, chia ChatGPT Desktop + Google Antigravity. Codex dịch index/download/guide rồi hết hạn mức → Antigravity nhận nốt privacy EN + rà soát + bảng thuật ngữ. Claude ghép nút VI | EN + hreflang vào 4 trang EN, sửa chuỗi phiên bản, placeholder ô tìm cả 2 ô, tràn 390px; Playwright 8 trang × 1280/390/tối + kiểm giữ #anchor, nhớ lựa chọn, dải gợi ý; sao lưu `docs` → `backup/manual/docs_2120/`; README thêm link English; `93c9bbf`; Pages 200 cả 8 trang (en/download 18 link, en/guide 17 chương).

## 21/11/2026 · 0.6.4 · phiên 2 · Claude Opus 5.5 (claude.ai + máy tính, 19:33–) + Google Antigravity
- **19:33** chủ dự án gửi log 13 + 3 Excel: phân tích tiến độ, xin đủ quyền, /swarm chia Antigravity + Codex, lưu phiên 5 phút/lần cho cả 3. Đọc Second Brain 00→12, AGENTS, ghi chú 0.6.4, PROGRESS (dây chuyền lần 2 đang dựng TV).
- **19:40–19:46** quyền computer use; Antigravity hết credits (cả Claude Sonnet 5.5), Codex hết hạn mức; autosave 064b (5 phút, gồm ghi chú tác nhân).
- **19:55** chủ dự án bỏ Codex → Claude rà mã (0 lỗi Cao/TB), soạn trang chủ 0.6.4 VI/EN nháp, pending_065.
- **20:04** /swarm 4 (8 nguồn + 48 ngôn ngữ) – xong 20:45. **20:52** Note 9 adb về device sau khi đóng Samsung DeX; cài 0.6.4. **20:59** /swarm 5 (Note 9 S1–S7 + nháp Hướng Dẫn) – xong 21:37.
- **20:44–21:16** Windows Setup.exe cài đè 0.6.4+57; Tủ Sách thanh tin NXB khớp 4 tin Kim Đồng, ẩn/hiện lại tin ĐẠT; AMAK 404 → 0.6.5. **21:01** chủ dự án: 48 ngôn ngữ phụ để 0.6.5, xong thì đẩy GitHub.
- **21:39** dây chuyền XONG → changelog bổ sung + SHA → website/README `f569ed5` → Extension Repo push 21:47 → Release v0.6.4 (21:46–).
- **Tiếp theo (0.6.5)**: 11-J.

## 24–25/11/2026 · 0.6.5 · Claude Opus 5.5 (claude.ai + máy tính) + Google Antigravity + ChatGPT Codex + GitHub Copilot
- **24/11 chiều–tối**: tóm tắt yêu cầu 0.6.5, chủ dự án chọn Windows 10/11 x64, đồng ý phát hành; /swarm 3 bên (Codex: LOG/FEATURE/README; Copilot: REVIEW; Antigravity: i18n 65 ngôn ngữ ×2 đợt). Sửa overlay theo log 14/15 + sheet (xem TECHNICAL_UPDATE_NOTES "0.6.5"). Dropbox app YomiHub (icon 64/256 qua Chooser, Apply for production cần tài khoản test → chủ dự án tự điền).
- **25/11 00:30–02:40**: Dropbox (Cốc Cốc), gộp 2 376 bản dịch, Copilot REVIEW_r3 (49 điểm, 2 nghiêm trọng – Claude kiểm rồi sửa N1/N2/V1/V5/V6/PERF), dựng lần 1 (02:41).
- **02:50–05:15**: test yh_053 (repo mới) → dựng lại; Antigravity vòng 1 nộp ảnh chữ tự dựng → không nhận; phát hiện logo TV ô vuông → icon-glyph.
- **06:42** máy khởi động lại → BUILD_LOCK treo → gỡ; **07:55–08:05** vòng 2 Antigravity chạm mù TikTok/TeamViewer trên Note 9 → STOP_DEVICE, Claude tự kiểm Note 9 (uiautomator theo nhãn); phát hiện bộ lọc Quốc Gia không nhận "Type: Manga/Manhwa/Manhua" → sửa.
- **09:35–09:50** Copilot REVIEW_r6 + RELEASE_PRECHECK (repo mặc định script sai, comic/mã ngôn ngữ) → sửa, đồng bộ vào build+buildwin khi main4 đang test.
- **09:46–11:38** dựng main4 (1044/1044 test, verify OK, SHA 17/17); kiểm thử ảnh thật: Note 9 (Claude), TV/Windows/Android 6 (Antigravity) – Claude xem từng ảnh.
- **12:06–12:16** docs/README/Second Brain → commit `dc850f3` → **Release v0.6.5** (19 tệp, kích thước khớp) → Pages download VI/EN 200, 38 link v0.6.5.
- **Tiếp theo (0.6.6)**: copilot/patches_066 (V2–V4, V8–V15), che bí mật JSON/header, A7 sao lưu hiển thị Danh Mục, Microsoft client ID (OneDrive dựng sẵn), nhãn sheet ảnh màn hẹp, Dropbox production (chủ dự án).

## 25–26/11/2026 – YomiHub 0.6.6 (Claude Opus 5.5 + Antigravity + Codex + Copilot)
- **21:14–22:40**: phạm vi lỗi log 16, ApkBridge/MES, phần dở 0.6.5, Tủ Sách; chia 4 phần (/swarm). Copilot hết credit, Codex hết lượt (21:57); Antigravity r1–r3 (kho, vBook, UI che nút 19 mục, review 14 điểm, i18n 65 ngôn ngữ). Claude áp và sửa các bản vá hỏng (review_02/03/04, ui_02).
- **22:40–23:01**: Antigravity cũng hết quota → Claude tự làm UI-11/15–19 + 3 khóa A7×65; a08 analyze 0 lỗi, test đạt.
- **23:01–03:28**: dựng 3 lần (test yh_057_t4 theo nền tảng; pack ghi cứng +58) → 17 gói, SHA 17/17.
- **00:16–00:45** Antigravity r4 review 7 tệp UI (1 TB → r4_01 để bản sau). **01:32** Note 9 ĐẠT. **02:57** chủ dự án dừng điều khiển máy tính; **05:51** "Tiếp tục" → Claude kiểm AVD TV/Android 6 bằng job adb, đẩy repo tiện ích `8cfe2be`.
- **06:19–07:05**: Release v0.6.6 (19 asset), README + Pages VI/EN 0.6.6.
