# YomiHub

Ứng dụng đọc truyện tranh (Comic), xem phim (Film & Movie), đọc tiểu thuyết (Novel), Google Play Books và Booru App, xây dựng trên nhân [Mangayomi](https://github.com/kodjodevf/mangayomi) (Flutter). Từ 0.4.9 YomiHub chạy được cả **tiện ích vBook** (Darkrai9x/vbook-extensions, duongden/vbook và các kho cộng đồng).

**Phiên bản hiện tại: 0.5.8** (`17/11/2026`) – giữ nền Mangayomi hiện tại; hoàn thiện 11 nhóm tính năng & sửa lỗi cốt lõi (5 nhóm Core-Dev + 6 nhóm UI-Features), kiểm thử thành công trên Samsung Galaxy Note 9 (Android 10) và Windows Desktop. Có gì mới: [`YomiHub-0.5.8-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

Điểm chính của 0.5.8:
- **Sửa lỗi luồng tải ảnh MangaDex `Cannot add event after closing` (`uploads.mangadex.org`):** chuyển quyền sở hữu `StreamController` sang `_loadAsync`, không đóng luồng sớm trong `_loadNetwork`, thêm tự động thử lại với Referer tên miền gốc (`https://mangadex.org/`) & không Referer khi máy chủ trả mã lỗi 401/403/404/500+, tích hợp rate-limiting chống tràn log.
- **Triệt tiêu hiện tượng treo giao diện 2,6s – 2,9s khi cập nhật thư viện:** bóc tách DTO (`ChapterDiffInput`, `ChapterDiffResult`) và chuyển toàn bộ việc tính toán biểu thức chính quy (RegExp) trong `ChapterRecognition().chapterIdentityKey()` sang luồng nền qua `Isolate.run()`; giao dịch ghi Isar chỉ lưu danh sách đã tính toán mà không chiếm giữ luồng UI, giao diện duy trì 60 FPS mượt mà.
- **Tăng cường khả năng phục hồi nguồn tiện ích (Extension Resilience):** cập nhật gương dự phòng mặc định cho Anime47 (`anime47.best`, `anime47.tv`, `anime47.net`), AVSub (`animevietsub.best`), FikFap (`fikfap.com`, `fikfap.net`, `fikfap.org`); phân loại lỗi HTTP 404 thành lỗi dữ liệu nguồn có thông báo tiếng Việt trực quan; Google Drive 500 thêm backoff thử lại và bắt lỗi an toàn ở thư mục gốc (`depth == 0`); Shorts Pornhub định tuyến HLS (.m3u8) qua proxy `YomiVpnState.activeProxy()`.
- **Hỗ trợ quyền Health Connect Android 14+ (API 34+):** kiểm tra tính năng `MindfulnessSessionRecord` bằng reflection thay vì phụ thuộc cứng vào `SdkExtensions >= 15`; xin quyền bằng Intent `android.health.connect.action.MANAGE_HEALTH_PERMISSIONS` kèm tên gói ứng dụng; màn hình Health Connect hỗ trợ bấm để cấp quyền.
- **Màn hình khởi động (Splash Screen):** chuẩn hóa thời lượng chính xác 5 giây, logo bo tròn chuyển hình thái (morph animation) mượt mà từ hình vuông bo góc sang hình tròn hoàn chỉnh ($r = 66\text{px}$) từ $t=0.05$ đến $t=0.35$ (`Curves.easeInOutCubic`), giữ nguyên hình tròn cho đến khi hiệu ứng lỗ tròn thoát màn hình hoàn tất ($t=0.90..1.00$).
- **Giao diện Mangayomi phiên bản mới (Shiori Design System):** tích hợp thẻ và tiêu đề Shiori vào màn hình Hợp Nhất Tiện Ích (`ExtensionMergeScreen`) khi bật giao diện Hiện Đại; bổ sung công tắc `YomiUiStyleTile` tại mục Cài Đặt (chuyển đổi linh hoạt giữa Giao Diện Cũ và Mới).
- **Củng cố sao lưu Booru & Đồng bộ:** lưu trữ đầy đủ lịch sử tìm kiếm, mục yêu thích, cài đặt Booru vào Hive box `yomihub_booru` và khôi phục tự động qua hook `onRestored()`.
- **Bản địa hóa i18n 18 ngôn ngữ đối xứng 100%:** 1.657 khóa dịch trên toàn bộ 18 tệp JSON, toàn bộ 1.474 lệnh gọi `tr()` tĩnh đều có khóa chuẩn trong `en.json`.
- **Tiêu đề nhật ký ứng dụng (AppLogger):** tự động đính kèm tên thiết bị, phiên bản hệ điều hành và phiên bản ứng dụng trong dòng khởi tạo phiên (`===== Logger initialized (phiên mới) • $dev • YomiHub $ver =====`).

Kết quả kiểm thử thiết bị: Samsung Galaxy Note 9 (SM-N960N, Android 10, SDK 29): cài đặt thành công bản 0.5.8 (2051), khởi chạy ghi nhật ký phiên chuẩn xác, tải ảnh truyện ổn định qua CDN ngoại, cập nhật thư viện mượt mà không treo máy, Health Connect xử lý an toàn. Windows 11 (x64): phát hành kernel AOT sạch sẽ, bộ cài `.appxbundle` (ký số 0.5.8.0), `.exe` Setup installer và `.zip` portable hoạt động chuẩn xác. 78/78 bài kiểm thử tự động (unit & regression test) ĐẠT 100%.

## Tải về (Releases v0.5.8)

Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.8 (luôn có bản mới nhất ở [releases/latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)).

**Android 7.0 trở lên – Điện thoại / máy tính bảng**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.8-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-arm64-v8a.apk) | Hầu hết điện thoại/máy tính bảng (64-bit) |
| [YomiHub-0.5.8-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-armeabi-v7a.apk) | Máy ARM 32-bit đời cũ |
| [YomiHub-0.5.8-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-x86_64.apk) | Máy ảo / Chromebook x86_64 |

**Android 6.0 (API 23) – APK riêng, chỉ dùng cho Android 6.0**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.8-android6-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-android6-arm64-v8a.apk) | Máy Android 6.0 64-bit |
| [YomiHub-0.5.8-android6-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-android6-armeabi-v7a.apk) | Máy Android 6.0 32-bit |
| [YomiHub-0.5.8-android6-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-android6-x86_64.apk) | Máy ảo Android 6.0 x86_64 |

Android 6.0: APK này dành riêng cho Android 6.0 (kernel cũ, API 23). Từ Android 7.0 trở lên hãy dùng APK thường ở trên. Tor, GeckoView, PiP, IReader, Health Connect không dùng được (giống 0.5.7). 0.5.8 kế thừa toàn bộ các cải tiến QuickJS, bộ giải mã CBZ, Booru và tối ưu luồng Isolate.

**Android TV – YumiHub Android TV (bỏ Comic, Novel, Google Play Books, Booru)**

| Tệp | Dùng cho |
| --- | --- |
| [YumiHub-Android-TV-0.5.8-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YumiHub-Android-TV-0.5.8-arm64-v8a.apk) | TV box / Google TV 64-bit |
| [YumiHub-Android-TV-0.5.8-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YumiHub-Android-TV-0.5.8-armeabi-v7a.apk) | Đa số Android TV (32-bit) |
| [YumiHub-Android-TV-0.5.8-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YumiHub-Android-TV-0.5.8-x86_64.apk) | Máy ảo TV x86_64 |

**Windows 10/11 x64**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.8-windows-x64-Setup.exe](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64-Setup.exe) | Bản cài đặt .exe (khuyến nghị) |
| [YomiHub-0.5.8-windows-x64.appxbundle](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64.appxbundle) | Gói .appxbundle ký số – cần cài chứng chỉ trước (xem bên dưới) |
| [YomiHub-0.5.8-windows-x64.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64.zip) | Bản portable – giải nén và chạy `YomiHub.exe` |
| [YomiHub-0.5.8-windows-x64-full.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64-full.zip) | Bản portable đầy đủ (kèm M-Extension-Server + JRE cho tiện ích APK) |

**Tệp đi kèm**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-RootCA.cer](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-RootCA.cer) | Chứng chỉ để cài `.appxbundle` |
| [Install-YomiHub.bat](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/Install-YomiHub.bat) | Cài chứng chỉ + `.appxbundle` tự động |
| [Install-YomiHub.ps1](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/Install-YomiHub.ps1) | Kịch bản PowerShell cho `Install-YomiHub.bat` |
| [SHA256SUMS-0.5.8.txt](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/SHA256SUMS-0.5.8.txt) | Mã băm SHA-256 để kiểm tra toàn vẹn |
| [YomiHub-0.5.8-changelog.md](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-changelog.md) | Ghi chú phát hành 0.5.8 |

### Chọn tệp nào

- **Điện thoại / máy tính bảng Android 7.0 trở lên:** phần lớn máy là `arm64-v8a`; máy ARM 32-bit đời cũ dùng `armeabi-v7a`; máy ảo hoặc Chromebook dùng `x86_64`.
- **Android 6.0:** dùng APK `android6`, không dùng APK thường.
- **Android TV / TV box:** dùng `YumiHub-Android-TV-…`. TV box đời cũ thường là `armeabi-v7a`.
- **Windows 10/11 x64:** dùng `Setup.exe` (khuyến nghị). Dùng `.zip` hoặc `-full.zip` nếu muốn bản portable. Dùng `.appxbundle` kèm `Install-YomiHub.bat`, `Install-YomiHub.ps1`, `YomiHub-RootCA.cer` cùng thư mục.

### Cài đặt nhanh
- **Android / TV:** tải APK đúng kiến trúc, cho phép cài từ nguồn ngoài, mở tệp để cài. Cài đè bản 0.5.7 giữ nguyên dữ liệu (đã kiểm trên Note 9 và Windows).
- **Windows:** như 0.5.7 – `Setup.exe`, hoặc `.zip`/`-full.zip` portable, hoặc `.appxbundle` kèm `Install-YomiHub.bat`.
- **Kiểm tra toàn vẹn:** `sha256sum -c SHA256SUMS-0.5.8.txt` (Linux/macOS) hoặc `Get-FileHash` (Windows), rồi so với `SHA256SUMS-0.5.8.txt`.
- Không hỗ trợ: Windows 7/8/8.1, Windows 32-bit (x86), Windows ARM64, Android 5.x trở xuống.

---

**Phiên bản trước: 0.5.7** (`15/11/2026`) – giữ nền Mangayomi hiện tại; sửa lỗi trong nhật ký 12–14/11/2026 và thêm các mục còn lại của sheet "YomiHub Update" và "Feature Check". Có gì mới: [`YomiHub-0.5.7-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

Điểm chính của 0.5.7:
- Sửa lỗi từ nhật ký: lỗi "Null check operator" khi mở bảng chọn có thanh tab, Kotatsu bị đẩy vào cổng 9, Tor kẹt với cầu nối snowflake (tự đổi cầu nối), Cloudflare "đã giải xong nhưng vẫn không tải", kho `.pb` và kiểm tra cập nhật, phân loại lại lỗi tiện ích.
- Giao diện Mới (Shiori): ô bìa và huy hiệu kiểu Shiori; ẩn "gộp thư viện" khi dùng Mới.
- Hợp Nhất Tiện Ích: gom về một mục, chọn "Nguồn đọc" cho bộ đã hợp nhất.
- Google Play Books và Booru có công tắc bật/tắt trong "Bật/Tắt tính năng & Nguồn mở rộng".
- Trình phát: phát tiếp từ vị trí cũ ổn định hơn; Short Video nhận diện thêm tiện ích ngoài; công tắc "Ép chế độ Short".
- Health Connect: ghi phút đọc/xem; nhắc nghỉ mắt 20-20-20.
- Trình đọc: Yomikiru (phím tắt) và Yomihon (giãn dòng, thời gian đọc) – mặc định tắt.
- Trình duyệt: chống dấu vân tay có tác dụng (Chromium).

Kết quả kiểm thử thiết bị: Galaxy Note 9 (Android 10): hết lỗi "Null check", trang truyện hiện khoảng 3 giây, phát tiếp video đúng vị trí, không tua lặp, Quay lại không kẹt cửa sổ nổi. Máy ảo Android 10: video hiện hình (trước đây đen), APK TV mở được. Windows 11 (Intel Iris Xe + GTX 1650): hết cửa sổ trắng, cài đè giữ dữ liệu. Sao lưu/khôi phục hai chiều điện thoại ↔ máy tính: 4.490 bộ khôi phục đủ. Chưa kiểm trên máy thật: APK Android 6.0 trên máy ARM, đổi server khi phát video, Health Connect Android 14+, chia sẻ LAN/Bluetooth, Telegram.

## Tải về (Releases v0.5.7)

Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.7 (luôn có bản mới nhất ở [releases/latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)).

**Android 7.0 trở lên – Điện thoại / máy tính bảng**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.7-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-arm64-v8a.apk) | Hầu hết điện thoại/máy tính bảng (64-bit) |
| [YomiHub-0.5.7-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-armeabi-v7a.apk) | Máy ARM 32-bit đời cũ |
| [YomiHub-0.5.7-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-x86_64.apk) | Máy ảo / Chromebook x86_64 |

**Android 6.0 (API 23) – APK riêng, chỉ dùng cho Android 6.0**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.7-android6-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-android6-arm64-v8a.apk) | Máy Android 6.0 64-bit |
| [YomiHub-0.5.7-android6-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-android6-armeabi-v7a.apk) | Máy Android 6.0 32-bit |
| [YomiHub-0.5.7-android6-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-android6-x86_64.apk) | Máy ảo Android 6.0 x86_64 |

Android 6.0: APK này dành cho Android 6.0 (kernel cũ, API 23). Từ Android 7.0 trở lên hãy dùng APK thường ở trên. Tor, GeckoView, PiP, IReader, Health Connect không dùng được (giống 0.5.6.1). 0.5.7 sửa nạp QuickJS, bộ giải mã ảnh CBZ và ảnh Booru cho bản này; đã kiểm trên máy ảo Android 6.0, chưa kiểm trên máy thật.

**Android TV – YumiHub Android TV (bỏ Comic, Novel, Google Play Books, Booru)**

| Tệp | Dùng cho |
| --- | --- |
| [YumiHub-Android-TV-0.5.7-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YumiHub-Android-TV-0.5.7-arm64-v8a.apk) | TV box / Google TV 64-bit |
| [YumiHub-Android-TV-0.5.7-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YumiHub-Android-TV-0.5.7-armeabi-v7a.apk) | Đa số Android TV (32-bit) |
| [YumiHub-Android-TV-0.5.7-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YumiHub-Android-TV-0.5.7-x86_64.apk) | Máy ảo TV x86_64 |

**Windows 10/11 x64**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.7-windows-x64-Setup.exe](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-windows-x64-Setup.exe) | Bản cài đặt .exe (khuyến nghị) |
| [YomiHub-0.5.7-windows-x64.appxbundle](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-windows-x64.appxbundle) | Gói .appxbundle ký số – cần cài chứng chỉ trước (xem bên dưới) |
| [YomiHub-0.5.7-windows-x64.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-windows-x64.zip) | Bản portable – giải nén và chạy `YomiHub.exe` |
| [YomiHub-0.5.7-windows-x64-full.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-windows-x64-full.zip) | Bản portable đầy đủ (kèm M-Extension-Server + JRE cho tiện ích APK) |

**Tệp đi kèm**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-RootCA.cer](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-RootCA.cer) | Chứng chỉ để cài `.appxbundle` |
| [Install-YomiHub.bat](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/Install-YomiHub.bat) | Cài chứng chỉ + `.appxbundle` tự động |
| [Install-YomiHub.ps1](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/Install-YomiHub.ps1) | Kịch bản PowerShell cho `Install-YomiHub.bat` |
| [SHA256SUMS-0.5.7.txt](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/SHA256SUMS-0.5.7.txt) | Mã băm SHA-256 để kiểm tra toàn vẹn |
| [YomiHub-0.5.7-changelog.md](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-changelog.md) | Ghi chú phát hành 0.5.7 |

### Chọn tệp nào

- **Điện thoại / máy tính bảng Android 7.0 trở lên:** phần lớn máy là `arm64-v8a`; máy ARM 32-bit đời cũ dùng `armeabi-v7a`; máy ảo hoặc Chromebook dùng `x86_64`.
- **Android 6.0:** dùng APK `android6`, không dùng APK thường.
- **Android TV / TV box:** dùng `YumiHub-Android-TV-…`. TV box đời cũ thường là `armeabi-v7a`.
- **Windows 10/11 x64:** dùng `Setup.exe` (khuyến nghị). Dùng `.zip` hoặc `-full.zip` nếu muốn bản portable. Dùng `.appxbundle` kèm `Install-YomiHub.bat`, `Install-YomiHub.ps1`, `YomiHub-RootCA.cer` cùng thư mục.

### Cài đặt nhanh
- **Android / TV:** tải APK đúng kiến trúc, cho phép cài từ nguồn ngoài, mở tệp để cài. Cài đè bản 0.5.6.1 giữ nguyên dữ liệu (đã kiểm trên Note 9 và Windows).
- **Windows:** như 0.5.6.1 – `Setup.exe`, hoặc `.zip`/`-full.zip` portable, hoặc `.appxbundle` kèm `Install-YomiHub.bat`.
- **Kiểm tra toàn vẹn:** `sha256sum -c SHA256SUMS-0.5.7.txt` (Linux/macOS) hoặc `Get-FileHash` (Windows), rồi so với `SHA256SUMS-0.5.7.txt`.
- Không hỗ trợ: Windows 7/8/8.1, Windows 32-bit (x86), Windows ARM64, Android 5.x trở xuống.

---

**Phiên bản trước: 0.5.6.1** (`13/11/2026`) – bản vá của 0.5.6: sửa lỗi VPN và thêm **APK riêng cho Android 6.0**. Có gì mới: [`YomiHub-0.5.6.1-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

Điểm chính của 0.5.6.1: sửa VPN (link Xray có SNI/Host rỗng, Tor toàn thiết bị với danh sách ứng dụng rỗng, nhật ký "kết nối muộn" giả, tắt/bật Tor nhanh, WireGuard/WARP báo kết nối khi chưa bắt tay, lệch trạng thái sau khi vuốt app khỏi đa nhiệm). Kết quả kiểm thử VPN: ĐẠT trên máy ảo Android 14 x86_64 (12–13/11/2026): Tor toàn thiết bị (check.torproject.org), tắt/bật Tor nhanh (V4/V4b), WARP, VPN Gate, chuyển Tor→WARP, vuốt app rồi mở lại khi WARP/WireGuard đang bật (V7), WireGuard hồ sơ hỏng bị gỡ hầm + hồ sơ tốt bắt tay 0,4 s (V8); Xray chỉ có test đơn vị; chưa kiểm trên điện thoại thật. Kết quả kiểm thử Android 6.0: ĐẠT một phần trên máy ảo Android 6.0 x86_64 (API 23, 13/11/2026): mở app, CSDL Isar, HTTPS (bộ CA gốc đóng gói), WARP, Tor, mở lại sau khi bấm Back, nguồn cục bộ, EPUB, video, Play Books. Còn lỗi: ảnh xem trước Booru không hiện, trang ảnh CBZ báo "Không tải được ảnh này", tiện ích JavaScript (QuickJS) không chạy; bản ARM chưa thử trên máy Android 6 thật.

## Tải về (Releases v0.5.6.1)

Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.6.1 (luôn có bản mới nhất ở [releases/latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)).

**Android 7.0 trở lên – Điện thoại / máy tính bảng**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.6.1-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-arm64-v8a.apk) | Hầu hết điện thoại/máy tính bảng (64-bit) |
| [YomiHub-0.5.6.1-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-armeabi-v7a.apk) | Máy ARM 32-bit đời cũ |
| [YomiHub-0.5.6.1-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-x86_64.apk) | Máy ảo / Chromebook x86_64 |

**Android 6.0 (API 23) – APK riêng, chỉ dùng cho Android 6.0**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.6.1-android6-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-android6-arm64-v8a.apk) | Máy Android 6.0 64-bit |
| [YomiHub-0.5.6.1-android6-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-android6-armeabi-v7a.apk) | Máy Android 6.0 32-bit |
| [YomiHub-0.5.6.1-android6-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-android6-x86_64.apk) | Máy ảo Android 6.0 x86_64 |

Android 6.0: các APK này đã vá để chạy trên Android 6.0 (kernel cũ, API 23). Tor, GeckoView, PiP, IReader, Health Connect không dùng được; còn một số lỗi đã biết (xem changelog). Từ Android 7.0 trở lên hãy dùng APK thường ở trên.

**Android TV – YumiHub Android TV (chỉ Phim & Điện Ảnh)**

| Tệp | Dùng cho |
| --- | --- |
| [YumiHub-Android-TV-0.5.6.1-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YumiHub-Android-TV-0.5.6.1-arm64-v8a.apk) | TV box / Google TV 64-bit |
| [YumiHub-Android-TV-0.5.6.1-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YumiHub-Android-TV-0.5.6.1-armeabi-v7a.apk) | Đa số Android TV (32-bit) |
| [YumiHub-Android-TV-0.5.6.1-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YumiHub-Android-TV-0.5.6.1-x86_64.apk) | Máy ảo TV x86_64 |

**Windows 10/11 x64**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.6.1-windows-x64-Setup.exe](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-windows-x64-Setup.exe) | Bản cài đặt .exe |
| [YomiHub-0.5.6.1-windows-x64.appxbundle](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-windows-x64.appxbundle) | Gói .appxbundle ký số – cần cài chứng chỉ trước (xem bên dưới) |
| [YomiHub-0.5.6.1-windows-x64.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-windows-x64.zip) | Bản portable – giải nén và chạy `YomiHub.exe` |
| [YomiHub-0.5.6.1-windows-x64-full.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-windows-x64-full.zip) | Bản portable đầy đủ (kèm M-Extension-Server + JRE cho tiện ích APK) |

**Tệp đi kèm**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-RootCA.cer](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-RootCA.cer) | Chứng chỉ để cài `.appxbundle` |
| [Install-YomiHub.bat](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/Install-YomiHub.bat) | Cài chứng chỉ + `.appxbundle` tự động |
| [Install-YomiHub.ps1](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/Install-YomiHub.ps1) | Kịch bản PowerShell cho `Install-YomiHub.bat` |
| [SHA256SUMS-0.5.6.1.txt](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/SHA256SUMS-0.5.6.1.txt) | Mã băm SHA-256 để kiểm tra toàn vẹn |
| [YomiHub-0.5.6.1-changelog.md](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-changelog.md) | Ghi chú phát hành 0.5.6.1 |

### Cài đặt nhanh
- **Android / TV:** tải APK đúng kiến trúc (hầu hết điện thoại là `arm64-v8a`; TV box đời cũ thường là `armeabi-v7a`), cho phép cài từ nguồn ngoài, mở tệp để cài. Android 7.0+ dùng APK thường; **Android 6.0 dùng APK `android6`**.
- **Windows:** như 0.5.6 – `Setup.exe`, hoặc `.zip`/`-full.zip` portable, hoặc `.appxbundle` kèm `Install-YomiHub.bat`, `Install-YomiHub.ps1`, `YomiHub-RootCA.cer` trong cùng thư mục.
- **Kiểm tra toàn vẹn:** `sha256sum -c SHA256SUMS-0.5.6.1.txt` (Linux/macOS) hoặc `Get-FileHash` (Windows) rồi so với `SHA256SUMS-0.5.6.1.txt`.
- Không hỗ trợ: Windows 7/8/8.1, Windows 32-bit (x86), Windows ARM64 bản gốc, Android 5.x trở xuống.

---

**Phiên bản trước: 0.5.6** (`12/11/2026`). Có gì mới: [`YomiHub-0.5.6-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

Điểm chính của 0.5.6: mục **Thư Viện** gộp Truyện Tranh, Phim & Điện Ảnh, Tiểu Thuyết, Google Play Books (bản Android TV chỉ còn Phim & Điện Ảnh); công tắc giao diện **Cũ / Mới** (điều hướng nổi, tab viên; phần còn lại của giao diện Mới để 0.5.7); hạn mức sao lưu tự động; nút Kiểm Tra Cập Nhật cho tiện ích; sửa lỗi hàng đợi ghi Isar, cầu nối Kotatsu, Cloudflare, Tor, Telegram và phát tiếp video. Lỗi đã biết: cửa sổ Windows có thể hiện trắng chập chờn trên máy Intel driver cũ; 6 mô-đun tích hợp dự án (Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, GIF Viewer) chưa được nối vào ứng dụng. Kết quả kiểm thử trên thiết bị: `Mốc 2 duyệt 12/11/2026 00:40. Đạt: điện thoại thật Xiaomi Android 16 (cài đè 0.5.5→0.5.6 giữ dữ liệu, Thư Viện Cũ/Mới, giao diện Mới, phát tiếp video, sao lưu "Không giới hạn", không văng); AVD điện thoại (khởi động, Cũ/Mới, Sao Lưu, Kiểm Tra Cập Nhật "Kho thành công: 1. Kho lỗi: 0.", đọc chương ComicK); AVD Android TV (không có Truyện tranh/Tiểu thuyết/Play Books/Booru, D-pad, mở lần đầu không kẹt); Windows 11 x64 (giao diện chính, Thư Viện Cũ/Mới, Sao Lưu). Test tự động: 682/682 (Android) và 676/676 (Windows), analyze 0 lỗi. Chưa kiểm: VPN, Tor, Telegram, tracker, Health Connect, AirDrop/Quick Share, PiP đầy đủ, Short Video, cài đè Setup.exe trên Windows.`.

## Tải về (Releases v0.5.6)

Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.6 (luôn có bản mới nhất ở [releases/latest](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest)).

**Android 7.0 trở lên – Điện thoại / máy tính bảng**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.6-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-arm64-v8a.apk) | Hầu hết điện thoại/máy tính bảng (64-bit) |
| [YomiHub-0.5.6-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-armeabi-v7a.apk) | Máy ARM 32-bit đời cũ |
| [YomiHub-0.5.6-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-x86_64.apk) | Máy ảo / Chromebook x86_64 |

**Android TV – YumiHub Android TV (chỉ Phim & Điện Ảnh)**

| Tệp | Dùng cho |
| --- | --- |
| [YumiHub-Android-TV-0.5.6-arm64-v8a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YumiHub-Android-TV-0.5.6-arm64-v8a.apk) | TV box / Google TV 64-bit |
| [YumiHub-Android-TV-0.5.6-armeabi-v7a.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YumiHub-Android-TV-0.5.6-armeabi-v7a.apk) | Đa số Android TV (32-bit) |
| [YumiHub-Android-TV-0.5.6-x86_64.apk](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YumiHub-Android-TV-0.5.6-x86_64.apk) | Máy ảo TV x86_64 |

**Windows 10/11 x64**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-0.5.6-windows-x64-Setup.exe](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-windows-x64-Setup.exe) | Bản cài đặt .exe |
| [YomiHub-0.5.6-windows-x64.appxbundle](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-windows-x64.appxbundle) | Gói .appxbundle ký số – cần cài chứng chỉ trước (xem bên dưới) |
| [YomiHub-0.5.6-windows-x64.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-windows-x64.zip) | Bản portable – giải nén và chạy `YomiHub.exe` |
| [YomiHub-0.5.6-windows-x64-full.zip](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-windows-x64-full.zip) | Bản portable đầy đủ (kèm M-Extension-Server + JRE cho tiện ích APK) |

**Tệp đi kèm**

| Tệp | Dùng cho |
| --- | --- |
| [YomiHub-RootCA.cer](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-RootCA.cer) | Chứng chỉ để cài `.appxbundle` |
| [Install-YomiHub.bat](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/Install-YomiHub.bat) | Cài chứng chỉ + `.appxbundle` tự động |
| [Install-YomiHub.ps1](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/Install-YomiHub.ps1) | Kịch bản PowerShell cho `Install-YomiHub.bat` |
| [SHA256SUMS-0.5.6.txt](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/SHA256SUMS-0.5.6.txt) | Mã băm SHA-256 để kiểm tra toàn vẹn |
| [YomiHub-0.5.6-changelog.md](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-changelog.md) | Ghi chú phát hành 0.5.6 |

### Cài đặt nhanh
- **Android / TV:** tải APK đúng kiến trúc (hầu hết điện thoại là `arm64-v8a`; TV box đời cũ thường là `armeabi-v7a`), cho phép cài từ nguồn ngoài, mở tệp để cài. Cần Android 7.0 trở lên (Android 6.0 không hỗ trợ).
- **Windows – Setup.exe:** chạy bộ cài và làm theo hướng dẫn.
- **Windows – portable:** giải nén `.zip` (dùng `-full.zip` nếu cần tiện ích APK) rồi chạy `YomiHub.exe`.
- **Windows – .appxbundle:** tải `.appxbundle`, `Install-YomiHub.bat`, `Install-YomiHub.ps1`, `YomiHub-RootCA.cer` vào cùng một thư mục rồi chạy `Install-YomiHub.bat` (hoặc tự cài chứng chỉ trước).
- **Kiểm tra toàn vẹn:** `sha256sum -c SHA256SUMS-0.5.6.txt` (Linux/macOS) hoặc `Get-FileHash` (Windows) rồi so với `SHA256SUMS-0.5.6.txt`.
- Không hỗ trợ: Windows 7/8/8.1, Windows 32-bit (x86), Windows ARM64 bản gốc.
- Nếu cửa sổ Windows hiện trắng: đóng, mở lại sau 1–2 phút hoặc cập nhật driver đồ họa (lỗi đã biết, xem changelog).

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
