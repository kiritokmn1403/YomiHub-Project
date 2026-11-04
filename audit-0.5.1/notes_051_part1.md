
### 03/11/2026 — Cập nhật phiên bản 0.5.1 (YomiHub 0.5.1+43)

Thực hiện: Claude (phiên cloud liên kết máy `kiritokmn-lap`), 03/11/2026 21:51 → (xem mục J) (Asia/Saigon). Người dùng xác nhận bản tóm tắt lúc 21:51 ("đồng ý, hãy tiến hành ngay bây giờ"), giữ đề xuất như 0.5.0: Android 7.0+ (không phải 6.0) và Windows 10/11 x64 (không phải Windows 7/x86/ARM). 21:55 người dùng yêu cầu thêm: "tích hợp các mã nguồn mới, kiểm tra xem các tiện ích vBooks có còn bị mã hoá nữa không" (mục C).

#### A. Yêu cầu
1. Nâng lên 0.5.1; Android (3 APK) + `YumiHub Android TV` (3 APK, bỏ Comic, Novel, Google Play Books, Booru); Windows `.appxbundle`, `Setup.exe`, portable.
2. Sheet `Feature Check` (45 mục) và `YomiHub Update` (7 mục, mới: thư mục cục bộ không nhận tệp tải của Aniyomi/Nekoyomi/Mangayomi) của `Project YomiHub.xlsx`; `Project GitHub.xlsx` (579 liên kết).
3. Sửa lỗi trong `logs (1).txt` (30/10 06:09 → 03/11 21:24).
4. Ghi vào tài liệu này: hạng mục, lỗi, dòng lệnh sửa, công cụ, kết quả kiểm thử, ngày.
5. Dựng, cài, kiểm thử (ảnh + video), tải mã nguồn + Output lên GitHub (Releases + README).

#### B. Công cụ đã dùng
- Đọc/sửa mã: shell Linux của Claude trên máy người dùng (thư mục kết nối); mọi phép sửa bằng `audit-0.5.1/edit.py` (Python 3: `assert` chuỗi cũ xuất hiện đúng 1 lần, chép bản gốc vào `audit-0.5.1/before/`, ghi `audit-0.5.1/changed_files.txt`). Kịch bản sửa: `audit-0.5.1/e01_local.py` (thư mục cục bộ), `e02_net.py` (nhật ký mạng), `e03_vbook.py` (runtime vBook) và các lệnh `edit(...)` ghi trong mục D.
- Dựng/kiểm thử trên Windows: `3_run_jobs.bat` + `3b_run_fast_jobs.bat` (Claude mở lại bằng Computer use trong File Explorer lúc 21:54 – hai trình chạy đã dừng từ 14:08), `sync_051.ps1`, `build_051.ps1`, `qa051.ps1`, `release_051.ps1` (sinh từ bản 0.5.0, đổi phiên bản/thư mục); Flutter 3.47.6 / Dart 3.13.5, Android SDK + adb, Gradle, Rust/Cargo, Visual Studio 2022 Build Tools, WiX/NuGet, ffmpeg.
- Quét kho vBook: `git clone --depth 1` 18 kho + Python (`zipfile`) trong môi trường cloud (máy người dùng chặn `raw.githubusercontent.com` từ shell); kết quả `audit-0.5.1/vbook_encryption_scan_2026-11-03.csv`.
- Kiểm tra thư mục trên Note 9: `adb push` script `audit-0.5.1/yomi_ls*.sh` + `adb shell sh` (danh sách tệp cá nhân – không đưa lên Git, `.gitignore`).

#### C. Tiện ích vBook mã hóa – kiểm tra lại (yêu cầu bổ sung 21:55)
- Thư mục mới `D:\A.I Project\A.I Project - vBooks` chứa `vBooks.apk` và mã Java dịch ngược của ứng dụng vBook (đóng nguồn) cùng `decode_manifest.js`, `extract_classes.js`. **Không tích hợp** mã này vào YomiHub và không dùng để giải mã tiện ích: chép mã dịch ngược của ứng dụng đóng nguồn vào dự án công khai là vi phạm bản quyền, và lấy khóa từ ứng dụng để mở tiện ích mà tác giả chủ ý chỉ cho chạy trong vBook là vượt qua lớp bảo vệ của họ. Người dùng đã được thông báo và đồng ý tiếp tục ("Tiếp tục đi", 22:01).
- Quét 554 mục của 18 kho vBook (BaoBao666888, Darkrai9x ×2, Evamirion, Gold2k2k2k, Ivan1hai, Moleys, SoulGodEve9x9, WillSun28, dat-bi, duongden, gh369-639, hajljnopera, hienpro00123, kychitoge, lethituyen, mizhm, yae-miko-313): **234 mã hóa** (`metadata.encrypt=true`, mọi `src/*.js` là bản mã), **310 không mã hóa** + 3 không mã hóa (mã nén một phần: Legado, 85 Novel, 123 Truyện), 6 thiếu `plugin.zip` trong kho, 1 zip lỗi. Toàn bộ 16 tiện ích báo trong log (MotPhim, RoPhim ×2, GuPhim, LuPhim, Phim4K, Phim Nhựa, Phimtv, AnimeVietsub, Mimimoe, 210CB, CBunu Comic, BLVietsub, Bilibili, Bilibili TV, FreeReels) **vẫn mã hóa**. Kết luận: giữ cách xử lý 0.5.0 (khóa + nhãn "Chỉ chạy trên vBook").
