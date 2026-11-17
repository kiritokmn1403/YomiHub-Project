
#### E. Dựng bản cài (máy người dùng, 29/10/2026)

| Bước | Kết quả |
|---|---|
| `build_044.ps1 -step test` (10:36, 10:46, 11:47) | `dart analyze` 26 tệp đã sửa: **0 lỗi** (11 info/warning có từ trước: `unnecessary_non_null_assertion`, `curly_braces_in_flow_control_structures`…); `flutter test` yh_040–044: **41/41 đạt** (yh_044 mới: 14 nhóm kiểm thử – log rhttp/stack, Kill switch, tên miền dự phòng, 4 họ API booru, Cloudflare/API key, lọc NSFW/thẻ chặn, sao lưu yêu thích, autocomplete). `yh_043_test` sửa kỳ vọng phiên bản thành `startsWith('YomiHub/0.4.')`. |
| Lỗi dựng 1: job runner bỏ qua apk/tv/win/pack (10:50) | Điều kiện dừng `-match 'ERROR'` khớp nhầm tên tệp `ext_errors.dart` trong dòng lệnh analyze → đổi thành `-cmatch '\] ERROR: '`. |
| APK đợt 1 (10:54–11:11), TV (11:11–11:27), Windows + pack (11:28–11:47) | Thành công – dùng cho kiểm thử đợt 1 trên Xiaomi 15T. |
| Lỗi dựng 2 (12:16, 12:23, 12:27): `minifyReleaseWithR8 … coreLibDesugarConfig … FileNotFoundException …\transforms\a73013d…\workspace\transformed\desugar_jdk_libs_configuration-2.1.5-desugar.json`, rồi `checkReleaseAarMetadata … fragment-1.7.1` | Bộ đệm transform của Gradle bị thiếu thư mục `workspace` (hệ quả của script dọn ở 0.4.3) và một **Gradle daemon + Kotlin daemon chạy bằng JBR của Android Studio** (`D:\Programs\ADS\jbr`) vẫn giữ trạng thái cũ/khoá tệp. Xử lý: xoá các thư mục transform hỏng (`044_30_fixcache.ps1`), xoá `android\.gradle` của bản dựng, dừng mọi tiến trình `GradleDaemon/KotlinCompileDaemon` (`044_50_killgradle.ps1`) → Gradle tạo lại bộ đệm (lần dựng sau mất 52 phút). |
| Lỗi dựng 3 (13:22): `lintVitalRelease`: `MainActivity must extend android.app.Activity [Instantiatable]` | Báo nhầm (MainActivity kế thừa FlutterFragmentActivity) khi lint chạy trên bộ đệm vừa tạo lại. `android/app/build.gradle`: `lint { checkReleaseBuilds false; abortOnError false }`. |
| APK cuối 13:22–13:37 → thiếu sửa quét ảnh bìa (sửa lúc 13:50) → dựng lại APK + TV + pack sau khi kiểm thử Windows. | Xem mục F, G. |

#### F. Kiểm thử (ảnh/video ở `output/0.4.4/qa/`)

**Xiaomi 15T (Android 16, HyperOS), APK arm64 0.4.4 (versionCode 2036) – cài đè giữ dữ liệu:**
- Khởi động: ổn định, không văng; thanh dưới có 8 mục, **Booru ở bên phải Play Books** (`p02_home`, video `p044_start.mp4`).
- Booru App (`p05`–`p19`, `f04`–`f10`, video `p044_booru1/2.mp4`, `f044_final_walk.mp4`):
  - Safebooru tải lưới ảnh; tìm "scenery" cho kết quả.
  - Gợi ý thẻ đạt ở bản cuối: "scen" → scenery 65.949, scene reference 6.198… Bản đợt 1 chưa có gợi ý cho Safebooru vì API thẻ trả XML; đã sửa.
  - Trình xem: bản đợt 1 còn hiện thanh dưới; bản cuối **toàn màn hình**, vuốt sang ảnh kế.
  - ♥ Yêu thích hiện ở tab Yêu thích.
  - Tải xuống: tệp `safebooru_org_7272274.jpg` nằm trong `…/Backup Yomi Apps/downloads/Booru/Safebooru/`.
  - Đổi trang: e926 tải được. Yande.re "Không có kết quả" với "scenery" (thẻ này có 0 bài trên Yande.re – đúng).
  - Danbooru mở trang **xác minh Cloudflare** ("Xác minh bạn là con người"). Claude **không tự bấm CAPTCHA**; đóng trang → log `[Booru App] … TimeoutException`. Bản cuối có thông báo rõ ràng và nút "Vượt Cloudflare bằng WebView".
  - Cài đặt Booru App hiển thị đủ các mục.
- Health Connect (`p26`, `p29`): "Health Connect đã sẵn sàng trên thiết bị" (không còn `MissingPluginException`). Chạm "Quyền ghi phiên Chánh niệm" → hộp xin quyền Health Connect của Android hiện đúng mục **Chánh niệm – Quyền ghi**. Claude chọn "Không cho phép" để người dùng tự quyết định cấp quyền.
- Sao lưu đám mây (`p28`): có mục Rclone và MediaFire. Chưa kết nối thật vì cần tài khoản của người dùng.
- **VPN – kiểm tra bên ngoài ứng dụng** (`p32`–`p43`, video `p044_tor.mp4`, `p044_warp.mp4`):
  - Tor bật lúc 11:36. Sau 90 s ứng dụng báo **"Tor chưa kết nối được sau 90 giây (dừng ở 50%: Loading relay descriptors)…"** (thông báo mới). Sau 5 phút vẫn 50 % → mạng hiện tại chặn relay Tor. Đã tắt Tor.
  - Cloudflare WARP bật → "Đã kết nối • YomiHub + 2 ứng dụng". Kiểm tra từ **hệ thống Android** (`dumpsys connectivity`): `VPN CONNECTED extra: VPN:com.yomihub.app`, giao diện `tun0`, địa chỉ `172.16.0.2/32` và `2606:4700:110:…` (dải Cloudflare WARP), DNS 1.1.1.1, `IS_VALIDATED` → VPN hoạt động ở mức hệ điều hành. Đã tắt lại WARP như trạng thái ban đầu.
- Nhật ký (`phone_logs_*.txt`): ghi đúng `[Booru App] …`, `[VPN] … dừng ở 50%…`.
- Phát hiện khi kiểm thử bản APK 13:37: mỗi lần mở app vẫn có `[Thư mục cục bộ] Ảnh bìa lớn hơn 5 MB (7.85 MB / 12.13 MB)`.
  - Nguyên nhân: các tệp EPUB nằm trong thư mục Comic (`local/Truyện, Sách (Book) .EPUB/…`), nên ảnh bìa được dựng lại từ archive ở mỗi lần quét.
  - Đã sửa: `file_scanner.dart` lưu chữ ký thư mục `derived|…` và chỉ thử lại khi thư mục thay đổi. `YomiCoverSig` không cache bảng rỗng khi YomiPrefs chưa mở. `dart analyze` file_scanner: 0 lỗi.
- Ghi nhận: lần chạm đầu tiên vào thanh dưới ngay sau khi mở app (khoảng 14 s) đôi khi không được nhận (2/2 lần kiểm thử). Lần chạm thứ hai mở đúng. Chưa tái hiện được nguyên nhân, cần theo dõi.

**Android TV – AVD `YomiHub_TV_API34`, APK `YumiHub-Android-TV-0.4.4-armeabi-v7a` (`tv01`–`tv07`, video `tv044_walk.mp4`, `tv044_booru.mp4`):**
- Màn hình chính tiếng Việt "Thư viện Phim & Điện ảnh đang trống".
- Thanh bên chỉ có **Phim & Điện ảnh, Play Books, Booru, Cập nhật, Duyệt, Thêm** – không có Comic/Novel.
- Booru trên TV: Safebooru tải lưới, chỉ nội dung phổ thông vì NSFW đang tắt. Điều khiển bằng D-pad.
