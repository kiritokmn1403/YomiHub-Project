<p align="center">
  <img width="160" height="160" src="https://raw.githubusercontent.com/YomiHub-Project/Yomi-Logo/main/YomiHub.png" alt="Logo YomiHub">
</p>
<h3 align="center">YomiHub</h3>
<p align="center">Đọc truyện, xem phim và quản lý tủ sách trong một ứng dụng.</p>
<p align="center"><a href="https://github.com/YomiHub-Project/YomiHub-Project/releases/tag/v0.6.7"><img src="https://img.shields.io/badge/Download-YomiHub_v0.6.7-blue?style=for-the-badge&logo=github" alt="Download YomiHub v0.6.7"></a></p>

## 📝 Mục lục

- [Giới thiệu](#about)
- [Tính năng](#features)
- [Tải về](#download)
- [Samsung TV (Tizen 3.0+) — bản xem trước](#samsung-tv)
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

**Có gì mới ở 0.6.7** (chi tiết: [YomiHub-0.6.7-changelog.md](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-changelog.md)):

- **YumiHub cho Samsung Smart TV (Tizen 3.0+, TV đời 2017 trở đi) — bản xem trước:** ứng dụng Tizen Web App (`.wgt`) chỉ có Phim & Điện ảnh, màn chờ 5 giây, thanh bên Thư viện · Cập nhật · Duyệt · Thêm, trình phát nhớ vị trí xem, nhập thư viện từ tệp sao lưu YomiHub; điều khiển bằng remote Samsung (mũi tên/OK/Return, Play/Pause/Stop/tua, phím màu A–D). Gói `.wgt` đã ký chỉ cài được trên TV có mã DUID nằm trong chứng chỉ Samsung đã ký gói — hiện là Samsung UA55MU6500 (đời 2017, Tizen 3.0); TV khác cần ký lại gói bằng chứng chỉ có DUID của TV đó.
- **Kiểm tra cập nhật kho tiện ích cho biết kho nào lỗi và vì sao** (DNS, hết thời gian, HTTP `<mã>`, sai định dạng) thay vì chỉ đếm số kho lỗi.
- **Nhật ký lỗi tiện ích ghi thêm ID nguồn và phiên bản tiện ích**; địa chỉ kho trong nhật ký được làm sạch (bỏ tài khoản, tham số, phân đoạn).
- **Sửa 8 lỗi:** hiện lại ảnh bìa từ bộ nhớ máy (`content://`, `file://`); tạm ngưng máy chủ ảnh lỗi (vd. `cdn.donmai.us`) 30 giây sau 8 lỗi liên tiếp; đổi tên kho tiện ích mặc định thành **YomiHub Extension Repo** (`YomiHub-Project/YomiHub-Extension-Repo`) và tự chuyển kho cũ sang địa chỉ mới (Issue #2); giữ đúng giới hạn số nguồn đồng thời của tìm kiếm toàn cục; bỏ qua trong 10 phút nguồn lỗi DNS khi tìm kiếm toàn cục; hết treo ~2,4 giây khi xem trước tệp sao lưu lớn; trình phát giữ vị trí xem khi tự đổi máy chủ do lỗi giữa chừng; bỏ nhắc `-full.zip` trên màn chẩn đoán Windows ở 66 ngôn ngữ.
- **Cải tiến độ ổn định:** kiểm thử tự động mới cho ảnh cục bộ, bộ ngắt máy chủ ảnh, đổi tên kho, tìm kiếm toàn cục và Issue #2; kiểm tra cú pháp ES5 và đóng gói `.wgt` cho Samsung TV trên GitHub Actions; cập nhật 65 ngôn ngữ; website chính thức tại [yomihub-project.github.io/Yomi-Website](https://yomihub-project.github.io/Yomi-Website/) và bản sao trên [yomihubproject.wordpress.com](https://yomihubproject.wordpress.com/).

**YumiHub Android TV** và **YumiHub Samsung TV** tập trung vào phim/anime. Theo phạm vi bản TV, Comic, Novel, Google Play Books, Booru và Tủ Sách Cá Nhân không nằm trong trải nghiệm này.

## ⬇️ Tải về <a name="download"></a>

[Download — YomiHub v0.6.7](https://github.com/YomiHub-Project/YomiHub-Project/releases/tag/v0.6.7)

Mã kiểm tra SHA-256 của từng tệp nằm trong `SHA256SUMS-0.6.7.txt`.

| Thiết bị | Tải về |
| :--- | :--- |
| **Android 7.0+** | [YomiHub-0.6.7-arm64-v8a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-arm64-v8a.apk) (khuyên dùng) · [YomiHub-0.6.7-armeabi-v7a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-armeabi-v7a.apk) · [YomiHub-0.6.7-x86_64.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-x86_64.apk) |
| **Android 6.0** | [YomiHub-0.6.7-android6-arm64-v8a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-android6-arm64-v8a.apk) · [YomiHub-0.6.7-android6-armeabi-v7a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-android6-armeabi-v7a.apk) · [YomiHub-0.6.7-android6-x86_64.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-android6-x86_64.apk) |
| **Android TV** (`YumiHub Android TV`) | [YumiHub-Android-TV-0.6.7-arm64-v8a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YumiHub-Android-TV-0.6.7-arm64-v8a.apk) · [YumiHub-Android-TV-0.6.7-armeabi-v7a.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YumiHub-Android-TV-0.6.7-armeabi-v7a.apk) · [YumiHub-Android-TV-0.6.7-x86_64.apk](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YumiHub-Android-TV-0.6.7-x86_64.apk) – không có Comic, Novel, Google Play Books, Booru, Tủ Sách Cá Nhân |
| **Samsung TV (Tizen 3.0+)** — bản xem trước | [YumiHub-SamsungTV-0.6.7.wgt](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YumiHub-SamsungTV-0.6.7.wgt) — chỉ cài được trên TV có mã DUID nằm trong chứng chỉ Samsung đã ký gói — hiện là Samsung UA55MU6500 (đời 2017, Tizen 3.0); TV khác cần ký lại gói bằng chứng chỉ có DUID của TV đó (mã nguồn: [tizen/](https://github.com/YomiHub-Project/YomiHub-Project/tree/main/tizen)) |
| **Windows 10/11 x64** | [YomiHub-0.6.7-windows-x64-Setup.exe](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-windows-x64-Setup.exe) (cài đặt) · [YomiHub-0.6.7-windows-x64.appxbundle](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-windows-x64.appxbundle) (kèm [YomiHub-RootCA.cer](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-RootCA.cer), [Install-YomiHub.bat](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/Install-YomiHub.bat) và [Install-YomiHub.ps1](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/Install-YomiHub.ps1)) · [YomiHub-0.6.7-windows-x64.zip](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-windows-x64.zip) (portable) — mọi gói Windows đã kèm sẵn M-Extension-Server + Java |
| **Kiểm tra & Ghi chú** | [SHA256SUMS-0.6.7.txt](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/SHA256SUMS-0.6.7.txt) · [YomiHub-0.6.7-changelog.md](https://github.com/YomiHub-Project/YomiHub-Project/releases/download/v0.6.7/YomiHub-0.6.7-changelog.md) |

## 📺 Samsung TV (Tizen 3.0+) — bản xem trước <a name="samsung-tv"></a>

- **Phạm vi:** Tizen Web App (`.wgt`, thuần ES5, chạy trên TV đời 2017+ (Tizen 3.0), đã kiểm thật trên UA55MU6500) chỉ gồm **Phim & Điện ảnh**, thanh bên **Thư viện · Cập nhật · Duyệt · Thêm**, nhớ vị trí xem, nhập thư viện từ tệp sao lưu `.backup` / `.backup.db` của YomiHub.
- **Điều khiển remote Samsung:** mũi tên D-pad / OK / Return, Play/Pause/Stop/tua lùi-tới, 4 phím màu **A–D** (Đỏ = Thư viện, Xanh lá = Cập nhật, Vàng = Duyệt, Xanh dương = Thêm).
- **Trạng thái & cài đặt:** hiện là **bản xem trước**, chưa có trên Samsung Apps. Gói `YumiHub-SamsungTV-0.6.7.wgt` trong Release chỉ cài được trên TV có mã DUID nằm trong chứng chỉ Samsung đã ký gói — hiện là Samsung UA55MU6500 (đời 2017, Tizen 3.0); TV khác cần ký lại gói bằng chứng chỉ có DUID của TV đó. Mã nguồn đặt tại [`tizen/`](https://github.com/YomiHub-Project/YomiHub-Project/tree/main/tizen); tự đóng gói, ký bằng chứng chỉ Samsung qua Tizen Studio CLI và cài thử qua **Developer Mode** (`1 2 3 4 5` trong mục Apps trên TV, kết nối `sdb connect <IP>:26101`).

## 📋 Yêu cầu hệ thống <a name="requirements"></a>

| Nền tảng | Yêu cầu |
| :--- | :--- |
| Android | Android 7.0 trở lên (bản `android6` riêng cho Android 6.0) |
| Android TV | Android TV 7.0 trở lên, điều khiển D-Pad |
| Samsung TV | Tizen 3.0 trở lên (Smart TV Samsung đời 2017+), điều khiển remote; gói `.wgt` phát hành chỉ cài trên TV có DUID trong chứng chỉ |
| Windows | Windows 10 / 11 x64 (nên có WebView2 Runtime để dùng trình duyệt tích hợp và vượt Cloudflare) |

## 🎈 Sử dụng <a name="usage"></a>

1. Tải bản phù hợp ở mục [Tải về](#download), cài đè lên bản cũ để giữ nguyên dữ liệu.
2. Mở **Thêm › Tiện ích** (Extensions) và thêm kho tiện ích của bạn (có thể dán nhiều URL cùng lúc); YomiHub không kèm sẵn nội dung.
3. Duyệt nguồn, thêm truyện/phim vào **Danh Mục** trong Thư viện; mục đã thêm có dấu nhận biết ở cả dạng lưới và danh sách.
4. Bật/tắt nhóm tính năng (Comic, Film & Movie, Novel, Booru, Tủ Sách…) trong phần cài đặt.
5. Sao lưu: dùng nút **Sao lưu nhanh** ở Thư viện hoặc màn Sao Lưu & Đồng Bộ (tệp cục bộ, Google Drive, OneDrive, Dropbox, Telegram).
6. Xem [Hướng dẫn](https://yomihub-project.github.io/Yomi-Website/guide.html) để biết chi tiết từng tính năng (bao gồm mục [Samsung TV (Tizen)](https://yomihub-project.github.io/Yomi-Website/guide.html#samsung-tv)).

## 🛣️ Lộ trình <a name="roadmap"></a>

Các hạng mục đã biết, chưa hoàn tất ở 0.6.7 (mục "Đã biết" trong changelog):

- [ ] Điều tra và xử lý tình trạng trình phát có lúc khựng 3–4 giây khi đổi máy chủ (dự kiến 0.6.8).
- [ ] Đưa YumiHub Samsung TV lên Samsung Apps (hiện gói `.wgt` chỉ cài được trên TV có DUID trong chứng chỉ).
- [ ] Hỗ trợ TeraBox (hiện chưa hỗ trợ).
- [ ] Android 6: một số nguồn vẫn bị giới hạn TLS.
- [ ] Một số tiện ích APK chỉ chạy được qua ApkBridge (điện thoại Android) trên Windows.

Đề xuất mới: mở [Issue](https://github.com/YomiHub-Project/YomiHub-Project/issues).

## 🤝 Đóng góp <a name="contributing"></a>

Báo lỗi và góp ý qua [GitHub Issues](https://github.com/YomiHub-Project/YomiHub-Project/issues): ghi phiên bản (dòng `[YH …]` trong nhật ký), nền tảng, các bước tái hiện; **che** `api_key`, token, mật khẩu trước khi đính kèm log. Muốn gửi mã: fork, tạo nhánh, mở Pull Request; hướng dẫn dựng trong [BUILDING.md](BUILDING.md).

## 📜 Giấy phép <a name="license"></a>

Phát hành theo [GNU GPL v3.0](LICENSE). YomiHub không lưu trữ nội dung; mọi nội dung đến từ các tiện ích do người dùng tự thêm.

## 📬 Liên hệ <a name="contact"></a>

Kênh chính thức: [GitHub Issues](https://github.com/YomiHub-Project/YomiHub-Project/issues) và tổ chức [YomiHub-Project](https://github.com/YomiHub-Project). Website: [GitHub Pages](https://yomihub-project.github.io/Yomi-Website/) · [WordPress](https://yomihubproject.wordpress.com/). Chính sách quyền riêng tư: [privacy](https://yomihub-project.github.io/Yomi-Website/privacy.html).

## 🙏 Lời cảm ơn <a name="acknowledgements"></a>

- Xây dựng trên [Mangayomi](https://github.com/kodjodevf/mangayomi) và cộng đồng tiện ích Mihon/Aniyomi/Kotatsu.
- Danh sách đầy đủ dự án GitHub và tài liệu tham khảo có trong ứng dụng: **Thêm › Giới thiệu › Dự án GitHub đã sử dụng**.
- Các nhà cung cấp dịch vụ tuỳ chọn (Google, Microsoft, Dropbox, Telegram, AniList, MyAnimeList…) thuộc chính sách của từng bên.

## 🔗 Liên kết <a name="links"></a>

- [Trang chủ (GitHub Pages)](https://yomihub-project.github.io/Yomi-Website/)
- [Website WordPress (bản sao)](https://yomihubproject.wordpress.com/)
- [Tải về](https://yomihub-project.github.io/Yomi-Website/download.html)
- [Hướng dẫn](https://yomihub-project.github.io/Yomi-Website/guide.html)
- [Chính sách quyền riêng tư](https://yomihub-project.github.io/Yomi-Website/privacy.html)
- [Báo lỗi](https://github.com/YomiHub-Project/YomiHub-Project/issues)
