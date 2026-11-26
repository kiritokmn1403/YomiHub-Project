# Quy trình bàn giao dự án

Áp dụng khi: kết thúc một phiên bản, kết thúc phiên làm việc (hết hạn mức, máy ngủ, chuyển sang tác nhân/phiên khác), hoặc bàn giao cho chủ dự án/người khác.

## A. Bàn giao cuối phiên làm việc (giữa chừng một phiên bản)
1. **Dừng an toàn**: không để job dựng chạy dở mà không ghi lại; nếu buộc phải dừng tiến trình dựng thì xóa nội dung `audit/audit-0.5.6/coordination/BUILD_LOCK.txt`.
2. **Ghi trạng thái** vào `TECHNICAL_UPDATE_NOTES.md` (mục phiên bản đang làm) và `audit/audit-<ver>/coordination/PROGRESS_<ver>.md`:
   - việc đã xong (kèm tệp sửa, test, bằng chứng), việc đang dở (dừng ở bước nào, job nào trong `jobs/pending*`), việc chưa làm;
   - trạng thái bản dựng (`main_build_status_<ver>.txt`), các tác nhân/Antigravity đang chạy và tệp NOTES của chúng.
3. **Thêm một mục vào `12_session log_nhat_ky_phien_lam_viec.md`** (ngày, tác nhân, yêu cầu, đã làm, kết quả, việc tiếp theo).
4. **Lưu lên GitHub**: commit có chọn lọc (notes, overlay, docs, Second Brain, audit trừ evidence/input/backup) và push.
5. **Tắt tác vụ nền**: lịch hẹn kiểm tra, autosave (`jobs/STOP_AUTOSAVE`), theo dõi của Antigravity; ghi lại nếu cố ý để chạy tiếp.
6. **Báo chủ dự án** (tiếng Việt): đang ở đâu, phiên sau bắt đầu từ đâu, việc chủ dự án cần làm (đăng nhập, xác nhận, cài tay…).

## B. Bàn giao một phiên bản (sau phát hành)
Danh sách kiểm:
- [ ] `output/<ver>/` đủ gói + `SHA256SUMS-<ver>.txt` + changelog; verify ĐẠT.
- [ ] GitHub Release `v<ver>` (make_latest) đủ asset, kích thước khớp; README + trang chủ trỏ đúng bản mới nhất.
- [ ] Repo tiện ích đã push (nếu đổi); APKPure đã tải phiên bản mới (nếu có kênh này).
- [ ] Kiểm thử thiết bị thật (Note 9, Windows) có ảnh/video/log trong `audit/audit-<ver>/evidence/`.
- [ ] `TECHNICAL_UPDATE_NOTES.md`: dòng tóm tắt ở mục 1 + nhật ký chi tiết + mục "Còn mở".
- [ ] Second Brain: bài học mới (04), công cụ mới (06), quy trình/quy tắc thay đổi (02/03/05/07), nhật ký phiên (12).
- [ ] Tất cả đã push; lịch hẹn/autosave/Antigravity đã tắt.
- [ ] Báo cáo cuối cho chủ dự án: đã phát hành gì, kết quả kiểm, việc còn mở, việc chủ dự án cần tự làm.

## C. Nhận bàn giao (phiên/tác nhân mới)
1. Đọc Second Brain 00 → 12, `AGENTS.md`, mục 1 + mục phiên bản đang làm của `TECHNICAL_UPDATE_NOTES.md`.
2. Đọc mục mới nhất của `12_session log...` và `PROGRESS_<ver>.md`.
3. Kiểm thực tế: `main_build_status_<ver>.txt`, `jobs/pending*`, `jobs/done/` (job mới nhất), `logs/`, `git log -5`, `audit/audit-<ver>/antigravity/NOTES_*`; runner còn sống (`jobs/runner_*_alive.txt`).
4. Tóm tắt trạng thái cho chủ dự án rồi tiếp tục từ việc dở dang đầu tiên.

## D. Trạng thái bàn giao hiện tại (sau 0.5.9 – 18/11/2026)
- 0.5.9 (0.5.9+52) đã phát hành GitHub Release 14:17; gửi duyệt APKPure 16:36 (chờ kết quả; chủ dự án cần liên kết email trong APKPure Console).
- Còn mở cho 0.6.0: kho `kohiden.xyz` lỗi chứng chỉ; thêm kho Salmanbappi/Secozzi vào `repo_discovery.dart`; 5 liên kết công cụ tấn công cũ trong Dự án GitHub chờ quyết định gỡ; các mục lớn của sheet YomiHub Update chưa tích hợp hết (quét Yomikiru/Nyora/Nuvio/Frank Yomik/Browser Fingerprint…).
- Xiaomi của chủ dự án đang chạy APK android6 → cần cài tay APK thường 0.5.9 một lần.
- Không còn tác vụ nền chạy (autosave dừng 14:29, lịch hẹn tắt). Tệp `jobs/STOP_AUTOSAVE` còn – xóa trước khi bật lại autosave.

## E. Trạng thái bàn giao hiện tại (sau 0.6.0 – 19/11/2026 15:35) – thay mục D
- 0.6.0 (0.6.0+53) đã phát hành GitHub Release `v0.6.0` 15:29 (19 asset khớp kích thước; Pages đã bật sẵn). KHÔNG đẩy Kiritokmn Extension Repo (chủ dự án: để phiên khác). Chưa gửi APKPure bản 0.6.0 (0.5.9 vẫn chờ duyệt).
- Còn mở cho 0.6.1: kho `kohiden.xyz` CERTIFICATE_VERIFY_FAILED; `yh_055` Case 1 chập chờn khi máy quá tải (cân nhắc nới thời gian); giao diện mới Mangayomi v0.9.96 (cần Flutter 3.50) + Frank Yomik/Browser Fingerprint/Anti-bot chưa tích hợp; nguồn APK trên Windows cần bản full (M-Extension-Server); Antigravity /swarm 4 chưa xong kịch bản 5 (Savior quét link) và 6 (rà log) – xem `audit/audit-0.6.0/antigravity/NOTES_swarm3_device_tester.md`.
- Note 9 đã cài 0.6.0 (2053) + Antigravity đã cài thêm tiện ích "ComicK (Kotatsu)" để kiểm. Xiaomi của chủ dự án vẫn cần cài tay APK thường (nếu còn chạy bản android6).
- Sau phát hành (15:38–16:12): README theo mẫu Standard; `.ps1`/`.bat` đã chuyển vào `scripts/<nhóm>/`, ảnh/logo vào `assets/` (icon trang chủ `docs/assets/`); `scripts/lib/yh_defines.ps1` chỉ còn cục bộ (git-ignored, bản cũ còn trong lịch sử commit `22405f2` – không chứa secret). Runner mở bằng `scripts\runner\3_run_jobs.bat` / `3b_run_fast_jobs.bat` (hoặc `scripts\runner\ensure_runners.ps1`). Bộ script cho 0.6.1: chép `scripts/{pipeline,sync,build,packaging,release}/*_060*` → `*_061*` và đổi chuỗi phiên bản (xem 03).
- Tác vụ nền: autosave 0.6.0 dừng bằng `jobs/STOP_AUTOSAVE_060` (15:35); lịch hẹn kiểm tra đã xong/không còn.

## F. Trạng thái bàn giao hiện tại (sau 0.6.1 – 19/11/2026 21:10) – thay mục E
- 0.6.1 (0.6.1+54) đã phát hành GitHub Release `v0.6.1` 21:05 (19 asset khớp kích thước, `releases/latest` = v0.6.1). README + trang chủ trỏ v0.6.1. KHÔNG đẩy Extension Repo, KHÔNG gửi APKPure.
- Đã kiểm: Note 9 (arm64), Windows 11 (Setup.exe cài đè), AVD Android 6.0 (android6 x86_64), AVD API 34 (TV x86_64). Chưa kiểm sâu tính năng trên Android 6/TV; chưa thử `.appxbundle` 0.6.1.
- Còn mở cho 0.6.2: xem `TECHNICAL_UPDATE_NOTES.md` mục 0.6.1 › 21 (giao diện Mangayomi v0.9.96 Flutter 3.50 trên nhánh riêng – `src/mangayomi-0.9.96/` đã có; `pending_062/`; KeiSource trên Windows; Frank Yomik; ghim toolchain/YH_ROOT; AVD TV x86_64).
- Tác vụ nền: autosave 0.6.1 dừng bằng `jobs/STOP_AUTOSAVE_061`; máy ảo đã tắt; Antigravity /swarm 3 xong (xem `audit/audit-0.6.1/antigravity/VERIFICATION_swarm3_061.md`).

## G. Trạng thái bàn giao hiện tại (sau 0.6.2 – 20/11/2026 06:50) – thay mục F
- 0.6.2 (0.6.2+55) đã phát hành GitHub Release `v0.6.2` 06:45 (19 asset khớp kích thước, `releases/latest` = v0.6.2). README + trang chủ trỏ v0.6.2. KHÔNG đẩy Extension Repo, KHÔNG gửi APKPure.
- Đã kiểm: Note 9 (APK arm64 cuối – New Version, bộ lọc cũ/mới, hồi quy bool→double, Polski, Drive 2 tùy chọn, nhãn log), Windows 11 (Setup.exe cài đè, bộ lọc mới), AVD Android 6.0 (mở app), AVD API 34 (APK TV cài + màn hình chờ).
- Còn mở cho 0.6.3: `TECHNICAL_UPDATE_NOTES.md` mục 0.6.2 › 18.
- Tác vụ nền: autosave 0.6.2 dừng bằng `jobs/STOP_AUTOSAVE_062`; lịch hẹn kiểm tra đã hết; máy ảo đã tắt; Antigravity hết credits tới 26/11.

## H. Trạng thái bàn giao hiện tại (0.6.3 đang làm – 20/11/2026 13:05) – thay mục G
- 0.6.3 (0.6.3+56) CHƯA phát hành; dây chuyền lần 5 đang chạy (`x063_build_main5`). Tiến độ chi tiết: `audit/audit-0.6.3/notes/PROGRESS_063.md` (cuối tệp).
- Kiểm thử thiết bị: Note 9 không vào được adb (lỗi ủy quyền phía máy) → dùng Xiaomi 15T qua Phone Link (xem 06).
- Repo tiện ích có 2 commit cục bộ chưa push (`edf2fbd`, `9d4b588`); chủ dự án đã đồng ý đẩy sau khi kiểm thử Xiaomi.
- Antigravity hết AI credits tới 20/11 14:11.

## I. Trạng thái bàn giao hiện tại (sau 0.6.3 – 20/11/2026 16:05) – thay mục H
- 0.6.3 (0.6.3+56) đã phát hành GitHub Release `v0.6.3` 16:04 (19 asset khớp kích thước, `releases/latest` = v0.6.3). README (19 link v0.6.3 + nút Download → releases/latest) và trang chủ/chính sách (GitHub Pages 200) trỏ v0.6.3. Commit `1cb297d`. Kiritokmn Extension Repo đã đẩy `9d4b588`. KHÔNG gửi APKPure.
- Đã kiểm: Xiaomi 15T (APK 10:58 + lần 5), Note 9 (APK lần 6 – bản phát hành), Windows 11 Setup.exe (lần 6). Chưa kiểm sâu: APK TV và android6 trên AVD (chỉ dựng + verify), `.appxbundle`, nhập CSV Tủ Sách trên máy thật.
- Còn mở cho 0.6.4: `TECHNICAL_UPDATE_NOTES.md` mục 0.6.3 › 4 "Còn mở" + log Windows 6 ERROR 404 kho `MiraiEnoki/anymex_extensions`, `Schnitzel5/sugoi-modules` (kho người dùng thêm đã chết).
- **Website (20/11 20:44, commit `80c0b8e`)**: GitHub Pages 4 trang Trang Chủ (`index.html`) · Tải Về (`download.html`) · Hướng Dẫn (`guide.html`, 17 chương) · Chính Sách (`privacy.html`) – thiết kế theo logo + banner, menu mấu đánh dấu trang; link tải chỉ ở trang Tải Về (18 tệp, SHA-256 khớp Release). Mỗi bản mới: cập nhật theo 03 › "Bổ sung 20/11/2026 (website)".
- Tác vụ nền: autosave 063 dừng bằng `jobs/STOP_AUTOSAVE_063`; lịch hẹn kiểm tra đã hết; Codex /swarm 1–3 xong; Antigravity /swarm 4–5 (website) xong – còn chạy được bằng Gemini 3.8 Flash.

## J. Trạng thái bàn giao hiện tại (sau 0.6.4 – 21/11/2026 ~22:00) – thay mục I
- 0.6.4 (0.6.4+57) phát hành GitHub Release `v0.6.4` (21:46–22:22, 19 asset khớp kích thước, `releases/latest` = v0.6.4, Pages 200 – xác minh độc lập 22:25). README + website VI/EN (`f569ed5`) trỏ v0.6.4. Kiritokmn Extension Repo đẩy 6 commit (đến `39d60ed`). KHÔNG gửi APKPure.
- Đã kiểm: Note 9 (Antigravity S1–S7 + Claude đối chiếu ảnh/log), Windows 11 Setup.exe cài đè + Tủ Sách thanh tin NXB. Chưa kiểm: AVD Android 6/TV 0.6.4, `.appxbundle`, Xiaomi 15T (Phone Link chờ quyền chiếu màn hình).
- Còn mở cho 0.6.5: `audit/audit-0.6.4/pending_065/README.md` (48 ngôn ngữ phụ, 2 sửa REVIEW, bố cục Frank Yomik, AMAK 404) + nháp Hướng Dẫn `audit/audit-0.6.4/antigravity/web/guide_064_*`.
- Tác vụ nền: autosave 064b dừng bằng `jobs/STOP_AUTOSAVE_064b`; lịch hẹn kiểm tra đã hết; Antigravity /swarm 5 XONG; Codex không dùng.

## K. Trạng thái bàn giao hiện tại (sau 0.6.6 – 26/11/2026 ~07:15) – thay mục J
- 0.6.6 (0.6.6+59) phát hành GitHub Release `v0.6.6` (06:19–07:04, 19 asset khớp kích thước, `releases/latest` = v0.6.6, tag `3556145` = mã đã dựng – overlay khớp manifest 124/124). README + website VI/EN (download/index) chuyển 0.6.6 ở commit `31a3e15`, Pages download hiển thị 0.6.6.
- Đã kiểm: Note 9 (Claude), AVD TV API34 (APK armeabi-v7a), AVD Android 6 API23 – ảnh thật trong `audit/audit-0.6.6/evidence/`. Chưa chạy thử Windows (YomiHub.exe đang mở trên máy chủ dự án; mới kiểm tĩnh gói).
- Còn mở cho bản sau: `audit/audit-0.6.6/coordination/PENDING_REBUILD_066.md` (r4_01 bảng bộ lọc xoay ngang + bàn phím); Codex r2 (review diff cuối) chưa gửi vì quyền điều khiển máy tính bị dừng 02:57 – brief sẵn ở `audit/audit-0.6.6/codex/BRIEF_codex_066_r2.md`; Antigravity R4-3 kiểm thiết bị chưa làm (GO_DEVICE_066.txt đã tạo); 2 ghi chú Thấp của Antigravity về `mv2_manga_card` (lưới 3 cột 360 px, cỡ chữ lớn trên TV); repo tiện ích đã đổi tên thành `YomiHub-Project/YomiHub-Extension-Repo` (kiểm URL mặc định trong app).
- Tác vụ nền: autosave 066 dừng bằng `jobs/STOP_AUTOSAVE_066`; các lịch hẹn kiểm tra đã chạy hết.

## L. Cập nhật sau hotfix Windows 0.6.6+60 (26/11/2026 ~09:00) – bổ sung mục K
- Gói Windows trên Release v0.6.6 đã thay bằng 0.6.6+60: Setup.exe / `.zip` / `.appxbundle` đều kèm M-Extension-Server v1.1.1 + JRE 21; bỏ `-full.zip`; sửa cờ JVM `-XX:+UnlockDiagnosticVMOptions` (trước đó máy chủ không khởi động trên Windows từ 0.6.5). APK Android/Android 6/TV vẫn 0.6.6+59 (tag `v0.6.6` = `3556145`); mã hotfix nằm trên `main` sau tag.
- Quy tắc mới (07): mọi gói cài đặt phải tích hợp sẵn M-Extension-Server và ApkBridge.
- Còn mở: chuỗi `win_diag_screen.dart` còn nhắc `-full.zip`; chưa chạy thử YomiHub.exe 0.6.6+60 bằng giao diện với tiện ích APK thật (mới kiểm máy chủ kèm gói bằng đúng tham số app) – nhờ chủ dự án cài Setup.exe mới và mở 1 tiện ích Mihon/Aniyomi để xác nhận.
