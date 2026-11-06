# YomiHub

Ứng dụng đọc truyện tranh (Comic), xem phim (Film & Movie), đọc tiểu thuyết (Novel), Google Play Books và Booru App, xây dựng trên nhân [Mangayomi](https://github.com/kodjodevf/mangayomi) (Flutter). Từ 0.4.9 YomiHub chạy được cả **tiện ích vBook** (Darkrai9x/vbook-extensions, duongden/vbook và các kho cộng đồng).

**Phiên bản hiện tại: 0.5.2** (06/11/2026). Có gì mới: [`YomiHub-0.5.2-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

Điểm chính của 0.5.2: **sao lưu / khôi phục** nhanh và không treo (đọc bản sao lưu TachiyomiMi 12 MB từ 45 s còn 8 s, Mangayomi 22 MB còn 11 s trên Galaxy Note 9; Gộp giữ nguồn và cài tiện ích có trong bản sao lưu, thêm chương còn thiếu cho bộ đã có); **Windows** kèm VC++ runtime, `Setup.exe` cài gói đầy đủ (Java + M-Extension-Server) và tự ghi chẩn đoán phần cứng/thành phần thiếu vào nhật ký (báo lỗi "thiếu tính năng" trên AMD Ryzen 9); **WARP** tự thử cổng khác khi mạng chặn UDP và không còn báo "Đã kết nối" giả; sửa các lỗi trong nhật ký 0.5.1 (thư viện, cập nhật thư viện, Tor, Anime47, FikFap, vBook, Subsplease…).

## Tải về (Releases v0.5.2)

Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.2 (luôn có bản mới nhất ở [releases/latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)).

### Android 7.0 trở lên

| Tệp | Dành cho |
|---|---|
| [YomiHub-0.5.2-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-arm64-v8a.apk) | Hầu hết điện thoại/máy tính bảng (64-bit) |
| [YomiHub-0.5.2-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-armeabi-v7a.apk) | Máy ARM 32-bit đời cũ |
| [YomiHub-0.5.2-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-x86_64.apk) | Máy ảo / Chromebook x86_64 |

### Android TV (YumiHub Android TV – chỉ Phim & Điện ảnh; không có Comic, Novel, Google Play Books, Booru)

| Tệp | Dành cho |
|---|---|
| [YumiHub-Android-TV-0.5.2-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YumiHub-Android-TV-0.5.2-arm64-v8a.apk) | TV box / Google TV 64-bit |
| [YumiHub-Android-TV-0.5.2-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YumiHub-Android-TV-0.5.2-armeabi-v7a.apk) | Đa số Android TV (32-bit) |
| [YumiHub-Android-TV-0.5.2-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YumiHub-Android-TV-0.5.2-x86_64.apk) | Máy ảo TV x86_64 |

### Windows 10/11 x64

| Tệp | Cách dùng |
|---|---|
| [YomiHub-0.5.2-windows-x64-Setup.exe](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-windows-x64-Setup.exe) | Bản cài đặt .exe |
| [YomiHub-0.5.2-windows-x64.appxbundle](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-windows-x64.appxbundle) | Bản cài .appxbundle – chạy [Install-YomiHub.bat](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/Install-YomiHub.bat) (kèm [Install-YomiHub.ps1](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/Install-YomiHub.ps1)) hoặc cài chứng chỉ [YomiHub-RootCA.cer](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-RootCA.cer) trước |
| [YomiHub-0.5.2-windows-x64.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-windows-x64.zip) | Bản portable – giải nén và chạy `YomiHub.exe`, không cần cài |
| [YomiHub-0.5.2-windows-x64-full.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-windows-x64-full.zip) | Bản portable đầy đủ (kèm M-Extension-Server + JRE cho tiện ích APK) |

Kiểm tra toàn vẹn: [SHA256SUMS-0.5.2.txt](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/SHA256SUMS-0.5.2.txt). Ảnh và video kiểm thử: [YomiHub-0.5.2-QA-screenshots.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-QA-screenshots.zip).

**Chưa hỗ trợ:** Android 6.0 (CSDL Isar/libmdbx không mở được trên Android 6), Windows 7/8, Windows x86 và ARM (Flutter Windows chỉ hỗ trợ Windows 10+ x64). Chi tiết ở `TECHNICAL_UPDATE_NOTES.md`.

## Cấu trúc

| Thư mục / tệp | Nội dung |
|---|---|
| `overlay/` | **Mã nguồn YomiHub đầy đủ**: `lib`, `android`, `windows`, `assets`, `packages`, `test`, `pubspec.yaml`. Thư mục này được chép đè lên nền Mangayomi để dựng. |
| `src/mangayomi/` | Mã Mangayomi gốc (upstream) dùng làm nền. Xem `src/BASE_VERSION.txt`. |
| `build_052.ps1`, `sync_052.ps1`, `release_052.ps1`, `common.ps1`, `make_installer_exe.ps1`, `make_appxbundle.ps1`, `run_jobs*.ps1`, `*.bat` | Bộ script dựng APK, APK TV, Windows và đóng gói. |
| `audit-0.5.2/adb.sh`, `tv.sh`, `framerec.ps1`, `dlg.ps1`, `audit-0.5.1/winqa.ps1` và các `test_*`/`record_*`/`take_*` | Script kiểm thử: adb, giả lập, chụp màn hình, quay video. |
| `audit-0.3.9/` … `audit-0.5.2/` | Ghi chú, danh sách tệp đã sửa, ảnh kiểm thử của từng đợt. |
| `AGENTS.md`, `TECHNICAL_UPDATE_NOTES.md` | Quy định và nhật ký kỹ thuật bắt buộc đọc trước mỗi lần cập nhật. |

## Không có trong repo

Các tệp sau được loại qua `.gitignore`:

- khoá ký APK (`*.jks`), mật khẩu, `key.properties`, cookie;
- APK, EXE, ZIP, appxbundle và thư mục `output/` (bộ cài nằm ở **Releases**);
- log, hàng đợi `jobs/`;
- ảnh và video QA (ảnh chụp kiểm thử Android/TV/Windows 0.5.2 được đính kèm Release: `YomiHub-0.5.2-QA-screenshots.zip`);
- bản sao trước khi sửa (`audit-*/before/`).

## Dựng

Xem phần 7 của `TECHNICAL_UPDATE_NOTES.md`. Các bước:

1. Chép `overlay/` đè lên `src/mangayomi` vào thư mục dựng (`sync_052.ps1` chỉ chép các tệp trong `audit-0.5.2/changed_files.txt`).
2. Chạy `build_052.ps1 -step test|unit|apk|tv|win|pack` (Flutter 3.47.6, Dart 3.13.5).
3. Dựng APK cần khoá ký riêng của bạn trong `android/key.properties`. Tệp này không có trong repo.
