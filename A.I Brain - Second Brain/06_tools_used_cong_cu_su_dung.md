# Công cụ sử dụng (YomiHub)
Ghi lại các công cụ Claude/tác nhân đã dùng để làm YomiHub, cách dùng đúng và lỗi hay gặp. Cập nhật mỗi khi dùng công cụ mới. **Không ghi mật khẩu, token, Client Secret vào tệp này.**

## 1. Làm việc với tệp & lệnh trên máy dự án (KIRITOKMN_LAP, Windows 11)
| Công cụ | Dùng để | Lưu ý |
|---|---|---|
| `device_bash` (VM Linux trên máy, thư mục gắn ở `$HOME/mnt/<tên>`) | Đọc/sửa tệp dự án (grep, sed, python3 read-modify-write), tạo job | Tối đa 180 s/lệnh; `grep -r` cả `overlay/lib` có thể quá 120 s → thu hẹp thư mục/`timeout`. Không xóa được tệp (rm bị chặn) trừ khi xin quyền. `git commit/mv` trên mount dễ để lại `.lock` → làm git qua runner Windows. |
| `device_list_dir`, `device_stage_files`, `device_commit_files` | Liệt kê, đưa tệp (ảnh/PDF) vào container để xem, ghi kết quả về máy | Ảnh chụp điện thoại 1440×2960 → thu nhỏ bằng PIL trước khi xem. |
| Runner job PowerShell: `jobs/pending/` (dài, dựng) và `jobs/pending_fast/` (ngắn: test, adb, git) | Chạy mọi lệnh Windows: flutter/dart, adb, git push, Start-Process | Dòng 1 `# timeout: <phút>`; log `jobs/done/<tên>.log` là **UTF-16LE** → `iconv -f utf-16le -t utf-8`. Runner tuần tự: job dài chiếm `pending`, job nhanh vẫn chạy song song ở `pending_fast`. Cửa sổ cmd runner có thể kẹt QuickEdit khi máy ngủ. |
| Thư viện job: `scripts/lib/common.ps1`, `yh_defines.ps1`, `jobs/q059_lib.ps1` (`Sync-Overlay`, `Run-Tests`, `Run-Analyze`), `jobs/q059_dev.ps1` (Note 9: `Shot`, `Dump`, `Tap`, `Swipe`, `Key`, `RecStart/RecPull`, `PullLog`, `Launch`, `Stop-App`) | Viết job ngắn gọn | `yh_defines.ps1` đọc `secrets/google_oauth.json` → `--dart-define` (không in ra log chia sẻ). |
| Dây chuyền dựng `scripts/pipeline/run_<ver>_main.ps1` → `scripts/build/build_<ver>*.ps1`, `scripts/sync/sync_<ver>.ps1`, `scripts/packaging/make_installer_exe_<ver>.ps1`, `scripts/packaging/make_appxbundle_<ver>.ps1` | sync → test → apk → tv → wintest → win → pack → a6build → a6copy → verify | Trạng thái `audit/audit-<ver>/release/main_build_status_<ver>.txt`; khóa `audit/audit-0.5.6/coordination/BUILD_LOCK.txt`. 0.5.9 mất ~2 giờ 20. |
| `scripts/release/release_<ver>.ps1` | Tạo GitHub Release, tải asset bằng curl, tự đối chiếu kích thước | Token lấy từ Git Credential Manager lúc chạy. Cần chủ dự án xác nhận trong chat (bộ phân loại an toàn chặn nếu chưa). |
| `scripts/autosave/autosave_progress_<ver>.ps1` | Tự commit + push tiến độ mỗi 3 phút (chạy nền) | Dừng: tạo `jobs/STOP_AUTOSAVE`; tự dừng sau 8 giờ; log `logs/autosave_<ver>.txt`. |
| Toolchain trên máy | Flutter 3.47.6 / Dart 3.13.5, MSVC 19.44, Gradle 9.3.1, Android SDK (adb, aapt2), Rust (cargokit), Java (M-Extension-Server), `D:\yh` (pub-cache, tools, build, buildwin, build23) | `D:\yh\build\mangayomi` (Android), `D:\yh\buildwin\mangayomi` (Windows), `D:\yh\build23\mangayomi` (Android 6) là bản sao — chỉ sửa `overlay/`. |
| `adb` (Samsung Galaxy Note 9 SM-N960N, Android 10, serial trong `q059_dev.ps1`) | Cài APK, chạy kịch bản chạm, chụp màn hình, quay video, kéo nhật ký `/sdcard/YomiHub/logs.txt` | Chụp bằng `screencap -p` + `pull` (không `exec-out >` trong PS5). Chụp/dump kiểm tra màn hình trước chuỗi chạm (hộp thoại Google có thể đè lên). |
| Python 3 trong VM (json, PIL), `iconv`, `sed` | Sửa i18n 18 ngôn ngữ (dùng `json`, không ConvertFrom-Json của PS), xử lý log, ghép ảnh | Giữ BOM/CRLF khi sửa script .ps1 (đọc/ghi dạng byte). |

## 2. Điều khiển giao diện máy tính
| Công cụ | Dùng để | Lưu ý |
|---|---|---|
| Computer use (`computer_resolve_access` → `computer_request_access`, `screenshot`, `left_click`, `type`, `key`, `batch`, `write_clipboard`) | Antigravity (gõ /swarm), bộ cài `Setup.exe`, kiểm thử YomiHub Windows, xem Cốc Cốc | Quyền mất sau khi app desktop cập nhật/hết hạn → xin lại. Trình duyệt/IDE/Explorer chỉ được cấp mức đọc/bấm. Cửa sổ chưa nhận phím → bấm biểu tượng trên thanh tác vụ (cần quyền File Explorer). Tiến trình không có trong danh sách cài đặt (vd. `yomihub-0.5.9-windows-x64-setup.exe`) → xin quyền bằng đúng tên tệp. Gọi `computer_release_lock` khi xong. |
| Trình duyệt tích hợp Claude (`Claude_Browser__*`: `preview_start`, `navigate`, `find`, `read_page`, `computer`, `javascript_tool`) | GitHub (Settings › Pages), Google Cloud Console (Google Auth Platform: Branding, Audience → Publish app) | Hồ sơ đăng nhập riêng, không chung Cốc Cốc; chủ dự án tự đăng nhập (Claude không nhập mật khẩu). Tài khoản dự án Google Cloud `yomihub` = `authuser=1`. Ô nhập Angular: lấy tọa độ bằng `javascript_tool` rồi bấm + gõ. |
| Cốc Cốc (trình duyệt hằng ngày của chủ dự án) | Chỉ xem | Không dùng thay trình duyệt tích hợp. |

## 3. Tác nhân khác
| Công cụ | Dùng để | Lưu ý |
|---|---|---|
| Google Antigravity (app, Gemini 3.8 Flash) | Giao việc bằng `/swarm`: sửa tiện ích Extension Repo, báo cáo kho/nguồn cập nhật, README, rà lang/NSFW, theo dõi tải Release (3 tác tử, 40 s/lượt) | Brief ghi "[Claude (Anthropic) điều phối thay mặt Kiệt]", phạm vi tệp riêng, cấm sửa overlay/jobs/D:\yh, không push; ghi `audit/audit-<ver>/antigravity/NOTES_swarm*.md`. Cách gõ: "/swarm" → bấm gợi ý → End → Ctrl+V → Enter. Kiểm lại khẳng định của tác nhân (README từng ghi tính năng không có). |
| Tác nhân phụ Claude (Agent) | Chia việc song song | Tối đa 2–3; bị ngắt thì thường không để lại gì → tự làm. |

## 4. Dịch vụ & tra cứu
| Công cụ | Dùng để | Lưu ý |
|---|---|---|
| `WebFetch` | Đọc API công khai GitHub (`api.github.com/repos/.../releases/tags/<tag>`), trang GitHub Pages | Không dùng cho trang cần đăng nhập. |
| GitHub (repo `kiritokmn1403/YomiHub-Project`, `kiritokmn1403/Kiritokmn---Extension-Repo`, Pages `/docs`) | Mã nguồn, Release, trang chủ + chính sách quyền riêng tư | `gh` CLI KHÔNG có trên máy; push qua git trong job. |
| Google Cloud project `yomihub` | OAuth client "YomiHub Windows" (Desktop) + "YomiHub Android TV" (TV/Limited Input), Drive API; app OAuth "In production" | Giá trị client chỉ ở `secrets/google_oauth.json` (git-ignored). |
| Lịch hẹn (`send_later`, `update_trigger`) | Tự kiểm tra lại bản dựng/Release | Lịch gắn máy KHÔNG đổi được nội dung lời nhắc từ chat (chỉ giờ/tên/bật-tắt); tắt lịch khi xong. |
| `SendUserMessage`, `TaskCreate/TaskUpdate` | Báo tiến độ cho chủ dự án, danh sách việc | Chủ dự án muốn thấy quá trình: mỗi bước 1 câu tiếng Việt. |
- (18/11) **APKPure** (developer.apkpure.com, tài khoản "Kiritokmn", dùng Cốc Cốc vì trình duyệt tích hợp bị Cloudflare chặn): app `com.yomihub.app`; ảnh chụp cạnh dài ≤ 2× cạnh ngắn (1080×2160), ảnh nổi bật 1024×500 không alpha, icon 512 PNG; mỗi ngôn ngữ cần đủ ảnh riêng; hộp chọn tệp chỉ 1 tệp/lần; tải APK → chờ xác minh → "Công bố" → chờ duyệt. Tư liệu: `audit/audit-0.5.9/apkpure/`.
