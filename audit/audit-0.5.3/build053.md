- Công cụ: Flutter 3.47.6 / Dart 3.13.5, Android SDK + Emulator (Android Studio), Visual Studio 2022 (MSVC, dựng Windows), VS Code để đọc/sửa mã, Git, adb, ffmpeg. Lệnh: `sync_053.ps1` (chép 96 tệp của `audit-0.5.3/changed_files.txt` vào `D:\yh\build` và `D:\yh\buildwin`), `build_053.ps1 -step test|apk|tv|win|pack`.
- **Bản dựng 1**: kiểm thử đầu trên Note 9, TV AVD, emulator Android 17 và bản portable Windows. Phát hiện 3 lỗi → sửa ở bản dựng 2:
  1. HotPhim (HLS) dừng > 5 phút khi bật Tor "Chỉ YomiHub" vì proxy áp cho mọi URL → `YomiPlayerNet.apply` chỉ đặt `http-proxy` cho tệp video (mp4/m4v/webm/mkv/mov); Shorts thử lại nối thẳng một lần nếu lỗi.
  2. Xuất MAL khi chưa có mục theo dõi báo "anime 0, manga 0" → báo rõ "Không có mục nào đang theo dõi trên MyAnimeList hoặc AniList để xuất".
  3. Vị trí tự sao lưu trên thẻ nhớ đã tháo hiển thị như bình thường → chữ đỏ + tự lưu vào thư mục mặc định (`auto_backup.dart`, `data_and_storage.dart`, `tr053b.py` 2 chuỗi × 18 ngôn ngữ).
- **Bản dựng 2** (`jobs/done/p053_100_build2.log`, 16:42 → 17:26):
  - `flutter gen-l10n`; `dart analyze lib`: **0 lỗi**; `flutter test` 14 tệp (`yh_040` … `yh_053`): **122/122 đạt**.
  - APK điện thoại 16:47 → 17:01; APK TV 17:01 → 17:13 (`aapt2` xác nhận nhãn `YomiHub` / `YumiHub Android TV`); Windows 17:13 → 17:24 (VC++ runtime, xray + tor, bridge 54 jar 21,5 MB, JRE + M-Extension-Server); `pack` 17:26 (Setup.exe, appxbundle, `Install-YomiHub.bat/.ps1`, `YomiHub-RootCA.cer`, `SHA256SUMS-0.5.3.txt`).

| Tệp (`output/0.5.3`) | Kích thước | SHA-256 (đầu) |
| --- | --- | --- |
| YomiHub-0.5.3-arm64-v8a.apk | 168,8 MB | `902a5718…` (đúng tệp đã cài lên Note 9) |
| YomiHub-0.5.3-armeabi-v7a.apk | 165,6 MB | `6cfa35a3…` |
| YomiHub-0.5.3-x86_64.apk | 178,1 MB | `f6b47dc6…` |
| YumiHub-Android-TV-0.5.3-arm64-v8a.apk | 168,6 MB | `2e22ebdd…` |
| YumiHub-Android-TV-0.5.3-armeabi-v7a.apk | 165,4 MB | `28353209…` |
| YumiHub-Android-TV-0.5.3-x86_64.apk | 178,1 MB | `71f9e54e…` |
| YomiHub-0.5.3-windows-x64-Setup.exe (gói đầy đủ) | 267,2 MB | `96289ae7…` |
| YomiHub-0.5.3-windows-x64.appxbundle | 271,6 MB | `c46845de…` |
| YomiHub-0.5.3-windows-x64.zip (portable) | 139,2 MB | `44a82af0…` |
| YomiHub-0.5.3-windows-x64-full.zip (portable + JRE/MES) | 267,1 MB | `060826b9…` |

- **Galaxy Note 9** (SM-N960N, Android 10, Samsung DeX display 2; `audit-0.5.3/adb.sh`):
  - Bản dựng 1 cài đè 0.5.2 → 0.5.3 "Success"; bản dựng 2 cài đè lúc 17:06 (`versionName=0.5.3`).
  - Nhật ký: `[Kho tiện ích] Đã thêm kho Kiritokmn Extension Repo…` và chuyển 29 tiện ích (isLocal=false, có `repo`); kho xuất hiện trong danh sách kho Truyện tranh / Phim & Điện ảnh / Tiểu thuyết (`n9_53_16`, `n9_53_17`).
  - HotPhim và Anime47 hiện "Đang chờ cập nhật" → cập nhật từ kho thành công (`n9_53_20`); HotPhim danh sách Phổ biến, chi tiết, phát phim (`n9_53_24` … `n9_53_27`).
  - Thêm › Sao Lưu & Đồng Bộ và Cài đặt › Sao Lưu & Đồng Bộ: đủ tạo/khôi phục, tần suất, mã hoá, nén, vị trí, đám mây, đồng bộ, "Sao lưu dữ liệu Booru App"; tạo bản sao lưu **23,9 MB trong 13 s**, giao diện không treo (`n9_53_04` … `n9_53_12`).
  - Bật/Tắt tính năng › Tính năng khác: Google Play Books, Booru App (`n9_53_15`). Cài đặt không còn 2 ô này.
  - Theo dõi › Xuất danh sách MyAnimeList (XML) (`n9_53_31` … `n9_53_33`, bản dựng 2: `n9_53_52`).
  - Bản dựng 2: Tor "Chỉ YomiHub" → HotPhim phát được (AudioPlayer `state:started` 17:12:31; `n9_53_53` … `n9_53_57`); tắt VPN, phạm vi trả về "Chỉ YomiHub" (`n9_53_58`, `n9_53_59`).
  - `n9_logs_053a…e.txt`: không có văng/FATAL; 17–18 dòng `[ERROR]` đều do mạng hoặc nguồn bên ngoài (DNS `api.github.com` khi kiểm tra cập nhật, HTTP 404 của Rule34Video/Xvideos, Kohi-den lỗi TLS, Anime47 cần đăng nhập). Tệp nhật ký có tên mục trong thư viện nên không đưa lên GitHub.
- **VPN ngoài ứng dụng (Note 9):** Tor phạm vi "Toàn bộ thiết bị" → Chrome mở `check.torproject.org`: "Congratulations. This browser is configured to use Tor." (`n9_53_41`, IP che trong ảnh công khai). WARP: mạng chặn UDP → báo lỗi và gỡ đường hầm (`n9_53_37` … `n9_53_39`).
- **Emulator Android 17** (1080×2400, thanh cử chỉ): Thêm, Cài đặt, cuối danh sách Theo dõi, hộp đăng nhập Kitsu có bàn phím (`emu_53_01` … `emu_53_06`).
- **Android TV** (AVD `YomiHub_TV_API34`, APK TV `armeabi-v7a`): cài "Success", tên "YumiHub Android TV", thanh bên chỉ có Phim & Điện ảnh / Cập nhật / Duyệt / Thêm, HotPhim tải từ kho Kiritokmn, có viền focus D-pad (`tv_53_01` … `tv_53_04`).
- **Windows** (i5-11300H, GTX 1650 + Iris Xe, Windows build 26300):
  - Portable: nhật ký ghi dòng `[Windows] Chẩn đoán: …` và chuyển 29 tiện ích sang kho.
  - `Setup.exe` (bản dựng 2): cài vào `%LOCALAPPDATA%\YomiHub`, FileVersion **0.5.3+45**, có `yomihub_bin\mes` và VC++ runtime; tạo lối tắt Desktop + Start Menu; ứng dụng tự mở, `Responding = True`. Nút của trình cài được bấm bằng `SetCursorPos`/`mouse_event` (computer use bị chặn bởi Pickerhost). Video `win053_setup.mp4` (gdigrab).
  - Nhật ký sau cài (17:50–17:55): tự sao lưu báo "Vị trí … `/storage/3730-6132/…` không dùng được trên thiết bị này … dùng thư mục mặc định" (sửa của 0.5.3 hoạt động); các cảnh báo DNS lúc 17:50 là do máy mất mạng (cùng lúc phiên mất kết nối), không phải lỗi ứng dụng.
  - **Không chụp được nội dung cửa sổ Flutter**: ảnh trắng với cả `PrintWindow`, `gdigrab`, computer use, kể cả ứng dụng Flutter mẫu `hello_win` (`win_53_00_hello`); ffmpeg `ddagrab` báo "Operation not permitted". Giống 0.5.2: lỗi môi trường chụp màn hình, không phải lỗi ứng dụng.
- **Gói QA công khai:** `output/YomiHub-0.5.3-QA-screenshots.zip` (`audit-0.5.3/qa_zip.ps1`): 75 tệp (ảnh + `n9v053_02_build2_settings_tor.mp4`, `win053_setup.mp4`), 15,8 MB. Ảnh/video có thư viện cá nhân (`PRIVATE_*`, `n9v053_01_*`) chỉ giữ trong `audit-0.5.3/qa`, không đưa lên GitHub.
