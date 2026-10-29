### 28/10/2026 — Cập nhật phiên bản 0.4.3 (YomiHub 0.4.3+35)

> Thực hiện bởi Claude (Cowork). Công cụ: GitHub Desktop (fetch nhánh `main` của `YomiHub-Project`), Flutter 3.47.6 / Dart 3.13.5 trong `D:\yh\tools\flutter`, Android SDK + Android Emulator (AVD `Medium_Phone_API_37.0`, `OOS_Android6_API23`, AVD mới `YomiHub_TV_API34`), Visual Studio 2022 Build Tools (MSVC, `flutter build windows`), NDK 28.2 (clang), Python/patchelf (máy ảo Linux của phiên làm việc), PowerShell job runner (`run_jobs.ps1`, `run_jobs_fast.ps1`), ffmpeg 9.0.2 (quay màn hình Windows), `adb screenrecord/screencap` (quay/chụp Android). Mọi sửa đổi được làm trong `overlay` rồi chép sang `D:\yh\build\mangayomi` và `D:\yh\buildwin\mangayomi`; bản trước khi sửa lưu ở `audit-0.4.3/before/android|windows`, danh sách tệp ở `audit-0.4.3/changed_files.txt`.

**Yêu cầu:** nâng lên 0.4.3; Android 6.0+ và mọi bản Android TV (APK riêng `YumiHub Android TV`, bỏ Comic/Novel); Windows 7+ (x64/x86/ARM) với 3 gói `.appxbundle`, `.exe`, portable; làm từng mục sheet `Feature Check` (39) và `YomiHub Update` (12); sửa lỗi trong `logs 22.txt`; ghi nhật ký vào tệp này; kiểm thử có ảnh/video.

#### A. Lỗi phát hiện trong `logs 22.txt` (6.504 dòng, 21–28/10/2026) và cách sửa

| # | Lỗi trong log | Nguyên nhân | Sửa (tệp) |
|---|---|---|---|
| 1 | `[Hiệu năng] Giao diện bị treo 111.2 giây` (27/10 20:33) | Bộ phát hiện treo đo bằng đồng hồ thực (`DateTime`); khi máy ngủ/tắt màn hình thời gian vẫn chạy → báo treo giả. | `lib/yomihub/perf/perf_watchdog.dart`: đo bằng `Stopwatch` đơn điệu, bỏ qua khi chênh lệch đồng hồ thực ≫ đồng hồ đơn điệu (máy ngủ), giới hạn < 600 s; log kèm tác vụ đang chạy (`YomiPerf.activity`). |
| 2 | 698 × `Failed to update Manga:` + 455 × `Missing Madara post ID from redirection` (CBHentai/Madara), log 2 dòng + stack dump cho mỗi truyện | Vòng cập nhật thư viện thử lại mọi truyện của một nguồn đang hỏng; ghi 2 dòng rời rạc không có tên truyện/nguồn. | `lib/services/library_updater.dart`: kiểm tra mạng trước khi chạy; ngắt mạch theo nguồn (lỗi 3 lần liên tiếp → bỏ qua phần còn lại của nguồn trong lần chạy đó, ghi rõ); log 1 dòng `[Cập nhật thư viện] … "<tên>" • nguồn: … • lỗi: …` (bỏ stack dump). |
| 3 | 13–26 × `fetchStore failed … Failed host lookup` + `fetchSourcesList … unreachable` khi mất mạng, ngay sau đó treo UI | Mỗi request tự phân giải DNS (5 s hệ thống + 2 lần DoH, không timeout) song song ~30 kho; JSON chỉ mục lớn giải mã trên luồng UI; mã cũ còn `utf8.decode` toàn bộ tệp protobuf chỉ để kiểm tra ký tự đầu. | `lib/services/http/m_client.dart`: cache lỗi DNS 30 s, gộp truy vấn trùng (in-flight), timeout DoH 4 s. `lib/services/extension_store_service.dart`: chỉ đọc vài byte đầu, giải mã JSON > 64 KB bằng `Isolate.run`, log mất mạng 1 lần/host, lỗi kho khác 1 lần/URL/phiên. |
| 4 | `SyntaxError: unexpected token: '<'` (FikFap, CBHentai Kotatsu, Shorts) | Trang trả HTML (Cloudflare/chặn) thay JSON. | `lib/eval/javascript/service.dart`: bọc `JSON.parse` trong runtime JS → báo rõ "máy chủ trả về trang Cloudflare/HTML". `assets/yomihub_extensions/fikfap.js` (v0.4.3): thử API cấu hình rồi `api.fikfap.com`, nhận diện HTML. |
| 5 | `Drive update check failed: … Software caused connection abort` | Chỉ thử lại 1 lần; 1 thư mục con lỗi làm hỏng cả lần kiểm tra. | `lib/yomihub/update/drive_update.dart`: 3 lần thử, giãn cách tăng dần, dừng ngay khi lỗi DNS; bỏ qua thư mục con lỗi (ghi log); bỏ qua thư mục phiên bản cũ hơn khi đã có bản mới hơn. |
| 6 | `Unable to resolve host "mimihentai.net24403"`, `relative URL without a base` | Đã sửa ở 0.4.1 (`sanitizeUrl`); các dòng log thuộc bản cũ. | Thêm test hồi quy trong `test/yh_043_test.dart`. |
| 7 | `Tor chưa kết nối được`, `OpenVPN: máy chủ từ chối đăng nhập` | Mạng/nhà cung cấp chặn Tor; sai tài khoản OpenVPN của người dùng. | Không phải lỗi mã; theo yêu cầu, VPN chỉ kiểm tra bên ngoài ứng dụng. |
| 8 | `CertPathValidatorException: Trust anchor…` (TruyenHentaiVN Kotatsu) | Máy chủ thiếu chứng chỉ trung gian. | Chưa sửa (phía máy chủ); ghi nhận. |
| 9 | `FlutterError @ /MangaLibrary: Null check…` (build_id `41b32…` = bản cũ) | Không có symbol của build đó để giải mã stack. | Không tái hiện trên 0.4.3; theo dõi tiếp. |

#### B. Sheet "YomiHub Update"

| Mục | Kết quả 0.4.3 |
|---|---|
| Đọc log, sửa lỗi, tối ưu | Mục A. |
| Hợp nhất lag/treo | `chapter_origins.dart`: `isMangaMerged` dùng tập id được cache (trước: quét toàn bộ nguồn gốc chương cho **mỗi** bìa truyện). `builtin_extensions.dart`: `YomiMerge.groups` cache theo bản ghi (trước: sao chép sâu mỗi request HTTP/mỗi dòng Duyệt). `merge_screen.dart`: đếm mục thư viện 1 lần/lần tải (trước: quét cả thư viện cho mỗi dòng ở mỗi lần bấm ô chọn). |
| Giao diện sau hợp nhất (sheet Merge – ảnh) | Bộ chọn nguồn "Chọn nguồn" nằm dưới Đề xuất/Liên quan (có từ 0.3.x) nay dựng 1 lần/danh sách, không tải liên kết Isar từng chương (`manga_detail_view.dart`, `ChapterOrigins.sourceKey(…, owner)`); huy hiệu "Hợp nhất" giữ từ 0.4.2. |
| Tự chọn tiện ích để hợp nhất | **Mới:** nút "Tự chọn tiện ích" (FAB + nút trên thanh tiêu đề) trong Thêm › Hợp nhất tiện ích: chọn ≥ 2 tiện ích cùng loại bất kỳ (khác tên miền), chọn tiện ích chính; nhóm hiển thị "Tự chọn: A + B", tách nhóm được. Nhóm tự chọn không chia sẻ đổi tên miền (`url_override.dart`). (Màn hình chọn tiện ích viết ở 0.4.x trong `yomihub/merge/extension_merge_screen.dart` chưa từng được gắn vào router.) |
| Treo/lag/văng | Mục A1–A3, B2. |
| Kotatsu | `kotatsu.js` đã kiểm tra HTML/Cloudflare; JSON.parse toàn cục báo rõ lỗi. Lỗi chứng chỉ ở A8. |
| Ghi Nhật ký khi không tải được nội dung | Đã có từ 0.4.2 (tên tiện ích, repo, engine); 0.4.3 thêm log thư viện theo truyện/nguồn, log "Video không thoát được" (`anime_player_view.dart`, giải phóng trình phát lỗi/quá 8 s). |
| Không lưu vị trí video | Trình phát web (`web_player.dart`, các nguồn Film & Movie phát qua trang): đọc vị trí từ CSDL (trước: bản sao cũ của tập → luôn phát từ 0), lưu vị trí cuối khi thoát (trước: mất 4–10 s cuối), chỉ đánh dấu "đã xem" khi ≥ 85 % (trước: sau 3 phút bất kỳ), cập nhật Lịch sử. Trình phát mpv: đã có bảo vệ ở 0.3.3–0.4.1. |
| Kiểm tra cập nhật (Giới thiệu) | A5. |
| Website Extension | Đối chiếu 30 tiện ích/URL/ngôn ngữ/NSFW với sheet: khớp; AVSub: sheet ghi `animevietsub.nl` nhưng tên miền này đã chết (curl 000, kiểm 28/10/2026) → giữ `animevietsub.sale` làm mặc định, tự chuyển `.nl`→`.sale` cho người dùng cũ (v0.4.3). |
| Dự án GitHub đã sử dụng | So khớp 469 URL của sheet với danh sách trong ứng dụng: thiếu 1 (`github.com/HypertextAssassin0273`) → đã thêm. |
| Lịch sử | Mục Lịch sử riêng chỉ còn trong "Thêm" (bỏ khỏi thanh điều hướng, `main_screen.dart`); lịch sử từng mục Truyện/Phim/Tiểu thuyết đồng bộ thời gian thực như 0.4.2. |

#### C. Feature Check — thay đổi mới ở 0.4.3 (các mục còn lại giữ như 0.4.2, xem nhật ký trước)

- FC 25 (loading): logo trong màn hình 5 giây nay là **chính logo ứng dụng** biến từ vuông bo góc thành tròn (một vùng cắt có bán kính tăng dần), giải mã trước khung hình đầu (0.4.2 hiện đĩa xanh trống ~1 s) — `yomi_splash.dart`.
- FC 29/32 (dịch): quét 1.197 chuỗi `tr()` → 8 chuỗi chưa có bản dịch, đã dịch sang 18 ngôn ngữ (`assets/yomihub_i18n/*.json`).
- FC 33: mục B "Dự án GitHub".
- FC 34: log Wi‑Fi Windows 7/8 (`wifi_settings_screen.dart`: `ms-settings:` không có trên Win 7/8 → mở `ncpa.cpl`), "Video không thoát được", cập nhật thư viện.
- FC 30 (dung lượng/tốc độ): xem bảng kích thước ở mục F; tốc độ: A1–A3, B2.

#### D. Android 6.0 (API 23) — kết quả thật

- Phát hiện: các bản 0.4.1/0.4.2 ghi "tương thích Android 6.0+" nhưng `build.gradle` thực tế dùng `flutter.minSdkVersion` = **24** (Flutter tool tự đổi giá trị 23 về 24); APK 0.4.2/0.4.3 cài lên Android 6.0 báo `INSTALL_FAILED_OLDER_SDK`.
- Đã thử đưa xuống API 23 (lưu toàn bộ ở `audit-0.4.3/compat23`):
  1. `minSdkVersion` qua biến `yhMinSdk` (tránh bộ migrate của Flutter) + `tools:overrideLibrary` cho 10 thư viện khai báo minSdk 24 + chặn Tor/WireGuard/WARP dưới API 24 (`YomiVpn.kt`, `YomiTunnels.kt`) → build được.
  2. `libflutter.so` (engine Flutter 3.47) cần 4 hàm libc của API 24 (`__fwrite_chk`, `__write_chk`, `getifaddrs`, `freeifaddrs`) → viết `libyhcompat.so` (NDK clang) và vá `DT_NEEDED` bằng patchelf → engine nạp được trên 6.0.
  3. Java embedding gọi API 24 không kiểm tra phiên bản (`Configuration.getLocales`, `Context.getDataDir`, `EditorInfo.hintLocales`, `setDrawingOrder`) → biên dịch lại 4 lớp có kiểm tra phiên bản → giao diện Flutter chạy trên 6.0.
  4. **Chặn cuối:** CSDL Isar (libmdbx) trên Android 6.0 trả `MDBX_INCOMPATIBLE (-30784)` khi mở CSDL → ứng dụng hiện "Không khởi động được YomiHub". Cần biên dịch lại thư viện gốc `isar_community` (libmdbx) cho kernel Android 6 — ngoài phạm vi bản cập nhật này.
- Quyết định phát hành: **giữ minSdk 24 (Android 7.0+)** để không phát hành APK cài được nhưng không mở được; các thay đổi thử nghiệm cho API 23 đã gỡ khỏi mã dựng (giữ nguyên trong `audit-0.4.3/compat23`, gồm script vá và mã nguồn). Bộ đệm engine Flutter/Gradle đã khôi phục bản gốc (đối chiếu SHA-256).

#### E. Windows 7 / x86 / ARM

- Flutter Windows chỉ hỗ trợ Windows 10+ x64 (ARM64 chỉ dựng được trên máy ARM64). Bản 0.4.3 phát hành Windows 10/11 x64, 3 định dạng như yêu cầu. Ghi chú "Windows 7 x86/ARM" ở các nhật ký 0.4.1–0.4.2 không đúng thực tế.

#### F. Trạng thái khi tạm dừng (28/10/2026 ~14:30, người dùng khởi động lại máy)

- Đã dựng: APK mobile 3 ABI (13:22), APK TV 3 ABI (bản 13:22–14:05), Windows `.zip`/`-full.zip`/`Setup.exe`/`.appxbundle` (14:05–14:23) trong `output/0.4.3`. Kiểm thử tự động 26/26 đạt (`b043_test.txt`).
- Sửa sau cùng (AVSub `.sale` + chuyển `.nl`→`.sale`) đã vào bản Windows 14:05 nhưng **chưa** vào APK mobile/TV → cần chạy lại: `jobs/pending/043_35_apk.ps1` (đang chạy dở khi dừng), sau đó `jobs/_hold/043_36_tv.ps1`, `jobs/_hold/043_37_pack.ps1` (chuyển vào `jobs/pending`).
- Đã tạo `jobs/STOP` và `jobs/STOP_FAST` để dừng 2 job runner; xoá 2 tệp này rồi chạy `3_run_jobs.bat`/`3b_run_fast_jobs.bat` để tiếp tục.
- Kiểm thử đã làm: Android 17 (emulator): loading logo tròn, Thêm (Lịch sử chỉ trong Thêm), Hợp nhất tiện ích + Tự chọn (hợp nhất AVSub + AnimeVN, tiện ích phụ được gộp trong Duyệt), Giới thiệu "Beta (0.4.3)", Kiểm tra cập nhật → "Không có bản cập nhật mới". Windows portable: thư viện, Thêm, Hợp nhất tiện ích tự chọn (hợp nhất rồi tách nhóm), Lịch sử 3 tab, Giới thiệu 0.4.3. Ảnh: `output/0.4.3/qa/`; video: `qa/m043_walk1.mp4` (Android, trên emulator), `qa/win_qa_portable*.mp4`.
- Sự cố Windows: sau ~8 phút cửa sổ Flutter ngừng vẽ; sau đó cả 0.4.2 lẫn 0.4.3 mở ra màn trắng dù tiến trình vẫn chạy/ghi log, không có lỗi TDR trong Event Log → nghi trình điều khiển đồ hoạ (Intel Iris Xe + GTX 1650). Cần kiểm tra lại sau khi khởi động lại máy.
- Lưu ý bộ đệm: script dọn ở bước thử Android 6 đã xoá phần lớn `D:\yh\gradle-home\caches\9.3.1\transforms` (bộ đệm, Gradle tự tạo lại — lần dựng đầu chậm hơn). Engine Flutter và jar trong bộ đệm Gradle đã khôi phục bản gốc (khớp SHA-256 bản sao lưu trong `audit-0.4.3/compat23`).
- Việc còn lại: dựng lại APK/TV, kiểm thử TV trên AVD `YomiHub_TV_API34` (đã tạo), kiểm thử Windows Setup/appxbundle sau khi khởi động lại, quay video, cập nhật trạng thái đầu tài liệu, changelog `output/0.4.3/YomiHub-0.4.3-changelog.md` (bản nháp: `audit-0.4.3/changelog043_draft.md`).

#### G. Tiếp tục sau khi khởi động lại (28/10/2026 14:40–16:40)

- Dựng lại: APK mobile 3 ABI (15:09; kiểm: `libflutter.so` gốc, không có `libyhcompat`, `avsub.js` dùng `animevietsub.sale`); APK TV 3 ABI (16:26, gồm 2 sửa TV bên dưới); đóng gói lại `Setup.exe`, `.appxbundle` (270,5 MB), `SHA256SUMS-0.4.3.txt` (16:30).
- Kiểm thử tự động sau sửa (16:39): `dart analyze` 17 tệp đã sửa — 0 lỗi (27 cảnh báo/info có sẵn từ trước, ví dụ `unnecessary_non_null_assertion` trong onboarding, `deprecated_member_use` Radio); `flutter test` yh_040–043: **26/26 đạt**.
- Sửa ghi chép mục B: AVSub — sheet ghi `.nl` nhưng tên miền chết (curl 000, 28/10/2026) → mặc định `animevietsub.sale`, tự chuyển `.nl`→`.sale`.
- Kiểm thử TV (AVD `YomiHub_TV_API34`, ảnh hệ thống x86 + dịch ARM `libndk_translation` → cài APK `armeabi-v7a`; APK `x86_64` báo `INSTALL_FAILED_NO_MATCHING_ABIS` vì ảnh TV chỉ có x86 32-bit):
  - Lần đầu mở: hệ thống mở trang "Allow access to manage all files" (quyền `MANAGE_EXTERNAL_STORAGE`, `storage_provider.dart`); bấm Back → ứng dụng tiếp tục bình thường.
  - **Lỗi 1 (đã sửa):** màn "Thêm nguồn" tự đặt tiêu điểm vào ô "URL kho" trên TV; phím D-pad Xuống không rời ô (kết nối IME giữ phím) → người dùng chỉ có remote bị kẹt. Sửa `lib/modules/onboarding/onboarding_screen.dart`: bỏ `autofocus` của ô nhập trên TV, nút "Để sau" nhận tiêu điểm ban đầu (Lên → ô nhập, OK → bàn phím); ẩn câu "Truyện tranh, Phim & Điện ảnh và Tiểu thuyết đều được hỗ trợ…" trên TV.
  - **Lỗi 2 (đã sửa):** màn hình chính TV còn chữ tiếng Anh cứng ("Your anime library is empty", "Add anime from Browse…", "Browse anime", "Continue", "Hidden categories", "New category", "Close/Cancel/Add", 2 thông báo lọc/ẩn). Sửa `lib/modules/library/tv_home/tv_anime_home_view.dart` dùng `tr()` tiếng Việt; thêm 8 khoá vào 18 tệp `assets/yomihub_i18n/*.json` (bản trước: `audit-0.4.3/before/i18n_tv`).
  - Xác nhận: thanh điều hướng TV chỉ có Phim & Điện ảnh, Play Books, Cập nhật, Duyệt, Thêm — **không có Comic/Novel**.
  - Ảnh: `output/0.4.3/qa/tv1_*`–`tv8_*` (bản trước sửa), `tv2x_*` (bản sau sửa); video `qa/tv043_walk1.mp4`, `qa/tv043_walk2.mp4`.
- `build_043.ps1`: bỏ cờ `--no-fatal-infos` (Dart 3.13 không nhận → analyze lỗi exit 64), thêm 2 tệp mới vào danh sách analyze.
- Windows: sau khi khởi động lại, bản portable 0.4.3 hiển thị bình thường; sau khi bật ghi màn hình ffmpeg gdigrab + phóng to cửa sổ thì ngừng vẽ; mở lại cả 0.4.3 lẫn 0.4.2 đều ra cửa sổ trắng dù tiến trình phản hồi (`Responding=True`) và vẫn ghi log. Lúc đó RAM trống chỉ ~0,9–1 GB/16 GB (Gradle 3,5 GB + VM phiên làm việc 4 GB + ứng dụng khác) → nghi thiếu bộ nhớ đồ hoạ dùng chung (Iris Xe) hoặc driver hybrid; chưa kết luận. Không dùng ffmpeg gdigrab khi kiểm thử Flutter Windows nữa.
- Máy người dùng mất kết nối với phiên làm việc ~16:20–16:50 (job runner vẫn chạy và hoàn tất các bước trên).
- Đã chạy sau cùng (17:00): kiểm thử lại bản TV mới trên `YomiHub_TV_API34` — lần mở đầu tiêu điểm ở "Để sau", OK → vào màn hình chính; màn hình chính tiếng Việt ("Thư viện Phim & Điện ảnh đang trống", "Duyệt phim"); D-pad Trái vào thanh điều hướng, mở Cập nhật được (ảnh `qa/tv20_*`–`tv34_*`, video `qa/tv043_walk2.mp4`). Mỗi lần mở, nếu chưa cấp quyền "Quản lý tất cả tệp", hệ thống lại hiện trang quyền (hành vi có từ Mangayomi gốc, `storage_provider.dart`) — ghi nhận, chưa đổi.
- Windows sau khi tắt giả lập và Gradle daemon (RAM trống ~4,8 GB): bản portable 0.4.3 hiển thị bình thường (ảnh `qa/w55_front.png`) → cửa sổ trắng trước đó trùng thời điểm máy thiếu RAM. Chưa cài thử lại `Setup.exe`/`.appxbundle` trong phiên này (đã dựng, ký số, có SHA-256).
- Dọn: `probe23-x86_64.apk` và các thư mục `qa/libs23*`, `qa/final_libchk` chuyển sang `audit-0.4.3/compat23/` (không phát hành); bỏ dòng probe khỏi `SHA256SUMS-0.4.3.txt`. Changelog: `output/0.4.3/YomiHub-0.4.3-changelog.md`.

#### H. Kiểm thử tiếp theo yêu cầu "tiếp đi" (28/10/2026 17:20–21:00) — phát hiện lỗi hồi quy của chính 0.4.3

- **Lỗi nghiêm trọng (do sửa đổi 0.4.3 gây ra, đã sửa):** trên giả lập điện thoại, mọi nguồn (AVSub, AnimeVN) đứng mãi ở khung tải (> 3 giờ), biểu tượng tiện ích không hiện; cài lại 0.4.2 trên cùng giả lập → AnimeVN tải danh sách ngay (ảnh `qa/c42_06.png`, `qa/c42_07.png`). Nguyên nhân: `lib/services/http/m_client.dart` (mục A3) dùng `_yomiResolve(host).whenComplete(() => _yomiDnsInflight.remove(host))` — hàm mũi tên trả về chính Future đang được gán, `whenComplete` chờ Future đó → Future tự chờ chính nó, mọi lần phân giải DNS treo vĩnh viễn. Cũng là nguyên nhân các dòng `[Kho tiện ích] … TimeoutException after 0:00:25` trong log Windows 0.4.3 (14:38, 14:44). Sửa: callback dạng khối `{ _yomiDnsInflight.remove(host); }`. Test cũ chỉ thử địa chỉ IP (đi đường tắt) nên không bắt được; thêm test `DNS helper completes a real lookup` (2 truy vấn đồng thời + truy vấn lại) trong `test/yh_043_test.dart`.
- **AVSub — sửa lại kết luận sai ở mục B/G:** kiểm tra trực tiếp từ Windows (DNS 8.8.8.8 + `curl --resolve`): `animevietsub.nl` và `animevietsub.sale` đều trả `301 → https://animevietsub.news/`; `.news` trả 403 Cloudflare với curl (cần WebView – tiện ích đã có bước vượt Cloudflare). Kết luận "`.nl` đã chết" trước đó là sai: phép thử chạy từ máy ảo của phiên làm việc (mạng bị giới hạn theo danh sách cho phép) nên trả `000`. Đã đổi: `builtin_extensions.dart` baseUrl/icon `https://animevietsub.news`, tự chuyển nguồn đang dùng `.nl` hoặc `.sale` sang `.news`; `avsub.js` tên miền mặc định `.news`; `url_override.dart` thêm `.news` làm tên miền dự phòng đầu tiên cho `.nl`/`.sale`/`.news`. Ghi chú: DNS nhà mạng của máy người dùng không phân giải các tên miền này (Windows `Resolve-DnsName` thất bại) → ứng dụng dùng DNS-over-HTTPS dự phòng.
- **Setup.exe hiển thị tiếng Việt lỗi phông** (tiêu đề "YomiHub 0.4.3 Setup - CÃ i Äáº·t…"): `make_installer_exe.ps1` là UTF-8 không BOM nên Windows PowerShell 5.1 đọc như ANSI trước khi ghi mã C#. Sửa: thêm BOM UTF-8 (bản cũ: `audit-0.4.3/before/make_installer_exe.ps1.nobom`). Còn 5 script QA cũ (không dùng khi dựng 0.4.3) có ký tự tiếng Việt mà không BOM: `gen_checksums_036.ps1`, `record_walkthrough_042.ps1`, `run_042_perfect_screenshots.ps1`, `test_all_features_deep.ps1`, `test_and_record_042.ps1`.
- `.appxbundle`: chữ ký số hợp lệ về cấu trúc nhưng chứng chỉ `CN=YomiHub` (tự tạo, thumbprint 4C62D3C5…2A49) chưa có trong kho tin cậy của máy → cài cần chạy `Install-YomiHub.bat` (thêm chứng chỉ vào Root/TrustedPeople) — thay đổi cài đặt bảo mật nên không tự chạy trong phiên; người dùng tự thực hiện.
- Giả lập điện thoại: sau khi cài đè, Android mở trang "Quyền truy cập mọi tệp" (màn tối) mỗi lần mở cho tới khi cấp quyền (đã cấp bằng `appops` để kiểm thử).
- Dựng lại sau sửa: test → APK → TV → Windows → pack (kết quả bên dưới).
- Kết quả dựng lại (28/10/2026): test 20:52 — **27/27 đạt** (thêm test DNS mới); Windows 21:03 (`.zip` 138,2 MB, `-full.zip` 266,1 MB); APK 21:10 (3 ABI); TV 21:39 (3 ABI); pack 21:44 (`Setup.exe`, `.appxbundle` 270,5 MB, `SHA256SUMS-0.4.3.txt`).
- Kiểm thử sau sửa:
  - Windows portable mới: log khởi động 21:04 — các kho tiện ích tải trong ~12 s, không còn `TimeoutException 25 s` (chỉ còn `kohiden.xyz` lỗi phía máy chủ như ở 0.4.2).
  - Giả lập Android 17, APK x86_64 mới: Duyệt hiện đủ biểu tượng tiện ích; AnimeVN → "Mới nhất" tải danh sách (`qa/n05_browse_film.png`, `qa/n06_animevn.png`); mở "Tiên Nghịch" (134 tập, `qa/n07_detail.png`); Tập 134 báo đúng lỗi của trang "Tập này chưa có link phát trên AnimeVN" (`qa/n09_play60.png`); **Tập 131 phát được** (01:41/24:20, `qa/n12_ctrl.png`); Back khi đang phát → thu nhỏ PiP và tiếp tục phát (`qa/n13_detail_after.png`).
  - Chưa kết luận được bài kiểm "nhớ vị trí xem": giả lập (qemu) bị sập 2 lần (Windows Event Log: `qemu-system-x86_64` lỗi `c0000005`) và lớp "Viewing full screen" của Android chặn thao tác chạm tự động; lần thử cuối trình phát đứng ở 00:00/00:00.
  - `Setup.exe` mới: tiêu đề "YomiHub 0.4.3 Setup - Cài Đặt YomiHub", các nhãn tiếng Việt hiển thị đúng (`qa/w100_setup.png`); cài vào `D:\yh\qa_setup_043` (bỏ lối tắt Desktop/Start Menu): 192 tệp, `YomiHub.exe` 0.4.3+35, có `Uninstall.cmd`, ứng dụng tự mở sau cài và hiển thị thư viện (`qa/w101_installed.png`).
  - Ghi nhận: ảnh bìa trong thư viện Windows không hiện ở cả 0.4.2 và 0.4.3 (log `Image/network load failed … hentaicb.help` có từ 0.4.2) — trình tải ảnh không dùng DNS-over-HTTPS trong khi DNS nhà mạng chặn các tên miền này; chưa sửa trong 0.4.3.

#### I. Ảnh bìa thư viện trên Windows (28/10/2026 22:00–22:40, theo yêu cầu "Sửa phần ảnh bìa thư viện trên Windows")

- Kiểm tra lại: tab "00 - Tất Cả" hiện ảnh bìa bình thường; các thẻ trắng nằm ở tab "Lịch Sử Đọc" và một số mục có máy chủ ảnh hỏng. Từ Windows (DNS 8.8.8.8 + `curl --resolve`): `i.hinhgg.com` trả **521** (máy chủ gốc Cloudflare ngừng), `hentaicb.help/wp-content/uploads/…` đóng kết nối TLS ngay (`schannel: server closed abruptly`) dù trang chủ trả 200 → ảnh bị máy chủ chặn/ngừng, không phải do DNS nhà mạng hay ứng dụng. Sửa nhận định ở mục H ("trình tải ảnh không dùng DoH") — trình tải ảnh đã có thử lại qua HTTP khác và DNS-over-HTTPS (`custom_extended_image_provider.dart`, `_getResponse`).
- **Lỗi 1 (đã sửa):** tab "Lịch Sử Đọc/Xem" ở lưới thu gọn không hiện tên truyện — `CoverViewWidget` chỉ vẽ `bottomTextWidget` ở lưới thoải mái, còn `history_screen.dart` chỉ truyền tên qua tham số đó. Sửa `lib/modules/history/history_screen.dart`: ở lưới thu gọn thêm `BottomTextWidget` vào trong thẻ, chuyển nhãn tập/giờ lên trên để không đè tên.
- **Lỗi 2 (đã sửa):** ảnh bìa không tải được (máy chủ hỏng) để lại thẻ trống. Sửa `lib/modules/widgets/cover_view_widget.dart`: nền giữ chỗ (biểu tượng `image_not_supported_outlined` trên màu `surfaceContainerHighest`) nằm dưới lớp Material trong suốt; ảnh tải được vẽ đè lên → không ảnh hưởng ảnh bình thường (kiểm tra tab "00 - Tất Cả").
- Kiểm thử: `dart analyze` (19 tệp) 0 lỗi; `flutter test` 27/27 đạt; Windows portable dựng 22:30 — ảnh `qa/w114_history_tab.png` (tên + nền giữ chỗ hiện đủ), tab "00 - Tất Cả" ảnh bìa bình thường.
- Chưa làm: tải ảnh từ máy chủ chặn kết nối không phải trình duyệt (`hentaicb.help/wp-content`) — cần tải qua WebView; ghi nhận cho bản sau.
- Bản cũ trước sửa: `audit-0.4.3/before/covers/`.
- Dựng lại toàn bộ sau sửa: Windows 22:30, APK 22:49, TV 23:22, pack 23:38. Lần pack này `Setup.exe` mới không chuyển được vào `output/0.4.3` (`Move-Item` IOException vì cửa sổ `Setup.exe` cũ còn mở từ lần cài thử) → đã đóng tiến trình, chuyển tệp (23:23:44, 145.015.808 byte) và tính lại `SHA256SUMS-0.4.3.txt` (23:40, 10 tệp).

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
- Dựng cuối 29/10/2026: TV 09:13, pack 09:17 (`Setup.exe` 09:13, `.appxbundle` 270,5 MB, `SHA256SUMS-0.4.3.txt` 10 tệp); chép sang `..\output\0.4.3` và đối chiếu SHA-256.
