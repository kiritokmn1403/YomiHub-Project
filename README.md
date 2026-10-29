# YomiHub

Ứng dụng đọc truyện tranh (Comic), xem phim (Film & Movie), đọc tiểu thuyết (Novel), Google Play Books và Booru App. Ứng dụng được xây dựng trên nhân [Mangayomi](https://github.com/kodjodevf/mangayomi) (Flutter) và có các bản sau:

- Android 7.0+ (3 APK theo ABI);
- Android TV (`YumiHub Android TV`, chỉ có Phim & Điện ảnh);
- Windows 10/11 x64 (`Setup.exe`, `.appxbundle`, bản portable).

Phiên bản hiện tại: **0.4.4+36** (29/10/2026). Xem `TECHNICAL_UPDATE_NOTES.md`.

## Cấu trúc

| Thư mục / tệp | Nội dung |
|---|---|
| `overlay/` | **Mã nguồn YomiHub đầy đủ**: `lib`, `android`, `windows`, `assets`, `packages`, `test`, `pubspec.yaml`. Thư mục này được chép đè lên nền Mangayomi để dựng. |
| `src/mangayomi/` | Mã Mangayomi gốc (upstream) dùng làm nền. Xem `src/BASE_VERSION.txt`. |
| `build_044.ps1`, `common.ps1`, `make_installer_exe.ps1`, `make_appxbundle.ps1`, `run_jobs*.ps1`, `*.bat` | Bộ script dựng APK, APK TV, Windows và đóng gói. |
| `qa044.ps1` và các `test_*`/`record_*`/`take_*` | Script kiểm thử: adb, giả lập, chụp màn hình, quay video. |
| `audit-0.3.9/`, `audit-0.4.3/`, `audit-0.4.4/` | Ghi chú, script kiểm tra, danh sách tệp đã sửa của từng đợt. |
| `work-0.1.8/` | Bản làm việc cũ 0.1.8, giữ để tham khảo. |
| `AGENTS.md`, `TECHNICAL_UPDATE_NOTES.md` | Quy định và nhật ký kỹ thuật bắt buộc đọc trước mỗi lần cập nhật. |

## Không có trong repo

Các tệp sau được loại qua `.gitignore`:

- khoá ký APK (`*.jks`), mật khẩu, `key.properties`, cookie;
- APK, EXE, ZIP, appxbundle và thư mục `output/`;
- log, hàng đợi `jobs/`;
- ảnh và video QA;
- bản sao trước khi sửa (`audit-*/before/`).

Bộ cài được đăng ở mục **Releases**.

## Dựng

Xem phần 7 của `TECHNICAL_UPDATE_NOTES.md`. Các bước:

1. Chép `overlay/` đè lên `src/mangayomi` vào thư mục dựng.
2. Chạy `build_044.ps1 -step test|apk|tv|win|pack` (Flutter 3.47.6, Dart 3.13.5).
3. Dựng APK cần khoá ký riêng của bạn trong `android/key.properties`. Tệp này không có trong repo.
