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

## 6. Bổ sung 19/11/2026 (0.6.0)
- Note 9 dùng `jobs/q060_dev.ps1`: thêm `TapText <regex>`, `Find-Node`, `Labels` (đọc uiautomator), `NewLog <tên>` (lọc log từ dòng "Logger initialized" cuối, bỏ cảnh báo ảnh CDN). Job có chữ tiếng Việt (regex TapText) phải lưu UTF-8 **có BOM**, nếu không PowerShell 5 đọc sai → chạm theo toạ độ lấy từ `Labels`.
- Kiểm bộ lọc ô chọn: hồ sơ Mangayomi (vd. MangaDex), Aniyomi (nguồn APK, vd. DocTruyen5s/MoeTruyen), Kotatsu (nguồn có chữ "(Kotatsu)", vd. ComicK (Kotatsu)) – mỗi loại: chọn-một, Sắp xếp bấm lại đổi ↑/↓, thể loại ✓ → ô đỏ loại trừ, áp dụng có kết quả.
- Windows portable: giải nén `.zip` vào `D:\yh\qa<ver>win` bằng job, mở `YomiHub.exe`; computer use phải xin quyền theo **đường dẫn exe** (`d:\a.i project\yh\qa060win\yomihub.exe`) – tên "YomiHub" trỏ về bản đã cài trong `%LOCALAPPDATA%`. Bản portable dùng chung dữ liệu với bản cài (chỉ thao tác xem/lọc). Nguồn APK trên Windows cần bản `-full.zip` (M-Extension-Server).
- Test `yh_055` Case 1 (giao dịch Isar tranh chấp có hẹn giờ) có thể trượt khi máy quá tải → chạy lại riêng trước khi kết luận lỗi mã.

## 7. Bổ sung 19/11/2026 (0.6.1) – máy ảo
- AVD có sẵn (`%USERPROFILE%\.android\avd`): `OOS_Android6_API23` (x86_64, Android 6.0 – APK android6 x86_64), `YH_Android10_API29`, `YomiHub056_Phone_API34` (x86_64 – dùng cho APK TV x86_64), `YomiHub_TV_API34` (x86 32-bit – KHÔNG cài được APK x86_64), `Medium_Phone_API_37.0`.
- Mẫu job: tắt máy ảo cũ → đặt `ANDROID_SDK_ROOT` = SDK Android Studio → `Start-Process emulator.exe -avd <tên> -no-boot-anim -no-audio -no-snapshot-load -gpu swiftshader_indirect -memory 1536` → chờ `sys.boot_completed=1` → `install -r -g` → mở app → `screencap` → logcat lọc `FATAL|ANR|UnsatisfiedLink`. Mẫu: `jobs/done/f061_avd6_run5.ps1`, `f061_avdtv_run2.ps1`. Bằng chứng: `audit/audit-<ver>/evidence/avd6/`, `avdtv/`.
- Tiêu chí TV: chỉ thư viện Phim & Điện ảnh, thanh bên Thư viện · Cập nhật · Duyệt · Thêm (không Truyện tranh/Tiểu thuyết/Play Books/Booru).

## 8. Bổ sung 25/11/2026 (0.6.5) – bằng chứng phải thật
- **Không nhận ảnh chữ tự dựng** ("[PASSED] …"), không 2 ca dùng chung 1 ảnh (so md5), mỗi ảnh ghi `fg=` (gói/cửa sổ đang ở trước) lúc chụp. Claude mở xem ảnh trước khi nhận ĐẠT.
- **Điện thoại thật của chủ dự án (Note 9)**: kịch bản chạm theo toạ độ đã mở nhầm TikTok/TeamViewer → chỉ Claude kiểm, bằng `jobs/n9lib.ps1` (Fg/IsYomi/TapText theo nhãn uiautomator, dừng nếu gói trước không phải `com.yomihub.app`); không dùng phím Back ở màn gốc; tránh mở thư viện cá nhân. Tác nhân khác chỉ dùng AVD.
- Ca cần trình đọc (Tìm ảnh) làm trên AVD với ảnh thử cục bộ; không bấm tìm thật (không gửi ảnh ra ngoài).
- Windows: bản portable giải nén vào `audit/.../scratch/win_portable/`, chụp đúng cửa sổ chính YomiHub (EnumWindows, không dùng MainWindowHandle của cửa sổ phụ).
