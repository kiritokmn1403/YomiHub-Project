
#### J. Treo/thoát khi khởi động trên điện thoại thật Xiaomi 15T (29/10/2026 07:00–08:00)

- Thiết bị: Xiaomi 15T (`25069PTEBG`, HyperOS, Android 16, 1280×2772), kết nối `adb` qua USB; bản đã cài trùng SHA-256 với APK `arm64-v8a` 0.4.3 (dựng 22:49).
- Hiện tượng (người dùng báo "YomiHub bị treo trong khi khởi động"): mở ứng dụng → màn khởi động rồi tự đóng. Logcat (`qa/x11_logcat.txt`): ~3 s sau khi mở, `TorService: Acquired lock`, rồi thư viện tor (`libtor.so`, tor-android 0.4.8.22) gọi `exit()` từ `networkstatus_set_current_consensus` ← `router_reload_consensus_networkstatus` (nạp consensus đã lưu) → tiến trình thoát khi các luồng Flutter còn chạy → `FORTIFY: pthread_mutex_lock called on a destroyed mutex`, `Fatal signal 6 (SIGABRT)` → "Process com.yomihub.app has died". Lặp lại ở mỗi lần mở vì Tor được bật sẵn (tự khởi động lúc mở app) và consensus vẫn nằm trong bộ đệm. Tor 0.4.8 thoát khi consensus yêu cầu giao thức mà phiên bản đó không hỗ trợ.
- Sửa:
  1. `android/app/build.gradle`: `info.guardianproject:tor-android` 0.4.8.22 → **0.4.9.13** (đã có trong bộ đệm Gradle; cùng API `TorService`: `STATUS_ON`, `getTorrc`, `LocalBinder`, `getTorControlConnection` — đối chiếu lớp trong AAR). APK mới có `libtor.so` arm64 7.574.016 byte = bản 0.4.9.13.
  2. `lib/yomihub/vpn/vpn_service.dart`: chống vòng lặp thoát — trước mỗi lần khởi động Tor (Android) ghi `torStartPending=true` (flush Hive), xoá sau 25 s ứng dụng còn sống. Lần mở sau nếu dấu còn → tắt Tor, lưu `torEnabled=false`, ghi log `[VPN] Tor dừng đột ngột khi khởi động…` và hiện thông báo "Tor đã làm ứng dụng thoát ở lần mở trước nên đã được tắt…" (dịch 18 ngôn ngữ). Tối đa 1 lần thoát thay vì không mở được ứng dụng.
- Kiểm thử: `dart analyze` 0 lỗi; `flutter test` 27/27; APK dựng 07:57 (arm64 162,5 MB).
- Bản cũ trước sửa: `audit-0.4.3/before/tor/`.
- Cài APK mới lên Xiaomi 15T (`adb install -r`, 08:09, giữ dữ liệu) → mở ứng dụng: tiến trình sống ổn định (kiểm 40 s liền, `TorService` khởi động, tor 0.4.9 chạy không thoát), vào được thư viện (ảnh `qa/x25_s*.png`, video `qa/ph_start2.mp4`).
- Phát hiện thêm và sửa: mỗi lần mở app hiện toast tiếng Anh "Cover image is larger than 5MB (7.85MB). Skipping cover image." (từ lượt quét thư mục cục bộ có EPUB bìa 7,85 MB) → `lib/modules/library/providers/local_archive.dart`: thay `botToast` bằng `AppLogger.logOnce` tiếng Việt "[Thư mục cục bộ] Ảnh bìa lớn hơn 5 MB … – bỏ qua ảnh bìa này".
- Kiểm thử trên điện thoại thật (chạm qua `adb input`, ảnh `qa/x3*–x4*.png`, video `qa/ph_browse.mp4`, `qa/ph_play.mp4`):
  - Duyệt → Phim & Điện ảnh: danh sách tiện ích, biểu tượng hiện đủ.
  - AVSub (`animevietsub.news`): danh sách "Mới nhất" tải được sau ~40–60 s (vượt Cloudflare bằng WebView); trang chi tiết trả 0 tập — kiểm tra bằng trình duyệt trên máy tính: `animevietsub.news` đang trả **Cloudflare 520 "Lỗi Server 5xx"** (máy chủ gốc lỗi) → phía máy chủ, không phải lỗi ứng dụng.
  - AnimeVN: danh sách tải ngay (ảnh bìa lỗi hiện nền giữ chỗ mới); "Tiên Nghịch" 134 tập; **Tập 133 phát được** (00:54 → 01:27/26:18).
  - **Nhớ vị trí xem đạt:** thoát ở 01:14, mở lại → thông báo "Tiếp tục phát từ 01:15", log `[Trình phát] Tiếp tục xem video tại 75s`.
  - Back khi đang phát → thu nhỏ PiP (đúng thiết kế).
  - Ghi nhận: luồng mpv của AnimeVN bị ngắt `tcp: ffurl_read returned 0xffffff92` (hết thời gian chờ mạng, log `[Trình phát] Lỗi video không tải được`) → trình phát tự chuyển sang máy chủ web "HY (web)", trang web này chỉ hiện nút phát và vòng tải (không phát được trên mạng lúc kiểm) — phía máy chủ/mạng.
  - Ảnh bìa lỗi trên điện thoại: `i.hinhhinh.com` (403 Cloudflare), `i.hinhgg.com` (521), `hentaicb.help` (đóng TLS), `nhattruyensss.com` (lỗi chứng chỉ) — máy chủ ảnh hỏng; tên truyện + nền giữ chỗ hiện đúng.
- Dựng lại toàn bộ (test → APK → TV → Windows → pack) để có bản sửa Tor + toast.
- Dựng lại: test 08:42 (`dart analyze` 0 lỗi, `flutter test` 27/27), Windows 08:50, APK 08:56, TV và pack sau đó. Cài APK cuối lên Xiaomi 15T (08:59): mở app ổn định 30 s, không còn `Fatal signal`/`FORTIFY`, không còn toast tiếng Anh (ảnh `qa/x50_s*.png`, video `qa/ph_final_start.mp4`).
