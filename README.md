# YomiHub

Ứng dụng đọc truyện tranh (Comic), xem phim (Film & Movie), đọc tiểu thuyết (Novel), Google Play Books và Booru App, xây dựng trên nhân [Mangayomi](https://github.com/kodjodevf/mangayomi) (Flutter). Từ 0.4.9 YomiHub chạy được cả **tiện ích vBook** (Darkrai9x/vbook-extensions, duongden/vbook và các kho cộng đồng).

**Phiên bản hiện tại: 0.5.5** (10/11/2026). Có gì mới: [`YomiHub-0.5.5-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

Điểm chính của 0.5.5: **Cách ly triệt để Retry CSDL Isar & Bảo vệ Callback có Side-effect** (`DbWriteQueue.run` thực thi đúng 1 lần FIFO, thu hẹp retry vào bước xin giao dịch `writeTxnSyncSafe`, chuẩn hóa 20 caller repo); **Tối ưu hóa Anime Player** kiểm tra an toàn live stream không hỗ trợ seek và xử lý an toàn khi chuyển tập / dispose controller; **Nâng cấp gói phát hành** tách riêng `YumiHub Android TV` (loại bỏ Comic, Novel, Google Play Books, Booru App); **Windows x64** xuất bản đầy đủ 3 định dạng: Setup `.exe`, Store `.appxbundle` có chứng chỉ số, và portable `.zip` / `-full.zip`; 15 bộ test với **175/175 bài test tự động đạt 100%**.

## Tải về (Releases v0.5.5)

Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.5 (luôn có bản mới nhất ở [releases/latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)).

### Android 7.0 trở lên

| Tệp | Dành cho |
|---|---|
| [YomiHub-0.5.5-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-arm64-v8a.apk) | Hầu hết điện thoại/máy tính bảng (64-bit) |
| [YomiHub-0.5.5-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-armeabi-v7a.apk) | Máy ARM 32-bit đời cũ |
| [YomiHub-0.5.5-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-x86_64.apk) | Máy ảo / Chromebook x86_64 |

### Android TV (YumiHub Android TV – chỉ Phim & Điện ảnh; không có Comic, Novel, Google Play Books, Booru)

| Tệp | Dành cho |
|---|---|
| [YumiHub-Android-TV-0.5.5-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YumiHub-Android-TV-0.5.5-arm64-v8a.apk) | TV box / Google TV 64-bit |
| [YumiHub-Android-TV-0.5.5-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YumiHub-Android-TV-0.5.5-armeabi-v7a.apk) | Đa số Android TV (32-bit) |
| [YumiHub-Android-TV-0.5.5-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YumiHub-Android-TV-0.5.5-x86_64.apk) | Máy ảo TV x86_64 |

### Windows 10/11 x64

| Tệp | Cách dùng |
|---|---|
| [YomiHub-0.5.5-windows-x64-Setup.exe](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-windows-x64-Setup.exe) | Bản cài đặt .exe |
| [YomiHub-0.5.5-windows-x64.appxbundle](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-windows-x64.appxbundle) | Bản cài .appxbundle – chạy [Install-YomiHub.bat](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/Install-YomiHub.bat) (kèm [Install-YomiHub.ps1](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/Install-YomiHub.ps1)) hoặc cài chứng chỉ [YomiHub-RootCA.cer](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-RootCA.cer) trước |
| [YomiHub-0.5.5-windows-x64.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-windows-x64.zip) | Bản portable – giải nén và chạy `YomiHub.exe`, không cần cài |
| [YomiHub-0.5.5-windows-x64-full.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/YomiHub-0.5.5-windows-x64-full.zip) | Bản portable đầy đủ (kèm M-Extension-Server + JRE cho tiện ích APK) |

Kiểm tra toàn vẹn: [SHA256SUMS-0.5.5.txt](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.5/SHA256SUMS-0.5.5.txt).

**Tiện ích website:** từ 0.5.3 nằm ở kho `https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json` (ứng dụng tự thêm khi cập nhật; cài thủ công: Duyệt › Tiện ích › Kho tiện ích).

**Chưa hỗ trợ:** Android 6.0 (CSDL Isar/libmdbx không mở được trên Android 6), Windows 7/8, Windows x86 và ARM (Flutter Windows chỉ hỗ trợ Windows 10+ x64). Chi tiết ở `TECHNICAL_UPDATE_NOTES.md`.

## Cấu trúc

| Thư mục / tệp | Nội dung |
|---|---|
| `overlay/` | **Mã nguồn YomiHub đầy đủ**: `lib`, `android`, `windows`, `assets`, `packages`, `test`, `pubspec.yaml`. Thư mục này được chép đè lên nền Mangayomi để dựng. |
| `src/mangayomi/` | Mã Mangayomi gốc (upstream) dùng làm nền. Xem `src/BASE_VERSION.txt`. |
| `build_055.ps1`, `sync_055.ps1`, `build_054.ps1`, `common.ps1`, `make_installer_exe.ps1`, `make_appxbundle.ps1`, `run_jobs*.ps1`, `*.bat` | Bộ script dựng APK, APK TV, Windows và đóng gói. |
| `audit-0.5.5/`, `audit-0.5.4/` | Kế hoạch, danh sách tệp thay đổi và tài liệu kiểm thử 0.5.4/0.5.5 (bảng theo dõi `QA_FEATURE_CHECK_TRACKER.md`). |
| `audit-0.3.9/` … `audit-0.5.3/` | Ghi chú, danh sách tệp đã sửa, ảnh kiểm thử của từng đợt trước. |
| `AGENTS.md`, `TECHNICAL_UPDATE_NOTES.md` | Quy định và nhật ký kỹ thuật bắt buộc đọc trước mỗi lần cập nhật. |

## Không có trong repo

Các tệp sau được loại qua `.gitignore`:

- khoá ký APK (`*.jks`), mật khẩu, `key.properties`, cookie;
- APK, EXE, ZIP, appxbundle và thư mục `output/` (bộ cài nằm ở **Releases**);
- log, hàng đợi `jobs/`;
- bản sao lưu từ thiết bị (`*.backup`, `latest_backup.zip`, dump thiết bị);
- ảnh và video QA cá nhân;
- bản sao trước khi sửa (`audit-*/before/`).

## Dựng

Xem phần 7 và mục 19 của `TECHNICAL_UPDATE_NOTES.md`. Các bước:

1. Chép `overlay/` đè lên `src/mangayomi` vào thư mục dựng.
2. Chạy `build_055.ps1 -step test|apk|tv|win|pack` (hoặc `build_054.ps1`) (Flutter 3.47.6, Dart 3.13.5).
3. Dựng APK cần khoá ký riêng của bạn trong `android/key.properties`. Tệp này không có trong repo.
