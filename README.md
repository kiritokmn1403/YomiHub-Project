<p align="center">
  <img width="160" height="160" src="https://raw.githubusercontent.com/YomiHub-Project/Yomi-Logo/main/YomiHub.png" alt="Logo YomiHub">
</p>
<h3 align="center">YomiHub</h3>
<p align="center">Đọc truyện, xem phim và quản lý tủ sách trong một ứng dụng.</p>
<p align="center"><a href="https://github.com/YomiHub-Project/YomiHub-Project/releases/tag/v0.6.6"><img src="https://img.shields.io/badge/Download-YomiHub-blue?style=for-the-badge&logo=github" alt="Download YomiHub"></a></p>

## 📝 Mục lục

- [Giới thiệu](#about)
- [Tính năng](#features)
- [Tải về](#download)
- [Yêu cầu hệ thống](#requirements)
- [Sử dụng](#usage)
- [Lộ trình](#roadmap)
- [Đóng góp](#contributing)
- [Giấy phép](#license)
- [Liên hệ](#contact)
- [Lời cảm ơn](#acknowledgements)
- [Liên kết](#links)

## 🧐 Giới thiệu <a name="about"></a>

YomiHub tập hợp trình đọc truyện tranh, trình phát phim/anime, trình đọc sách và các công cụ quản lý bộ sưu tập. Bạn có thể chọn các nhóm tính năng phù hợp với nhu cầu sử dụng.

## ✨ Tính năng <a name="features"></a>

- **Comic:** trình đọc truyện tranh trong ứng dụng.
- **Film & Movie:** trình phát phim và anime, có giao diện điều khiển dành cho TV.
- **Novel và sách trên máy:** trình đọc tiểu thuyết, EPUB và PDF.
- **Google Play Books:** màn hình Google Play Sách tích hợp.
- **Booru:** màn hình duyệt ảnh Booru và phần cài đặt riêng.
- **Tủ Sách Cá Nhân:** quản lý bộ sưu tập sách, quét mã (QR, EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, DataMatrix), nhập và xuất CSV.
- **Sao lưu:** giao diện sao lưu đám mây (Google Drive, OneDrive, Dropbox, MediaFire, Telegram); OneDrive và Dropbox dùng được ngay, Google Drive có lựa chọn đăng nhập tài khoản Google hoặc cấu hình Client ID riêng; tự dọn bản cũ theo "Số bản sao lưu giữ lại". Khả năng kết nối phụ thuộc cấu hình dịch vụ và nền tảng.
- **Trình duyệt tích hợp:** mở trang web trong ứng dụng và quản lý tùy chọn chặn quảng cáo.
- **Tùy chỉnh:** bật/tắt các nhóm tính năng và nguồn mở rộng từ phần cài đặt.

**Có gì mới ở 0.6.6** (chi tiết: [YomiHub-0.6.6-changelog.md](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-changelog.md)):

- **M-Extension-Server tự cài trên Windows** khi mở tiện ích APK lần đầu; tiện ích APK mà máy chủ Windows không chạy được **tự chuyển sang ApkBridge** đã lưu.
- **Hiển thị riêng từng Danh Mục**: nhấn giữ tên Danh Mục để chọn kiểu hiển thị, cách sắp xếp và thứ tự riêng (có trong bản sao lưu).
- **Tủ Sách Cá Nhân**: sắp xếp, lọc và mục **Đang cho mượn**; CSV nhận `;`, giá `120.000đ`, ngày `dd/mm/yyyy`; ảnh Tủ Sách nằm trong bản sao lưu.
- **Thanh điều hướng không còn che nút** cuối trang; sửa nút nổi che mục cuối danh sách, hàng chữ tràn trên màn hẹp, hộp thoại tràn khi mở bàn phím.
- Sửa vBook Anime47, Hako ghép sai địa chỉ, treo khi thêm kho tiện ích, Danbooru bị Cloudflare chặn trên Windows, `ERR_PROXY_CONNECTION_FAILED` của trình duyệt trong app.
- Tệp nhật ký đổi tên thành `YomiHub-log.txt`.

**YumiHub Android TV** tập trung vào phim/anime. Theo phạm vi bản TV, Comic, Novel, Google Play Books, Booru và Tủ Sách Cá Nhân không nằm trong trải nghiệm này.

## ⬇️ Tải về <a name="download"></a>

[Download — YomiHub v0.6.6](https://github.com/YomiHub-Project/YomiHub-Project/releases/tag/v0.6.6)

Mã kiểm tra SHA-256 của từng tệp nằm trong `SHA256SUMS-0.6.6.txt`.

| Thiết bị | Tải về |
| :--- | :--- |
| **Android 7.0+** | [YomiHub-0.6.6-arm64-v8a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-arm64-v8a.apk) (hầu hết điện thoại) · [YomiHub-0.6.6-armeabi-v7a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-armeabi-v7a.apk) · [YomiHub-0.6.6-x86_64.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-x86_64.apk) |
| **Android 6.0** | [YomiHub-0.6.6-android6-arm64-v8a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-android6-arm64-v8a.apk) · [YomiHub-0.6.6-android6-armeabi-v7a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-android6-armeabi-v7a.apk) · [YomiHub-0.6.6-android6-x86_64.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-android6-x86_64.apk) |
| **Android TV** (`YumiHub Android TV`) | [YumiHub-Android-TV-0.6.6-arm64-v8a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YumiHub-Android-TV-0.6.6-arm64-v8a.apk) · [YumiHub-Android-TV-0.6.6-armeabi-v7a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YumiHub-Android-TV-0.6.6-armeabi-v7a.apk) · [YumiHub-Android-TV-0.6.6-x86_64.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YumiHub-Android-TV-0.6.6-x86_64.apk) – không có Comic, Novel, Google Play Books, Booru, Tủ Sách Cá Nhân |
| **Windows 10/11 x64** | [YomiHub-0.6.6-windows-x64-Setup.exe](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-windows-x64-Setup.exe) (cài đặt) · [YomiHub-0.6.6-windows-x64.appxbundle](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-windows-x64.appxbundle) (kèm [YomiHub-RootCA.cer](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-RootCA.cer), [Install-YomiHub.bat](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/Install-YomiHub.bat) và [Install-YomiHub.ps1](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/Install-YomiHub.ps1)) · [YomiHub-0.6.6-windows-x64.zip](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-windows-x64.zip) (portable) · [YomiHub-0.6.6-windows-x64-full.zip](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-windows-x64-full.zip) (kèm Java cho tiện ích APK) |
| **Kiểm tra & Ghi chú** | [SHA256SUMS-0.6.6.txt](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/SHA256SUMS-0.6.6.txt) · [YomiHub-0.6.6-changelog.md](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.6/YomiHub-0.6.6-changelog.md) |

## 📋 Yêu cầu hệ thống <a name="requirements"></a>

| Nền tảng | Yêu cầu |
| :--- | :--- |
| Android | Android 7.0 trở lên (bản `android6` riêng cho Android 6.0) |
| Android TV | Android TV 7.0 trở lên, điều khiển D-Pad |
| Windows | Windows 10 / 11 x64 (nên có WebView2 Runtime để dùng trình duyệt tích hợp và vượt Cloudflare) |

## 🎈 Sử dụng <a name="usage"></a>

1. Tải bản phù hợp ở mục [Tải về](#download), cài đè lên bản cũ để giữ nguyên dữ liệu.
2. Mở **Thêm › Tiện ích** (Extensions) và thêm kho tiện ích của bạn (có thể dán nhiều URL cùng lúc); YomiHub không kèm sẵn nội dung.
3. Duyệt nguồn, thêm truyện/phim vào **Danh Mục** trong Thư viện; mục đã thêm có dấu nhận biết ở cả dạng lưới và danh sách.
4. Bật/tắt nhóm tính năng (Comic, Film & Movie, Novel, Booru, Tủ Sách…) trong phần cài đặt.
5. Sao lưu: dùng nút **Sao lưu nhanh** ở Thư viện hoặc màn Sao Lưu & Đồng Bộ (tệp cục bộ, Google Drive, OneDrive, Dropbox, Telegram).
6. Xem [Hướng dẫn](https://yomihub-project.github.io/YomiHub-Project/guide.html) để biết chi tiết từng tính năng.

## 🛣️ Lộ trình <a name="roadmap"></a>

Các hạng mục đã biết, chưa hoàn tất ở 0.6.6 (mục "Đã biết" trong changelog):

- [ ] Hỗ trợ TeraBox (hiện chưa hỗ trợ).
- [ ] Một số tiện ích APK chỉ chạy được qua ApkBridge (điện thoại Android) trên Windows.
- [ ] Android 6: một số nguồn bị giới hạn TLS (ví dụ MangaDex).
- [ ] Bảng bộ lọc nguồn có thể tràn khi điện thoại xoay ngang và đang mở bàn phím.

Đề xuất mới: mở [Issue](https://github.com/YomiHub-Project/YomiHub-Project/issues).

## 🤝 Đóng góp <a name="contributing"></a>

Báo lỗi và góp ý qua [GitHub Issues](https://github.com/YomiHub-Project/YomiHub-Project/issues): ghi phiên bản (dòng `[YH …]` trong nhật ký), nền tảng, các bước tái hiện; **che** `api_key`, token, mật khẩu trước khi đính kèm log. Muốn gửi mã: fork, tạo nhánh, mở Pull Request; hướng dẫn dựng trong [BUILDING.md](BUILDING.md).

## 📜 Giấy phép <a name="license"></a>

Phát hành theo [GNU GPL v3.0](LICENSE). YomiHub không lưu trữ nội dung; mọi nội dung đến từ các tiện ích do người dùng tự thêm.

## 📬 Liên hệ <a name="contact"></a>

Kênh chính thức: [GitHub Issues](https://github.com/YomiHub-Project/YomiHub-Project/issues) và tổ chức [YomiHub-Project](https://github.com/YomiHub-Project). Chính sách quyền riêng tư: [privacy](https://yomihub-project.github.io/YomiHub-Project/privacy.html).

## 🙏 Lời cảm ơn <a name="acknowledgements"></a>

- Xây dựng trên [Mangayomi](https://github.com/kodjodevf/mangayomi) và cộng đồng tiện ích Mihon/Aniyomi/Kotatsu.
- Danh sách đầy đủ dự án GitHub và tài liệu tham khảo có trong ứng dụng: **Thêm › Giới thiệu › Dự án GitHub đã sử dụng**.
- Các nhà cung cấp dịch vụ tuỳ chọn (Google, Microsoft, Dropbox, Telegram, AniList, MyAnimeList…) thuộc chính sách của từng bên.

## 🔗 Liên kết <a name="links"></a>

- [Trang chủ](https://yomihub-project.github.io/YomiHub-Project/)
- [Tải về](https://yomihub-project.github.io/YomiHub-Project/download.html)
- [Hướng dẫn](https://yomihub-project.github.io/YomiHub-Project/guide.html)
- [Chính sách quyền riêng tư](https://yomihub-project.github.io/YomiHub-Project/privacy.html)
- [Báo lỗi](https://github.com/YomiHub-Project/YomiHub-Project/issues)
