<!-- BẢN NHÁP – thay mục "Phiên bản hiện tại" và "Tải về" trong README.md khi phát hành 0.5.6 (sau Mốc 2 và khi đã có Release v0.5.6). -->

**Phiên bản hiện tại: 0.5.6** (`12/11/2026`). Có gì mới: [`YomiHub-0.5.6-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.6/YomiHub-0.5.6-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).

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
