# Quy trình làm việc một đợt cập nhật

1. **Đọc**: toàn bộ Second Brain (00–12) → `AGENTS.md` → `TECHNICAL_UPDATE_NOTES.md` (mục 1 + nhật ký bản đang làm) → tiến độ `audit/audit-<ver>/coordination/PROGRESS_*.md` nếu đang dở.
2. **Đầu vào**: chép Excel yêu cầu (`Project YomiHub.xlsx` – các sheet Feature Check, YomiHub Update, Website Update Apps, Extension Repo, Website Scan…; `Project GitHub.xlsx`) và log người dùng (`logs_N.txt`) vào `audit/audit-<ver>/input/`; xuất JSON **che tài khoản/mật khẩu** (sheet có tài khoản Anime47 – không chép ra ghi chú).
3. **Phân tích log**: nhóm lỗi theo loại (ERROR/WARNING lặp, treo UI, tiện ích, mạng/Tor, Cloudflare, cập nhật); xác định nguyên nhân trong mã trước khi sửa. Log mỗi dòng có nhãn phiên bản/thiết bị → biết đúng bản cài (vd. phát hiện máy Android 16 đang chạy APK android6).
4. **Lập kế hoạch & phân việc**: danh sách việc (TaskCreate), chia phần rời cho tác nhân/Antigravity (xem 09); mỗi phần có tệp NOTES ghi từng bước.
5. **Sửa mã trong `overlay/`** → đồng bộ sang bản dựng (`Sync-Overlay`) → `dart analyze` tệp đã sửa → test đơn vị mới `overlay/test/yh_<ver>_*_test.dart` qua job `pending_fast`.
6. **Ghi chú ngay**: mỗi lỗi/tính năng một mục trong `TECHNICAL_UPDATE_NOTES.md` (yêu cầu, nguyên nhân, tệp sửa, test, kết quả, giới hạn).
7. **Dựng bộ gói** (xem 03) → **kiểm thử thiết bị thật** (xem 05).
8. **Phát hành** khi chủ dự án xác nhận (xem 03, 07).
9. **Cập nhật kiến thức**: README/trang chủ nếu đổi tính năng, mục 1 ghi chú kỹ thuật, Second Brain đúng tệp; tự lưu/push lên GitHub.
10. **Bàn giao & nhật ký** theo 11 và 12, rồi **báo cáo** cho chủ dự án bằng tiếng Việt: đã xong gì, còn gì, việc chủ dự án cần làm.

## Hạ tầng thực hiện
- Máy Windows chạy 2 runner: `jobs/pending/` (dài – dựng) và `jobs/pending_fast/` (ngắn – test, adb, git). Job = `.ps1`, dòng 1 `# timeout: <phút>`; log `jobs/done/<tên>.log` (thường UTF-16LE, đôi khi UTF-8). `ensure_runners.ps1` / `3_run_jobs.bat`, `3b_run_fast_jobs.bat` bật lại runner.
- Thư viện job: `common.ps1` (PATH Flutter/JDK/SDK/Rust, `PUB_CACHE=D:\yh\pub-cache`), `yh_defines.ps1` (`--dart-define` Google OAuth từ `secrets/`), `jobs/q059_lib.ps1` (`Sync-Overlay`, `Run-Tests`, `Run-Analyze`), `jobs/q059_dev.ps1` (điều khiển Note 9).
- **Tự lưu tiến độ** (yêu cầu chủ dự án 18/11): `scripts/autosave_progress_<ver>.ps1` chạy nền, 3 phút commit + push có chọn lọc; dừng bằng `jobs/STOP_AUTOSAVE` (xóa tệp này trước khi bật lại); tự dừng sau 8 giờ.
