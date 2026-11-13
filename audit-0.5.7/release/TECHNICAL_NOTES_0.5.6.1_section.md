<!-- BẢN NHÁP – chèn cuối TECHNICAL_UPDATE_NOTES.md. Dòng tóm tắt cho mục "1. Trạng thái hiện tại" nằm ở cuối tệp này. -->

### 13/11/2026 — YomiHub 0.5.6.1 (0.5.6+49): sửa lỗi VPN + APK riêng cho Android 6.0

#### A. Yêu cầu và quyết định
- Chủ dự án (12/11/2026 21:00 và 23:18): số hiệu **0.5.6.1** = sửa VPN + APK Android 6.0 riêng bên cạnh APK Android 7.0+; 0.5.7 dành cho nền Mangayomi 0.9.95; không sửa tag/Release v0.5.6; phát hành sau "MỐC DUYỆT 0.5.6.1". Chi tiết: `audit-0.5.7/00_DECISIONS.md`.

#### B. Sửa lỗi VPN (V1–V8)
- Chi tiết, bằng chứng AVD và nguyên nhân: `audit-0.5.7/vpn/VPN_FIX.md`. Tệp: `lib/yomihub/vpn/vpn_tunnels.dart`, `vpn_service.dart`, `YomiVpn.kt`, `YomiTunnels.kt`, `YomiTorVpnService.kt`, `YomiWg.kt` (mới). Test: `test/yh_057_vpn_test.dart`, `test/yh_0561_vpn_resume_test.dart`.
- Kết quả kiểm thử VPN: ĐẠT trên máy ảo Android 14 x86_64 (12–13/11/2026): Tor toàn thiết bị (check.torproject.org), tắt/bật Tor nhanh (V4/V4b), WARP, VPN Gate, chuyển Tor→WARP, vuốt app rồi mở lại khi WARP/WireGuard đang bật (V7), WireGuard hồ sơ hỏng bị gỡ hầm + hồ sơ tốt bắt tay 0,4 s (V8); Xray chỉ có test đơn vị; chưa kiểm trên điện thoại thật

#### C. APK Android 6.0
- Chi tiết: `audit-0.5.7/android6/A6_FEASIBILITY.md`; dựng bằng `build_0561_android6.ps1` (thư mục `D:\yh\build23`, build-number 49). Kết quả kiểm thử: ĐẠT một phần trên máy ảo Android 6.0 x86_64 (API 23, 13/11/2026): mở app, CSDL Isar, HTTPS (bộ CA gốc đóng gói), WARP, Tor, mở lại sau khi bấm Back, nguồn cục bộ, EPUB, video, Play Books. Còn lỗi: ảnh xem trước Booru không hiện, trang ảnh CBZ báo "Không tải được ảnh này", tiện ích JavaScript (QuickJS) không chạy; bản ARM chưa thử trên máy Android 6 thật

#### D. Số hiệu và dựng/phát hành
- `overlay/pubspec.yaml` `version: 0.5.6+49`; `--build-name 0.5.6.1 --build-number 49`; `AppIdentity.userAgent = 'YomiHub/0.5.6.1'`. versionCode: armeabi-v7a 1049, arm64-v8a 2049, x86_64 4049. Windows MSIX/appxbundle 0.5.6.1.
- Script: `sync_0561.ps1`, `build_0561_android.ps1` (apk, tv, a6, verify), `build_0561.ps1` (test, win, pack, verify), `make_appxbundle_0561.ps1`, `make_installer_exe_0561.ps1`, `release_0561_publish.ps1`, `release_0561_fixed.ps1`. Thứ tự và thời gian: `audit-0.5.7/release/BUILD_PREP.md`.

#### E. Việc còn lại
- 0.5.7: chuyển nền Mangayomi 0.9.95. Android 6.0: ảnh Booru, trình đọc CBZ, `libqjs.so` (QuickJS), kiểm ARM thật. Windows: cửa sổ trắng (R21).

<!-- ===== Dòng tóm tắt cho mục "1. Trạng thái hiện tại" (đặt trên cùng danh sách) ===== -->
- **`<<NGÀY PHÁT HÀNH>>` – 0.5.6.1 (0.5.6+49), bản vá của 0.5.6:** sửa lỗi VPN (V1–V8: Xray SNI/Host rỗng, Tor danh sách ứng dụng rỗng, log "muộn" giả, tắt/bật Tor nhanh, WireGuard/WARP báo kết nối khi chưa bắt tay, lệch trạng thái sau khi vuốt app) và thêm 3 APK riêng cho Android 6.0 (`YomiHub-0.5.6.1-android6-*`); APK Android 7.0+ không đổi cấu hình. Kết quả VPN: ĐẠT trên máy ảo Android 14 x86_64 (12–13/11/2026): Tor toàn thiết bị (check.torproject.org), tắt/bật Tor nhanh (V4/V4b), WARP, VPN Gate, chuyển Tor→WARP, vuốt app rồi mở lại khi WARP/WireGuard đang bật (V7), WireGuard hồ sơ hỏng bị gỡ hầm + hồ sơ tốt bắt tay 0,4 s (V8); Xray chỉ có test đơn vị; chưa kiểm trên điện thoại thật. Kết quả Android 6.0: ĐẠT một phần trên máy ảo Android 6.0 x86_64 (API 23, 13/11/2026): mở app, CSDL Isar, HTTPS (bộ CA gốc đóng gói), WARP, Tor, mở lại sau khi bấm Back, nguồn cục bộ, EPUB, video, Play Books. Còn lỗi: ảnh xem trước Booru không hiện, trang ảnh CBZ báo "Không tải được ảnh này", tiện ích JavaScript (QuickJS) không chạy; bản ARM chưa thử trên máy Android 6 thật. Chi tiết: mục "13/11/2026 — YomiHub 0.5.6.1 (0.5.6+49)".
