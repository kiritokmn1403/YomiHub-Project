# Quy trình kiểm tra

## 1. Kiểm thử tự động
- `dart analyze` các tệp đã sửa (0 lỗi) → test mới `overlay/test/yh_<ver>_*_test.dart` + test hồi quy liên quan, chạy qua job `pending_fast` (không chạy 2 `flutter test` cùng lúc trên một thư mục dựng).
- Bước `test` của dây chuyền chạy toàn bộ bộ test; test mạng (vd. Website Scan) có thể trượt do mạng → đọc mục "Failing tests" trong log trước khi kết luận lỗi mã.
- Lần biên dịch test đầu (Windows MSVC) mất 5–7 phút → job test đặt `# timeout: 15–20`.
- i18n: kiểm đối xứng 18 tệp bằng Python/Node `json` (không dùng `ConvertFrom-Json` của PowerShell – không phân biệt hoa/thường).

## 2. Thiết bị thật Android – Samsung Galaxy Note 9 (SM-N960N, Android 10)
- Điều khiển qua adb bằng `jobs/q059_dev.ps1`: `Launch`, `Stop-App`, `Tap x y`, `Swipe`, `Key`, `Shot <tên>`, `Dump <tên>` (uiautomator), `RecStart <tên> <giây>` / `RecPull`, `PullLog <tên>` (`/sdcard/YomiHub/logs.txt`).
- **Trước chuỗi chạm: chụp/dump kiểm tra đúng màn hình** (hộp thoại hệ thống – vd. Google xác minh đăng nhập – có thể đè lên app; KHÔNG bấm vào hộp thoại tài khoản).
- Cài bản phát hành: `adb install -r output/<ver>/YomiHub-<ver>-arm64-v8a.apk` (cài đè giữ dữ liệu); kiểm `dumpsys package` versionName/Code.
- Kịch bản tối thiểu: khởi động (splash 5 s), Thư viện + lọc/sắp xếp, chi tiết truyện, trình đọc, trình phát/tiếp tục xem, tiện ích & bộ lọc, VPN/Tor, sao lưu/khôi phục, các mục mới của bản. Sau mỗi kịch bản đọc nhật ký phiên mới (từ dòng "Logger initialized" cuối) và lọc bỏ cảnh báo ảnh CDN lặp.
- Bằng chứng lưu `audit/audit-<ver>/evidence/note9/` (ảnh, xml, mp4, log). Ảnh có bìa 18+/bản quyền KHÔNG dùng cho tài liệu công khai/APKPure.
- AVD dùng khi cần Android 6/TV/API khác (`D:\yh\avd`, cửa sổ `qemu-system-x86_64.exe`); APK TV mở bằng `am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity`.

## 3. Windows 11
- Portable: giải nén `.zip` vào `D:\yh\qa<ver>win`, chạy `YomiHub.exe`, kiểm `FileVersion`.
- Cài đè: chạy `Setup.exe` (không có chế độ im lặng) → computer use, cấp quyền đúng tên tiến trình `yomihub-<ver>-windows-x64-setup.exe`, bấm "Cài Đặt Ngay" → app cài ở `%LOCALAPPDATA%\YomiHub`; kiểm không cửa sổ trắng, các tab chính.
- Kiểm sao lưu không đụng dữ liệu thật: tắt app → đổi tên `Documents\YomiHub`, `Documents\Mangayomi` → thử → đổi tên lại.

## 4. Kiểm tiện ích & kho
- Repo tiện ích: `node .build/test/<nguồn>.mjs` (popular, search, detail, chapters, videos) → `npm run build`.
- Kho/nguồn cập nhật: kiểm HTTP + định dạng index + số tiện ích (báo cáo mẫu `audit/audit-0.5.9/antigravity/extension_repos_report.md`, `update_sources_report.md`).

## 5. Tiêu chí "ĐẠT"
- Có log/ảnh/video thật của đúng bản, đúng tính năng; người kiểm tự mở ảnh xem.
- Phân biệt: kiểm HTTP ≠ phân tích index ≠ cài tiện ích ≠ đọc/phát nội dung.
- Không đánh dấu đạt chỉ vì có nút giao diện; ghi rõ phần cần tài khoản/thiết bị thứ hai/quyền hệ thống chưa kiểm.
