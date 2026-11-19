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
