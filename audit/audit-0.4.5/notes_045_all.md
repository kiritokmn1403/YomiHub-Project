
### 30/10/2026 — Cập nhật phiên bản 0.4.5 (YomiHub 0.4.5+37)

> Thực hiện bởi Claude (Cowork). Công cụ:
> - **GitHub Desktop 3.6.7**: Fetch `origin/main` lúc 09:24. Kết quả `43461ac`, trùng bản trên máy, không cần Pull.
> - Flutter 3.47.6 / Dart 3.13.5, Gradle 9.3.1, Android SDK `adb` (Xiaomi 15T `K75THMJVHA95EARO`, Android 16 / HyperOS 3.0.303).
> - PowerShell job runner (`3_run_jobs.bat`, `3b_run_fast_jobs.bat`); `curl.exe` trên Windows để kiểm tra trang/API thật.
> - Python 3 trong máy ảo Linux của phiên, dùng để sửa mã, quét bản dịch, so khớp sheet Excel.
>
> Cách làm: mọi sửa đổi làm trong `overlay`, sao lưu bản trước khi sửa ở `audit-0.4.5/before/` (`audit-0.4.5/bk.sh`), danh sách tệp ở `audit-0.4.5/changed_files.txt`, rồi chép sang `D:\yh\build` / `D:\yh\buildwin` bằng `audit-0.4.5/sync.sh`. Script dựng: `build_045.ps1`, sao từ `build_044.ps1`; danh sách `dart analyze` lấy tự động từ `changed_files.txt`, thêm bước `-step apk64` để dựng nhanh bản arm64 cho kiểm thử.

**Yêu cầu (người dùng xác nhận 30/10/2026):**
- Nâng lên 0.4.5, giữ **Android 7.0+** (Android 6.0 vẫn bị chặn bởi Isar/libmdbx).
- APK riêng `YumiHub Android TV`, bỏ Comic/Novel.
- Windows 10/11 x64 đủ 3 gói `.appxbundle`, `Setup.exe`, portable. Người dùng để Claude chọn phạm vi Windows → giữ x64 như 0.4.4.
- Làm sheet `YomiHub Update` (6 mục) và `Feature Check` (43 mục); sửa lỗi trong `logs 2.txt`.
- Kiểm thử có ảnh/video; VPN kiểm tra bên ngoài ứng dụng; đẩy mã lên GitHub.

#### A. Lỗi trong `logs 2.txt` (30/10/2026 06:09–09:12, 27 dòng)

| # | Dòng log | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | `[ERROR] [Booru App] Không tải được danh sách (Rule34, api.rule34.xxx): Rule34: missing authentication` | Rule34/Gelbooru bắt buộc API key. App vẫn gửi yêu cầu, rồi ghi ERROR mỗi lần mở tab. | `lib/yomihub/booru/booru_screen.dart`: trang `needsKey` chưa có key thì không gửi yêu cầu, ném `BooruException(needsKey)` ngay. Màn hình hiện nút mới **"Nhập API key"**, mở `/booruSettings` rồi tải lại khi quay về. `booruLog()`: lỗi cấu hình (`needsKey`, `cloudflare`, `blocked`) ghi **WARNING**, chỉ 1 lần cho mỗi trang/loại lỗi trong một phiên (`_booruLogged`). |
| 2 | `[Hiệu năng] Khung hình chậm: dựng 421ms, vẽ 434ms` (09:10:59, ~1 s sau khi mở app) | `YomiSplash.build()` trả `Stack[app, splash]` trong 5 s đầu rồi trả `widget.child` trơn. Kiểu widget gốc đổi → **toàn bộ ứng dụng (Navigator, thư viện 41 tab, lưới bìa) bị huỷ và dựng lại từ đầu** ngay sau màn hình loading, đồng thời mất trạng thái điều hướng. | `lib/yomihub/splash/yomi_splash.dart`: luôn trả cùng một `Stack`, ứng dụng nằm trong `KeyedSubtree(GlobalKey)`, lớp splash chỉ bị bỏ khỏi `children` (`if (!_removed)`). |
| 3 | `[Hiệu năng] Hệ thống báo thiếu bộ nhớ (RAM máy 11.1 GB) – … không còn bộ đệm nào khác` | Android gửi `onTrimMemory` khi app ở nền; bộ đệm ảnh đã trống. | Thông tin, không phải lỗi; không đổi. |
| 4 | `Image/network load failed` (i.hinhhinh.com, i.hinhgg.com, nhattruyensss.com, hentaicb.help) | Máy chủ ảnh hỏng hoặc chặn (403/521/TLS), đã phân tích ở 0.4.3 mục I. | Không đổi (ghi INFO, 1 lần/máy chủ). |
| 5 | `Refreshed MAL token!`, `Refreshed Trakt.tv token!`, `Download index: 81 on disk, +9, -0` | Thông tin. | — |

#### B. Sheet "YomiHub Update" (6 yêu cầu)

| Yêu cầu | Kết quả 0.4.5 |
|---|---|
| Sửa lỗi/cảnh báo trong log, tối ưu cho mượt | Mục A; thêm mục C (lỗi phát hiện khi kiểm thử). |
| Xem và sửa Website Extension | So khớp tự động sheet với `builtin_extensions.dart` + `url_override.dart`: tất cả 30 tiện ích và mọi URL đều có, **trừ `https://cache.vtvgo.vn/`** (VTV Go). Kiểm tra bằng `curl.exe` trên máy người dùng: `cache.vtvgo.vn` trả 200, API `api.vtvdigital.org` nhận `Origin: https://cache.vtvgo.vn` và trả nguồn HLS VTV1 như `vtvgo.vn` → thêm cặp tên miền dự phòng `vtvgo.vn` ⇄ `cache.vtvgo.vn` (`url_override.dart › defaultMirrors`). Test `yh_045`: "VTV Go mirrors include cache.vtvgo.vn". |
| Dự án GitHub còn thiếu | Quét lại cả 21 nhóm trong `Project GitHub.xlsx` so với `about/github_projects.dart`: **0 URL thiếu** – không cần bổ sung. |
| Sửa lỗi VPN | Log 2 không có lỗi VPN. Kiểm tra ngoài ứng dụng: mục E. Cầu nối Tor (obfs4/snowflake) cho Android vẫn **chưa làm được**: thư viện IPtProxy 5.7.0 (Maven Central, đã tải về `audit-0.4.5/iptproxy/` để kiểm tra) đóng gói `libgojni.so` của gomobile, trùng tên/lớp `go.Seq` với `libmtorrentserver.aar` đang có trong app → hai thư viện gomobile không thể cùng nằm trong một APK. |
| **Kiểm tra lỗi sao lưu Telegram** | Mục D. |
| Treo/lag/văng | Mục A2 (splash dựng lại cả app), C2 (trình phát), C4 (ghi nhận khung hình chậm khi quay lại từ trang con). |

#### C. Lỗi phát hiện khi kiểm thử trên Xiaomi 15T

| # | Hiện tượng (bằng chứng) | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | VTVgo › VTV1: thẻ "**1 chương** không tự đánh số được và có thể bị sai thứ tự hoặc thiếu **trong trình đọc**" (`p11_vtv1_detail.png`). | Thông báo của Mangayomi áp cho mọi loại, kể cả kênh truyền hình chỉ có 1 tập "Trực tiếp". | `manga_detail_view.dart › _notifyUnrecognizedChapterNumbers`: bỏ qua với Phim & Điện ảnh và khi chỉ có ≤ 1 chương/tập. |
| 2 | VTV1 phát được (`p12`, `p13`, video `p045_vtv1_play.mp4`) nhưng log có **8 dòng ERROR** `Lỗi video không tải được: Cannot seek in this stream` / `--force-seekable=yes`; trình phát **tự đổi máy chủ 4 lần** (`phone_logs_b3.txt` 10:27:40–41). | Vị trí "46s" lưu từ lần xem trước được khôi phục trên **luồng trực tiếp không tua được**; lỗi tua của mpv bị coi là nguồn hỏng → `_yhNextServer`. | `anime_player_view.dart`: `doSeek` đọc thuộc tính mpv `seekable`, `no` → bỏ qua vị trí, đánh dấu `_yhLiveStream`; bộ nghe lỗi coi `cannot seek`/`force-seekable` là thông tin (INFO, 1 lần), **không đổi máy chủ**; `_setCurrentPosition` không lưu vị trí cho luồng trực tiếp; cờ đặt lại khi mở video mới. Kiểm tra lại bản 4 (11:45): 0 ERROR, không đổi máy chủ, VTV1 phát liên tục (`p14_vtv1_b4.png`, `p045_vtv1_live_b4.mp4`). |
| 3 | Tiểu thuyết › Lịch Sử Đọc › "Mushoku Tensei…": màn hình "Đã xảy ra lỗi – TypeError: not a function at <anonymous> (<eval>:1:8845)" (`p50_novel_detail.png`), **không có dòng nào trong Nhật ký** (vi phạm FC 34). | `getHtmlContent` ném lỗi thẳng lên giao diện, không ghi log, không nêu nguồn. | `services/get_html_content.dart`: mọi lỗi tải nội dung chương ghi `[Tiểu thuyết] Không tải được nội dung chương "…" (nguồn, ngôn ngữ, truyện "…"): …` – lỗi mạng WARNING, còn lại ERROR, kèm gợi ý `YomiExtErrors.hint`. |
| 4 | Bản 1 và bản 3 ghi `Khung hình chậm: dựng 855–1195ms` ngay khi **quay lại** từ trang con (cài đặt Booru 10:21:12, trang lỗi tiểu thuyết 11:37:04, Sao lưu đám mây 11:33:05). Chuyển tab thường không chậm: 7 lần chuyển tab bản 3 (11:03–11:10) không có dòng nào. | Chưa xác định được widget gây chậm. Bản release không có công cụ profiler. | `perf_watchdog.dart`: dòng "Khung hình chậm" ghi thêm **màn hình hiện tại** (`YomiPerf.route`, đặt trong `MainScreen.build`) và việc nền đang chạy, để lần sau tìm đúng chỗ. **Còn mở.** |
| 5 | Nguồn gây lỗi ở C3 (log bản 5, 11:57:17): `[Tiểu thuyết] Không tải được nội dung chương "Hình minh họa" (Hako vi, truyện "Mushoku Tensei…"): TypeError: not a function at <eval>:1:8845`. | Nguồn là **plugin LNReader "Hako" 1.2.0** (`LNHako.js`, kho `lnreader-plugins/v3.0.0`, đã tải về `audit-0.4.5/hako_repo/` để đối chiếu). Cột 8845 rơi vào `n.replaceWith(r)`, ngay sau đó là `.has('img[src*="chapter-banners"]')`. Bộ giả lập cheerio của YomiHub (`lib/eval/lnreader/js_cheerio.dart`) không có `replaceWith`, `has`. Ngoài ra `.length` của tập phần tử là **hàm** chứ không phải số, nên `if (n.length)` luôn đúng. | `js_cheerio.dart`: thêm `replaceWith`, `before`, `after` (Dart: `parseFragment` + `nodes.insertAll`), `has`, `is`, `eq`; `.length` thành getter số như cheerio thật. |
| 6 | **VPN – kiểm tra ngoài ứng dụng** (12:22, video `p045_warp.mp4`, `p63_warp_on.png`). Bật Cloudflare WARP ở chế độ "YomiHub + 2 ứng dụng". `dumpsys connectivity`: `VPN CONNECTED extra: VPN:com.yomihub.app`, `tun0` 172.16.0.2/32 + `2606:4700:110:…` (dải Cloudflare), DNS 1.1.1.1, `IS_VALIDATED`; `ping 1.1.1.1` 0 % mất gói. **Nhưng** `Uids` của VPN chỉ có 10451 (`com.truthsocial.android.app`), 10475 (`com.facebook.aura`) và bản sao hồ sơ công việc – **không có YomiHub (10383)**. | `vpn_service.dart` (dựng cấu hình WARP): chế độ `WarpMode.apps` ghi `IncludedApplications` chỉ gồm các ứng dụng đã chọn. WireGuard (`wireguardScoped`) và OpenVPN (`tunnelBypass`) thì có cả YomiHub. | `WarpMode.apps => {ownPackage, ...warpApps}`. Đã tắt lại WARP (12:27, `VPN CONNECTED` = 0). |
| 7 | Lần dựng 6 (12:13) lỗi `kernel_snapshot_program`: `js_cheerio.dart:410:12 A '$' has special meaning inside a string`. | Ghi chú JS mới viết trong chuỗi Dart `'''…'''` có ký tự `$(`. | Sửa ghi chú. Job dựng mới (`x045_107`) chỉ dựng APK khi lần `dart analyze` gần nhất không có `error -`. |

**Sự cố trong lúc kiểm thử (ghi lại để minh bạch):**
- Lúc 10:36, job đo khởi động lạnh gọi `am start -n com.yomihub.app/.MainActivity`. Lớp thật là `com.kodjodevf.mangayomi.MainActivity`, nên lệnh không mở được app. Màn hình nằm ở **Cài đặt › Tuỳ chọn nhà phát triển** (trang người dùng mở từ trước).
- Job đo chuyển tab (10:41–10:46) vì thế đã bấm **6 lần ở hàng dưới cùng** (y = 2489) của trang này. Job đọc Comic (10:51) bấm thêm 1 lần và vuốt cuộn.
- Kiểm tra sau đó:
  - `dumpsys settings`: mục cài đặt mới nhất do `com.android.settings` ghi là `tether_offload_disabled` (id 235235), cũ hơn rất nhiều so với id hiện tại (237086). Như vậy không có cài đặt Global/Secure/System nào bị đổi trong khoảng đó.
  - `getprop debug.*`/`persist.*`: không có cờ gỡ lỗi đồ hoạ nào bật (`debug.hwui.profile`, `overdraw`, `debug.layout`… đều không có).
- Đã bổ sung chốt an toàn trong `qa045.ps1`: `EnsureApp`/`Fg` kiểm tra `topResumedActivity` trước **mọi** thao tác `Tap`/`Key`/`Swipe`. Nếu YomiHub không ở trên cùng thì mở lại app, và dừng job khi vẫn không mở được.
- Kết quả đo hiệu năng của job 10:41 bị loại bỏ; đã đo lại ở bản 3 (11:03–11:10).
| 8 | Hako (LNReader) sau khi sửa C5, bản 7 (12:42–12:53). | — | Chương chữ "Mở đầu" (nội dung `xor_shuffle`) hiển thị đúng tiếng Việt (`p53_hako_text_b7.png`, video `p045_hako_text.mp4`). Chương "Minh họa" không còn `TypeError`: đọc được 13 ảnh nhưng ảnh đều báo "Không tải được ảnh: default.jpg" (`p52_hako_chapter_b7.png`). Đã giải mã chương `c6764-minh-hoa` bằng Python: ảnh là `https://*.bp.blogspot.com/…/s0/default.jpg`. `curl.exe` có và không có Referer đều trả **403** → ảnh đã bị xoá phía máy chủ Blogspot, không phải lỗi app. |

#### D. Sao lưu Telegram (sheet "YomiHub Update")

Rà mã `TelegramProvider` (`lib/yomihub/cloud/cloud_backup_service.dart`) và đối chiếu dữ liệu thật trên Xiaomi 15T.

Dữ liệu thật trên máy:
- Telegram đang "Đã kết nối", bật "Tự động tải lên khi sao lưu".
- Nút "Khôi phục từ đám mây" (12:27) báo **không có bản sao lưu nào**: lịch sử tải lên rỗng.
- Bản sao lưu YomiHub trong `Backup Yomi Apps/autobackup` nặng **24,6–25,2 MB** (08/10–30/10).
- `api.telegram.org` truy cập được từ mạng hiện tại: điện thoại `ping` + TCP 443 OK, Windows `curl` 302.

Các lỗi trong mã:
1. **Giới hạn Bot API**:
   - `sendDocument` nhận tối đa 50 MB.
   - `getFile` chỉ tải về được tệp tối đa **20 MB**. Bản sao lưu 25 MB của người dùng tải lên được nhưng **không bao giờ khôi phục được** ("file is too big").
2. Dùng `http.Client()` trơn, bỏ qua "VPN & DNS" (Tor/Proxy/DoH). Khi nhà mạng chặn Telegram thì không có đường vòng.
3. Thông báo lỗi chứa URL `…/bot<TOKEN>/…`. Lỗi được ghi vào Nhật ký nên **lộ bot token**.
4. Token/Chat ID không được `trim()`. Không kiểm tra Chat ID khi kết nối, nên lỗi "chat not found" chỉ lộ ra ở lần sao lưu đầu.
5. Không có timeout và không thử lại khi gặp HTTP 429.

Sửa:
- Tệp > 19 MB được gửi thành các phần `…backup.part01ofNN`. Lịch sử lưu `parts:id1,id2,…`. Khôi phục tải từng phần, nối lại và kiểm tra kích thước.
- `getUpdates` nhận ra các phần do người dùng chuyển tiếp cho bot.
- Dùng `MClient` (theo "VPN & DNS"). Lỗi mạng kèm gợi ý bật WARP/Tor/Proxy.
- `maskToken()` che token trong mọi thông báo.
- `completeAuth` gọi `getMe` + `getChat`. Có gợi ý riêng cho 401, chat not found, bot bị chặn, 413, 429.
- Timeout 30 s / 5 phút, thử lại 3 lần.
- 10 chuỗi mới, dịch đủ 18 ngôn ngữ (`audit-0.4.5/tr045.py`; `i18n_scan`: 1.280 chuỗi, 0 thiếu).
- Test `yh_045`: che token, kích thước phần < 20 MB, đặt tên/ghép lại các phần.

**Chưa thử tải lên thật**: thao tác này gửi bản sao lưu vào cuộc trò chuyện Telegram của người dùng, nên cần người dùng đồng ý trước.

#### E. Kiểm thử trên Xiaomi 15T (Android 16, HyperOS 3.0.303) – các bản dựng arm64 trung gian

| Bản | Giờ dựng | Nội dung thêm |
|---|---|---|
| 1 | 10:04 (1.187 s) | Booru Rule34, VTV Go `cache.vtvgo.vn`, version 0.4.5+37 |
| 2 | 10:31 (471 s) | Telegram, splash, bản dịch |
| 3 | 11:01 (359 s) | thông báo "chương không đánh số" |
| 4 | 11:43 (320 s) | trình phát – luồng trực tiếp |
| 5 | 11:55 (377 s) | log lỗi chương tiểu thuyết, màn hình trong log hiệu năng |
| 6 | 12:13 | **lỗi dựng** (C7) |
| 7 | 12:38 (290 s) | cheerio LNReader, WARP gồm YomiHub |

Mọi bản: `dart analyze` trên các tệp đã sửa **0 lỗi** (chỉ còn info/warning có từ trước); `flutter test` yh_040–045 **45/45 đạt**. Cài đè giữ dữ liệu (`adb install -r`, versionCode 2037).

| Hạng mục | Kết quả | Bằng chứng (`output/0.4.5/qa/`) |
|---|---|---|
| Khởi động, loading 5 s | Logo tròn, chữ "Truyện tranh · Phim & Điện ảnh · Tiểu thuyết", không văng. 3 lần khởi động lạnh bản 2 không có dòng "Khung hình chậm" (bản 0.4.4: 421/434 ms). | `p01_splash.png`, `p045_start*.mp4` |
| Booru App – Rule34 chưa có key | Hiện thông báo + nút "Nhập API key" → mở Cài đặt Booru App. Log 1 dòng WARNING thay vì ERROR. Đã chuyển lại Safebooru như trạng thái cũ. | `p05`–`p07`, `p045_booru_rule34.mp4` |
| VTV Go (Phim & Điện ảnh) | Danh sách ~40 kênh. VTV1 phát trực tiếp. Bản 4: không còn ERROR/đổi máy chủ. Thoát trình phát bình thường. | `p10`–`p14`, `p045_vtv1_*.mp4` |
| Chuyển tab (bản 3, 7 lần, cách 62 s) | Không có khung hình chậm. | `phone_logs_b3.txt` |
| Tiểu thuyết Hako (LNReader) | Bản 3/5: `TypeError` → bản 7: đọc được (C3, C5, C8). | `p50`–`p53` |
| Sao lưu đám mây | Màn hình đủ 7 dịch vụ (Google Drive, OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram). | `p40`–`p44` |
| VPN (ngoài ứng dụng) | WARP lên ở mức hệ điều hành; sửa danh sách ứng dụng (C6). | `p60`–`p63`, `p045_warp.mp4` |
| Chạm đầu tiên bị bỏ qua | Lặp lại 2/≈60 lần chạm (10:10 thanh dưới, 12:07 nút "Thêm"); các lần khác đều nhận. Không tái hiện được có chủ đích (thử chờ 70 s, thử khi đang quay màn hình). Còn mở như ghi nhận ở 0.4.4. | `x045_015`, `x045_063` trong `jobs/done` |

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
