# YomiHub 0.5.3 – Đợt 1 (bàn giao cho phiên Cowork trên kiritokmn-lap)

Tệp kèm: `YomiHub-0.5.3-part1.patch` (5 tệp trong `overlay/`).
Thư mục dự án trên laptop: `D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project`.

## Cách áp patch (trên laptop)
```
cd <thư mục repo YomiHub-Project>
git fetch && git status              # phải đang ở main = origin/main = b102151, cây sạch
git apply --check YomiHub-0.5.3-part1.patch
git apply YomiHub-0.5.3-part1.patch
```
Sau đó đồng bộ `overlay` sang `D:\yh\build\mangayomi` như `sync_052.ps1` rồi build theo `build_052.ps1` (đổi số phiên bản thành `0.5.3+45`).

---

## Mục chép vào TECHNICAL_UPDATE_NOTES.md

### 06/11/2026 — Cập nhật phiên bản 0.5.3, đợt 1 (phân tích log + sửa mã, CHƯA build)

Thực hiện: Claude, phiên chat claude.ai (Project "YomiHub Project"). Phiên này **không kết nối tới máy `kiritokmn-lap`**, nên chỉ đọc và sửa mã trên một bản clone trong máy Linux tạm của phiên.

#### A. Yêu cầu (đã xác nhận 06/11/2026)
- Nâng lên 0.5.3.
- Thực hiện sheet `Feature Check` (45 mục) và `YomiHub Update` (9 mục) trong `Project YomiHub.xlsx`, kèm `Project GitHub.xlsx`.
- Sửa lỗi trong `logs (3).txt`: 3.288 dòng, từ 30/10 06:09 đến 06/11 14:10.
- Ghi tài liệu, dựng bản phát hành, kiểm thử có ảnh và video, phát hành lên GitHub.
- Ràng buộc nền tảng vẫn chờ người dùng chốt. Theo thỏa thuận ở 0.5.2: Android 7.0+ (Isar/libmdbx không chạy trên Android 6) và Windows 10/11 x64.

#### B. Công cụ
- `git clone --depth 1` của `kiritokmn1403/YomiHub-Project` (HEAD `b102151`) và `kiritokmn1403/Kiritokmn---Extension-Repo`.
- Python 3 (`openpyxl` đọc Excel; phân tích và gom nhóm log).
- Sửa mã bằng `audit-0.5.3/edit.py`: `assert` chuỗi cũ xuất hiện đúng 1 lần, bản gốc chép vào `audit-0.5.3/before/`.
- `git diff` để xuất patch; `git apply --check` xác nhận patch áp sạch lên `b102151`.
- Không có Flutter/Dart SDK trong phiên, vì mạng chặn tải SDK. **Chưa chạy `dart analyze`, `flutter test` hay build.**

#### C. Lỗi trong log sau khi cài 0.5.2 (06/11 11:39 → 14:10) – nguyên nhân và cách sửa

| # | Dòng log | Nguyên nhân (đọc mã + đối chiếu log) | Sửa (tệp – thay đổi) |
| --- | --- | --- | --- |
| 1 | `[WARNING] [Hiệu năng] Giao diện bị treo 3.3 giây` (13:40:53) | Trùng đúng giây bắt đầu tự sao lưu `yomihub_2026-11-06_13_40_53…backup` (27,8 MB). Từ 0.5.2, việc nén ZIP đã chạy nền, nhưng `writeMangayomiBackupZip` vẫn đọc ~88.000 chương bằng `findAllSync()` và chạy `toJson()` hàng loạt trên luồng UI. | `lib/modules/more/data_and_storage/providers/backup.dart`: chương đọc bằng `chapterRepository.getAllAsync()`. Hàm mới `_toJsonInBatches()` chuyển JSON theo lô 1.000 bản ghi và nhường event loop (`Future.delayed(Duration.zero)`) giữa các lô. Áp dụng cho chapters, downloads, history, updates. |
| 2 | `[WARNING]` rỗng + `Logger initialized` (73 lần trong log) | Mốc phiên được ghi ở mức WARNING và bọc 4 ký tự xuống dòng, làm nhiễu bộ đếm cảnh báo. | `lib/utils/log/logger.dart`: ghi một dòng `[INFO] ===== Logger initialized (phiên mới) =====` với `always: true`. |
| 3 | `[Thư mục cục bộ] Bỏ qua EPUB hỏng: …Bản Lĩnh Putin…` lặp lại mỗi lần mở app (11:40, 13:36), dù 0.5.2 đã lưu danh sách `badEpubs` | Lần quét lúc khởi động chạy **trước khi** box Hive `yomihub_prefs` mở xong. Khi đó `YomiPrefs.get` trả về `[]` và `YomiPrefs.set` (`_box?.put`) không ghi gì. Danh sách EPUB hỏng vì thế không bao giờ được đọc hay lưu. | `lib/modules/library/providers/file_scanner.dart`: trước vòng lặp chương, nếu `!YomiPrefs.isOpen` thì `await YomiPrefs.ready.timeout(5 s)`. |
| 4 | `Shorts FapReel (18+): lỗi phát video: Failed to open https://cdncontent.imctransfer.com/…?expires=1794023206&token=…` (×2, 13:36:50) | **Chưa xác định.** Token còn hạn tới 07/11 10:46 nên không phải link hết hạn. Hai video lỗi cùng một giây, lúc nạp trước 2 trình phát. Giả thuyết: CDN gắn token với IP, trong khi trang danh sách và luồng video libmpv đi qua hai đường mạng khác nhau (VPN "Chỉ YomiHub"). Phiên này bị chặn mạng tới hai tên miền nên không kiểm chứng được. | Chưa sửa. Việc cho phiên Cowork: chạy `curl.exe -I -H "Referer: https://fapreel.com/" -A "<YH_UA>" "<URL mp4>"` hai lần, một lần bật VPN và một lần tắt; so với trạng thái VPN lúc lỗi. |

Các dòng `[INFO] Hệ thống báo thiếu bộ nhớ` và `Image/network load failed` (ảnh bìa từ trang nguồn) là thông tin, không phải lỗi của ứng dụng.

#### D. Việc tồn từ 0.5.2 đã sửa
- **Bản Windows tự sao lưu vào đường dẫn Android** (`/storage/3730-6132/Backup & Sync/…` thành thư mục `\storage\…` trên ổ hiện tại). Nguyên nhân: cài đặt khôi phục từ bản sao lưu Android.
- Sửa ở `lib/modules/more/data_and_storage/providers/auto_backup.dart`, hàm mới `_isUsableBackupLocation()`:
  - Windows chỉ nhận đường dẫn ổ đĩa (`C:\`) hoặc UNC (`\\server`).
  - Máy tính để bàn không nhận `/storage/…` hay `/sdcard…`.
  - Nếu không hợp lệ thì dùng thư mục mặc định và ghi `logOnce` cảnh báo.
- Logic regex đã chạy thử bằng biểu thức Python tương đương với 5 đường dẫn mẫu, cho kết quả đúng.

#### E. Ghi nhận, không sửa
- Hai bản sao lưu cách nhau 2 phút (13:38 và 13:40). `checkAndBackup` chỉ chạy một lần mỗi lần mở app, chu kỳ tối thiểu 6 giờ, và giữa hai lần không có lần khởi động lại. Rất có thể một bản là sao lưu thủ công. Cần người dùng xác nhận.

#### E2. YomiHub Update mục 3 – Dự án GitHub còn thiếu
- So khớp `Project GitHub.xlsx` với `lib/yomihub/about/github_projects.dart`: Excel có 606 liên kết khác nhau, ứng dụng có 624; còn **20 mục thiếu**. Sau khi chuẩn hóa, 18 trong số đó là repo mới thêm vào sheet.
- 18 repo đều được xác minh bằng `git ls-remote` (đều tồn tại).
- Đã bổ sung 19 liên kết:
  - Nhóm "Ứng dụng": Mangayomi Server, Yomikiru, Yomihon, Zenshin, Nyora (9 repo), Nuvio.
  - Nhóm "Trình duyệt": Donut Browser (sheet không có link, đã xác minh `github.com/donutbrowser/donutbrowser`).
  - Nhóm "Tracker": AnymeX, AniSync, Tankobun, Rokku.
- Không thêm: link LeechText kèm `?fbclid=…`. Đây chỉ là tham số theo dõi của Facebook; link `…/LeechText/releases` đã có từ 0.4.9.
- Sau khi sửa: 643 liên kết, 0 repo thiếu.

#### F. Kết quả kiểm thử
- `git apply --check`: đạt trên `b102151`.
- **Chưa biên dịch, chưa chạy test, chưa cài lên thiết bị.** Không coi đợt này là đã kiểm thử tính năng (theo AGENTS.md mục 2).

---

## Việc còn lại cho phiên Cowork (theo thứ tự đề xuất)
1. Áp patch, `dart analyze`, `flutter test`. Thêm test cho `_toJsonInBatches` và `_isUsableBackupLocation`.
2. Kiểm tra lỗi FapReel (mục C4) bằng `curl` trên máy thật.
3. **YomiHub Update** mục 2: chuyển các tiện ích trong sheet *Website Extension* sang `Kiritokmn---Extension-Repo` và gỡ bản tích hợp sẵn. Cần chốt với người dùng: app có tự thêm repo này không?
4. YomiHub Update mục 4–5: gom mục "Sao Lưu & Đồng Bộ" (menu Cài đặt + menu Thêm); đưa công tắc Google Play Books/Booru vào "Bật/Tắt tính năng & Nguồn mở rộng".
6. YomiHub Update mục 6–7 (Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, Mangayomi Server; Tracker theo AnymeX/AniSync/Tankobun/Rokku + insets), mục 8–9 (treo/văng; Windows Ryzen 9).
7. 45 mục Feature Check → build 3 APK + 3 APK TV + Windows (Setup.exe, .appxbundle, portable) → kiểm thử Note 9/emulator/TV/Windows có ảnh và video → release `v0.5.3` + README.
8. Không tích hợp các repo bẻ khóa Wi-Fi trong nhóm "Wifi Setting" của `Project GitHub.xlsx`. Tính năng Wi-Fi giữ ở mức mở cài đặt mạng hệ thống.
