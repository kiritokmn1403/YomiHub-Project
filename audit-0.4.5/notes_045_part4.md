
#### F. Dựng bản cài đầy đủ (30/10/2026, máy người dùng)

| Bước | Giờ | Kết quả |
|---|---|---|
| `build_045.ps1 -step apk` | 12:57–13:10 | 3 APK (arm64 162,7 MB, armv7 159,3 MB, x86_64 171,4 MB), Gradle 774 s |
| `-step tv` | 13:10–13:28 | 3 APK `YumiHub-Android-TV-0.4.5-*` (`IS_TV_BUILD=true`) |
| `-step win` | 13:29–13:42 | `flutter build windows` 579 s; `yomihub_bin` (xray + tor + lyrebird), JVM bridge 54 jar; zip 138,5 MB, full zip 266,3 MB |
| `-step pack` | 13:42–13:50 | `Setup.exe`, `.appxbundle` 270,8 MB (ký `CN=YomiHub, O=YomiHub, C=VN`), `Install-YomiHub.bat/.ps1`, `YomiHub-RootCA.cer`, `SHA256SUMS-0.4.5.txt` |

Kiểm tra lại APK arm64 bản cuối trên Xiaomi 15T (13:31): cài đè thành công (versionCode 2037). Thử chuyển 6 tab, không văng. Log từ 13:31 không có ERROR và không có "Khung hình chậm" (`p70`, `p71`, `p045_final_smoke.mp4`).

#### G. Windows (Windows 11 Pro build 26300; Intel Iris Xe 27.20.100.9664 + GTX 1650 32.0.16.1714)

**Setup.exe** (13:51–13:53, có điều khiển GUI, video `w045_setup_install.mp4`):
- Cài vào thư mục thử `D:\yh\qa_setup_045`, bỏ tạo lối tắt và bỏ tự chạy.
- Kết quả: thông báo "Cài đặt YomiHub v0.4.5 thành công!"; 192 tệp; `YomiHub.exe` 0.4.5+37; có `Uninstall.cmd`, `tor.exe`, `xray.exe`, 54 jar bridge.

**Portable**: giải nén ra 191 tệp.

**.appxbundle**:
- Chữ ký là `CN=YomiHub`. `Get-AuthenticodeSignature` báo `UnknownError` vì chứng chỉ tự ký chưa nằm trong kho tin cậy.
- Cài đặt cần chạy `Install-YomiHub.bat`. Bước này thêm chứng chỉ gốc vào máy, tức là thay đổi bảo mật, nên **người dùng tự thực hiện**.

**Cửa sổ trắng – đã khoanh vùng**:
- Sau khi máy khởi động lại (07:06), bản 0.4.4 portable và bản 0.4.5 cài đặt vẫn chỉ hiện cửa sổ trắng.
  - Tiến trình vẫn chạy bình thường: `Responding=True`, 511 MB.
  - Cửa sổ chỉ hiện sau khung hình đầu (`SetNextFrameCallback → Show()`), nghĩa là Dart đã dựng xong khung hình đầu.
- Đã dựng ứng dụng mẫu **`flutter create` (hello_win, Flutter 3.47.6)**. Ứng dụng mẫu này **cũng chỉ hiện cửa sổ trắng** (`w02_hello_flutter.png`).
  → Lỗi thuộc **trình hiển thị Flutter (ANGLE/D3D11) trên máy này**, không phải mã YomiHub.
- Đã thử cho riêng `hello_win.exe` khoá `SwapEffectUpgradeEnable=0;` ("Tối ưu cho trò chơi chạy cửa sổ"): vẫn trắng. Đã xoá khoá ngay sau khi thử.
- Máy không bật HDR (`AdvancedColorEnabled` trống).
- Thay đổi hệ thống duy nhất trùng thời điểm (28/10 còn hiển thị được, 29/10 trắng): Microsoft GamingServices cài driver `xvdd.inf` + `gameflt.inf` lúc **29/10 06:33** (`setupapi.dev.log`), và cập nhật Xbox Game Overlay lúc 29/10 22:32.
- Đề nghị người dùng:
  1. Cập nhật driver Intel Iris Xe (bản 2021).
  2. Thử tắt Game Bar / gỡ Gaming Services.
  3. Chạy thử trên máy Windows khác.
- Vì giao diện không hiện, **chưa kiểm thử được tính năng bên trong bản Windows**.

#### H. Đẩy mã lên GitHub

`.gitignore` thêm `/audit-0.4.5/iptproxy/`, `/_scratch/`, `/hako_repo/`, `vtv_*.html` (tệp tải về của bên thứ ba) và `/dev/x018/ref/` (414 MB mã nguồn tham khảo của bên thứ ba, không phải mã YomiHub).

#### I. Android TV (AVD `YomiHub_TV_API34`, 1920×1080, ABI x86/armeabi-v7a)

- `YumiHub-Android-TV-0.4.5-x86_64.apk` báo `INSTALL_FAILED_NO_MATCHING_ABIS`. Lý do: AVD này chỉ có x86/armv7, đúng như 0.4.4 đã dùng bản armv7. Cài bản `armeabi-v7a` thì thành công (0.4.5).
- Màn hình chính: "Thư viện Phim & Điện ảnh đang trống".
- Thanh bên chỉ có **Phim & Điện ảnh, Play Books, Booru, Cập nhật, Duyệt, Thêm** – không có Comic/Novel (`tv04_sidebar.png`, video `tv045_walk.mp4`).
- Lần mở đầu tiên, Android hiện trang "Allow access to manage all files" (quyền quản lý tệp của app). Bấm Back thì quay về app.

#### J. Sheet "Feature Check" (43 mục) – thay đổi ở 0.4.5

Các mục không liệt kê giữ trạng thái của 0.4.4.

- FC 3: mục A.
- FC 4/19/36: VTV Go `cache.vtvgo.vn`; các URL, ngôn ngữ, NSFW khác khớp sheet.
- FC 6/14: plugin LNReader (cheerio) – C5, C8.
- FC 13: WARP (C6), Tor bridge chưa làm được (mục B).
- FC 15/17/41: luồng trực tiếp, vị trí xem (C2).
- FC 25: splash (A2).
- FC 29/32: 0 chuỗi thiếu.
- FC 30/43: mục A2, C2, C4; log hiệu năng.
- FC 33: 0 dự án thiếu.
- FC 34: log chương tiểu thuyết, Booru, Telegram.
- FC 42: Booru Rule34.
- Sheet "YomiHub Update" mục Telegram: D (chờ người dùng đồng ý để thử tải lên thật).

**Còn mở:**
1. Cửa sổ trắng trên máy Windows này (G).
2. Khung hình chậm khi quay lại từ trang con (C4).
3. Chạm đầu tiên đôi khi bị bỏ qua.
4. Cầu nối Tor Android.
5. Thử tải lên/khôi phục Telegram thật.
6. Tính năng bên trong bản Windows chưa kiểm thử được.
