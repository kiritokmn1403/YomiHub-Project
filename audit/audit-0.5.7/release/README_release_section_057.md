<!-- BẢN NHÁP – chèn vào README.md khi phát hành 0.5.7, sau khi dựng đủ gói, kiểm SHA256 và kiểm thử thiết bị. Thay khối 0.5.6.1 bằng "Phiên bản trước". Tên tệp lấy từ build_057.ps1, build_057_android.ps1, build_057_android6.ps1, make_installer_exe_057.ps1 và make_appxbundle_057.ps1; CHƯA dựng nên phải kiểm lại tên thật trên thư mục output\0.5.7 trước khi đăng. -->

**Phiên bản hiện tại: 0.5.7** (`<<NGÀY PHÁT HÀNH>>`) – giữ nền Mangayomi hiện tại; sửa lỗi trong nhật ký 12–14/11/2026 và thêm các mục còn lại của sheet "YomiHub Update" và "Feature Check". Có gì mới: [`YomiHub-0.5.7-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.7/YomiHub-0.5.7-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

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
