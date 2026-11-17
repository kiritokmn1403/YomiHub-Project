
### 29/10/2026 — Cập nhật phiên bản 0.4.4 (YomiHub 0.4.4+36)

> Thực hiện bởi Claude (Cowork). Công cụ: **GitHub Desktop 3.6.7** (Repository › Fetch nhánh `main` của `YomiHub-Project` lúc 10:15; `origin/main` = `fb28229`, không có commit mới → không cần Pull; nhánh máy đi trước 11 commit chưa đẩy), Flutter 3.47.6 / Dart 3.13.5 (`D:\yh\tools\flutter`), Android SDK (platform-tools/adb, platform android-37.0 để đối chiếu API Health Connect), Gradle 9.3.1, Visual Studio 2022 Build Tools (MSVC – `flutter build windows`), PowerShell job runner (`run_jobs.ps1`, `run_jobs_fast.ps1`), Python 3 (máy ảo Linux của phiên – chỉnh sửa mã, quét bản dịch, so khớp danh sách GitHub), `adb screencap/screenrecord/uiautomator` (Xiaomi 15T), `curl.exe` trên Windows (kiểm tra API booru thật). Mọi sửa đổi làm trong `overlay` rồi chép sang `D:\yh\build\mangayomi` và `D:\yh\buildwin\mangayomi` bằng `audit-0.4.4/sync.sh`; bản trước khi sửa lưu ở `audit-0.4.4/before/`, danh sách tệp ở `audit-0.4.4/changed_files.txt`. Script dựng: `build_044.ps1` (sao từ `build_043.ps1`, danh sách analyze = 26 tệp Dart đã sửa).

**Yêu cầu (người dùng xác nhận 29/10/2026):** nâng lên 0.4.4; Android: chọn phương án **B – giữ Android 7.0+** (Android 6.0 bị chặn bởi Isar/libmdbx, xem mục D của 0.4.3); APK riêng `YumiHub Android TV` bỏ Comic/Novel; Windows: đồng ý **chỉ dựng Windows 10/11 x64** (Flutter không hỗ trợ Windows 7/x86; ARM64 cần máy ARM; `.appxbundle` chỉ cài trên Windows 10+), đủ 3 gói `.appxbundle`, `Setup.exe`, portable; làm từng mục sheet `Feature Check` (42 mục) và `YomiHub Update` (7 mục); sửa lỗi trong `logs 1.txt`; Booru App theo phạm vi đã đồng ý; ghi nhật ký vào tệp này; kiểm thử có ảnh/video (Windows: ảnh chụp, video ngắn khi đủ RAM); VPN kiểm tra bên ngoài ứng dụng.

#### A. Lỗi trong `logs 1.txt` (7.017 dòng, 21–29/10/2026: 1.545 ERROR, 168 WARNING)

Phần lớn dòng lỗi thuộc các bản trước 0.4.3 (đã sửa ở 0.4.3): 698 × `Failed to update Manga` + 455 × `Missing Madara post ID` (23 và 26/10), 212 × `relative URL without a base` (23/10), 14 × `Null check @ /MangaLibrary` (23/10). Các lỗi còn xuất hiện ở 0.4.3 (28–29/10) và cách sửa:

| # | Lỗi trong log | Nguyên nhân | Sửa (tệp, dòng lệnh chính) |
|---|---|---|---|
| 1 | `[VPN] … Tor chưa kết nối được` (29/10 08:12, 09:00, 09:32, 09:34) rồi mọi nguồn báo `ConnectError … 127.0.0.1:9 Connection refused` (Pornhub 09:30–09:35) | Khi Tor khởi động quá 90 s, `torStart` trả trạng thái STARTING; về sau tor báo `ON` qua broadcast nhưng Dart chỉ đổi nhãn (`torStatus`), **không** đặt `torRunning`/cổng proxy → định tuyến kẹt ở kill switch (`127.0.0.1:9`) tới khi mở lại app. | `lib/yomihub/vpn/vpn_service.dart`: nhánh `case 'torStatus'` gọi `_onTorLateOn()` khi nhận `ON` lúc `torEnabled && !torRunning` → đọc cổng bằng `invokeMethod('torStatus')`, đặt `torHttpPort/torSocksPort`, `torRunning = true`, xoá `lastError`, `YomiVpnState.bump()`, áp proxy trình duyệt + VPN thiết bị. Thông báo lỗi kèm tiến độ bootstrap: `Tor chưa kết nối được sau 90 giây (dừng ở {p0}%{p1}) – Tor vẫn tiếp tục thử ở nền…`. `android/.../YomiVpn.kt`: `torInfo()` thêm khoá `bootstrap` (đọc `status/bootstrap-phase` trên luồng `io`, không chặn luồng chính). |
| 2 | `Extension "Pornhub (18+)" … [RhttpConnectionException] Connection error … TunnelUnsuccessful` ghi ERROR kèm 20 dòng stack `*** *** *** pid: … #00 abs …` (28/10 23:06–23:09) | Biểu thức nhận diện lỗi mạng không biết cách diễn đạt của rhttp; `toString()` của rhttp chứa sẵn stack gốc của Dart. | `lib/yomihub/extensions/ext_errors.dart`: `_net` thêm `rhttpconnectionexception|connection error|tunnelunsuccessful|connectfailed|connection timed out`; `short()` cắt từ `*** ***`/`pid:`/`#00 abs`; `hint()` giải thích `127.0.0.1:9` (Kill switch đang chặn vì Tor chưa kết nối) và `TunnelUnsuccessful` (proxy/VPN từ chối). `lib/yomihub/player/yomi_shorts.dart`: log Short Video dùng `short()` + gợi ý, mức WARNING khi là lỗi mạng. |
| 3 | `fetchStore: repo.json check failed: ClientException: Software caused connection abort` + stack (29/10 06:41) | Mất kết nối tạm thời khi tải `repo.json` LNReader (đã có đường dự phòng parser thường) nhưng ghi ERROR + stack. | `lib/services/extension_store_service.dart`: lỗi mạng/timeout → 1 dòng WARNING `repo.json không tải được (…) – dùng chỉ mục thường`; kho lỗi `Connection closed before full header` (kohiden.xyz, log Windows 29/10 11:49) hạ xuống WARNING. |
| 4 | `[Health Connect] Cannot verify native integration: MissingPluginException(No implementation found for method isAvailable on channel com.yomihub/health_connect)` (29/10 09:37) | Từ 0.3.0 Dart gọi kênh `com.yomihub/health_connect` nhưng **không có mã Android nào trả lời** (đã ghi nhận ở mục 5.7 bản 0.3.9). | **Mới** `android/.../YomiHealth.kt` (đăng ký trong `MainActivity.configureFlutterEngine`): `isAvailable`, `status`, `openSettings`, `requestPermission`, `syncSession` dùng API Health Connect của nền tảng (`android.health.connect`, Android 14+, không thêm thư viện): ghi `MindfulnessSessionRecord` khi có SDK extension ≥ 15 (Android 16 hoặc 14/15 đã cập nhật); Android 9–13: kiểm tra app Health Connect + mở cài đặt. `AndroidManifest.xml`: quyền `android.permission.health.WRITE_MINDFULNESS`, 2 `activity-alias` (`VIEW_PERMISSION_USAGE` + `HEALTH_PERMISSIONS`, `ACTION_SHOW_PERMISSIONS_RATIONALE`). Dart `health_connect_service.dart`: thêm `status()`, `requestPermission()`, lỗi đồng bộ ghi WARNING; `health_connect_screen.dart`: mục "Quyền ghi phiên Chánh niệm". |
| 5 | `[Hiệu năng] Khung hình chậm: dựng 610ms / 639ms / 1224ms` cùng giây với `[Thư mục cục bộ] Ảnh bìa lớn hơn 5 MB (7.85 MB)` ở **mỗi** lần mở app (29/10 08:59, 09:31) | Lượt quét Thư mục cục bộ lúc khởi động đọc lại toàn bộ tệp ảnh bìa của mọi truyện (Comic còn giải mã ảnh để kiểm tra trang trắng) dù không đổi; tệp 7,85 MB bị đọc rồi bỏ mỗi lần. | `lib/modules/library/providers/file_scanner.dart`: lớp mới `YomiCoverSig` lưu chữ ký `đường dẫn|kích thước|giờ sửa` của ảnh bìa theo truyện (khoá `localCoverSig` trong YomiPrefs); bỏ qua ảnh bìa không đổi; tệp ≥ 5 MB chỉ `stat()` (không đọc) và log 1 lần. |
| 6 | `Tor chưa kết nối` lặp lại dù đã sửa #1 | Kiểm tra thật trên Xiaomi 15T (11:36–11:41): tor 0.4.9 dừng ở **50 % "Loading relay descriptors"** > 5 phút → mạng/nhà mạng chặn relay Tor. | Không phải lỗi mã. tor-android không kèm obfs4/snowflake (bản Windows đã có `lyrebird`); thông báo nay nói rõ % và gợi ý dùng WARP. Ghi nhận cho bản sau: thêm cầu nối (IPtProxy) cho Android. |
| 7 | `Image/network load failed` (i.hinhhinh.com 403, i.hinhgg.com 521, hentaicb.help đóng TLS…) | Máy chủ ảnh hỏng/chặn (đã phân tích ở 0.4.3 mục I). | Không đổi; nền giữ chỗ hiển thị đúng. |
| 8 | `[Trình phát] Lỗi video không tải được: tcp: ffurl_read returned 0xffffff92` (AnimeVN) | Hết thời gian chờ mạng phía máy chủ (0.4.3 mục J). | Không đổi (đã tự chuyển máy chủ). |

#### B. Sheet "YomiHub Update" (7 yêu cầu bắt buộc)

| Yêu cầu | Kết quả 0.4.4 |
|---|---|
| Đọc nhật ký, sửa lỗi/cảnh báo, tối ưu | Mục A (1–5). |
| Xem và sửa các mục trong Website Extension | 30 tiện ích của sheet đều có trong `builtin_extensions.dart` (tên, URL, ngôn ngữ, NSFW khớp). Bổ sung tên miền dự phòng còn thiếu trong `url_override.dart › defaultMirrors`: Phimmoi (`phimmoii.mom`, `messiahelartista.com`, `phimmois.sh`), MotPhim (`motphimc.my`, `motphim.website`, `motchill10.io`), khoá `xemphimgi.com`, `nextphim.net` (trước chỉ có `.net`/`.com` ngược nên không khớp). Test `Website Extension mirrors cover every URL of Phimmoi and MotPhim`. |
| Dự án GitHub còn thiếu | So khớp 505 dòng URL của sheet với `about/github_projects.dart`: thiếu 35 URL (Booru Project 15, Widget 18, Browser Fingerprint 2) + "Donut Browser" (sheet không có URL → `github.com/zhom/donutbrowser`). Đã thêm 3 nhóm mới; quét lại: **0 thiếu**. |
| **Booru App** (nhóm Booru Project) | **Mới** – mục C. |
| Sửa lỗi VPN | Mục A1, A2, A6; kiểm thử ngoài ứng dụng ở mục F. |
| Đồng bộ đám mây (nhóm Google, Dropbox, Microsoft, Mediafire – Cloud) | Đã có: Google Drive, OneDrive, Dropbox (OAuth), WebDAV, Telegram. **Mới** (`cloud_backup_service.dart`): `RcloneProvider` – mọi backend của rclone (Google Drive/Workspace, OneDrive, Dropbox, Mega, S3, pCloud, SFTP…) qua `rclone rcd` (API `rc/noop`, `operations/mkdir`, `operations/uploadfile`, `operations/list`, tải về qua `--rc-serve`); `MediaFireProvider` – REST API 1.5 (`user/get_session_token`, `folder/get_content`, `folder/create`, `upload/simple` + `poll_upload`, `file/get_links`). Mọi lỗi tải lên/kết nối/khôi phục ghi `[Đồng bộ đám mây] …` vào Nhật ký (`cloud_backup_screen.dart`, `uploadInBackground`). Mô tả trong Cài đặt và Dữ liệu & bộ nhớ cập nhật (18 ngôn ngữ). |
| Treo/lag/văng | Mục A5 (quét ảnh bìa lúc mở app), A2–A3 (giảm ghi log nặng); 0 lỗi `dart analyze`. |

#### C. Booru App (mới)

Tệp mới `lib/yomihub/booru/`: `booru_models.dart`, `booru_api.dart`, `booru_store.dart`, `booru_screen.dart`, `booru_viewer.dart`, `booru_settings_screen.dart`.

- 4 họ API (theo BooruHub/Boorusama/Boorusphere/Rule-34 App/Hybooru/danbooru): Danbooru 2, Gelbooru 0.2, Moebooru, e621. 10 trang có sẵn: Safebooru, Danbooru, Konachan (an toàn), e926, Yande.re, Gelbooru, Konachan, e621, Rule34, Xbooru; thêm trang tự chọn (loại API + URL + cờ 18+).
- Lưới vô hạn, kéo để tải lại, tìm theo thẻ có gợi ý (autocomplete), lịch sử tìm, Yêu thích, trình xem vuốt/zoom (ExtendedImage gesture), phát video/GIF (media_kit), tải bản gốc vào thư mục `Booru` trong thư mục tải xuống của app, chia sẻ, mở trang bài đăng, bảng thẻ (chạm thẻ để tìm).
- Nội dung 18+ theo **cài đặt NSFW của ứng dụng**: tắt → ẩn trang chỉ 18+, thêm `rating:g/general/s` phía máy chủ và lọc lại phía máy; danh sách thẻ chặn (mặc định `guro scat gore`).
- Nút **Booru** nằm **bên phải Play Books** (thanh dưới và thanh bên/TV) – `router.dart` (nhánh `/booru`, route `/booruSettings`), `reader_state_provider.dart` (chèn `/booru` sau `/playBooks` cho cấu hình cũ), `main_screen.dart`, `appearance_screen.dart`, `main.dart` (lối tắt).
- Cài đặt › **Booru App** (cạnh Google Play Books): bật/tắt (ẩn nút qua `hideItems`), số cột, ảnh gốc/thu nhỏ, tự phát video, thẻ chặn, tài khoản/API key từng trang, thêm/xoá trang, danh sách 12 dự án nguồn mở.
- Sao lưu **dùng chung với ứng dụng**: hộp Hive `yomihub_booru` thêm vào `YomiBackupExtras.boxes`; API key (`creds`) là dữ liệu nhạy cảm, chỉ xuất khi chọn "gồm cài đặt nhạy cảm".
- Mọi lỗi ghi `[Booru App] …` (tải danh sách, gợi ý thẻ, ảnh, video, tải xuống, Cloudflare), lỗi mạng ở mức WARNING.
- Kiểm tra API thật từ Windows (29/10 10:54): Safebooru/Konachan.net/e926/Yande.re/Xbooru/e621 trả JSON 200; **Danbooru và konachan.com trả 403 Cloudflare** "Just a moment…" (kể cả UA trình duyệt); Gelbooru 401; Rule34 200 nhưng nội dung là chuỗi `"Missing authentication…"`; API thẻ của Gelbooru 0.2 trả XML dù `json=1` → dùng `autocomplete.php` (Safebooru/Xbooru) và `page=autocomplete2` (Gelbooru). Mã nhận diện các trường hợp này thành lỗi có kiểu (`cloudflare`, `needsKey`) và hiện nút **"Vượt Cloudflare bằng WebView"** (dùng trang xác minh chung `YomiCf.solve`).

#### D. Feature Check (42 mục) – thay đổi ở 0.4.4

Các mục không liệt kê giữ nguyên trạng thái của 0.4.3 (xem nhật ký trước).

- FC 1/2/33: Booru App, Rclone/MediaFire, 36 dự án GitHub bổ sung (mục B, C). Không tự động ghép mã upstream (nguyên tắc mục 4.6).
- FC 3: mục A.
- FC 4/19/36: tên miền dự phòng Phimmoi/MotPhim/XemPhimGi/NextPhim; ngôn ngữ + NSFW khớp sheet.
- FC 13: sửa Tor (A1/A6), thông báo Kill switch (A2); kiểm tra WARP ngoài ứng dụng (mục F).
- FC 21: Booru dùng chung cơ chế vượt Cloudflare; thông báo Cloudflare rõ ràng.
- FC 29/32: quét lại toàn bộ `tr()` bằng `audit-0.4.4/i18n_scan.py` (ghép đúng chuỗi nối liền `'a' 'b'`, khác `language_audit.py` cũ chỉ lấy đoạn đầu): **1.270 chuỗi, thiếu 65 → đã dịch 18 ngôn ngữ → 0 thiếu**, placeholder `{p0}{p1}` khớp.
- FC 30: A5; ảnh bìa Booru dùng ảnh thu nhỏ của trang, ảnh gốc chỉ khi bật.
- FC 34: log Booru, đồng bộ đám mây, Health Connect, Tor (bootstrap %), Kill switch.
- FC 37 (Health Connect): mã native mới (A4) – kiểm thử thật mục F.
- FC 39: kiểm thử mục F.
