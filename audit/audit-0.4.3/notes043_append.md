
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
| Website Extension | Đối chiếu 30 tiện ích/URL/ngôn ngữ/NSFW với sheet: khớp; AVSub dùng `animevietsub.nl` như sheet (v0.4.3, dự phòng `.sale`). |
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
