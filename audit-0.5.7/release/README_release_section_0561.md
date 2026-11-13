<!-- BẢN NHÁP – chèn vào README.md khi phát hành 0.5.6.1 (release_0561_publish.ps1 chèn phía trên khối 0.5.6 và đổi khối đó thành "Phiên bản trước"). -->

**Phiên bản hiện tại: 0.5.6.1** (`<<NGÀY PHÁT HÀNH>>`) – bản vá của 0.5.6: sửa lỗi VPN và thêm **APK riêng cho Android 6.0**. Có gì mới: [`YomiHub-0.5.6.1-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6.1/YomiHub-0.5.6.1-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

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
