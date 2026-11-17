
**Windows 10/11 x64 (máy người dùng: Windows 10 Pro build 26300, Intel Iris Xe driver 27.20.100.9664 + NVIDIA GTX 1650 driver 32.0.16.1714):**
- `Setup.exe` 0.4.4: giao diện tiếng Việt đúng ("YomiHub 0.4.4 Setup - Cài Đặt YomiHub"). Cài vào `D:\yh\qa_setup_044`, bỏ lối tắt Desktop/Start Menu → "Cài đặt YomiHub v0.4.4 thành công!". Kết quả: 192 tệp, `YomiHub.exe` 0.4.4+36, có `Uninstall.cmd`, `yomihub_bin\tor\tor.exe`.
- `.appxbundle`: chữ ký số hợp lệ về cấu trúc (`CN=YomiHub, O=YomiHub, C=VN`). Chứng chỉ tự ký chưa có trong kho tin cậy nên cần chạy `Install-YomiHub.bat`. Bước này thay đổi cài đặt bảo mật, người dùng tự thực hiện (giống 0.4.3).
- **Lỗi chưa khắc phục được: cửa sổ trắng.** Bản portable 0.4.4 (cả bản dựng đợt 1 và bản cuối) mở ra chỉ là cửa sổ trắng.
  - Kiểm tra lại: **bản 0.4.3 cũng trắng y hệt** trên máy ở thời điểm này.
  - Tiến trình vẫn chạy (`Responding=True`), nhật ký ghi bình thường (tải kho, tải ảnh bìa). Cây UI Automation chỉ có `FLUTTERVIEW`. `PrintWindow` cũng ra ảnh trắng.
  - Khi đóng cửa sổ trắng (lần đóng 11:56), `flutter_windows.dll` văng `0xc0000005`/`0xc000041d` tại offset `0x1e220` (Windows Event Log).
  - Đã thử, đều vẫn trắng:
    1. Giải phóng RAM (6 GB trống, dừng Gradle).
    2. Tắt NVIDIA Overlay (người dùng đồng ý).
    3. Chọn GPU riêng cho `YomiHub.exe` qua `HKCU\Software\Microsoft\DirectX\UserGpuPreferences` (`GpuPreference=2` rồi `=1`; người dùng đồng ý; đã xoá khoá sau khi thử).
    4. Nhả quyền chụp màn hình của phiên.
    5. **Đổi bộ dựng hình**: stderr cho thấy Flutter 3.47 dùng **Impeller (OpenGLES SDF)** trên Windows. `windows/runner/main.cpp` nay đặt `project.set_impeller_switch(Disabled)` (dùng Skia; biến môi trường `YOMIHUB_IMPELLER=1` để bật lại Impeller). Sau đó stderr không còn dòng Impeller nhưng cửa sổ vẫn trắng.
  - Kết luận tạm: lỗi phía hệ thống (ANGLE/D3D11 trên bản Windows Insider 26300 + driver Intel đời 2021; ngày 28/10 bản 0.4.3 từng hiển thị bình thường trên cùng máy). Đề nghị: cập nhật driver Intel Iris Xe, khởi động lại máy, thử trên máy Windows khác.
  - Vì chưa nhìn thấy được giao diện nên **chưa kiểm thử được tính năng bên trong bản Windows** (Booru, đồng bộ, …). Chỉ xác minh được từ nhật ký: kho tiện ích tải được; dòng `kohiden.xyz` nay ở mức WARNING (bản sửa A3 có hiệu lực).

#### G. Bộ cài bàn giao (`output/0.4.4`, chép sang `..\output\0.4.4`)

| Tệp | Ghi chú |
|---|---|
| `YomiHub-0.4.4-arm64-v8a.apk`, `-armeabi-v7a.apk`, `-x86_64.apk` | Android 7.0+, dựng 15:40 (có sửa quét ảnh bìa). Xiaomi 15T: lần mở thứ 2 không còn dòng "Ảnh bìa lớn hơn 5 MB". |
| `YumiHub-Android-TV-0.4.4-*.apk` (3 ABI) | `IS_TV_BUILD=true`, tên "YumiHub Android TV", không có Comic/Novel. |
| `YomiHub-0.4.4-windows-x64-Setup.exe`, `.appxbundle`, `.zip` (portable), `-full.zip` (kèm JRE cho M-Extension-Server) | Windows 10/11 x64, renderer Skia. |
| `SHA256SUMS-0.4.4.txt`, `YomiHub-0.4.4-changelog.md`, `Install-YomiHub.bat/.ps1`, `YomiHub-RootCA.cer`, `qa/` | |

Việc còn lại / bản sau:
1. Tìm nguyên nhân cửa sổ trắng trên Windows của máy này (cập nhật driver, thử máy khác), rồi kiểm thử đầy đủ bản Windows.
2. Cầu nối Tor (obfs4/snowflake) cho Android.
3. Lần chạm đầu tiên vào thanh điều hướng sau khi mở app đôi khi bị bỏ qua.
4. Kết nối thật Rclone/MediaFire và cấp quyền Health Connect bằng tài khoản/quyết định của người dùng.
5. Android 6.0 (Isar/libmdbx) – giữ phương án B theo xác nhận của người dùng.
