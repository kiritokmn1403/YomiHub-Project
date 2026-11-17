
#### G. Kiểm thử bản dựng lần 2 và lần 3 trên Note 9 (04/11 00:18 → 01:03) và các lỗi sửa thêm
- **Luồng quyền bộ nhớ (bản dựng lần 2, 00:18):** thu hồi các quyền cấp tạm (`pm revoke`, `appops set … LEGACY_STORAGE default`) → cài đè → `LEGACY_STORAGE: allow` (nhờ cờ manifest) → mở app: hộp thoại hệ thống **"Cho phép YomiHub truy cập vào ảnh, phương tiện và tệp trên thiết bị của bạn?"** → Cho phép → `READ_EXTERNAL_STORAGE: granted=true` (hộp thoại của hệ thống chặn chụp màn hình; có trong video `v02_thu_muc_cuc_bo.mp4`). Lần bấm đầu trượt vì màn hình tắt (`Display Power: state=OFF`, ứng dụng "My Files" của Samsung bật lên) → đánh thức, bấm lại.
- **Quét thư mục cục bộ** (Cài đặt › Tải xuống › Quét lại mọi thư mục cục bộ), `adb logcat [LocalLibraryScanner]`:

| Thư mục (thẻ nhớ `…/Backup Yomi Apps/`) | Thư mục truyện tìm thấy | Truyện/phim/sách nhập | Chương/tập |
| --- | ---: | ---: | ---: |
| `downloads` (Aniyomi / Nekoyomi / Mihon / Mangayomi) | 467 | **427** | **1.905** |
| `local` | 1 | 1 | 1 |
| `localnovel` (EPUB) | 737 | **131** | **193** |
| `autobackup`, `localanime`, `/storage/emulated/0/YomiHub/local` | 0 | 0 | 0 |

  Trước khi sửa (bản 0.5.0 và bản 0.5.1 lần 1): **0** ở mọi thư mục. Duyệt › Nguồn cục bộ Truyện tranh hiện các bộ truyện (ảnh màn hình chỉ giữ trên máy – nội dung 18+, không đưa vào gói QA công khai). Thư viện chính chỉ hiện mục yêu thích (thiết kế gốc: mục cục bộ `favorite=false`).
- **Lỗi mới phát hiện:** `crash_reports.json` 00:25:54 – `Failed to open EPUB: Archive Error: Zip Error: invalid Zip archive: Could not find EOCD` (màn `/downloads`, khi quét `localnovel`): `parseEpubFromPath` ném lỗi trong vòng lưu chương → dừng cả lượt lưu. Sửa `file_scanner.dart`: `try/catch`, bỏ qua tệp hỏng, `AppLogger.logOnce('bad-epub:…', '[Thư mục cục bộ] Bỏ qua EPUB hỏng: …')`.
- **Màn "Nhật ký ứng dụng" vẫn quay vòng ở bản lần 2** dù đã giới hạn thời gian chờ → viết lại `_load`: đọc + tách mục trong isolate nền, nối chuỗi tuyến tính (`StringBuffer` thay cho `entries[last] += …` – bậc hai), 3.000 mục mới nhất, `finally` luôn tắt vòng quay. Bản lần 3 (01:01): vòng quay hết ngay, hiện lỗi thật `Illegal argument in isolate message: object is unsendable – _AsyncCompleter` (closure `Isolate.run` tạo trong phương thức `State` kéo theo cây widget) → chuyển `Isolate.run` ra hàm cấp cao: `parseAppLogInBackground(paths)` (`app_log_screen.dart`), `inspectApkInBackground(bytes)` (`apk_inspector_screen.dart` – cùng lỗi). Thêm 2 test **chạy thật** hai hàm này (tệp nhật ký tạm; APK dựng từ mẫu AXML) – test chỉ so chuỗi mã nguồn đã bỏ sót lỗi này.
- **Mạng của Note 9 bị mất** từ khoảng 00:32 (`DnsResolver … ETIMEDOUT`, `NetworkMonitor … Probe failed`): giải thích việc cài lại tiện ích vBook "MotPhim" kết thúc sau ~4 s mà không khóa (tải `plugin.zip` thất bại do mạng, chưa tới bước nhận diện mã hóa). Các phần cần mạng được kiểm thử trên máy ảo / Windows (mục H).
- Kiểm thử tự động sau mọi sửa (`build_051.ps1 -step test`, 01:12): `dart analyze lib` **0 lỗi** (211 info/warning, không đổi so với 0.5.0); `flutter test` 12 tệp yh_040…yh_051: **102/102 đạt**.
