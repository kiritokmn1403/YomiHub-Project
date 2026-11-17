
### 05/11/2026 – 06/11/2026 — Cập nhật phiên bản 0.5.2 (YomiHub 0.5.2+44)

Thực hiện: Claude (phiên cloud liên kết máy `kiritokmn-lap`), bắt đầu 05/11/2026 22:02 (Asia/Saigon). Người dùng xác nhận bản tóm tắt yêu cầu ("đồng ý", cho toàn quyền điều khiển máy) và yêu cầu thêm lúc 22:38: "dùng chính điện thoại đang được kết nối vào để test ứng dụng" → mọi kiểm thử Android chạy trên **Galaxy Note 9 SM-N960N (Android 10)** đang cắm USB, ở chế độ **Samsung DeX** (ứng dụng chạy trên màn ảo "Desktop" 1920×1080, display 2).

#### A. Yêu cầu (đã xác nhận)
1. Nâng lên 0.5.2; Android 7.0+ (Android 6.0 vẫn bị chặn bởi Isar/libmdbx – người dùng đồng ý giữ 7.0+), 3 APK điện thoại + 3 APK `YumiHub Android TV` (bỏ Comic, Novel, Google Play Books, Booru); Windows 10/11 x64 (người dùng đồng ý thay cho Windows 7/x86/ARM) với `.appxbundle`, `Setup.exe`, portable.
2. `Project YomiHub.xlsx`: sheet `Feature Check` (45 mục), `YomiHub Update` (7 mục – mới: **Sao lưu / Tạo bản sao lưu & Khôi phục sao lưu bị lỗi** (quét Aniyomi, Nekoyomi, Mangayomi, vBooks, Booru Project), **Windows – đặc biệt AMD Ryzen 9 – thiếu tính năng**), `Website Extension`, `Extension Repo`, `Website Update Apps`, `Website Scan`, `Tracker`; `Project GitHub.xlsx` (618 dòng, 576 liên kết khác nhau).
3. Sửa lỗi/cảnh báo trong `logs 2.txt` (3.192 dòng, 30/10 06:09 → 05/11 21:57; 138 ERROR, 334 WARNING).
4. Ghi tài liệu này; dựng, cài, kiểm thử (ảnh + video, VPN kiểm tra ngoài ứng dụng); tải mã nguồn + Output lên GitHub (Release + README).

#### B. Công cụ
- **GitHub Desktop 3.6.10** (Fetch origin 22:07 – không có thay đổi mới, `main` = `origin/main` = `3dd43be`) + Git for Windows (`git fetch`, `git status`).
- Trình chạy tác vụ `3_run_jobs.bat` / `3b_run_fast_jobs.bat` (mở lại bằng Computer use trong File Explorer lúc 22:05 – đã dừng từ 15:13); job PowerShell sinh từ shell Linux của Claude (`audit-0.5.2/job.sh`, `wait.sh`, `adb.sh`).
- Sửa mã: Python 3 (`audit-0.5.2/edit.py` – `assert` chuỗi cũ xuất hiện đúng 1 lần, chép bản gốc vào `audit-0.5.2/before/`, ghi `audit-0.5.2/changed_files.txt`; kịch bản `e01_libupd.py` … `e12_data.py`, `tr052a.py`).
- `sync_052.ps1`, `build_052.ps1` (sinh từ 0.5.1); Flutter 3.47.6 / Dart 3.13.5, Gradle 9.3.1, Rust/Cargo, Android SDK + adb, Visual Studio 2022 Build Tools, WiX/NuGet, ffmpeg 9.0.2.
- Giải mã stack trace: `llvm-symbolizer` (cloud) với `D:\yh\symbols\app.android-arm64.symbols` (build-id `e05840e0…` khớp log), `readelf`.
- Kiểm tra trang/API thật: `curl.exe --doh-url https://1.1.1.1/dns-query` trên Windows; `node` (kiểm tra cú pháp + chạy thử hàm của tiện ích JS).
- Thiết bị: Note 9 qua adb (`input -d 2`, `screencap -d 2`); video: `audit-0.5.2/framerec.ps1` (screencap liên tục của màn DeX → ffmpeg MP4, vì `screenrecord` v1.2 của máy không có `--display-id`). Computer use cho GitHub Desktop, File Explorer, Samsung DeX và bản Windows.

#### C. Lỗi trong `logs 2.txt` sau khi cài 0.5.1 (04/11 08:57 → 05/11 21:57) – nguyên nhân và cách sửa

Phần log trước 0.5.1 (30/10 → 04/11 08:57: Cloudflare MiMiHentai ×22, Hako `TypeError`, "Cannot seek", Telegram `chat_id is empty`…) đã được xử lý ở 0.4.5–0.5.1. Stack trace trong log đã bị làm rối (split-debug-info); đã giải mã bằng `llvm-symbolizer` với `app.android-arm64.symbols` (build-id `e05840e01c13b4f78e173a990427d256` = bản 0.5.1 arm64).

| # | Dòng log | Nguyên nhân (đã kiểm chứng) | Sửa (tệp – dòng lệnh) |
| --- | --- | --- | --- |
| 1 | `[ERROR] FlutterError: Null check operator used on a null value` @ `/AnimeLibrary` (04/11 09:49:27, ×2) | Giải mã: `_IndicatorPainter.paint` → `flutter/material/tabs.dart:633` `controller.animation!.value`: thanh tab danh mục vẽ bằng một `TabController` **đã dispose**. `library_screen.dart` dispose controller cũ ngay sau 1 khung hình khi số danh mục đổi (cập nhật thư viện đang chạy). | `lib/modules/library/library_screen.dart › _retireTabController`: giữ controller cũ tới khi màn hình bị huỷ (chỉ giải phóng bớt khi > 16). |
| 2 | `[ERROR] runZonedGuarded: Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe.` (09:50:39) | Giải mã: `ConsumerStatefulElement._assertNotDisposed` ← `_runUpdate` (`library_updater.dart:85`, `ref.read(libraryUpdateProvider)`) ← `updateLibrary` ← `LibraryBody` (kéo để làm mới). Cập nhật thư viện kéo dài vài phút nhưng dùng `WidgetRef` của màn Thư viện – rời màn hình là cả lượt cập nhật văng. | `lib/services/library_updater.dart`: `_runUpdate({required YhProviderRead read})` (typedef `T Function<T>(ProviderListenable<T>)`), `updateLibrary` lấy `ProviderScope.containerOf(context, listen: false)` trước `await` đầu tiên và dùng `container.read` suốt vòng lặp; lỗi giữa chừng → `end()` + log `[Cập nhật thư viện] Dừng giữa chừng`. Import `flutter_riverpod/misc.dart show ProviderListenable` (Riverpod 3). |
| 3 | `[ERROR] [VPN] Tor dừng đột ngột khi khởi động (tiến trình bị đóng) – đã tắt Tor` (09:04:55) | **Báo động nhầm**: 09:01:46 Tor đã `PROGRESS=75 enough_dirinfo` (đã tải consensus – qua thời điểm tor từng `exit()`), 09:01:49 hệ thống gửi `onTrimMemory` (ứng dụng xuống nền), sau đó tiến trình bị đóng trong cửa sổ 25 s của bộ canh `torStartPending` (0.4.3) → lần mở sau tắt Tor. | `lib/yomihub/vpn/vpn_service.dart`: `_clearTorGuard()`; gỡ bộ canh khi `torDiag` báo `PROGRESS ≥ 50` và khi ứng dụng `onHide/onPause/onDetach` (`AppLifecycleListener`). Câu log đổi thành "Ứng dụng bị đóng trong lúc Tor đang khởi động (chưa tải xong dữ liệu mạng Tor)…". |
| 4 | `[ERROR] Extension "FikFap (18+)" … getDetail https://fikfap.com/post/1974019: SyntaxError: unexpected token: 'https'` ×4 (09:48:58) | Ứng dụng lưu `link` của `getDetail` (`https://fikfap.com/post/<id>`) làm URL của mục; lần cập nhật sau `getDetail` gọi `JSON.parse(url)`. | `assets/yomihub_extensions/fikfap.js`: `postId(url)` nhận JSON / `/post/<id>` / id; `getDetail` + `getVideoList` dùng `getJsonAny` (thử API phụ, báo HTML rõ ràng). Phiên bản tiện ích 0.4.3 → **0.5.2** (`builtin_extensions.dart`) để bản đã cài tự cập nhật. Kiểm tra: `node --check`, chạy `postId` với 3 dạng link. |
| 5 | `[ERROR] … Anime47: máy chủ trả về trang HTML thay vì dữ liệu (HTTP 404)` ×3 (12:15) – `getDetail https://anime47.best/phim/tensei-shitara-slime-datta-ken-4th-season-1` | Cùng kiểu (4): link lưu là `/phim/<slug>` (không có id); quy tắc cũ `(\d+)$` lấy nhầm **"1"** ở đuôi `…-4th-season-1` → `/anime/info/1` → 404. `curl` API thật: `search/full` trả `link "/phim/<slug>/m10321.html"`, danh sách trả `"/phim/<slug>-<id>"`. | `anime47.js`: `resolveId(url)` – `/m<id>.html` → id thuần → slug: tìm qua `search/full` (khớp slug, lưu đệm `a47_slug_<slug>`) → `-<id>` (≥ 3 chữ số) → báo lỗi rõ ràng (không còn đoán bằng số cuối). `getDetail` trả `link` dạng `/phim/<slug>/m<id>.html`. Phiên bản 0.1.4 → **0.5.2**. Kiểm tra bằng `node` trên Windows với API thật: slug cũ → **10321**, `fx-senshi-kurumi-chan-11297` → 11297. |
| 6 | `[WARNING] Extension "MiMiHentai" (Keiyoushi) getPageList 24403/48522: Unable to resolve host "mimihentai.moe24403"` (21:48:19) | Mã nguồn hiện tại của tiện ích (keiyoushi/extensions-source `src/vi/mimihentai`) dùng URL `/truyen/<slug>`; chương trong thư viện được lưu bởi bản tiện ích cũ (`24403/48522`, không có `/`) → bản mới ghép `baseUrl + url`. Bộ rewrite tên miền của YomiHub (`YomiNet.rewriteInterceptor`) đổi host đúng, không gây lỗi này. | `lib/yomihub/extensions/ext_errors.dart › hint`: nhận dạng host dính số (`…\.[a-z]{2,10}\d+`) → gợi ý "Đường dẫn chương/truyện được lưu từ phiên bản cũ của tiện ích… làm mới danh sách chương, hoặc dùng "Di chuyển"" thay cho "Tên miền không phân giải được". |
| 7 | `[ERROR] Extension "OPhim" (kychi vBook) search …: Error: vBook: search.js trả về kết quả rỗng` | Script vBook trả `null` khi không có kết quả – là trang rỗng, không phải lỗi. | `assets/yomihub_extensions/vbook.js › _list`: lỗi "trả về kết quả rỗng" → `{list: [], hasNextPage: false}`; `VBookBridge.runtimeRev` 3 → **4** (tiện ích vBook đã cài tự cập nhật runtime). |
| 8 | `[ERROR] Extension "Subsplease" search …: Unexpected JSON token … Expected start of the object '{', but had '['` | API Subsplease trả `[]` khi không có kết quả, tiện ích (Yūzōnō) chờ object. Ngoài ra mỗi dòng lặp lại cả tên phim dài (tìm kiếm toàn cục). | `lib/services/isolate_service.dart`: lỗi `search` dạng "Expected start of the object '{', but had '['" / `HTTP error 404` → INFO "nguồn không có kết quả cho từ khóa này" (không stack); từ khóa trong log cắt 80 ký tự. |
| 9 | `[WARNING] [Hiệu năng] Giao diện bị treo 2.6 giây … • đang chạy: cập nhật thư viện` (09:52:16), `Khung hình chậm … /manga-reader/detail • đang chạy: cập nhật thư viện` | `updateMangaDetail` (gọi cho từng mục khi cập nhật thư viện) chạy `mangaRepository.findById` (`getSync`) + `manga.chapters.loadSync()` trên luồng UI – bộ dài vài nghìn chương chặn UI. | `lib/modules/manga/detail/providers/update_manga_detail_providers.dart`: `await findByIdAsync` + `await manga.chapters.load()`. |
| 10 | `[INFO] [Hiệu năng] Khung hình chậm: dựng 4855ms • màn hình: /about` (09:01:05, ngay trước khi ứng dụng khởi động lại để cài bản cập nhật) | Khung hình bị tính cả thời gian Android tạm dừng ứng dụng khi mở trình cài APK (Kiểm tra cập nhật → cài) – không phải màn Giới thiệu chậm. | `lib/yomihub/perf/perf_watchdog.dart`: bỏ qua khung hình/khoảng treo trong 2 s quanh lúc ứng dụng đổi foreground ↔ background (`_lifecycleMonoMs`) và khi không ở foreground. |
| 11 | `[WARNING] [Thư mục cục bộ] Bỏ qua EPUB hỏng: …Bản Lĩnh Putin…` ×11 (mỗi lần mở ứng dụng) | `logOnce` chỉ nhớ trong một phiên; tệp hỏng bị đọc lại mỗi lần quét. | `lib/modules/library/providers/file_scanner.dart`: nhớ tệp hỏng (đường dẫn + kích thước + ngày sửa, tối đa 200) trong `YomiPrefs['badEpubs']`; lần quét sau bỏ qua, tệp được thay thì đọc lại. |
| 12 | `Cloudflare MyReadingManga`, `MissAV getDetail TimeoutException 3:00`, `Phimmoi RhttpConnectionException`, `Đề Xuất … Timeout 12–20s`, `Google Drive (all) Enter drive path(s)`, `Booru Rule34 missing authentication` | Trang nguồn / mạng / thiếu cấu hình của tiện ích (đã có gợi ý, mức WARNING). Phimmoi: `phimmoii.mom` nay chuyển hướng 301 → `phimmoii.cloud` (mục D). | Không phải lỗi mã; tên miền mới bổ sung ở mục D. |

#### D. Sheet "YomiHub Update" (7 mục)

**Mục 1 – log:** mục C.

**Mục 2 – Website Extension:**
- So khớp tự động (`audit-0.5.2/webext_052.json`) 52 dòng của sheet với `builtin_extensions.dart` + `url_override.dart` + `assets/yomihub_extensions/*.js`: **0 tên miền thiếu**; ngôn ngữ (`vi` / `all`) và NSFW khớp như 0.5.1.
- Kiểm tra trang thật (`curl.exe --doh-url https://1.1.1.1/dns-query`, 05/11 23:35, `audit-0.5.2/webext_urls.txt`): 200 – anime47.best, animevn.net, vtvgo.vn, cache.vtvgo.vn, hotphim.org, xemphimgi.com, nextphim.net, vfilm.vn, messiahelartista.com, pornhub.com (+/shorties), tik.porn, kwiky.com, xfree.com, fapreel.com, motphim.website, hihiphim.com, sayhentai.cx, sayhentaii.art, docln.sbs; 403 (Cloudflare/chặn bot, cần WebView) – animevietsub, hentaicube.xyz, 2tencb.pro, sonako.fandom.com; 000 (nhà mạng chặn / hết thời gian) – rophimhd.com, phimhaychill.org, fikfap.com, top1sexvn.com, damconuong.*, phimmoihd.online, ln.hako.vn, docln.net.
- **Tên miền mới** (chuyển hướng 301): `phimmoii.mom → phimmoii.cloud`, `animevietsub.nl → animevietsub.best`, `xoilacvb.cc → xoilac.run`, `xoilac32.org → xoilactv3.co`, `motchill10.io → motchill10.com.mx` → thêm vào `url_override.dart › defaultMirrors` (nhóm Phimmoi, AVSub, Xôi Lạc, MotPhim).

**Mục 3 – Dự án GitHub:** 576 liên kết khác nhau của `Project GitHub.xlsx` (chuẩn hoá: bỏ `#`, `?`, `/` cuối, `www.`, http→https) so với 623 liên kết trong `github_projects.dart`: thiếu **1** – chính repo `kiritokmn1403/YomiHub-Project` → thêm "YomiHub – mã nguồn và bản phát hành (0.5.2)" (dịch 18 ngôn ngữ).

**Mục 4 – Sao lưu / Khôi phục bị lỗi** (kiểm tra thật trên Note 9 với bản 0.5.1 trước khi sửa, 05/11 22:42 → 23:15; video `n9v_*`, ảnh `n9_*`):

| Phép thử (0.5.1) | Kết quả |
| --- | --- |
| Tạo bản sao lưu (thư viện trống) | Thành công, 3,5 MB – nhưng thông báo "**Backup created!**" tiếng Anh. |
| Khôi phục Nekoyomi `app.nekoyomi_2026-09-14_13-59.tachibk` (16 MB), Gộp | Thành công: 2.698 bộ, 51.195 chương. |
| Tạo bản sao lưu thư viện lớn | Thành công, 5,2 MB; giải nén kiểm tra bằng Python: 2.698 bộ, 62.030 chương, 46 danh mục, 2.659 lịch sử. |
| Khôi phục Mangayomi `mangayomi_2026-09-27_14_58_56.033852.backup` (22 MB, kèm **3.830 tiện ích, 251 tiện ích đã cài có mã**), Gộp | Nhập được 1.793 bộ mới / 2.701 cập nhật / 37.779 chương, nhưng hộp "**Không tìm thấy nguồn**" liệt kê CBHentai, FoxTruyen, HentaiVN.plus… dù bản sao lưu có sẵn các tiện ích đó; sau khi nhập các bộ mới mang `sourceId = null` (mở ra không có chương). Có 1 dòng nguồn **không tên** (412 bộ `source = ""`). Choreographer: bỏ 128 khung hình khi bắt đầu nhập. |
| Khôi phục TachiyomiMi `xyz.jmir.tachiyomi.mi_2026-08-21_20-44.tachibk` (12 MB) | Sau khi chọn tệp, **45 giây** màn hình đứng yên, không có dấu hiệu đang xử lý, rồi mới hiện "Nhập theo cách nào?" – lần đầu tưởng hỏng, chạm tiếp làm đóng hộp thoại. |

Nguyên nhân (mã):
1. `.tachibk` được giải nén bằng `GZipDecoder` của gói `archive` (Dart thuần) **3–4 lần trên luồng UI**: `_sniffTachiBk` (nhận dạng), `previewTachiBkImport`, `restoreTachiBkBackup`, nhập kho tiện ích.
2. `restoreBackup(merge: true)` chỉ gộp truyện/chương/lịch sử/cập nhật; tiện ích, cài đặt tiện ích chỉ được ghi khi **Thay thế** (`if (full)`), nên Gộp làm mất nguồn của mọi bộ mới.
3. `decodeMangayomiBackup`: `catch (_)` bắt **mọi** lỗi (tệp hỏng, JSON lỗi, hết bộ nhớ) rồi hỏi mật khẩu – bản sao lưu không mã hoá bị hỏng hiện "nhập mật khẩu" và lỗi thật không được ghi log; giải nén + `jsonDecode` (~150 MB JSON) trên luồng UI.
4. Tạo bản sao lưu: `jsonEncode` + nén ZIP trên luồng UI; không ghi log khi thành công/khôi phục; thông báo tiếng Anh ("Backup created!", "Backup restored!", "Backup failed", "Error restoring backup", "Unsupported or unrecognized backup file").

Sửa:
- `backup_format.dart`: `yhGunzip` (zlib của nền tảng – `dart:io gzip`, dự phòng `GZipDecoder`), `tachiBkBytes(path)` (lưu đệm theo đường dẫn + kích thước + ngày sửa), `warmTachiBk(path)` (giải nén trong `Isolate.run`), `clearTachiBkCache()`; `_sniffTachiBk`, `previewTachiBkImport`, `restoreTachiBkBackup` dùng bản đã giải nén. `backupInstalledExtensions(backup)` (tiện ích `isAdded` có mã, kể cả `yomihub.extensions`); `previewMangayomiBackup` coi các tiện ích đó là có sẵn.
- `restore.dart`: `_installBackupExtensions` – khi Gộp, cài tiện ích có trong bản sao lưu nếu máy chưa có nguồn cùng tên/ngôn ngữ/loại (không ghi đè nguồn đã cài cùng id), kèm cài đặt tiện ích của chúng (`id = null`, không ghi đè hàng của nguồn khác); làm mới màn hình sau khi gộp; log `[Sao lưu] Đã khôi phục … (gộp/thay thế): N bộ, M chương, cài K tiện ích…`, `Khôi phục xong`, `Khôi phục thất bại` (ERROR + stack), `Không nhận ra định dạng`.
- `backup_decoder.dart`: `_decodeBackupFile` trong `Isolate.run`; `_firstZipEntryEncrypted` (bit 0 cờ của header ZIP) – chỉ hỏi mật khẩu khi tệp thật sự được mã hoá, còn lại báo + log "Không đọc được bản sao lưu (tệp hỏng…)".
- `unified_restore.dart`: hộp "**Đang đọc bản sao lưu…**" trong lúc giải nén/nhận dạng/xem trước; thông báo lỗi tiếng Việt + log; nhãn "(Không rõ nguồn)" cho nguồn tên rỗng; giải phóng bộ đệm `.tachibk` sau khi xong.
- `backup.dart`: `jsonEncode` + nén ZIP trong `Isolate.run`; log `[Sao lưu] Đã tạo bản sao lưu … (x MB) trong …` / `Tạo bản sao lưu thất bại (đường dẫn): lỗi + stack`; chuỗi tiếng Việt qua `tr()`.
- `data_and_storage.dart`: "Vị trí tải xuống" báo đỏ khi thư mục tuỳ chọn không còn tồn tại (Note 9: thẻ nhớ `/storage/7563-670C` đã được thay bằng `/storage/0000-0000`, ứng dụng vẫn trỏ tới thẻ cũ); dòng ghi chú "Dùng cho tải chương" đưa biểu tượng và chữ về cùng một hàng (trước đây trông như một hàng thiếu tiêu đề trên màn DeX).
- Telegram (sheet Feature Check mục sao lưu Telegram; log 03/11 12:26 "Chưa tìm thấy Chat ID" ×2 trong 7 s): `cloud_backup_service.dart › _detectChatId(wait: true)` – nếu `getUpdates` trả 409 (bot đang dùng webhook) thì `deleteWebhook` rồi đọc lại; nếu chưa có tin nhắn thì long-poll tối đa 55 s để người dùng kịp nhắn `/start` sau khi bấm Kết nối.

**Mục 5 – treo/lag/văng:** mục C1, C2, C9, C10; tạo/khôi phục sao lưu không còn chạy việc nặng trên luồng UI.

**Mục 6 – Windows (AMD Ryzen 9) thiếu tính năng:** không có máy Ryzen 9 để thử; máy kiểm thử Intel i5-11300H + GTX 1650/Iris Xe (đã cài Visual Studio, JDK, WebView2 156.0.4314.58). Rà gói Windows 0.5.1:
- `Release\` **không có VC++ runtime** (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`) – các thư viện nạp bằng FFI lúc chạy (`rust_lib_mangayomi.dll`, `libisar.dll`, `libmtorrentserver.dll`, `dartjni.dll`, `libmpv-2.dll`) dựa vào runtime của hệ thống.
- `Setup.exe` / `.zip` được đóng gói từ gói **nhẹ** (không có JRE + MExtensionServer); chỉ `-full.zip` có. Trên máy mới, các nguồn Mihon/Aniyomi (ApkBridge), Kotatsu, IReader không chạy cho tới khi người dùng tìm thấy "Cài đặt › Duyệt › M-Extension-Server › Cài tự động" – đúng với mô tả "không có đầy đủ tính năng". Máy dựng không gặp vì đã cài bản này từ trước (thư mục `%APPDATA%\…\mes`).
- Sửa: `build_052.ps1 -step win` chép VC++ runtime từ `VC\Redist\MSVC\14.44.35112\x64\Microsoft.VC143.CRT` vào cạnh `YomiHub.exe`; `-step pack` đóng `Setup.exe` từ gói **-full** (`.appxbundle` vốn đóng từ thư mục `Release` đã có `yomihub_bin\mes`).
- Mới `lib/yomihub/win/win_diag.dart` (`WinDiag.runOnce`, gọi trong `_postLaunchInit` sau 12 s, 1 lần mỗi phiên bản): ghi vào Nhật ký hệ điều hành, CPU (`ProcessorNameString`), số luồng, GPU + driver, WebView2 Runtime, Java/M-Extension-Server, thư mục cài; mỗi thành phần thiếu → 1 dòng `[Windows] Thiếu thành phần: … – <tính năng bị tắt>`. Từ nay chỉ cần gửi `logs.txt` của máy Ryzen là biết tính năng nào thiếu và vì sao.

#### E. Kiểm thử bản dựng 1 trên Note 9 (06/11 00:12 → 00:52)
- Bản dựng 1 (arm64, 00:09): cài đè 0.5.1 → 0.5.2 (versionCode 2044) thành công; Giới thiệu "Beta (0.5.2)"; "Vị trí tải xuống" báo đỏ thư mục thẻ nhớ cũ; khôi phục `.tachibk` hiện "Đang đọc bản sao lưu…" ngay (nhưng vẫn ~53 s → tối ưu protobuf, mục D); Gộp Mangayomi: "Không tìm thấy nguồn" còn 6 nguồn (trước > 20), tiện ích FoxTruyen/CoManhua/Comick/MangaDex… được tự cài.
- Lỗi phát hiện nhờ kiểm thử và đã sửa ở bản dựng 2 (00:51, analyze 0 lỗi, test 109/109):
  1. `Cannot use the Ref of updateMangaDetailProvider … disposed` (màn chi tiết + cập nhật thư viện) – do `await` đầu hàm (bản sửa C9) → `ref.keepAlive()` + `close()` trong `finally`; cập nhật thư viện giữ provider bằng `container.listen`.
  2. `Cannot use the Ref of restoreBackupProvider(…) disposed` khi kết thúc khôi phục (cũng xảy ra ở chế độ Thay thế của bản gốc) → không dùng `ref` sau `await` trong các provider khôi phục; `doRestore` (keepAlive) làm mới màn hình.
  3. Lỗi trên in toàn bộ bản sao lưu vào log → `logs.txt` 133 MB, `crash_reports.json` 132 MB → `AppLogger.log` cắt dòng > 16.000 ký tự, `CrashReports.record` cắt lỗi > 8.000 ký tự.
  4. Bộ đã có trong thư viện nhưng mất nguồn (nhập từ Nekoyomi khi chưa có tiện ích) được gắn lại nguồn khi Gộp; `installedSourcesFor` chỉ đọc 1 lần (trước đây mỗi bộ đọc lại 3.800+ tiện ích kèm mã → treo 22–64 s).
- Các màn Ebook & PDF, AirDrop & Quicksharing, VPN & DNS, Lịch, Cài đặt, Play Books mở bình thường (ảnh `n9_52_31…37`).

#### F. Kiểm thử bản dựng 2 trên Note 9 (06/11 06:07 → 06:47)
- Cài `YomiHub-0.5.2-arm64-v8a.apk` (168,8 MB, dựng 00:51; analyze 0 lỗi, 109/109 test) – "Success".
- Khôi phục TachiyomiMi `.tachibk` 12 MB: hộp **"Đang đọc bản sao lưu…"** hiện sau **4 s** (0.5.1: 45 s không có phản hồi), sau đó hộp "Nhập theo cách nào?" (ảnh `n9_52_54_restore_busy`, `n9_52_55…`). Thời gian đọc chính xác chưa đo được: máy đang quá nhiệt (xem dưới) và việc dò giao diện bằng `uiautomator` mỗi giây làm chậm thêm.
- **Trở ngại thiết bị (không phải lỗi ứng dụng):**
  - Wi-Fi của Note 9 mất kết nối từ ~06:20 (`Active default network: none`, `ip rule` không còn bảng wlan0; Samsung Internet cũng báo "chưa kết nối mạng"; `nc` từ adb shell: "Network is unreachable"), nên Anime47 báo `RhttpConnectionException … Network unreachable` – chưa test lại được nguồn online.
  - Máy quá nhiệt: `thermalservice` Status 3 (SEVERE), CPU 55,2 °C, pin 45,7 °C, cổng USB 47,4 °C (đang sạc + DeX suốt đêm + ghi hình bằng screencap liên tục). One UI tự đóng "Trình điều khiển quyền" và **YomiHub** ("đã tự động đóng vì khiến điện thoại quá nóng") lúc đang Gộp (06:43–06:46). Ảnh `n9_52_57_overheat_killed`.
- Trong lúc chờ máy nguội: đã đưa vào hàng đợi `build_052 -step win` + `-step pack` (bắt đầu 06:34).
- Kết nối tới máy tính (cầu nối thiết bị) bị ngắt lúc ~06:49.

#### G. Tiếp tục kiểm thử (06/11 06:50 → 07:01)
- Máy nguội dần: Thermal Status 3 → 1 (06:50) → 0 (06:55), pin 40,8 °C → 38,1 °C. Wi-Fi tự kết nối lại vào mạng "Ban Dieu Hanh Du An CLC 2" (Active default network 613), `ping 1.1.1.1` 36 ms.
- **Anime47** (bản dựng 2): tìm "slime" trả đủ danh sách (15 kết quả, có "Tensei shitara Slime Datta Ken 4th Season"); mở phim → `getDetail 10321` (id đúng, không còn `/anime/info/1` → 404). Trang báo "Anime47 cần đăng nhập": `curl` xác nhận API `anime/info/10321` trả **HTTP 401 `PRIVATE_MODE`** – trang đang bật chế độ riêng tư, phải đăng nhập (người dùng tự đăng nhập qua Webview; Claude không nhập mật khẩu). Ảnh `n9_52_59_a47_search`, `n9_52_60_a47_detail`.
- **Cập nhật thư viện rồi rời màn hình** (Phim & Điện ảnh → kéo làm mới → chuyển sang "Thêm"): thanh "Đang cập nhật thư viện" vẫn chạy và kết thúc, mục được xử lý lúc 06:56:34 sau khi đã rời màn Thư viện; **không còn** lỗi `Using "ref" … unmounted` / `Null check operator` (log `n9_logs_052b.txt`). Lỗi duy nhất: Rule34Video `HTTP 404` cho một video đã bị gỡ khỏi trang (lỗi nguồn).
- **Bản Windows** dựng xong 06:56 (flutter build windows 1065 s; VC++ runtime 14.44.35112 đã chép; xray + tor; bridge 54 jar 21,5 MB): `windows-x64.zip` 139,2 MB, `-full.zip` 267,0 MB; `pack` 06:58: `Setup.exe` (từ gói -full) 280 MB, `.appxbundle` 284,7 MB, `Install-YomiHub.bat/.ps1`, `YomiHub-RootCA.cer`, `SHA256SUMS-0.5.2.txt`.
- 06:59: đưa vào hàng đợi `build_052 -step apk` (3 ABI) + `-step tv` (3 APK "YumiHub Android TV").
- Khôi phục TachiyomiMi (lần 2, máy đã nguội): hộp "Đang đọc bản sao lưu…" hiện ngay sau khi chọn tệp (07:00:4x); đang đo thời gian tới hộp "Nhập theo cách nào?" thì cầu nối thiết bị ngắt lần 2 (~07:01).
- Ghi chú công cụ: trên DeX, `input -d 2 swipe` không cuộn danh sách Flutter; phải dùng `input touchscreen -d 2 swipe` (đã sửa `adb.sh`). `uiautomator dump` lấy cửa sổ đang focus (có khi là màn hình chính của điện thoại) nên dùng ảnh chụp + kiểm tra điểm ảnh (`dlg.ps1`) để đo thời gian hộp thoại.

#### H. Đo lại sao lưu/khôi phục trên Note 9 (máy đã nguội, Thermal 0) – bản dựng 2 → sửa thêm (bản dựng 3)
| Phép thử (bản dựng 2) | Kết quả |
| --- | --- |
| TachiyomiMi 12 MB: chọn tệp → hộp "Nhập theo cách nào?" | ~73 s (07:00:47 → 07:02:00), hộp "Đang đọc bản sao lưu…" hiện suốt thời gian chờ (0.5.1: 45 s không có gì trên màn hình). |
| TachiyomiMi – Gộp | Hộp "Danh mục trùng" → "Không tìm thấy nguồn" (5 nguồn, có nhãn "(Không rõ nguồn)") → "Sẵn sàng nhập: 0 bộ mới, 4407 cập nhật, 9053 chương mới" → nhập xong sau **75 s**, thông báo "Đã nhập 0 bộ mới, cập nhật 4407 bộ có sẵn, thêm 9053 chương mới" + "Hoàn tác". Nhật ký: **"Giao diện bị treo 46.1 giây"** trong lúc ghi. |
| Mangayomi 22 MB (3.830 tiện ích) – chọn tệp → hộp chọn | 95–107 s; 3 lần "treo 2.6 giây" trong lúc xem trước. |
| Mangayomi – Gộp | "Không tìm thấy nguồn" chỉ còn **6** nguồn (TruyenGG, AnimeOnsen, (Không rõ nguồn), XBatCat, Nguồn anime trên thiết bị, SupJav) – 0.5.1 liệt kê cả CBHentai, FoxTruyen, HentaiVN.plus… dù bản sao lưu có sẵn tiện ích. Nhập 4494 bộ / 5858 chương trong **19 s**. |

Nguyên nhân còn lại (đọc mã): phần xem trước và phần Gộp vẫn truy vấn chương **đồng bộ cho từng bộ** (4.400 lần `getAllByMangaId` trên luồng UI), và bộ không có gì mới vẫn bị ghi lại.

Sửa (bản dựng 3, `e15`–`e22`):
- `backup_format.dart`: `_chapterUrlsFor` / `yhChapterUrlsFor` – đọc URL chương của các bộ đã có bằng truy vấn Isar **bất đồng bộ, theo lô 200 id**; `previewTachiBkImport` và `previewMangayomiBackup` dùng `getAllAsync` + bản đồ này; ghi log thời gian giải mã/xem trước.
- `restore.dart › restoreTachiBkBackup` (Gộp): nạp trước URL chương ngoài giao dịch ghi; bỏ qua bộ không đổi danh mục và không có chương mới (không `putSync` lại); chỉ ghi chương mới.
- `backup_decoder.dart`: log thời gian giải nén + đọc JSON.
- `logger.dart`: tham số `always` – dòng INFO vẫn được ghi khi tắt "Bật nhật ký" (kết quả sao lưu/khôi phục, chẩn đoán Windows; trước đó các dòng `[Sao lưu] Đã tạo/khôi phục…` và `[Windows] Chẩn đoán` ở mức INFO bị bỏ qua nên không có trong `logs.txt` của người dùng).
- `crash_report.dart`: lỗi của tiện ích/mạng (vd. "Anime47 cần đăng nhập") ghi WARNING thay vì ERROR.
- `fetch_sources_list.dart`: lỗi TLS (`HandshakeException` – kho kohiden.xyz, 5 dòng ERROR + stack trong 7 phút) xử lý như lỗi mạng (1 dòng/host/phiên).
- `test/yh_052_test.dart`: thêm test WinDiag, đóng gói, mức log lỗi nguồn, `always`, không còn truy vấn chương từng bộ.
- `build_052.ps1`: `audit-0.5.2\SKIP_STEPS` để bỏ qua bước đang chờ bản mã mới.
- 07:29: bản APK (bản dựng 2, 3 ABI) xong – arm64 168,8 MB, armeabi-v7a 165,7 MB, x86_64 178,2 MB; bước TV được bỏ qua bằng `SKIP_STEPS` (sẽ dựng lại từ bản 3).
- **Bản dựng 3** (07:29): `dart analyze` 0 lỗi (216 gợi ý/cảnh báo), `flutter test` **112/112** đạt (thêm 3 test so với bản 2); 07:37 bắt đầu dựng APK 3 ABI.
- 07:39: cầu nối thiết bị lại bị ngắt trong lúc mở màn VPN & DNS trên Note 9 (để kiểm tra VPN ngoài ứng dụng).

#### I. Bản dựng 3 trên Note 9 (07:53 → 08:16)
| Phép thử | 0.5.1 / bản 2 | Bản 3 |
| --- | --- | --- |
| TachiyomiMi 12 MB: chọn tệp → "Nhập theo cách nào?" | 45 s im lặng (0.5.1) / 73 s (bản 2) | **8,1 s** (log: giải mã ở luồng nền 1,7 s, xem trước 4,4 s) |
| TachiyomiMi Gộp (dữ liệu đã có) | 75 s, treo UI 46 s | 57,6 s, **không còn dòng "Giao diện bị treo"**; thời gian chủ yếu chờ nhập kho tiện ích (kohiden.xyz lỗi TLS) → sửa tiếp ở bản 4 (nhập kho chạy nền) |
| Mangayomi 22 MB: chọn tệp → hộp chọn | 95–107 s (bản 2) | **10,6 s** (giải nén + JSON 2,7 s, xem trước 6,7 s) |
| Tạo bản sao lưu (2.698+ bộ) | – | 23,6 MB trong ~8 s, thông báo "Đã tạo bản sao lưu!" + log `[Sao lưu] Đã tạo…` (không có dấu hiệu đang chạy trong 8 s → bản 4: vòng quay `BotToast.showLoading`) |

- Phát hiện thêm: bản xem trước Mangayomi báo "thêm 5858 chương mới" nhưng Gộp **không ghi** chương mới cho bộ đã có (mã gốc chỉ ghi chương cho bộ mới) → bản 4: Gộp thêm chương còn thiếu (so URL) cho cả bộ đã có, không đụng chương cũ.
- **VPN ngoài ứng dụng** (chế độ "Toàn bộ thiết bị"):
  - Cloudflare WARP trên Wi-Fi "Ban Dieu Hanh Du An CLC 2": giao diện báo "Đã kết nối • Toàn bộ thiết bị", có biểu tượng chìa khoá VPN, `dumpsys connectivity` có mạng VPN 616, nhưng logcat WireGuard lặp "Handshake did not complete after 5 seconds" và Samsung Internet không tải được trang → mạng chặn UDP 2408. **Lỗi hiển thị sai trạng thái** → bản 4 (`e26`): kiểm tra thật qua `cloudflare.com/cdn-cgi/trace` (`warp=on`), thử lần lượt cổng 2408 → 500 → 4500 → 1701 → 854, nhớ cổng chạy được; không bắt tay được thì gỡ đường hầm (tránh mất mạng toàn máy) và báo lỗi rõ ràng (dịch 18 ngôn ngữ).
  - **Tor** (toàn bộ thiết bị): kết nối, Samsung Internet mở `check.torproject.org` → "Congratulations. This browser is configured to use Tor." (IP thoát 195.47.238.50). Ảnh `n9_53_30_browser_torcheck`.
  - Sau kiểm thử: tắt VPN, trả phạm vi về "Chỉ YomiHub", mạng bình thường.
- **Android TV** (AVD `YomiHub_TV_API34`, x86 + dịch ARM → cài APK TV `armeabi-v7a`; APK x86_64 báo `INSTALL_FAILED_NO_MATCHING_ABIS` vì AVD là x86 32-bit): tên "YumiHub Android TV", Giới thiệu "Beta (0.5.2)", thanh bên chỉ có Phim & Điện ảnh / Cập nhật / Duyệt / Thêm (không Truyện tranh, Tiểu thuyết, Play Books, Booru), Duyệt chỉ có tiện ích Phim & Điện ảnh, HotPhim tải danh sách Phổ biến, điều hướng D-pad có viền focus. Ảnh `tv_52_01…06`.
- Bản dựng 4 (`e23`–`e26`, `tr052c.py`) đưa vào hàng đợi lúc 08:16 (bản giữa lúc 08:09 thiếu `e26` nên bị bỏ qua bằng `SKIP_STEPS`): sync → analyze/test → APK 3 ABI → TV 3 ABI → Windows → đóng gói.

#### J. Bản dựng cuối (bản 4) – kiểm thử trên Note 9 (08:54 → 09:08)
- Dựng 08:31–08:51: `dart analyze` 0 lỗi; `flutter test` **113/113** đạt (thêm test WARP vào repo sau khi đã chạy – chạy lại ở bước `unit` trước khi commit); APK arm64-v8a / armeabi-v7a 165,7 MB / x86_64 (nhãn `YomiHub` được `aapt2` xác nhận).
- **WARP – sửa đã kiểm chứng trên mạng thật:** chế độ "Chỉ YomiHub": log `[VPN] WARP đã bắt tay với Cloudflare (cổng 2408)`. Chuyển "Toàn bộ thiết bị": log `WARP: không bắt tay được qua cổng UDP 2408` → `WARP đã bắt tay với Cloudflare (cổng 500)` (tự đổi cổng sau 8 s); Samsung Internet mở `cloudflare.com/cdn-cgi/trace` → **`warp=on`**, `loc=VN`, `colo=HKG`. Ảnh `n9_54_03_warp_result`, `n9_54_05_trace_page`. Sau đó tắt VPN, trả về "Chỉ YomiHub".
- **Tạo bản sao lưu:** vòng quay chờ hiện trong lúc tạo (ảnh `n9_54_08_backup_spinner`), tệp 23,6 MB, log `[Sao lưu] Đã tạo…`.
- **Gộp Mangayomi 22 MB:** đọc tệp → hộp chọn 8,1 s; Gộp 4.494 bộ xong sau **22,6 s**, log `Đã khôi phục … (gộp): 4494 bộ, 88536 chương`, không có dòng "Giao diện bị treo". Mở lại cùng tệp: xem trước báo **"0 chương mới"** (trước khi Gộp: 5.858) → chương còn thiếu đã thực sự được ghi cho các bộ đã có.
- Trong lúc tự động hoá có một lần chạm nhầm bỏ chọn danh mục "Manhua - Trung Quốc" ở hộp "Danh mục trùng"; đã chọn lại trước khi bấm OK (ảnh `PRIVATE_n9_54_13_cats_fixed`), không ảnh hưởng thư viện.
- Ảnh có thư viện/bìa truyện của người dùng được đặt tên `PRIVATE_*` và **không** đưa vào gói QA công khai; các video quay màn hình (`n9v052_*.mp4`) chứa thư viện cá nhân nên chỉ giữ trong `audit-0.5.2/qa`.

#### K. Bản cuối – dựng, Android TV, Windows, phát hành (06/11 08:31 → 11:xx)
- **Gói phát hành** (`output/0.5.2`, `SHA256SUMS-0.5.2.txt`):

| Tệp | Kích thước | SHA-256 (đầu) |
| --- | --- | --- |
| YomiHub-0.5.2-arm64-v8a.apk | 168,8 MB | `9cd734f8…` (đúng tệp đã cài lên Note 9) |
| YomiHub-0.5.2-armeabi-v7a.apk | 165,7 MB | `587cad31…` |
| YomiHub-0.5.2-x86_64.apk | 178,2 MB | `523e698a…` |
| YumiHub-Android-TV-0.5.2-arm64-v8a.apk | 168,7 MB | `ba915839…` |
| YumiHub-Android-TV-0.5.2-armeabi-v7a.apk | 165,5 MB | `53ba73fd…` |
| YumiHub-Android-TV-0.5.2-x86_64.apk | 178,0 MB | `2bf133d6…` |
| YomiHub-0.5.2-windows-x64-Setup.exe (gói đầy đủ) | 267,1 MB | `ec7ff795…` |
| YomiHub-0.5.2-windows-x64.appxbundle | 271,5 MB | `234fc94b…` |
| YomiHub-0.5.2-windows-x64.zip (portable) | 139,2 MB | `084e263d…` |
| YomiHub-0.5.2-windows-x64-full.zip (portable + JRE/MES) | 267,0 MB | `f2fe289c…` |

  Nhãn APK được `aapt2 dump badging` xác nhận: điện thoại `YomiHub`, TV `YumiHub Android TV`. `flutter test` chạy lại sau cùng (`-step unit`, 11:07): **114/114** đạt (gồm test WARP).
- **Android TV bản cuối** (AVD `YomiHub_TV_API34`, APK TV `armeabi-v7a` 09:08): cài "Success", HotPhim tải danh sách Phổ biến, thanh bên chỉ có Phim & Điện ảnh / Cập nhật / Duyệt / Thêm (ảnh `tv_52_07_final_hotphim`, `tv_52_08_final_more`).
- **Windows** (máy dựng i5-11300H, GTX 1650 + Iris Xe, Windows build 26300):
  - Portable `-full.zip` giải nén ra `D:\yh\qa052\portable_full` (443 tệp): có `YomiHub.exe` (FileVersion 0.5.2+44), `vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140.dll`, `libmpv-2.dll`, `rust_lib_mangayomi.dll`, `yomihub_bin\xray.exe`, `tor\tor.exe`, `bridge\lib` (54 jar), `mes` (JRE + M-Extension-Server).
  - Chạy portable: nhật ký ghi `[INFO] [Windows] Chẩn đoán: "Windows 10 Pro" 10.0 (Build 26300) • CPU 11th Gen Intel(R) Core(TM) i5-11300H @ 3.10GHz (AMD64, 8 luồng) • GPU NVIDIA GeForce GTX 1650 …; Intel(R) Iris(R) Xe Graphics … • WebView2 156.0.4314.58 • Java có • thư mục …` (ghi được dù "Bật ghi nhật ký" tắt – tham số `always`), không có dòng "Thiếu thành phần" vì đủ tệp; M-Extension-Server khởi động (Windows Firewall hỏi quyền mạng cho `javaw.exe` của thư mục portable – Claude không trả lời hộp thoại bảo mật này).
  - `Setup.exe`: cài đè bản 0.5.1 ở `C:\Users\nguye\AppData\Local\YomiHub` (mặc định), có VC++ runtime và `yomihub_bin\mes`; tự mở ứng dụng; tiến trình `Responding = True`, nhật ký khởi động bình thường (MAL token, kho tiện ích, ảnh).
  - **Không chụp được giao diện Windows lúc kiểm thử:** cửa sổ Flutter hiện trắng/xám trong ảnh chụp màn hình (computer use, `PrintWindow`, `gdigrab`) – bản **0.5.1** chạy cùng lúc cũng trắng y hệt, ứng dụng vẫn phản hồi và ghi nhật ký → do môi trường chụp màn hình của máy lúc đó (Samsung DeX trên PC đang chạy, GPU lai), không phải lỗi của 0.5.2. Không có ảnh Windows trong gói QA lần này.
  - Ghi nhận thêm (chưa sửa, không thuộc phạm vi): bản Windows có cài đặt "tự sao lưu" khôi phục từ máy Android nên tạo bản sao lưu vào đường dẫn Android `/storage/3730-6132/Backup & Sync/Mangayomi` (thành thư mục `\storage\…` trên ổ hiện tại).
