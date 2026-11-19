<p align="center">
  <a href="https://github.com/kiritokmn1403/YomiHub-Project/releases/latest"><img width="160" height="160" src="logo/yomihub_logo_1024.png" alt="YomiHub logo"></a>
</p>

<h3 align="center">YomiHub</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![Latest release](https://img.shields.io/github/v/release/kiritokmn1403/YomiHub-Project?label=release)](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)
[![GitHub Issues](https://img.shields.io/github/issues/kiritokmn1403/YomiHub-Project.svg)](https://github.com/kiritokmn1403/YomiHub-Project/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/kiritokmn1403/YomiHub-Project.svg)](https://github.com/kiritokmn1403/YomiHub-Project/pulls)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

</div>

---

<p align="center"> Ứng dụng giải trí đa phương tiện mã nguồn mở: đọc truyện tranh (Comic), xem phim & Anime (Film & Movie), đọc tiểu thuyết (Novel), Google Play Books và duyệt ảnh Booru – trên Android, Android TV và Windows.
    <br>
    <br>
    <a href="https://github.com/kiritokmn1403/YomiHub-Project/releases/latest"><img src="https://img.shields.io/badge/Download-YomiHub%20Latest%20Release-blue?style=for-the-badge&logo=github" alt="Download YomiHub"></a>
</p>

## 📝 Mục lục

- [Giới thiệu](#about)
- [Bắt đầu](#getting_started)
- [Kiểm thử](#tests)
- [Sử dụng](#usage)
- [Dựng & phát hành](#deployment)
- [Công nghệ sử dụng](#built_using)
- [Tác giả](#authors)
- [Ghi nhận](#acknowledgement)

## 🧐 Giới thiệu <a name = "about"></a>

YomiHub gom các tính năng của nhiều ứng dụng đọc truyện/xem phim mã nguồn mở (Mangayomi, Aniyomi, Nekoyomi, Kotatsu, LNReader, IReader, Aidoku, vBook…) vào một ứng dụng duy nhất, tối ưu cho tiếng Việt và hỗ trợ 18 ngôn ngữ giao diện.

- **📖 Comic:** cuộn dọc (Webtoon), lật trang đơn/đôi, đọc phải sang trái, lọc màu, tải trước chương và tải về đọc ngoại tuyến.
- **🎬 Film & Movie:** trình phát mpv (media_kit), Picture-in-Picture, nhớ vị trí xem, đổi máy chủ/luồng phát, tải tập về máy; giao diện Short Video vuốt dọc (YouTube Shorts, TikTok, Kwai, RedGifs, Facebook Reels, Snapchat Spotlight, Moj…).
- **📚 Novel & Google Play Books:** tiểu thuyết trực tuyến, đọc EPUB/PDF trên máy, tùy chỉnh chữ/giãn dòng/nền tối; Google Play Sách nhúng trong ứng dụng.
- **🎨 Booru App:** tìm, duyệt và tải ảnh từ các nguồn Booru, gợi ý thẻ, yêu thích và lịch sử tìm kiếm.
- **🔌 Tiện ích nhiều nền tảng:** Mihon/Tachiyomi, Aniyomi, Mangayomi, Kotatsu, LNReader, IReader, Aidoku, vBook; gợi ý kho tiện ích; hợp nhất nhiều nguồn của cùng một bộ truyện/phim. Bộ lọc của mọi tiện ích dùng ô chọn (chọn một, sắp xếp ↑/↓, thể loại bao gồm → loại trừ → tắt).
- **🛡️ VPN & DNS:** Tor (cầu nối Snowflake/obfs4), Cloudflare WARP, proxy riêng, DNS-over-HTTPS; bật cho từng tiện ích hoặc toàn ứng dụng; hỗ trợ vượt Cloudflare qua WebView.
- **☁️ Sao lưu & đồng bộ:** chọn từng mục sao lưu (thư viện, lịch sử, tiện ích, cài đặt, dữ liệu Booru); đăng nhập Google để sao lưu lên Google Drive, ngoài ra OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram Bot.
- **🧭 Trình duyệt tích hợp:** nhiều tab, chặn quảng cáo, công cụ Savior tải video và quét mã trang tìm link m3u8/mp4.
- **🩺 Tiện ích khác:** đồng bộ thời gian đọc/xem với Health Connect, nhắc nghỉ mắt 20-20-20, theo dõi tiến độ trên các trình theo dõi (AniList, MAL, Trakt…).

## 🏁 Bắt đầu <a name = "getting_started"></a>

### Yêu cầu

| Nền tảng | Yêu cầu |
| :--- | :--- |
| Android | Android 7.0 trở lên (bản `android6` riêng cho Android 6.0) |
| Android TV | Android TV 7.0 trở lên, điều khiển D-Pad |
| Windows | Windows 10 / 11 x64 |

### Cài đặt

Tải gói phù hợp tại trang [Releases Latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest):

| Thiết bị | Tệp | Ghi chú |
| :--- | :--- | :--- |
| **Android 7.0+** | `YomiHub-*-arm64-v8a.apk` · `YomiHub-*-armeabi-v7a.apk` · `YomiHub-*-x86_64.apk` | Hầu hết điện thoại hiện nay dùng `arm64-v8a`. |
| **Android 6.0** | `YomiHub-*-android6-*.apk` | Bản tinh giản cho máy Android 6.0. |
| **Android TV** | `YumiHub-Android-TV-*.apk` | Tập trung Phim & Anime (không có Comic, Novel, Play Books, Booru). |
| **Windows 10/11** | `YomiHub-*-windows-x64-Setup.exe` · `.appxbundle` · `.zip` · `-full.zip` | Bản `-full.zip` kèm M-Extension-Server để chạy tiện ích APK (Mihon/Aniyomi) trên Windows. |

Mỗi bản phát hành có tệp `SHA256SUMS-<phiên bản>.txt` để kiểm tra tính toàn vẹn. Cài đè lên bản cũ giữ nguyên dữ liệu; ứng dụng tự kiểm tra cập nhật từ GitHub Releases.

## 🔧 Kiểm thử <a name = "tests"></a>

Mỗi phiên bản được kiểm tra trước khi phát hành:

- **Kiểm thử tự động:** bộ test Flutter (`overlay/test/yh_*_test.dart`, hơn 900 test) chạy ở bước `test` của dây chuyền dựng, cùng `dart analyze` các tệp thay đổi.
- **Thiết bị thật:** điện thoại Android (Samsung Galaxy Note 9, Xiaomi) qua adb, Windows 11 (bản portable và Setup.exe); bằng chứng (ảnh, log) lưu trong `audit/audit-<phiên bản>/evidence/`.
- **Kho & tiện ích:** kiểm HTTP, định dạng chỉ mục và số tiện ích của các kho được gợi ý.

## 🎈 Sử dụng <a name="usage"></a>

1. Mở ứng dụng → **Duyệt › Tiện ích**: thêm kho (hoặc chọn kho gợi ý) và cài tiện ích cho Comic / Film & Movie / Novel.
2. **Duyệt › Nguồn**: mở nguồn, dùng **Bộ lọc** hoặc tìm kiếm, thêm truyện/phim vào **Thư viện**.
3. Bật **VPN & DNS** (Tor/WARP/proxy) trong Cài đặt nếu nguồn bị chặn.
4. **Thêm › Sao Lưu & Đồng Bộ** để sao lưu cục bộ hoặc lên Google Drive và các dịch vụ đám mây khác.

## 🚀 Dựng & phát hành <a name = "deployment"></a>

YomiHub được dựng trên nền mã nguồn Mangayomi; mọi thay đổi riêng nằm trong `overlay/` và được đồng bộ sang thư mục dựng bằng script. Dây chuyền `run_<ver>_main.ps1` chạy tuần tự: đồng bộ → test → APK → Android TV → test Windows → dựng Windows → đóng gói (Setup.exe, .appxbundle, .zip) → APK android6 → xác minh (chữ ký, phiên bản, SHA256). Bản phát hành được tải lên GitHub Releases bằng `release_<ver>.ps1`. Chi tiết kỹ thuật và lịch sử thay đổi: [TECHNICAL_UPDATE_NOTES.md](TECHNICAL_UPDATE_NOTES.md).

## ⛏️ Công nghệ sử dụng <a name = "built_using"></a>

- [Flutter](https://flutter.dev/) & Dart – giao diện đa nền tảng (Android, Windows)
- [Mangayomi](https://github.com/kodjodevf/mangayomi) – mã nền ứng dụng
- [Isar](https://github.com/isar/isar) (isar_community) – cơ sở dữ liệu
- [media_kit](https://github.com/media-kit/media-kit) – trình phát video (mpv)
- Riverpod, go_router, flutter_qjs (QuickJS cho tiện ích JavaScript)
- [tor-android](https://github.com/guardianproject/tor-android), [Xray-core](https://github.com/XTLS/Xray-core) – Tor và VPN

## ✍️ Tác giả <a name = "authors"></a>

- [@kiritokmn1403](https://github.com/kiritokmn1403) – ý tưởng, quản lý dự án và phát hành

## 🎉 Ghi nhận <a name = "acknowledgement"></a>

- [Mangayomi](https://github.com/kodjodevf/mangayomi), [Aniyomi](https://github.com/aniyomiorg/aniyomi), [Nekoyomi](https://github.com/Seguaz/Nekoyomi), [Tachiyomi](https://github.com/tachiyomiorg), [Kotatsu](https://github.com/KotatsuApp), [LNReader](https://github.com/LNReader/lnreader) và các dự án khác – nguồn cảm hứng và mã tham khảo.
- Cộng đồng tác giả tiện ích và kho tiện ích.
- Danh sách đầy đủ các dự án GitHub đã sử dụng có trong ứng dụng: **Thêm › Giới thiệu › Dự án GitHub đã sử dụng**.

> Giấy phép: [GNU GPL v3.0](LICENSE). YomiHub không lưu trữ nội dung; mọi nội dung đến từ các tiện ích do người dùng tự thêm.
