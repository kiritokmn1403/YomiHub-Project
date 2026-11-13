# YomiHub 0.5.6.1 (0.5.6+49) – Bản vá VPN và APK riêng cho Android 6.0

> Ngày phát hành: `<<NGÀY PHÁT HÀNH>>` · Android 7.0+ (Điện thoại/Máy tính bảng và "YumiHub Android TV") · **Android 6.0 (APK riêng)** · Windows 10/11 x64

Bản vá của 0.5.6. Không thêm tính năng mới ngoài hai việc: (1) sửa lỗi VPN (Tor, Xray, WARP, WireGuard) và (2) thêm **APK riêng cho Android 6.0**. 0.5.7 vẫn dành cho việc chuyển nền Mangayomi 0.9.95. Mã VPN phía Dart dùng chung nên các gói Windows cũng được dựng lại. APK Android 7.0+ giữ `minSdk 24`, engine và Isar gốc.

## Sửa lỗi VPN

Kết quả kiểm thử VPN: ĐẠT trên máy ảo Android 14 x86_64 (12–13/11/2026): Tor toàn thiết bị (check.torproject.org), tắt/bật Tor nhanh (V4/V4b), WARP, VPN Gate, chuyển Tor→WARP, vuốt app rồi mở lại khi WARP/WireGuard đang bật (V7), WireGuard hồ sơ hỏng bị gỡ hầm + hồ sơ tốt bắt tay 0,4 s (V8); Xray chỉ có test đơn vị; chưa kiểm trên điện thoại thật

| # | Triệu chứng | Nguyên nhân và cách sửa |
| --- | --- | --- |
| V1 | Mihon Proxy/Xray với link vmess/vless TLS có `sni=` hoặc `host` rỗng: báo "kết nối" nhưng không ra Internet | Chuỗi rỗng không bị coi là thiếu nên SNI/Host bị đặt rỗng rồi thành địa chỉ IP. Sửa `_stream` (`vpn_tunnels.dart`): chuỗi rỗng rơi về giá trị kế tiếp |
| V2 | Tor toàn thiết bị, chế độ "ứng dụng đã chọn": nếu mọi gói đã chọn đều đã gỡ thì VPN áp cho cả máy, gồm chính YomiHub (Tor vào hầm của chính nó, mất mạng) | Danh sách cho phép rỗng = mọi ứng dụng. Sửa `YomiTorVpnService.kt`: không tạo hầm, báo lỗi tiếng Việt |
| V3 | Nhật ký ghi "Tor đã kết nối (muộn hơn thời gian chờ)" và chẩn đoán mạch hai lần ở mọi lần bật Tor | `_onTorLateOn` chạy ngay khi native báo ON, trước khi `torStart` trả về. Sửa `vpn_service.dart`: chờ `_pendingTorStart`; ON muộn thật vẫn được nhận |
| V4 | Tắt Tor khi dịch vụ còn đang kết nối: Tor vẫn khởi động nền sau đó | Nhánh `svc == null` của `torStop` chỉ đặt cờ OFF. Sửa `YomiVpn.kt` (cờ `torStopRequested`, `holdTorDormant`) |
| V4b | Bật lại Tor sau khi tắt sớm: "HTTP 0 • SOCKS 0", không tạo VPN thiết bị (lỗi phát sinh do V4) | TorService chỉ đọc cổng một lần. Sửa `YomiVpn.kt`: `refreshTorPorts()` hỏi `GETINFO net/listeners/*` |
| V5 | Tor kẹt 45–75% trên mạng chặn Tor | Do mạng/cầu Snowflake bên ngoài, không sửa trong mã |
| V6 | "Tor làm ứng dụng thoát" giả | Đã xử lý ở 0.5.2, không tái hiện |
| V7 | Vuốt ứng dụng khỏi đa nhiệm khi VPN bật rồi mở lại: giao diện báo "VPN đang tắt" hoặc kẹt "Đang kết nối…" trong khi WireGuard/WARP vẫn chạy | Mỗi Activity tạo `GoBackend` riêng nên không biết tunnel cũ. Sửa: một engine + tunnel WireGuard dùng chung cả tiến trình (`YomiWg.kt`), Dart hỏi trạng thái thật khi khởi tạo |
| V8 | WireGuard/WARP báo "Đã kết nối" khi chưa bắt tay (không ra Internet) | Sửa: chỉ báo "Đã kết nối" khi `getStatistics` có bắt tay (chờ tối đa 15 s); không có thì gỡ đường hầm (máy không mất mạng) và báo lỗi tiếng Việt. Bỏ 2 hồ sơ WARP WireGuard dựng sẵn (khóa cũ không còn bắt tay) – với Cloudflare dùng mục Cloudflare WARP |

## APK riêng cho Android 6.0

Tệp `YomiHub-0.5.6.1-android6-<abi>.apk` (arm64-v8a, armeabi-v7a, x86_64) **chỉ dành cho Android 6.0 (API 23)**; từ Android 7.0 trở lên hãy dùng APK thường. Cùng khóa ký với APK thường.

Kết quả kiểm thử Android 6.0: ĐẠT một phần trên máy ảo Android 6.0 x86_64 (API 23, 13/11/2026): mở app, CSDL Isar, HTTPS (bộ CA gốc đóng gói), WARP, Tor, mở lại sau khi bấm Back, nguồn cục bộ, EPUB, video, Play Books. Còn lỗi: ảnh xem trước Booru không hiện, trang ảnh CBZ báo "Không tải được ảnh này", tiện ích JavaScript (QuickJS) không chạy; bản ARM chưa thử trên máy Android 6 thật

- Nguyên nhân app không mở được trên Android 6.0: libmdbx của Isar từ chối kernel < 3.16 (`MDBX_INCOMPATIBLE`, "Không khởi động được YomiHub"). Đã hạ ngưỡng trong `libisar.so` (4 ABI), thêm `libyhcompat.so` cho các hàm API 24 (libflutter, libtor, libmpv ARM 32-bit), vá embedding Flutter (trợ năng, con trỏ chuột), bật `vmSafeMode` (ART 6.0 biên dịch sai handler VPN gộp), dùng `librust_lib_mangayomi.so` của bản chính.
- Vá thêm cho HTTPS và mạng: bộ CA gốc Mozilla đóng gói (121 CA, chỉ dùng khi Android < 7.0, không tắt kiểm tra chứng chỉ) cho cả Dart và Java; WireGuard/WARP (thay `CompletableFuture` của GoBackend); Tor (vá `FileObserver` của tor-android); bấm Back ở màn hình chính đưa app xuống nền thay vì đóng hẳn (trước đây mở lại bị kẹt ở logo).
- Không dùng được trên Android 6.0: GeckoView, PiP, IReader, Health Connect (yêu cầu API 26–28).
- **Lỗi đã biết trên Android 6.0** (chi tiết trong `audit-0.5.7/android6/A6_FEASIBILITY.md` và `CHECKPOINT.md`):
  - Booru: danh sách bài tải được nhưng ảnh xem trước không hiện.
  - Đọc truyện CBZ cục bộ: trang báo "Không tải được ảnh này".
  - Tiện ích chạy JavaScript (QuickJS/vBook) báo `libqjs.so not found`.
  - arm64-v8a / armeabi-v7a chưa chạy trên máy Android 6 thật (chỉ kiểm tĩnh); kernel rất cũ (3.4) có rủi ro hỏng CSDL hiếm gặp – nên bật sao lưu định kỳ.

## Số phiên bản và nâng cấp
- Windows: `YomiHub.exe` FileVersion 0.5.6.49, ProductVersion `0.5.6.1+49` (Kiểm Tra Cập Nhật đọc 0.5.6.1). Phiên bản hiển thị `0.5.6.1`, `versionCode` cơ sở 49: arm64-v8a 2049, armeabi-v7a 1049, x86_64 4049 (0.5.6 là 48). Windows `.appxbundle` 0.5.6.1.0 → `0.5.6.1`. User-Agent `YomiHub/0.5.6.1`.
- Cài đè 0.5.6 giữ dữ liệu (cùng khóa ký, versionCode cao hơn).

## Tệp phát hành
3 APK Android 7.0+, 3 APK `YumiHub Android TV`, 3 APK `android6`, 4 gói Windows x64 (`Setup.exe`, `.appxbundle`, `.zip`, `-full.zip`), `YomiHub-RootCA.cer`, `Install-YomiHub.bat/.ps1`, `SHA256SUMS-0.5.6.1.txt`.

## Chưa kiểm / còn mở
- Kiểm VPN trên máy ảo x86_64 (Android 14) và Android 6.0 (Tor, WARP); chưa thử WireGuard với hồ sơ thật khác, OpenVPN hồ sơ riêng, Xray với máy chủ thật (chỉ test đơn vị), DoH trong ứng dụng.
- V5 (mạng chặn Tor) ngoài mã.
- Vẫn như 0.5.6: cửa sổ Windows có thể trắng chập chờn trên Intel driver cũ (13/11 tái hiện với 0.5.6.1 sau khi cài đè Setup.exe, kể cả khi không có công cụ điều khiển màn hình); 6 mô-đun tích hợp dự án chưa nối vào ứng dụng.
