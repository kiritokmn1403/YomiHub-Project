# Cấu trúc thư mục dự án

## Gốc dự án: `D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project` (Git: `kiritokmn1403/YomiHub-Project`)
| Đường dẫn | Nội dung |
|---|---|
| `A.I Brain - Second Brain/` | Kiến thức bắt buộc đọc (00–10) |
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` | Quy định cho tác nhân (trỏ tới Second Brain) |
| `TECHNICAL_UPDATE_NOTES.md` | Ghi chú kỹ thuật & nhật ký mọi phiên bản (bắt buộc đọc) |
| `README.md` | Giới thiệu + nút Download → releases/latest |
| `docs/` | GitHub Pages: `index.html` (trang chủ, nút tải từng bản), `privacy.html`, favicon/icon |
| `overlay/` | **Mã YomiHub** (`lib/`, `lib/yomihub/`, `android/`, `windows/`, `assets/yomihub_i18n/`, `test/`, `pubspec.yaml`) |
| `src/` | Nền Mangayomi upstream (`mangayomi`, `mangayomi-0.9.95`, `v0.9.7`, `BASE_VERSION.txt`) |
| `build/` | Script dựng `build_<ver>.ps1`, `build_<ver>_android.ps1`, `build_<ver>_android6.ps1` |
| gốc | `run_<ver>_main.ps1`, `sync_<ver>.ps1`, `make_installer_exe_<ver>.ps1`, `make_appxbundle_<ver>.ps1`, `release_<ver>.ps1`, `common.ps1`, `yh_defines.ps1`, `setup_tools.ps1`, `run_jobs.ps1`, `run_jobs_fast.ps1`, `ensure_runners.ps1`, `0_probe.bat`…`3b_run_fast_jobs.bat` |
| `jobs/` | Hàng đợi runner: `pending/`, `pending_fast/`, `done/` (log), thư viện `q059_lib.ps1`, `q059_dev.ps1`; `STOP_AUTOSAVE` (git-ignored) |
| `scripts/` | `autosave_progress_<ver>.ps1`, nhóm `build/`, `checksums/`, `media/`, `packaging/`, `pipeline/`, `qa/`, `release/`, `sync/`, `test/` |
| `audit/audit-<ver>/` | Mỗi phiên bản: `input/` (Excel→JSON đã che), `notes/` (NOTES, i18n), `coordination/` (PROGRESS, BUILD_LOCK ở 0.5.6), `release/` (trạng thái dựng, changelog, manifest), `evidence/` (ảnh/video/log – git-ignored), `backup/`, `antigravity/` (báo cáo Antigravity), `apkpure/` (tư liệu cửa hàng) |
| `output/<ver>/` | Bộ cài đã dựng (git-ignored, tải lên Release) |
| `logs/` | Log dựng/autosave (git-ignored; có thể chứa dòng lệnh dart-define) |
| `secrets/` | `google_oauth.json` (git-ignored) |
| `logo/` | Logo gốc 1024; icon ứng dụng thật ở `overlay/assets/app_icons/icon-red.png` |
| `archive/`, `_old/`, `_to_delete/`, `work-0.1.8/`, `dev/`, `bug/`, `fetch/`, `test/`, `Screenshot/` | Lưu trữ cũ/thử nghiệm – không dùng cho bản mới |
| `yomihub-release.jks`, `keystore-password.txt` | Khóa ký – KHÔNG đọc/in/đẩy (git-ignored) |

## Máy dựng: `D:\yh` (junction → `D:\A.I Project\yh`)
- `build\mangayomi` (Android/TV), `buildwin\mangayomi` (Windows), `build23\mangayomi` (Android 6)
- `tools\` (Flutter 3.47.6, SDK…), `pub-cache\`, `gradle-home\`, `avd\`, `symbols_<ver>`, `symbols_tv_<ver>` (ký hiệu giải stack), `qa<ver>win\` (Windows portable thử)
- Các thư mục `aa00x*` là của dự án khác (Extension Repo/vBook…) – không đụng.

## Thư mục liên quan khác trong `D:\A.I Project\`
- `A.I Project - Extension Repo\Kiritokmn - Extension Repo\` – repo tiện ích (`sources/`, `.build/test/`, `repo/`, `_work/NOTES_swarm_<ver>.md`, Second Brain riêng `A.I Brain - Second Brain/`).
- `GitHub\` – mã tham khảo các dự án GitHub; `Claude outputs\` – ảnh/tệp bàn giao cũ; `A.I Project - YomiHub Project\` – gốc chứa `YomiHub-Project`, `output/`, `TECHNICAL_UPDATE_NOTES.md` cũ.
