# Quy trình & hạ tầng
- Mã riêng YomiHub chỉ sửa trong `overlay/`; `D:\yh\build\mangayomi` (Android), `D:\yh\buildwin\mangayomi` (Windows), `D:\yh\build23\mangayomi` (android6) là bản sao.
- Máy Windows chạy 2 runner: `jobs/pending/` (dài) và `jobs/pending_fast/` (ngắn). Job = .ps1 CRLF, dòng 1 `# timeout: <phút>`; log ở `jobs/done/<tên>.log` (UTF-16LE → `iconv -f utf-16le`). `ensure_runners.ps1` tự bật lại runner.
- Thư viện test nhanh: `jobs/q057_lib.ps1` (`Sync-Overlay`, `Run-Tests`); nạp `common.ps1` (PUB_CACHE=D:\yh\pub-cache, tools ở D:\yh\tools).
- Chụp màn hình Android trong PowerShell 5: `adb shell screencap -p /sdcard/x.png; adb pull ...` (KHÔNG `adb exec-out screencap > file` – PS5 làm hỏng nhị phân).
- Đầu vào mỗi bản: chép Excel + log vào `audit-<ver>/input/`, xuất JSON che tài khoản.
- Bản dựng đầy đủ 0.5.7: `jobs/pending/x*_build057.ps1` → `run_057_main.ps1` (sync → test → apk → tv → wintest → win → pack → a6build → a6copy → verify); trạng thái `audit-0.5.7/release/main_build_status_057.txt`; khóa `audit-0.5.6/coordination/BUILD_LOCK.txt` (nếu giết tiến trình phải xóa nội dung khóa).
- Quyền điều khiển máy (computer use) mất khi app desktop cập nhật và hết hạn sau 30 phút không dùng; cửa sổ máy ảo là `qemu-system-x86_64.exe`, điện thoại Samsung xem qua Samsung DeX / Phone Link.
