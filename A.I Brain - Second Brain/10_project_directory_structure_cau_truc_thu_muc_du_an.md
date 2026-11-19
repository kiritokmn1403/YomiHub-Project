# Cấu trúc thư mục dự án

## Gốc dự án: `D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project` (Git: `kiritokmn1403/YomiHub-Project`)
| Đường dẫn | Nội dung |
|---|---|
| `A.I Brain - Second Brain/` | Kiến thức bắt buộc đọc (00–12) |
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` | Quy định cho tác nhân (trỏ tới Second Brain) |
| `TECHNICAL_UPDATE_NOTES.md` | Ghi chú kỹ thuật & nhật ký mọi phiên bản (bắt buộc đọc) |
| `README.md` | Giới thiệu + nút Download → releases/latest |
| `docs/` | GitHub Pages: `index.html` (trang chủ, nút tải từng bản), `privacy.html`; favicon/icon trong `docs/assets/` (phải nằm dưới `docs/` để Pages phục vụ) |
| `assets/` | Hình ảnh của dự án (19/11/2026): `logo/` (logo 1024 sáng/tối, `tv_banner.png`, `preview.png`, `make.py` sinh logo; icon ứng dụng thật ở `overlay/assets/app_icons/icon-red.png` – README dùng `assets/logo/yomihub_logo_1024.png`), `screenshots/` (ảnh chụp riêng – git-ignored). Ảnh/biểu tượng của chính ứng dụng vẫn ở `overlay/assets/`; ảnh kiểm thử ở `audit/audit-<ver>/evidence/`, `test/shots/` |
| `overlay/` | **Mã YomiHub** (`lib/`, `lib/yomihub/`, `android/`, `windows/`, `assets/yomihub_i18n/`, `test/`, `pubspec.yaml`) |
| `src/` | Nền Mangayomi upstream (`mangayomi`, `mangayomi-0.9.95`, `v0.9.7`, `BASE_VERSION.txt`) |
| gốc | Chỉ còn `.bat` khởi chạy (`0_probe.bat`…`3b_run_fast_jobs.bat`), tài liệu (`README.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `TECHNICAL_UPDATE_NOTES.md`), khóa ký (git-ignored). **Không đặt `.ps1` ở gốc** (sắp xếp 19/11/2026) |
| `jobs/` | Hàng đợi runner: `pending/`, `pending_fast/`, `done/` (log), thư viện `q0xx_lib.ps1`, `q0xx_dev.ps1` (dot-source `scripts\lib\common.ps1`); `STOP_AUTOSAVE` (git-ignored) |
| `scripts/` | Mọi script PowerShell (19/11/2026): `lib/` (`common.ps1` – `$KIT` = gốc dự án, `yh_defines.ps1`), `runner/` (`run_jobs.ps1`, `run_jobs_fast.ps1`, `ensure_runners.ps1` – tác vụ Windows "YomiHub runners" trỏ vào đây), `setup/` (`setup_tools.ps1`), `pipeline/` (`run_<ver>_main.ps1`), `sync/` (`sync_<ver>.ps1`), `build/` (`build_<ver>.ps1`, `build_<ver>_android.ps1`, `build_<ver>_android6.ps1`), `packaging/` (`make_installer_exe_<ver>.ps1`, `make_appxbundle_<ver>.ps1`), `release/` (`release_<ver>.ps1`), `autosave/` (`autosave_progress_<ver>.ps1`), `checksums/`, `media/`, `qa/`, `test/`. Script trong `scripts/<nhóm>/` tính gốc dự án = 2 cấp trên `$PSScriptRoot`; script bản cũ (≤ 0.5.7) chỉ để lưu trữ |
| `audit/audit-<ver>/` | Mỗi phiên bản: `input/` (Excel→JSON đã che), `notes/` (NOTES, i18n), `coordination/` (PROGRESS, BUILD_LOCK ở 0.5.6), `release/` (trạng thái dựng, changelog, manifest), `evidence/` (ảnh/video/log – git-ignored), `backup/`, `antigravity/` (báo cáo Antigravity), `apkpure/` (tư liệu cửa hàng) |
| `output/<ver>/` | Bộ cài đã dựng (git-ignored, tải lên Release) |
| `logs/` | Log dựng/autosave (git-ignored; có thể chứa dòng lệnh dart-define) |
| `secrets/` | `google_oauth.json` (git-ignored) |
| `archive/`, `_old/`, `_to_delete/`, `work-0.1.8/`, `dev/`, `bug/`, `fetch/`, `test/` | Lưu trữ cũ/thử nghiệm – không dùng cho bản mới |
| `yomihub-release.jks`, `keystore-password.txt` | Khóa ký – KHÔNG đọc/in/đẩy (git-ignored) |

## Máy dựng: `D:\yh` (junction → `D:\A.I Project\yh`)
- `build\mangayomi` (Android/TV), `buildwin\mangayomi` (Windows), `build23\mangayomi` (Android 6)
- `tools\` (Flutter 3.47.6, SDK…), `pub-cache\`, `gradle-home\`, `avd\`, `symbols_<ver>`, `symbols_tv_<ver>` (ký hiệu giải stack), `qa<ver>win\` (Windows portable thử)
- Các thư mục `aa00x*` là của dự án khác (Extension Repo/vBook…) – không đụng.

## Thư mục liên quan khác trong `D:\A.I Project\`
- `A.I Project - Extension Repo\Kiritokmn - Extension Repo\` – repo tiện ích (`sources/`, `.build/test/`, `repo/`, `_work/NOTES_swarm_<ver>.md`, Second Brain riêng `A.I Brain - Second Brain/`).
- `GitHub\` – mã tham khảo các dự án GitHub; `Claude outputs\` – ảnh/tệp bàn giao cũ; `A.I Project - YomiHub Project\` – gốc chứa `YomiHub-Project`, `output/`, `TECHNICAL_UPDATE_NOTES.md` cũ.
