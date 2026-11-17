
#### L. Sửa lỗi Tor – cầu nối (obfs4 / Snowflake / meek) cho Android (30/10/2026 15:20–)

**Vấn đề (0.4.4 mục A6, 0.4.5 mục B):** trên mạng chặn Tor, Tor Android dừng ở 50 % "Loading relay descriptors". Bản Android không có pluggable transport. IPtProxy không đóng gói được vì `libgojni.so` xung đột với `libmtorrentserver`.

**Giải pháp:**
1. Tải **Tor Expert Bundle 16.0 cho Android** (aarch64/armv7/x86_64) từ `archive.torproject.org` vào `D:\yh\tor_android`. SHA-256 khớp `sha256sums-signed-build.txt`.
2. Trong gói có `lyrebird` là tệp thực thi PIE độc lập (Go, không phải gomobile), nên không xung đột. Chép thành `android/app/src/main/jniLibs/<abi>/liblyrebird.so` (17–20 MB/ABI). Nhờ `useLegacyPackaging true`, Android giải nén tệp vào `nativeLibraryDir` và cho phép chạy, giống `libxray.so`. APK arm64 tăng 162,7 → 168,7 MB.
3. Danh sách cầu nối mặc định (`pt_config.json` của bundle: obfs4 ×7, snowflake ×2, meek ×1) lưu thành asset `assets/yomihub_vpn/tor_pt_config.json`.
4. `YomiVpn.kt`: phương thức mới `torBridges` (mode + bridge lines từ Dart). `applyBridge()` gửi qua control port của tor-android: `SETCONF ClientTransportPlugin meek_lite,obfs2,obfs3,obfs4,scramblesuit,webtunnel,snowflake exec <nativeLibraryDir>/liblyrebird.so`, `Bridge …`, `UseBridges 1` – **áp dụng ngay, không cần khởi động lại Tor** (tor-android chỉ chạy được 1 lần mỗi tiến trình). `startBridgeWatcher()` (luồng riêng, không chặn `io`):
   - chế độ cố định: áp dụng ngay khi control port sẵn sàng;
   - **"Tự động" (mặc định Android):** kết nối thẳng; nếu % bootstrap không tăng trong 40 s thì chuyển Snowflake; sau đó 75 s không tăng thì chuyển obfs4, rồi meek.
   - Báo về Dart `torBridge` / `torBridgeError`; `torInfo()` có khoá `bridge`.
5. `vpn_service.dart`: `torBridge` dùng cho cả Android (mặc định `auto`), `_sendTorBridges()` trước `torStart`. Đổi chế độ trên Android áp dụng trực tiếp (không tắt/bật Tor). Log `[VPN] Tor chưa kết nối trực tiếp được – chuyển sang cầu nối "…"`. Thông báo 90 s nói rõ đang thử cầu nối.
6. `vpn_screen.dart`: mục "Cầu nối (khi mạng chặn Tor)" hiện trên Android (Tự động / Tắt / Snowflake / obfs4 / meek), kèm "đang dùng: …".
7. 3 chuỗi mới, dịch đủ 18 ngôn ngữ (`audit-0.4.5/tr045b.py`; i18n 1.283 chuỗi, 0 thiếu). `dart analyze` 0 lỗi; `flutter test` 46/46.

**Kiểm thử trên Xiaomi 15T (APK arm64 dựng 15:47, video `p045_tor_bridges.mp4`, `p045_tor_snowflake.mp4`):**
- Mục Cầu nối hiện "Tự động: kết nối thẳng, nếu bị chặn thì thử Snowflake → obfs4 → meek" (`p90`).
- Bật Tor ở chế độ Tự động lúc 15:51. Lần này mạng **không chặn**: Tor kết nối trực tiếp lúc 15:54:05 (log `[VPN] Tor đã kết nối (muộn hơn thời gian chờ)…`), không cần cầu nối.
- Chọn **Snowflake** khi Tor đang chạy (16:04): sau 18 s có tiến trình `liblyrebird.so` (pid 18738) do tor khởi chạy → cơ chế `ClientTransportPlugin exec` hoạt động trên Android 16. Trạng thái vẫn "Đã kết nối".
- 16:06 điện thoại ngắt kết nối USB (`adb: device not found`), nên kiểm thử tiếp trên máy ảo.

**Kiểm thử trên máy ảo Android Studio** (theo yêu cầu người dùng). AVD `Medium_Phone_API_37.0`, x86_64, Android 17, DNS 8.8.8.8/1.1.1.1. APK `YomiHub-0.4.5-x86_64.apk` dựng lúc 16:40 và 17:30 (`-step apkx64` mới trong `build_045.ps1`).

Cách kiểm tra:
- Cổng SOCKS của Tor trên máy ảo được chuyển ra Windows (`adb forward tcp:19050 tcp:9050`).
- `curl.exe --socks5-hostname 127.0.0.1:19050 https://check.torproject.org/api/ip` trả `IsTor` (dịch vụ chính thức của Tor Project).
- Đối chiếu: gọi trực tiếp, không qua Tor, trả `{"IsTor":false,"IP":"222.252.212.181"}` (IP thật của mạng).

| Lúc | Chế độ cầu nối | Kết quả |
|---|---|---|
| 16:40–16:47 | **Snowflake** (chọn trước khi bật Tor) | `liblyrebird.so` (pid 8575, cùng uid app) chạy sau 13 s. VPN báo "Tor • Đã kết nối". `{"IsTor":true,"IP":"192.42.116.67"}`. Tải 13,98 MB qua Tor thành công (`speed.cloudflare.com`). Video `e045_tor_snowflake.mp4`. |
| 17:35–17:40 | **obfs4** (7 cầu nối mặc định của Tor Browser 16.0) | Tor dừng ở **2 % "Connected to pluggable transport"**. Như vậy cầu nối đã được dùng (Tor chỉ còn đi qua PT), nhưng các cầu nối obfs4 công khai **không hoạt động trên mạng này**. App hiện thông báo mới "…YomiHub đang thử cầu nối (Snowflake/obfs4/meek) ở nền…" (`e10`). |
| 17:43–17:44 | đổi trực tiếp sang **Snowflake** khi đang kẹt ở obfs4 | Không cần tắt Tor: sau **37 s** có `{"IsTor":true,"IP":"171.25.193.82"}`, VPN "Đã kết nối" (`e11_snowflake.png`, `e045_tor_snowflake2.mp4`). Nhật ký: `[VPN] … cầu nối "snowflake"`. |
| 17:56–18:00 | đổi sang **meek** (cdn77) | Nhật ký `… cầu nối "meek"` lúc 17:56:44. IP thoát đổi sang 204.8.96.111, `IsTor:true` liên tục 214 s (`e045_tor_meek.mp4`). |

Ghi chú:
- `/proc/net/tcp*` của máy ảo không cho thấy socket của uid app, nên kiểm chứng dựa vào `check.torproject.org` và trạng thái bootstrap.
- App mở trang "All files access" ở mỗi lần khởi động khi chưa có quyền. Trên **máy ảo kiểm thử**, đã cấp bằng `appops set … MANAGE_EXTERNAL_STORAGE allow` để ghi được `logs.txt`.

Chỉnh sau kiểm thử (18:00):
- Chế độ cố định ghi INFO `[VPN] Tor dùng cầu nối "…" (theo cài đặt)`. Chế độ Tự động mới ghi WARNING "…tự chuyển sang cầu nối…". Trước đó cả hai đều báo "chưa kết nối trực tiếp được".
- Thêm `torDiag` (UseBridges, số cầu nối, nút vào mạch đang dùng, bootstrap), ghi vào Nhật ký sau khi Tor kết nối hoặc đổi cầu nối. Nếu không đọc được thì ghi lý do.
- Dựng lại toàn bộ APK (3 ABI) và APK TV (`x045_117_full`).

**Đánh giá:**
- Tor trên Android giờ có cầu nối hoạt động (Snowflake, meek). Chế độ **Tự động** (mặc định) dùng thứ tự **Snowflake → obfs4 → meek** khi kết nối thẳng bị chặn.
- Chưa giả lập được mạng chặn Tor để chạy hết luồng Tự động. Trên mạng hiện tại, Tor kết nối thẳng được (Xiaomi 15T 15:54).
