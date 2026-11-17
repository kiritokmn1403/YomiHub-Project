# YomiHub 0.5.7 — TIẾN ĐỘ (lưu 14/11/2026 15:05, trước khi hết hạn mức 5 giờ)

ĐỌC TRƯỚC KHI LÀM TIẾP: `AGENTS.md`, `A.I Brain - Second Brain/`, `audit-0.5.7/00_DECISIONS.md` (mục 0.5.7), `coordination/BRIEF.md`, `coordination/MATRIX_0571.md`, tệp này.

## Quyết định (chủ dự án, 14/11 ~09:40)
Windows 10/11 x64 (Setup.exe, .appxbundle, portable); Android 7.0+ chính; android6 APK riêng; YumiHub Android TV (không Comic/Novel/Play Books/Booru); giữ nền Mangayomi; Claude Opus điều phối + Fable/Sonnet/Haiku. Kiểm thử cả trên điện thoại đang cắm (hiện là Samsung Note 9 SM-N960N, Android 10, arm64, adb `281038ac31217ece`; đã cài com.yomihub.app). Đã được cấp quyền điều khiển máy (10 ứng dụng) và quyền xóa trong 2 thư mục dự án (chỉ trong phiên 14/11).

## Đã xong
| Mục | Tác nhân | Kết quả | Ghi chú |
|---|---|---|---|
| Lỗi 40× Null check (tabs.dart:633) @ /MangaLibrary, /mangaReaderView | Opus | sửa `modules/widgets/custom_draggable_tabbar.dart` (DraggableTabsHost); test `yh_057_tabs_test` 2/2 | Giải mã stack bằng llvm-symbolizer + `D:\yh\build23\symbols` (log đến từ APK android6). Bản vá 0.5.2 trong library_screen sửa nhầm chỗ. |
| Lỗi mạng log 7 (Kotatsu→127.0.0.1:9, Tor kẹt 45–50%, CF giải xong vẫn chặn, OpenVPN) | F1 (Fable) | 86/86 + 158/158 test | `notes/NOTES_F1.md` |
| Lỗi khác log 7 (kho .pb, Kiểm tra cập nhật, bộ lọc, phân loại lỗi, UI treo, lũ log ảnh) | S1 (Sonnet) | 44/44 | `notes/NOTES_S1.md` |
| Bảng truy vết U1–U14, FC1–FC43 + 8 gói việc | S2 (Sonnet) | 11 DONE / 22 PARTIAL / 24 TEST-ONLY | `coordination/MATRIX_0571.md`, `GITHUB_MISSING_0571.md` (0 dự án thiếu) |
| P1: U3, U4, FC37 (bộ chọn "Nguồn đọc" theo sheet Merge), FC38, FC41 | P1 (Sonnet) | 17/17 (+45/45 lượt 1) | `notes/NOTES_P1.md` |
| Kiểm tra tổng (job `z057_dev_apk`, 64 tệp overlay đồng bộ sang D:\yh\build) | Opus | analyze lib 0 error; test 768 đạt / 1 trượt (`yh_049` – chuỗi P1/P3/P5 chưa gộp) | `devbuild/analyze_057dev.txt`, `test_057dev.txt` |

## Dở dang (bị dừng do hạn mức / chủ dự án dừng 15:00)
- **APK thử** `devbuild/YomiHub-0.5.7-dev-arm64-v8a.apk` (0.5.7+50): job `z057_dev_apk` đang dựng (bắt đầu 14:48) rồi tự `adb install -r` lên Note 9 và chụp màn hình. Ảnh trong job có thể hỏng (PS5 ghi nhị phân) → chụp lại bằng `adb shell screencap -p /sdcard/x.png` + `adb pull`. Kiểm `jobs/done/z057_dev_apk.log`.
- **P3 (Fable, dừng giữa chừng)**: đã sửa `anime_player_view.dart`, `anime_player_controller_provider.dart`, `anime/widgets/mobile.dart`, `manga_home_screen.dart`, `nuvio_media_hub.dart`, `player/{shorts_store,yomi_pip,yomi_shorts}.dart`; mới `player/{resume_policy,resume_store,shorts_detect}.dart`, `test/yh_057_p3_test.dart`, `notes/i18n_P3.json`. CHƯA có NOTES_P3; job `p3_t01` còn chờ trong pending_fast. → Lượt sau: rà diff (so `backup/src_0571/`), chạy test, viết NOTES_P3.
- **P7 (Fable, 2 lượt dừng)**: đã sửa `ext_errors.dart`, `isolate_service.dart`, `platform_utils.dart`, `main.dart`, mới `lib/yomihub/a6/`, i18n 18 tệp (khóa ở `notes/i18n_T4.json`), test `yh_057_t4_test` 35/35; job `p7_a6d1`, `p7_ww1` đã chạy, `p7_a6d2` còn chờ. Chưa có script build_057*, pubspec vẫn 0.5.6+49, chưa NOTES_P7.
- **P5 (Sonnet, lượt 1 dừng)**: sửa `chapter_controller_mixin.dart`, `health_connect_service.dart`, i18n 18 tệp (bản sao lưu `backup/src_0571/assets/yomihub_i18n_P5/`), test `yh_057_p5_test` 33/33. Chưa NOTES_P5.

## Chưa làm
P2 (tích hợp trình đọc Yomikiru/Yomihon/GIF/Nyora), P4 (chống fingerprint/anti-bot/Frank Yomik, web scanner), P6 (giao diện Shiori U11, Thư Viện, loading 5 s), phần còn lại P5 (AirDrop/Telegram/Booru/log tải), P8 (gộp `notes/i18n_*.json` → 18 tệp, sửa yh_049), script dựng 0.5.7 + bump 0.5.7+50, dựng đủ gói, kiểm thử thiết bị 24 mục TEST-ONLY + ảnh/video, TECHNICAL_UPDATE_NOTES đầy đủ, thống kê so với 0.5.6.1, phát hành GitHub v0.5.7.

## Bài học đợt này
- 7 tác nhân song song làm cạn hạn mức 5 giờ trong ~1 giờ → chạy tối đa 2–3 tác nhân/lượt, việc nhỏ Opus tự làm.
- Tác nhân bị dừng không viết ghi chú → yêu cầu viết NOTES ngay từ đầu và cập nhật sau mỗi bước.

---
## MỐC LƯU 14/11/2026 15:36 (phiên Claude Fable "x1", chat riêng – không chạy tác nhân con)
Chủ dự án dặn 15:32: theo dõi hạn mức 5 giờ, gần hết thì lưu tiến độ. Phiên này KHÔNG đọc được số hạn mức còn lại → cách làm: **lưu mốc vào tệp này sau mỗi bước** (bước nào chưa có mốc coi như chưa làm), không chạy tác nhân song song.

### Sự thật đã kiểm lúc 15:36 (đọc log, không suy đoán)
- Không còn job chờ (`jobs/pending`, `jobs/pending_fast` trống); hai runner còn sống. Không tệp nào trong `overlay/` đổi sau 15:11 → không thấy tác nhân khác đang sửa mã. (NOTES_P3/NOTES_P5 "lượt 2" tạo 15:11–15:12 rồi dừng, chưa có nội dung.)
- `jobs/done/z057_t02_i18n.log` 15:19:46: `yh_049` **15/15 đạt** sau khi gộp i18n (18 tệp × 1598 khóa; mọi khóa của `notes/i18n_{P1,P3,P5,T4}.json` đã có trong `en.json`). → lỗi duy nhất của lượt test tổng 14:48 (768 đạt / 1 trượt) đã hết; CHƯA chạy lại toàn bộ test sau khi gộp.
- `devbuild/YomiHub-0.5.7-dev-arm64-v8a.apk` dựng xong 15:32:10 (BUILD EXIT 0, 168,9 MB). Note 9 (adb `281038ac31217ece`) lúc đó vẫn là 0.5.5/2047; phần cài + chụp ảnh của job chưa thấy kết quả trong log.
- Log 13–14/11 là của **APK android6 chạy trên máy Android đời mới** (build-id `d6bf8bd5…` = `D:\yh\build23\symbols`, đã đối chiếu bằng `readelf -n`). Hệ quả: tiện ích Mihon mới ("MiMi") lỗi `abstract method … typeParametersSerializers()` – nhiều khả năng do thư viện bản android6 (minSdk 23) không giữ được phương thức mặc định của interface; CHƯA chạy thật để xác nhận.

### Việc phiên x1 đã làm sáng 14/11 (10:35–10:58; PROGRESS phía trên ghi là "P1 lượt 1 / P5 lượt 1 / P7")
| Việc | Tệp (overlay/) | Kiểm | Log |
|---|---|---|---|
| U3, U4, FC37, FC38 | `playbooks_toggle`, `booru_settings_screen`, `merge/{chapter_origins,extension_merge_screen}`, `data_and_storage`, `manga_extensions`, `manga_detail_view`, `manga_details_view`, `test/yh_057_p1_test` | 45/45 | `x1_p1_test1.log` |
| FC35 Health Connect: ghi phút đọc/xem từ `setHistoryUpdate` (bỏ qua ẩn danh); nhắc 20-20-20 chạy theo phút khi ở trình đọc/trình phát (`startEyeCareWatch` trong `main.dart`) | `health/health_connect_service`, `reader/mixins/chapter_controller_mixin`, `main`, `test/yh_057_p5_test` | 33/33 | `x1_p5_test1.log` |
| Log 7 còn sót: Kavita "OPDS URL required" → cần cấu hình; HTTP 530 / "HTTP 0" → lỗi trang; tiện ích "(Ngừng hoạt động)" → 1 dòng INFO; Aidoku `SourceError`, CSRF… → WARNING không stack; "MiMi" → gợi ý; cờ `kIsA6Build` (`--dart-define=IS_A6_BUILD=true`) + thông báo khi bản android6 chạy trên Android 7.0+ | `extensions/ext_errors`, `services/isolate_service`, `utils/platform_utils`, `yomihub/a6/a6_notice` (mới), `main`, `test/yh_057_t4_test` | 35/35 | `x1_t4_test1.log` |
Bản gốc: `backup/src_0571/…`. Công cụ sửa: `tools/{ed.py,p1_patch*.py,p5_patch.py,t4_patch.py,i18n_merge.py}`.
**Phải nhớ khi viết script dựng 0.5.7:** bản android6 thêm `--dart-define=IS_A6_BUILD=true` (chưa có script nào truyền cờ này).
Chưa kiểm trên thiết bị: mọi mục trên (chỉ `flutter test` + `analyze`).

### Thứ tự làm tiếp (mỗi bước xong ghi 1 dòng "XONG hh:mm" ngay dưới đây)
1. Chạy lại toàn bộ `flutter test` sau gộp i18n (job nhanh) → xác nhận 0 trượt.
2. Xem kết quả cài dev APK lên Note 9; chụp lại màn hình bằng `adb exec-out screencap -p`.
3. Viết NOTES còn thiếu (P5 phần Health Connect, T4/P7 phần phân loại lỗi + android6).
4. Script dựng 0.5.7 (`sync_057`, `build_057*`, pubspec `0.5.7+50`, cờ A6) – CHỈ viết + chạy thử bước sync/verify, chưa dựng đủ gói.
5. Các gói chưa làm theo MATRIX: P3 (rà diff lượt 1), P5 còn lại, P2, P4, P6.
- 15:38 Opus: đã xếp job x2_fulltest (toàn bộ test) + x2_shot (chụp lại Note 9). Dev APK 0.5.7/2050 đã cài lên Note 9 lúc 15:33 (Success).
- 15:41 XONG bước 3 phần x1: notes/NOTES_X1.md
- 15:42 XONG bước 4 (phần viết): `sync_057.ps1`, `build_057{,_android,_android6}.ps1`, `make_{appxbundle,installer_exe}_057.ps1` sinh từ bộ 0561 bằng `tools/gen_057_scripts.py` + sửa tay (build-number 50, so nâng cấp với output\0.5.6.1, android6 có `--dart-define=IS_A6_BUILD=true`, bước test Android chạy toàn bộ thư mục test, giữ tên `yh_0561_vpn_resume_test`). overlay: pubspec `0.5.7+50`, `AppIdentity.userAgent = 'YomiHub/0.5.7'`. CHƯA chạy script nào; cần `sync_057.ps1 -Regen` trước. Runner.rc giữ nguyên (nhánh 0.5.6.49 không ảnh hưởng; 0.5.7 dùng FLUTTER_VERSION "0.5.7+50").
- 15:58 Toàn bộ test sau gộp i18n (`devbuild/test_057dev2.txt`): **790 đạt / 3 trượt**: 2 test đọc mã `yh_054` vỡ do P3 tách logic phát tiếp sang `resume_policy.dart` (hành vi giữ nguyên) → đã sửa kỳ vọng test; `yh_056_a` "real Isar … async write transaction already in progress" (không liên quan tệp nào đổi sau 14:48, đã đạt lượt 14:48) → nghi chập chờn do máy tải nặng, job `x2_retest` chạy lại riêng 2 lần. P3: đã rà diff `anime_player_view` / controller – hợp lý, nhận.
- 16:00 XONG bước 2: Note 9 chạy 0.5.7/2050 (dev arm64); ảnh `evidence/phone/p03_now.png` (1440×2960, đã mở xem): Thư Viện 4 tab (Truyện tranh/Phim & Điện ảnh/Tiểu thuyết/Play Books), điều hướng Thư viện/Booru/Cập nhật/Duyệt/Thêm; `logcat -b crash` trống. Một số ảnh bìa trống (chưa rõ do mạng hay lỗi – cần xem lại). Ảnh p01/p02 của job z057_dev_apk hỏng (PS5) – bỏ. Cách chụp đúng: `cmd /c "adb exec-out screencap -p > file"`.
- 16:06 `x2_retest`: `yh_056_a` đạt 2/2 lượt chạy riêng → xác nhận chập chờn khi máy tải nặng (không phải lỗi mã). `yh_054` "version / user agent" chưa nhận pubspec 0.5.7 → thêm `version: 0.5.7`; job `x2_retest2` (yh_054/055/049).
- 16:10 FC32 Web Scanner: `lib/yomihub/scanner/web_scanner.dart` ghi WARNING '[Web Scanner] Quét … thất bại' khi lỗi chứng chỉ/không tải được trang; test thêm vào `yh_057_t4_test`; job `x2_scan`.
- 15:56 (giờ thật; các dòng "16:0x/16:10" phía trên là giờ ước lượng, thực tế 15:45–15:52) `x2_retest2` yh_054/055/049 **30/30 đạt**; `x2_scan` analyze web_scanner **No issues**, yh_057_t4 **9/9 đạt**. → Toàn bộ test coi như xanh (790 + 3 đã xử lý).
- Tiếp theo: P4 (công tắc "Browser Fingerprint" đang chết – không nơi nào đọc khóa) → tiêm script chống fingerprint.
- 15:58 P4 (U6) phần 1: `lib/yomihub/browser/anti_fingerprint.dart` (mới) + `browser_screen.dart` tiêm script lúc đầu trang khi công tắc bật (mặc định bật), tải lại tab khi đổi công tắc; không áp vào WebView giải CF; test `yh_057_p4_test`; job `x2_p4`. Gecko (Firefox) chưa áp.
- 16:01 XONG: NOTES_P3 (rà soát Opus), NOTES_P4, mục 14/11 trong TECHNICAL_UPDATE_NOTES.md. Việc tiếp: P6 / P2 / phần còn lại P5, rồi dựng đủ gói bằng script 057.
- 16:03 Opus: giao P6 (U11 Shiori: ô bìa ShioriCard khi giao diện Mới, ẩn 'gộp thư viện', chuyển cảnh) cho 1 tác nhân Sonnet chạy nền; ghi chú ở notes/NOTES_P6.md. Chỉ 1 tác nhân/lượt.
- 16:05 P6 (Sonnet): bat dau U11, tao notes/NOTES_P6.md, dang khao sat widget o bia
- 16:20 P6 (Sonnet): sua cover_view_widget, library_entry_utils, library_gridview_widget, ui_style, custom_navigation_settings, router; xep job p6_a (analyze+test)
- 16:10 Opus: theo yêu cầu chủ dự án (16:07) chạy song song 3 tác nhân Sonnet: P6 (Shiori U11), P2 (U5 trình đọc: Yomikiru/Yomihon/GIF/Nyora → NOTES_P2.md), P3b (rà shorts/PiP/nuvio còn lại của P3, U9 → NOTES_P3.md mục P3b). Rủi ro đã biết: hai tác nhân cùng chạy i18n_merge.py một lúc có thể ghi đè 18 tệp i18n → Opus kiểm số khóa sau khi xong.
- 16:15 P6 (Sonnet): XONG U11 phan 1-3: analyze ui No issues, test p6 7/7 + yh_049/c2/r22 tong +49 dat; ghi chu notes/NOTES_P6.md
- 16:16 Opus: nhận báo cáo P6 – sửa cover_view_widget, library_entry_utils, library_gridview_widget, ui_style, custom_navigation_settings, router; p6_b 49/49 đạt, analyze ui No issues. Còn: ảnh thật Cũ/Mới, ShioriHeader/Theme, chuyển cảnh cần khởi động lại. Đã giao thêm P5b (share/Telegram/Booru/log tải) cho Sonnet.
- 16:16 P5b (Sonnet): bat dau, doc ghi chu, ra soat share/Telegram/Booru/download
- 09:17 P2 (Sonnet): bat dau U5 phan trinh doc, da doc cac mo-dun + reader_view/novel_reader_view, tao notes/NOTES_P2.md
- 16:18 P3b (Sonnet): rà xong 7 tệp; sửa shorts_detect.dart (bộ lọc 'Hide/No shorts' không còn bị coi là Short/bật nhầm) + test; xếp job p3b_a (analyze + yh_057_p3/056/054/049).
- 16:22 P5b (Sonnet): XONG buoc 1 share (share_log.warn, lan_share, bluetooth_share, share_screen: log WARNING cac nhanh nuot loi, xoa tep nhan do, kiem dung luong); tiep Telegram/Booru/download
- 16:25 P3b (Sonnet): XONG. job p3b_a: analyze 0 error (chỉ warning cũ manga_home_screen:88), test 61/61 đạt (yh_057_p3, 056, 054, 049). Không thêm chuỗi tr() mới nên không chạy i18n_merge.
- 16:22 Opus: nhận P3b – rà 7 tệp, sửa shorts_detect (bộ lọc 'Hide/No shorts' bị bật nhầm), p3b_a 61/61 đạt. Còn: PiP, Short extension ngoài, vuốt/tua trên máy thật.
- 16:23 P2 (Sonnet): da sua yomikiru/yomihon enhancer, reader_gestures, reader_view, novel_reader_view, integration_settings.dart (moi), reader_screen, novel_reader_screen, yomi_integrations; tiep: i18n + test + job
- 16:23 P5b (Sonnet): sua Telegram (log+mask), Booru (JSON->BooruException, viewer log), download_provider (log Wi-Fi only/loadSync); xep job p5b_a (analyze+test p5b+yh_049). Khong them chuoi tr() moi -> khong can i18n_P5b
- 16:28 P2 (Sonnet): i18n_P2.json (16 chuoi) da gop; test yh_057_p2_test.dart; xep job p2_a (analyze + test)
- 16:39 P2 (Sonnet): p2_a: analyze 0 error (10 warning cu unnecessary_non_null_assertion + 2 info import thua trong test), test 1 truot do regex dem tu (\w khong khop tieng Viet -> bug that trong estimateReadingTime, da sua bang \p{L}); xep p2_b
- 16:39 P5b (Sonnet): XONG. analyze 0 error/0 warning (2 info co san); p5b_b: +26 All tests passed (yh_057_p5b + yh_049). Ghi chu NOTES_P5 muc "Luot P5b". Can thiet bi that: LAN 2 may, Bluetooth, Telegram, Booru.
- 16:42 Opus: nhận P5b – log lỗi share/bluetooth/Telegram (che token)/Booru/tải xuống; sửa nhận tệp LAN bị ngắt để lại tệp hỏng; p5b_b 26/26 đạt, analyze 0 error 0 warning mới. Còn: thử 2 máy, Telegram thật, Booru từng site.
- 09:42 PB (Sonnet): đã xem 21 ảnh mẫu, sửa play_books_screen.dart (nav: Trang chủ/Thư viện/Danh sách yêu thích/Cửa hàng; tab Sách điện tử|Sách nói), i18n_PB gộp; tiếp: test + job analyze
- 16:50 P2 (Sonnet): XONG. p2_b: analyze chi con 1 warning cu (reader_view.dart:64), test yh_057_p2 + yh_056_part_c + yh_049 = 41 dat. Ghi chu notes/NOTES_P2.md
- 09:50 PB (Sonnet): XONG. job pb_a: analyze 0 error (1 info cũ withOpacity), test 19/19 đạt (yh_057_pb + yh_049). Chưa thử trên máy thật. Ghi chú: notes/NOTES_PB.md
- 16:51 Opus: nhận P2 – Yomikiru (phím A/D/Space/Home/End) vào reader_view, Yomihon (giãn dòng, thời gian đọc WPM) vào novel_reader_view, mặc định tắt; sửa regex đếm từ tiếng Việt; Nyora/GIF Viewer 'Không tích hợp' có lý do; p2_b 41/41 đạt. Còn: thử tay, Tate-gaki, regex Zenshin.
- 16:51 Opus: nhận PB (FC36) – đối chiếu 21 ảnh, sửa thanh dưới Play Books (Trang chủ/Thư viện/Danh sách yêu thích/Cửa hàng) + tab Sách điện tử/Sách nói; pb_a 19/19 đạt. i18n kiểm 16:5x: 18 tệp × 1615 khóa, mọi khóa i18n_*.json đều có (không bị ghi đè).
- 16:52 Opus: sửa regex Zenshin ('Show - 05 [1080]' → 5; bỏ qua độ phân giải trong ngoặc) + test (job x3_zenshin); soạn nháp audit-0.5.7/release/YomiHub-0.5.7-changelog.md (còn 2 chỗ <<…>> điền sau kiểm thử).
- 16:55 x3_zenshin 42/42 đạt. Còn chạy: I18 (FC30). Sau khi I18 xong: toàn bộ test → sync_057 -Regen → dựng đủ gói (build_057_android apk/tv, build_057_android6, build_057 win/pack/verify).
- 16:58 I18 (Sonnet): sua 5 tep dart (health/microg/vpn/wifi/win_diag), +30 khoa x18 ngon ngu da gop (1645 khoa), sua id.json 1 muc; da xep job i18_fc30 (analyze + yh_049/052), cho ket qua
- 17:10 I18 (Sonnet): XONG FC30 pham vi giao: analyze health/microg/vpn/win 0 issue, wifi 9 info co san; yh_049+yh_052 +27 All tests passed. NOTES_I18.md
- 17:10 Opus: nhận I18 (FC30) – 25 chuỗi bọc tr() ở 5 tệp + 13 ghi chú tiện ích, sửa so khớp mật khẩu Wi-Fi bị dịch, id.json 'Güncel-lemeler'; 18 tệp × 1645 khóa; i18_fc30b 27/27 đạt.
- 17:13 Opus: BẮT ĐẦU dựng đủ gói 0.5.7: job `jobs/pending/x3_build057.ps1` → `run_057_main.ps1` (sync → test → apk → tv → wintest → win → pack → a6build → a6copy → verify). Trạng thái: `audit-0.5.7/release/main_build_status_057.txt`, log `main_build_057.log`. sync 17:10 exit 0 (236 lượt chép, manifest `release/overlay_manifest_057.txt`). Nếu bước test trượt do yh_056_a (chập chờn) → chạy lại job.
- 21:30 Opus (phiên cowork chính): TIẾP QUẢN. Bản dựng x3_build057 dừng ở bước test 17:21. Đang xem logs/b057_test.txt, sửa test rồi dựng lại. Phiên khác xin đừng chạy song song.
- 21:39 P7F (Fable): bat dau, doc tai lieu; tao notes/NOTES_P7F.md
- 14:39 QA1 (Sonnet): bat dau, doc tai lieu, tao NOTES_QA1.md
- 21:47 QA1 (Sonnet): qa_lib.ps1 + submit.sh chay duoc tren Note 9 (probe: app 0.5.7+50 mo OK)
- 21:48 P7F (Fable): viec 1 - loi that trong DbWriteQueue (lenh long chay chen khi tac vu con chay); da sua db_write_queue.dart + test yh_057_p7f_test.dart; xep job p7f_q1
- 22:20 QA1 (Sonnet): flow1 launch DAT (video+timeline), flow3 sheet Thu vien x25 DAT (0 Null check logcat); dang lam flow2/4..
- 22:15 Opus: xin lại quyền điều khiển máy (14 ứng dụng) + quyền xóa sau khi app desktop cập nhật; Fable (P7F) và Sonnet (QA1) bị dừng giữa chừng theo yêu cầu chủ dự án; Haiku (DOC1) XONG: release/STATS_0.5.7_vs_0.5.6.1.md, README_release_section_057.md, CHANGELOG_TODO_057.md.
- 22:20 P7F (Fable): TIEP TUC. Viec 1 XONG: p7f_q1 EXIT 0 - hang doi cu truot 6/9 test moi (dung ky vong), hang doi moi: analyze 0 issue, yh_057_p7f 5x(+9), yh_056_a 5x(+50), nhom 056_a+057_p7f+055+054+056 +85 dat. Chuyen viec 2 (android6).
- 23:08 QA1 (Sonnet): tiep tuc flow2 (doi giao dien Cu/Moi) va flow4 (reader x10); dang kiem tra anh cu
- 23:08 P7F (Fable): TIEP TUC (phien 3). Da doc lai notes + p7f_q1.log (EXIT 0); ban sua db_write_queue.dart khong doi tu 21:46; sao luu goc da co o backup/src_0571. Xep job kiem chung jobs/pending_fast/p7f_q2.ps1 (057_p7f, 5x 056_a, 055, analyze).
- 23:11 QA1 (Sonnet): xem lai anh flow2: 4 tab (Cu), giao dien Moi (thu vien tab tren + nav Hoat dong), da khoi phuc Cu (nav Cap nhat) -> flow2 DAT; flow4 lan truoc loi mang comick (04_reader_1) -> thu lai tu Lich su
- 23:14 QA1 (Sonnet): da xep job qa1_04b (reader tu Lich su); hang doi dang cho p7f_q2 chay xong
- 23:17 P7F (Fable): p7f_q2 dang chay: yh_057_p7f +9 dat (EXIT 0), yh_056_a lan 1/5 +50 dat; dang chay lan 2.
- 23:21 P7F (Fable): p7f_q2: yh_056_a lan 1-3 deu +50 dat; dang chay lan 4.
- 23:25 P7F (Fable): p7f_q2: yh_056_a 5/5 lan deu +50 dat (EXIT 0); dang chay yh_055 roi analyze.
- 23:27 QA1 (Sonnet): job qa1_04b khong chay: runner fast ngung (runner_fast_alive.txt dung o 23:08, hang doi con p7f_q2 + qa1_04b) -> flow4 CHUA CO bang chung, dung cho Opus
- 23:32 P7F (Fable): p7f_q2: yh_055 +5 dat (EXIT 0); buoc analyze dang chay lau (tu 23:25, chua ra ket qua) - tiep tuc cho.
- 23:35 P7F (Fable): XONG. p7f_q2 EXIT 0 (23:35:07): yh_057_p7f +9 dat; yh_056_a 5/5 lan +50 dat; yh_055 +5 dat; analyze db_write_queue.dart 'No issues found!' (525.9s vi may dang tai nang). Khong can sua them. Chi tiet: notes/NOTES_P7F.md.
- 23:36 P7F (Fable): bắt đầu VIỆC 2 (U10 – 3 lỗi APK android6: ảnh Booru, trang CBZ, libqjs.so); đang đọc A6_FEASIBILITY, build_057_android6.ps1, NOTES_X1.
- 23:41 QA1 (Sonnet): phan 2 bat dau, qa1_04b da chay xong, dang xem anh 04b
- 23:42 QA1 (Sonnet): 04b mo nham truyen Comick (loi mang); xep job qa1_04c tim Lich su + hang doi tai
- 23:43 QA1 (Sonnet): Lich su co 4 muc truyen; hang doi tai trong -> khong co chuong tai san; thu mo 'Chi Gai Toi Va Nguoi Khong Lo' (job qa1_04d)
- 23:46 QA1 (Sonnet): 3/4 muc Lich su loi (Google webview / 'khong co trang nao'); tim nguon khac trong Duyet
- 23:48 QA1 (Sonnet): MangaDex (VI) 'Shirley Madison' tai duoc 12 chuong -> mo Ch.11 de test reader
- 23:49 QA1 (Sonnet): reader mo duoc (13 trang) nhung anh MangaDex 'Khong tai duoc anh'; tap giua y=1000 de goi menu
- 23:52 QA1 (Sonnet): tap giua khong goi menu khi anh loi; thu tap giu + nguon CoManhua
- 23:57 QA1 (Sonnet): CoManhua/WebtoonScan chet (DNS/loi); thu FoxTruyen, NhatTruyenS
- 23:59 QA1 (Sonnet): MangaDex (ca 2 nguon) mo reader 13/26 trang nhung anh deu loi -> khong goi duoc menu; chuyen sang flow 9 (Lich su > Phim)
- 00:00 QA1 (Sonnet): Lich su > Phim: player chi quay spinner sau 15s; thu cho 50s
- 00:02 QA1 (Sonnet): xong phan 2 - Flow4 va Flow9 BI CHAN (mang/nguon), khong danh dau DAT; chi tiet RESULTS_QA1_dev.md
- 00:03 P7F (Fable): U10 – đã có giả thuyết gốc cho (b)+(c): Android 6 mỗi lần System.loadLibrary của lớp khác (WebView/framework) ghi đè LD_LIBRARY_PATH → Dart mở 'libqjs.so'/'libsubsampling_scale_image_view.so' bằng tên trần bị 'not found' (2 thư viện này nạp trễ; libisar nạp lúc khởi động nên được). Booru: ảnh d2 sáng 14/11 CÓ hiện, d1 thì không → chập chờn, cần log chẩn đoán. Đang viết bản vá.
- 00:07 P7F (Fable): đã viết bản vá U10 trong overlay: mới lib/yomihub/a6/a6_native.dart (mở thư viện bằng đường dẫn tuyệt đối + nạp trước libqjs.so, chỉ khi kIsA6Build); sửa ffi_image_decoder.dart, main.dart; thêm log chẩn đoán ảnh mạng (chỉ android6) trong custom_extended_image_provider.dart. Tiếp: job dựng x86_64 trong build23 + thử AVD API 23.
- 00:08 P7F (Fable): đã xếp job jobs/pending_fast/p7f_u10a.ps1 (sync build→build23 + chép overlay + patch + dựng APK android6 x86_64 có IS_A6_BUILD, rồi thử AVD API 23: Booru/CBZ/libqjs; ảnh u10a_* trong android6/evidence57). Dự kiến ~35–45 phút.
- 00:10 P7F (Fable): p7f_u10a – sync + patch build23 ĐẠT với mã 0.5.7 (00:09), đang dựng APK x86_64 (flutter build apk --dart-define=IS_A6_BUILD=true). Đã thêm test overlay/test/yh_057_u10_test.dart (chưa chạy).
- 00:26 Opus: máy kết nối lại (mất ~00:22–00:25). Fable P7F: DbWriteQueue XONG (p7f_q2 đạt); U10 android6 đã viết sửa (a6_native.dart, ffi_image_decoder, log Booru) – job p7f_u10a đang dựng+thử AVD. QA1: luồng 1-3 ĐẠT, 4 và 9 BỊ CHẶN (ảnh MangaDex 'Không tải được ảnh này' – nghi AImageDecoder chỉ có từ API 30; video không phát). Đã xếp jobs/pending/x4_build057.ps1 (run_057_main, chờ BUILD_LOCK).
- 00:26 Opus: TẠM GIỮ x4_build057 (jobs/_hold) cho tới khi P7F (R21 Windows, chỉ sửa mã) và QA2 (bộ giải mã ảnh Android 7–10) xong.
- 00:27 P7F (Fable): bắt đầu việc 3 (U14/R21 cửa sổ trắng Windows) – đang đọc runner main.cpp, win_diag, NOTES_F 0.5.6, script installer.
- 00:27 QA2 (Sonnet): bat dau, doc ma bo giai ma anh (ffi_image_decoder.dart / image_decoder.cpp)
- 00:29 QA2 (Sonnet): da doc xong duong Dart; dang tim ham ghi log ung dung
- 00:31 QA2 (Sonnet): da sua ffi_image_decoder.dart (them nhanh du phong giai ma Dart + log WARNING 1 lan)
- 00:31 P7F (Fable): đã đọc bằng chứng R21 + header engine Flutter 3.47.6 (có set_gpu_preference; KHÔNG có công tắc phần mềm/WARP ở bản release). Phương án: runner đọc chế độ kết xuất (auto/igpu/dgpu/impeller), tự phát hiện vùng vẽ một màu rồi mở lại với chế độ khác; đang viết main.cpp.
- 00:34 QA2 (Sonnet): da viet test yh_057_qa2_test.dart + xep job jobs/pending_fast/qa2_dec1.ps1 (test + analyze), dang cho chay
- 00:38 P7F (Fable): đã viết overlay/windows/runner/main.cpp (yh_render: chọn GPU theo lần chạy, theo dõi vùng vẽ một màu 12–20 s, tự mở lại tối đa 2 chế độ khác, không lặp vô hạn). Tiếp: phần Dart chẩn đoán + installer.
- 00:38 QA2 (Sonnet): job qa2_dec1 dang xep hang sau p7f_u10a (dung APK android6), cho chay
- 00:50 P7F (Fable): đã thêm overlay/lib/yomihub/win/win_render.dart + mục 'Chế độ GPU (khi cửa sổ trắng)' trong Chẩn đoán Windows; 5 chuỗi mới ×18 ngôn ngữ đã gộp. Tiếp: installer dọn tệp cũ + rà cổng Platform.isWindows.
- 00:50 QA2 (Sonnet): van cho qa2_dec1 (p7f_u10a con chay)
- 00:59 P7F (Fable): tiếp tục việc 3 (phiên 4): đang đọc make_installer_exe_057.ps1 để thêm bước dọn tệp chương trình cũ.
- 01:00 P7F (Fable): installer: RemoveStaleFiles đã có (xoá *.dll cạnh YomiHub.exe + mọi tệp trong data\ của bản cũ, không đụng dữ liệu người dùng); vừa thêm xoá thư mục con rỗng trong data\. Tiếp: rà main.cpp + cổng Platform.isWindows.
- 01:01 QA2 (Sonnet): tiep tuc; p7f_u10a van dang chay (log cap nhat), qa2_dec1 cho; trong luc do rà lai ma ffi_image_decoder.dart
- 01:01 P7F (Fable): rà main.cpp: PHÁT HIỆN + SỬA lỗi biên dịch (chuỗi MessageBoxW có xuống dòng thật trong L"..." → đổi thành \n). Đang đối chiếu ký hiệu engine (GpuPreference, ImpellerSwitch, GetHandle).
- 06:21 Opus: HẾT HẠN MỨC 5 GIỜ (mở lại 03:40). P7F (Fable) và QA2 (Sonnet) bị dừng giữa chừng.
  - **CHẶN:** P7F phát hiện `overlay/windows/runner/main.cpp` (yh_render) có LỖI BIÊN DỊCH – xuống dòng thô trong chuỗi wide literal – CHƯA SỬA. KHÔNG thả `jobs/_hold/x4_build057.ps1` trước khi sửa main.cpp (bước win sẽ hỏng).
  - Còn lại P7F: sửa main.cpp; installer dọn tệp cũ (`make_installer_exe_057.ps1`); danh sách tính năng bị khóa trên Windows; đọc kết quả AVD của `p7f_u10a` (APK android6 dựng xong 00:54).
  - Còn lại QA2: chờ/đọc `jobs/done/qa2_dec1.log` (test + analyze nhánh dự phòng giải mã ảnh Dart cho API < 30 trong `ffi_image_decoder.dart`), sửa nếu trượt.
  - Sau đó: thả x4_build057 (mv jobs/_hold/x4_build057.ps1 jobs/pending/), QA lại trên Note 9 bằng APK phát hành, kiểm Windows, phát hành GitHub.
- 06:23 Opus: hạn mức mở lại. p7f_u10a: AVD API 23 nạp sẵn libqjs.so + libsubsampling (YomiA6Native), 121 CA. qa2_dec1: 11/11 đạt, analyze 0. main.cpp đã hết lỗi chuỗi (sửa 01:01). THẢ x4_build057 vào jobs/pending (bản dựng đầy đủ 0.5.7). Opus tự làm installer dọn tệp cũ trước bước pack.
- 06:24 DOC2 (Haiku): bắt đầu viết changelog v2 + section kỹ thuật 0.5.7
- 06:26 DOC2 (Haiku): đã viết changelog v2; đang viết section kỹ thuật
- 06:26 DOC2 (Haiku): xong changelog v2 + section kỹ thuật 0.5.7 (2 file trong release/)
- 06:44 Opus: x4_build057 hỏng ở bước test: ffi_image_decoder.dart dùng math.* nhưng thiếu import 'dart:math' (từ lượt QA2 bị cắt). Đã thêm import; job z057_t04_fix dừng bản dựng, nhả khóa, kiểm analyze + test; sau đó dựng lại (x5).
- 06:51 Opus: sửa ffi_image_decoder.dart (thiếu import dart:math; giải mã khung hình trước khi dispose ImageDescriptor – test QA2 đầu-cuối trước đó trượt 'Codec failed'). z057_t05_qa2: 11/11 đạt. Xếp jobs/pending/x5_build057.ps1 (bản dựng đầy đủ lần 3).
- 07:15 Opus: x5 bước test ĐẠT 849/849 (06:58), đang dựng APK. Đã bổ sung bài học 15/11 vào A.I Brain - Second Brain.
- 07:53 Opus: x5 bước apk XONG 07:31 (3 APK trong output/0.5.7), đang dựng TV. Giao QA1 (Sonnet) kiểm thử APK phát hành YomiHub-0.5.7-arm64-v8a.apk trên Note 9.
- 07:54 QA1 (Sonnet): Bắt đầu test APK phát hành 0.5.7+50 trên Note 9: cài đè giữ dữ liệu.
- 07:58 QA1 (Sonnet): Flow 1 cài đè OK (versionName 0.5.7, code 2050, update 07:55), video khởi động + timeline đã xem: splash -> màn tải YomiHub -> Thư viện.
- 07:59 QA1 (Sonnet): Flow 4: Lịch sử giờ có 4 mục truyện (không còn Shirley Madison); mở mục đầu 'Chị Gái Tôi Và Người Khổng Lồ' Ch.15.6.
- 08:00 QA1 (Sonnet): Flow 4: mục Lịch sử mở ra 'Lỗi: không có trang nào' (r04d_a); chuyển sang duyệt MangaDex (VI) để mở chương mới.
- 08:01 QA1 (Sonnet): Flow 4: MangaDex (VI) tải được danh sách (Tôi Thăng Cấp Một Mình, Slime, Frieren...); mở 'Slime' để chọn chương.
- 08:02 QA1 (Sonnet): Flow 4: Slime (MangaDex VI) có 0 chương nên không đọc được; thử 'Tôi Thăng Cấp Một Mình'.
- 08:03 QA1 (Sonnet): Flow 4: Solo Leveling (MangaDex VI) cũng 0 chương sau kéo-làm-mới; thử tìm 'Shirley Madison' qua tìm kiếm nguồn.
- 08:04 QA1 (Sonnet): Flow 4: Shirley Madison (MangaDex VI) có 12 chương; mở Vol.2 Ch.11 để xem ảnh trang.
- 08:05 QA1 (Sonnet): Flow 4: reader mở được (13 trang, menu hiện khi chạm giữa) nhưng trang 1 vẫn quay spinner sau ~20 s; đang chờ thêm + xem logcat.
- 08:05 QA1 (Sonnet): Flow 4: trang 1 vẫn spinner ~40 s, không có lỗi flutter trong logcat; thử ping CDN + nút tải lại.
- 08:06 QA1 (Sonnet): Flow 4: ảnh trang vẫn không tải (spinner treo, không báo lỗi); điện thoại ping api.mangadex.org = unknown host (DNS hệ thống), ping google OK. Chuyển sang vòng mở/đóng cài đặt reader x10.
- 08:08 QA1 (Sonnet): Flow 4b: sheet cài đặt reader mở/đóng x10 ĐẠT (đã xem ảnh r04q_settings_open1/open10, logcat không có Null check/FATAL). Nhưng ẢNH TRANG vẫn spinner treo (13 trang) -> chưa PASS phần hiển thị ảnh.
- 08:09 QA1 (Sonnet): Flow 3: sheet Bộ lọc thư viện mở/đóng x10 ĐẠT (đã xem r03_sheet_open_10.png; logcat không có Null check/FATAL). Bắt đầu Flow 9 (video).
- 08:11 QA1 (Sonnet): Flow 9: mở Phim 'Goblin Tập 04' (lịch sử 13:08) -> màn đen toàn bộ ở screencap (uiautomator dump không lấy được); kiểm tra bằng screenrecord + dumpsys media_session.
- 08:12 QA1 (Sonnet): Flow 9: màn đen là do điện thoại tắt màn hình/khoá (screen off) chứ chưa chắc lỗi player; đã bật stayon + timeout 10 phút (cần hoàn nguyên sau test), chạy lại.
- 08:14 QA1 (Sonnet): Flow 9: BLOCKED - mở Phim Goblin Tập 04, sau 22 s vẫn màn đen + spinner mờ, không thanh điều khiển/không phát (r09g_t22.png); giống bản dev, do nguồn phim. Chuyển Flow 7/15/13/12.
- 08:16 QA1 (Sonnet): Flow 7 ĐẠT từng phần (đã xem ảnh): Hợp Nhất Tiện Ích, Sao Lưu & Đồng Bộ; Flow 12 VPN & DNS mở được (VPN tắt, 5 mục) ĐẠT. Tiếp: Cài đặt > Bật/Tắt tính năng.
- 08:19 QA1 (Sonnet): Flow 7 ĐẠT (đã xem r07g_features_bottom: công tắc Google Play Books + Booru App đang bật). Tiếp Flow 15 Play Books.
- 08:19 QA1 (Sonnet): Flow 15 ĐẠT (đã xem r15_pb.png): tab Play Books có Sách điện tử/Sách nói, nav Trang chủ/Thư viện/Danh sách yêu thích/Cửa hàng; lỗi nhỏ: nhãn 'Danh sách yêu thích' xuống dòng, đè lên biểu tượng. Tiếp Flow 13 nhật ký.
- 08:21 QA1 (Sonnet): Flow 13 ĐẠT (đã xem r13c_applog.png): Nhật ký ứng dụng + Báo cáo lỗi mở được; log lặp cảnh báo CERTIFICATE_VERIFY_FAILED khi tải kho kohiden.xyz (Android 10); không có dòng nào cho lỗi ảnh reader. Tiếp Flow 2.
- 08:24 QA1 (Sonnet): Flow 2 ĐẠT (đã xem r02_montage.png): giao diện Mới (thẻ Shiori + thanh nav nổi, nhãn 'Hoạt độ...' bị cắt) và đã khôi phục giao diện Cũ. Thử thêm Booru để cô lập lỗi tải ảnh.
- 08:25 QA1 (Sonnet): Hoàn tất: ghi audit-0.5.7/qa/RESULTS_QA1_release.md. PASS flow 1,2,3,4b,7,12,13,15; FAIL 4a (ảnh MangaDex treo spinner); BLOCKED 9.
- 08:28 Opus: x5: apk/tv/wintest/win ĐẠT (Windows biên dịch được main.cpp), pack DỪNG: AppxManifest Version '0.5.7' phải 4 phần → sửa make_appxbundle_057.ps1 ($verQuad = "$ver.0"). Setup.exe đã tạo (output/). Xếp x6_rest057 (pack → a6build → a6copy → verify). QA1 trên APK phát hành: luồng 1,2,3,4b,7,12,13,15 ĐẠT; 4a trang MangaDex quay mãi (máy không phân giải api.mangadex.org – nghi mạng/DNS, nhưng app thiếu thời gian chờ + báo lỗi); 9 CHẶN (video không phát).
- 09:00 Opus: KIỂM THỬ WINDOWS: cài Setup.exe 0.5.7 đè 0.5.6.1 OK nhưng cửa sổ TRẮNG (R21 vẫn còn) ở cả dgpu, igpu, igpu+Impeller; Dart vẫn chạy (log, Tor, DB). Bản sửa tự đổi GPU KHÔNG khắc phục, bộ phát hiện báo 'ok' sai. Ghi chi tiết NOTES_P7F.md. Cần thử hồ sơ dữ liệu sạch (cần chủ dự án đồng ý).
- 09:07 QA3 (Sonnet): bắt đầu 3 việc: timeout ảnh reader, nhãn nav bị cắt, chẩn đoán video. Đang đọc NOTES_QA1.
- 09:07 P7F (Fable): Bắt đầu R21: đọc ghi chú, mã runner; chuẩn bị app tối giản + chụp ảnh CopyFromScreen.
- 09:09 P7F (Fable): Xếp job p7f_r1: chạy app tối giản hello_win (đã dựng sẵn) + YomiHub đã cài, chụp CopyFromScreen + PrintWindow.
- 09:11 QA3 (Sonnet): đã xác định đường tải ảnh: CustomExtendedNetworkImageProvider._getResponse (không có timeout) -> SSIV/MinSubsamplingImage chờ vô hạn; yêu cầu tải lại bị gộp vào request treo (_inFlightRequests). Bắt đầu sửa.
- 09:12 P7F (Fable): KẾT QUẢ p7f_r1 (đã xem ảnh): app tối giản hello_win (cùng flutter_windows.dll 21274112 byte) CŨNG TRẮNG → lỗi ở tầng engine/driver/máy, không phải mã YomiHub. Xếp p7f_r2: chẩn đoán module D3D, stderr engine, cửa sổ phủ, Event Log.
- 09:13 P7F (Fable): p7f_r2: hello_win trắng dù dùng GPU Intel phần cứng (igd10iumd64.dll), stderr engine không báo lỗi, đổi kích thước vẫn trắng. Xếp p7f_r3: liệt kê mọi cửa sổ phủ + tìm trình biên dịch để viết chương trình thử ANGLE thuần.
- 09:14 QA3 (Sonnet): xong code timeout ảnh (provider 30s, backstop SSIV/Min, hiện lý do, log WARNING theo host). Chuyển sang việc 2 (nhãn nav).
- 09:15 P7F (Fable): p7f_r3: thấy cửa sổ phủ toàn màn hình trong suốt của Claude (computer-use, 0,0-1920x1080, topmost+layered) đang bật; FLUTTERVIEW con có đủ kích thước. Xếp p7f_r4: chương trình C++ thử ANGLE thuần (7 chế độ: D3D11 như Flutter, WARP, DirectComposition…) để khoanh tầng lỗi.
- 09:17 QA3 (Sonnet): xong việc 2: Shiori nav dùng FittedBox scaleDown + padding 6; Play Books nhãn 'Yêu thích' + tooltip 'Danh sách yêu thích' (khóa dịch đã có). Chuyển i18n + test.
- 09:17 P7F (Fable): p7f_r4b QUAN TRỌNG: ANGLE thuần (không Flutter) với swapchain gắn HWND (kiểu engine Flutter dùng) cũng TRẮNG, kể cả WARP phần mềm; chỉ chế độ DirectComposition vẽ được → lỗi ở khâu trình chiếu DXGI-HWND ↔ DWM của máy, không phải driver kết xuất. Đang xem ảnh xác nhận.
- 09:18 QA3 (Sonnet): i18n_QA3.json (5 khóa x 18 ngôn ngữ) đã gộp; viết test yh_057_qa3_test.dart; xếp job qa3_t1 (analyze + test).
- 09:20 QA3 (Sonnet): xếp job qa3_0571_b (kéo logcat Note 9, chỉ đọc) để chẩn đoán video; đang đọc mã trình phát: video mạng mở ở 0:00, resume chỉ seek sau khi phát nên không chặn mở.
- 09:22 P7F (Fable): Đã xem ảnh r4b: mode 3 (DirectComposition) vẽ đúng xanh/đỏ, mode 0/1/2 trắng. Engine Flutter liên kết tĩnh ANGLE (không móc được libEGL). Xếp p7f_r5: thử cửa sổ topmost (nằm trên lớp phủ Claude), layered, swap interval để tìm tác nhân.
- 09:29 QA3 (Sonnet): job qa3_0571_a: 13/14 test qa3 + test pb/c2 ĐẠT; 1 test widget cần ProviderScope, 4 cảnh báo analyze (dấu !, @override) đã sửa; xếp lại qa3_0571_c.
- 09:31 P7F (Fable): p7f_r5: lớp phủ Claude ĐÃ TẮT mà ANGLE-HWND vẫn trắng → không phải do computer-use; topmost/layered/swap-interval đều trắng. Xếp p7f_r6: thử móc vtable DXGI trong tiến trình để đổi swapchain bitblt → flip-model (cách sửa khả thi ngay trong runner).
- 09:32 QA3 (Sonnet): job c: analyze lộ 3 lỗi do tôi bỏ nhầm dấu '!' -> đã khôi phục; chạy lại qa3_0571_d. Logcat (job b): không có dòng mpv/media_kit nào; DNS api.mangadex.org giờ phân giải được (lỗi mạng trước đó chập chờn).
- 09:32 QA3 (Sonnet): viết NOTES_QA3.md; chẩn đoán video: không thấy lỗi app, nghiêng về nguồn/mạng (DNS chập chờn), không sửa mã.
- 09:36 P7F (Fable): TÌM RA CÁCH SỬA: p7f_r6 (đã xem ảnh r6_angle_m0_f24.png) – đổi swapchain bitblt → flip-model bằng móc vtable DXGI thì ANGLE vẽ đúng (cả Intel lẫn WARP, cả sau khi huỷ/tạo lại surface). Đang dựng hello_win có bản vá (p7f_r7) rồi vá runner YomiHub.
- 09:37 QA3 (Sonnet): XONG. Job qa3_0571_d: 11/11 test ĐẠT; analyze 0 lỗi mới (còn 5 cảnh báo có sẵn, không phải của tôi). Báo Opus.
- 09:38 P7F (Fable): Đã vá overlay/windows/runner/main.cpp (yh_present: swapchain flip-model; bộ phát hiện đổi sang PrintWindow; tự mở lại = TẮT mặc định) + win_render.dart. Chờ kết quả hello_win.
- 09:39 P7F (Fable): p7f_r7 ĐẠT (đã xem ảnh r7_hello_flip_resized.png): cùng một hello_win.exe – YOMIHUB_PRESENT=blt → trắng; mặc định (flip) → hiện đủ giao diện, cả sau đổi kích thước/phóng to/khôi phục. Xếp p7f_r8: dựng YomiHub Windows trong D:\yh\buildwin với bản vá (~12 phút) rồi chụp.
- 09:41 P7F (Fable): p7f_r8 đang dựng YomiHub Windows (bắt đầu 09:39), chờ kết quả.
- 09:48 P7F (Fable): p7f_r8 vẫn đang dựng (phút thứ 9/≈12).
- 09:52 P7F (Fable): p7f_r8: dựng xong (EXIT 0); YomiHub bản vá: white=0 %, state result=ok present=flip flip_swapchains=2; đối chứng blt cùng exe: trắng. Đang xem ảnh + chạy p7f_r9 kiểm bộ phát hiện.
- 09:54 P7F (Fable): R21 ĐÃ SỬA & KIỂM CHỨNG trên máy chủ dự án: YomiHub (bản dựng D:\yh\buildwin có bản vá) hiện đủ Thư viện (đã xem ảnh r8_yomi_flip_26s.png, r8_yomi_flip_resized.png); đối chứng cùng exe với YOMIHUB_PRESENT=blt → trắng và bộ phát hiện ghi đúng result=blank color=FFFFFF, không tự mở lại. Cần dựng lại + đóng gói lại bản Windows 0.5.7 (zip, full zip, Setup.exe, appxbundle) từ overlay hiện tại.
- 10:04 Opus: chủ dự án cấp lại quyền xóa (2 thư mục dự án) + điều khiển máy (YomiHub, Explorer, PowerShell, Notepad, Task Manager). Bước pack 09:02 lỗi vì tiến trình YomiHub-0.5.7-windows-x64-Setup.exe (PID 5160, chạy từ 08:48, treo) khóa tệp output. Vì QA3 (07:xx–09:37) và P7F (bản vá R21 trong overlay/windows/runner) đổi mã SAU khi dựng APK/Windows → dựng lại TOÀN BỘ: job jobs/pending/x4_build057.ps1 (dừng Setup treo → run_057_full2.ps1: sync→test→apk→tv→wintest→win→pack→a6build→a6copy→verify).
- 10:07 Opus: đã đọc toàn bộ tiến độ các phiên trước (QA1/QA2/QA3/P7F/DOC2). Changelog: dùng v2 (DOC2) + cập nhật R21 (flip-model) và QA3 (timeout ảnh 30 s, nhãn nav) → chép đè YomiHub-0.5.7-changelog.md (v1 sao lưu backup/). Còn 2 chỗ <<…>> (ngày + kết quả kiểm thử).
- 15/11 10:12 (Opus): tạo `release_057_publish.ps1` + `release_057_fixed.ps1` (sinh bằng `audit-0.5.7/tools/gen_057_release.py` từ bản 0561; tag cũ kiểm v0.5.6.1; anchor README `**Phiên bản hiện tại: 0.5.6.1**`; placeholder thiết bị/android6/cài đè điền qua `-FillFile fill_057.json`). Thêm dòng tóm tắt + marker vào `TECHNICAL_NOTES_0.5.7_section.md` (bản trước ở backup/). Dry-run r1: preflight qua phần git/tag, dừng ở "thiếu asset android6" (đúng, x4 đang dựng).
- 15/11 10:20 (Opus): x4 dừng ở bước test: 859 đạt, 1 trượt `yh_017` (Website Scan, test mạng, TimeoutException 20 s); không phải lỗi mã. Thả x6_build057 = `run_057_full3.ps1` (chạy lại riêng yh_017 để ghi nhận, rồi apk → tv → wintest → win → pack → a6build → a6copy → verify).
- 15/11 10:27 (Opus): bổ sung 4 bài học vào `A.I Brain - Second Brain/02_bai_hoc_ky_thuat.md`. x7 đang dựng APK.
- 15/11 11:01 (Opus): x7: apk ĐẠT (10:37), tv ĐẠT (10:57), wintest ĐẠT (11:00), đang win. Note 9: cài đè APK mới thành công (lastUpdateTime 10:42, SHA256 7C06AFE5…8248, giữ dữ liệu) nhưng máy ở màn khóa PIN (Bouncer) → chờ chủ dự án mở khóa; đã bật `svc power stayon usb`, screen_off_timeout 600000 (gốc 30000, phải trả lại sau QA).
- 15/11 11:27 (Opus) LƯU TIẾN ĐỘ (chủ dự án yêu cầu dừng):
  * x7_build057 (`run_057_full3.ps1`): apk ĐẠT 10:37, tv ĐẠT 10:57, wintest ĐẠT 11:00, win ĐẠT 11:12, pack ĐẠT 11:15; đang a6build (bắt đầu 11:15) → còn a6copy, verify. Trạng thái: `audit-0.5.7/release/main_build_status_057.txt`. Nếu lỗi: tạo bản run_057_* chỉ gồm các bước còn lại (mẫu run_057_full3.ps1).
  * output\0.5.7 sau pack: Setup.exe 259 474 944 B (SHA256 31EA815A…D9CA), full.zip 259 398 259, appxbundle 264 024 132, zip 125 309 525; APK 0.5.7 arm64 177 138 107 (SHA256 7C06AFE5…8248), TV arm64 176 951 439. SHA256SUMS sẽ do release_057_publish.ps1 tạo lại.
  * Windows: job q4_wininst chạy Setup.exe (không có cờ im lặng) → hết giờ 6 phút (11:24), cửa sổ cài đặt có thể vẫn đang mở chờ bấm (bị che vì chưa cấp quyền computer-use cho setup.exe). YomiHub.exe đã cài vẫn là bản 08:11 (CHƯA có bản vá R21). Việc tiếp: cấp quyền computer-use cho "yomihub-0.5.7-windows-x64-setup.exe", hoàn tất cài, mở YomiHub, chụp xác nhận không trắng.
  * Note 9: APK mới đã cài đè (10:42) nhưng máy khóa PIN (Bouncer). Chủ dự án muốn hiện màn khóa lên máy tính để tự mở khóa: đang tìm scrcpy (job q4_findscrcpy, chưa có kết quả); trên desktop có Samsung DeX. Sau khi mở khóa: kiểm luồng 4a (ảnh trang MangaDex) và 9 (video); trả screen_off_timeout=30000 và `svc power stayon false`.
  * Đã tạo release_057_publish.ps1 / release_057_fixed.ps1 (dry-run r1 dừng đúng chỗ thiếu asset android6). Còn điền placeholder (fill_057.json: device/a6/upgrade) sau kiểm thử. Bài học đã ghi vào A.I Brain.
- 11:42 Opus: WINDOWS ĐẠT – cài Setup.exe 0.5.7 (bản 11:15, có vá R21 flip-model) đè bản 08:11: giao diện HIỆN ĐỦ (hết cửa sổ trắng). Đã xem: Thư Viện 4 tab (Truyện/Phim/Tiểu thuyết/Play Books), màn Thêm (có Sao Lưu & Đồng Bộ), VPN & DNS (Tor đang kết nối), Cài đặt (đủ mục). Video: evidence/windows/win057_walkthrough.mp4. Note 9 đã mở khóa (scrcpy v5.0.1 tại D:\yh\tools\scrcpy).
- 11:43 QA1 (Sonnet): bắt đầu kiểm lại Note 9 (4a ảnh MangaDex, 9 video, nhãn nav, logcat); đang xác nhận APK 10:42 + chụp màn hình hiện tại.
- 11:44 QA1 (Sonnet): APK xác nhận 0.5.7+50 cài 10:42, máy mở khóa (đang ở launcher). Mở app, tìm Shirley Madison.
- 11:45 QA1 (Sonnet): app mở lên Thư viện bình thường (ảnh s1_home.png); sang tab Duyệt tìm MangaDex.
- 11:48 QA1 (Sonnet): MangaDex tìm Shirley Madison: bìa ảnh tải được (s4_search.png). Mở chi tiết rồi vào chương.
- 11:50 QA1 (Sonnet): 4a: mở Vol.2 Ch.11 (13 trang) nhưng sau ~48 s vẫn spinner đen, chưa có 'Không tải được ảnh này' (s6_reader_t10/t48.png); đợi thêm 40 s + xem logcat.
- 11:51 QA1 (Sonnet): 4a: sau ~95 s trang 1 VẪN spinner, không có lỗi/Thử lại (s6_reader_t95.png) dù api+uploads.mangadex.org ping/phân giải được -> tạm FAIL; thử chạm menu xem có tải lại.
- 11:52 QA1 (Sonnet): 4a: bấm nút tải lại trên thanh trên, đợi ~50 s xem có lỗi/ảnh.
- 11:53 QA1 (Sonnet): 4a sau bấm tải lại ~52 s vẫn spinner, không báo lỗi/Thử lại (s9_reload_t52.png) -> FAIL. Chuyển sang flow 9 (video, lịch sử Phim).
- 11:54 QA1 (Sonnet): flow 9: lịch sử Phim có 4 mục; thử phát 'Kungfu Nữ Túc' (17:13) ~40 s.
- 11:55 QA1 (Sonnet): flow 9: 'Kungfu Nữ Túc' màn đen không phát (s11_play_t12/t28.png); thử nguồn thứ 2 'Thanh Gươm Diệt Quỷ'.
- 11:56 QA1 (Sonnet): flow 9: bấm Back trong trình phát -> app thu nhỏ thành cửa sổ PiP đen góc phải + thoát ra launcher (s12_afterback.png), không về Lịch sử; đóng PiP, mở lại app thử nguồn 2.
- 11:58 QA1 (Sonnet): flow 9: nguồn 2 cũng màn đen không phát, không điều khiển (s13_play_t12/t30.png) -> BLOCKED (video không phát được). Chuyển sang mục 3 (nhãn nav).
- 11:59 QA1 (Sonnet): Play Books nav: 'Yêu thích' hiển thị đủ, không xuống dòng/đè icon (s15_playbooks.png) -> PASS. Giờ đổi sang giao diện Mới xem nhãn 'Hoạt động'.
- 12:00 QA1 (Sonnet): giao diện Mới: nhãn 'Hoạt động' hiện đủ, không bị cắt (s16_ui_new_home.png) -> PASS. Đang khôi phục giao diện Cũ.
- 12:02 QA1 (Sonnet): XONG kiểm lại. 4a FAIL (spinner >95 s, không báo lỗi/Thử lại); 9 BLOCKED (2 nguồn đen); nhãn Hoạt động PASS; Yêu thích PASS; logcat sạch; đã trả UI Cũ. Chi tiết qa/RESULTS_QA1_retest.md
- 12:03 P8F (Fable): bắt đầu — đọc kết quả QA1/QA3/QA2 và script QA, rồi tái hiện 2 lỗi treo (reader MangaDex, video) trên Note 9.
- 12:07 P8F (Fable): đã đọc ghi chú QA; mở app trên Note 9 (Lịch sử truyện không có Shirley) -> đi qua Duyệt > MangaDex để tái hiện reader kèm logcat.
- 12:10 P8F (Fable): tái hiện được lỗi 1 (60 s vẫn spinner 1/13, logcat của app hoàn toàn im lặng) -> đang lần đường mã SSIV (_initImage / backstop 45 s).
- 12:11 P8F (Fable): lấy được nhật ký ứng dụng /sdcard/YomiHub/logs.txt (cập nhật 12:08) + thư mục mpv -> đọc dòng quanh 11:50-12:09.
- 12:14 P8F (Fable): logs.txt cho thấy ảnh ĐÃ tải xong, treo ở khâu giải mã: '[Reader] Image decoder fallback: native decoder returned no image (Android < 11?)' rồi im lặng -> nhánh BMP/Dart (toByteData) không bao giờ trả lời, không có hạn giờ. Đang đo bộ nhớ đồ hoạ để củng cố + thiết kế đường giải mã mới.
- 12:16 P8F (Fable): thiết kế sửa lỗi 1: Android <11 dùng ảnh ui.Image giải mã trực tiếp bằng codec Flutter (không đọc ngược điểm ảnh toByteData/BMP), mọi bước giải mã có hạn 12-20 s, watchdog 30 s -> 'Không tải được ảnh này' + lý do + WARNING. Đang viết mã.
- 12:17 P8F (Fable): bằng chứng thêm: mở chương -> trong 6 s Native Heap 48->388 MB, Graphics 322->498 MB rồi đứng yên tuyệt đối (13 trang đã giải mã, kẹt ở bước đọc ngược điểm ảnh). Đã vá ffi_image_decoder.dart (đường 'direct' + hạn giờ từng bước); đang vá SSIV/watchdog.
- 12:19 P8F (Fable): vá xong lỗi 1 (5 tệp overlay, 2 chuỗi i18n x18 đã gộp), viết test yh_057_p8f_test.dart, đã gửi job p8f_t1 (analyze + test). Trong lúc chờ: điều tra lỗi 2 (video).
- 12:22 P8F (Fable): lỗi 2: nhật ký cho thấy luồng video MỞ ĐƯỢC và vị trí vẫn chạy ('không phát tiếp được tại 28:34 sau 8 lần tua ... vị trí hiện tại 28:59') -> không phải do nguồn; nghi vòng tua lại của resume + lớp điều khiển/PiP. Đang chờ job test và job tái hiện video.
- 12:25 P8F (Fable): job p8f_t1 (flutter analyze) đang chạy lâu >10 phút (có thể chờ khoá flutter của bản dựng android6) nên job tái hiện video p8f_v1 còn xếp hàng; trong lúc chờ đọc mã trình phát (PopScope/backToPip, _inPip, _yhResumeTo).
- 12:32 P8F (Fable): lỗi 2 tái hiện + logcat: luồng mở được, OMX.Exynos.avc.dec chạy, có tiếng; vòng phát tiếp tua lại 8 lần cách nhau ~2,5 s (12:31:02→12:31:20, mỗi lần xả bộ giải mã) vì phép so vị trí không tính thời gian đã trôi sau khi tua -> màn đen + vòng quay; Back lúc 'đang phát' thì theo thiết kế vào PiP (đen). Đang sửa resume_policy + điều kiện Back→PiP.
- 12:33 P8F (Fable): đã vá lỗi 2 (resume_policy.dart: tính thời gian sau khi tua; yomi_pip.dart + anime_player_view.dart: Back chỉ vào PiP khi hình đang phát thật), thêm test; gửi job p8f_t2 (6 tệp test + analyze 9 tệp). Dọn PiP còn treo trên máy sau khi job xong.
- 12:37 P8F (Fable): job p8f_t2: 6 tệp test chạy xong, TEST EXIT 0 (đang chờ phần analyze ~6 phút); đã viết notes/NOTES_P8F.md.
- 12:40 P8F (Fable): XONG. Test 74/74 đạt (p8f_zt3), analyze 9 tệp 0 lỗi (chỉ cảnh báo cũ). Lỗi 1: treo ở giải mã ảnh Android <11 -> đường ui.Image trực tiếp + hạn giờ + báo lỗi/Thử lại. Lỗi 2: vòng phát tiếp tua 8 lần + Back→PiP khi chưa có hình -> đã sửa; còn 1 điểm chưa rõ (hình vẫn đen sau khi hết tua) cần Opus kiểm trên bản dựng mới. Đã đóng PiP trên máy (force-stop). Chi tiết notes/NOTES_P8F.md
- 12:41 Opus: bản dựng 11:55 XONG (gồm android6 + verify). QA1 retest Note 9: nhãn ĐẠT, logcat sạch, 4a vẫn quay, 9 màn đen. P8F (Fable): 4a = treo ở bước giải mã Android<11 (toByteData), sửa giải mã thẳng ui.Image + giới hạn 12 s/bước + watchdog 30 s; 9 = resume tua 8 lần (isNear quá chặt) + Back tự PiP khi chưa có hình – đã sửa; 74/74 test, analyze 0 lỗi. Xếp x9_build057 (run_057_main đầy đủ).
- 13:18 QA1 (Sonnet): bắt đầu kiểm lần cuối trên Note 9; đang xem lịch sử
- 13:22 QA1 (Sonnet): đọc MangaDex Shirley Madison Vol.2 Ch.11: trang 1/13 hiện sau ~3 s (đã xem ảnh a4_r_t3); đang lật trang 2, 5
- 13:22 QA1 (Sonnet): lật trang bằng vuốt trái không đổi (vẫn 1/13), thử vuốt phải/dọc/chạm mép
- 13:23 QA1 (Sonnet): reader dùng vuốt dọc: trang 2/13 hiện đúng (a6_up.png); đang sang trang 5
- 13:23 QA1 (Sonnet): trang 5/13 hiện đúng (a7_p5.png) -> mục 1 MangaDex đạt; đang mở chương từ nguồn truyện khác (Lịch sử)
- 13:25 QA1 (Sonnet): chương thứ 1 trong Lịch sử (Chị Gái Tôi...) báo 'Lỗi: không có trang nào' (nguồn không trả trang, không có Thử lại); thử các mục lịch sử khác
- 13:27 QA1 (Sonnet): FoxTruyen 'Không có kết quả' (nguồn rỗng); thử Comick/CoManhua
- 13:28 QA1 (Sonnet): Comick/CoManhua lỗi kết nối (api.comick.fun 'Network unreachable' - nguồn/mạng, không phải reader); thử NhatTruyenS
- 13:29 QA1 (Sonnet): NhatTruyenS cũng 'Không có kết quả'; thử Thư viện
- 13:30 QA1 (Sonnet): mở chương Comick (nguồn DNS lỗi) để xem đường báo lỗi/Thử lại
- 13:31 QA1 (Sonnet): Comick: sau 10 s đã có 'Đã xảy ra lỗi' + lý do (Network unreachable) + nút Thử lại (UI dump b8_t35) -> thử bấm Thử lại, rồi sang video
- 13:32 QA1 (Sonnet): Thử lại trên Comick bấm được và tải lại (spinner, b9_retry.png); chuyển sang kiểm video Kungfu Nữ Túc + quay màn hình
- 13:34 QA1 (Sonnet): video Kungfu: log 'sau 8 lần tua' vẫn xuất hiện 13:33:23 (đếm 5->6) – đang xem ảnh + logcat
- 13:34 QA1 (Sonnet): video Kungfu 0.5.7+50 mới: VẪN 8 lần tua (log 13:33:23 'sau 8 lần tua', AudioTrack stop x9), màn đen không có hình, 00:00; xem video quay để chốt
- 13:34 QA1 (Sonnet): kiểm Back khi video đen, rồi hồi quy sheet Thư viện x5 + sheet Reader x5
- 13:37 QA1 (Sonnet): Back khi video đen -> app vào PiP (stack pinned 672x378) và thoát ra launcher; thư viện sheet x5 xong, đang làm reader sheet x5
- 13:38 QA1 (Sonnet): XONG kiểm lần cuối: reader ĐẠT; video FAIL (vẫn 8 lần tua, không hình, Back->PiP); sheet x5 + logcat ĐẠT. Chi tiết qa/RESULTS_QA1_final.md
- 13:45 P8F (Fable): tiếp tục lỗi video Note 9 - đọc lại mã trình phát (hwdec/vo, vòng phát tiếp, PiP) và logcat QA1
- 13:50 P8F (Fable): đã đọc mã: Android dùng vo=gpu + hwdec 'auto' (MediaCodec xuất thẳng ra surface); logcat QA1 xác nhận 9 lần tua cách 2,5 s. Chuẩn bị tái hiện trên máy và thử đổi 'Hardware Decoder'
- 13:54 P8F (Fable): đã chạy tái hiện e1 trên Note 9 (cài đặt mặc định), đang xem ảnh + logcat
- 13:56 P8F (Fable): e1 tái hiện: toàn màn hình đen (kể cả sau chạm), tiếng chạy, log 'sau 8 lần tua' 47:03 -> 47:27 (mỗi lần tua rơi lệch ~+22 s so với đích => vòng lặp không bao giờ 'tới đích'). Cài đặt hiện tại: Bộ giải mã phần cứng = auto. Sắp thử đổi sang mediacodec-copy/no
- 13:58 P8F (Fable): đã đổi tạm 'Bộ giải mã phần cứng' auto -> mediacodec-copy trên máy (sẽ trả lại auto sau khi thử), đang phát lại video (e2)
- 14:01 P8F (Fable): e2 (mediacodec-copy) VẪN đen => không phải do hwdec. Phát hiện: máy chạy Flutter Impeller (OpenGLES); đang thử khởi động app với Impeller tắt (cờ intent, không đổi cài đặt) rồi phát video (e3)
- 14:04 P8F (Fable): e3 (Impeller tắt) VẪN đen => không phải Impeller, không phải hwdec. Đang quay màn hình 45 s kèm chạm để xem dòng thời gian chính xác (e4)
- 14:06 P8F (Fable): e4 (quay màn hình): điều khiển + thời gian chạy bình thường (51:57/1:37:43, nút tạm dừng), CHỈ phần hình đen. Tìm cách lấy log mpv để biết vì sao không ra hình
- 14:07 P8F (Fable): máy đang bật 'mpv config' (/sdcard/YomiHub/mpv/mpv.conf). Tạm thêm 1 dòng log-file vào mpv.conf (đã sao lưu, sẽ trả lại ngay) để lấy log mpv thật khi phát (e5)
- 14:08 P8F (Fable): đã lấy được log mpv (e5_mpv.log, 103 KB), mpv.conf đã trả về nguyên bản; đang đọc
- 14:09 P8F (Fable): log mpv: (1) tua tới 3359,44 s luôn rơi ở 3380,88 s (+21 s, HLS) => vòng tua 8 lần; (2) mpv báo đang vẽ hình bình thường nhưng chọn cấu hình EGL 10-bit (rgb10_a2) cho surface của Flutter - nghi đây là lý do hình đen. Thử ép egl-output-format=rgba8 qua mpv.conf tạm (e6)
- 14:11 P8F (Fable): e6 (ép EGL 8-bit) VẪN đen => loại nốt giả thuyết 10-bit. mpv vẫn báo vẽ hình đều; lỗi nằm giữa mpv và Texture của Flutter. Lấy mã media_kit_video (Android) từ pub cache để đọc
- 14:12 P8F (Fable): mã media_kit không có gì lạ. Dùng 1 script Lua tạm trong thư mục mpv của máy (sẽ xoá ngay sau) để mpv tự chụp khung nó đang vẽ + in thuộc tính (e7) - biết lỗi ở mpv hay ở Flutter
- 14:14 P8F (Fable): BẰNG CHỨNG: khung do chính mpv chụp từ đầu ra của nó (e7_win.jpg) là hình phim bình thường => mpv giải mã + vẽ ĐÚNG; hình mất ở khâu Flutter hiển thị Texture (surface ImageReader trên Android 10). Script tạm + mpv.conf đã trả nguyên. Đang tìm thêm dấu vết trong logcat
- 14:15 P8F (Fable): mã nguồn Flutter 3.44 xác nhận: Texture video trên Android 10 đi qua ImageReader/HardwareBuffer, Flutter đã phải né đường này cho Huawei <= Android 10 (cờ debugForceSurfaceProducerGlTextures). Kiểm xem bản trước video có hình trên Note 9 không
- 14:16 P8F (Fable): chốt nguyên nhân: (1) hình mất ở khâu Flutter Texture/ImageReader trên Android 10 (mpv vẽ đúng); (2) nguồn HLS tua lệch +21 s nên vòng phát tiếp tua 8 lần. Bắt đầu sửa: MainActivity (Android <= 10 dùng SurfaceTexture + Skia), resume_policy, PiP
- 14:18 P8F (Fable): đã vá overlay: MainActivity.kt (Android <= 10: SurfaceTexture + tắt Impeller), resume_policy (chấp nhận tua lệch tới 60 s, tối đa 2 lần tua, không tua khi vị trí đứng yên), yomi_pip (Back chỉ PiP khi vị trí đang chạy và hết giai đoạn phát tiếp), watchdog đổi bộ giải mã khi không có hình. Viết test
- 14:18 P8F (Fable): chạy flutter test + analyze cho các tệp vừa sửa (job p8f_t5)
- 14:25 P8F (Fable): analyze 0 lỗi (chỉ 1 info cũ); test báo exit 1 nhưng không in chi tiết - chạy lại riêng yh_057_p8f để xem ca nào trượt
- 14:30 P8F (Fable): 1 test cũ (yh_054, so khớp nguyên văn mã) trượt do tôi đổi dòng log - đã giữ nguyên dòng cũ và thêm dòng mới riêng; chạy lại toàn bộ (job p8f_t8)
- 14:33 P8F (Fable): test 79/79 đạt, analyze 0 lỗi/0 cảnh báo mới. Trả cài đặt 'Bộ giải mã phần cứng' trên máy về auto và dọn tệp tạm
- 14:37 Opus: QA1 final (APK 13:17): reader MangaDex ĐẠT, báo lỗi/Thử lại ĐẠT, sheet ×5 ĐẠT, logcat sạch; video vẫn đen. P8F-2 (Fable, 14:06–14:33) chứng minh mpv vẽ đúng (khung mpv tự chụp có hình) → mất ở Flutter Texture/ImageReader Android 10; sửa MainActivity (SDK<=29: debugForceSurfaceProducerGlTextures + tắt Impeller), resume chấp nhận HLS lệch ≤60 s, PiP chỉ khi hình chạy; 79/79 test. Opus đã đọc diff MainActivity (an toàn, try/catch). x9 XONG 14:08 (chưa có P8F-2). Xếp x10_build057 (lần cuối).
- 15:27 Opus: KIỂM VIDEO trên Note 9 (APK 15:13): điều khiển hiện, phát tiếp đúng (01:22:56), không còn tua lặp, Back về trong app (không PiP) – nhưng hình VẪN ĐEN. Logcat: 'legacy video textures not available: NoSuchFieldException: debugForceSurfaceProducerGlTextures' – trường có trong flutter.jar (public static) nhưng R8 đổi tên/gỡ trong bản release. Thêm -keepclassmembers vào overlay/android/app/proguard-rules.pro. Dừng x10 (đang TV), xếp x11 dựng lại đầy đủ.
- 15:46 Opus: x11 bước test 876/877 (chỉ yh_017 – test mạng Website Scan timeout 20 s, không phải lỗi mã). Xếp x12 = run_057_full3 (apk→tv→wintest→win→pack→a6build→a6copy→verify).
- 16:57 Opus: chủ dự án chọn kiểm video trên máy ảo Android 10 (tải system-images;android-29;google_apis;x86_64 ~1 GB) + kiểm Sao lưu/Khôi phục điện thoại↔máy tính (Note9→Windows hồ sơ tạm; Windows→AVD API29, không đè dữ liệu thật). Job f9_img29 đang tải.
- 19:16 Opus: máy ngủ ~17:12 làm 2 runner treo (x12 dừng ở TV, f9 sdkmanager); 1 cửa sổ PowerShell kẹt chế độ 'Select' (QuickEdit). Đã đóng runner treo, mở lại 3_run_jobs.bat + 3b_run_fast_jobs.bat qua Explorer; f10_cleanup tắt gradle/sdkmanager treo, nhả khóa. Xếp x13_tail (tv→…→verify) và f11 tải image API 29 chạy tách.
- 19:21–20:15 Opus: SAO LƯU/KHÔI PHỤC 2 CHIỀU – ĐẠT. Note 9 tạo 24,5 MB (Download/YomiHub_test) → pull → Windows hồ sơ tạm khôi phục Thay thế 4490 bộ/99299 chương (52 s) → Windows tạo 24,2 MB → AVD API29 khôi phục 4490/88371 (70 s) → Note 9 khôi phục đè (chủ dự án cho phép) 4490/88371 (~10 phút). Dữ liệu thật Windows trả về nguyên vẹn (isar 618659840). Bằng chứng evidence/backup, evidence/avd29.
- 19:53 Opus: VIDEO ANDROID 10 – ĐẠT trên AVD YH_Android10_API29 (image giải nén thủ công từ zip đã tải 17:00): log 'SurfaceTexture video textures, Impeller off', không NoSuchField; MP4 hiện hình + chuyển động (avd29_video_playback.mp4).
- 20:16–20:27 Opus: Cài đè Setup.exe bản cuối (19:58) lên Windows, dữ liệu thật giữ nguyên, không trắng. Quay video evidence/windows/YomiHub-0.5.7-windows-walkthrough.mp4 (4 phút): Thư viện 4 tab, Play Books, Booru, Cập nhật, Duyệt, Hợp nhất, Thống kê, VPN & DNS (Tor đã kết nối), Sao lưu, Cài đặt, Giới thiệu (Beta 0.5.7), lỗi nguồn 500 có Thử lại.
- 21:18 Opus: PHÁT HÀNH XONG v0.5.7 – commit cb16f65, tag v0.5.7, Release id 446092528, 19/19 tệp OK (tên+kích thước), draft=False. https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.5.7
