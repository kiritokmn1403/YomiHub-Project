# YomiHub 0.5.7 so với 0.5.6.1: tính năng, lỗi đã sửa, số liệu và trạng thái

> Ngày lập: 14/11/2026 (bản nháp của DOC1, chỉ đọc mã và ghi chú; không chạy job nào).
> Nguồn: `coordination/PROGRESS_0571.md`, `coordination/MATRIX_0571.md`, `notes/NOTES_*.md`, `00_DECISIONS.md`, `logs/b057_test.txt`, `release/main_build_status_057.txt`, `release/main_build_057.log`, `git diff HEAD -- overlay`.

## Tình trạng bản dựng (đọc trước)

- **Bản dựng 0.5.7 CHƯA hoàn tất.** Bước test của `build_057.ps1` dừng lúc 17:21 (exit 1). Lượt test cuối trong `logs/b057_test.txt` ghi **828 đạt / 1 trượt**: `yh_056_a` ("async write transaction already in progress", real Isar). Ghi chú `NOTES_X1` và x2_retest ghi test này chập chờn: chạy riêng 2/2 đạt.
- `output/0.5.7/` đang trống: **chưa có APK, Windows (Setup/appxbundle/zip), SHA256SUMS hay changelog đã dựng**. Chưa dựng APK Android 6.0 và APK Android TV của 0.5.7.
- Thiết bị: chỉ có bản dev `YomiHub-0.5.7-dev-arm64-v8a.apk` (versionCode 2050) cài trên Samsung Note 9 (Android 10). Ảnh `evidence/phone/p03_now.png` cho thấy Thư viện 4 tab, `logcat -b crash` trống; một số ảnh bìa trống, chưa rõ nguyên nhân. Không có kết quả kiểm thử máy nào khác cho 0.5.7.
- Mọi mục bên dưới là **đã sửa trong mã và có test đơn vị/widget**, trừ khi ghi khác. Chưa kiểm trên máy thật, trừ ảnh nêu trên.

## 0. Tóm tắt

- **13 tính năng mới hoặc nối mới** (mục a), **22 mục lỗi** (mục b: 21 đã sửa, 1 còn mở là B10; có bằng chứng log khi có), **120 tệp** trong `overlay/` thay đổi so với HEAD: 96 tệp đã sửa (+3544 / -442 dòng) và 24 tệp mới.
- Kiểm thử: lượt cuối 828 test (1 trượt chập chờn); `dart analyze` các gói không có lỗi mới (cảnh báo còn lại là cảnh báo có sẵn).
- Chưa kiểm trên máy: gần như toàn bộ tính năng, dựng APK/Windows, Android 6.0, Android TV.

## (a) Tính năng mới so với 0.5.6.1

| # | Tính năng | Chi tiết | Nguồn (ghi chú) | Kiểm thử |
|---|---|---|---|---|
| 1 | Bật/tắt Google Play Books và Booru ngay trong "Bật/Tắt tính năng & Nguồn mở rộng" | Công tắc thật (SwitchListTile), khóa pref cũ giữ nguyên | NOTES_P1 | yh_057_p1 45/45 (mã) |
| 2 | Hợp Nhất Tiện Ích: gom công cụ hợp nhất về một mục; bỏ ô trùng ở "Dữ liệu và bộ nhớ" | Mục "Hợp nhất nội dung" thành mục con | NOTES_P1 | Mã + test |
| 3 | Chọn "Nguồn đọc" cho bộ đã hợp nhất, nhớ theo bộ | Nút Đọc lần đầu và chương kế tiếp trong trình đọc mở chương theo nguồn ưu tiên; nút Tiếp tục không đổi nguồn | NOTES_P1 (FC37) | Mã + test |
| 4 | Giao diện Mới: ô bìa và huy hiệu kiểu Shiori, ẩn ô "gộp thư viện" khi dùng Mới | Chuyển trang Shiori chỉ có hiệu lực sau khi khởi động lại; Giao diện Cũ không đổi | NOTES_P6 (U11) | yh_057_p6 7/7; yh_049 + 2 test UI 49/49 |
| 5 | Yomikiru: phím A/D/Space/Home/End trong trình đọc truyện | Mặc định tắt; bật trong cài đặt trình đọc | NOTES_P2 (U5) | yh_057_p2 + 41/41 |
| 6 | Yomihon: preset giãn dòng và chip "thời gian đọc ước tính" (WPM) cho tiểu thuyết | Mặc định tắt; chế độ dọc (Tate-gaki) chưa làm | NOTES_P2 (U5) | yh_057_p2 |
| 7 | Health Connect: ghi phút đọc/xem thật; nhắc nghỉ mắt 20-20-20 khi đọc/xem liên tục | Trước đó hàm không được gọi nên thống kê luôn bằng 0 | NOTES_X1 (FC35) | yh_057_p5 33/33 (mã) |
| 8 | Trình duyệt: script chống dấu vân tay (Canvas, Audio, WebGL, navigator); công tắc "Bảo vệ dấu vân tay" nay có tác dụng | Chỉ trình duyệt Chromium/WebView; Firefox (Gecko) chưa áp; không áp vào WebView giải Cloudflare | NOTES_P4 (U6, một phần) | yh_057_p4 3/3 |
| 9 | Google Play Books: thanh dưới Trang chủ / Thư viện / Danh sách yêu thích / Cửa hàng; tab Sách điện tử / Sách nói | Theo 21 ảnh mẫu; phần nội dung do trang Google tạo, không sửa được trong WebView | NOTES_PB (FC36) | yh_057_pb 19/19 (cùng yh_049) |
| 10 | Short Video: nhận diện thêm tiện ích ngoài (bộ lọc Short, checkbox/tri-state/nhóm lồng); công tắc "Ép chế độ Short" theo từng nguồn | Chỉ với nguồn anime; không nhận genre "short" trơn | NOTES_P3 (P3b) (U9, FC26) | yh_057_p3 + 61/61 |
| 11 | Trình phát: nối module Nuvio (vuốt sáng/âm lượng, tua đúp, tỉ lệ PiP); ba công tắc Nuvio/Zenshin/PiP trong cài đặt | Module đã có từ 0.5.6, nay mới được nối vào trình phát | NOTES_P3 (U5) | Mã + test |
| 12 | Zenshin: đồng bộ tracker khi đạt ngưỡng xem, một lần mỗi lượt phát | Ngưỡng 85 % | NOTES_P3 (U5) | Mã + test |
| 13 | Tor: tự đổi cầu nối khi bootstrap kẹt (công tắc "Tự đổi cầu nối khi Tor bị kẹt", mặc định bật) | Chỉ Android và khi chọn snowflake/obfs4/meek; Windows chưa có | NOTES_F1 | yh_057_f1_net 18 test (mã) |

Ghi chú: mục 11 và 12 nối các mô-đun đã có trong `lib/yomihub/integrations/` từ 0.5.6; theo MATRIX, Nyora và GIF Viewer chưa được nối (xem mục d).

## (b) Lỗi đã sửa (22 mục)

| # | Triệu chứng | Bằng chứng (log hoặc mã) | Nguyên nhân và cách sửa | Trạng thái |
|---|---|---|---|---|
| B1 | "Null check operator used on a null value" khi đóng bảng chọn có thanh tab (Thư viện, trình đọc) | 40× theo MATRIX: /mangaReaderView (13/11 16:00) và /MangaLibrary ×34 (14/11 07:02:45), tabs.dart:633 | `modules/widgets/custom_draggable_tabbar.dart` (DraggableTabsHost). Giải mã stack bằng llvm-symbolizer với symbols build_id d6bf8bd5… | Sửa trong mã; test yh_057_tabs 2/2; chưa kiểm máy |
| B2 | Tiện ích Kotatsu gửi yêu cầu tới `127.0.0.1:9` khi Tor khởi động; cầu nối bị khởi động lại và làm hỏng các nguồn Kotatsu khác | Log 12/11 16:18:53–16:19:13, 6 cảnh báo; "Kill switch đang chặn" | Yêu cầu loopback đi trực tiếp (`loopback_bypass.dart`); khi có nguy cơ rò IP thì chặn kèm thông báo tiếng Việt thay vì khởi động lại cầu nối | Sửa một phần: Kotatsu/IReader theo phạm vi từng tiện ích và Windows vẫn chưa đi qua proxy (cần Kotlin) |
| B3 | Tor kẹt 45–50 % với cầu nối snowflake, không tự đổi | MATRIX U1: 11 lần; NOTES_F1: 10 lỗi (hai số khác nhau, xem CHANGELOG_TODO) | `tor_fallback.dart`: kẹt = % không tăng trong 75 s (cầu nối) hoặc 40 s (kết nối thẳng), thử lần lượt các cầu nối khác | Sửa trong mã; chưa kiểm máy; mạng chặn Tor là nguyên nhân bên ngoài (V5) |
| B4 | "CBHentai: đã giải Cloudflare xong nhưng vẫn không tải được" (hentaicube.xyz) | MATRIX: ×8; NOTES_F1: 5 dòng, chênh 3–5 s giữa các lần | `cf_identity.dart` gửi đúng Client Hints của WebView đã vượt xác minh; "đã giải" chỉ khi WebView rời trang xác minh | Sửa trong mã; không tái hiện được; trang có thể đã đổi tên miền |
| B5 | "Invalid repository index" cho kho `.pb` (x.noz.one, yuzono, cursed) | Log 12/11 15:02:43–47: hết 25 s rồi nhánh JSON ném FormatException | `extension_store_service.dart` (lý do lỗi, nhận diện HTML, thử lại 1 lần với 60 s); `fetch_sources_list.dart` không chạy nhánh JSON cho `.pb` | Sửa trong mã; chưa thử mạng thật |
| B6 | Kiểm tra cập nhật bị chậm/timeout (MediaFire, Drive) | Log: timeout MediaFire ×2 | `multi_source_update.dart`: 7 lượt chạy song song, thử lại 1 lần, chỉ ghi WARNING sau khi thử lại | Sửa trong mã; chưa chạy thật |
| B7 | Lỗi tiện ích ghi ERROR kèm stack cho trường hợp không phải lỗi ứng dụng (Kavita chưa cấu hình, HTTP 530/"HTTP 0", "(Ngừng hoạt động)", Aidoku SourceError, NHentai "Bad state: No element", JSON/CSRF, 405) | Nhiều dòng trong log 12–14/11 | `ext_errors.dart`, `logger.dart` `classifyMessage`: WARNING/INFO một dòng; tin "Extension …" không còn bị gắn "Lỗi Ứng Dụng" | Sửa trong mã; test yh_057_t4 35/35 |
| B8 | Tiện ích "MiMi": `abstract method … typeParametersSerializers()` | Log 13–14/11, build_id trùng symbols của APK android6 chạy trên máy đời mới | Chỉ phân loại thành WARNING kèm gợi ý; `a6_notice.dart` cảnh báo khi APK android6 chạy trên Android 7.0+. Nguyên nhân gốc (thư viện android6 thiếu phương thức mặc định) mới là giả thuyết | Phân loại đã sửa; nguyên nhân chưa xác nhận |
| B9 | "Image/network load failed" lặp 164 dòng | Log 12–14/11 | `log_rate_limiter.dart` (`LogBurstAggregator`): dòng đầu ghi ngay, các lần sau gộp thành một dòng tổng mỗi phút; test kiểm tổng 164 | Sửa trong mã; test yh_057_s1_logs 11/11 |
| B10 | Giao diện treo 2,6 s và 2,8 s | Log: 2 lần | Chưa tìm được nguyên nhân. `perf_watchdog.dart` ghi thêm tên màn hình khi treo | **Còn mở** (chỉ thêm dữ liệu để chẩn đoán lần sau) |
| B11 | Bộ lọc VinaHentai không tải, log không có lý do | Log: "không trả về danh sách bộ lọc (sau 3 lần thử)" | `filter_refresh.dart` / `filter_loader.dart`: ghi lý do; danh sách rỗng là hợp lệ, không thử lại | Sửa trong mã; chưa có test tự động cho nhánh này |
| B12 | Phát tiếp video: vị trí không đúng khi đổi server/chất lượng; mini player văng khi tập chưa có id | Mã (không có số lần trong log 7) | `resume_policy.dart`, `resume_store.dart`; mini player không còn `episode.id!` | Sửa trong mã; test yh_054/056/057_p3; chưa kiểm máy (VOD/HLS, đổi server) |
| B13 | Bộ lọc kiểu "Hide shorts / No shorts" bị áp dụng ngược (bật Short) | Phát hiện khi rà mã (P3b), không có trong log | `shorts_detect.dart`: từ phủ định không được coi là Short | Sửa trong mã; test có |
| B14 | Zenshin: số tập sai với tên "Show - 05 [1080]" | Rà mã và test | Regex bỏ qua phần ngoặc độ phân giải | Sửa trong mã; x3_zenshin 42/42 |
| B15 | Yomihon đếm từ tiếng Việt sai (đếm dư) | Test P2 thất bại | `\w` của Dart không khớp chữ có dấu; dùng `\p{L}\p{N}` | Sửa trong mã; test có |
| B16 | Wi-Fi: đánh giá "không có mật khẩu" sai khi đổi ngôn ngữ | Rà mã (I18) | So sánh chuỗi đã dịch bằng `tr()` | Sửa trong mã |
| B17 | Nhận tệp LAN bị ngắt giữa chừng để lại tệp hỏng | Rà mã (P5b) | Xóa tệp dở, kiểm dung lượng với Content-Length, ghi ERROR | Sửa trong mã; cần thử 2 máy |
| B18 | Health Connect: thời lượng đọc/xem luôn bằng 0; nhắc 20-20-20 không chạy | Rà mã (FC35): hàm `record*` không được gọi | Gọi từ `setHistoryUpdate` (bỏ qua ẩn danh) và từ vòng đời trình đọc/phát | Sửa trong mã; chưa kiểm Android 14+ |
| B19 | Booru: JSON hỏng gây FormatException thô | Rà mã (P5b) | `BooruException(format)` | Sửa trong mã |
| B20 | Tải chương bị chặn "chỉ Wi-Fi" hoặc lỗi hàng chờ không có nhật ký | Rà mã (FC32) | Ghi WARNING trong `download_provider.dart` | Sửa trong mã |
| B21 | Nhật ký thiếu lỗi sao lưu Telegram, chia sẻ LAN/Bluetooth, Web Scanner | Rà mã (FC32, FC24, FC16) | Ghi nhật ký, che token (`_mask`) | Sửa trong mã; chưa thử Telegram thật |
| B22 | Thanh dưới Play Books không khớp ảnh mẫu (Sách nói ở thanh dưới) | So sánh 21 ảnh (FC36) | Đổi thanh điều hướng thành 4 mục, đưa Sách nói vào tab Trang chủ | Sửa trong mã; chưa kiểm máy |

## (c) Số liệu

| Chỉ số | Giá trị | Ghi chú |
|---|---|---|
| Tính năng mới hoặc nối mới | 13 | Mục (a) |
| Lỗi | 22 mục (21 đã sửa, 1 còn mở) | Mục (b); B10 (treo UI) còn mở |
| Tệp `overlay/` đã sửa (tracked) | 96 | `git diff --stat HEAD -- overlay`: 3544 dòng thêm, 442 dòng xóa |
| Tệp `overlay/` mới (untracked) | 24 | 10 trong `lib/`, 14 trong `test/` (gồm `yh_057_p7f_test.dart`, chưa có ghi chú) |
| Tổng tệp thay đổi | 120 | Manifest đồng bộ 17:10 chỉ có 118 mục: đã cũ, cần `sync_057.ps1 -Regen` |
| Phân bố tệp đã sửa | `lib/yomihub` 42, `lib/modules` 20, `assets/yomihub_i18n` 18, `lib/services` 5, `lib/utils` 3, `lib/eval` 2, `lib/router` 1, `lib/repositories` 1, `lib/main.dart` 1, `test` 2, `pubspec.yaml` 1 | Không có tệp trong `overlay/android` (theo git diff) |
| Test | 828 chạy, 1 trượt (chập chờn) | Lượt test cuối trong `logs/b057_test.txt` |
| Chuỗi giao diện (i18n) | 1645 khóa x 18 ngôn ngữ | `en.json` 1645 khóa; `yh_049` 15/15 và các lượt sau đạt |
| Phiên bản | 0.5.7+50 | versionCode: arm64 2050, armeabi-v7a 1050, x86_64 4050 (đã thấy 2050 trên máy) |

## (d) Vấn đề còn mở và chưa kiểm

**Bản dựng và phát hành**
- Chưa dựng: APK Android 7.0+ (3 ABI), APK Android TV (3 ABI), APK Android 6.0 (3 ABI), Windows (Setup.exe, .appxbundle, .zip, -full.zip), SHA256SUMS, changelog.
- Bước test của `build_057.ps1` chưa đạt lần nào; `yh_056_a` cần xác nhận ổn định trước khi dựng.
- Chưa kiểm nâng cấp từ 0.5.6.1 (cài đè giữ dữ liệu) – `build_057_android.ps1` có bước kiểm nhưng chưa chạy.
- Đã đồng bộ overlay lúc 17:10; sau đó còn nhiều tệp đổi (P6, P2, P5b, PB, I18, P4, P7F) nên manifest cũ.

**Chưa kiểm trên thiết bị (chưa có kết quả)**
- Toàn bộ 24 mục TEST-ONLY của MATRIX (kho repo, tải/bộ lọc, trình duyệt, đọc truyện/ebook/PDF, PiP, Share LAN và Bluetooth, tracker, dịch ảnh, Booru, Telegram, quay video/ảnh).
- Phát tiếp video (VOD, HLS, đổi server), Short với tiện ích ngoài, vuốt sáng/âm lượng, tua đúp, PiP.
- Health Connect trên Android 14+; chống dấu vân tay trên trang thử thật.
- Giao diện Shiori: chưa chụp ảnh Cũ/Mới thật; chuyển trang cần khởi động lại; `ShioriHeader`, `ShioriTheme`, `ShioriCard` (lớp phủ) chưa nối.
- Ảnh bìa trống trong ảnh chụp p03 trên Note 9: nguyên nhân chưa rõ (mạng hay lỗi).

**Chưa làm hoặc làm một phần**
- U5: Nyora và GIF Viewer "Không tích hợp" (có lý do ghi trong bảng); Yomihon chế độ dọc; Frank Yomik (U6) chưa làm.
- U6: Gecko chưa áp chống dấu vân tay; chữ ký anti-bot cho WebView giải Cloudflare chưa làm.
- U10: APK Android 6.0 0.5.7 chưa dựng; Isar chưa nâng; lỗi A6 của 0.5.6.1 (ảnh Booru, CBZ, QuickJS, CA HTTPS) chưa đánh giá lại.
- U14: cửa sổ trắng trên Windows (R21) chưa có biện pháp; không có kết xuất dự phòng.
- Kotatsu/IReader đi VPN theo từng tiện ích (cần sửa `YomiKotatsu.kt`) và Windows JVM proxy: chưa làm.
- B10: nguyên nhân treo UI chưa tìm ra.
- Chưa chạy `dart analyze lib` toàn phần (theo NOTES_F1); chỉ phân tích từng nhóm tệp.
- FC27/FC30: còn một số tệp chưa quét chuỗi tiếng Việt chưa `tr()`: `vpn_tunnels.dart`, `vpn_service.dart`, `lan_share.dart`, `playbooks_settings_screen.dart`.
- FC28: chưa đo dung lượng APK và cold start so với 0.5.6.1.
- FC37: nút Tiếp tục không theo nguồn đã chọn; chưa thử với extension repo của sheet.
- FC32: `download_provider.dart` còn một catch rỗng (được chấp nhận trong NOTES_P5).
- Sheet "Website Extension" (FC15, FC34) không còn trong `Project YomiHub.xlsx` mới.
- Khối còn lại của Android TV (FC TV): cờ `IS_TV_BUILD` chưa xác minh trong APK 0.5.7.

**Rủi ro cần để ý**
- `yh_057_p7f_test.dart` (untracked) chưa có ghi chú nào giải thích; cần đọc và xác nhận trước khi dựng.
- Trước khi dựng: chạy `sync_057.ps1 -Regen`, kiểm pubspec `0.5.7+50`, và kiểm cờ `--dart-define=IS_A6_BUILD=true` trong script android6.

## (e) Trạng thái U1–U14, FC1–FC43 và TV

Cách ghi: **DONE (mã)** = có mã và test đơn vị/widget, cần kiểm trên máy; **Cần test máy** = không có thay đổi mã lớn, chỉ cần kiểm thử thiết bị; **PARTIAL** = mã chưa đủ theo yêu cầu. Các ghi chú sau (NOTES_*) được ưu tiên hơn MATRIX.

| Mã | Yêu cầu (rút gọn) | Trạng thái | Ghi chú theo ghi chú mới nhất |
|---|---|---|---|
| U1 | Đọc nhật ký, sửa lỗi/cảnh báo | PARTIAL | Các mục log 7 đã sửa trong mã (B1–B9); treo UI chưa rõ nguyên nhân (B10) |
| U2 | Bổ sung dự án GitHub | DONE (mã) | 637 URL khớp, 0 thiếu (MATRIX; không đổi ở 0.5.7) |
| U3 | Gộp sao lưu/đồng bộ/Booru vào "Sao Lưu & Đồng Bộ" | DONE (mã) | Chuỗi sai vị trí đã sửa (NOTES_P1, booru_settings) |
| U4 | Công tắc Play Books/Booru trong "Bật/Tắt tính năng" | DONE (mã) | Lượt 2 đã thêm công tắc thật; còn xác nhận có nên thêm mục vào menu Thêm |
| U5 | Tích hợp Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, Mangayomi/Kotatsu, GIF Viewer | PARTIAL | Yomikiru, Yomihon, Zenshin, Nuvio đã nối một phần; Nyora và GIF Viewer không tích hợp (lý do ghi trong bảng) |
| U6 | Frank Yomik, Browser Fingerprint, Anti-bot | PARTIAL | Chống dấu vân tay cho Chromium (NOTES_P4); Gecko, Frank Yomik, chữ ký anti-bot chưa làm |
| U7 | Phát tiếp video từ vị trí cũ | DONE (mã) | Đã có logic `resume_policy` và `resume_store` (NOTES_P3); cần test máy |
| U8 | Kiểm tra và sửa VPN | DONE (mã) | VPN 0.5.6.1 đạt trên AVD; 0.5.7 thêm Tor fallback và loopback (NOTES_F1); cần test máy |
| U9 | Short Video cho extension ngoài | DONE (mã) | Nhận diện và công tắc ép (NOTES_P3, P3b); cần test máy với extension thật |
| U10 | Isar/libmdbx, Android 6.0 | PARTIAL | APK android6 0.5.7 chưa dựng; Isar chưa nâng; còn lỗi A6 của 0.5.6.1 |
| U11 | Giao diện Mới (Shiori), chuyển Cũ/Mới | PARTIAL | Bìa và huy hiệu, ẩn "gộp thư viện" (NOTES_P6); chưa có ảnh thật; cần khởi động lại |
| U12 | Thư Viện gộp Truyện/Phim/Tiểu thuyết/Play Books | DONE (mã) | Đã kiểm trên 0.5.6 (QA2); 0.5.7 cần kiểm lại |
| U13 | Treo, lag, văng | PARTIAL | Sửa null-check và log treo (B1, B10); chưa đo cold start, bộ nhớ |
| U14 | Windows (AMD Ryzen 9) thiếu tính năng | PARTIAL | Chẩn đoán Windows có chuỗi dịch (I18); cửa sổ trắng R21 chưa xử lý |
| FC1 | Tính năng mới theo sheet GitHub | PARTIAL | Phụ thuộc U5 và U6 |
| FC2 | Nâng cấp theo YomiHub Update | PARTIAL | U1, U5, U6, U10, U11, U14 chưa xong |
| FC3 | Đọc nhật ký và sửa lỗi | PARTIAL | = U1 |
| FC4 | Đồng nhất giao diện Android và Windows | Cần test máy | Chưa có ảnh so sánh thật |
| FC5 | Đồng bộ kho Aniyomi/Nekoyomi/Kotatsu/IReader/Aidoku/LNReader | Cần test máy | Sửa thông báo kho `.pb` (B5); chưa nạp kho thật |
| FC6 | Tương thích 14 kho của sheet | Cần test máy | URL đã có trong `extensions_repo_screen.dart` |
| FC7 | Tải extension ổn định; bộ lọc | Cần test máy | Sửa lý do lỗi bộ lọc (B11) |
| FC8 | Giao diện và Liquid Glass | Cần test máy | |
| FC9 | Tương thích extension | Cần test máy | |
| FC10 | Ổn định Mangayomi Extension Server, ApkBridge, MiHon Server | Cần test máy | Phân loại lỗi "MiMi" (B8) |
| FC11 | Trình duyệt Chromium/Firefox ổn định | Cần test máy | Chống dấu vân tay chỉ Chromium |
| FC12 | VPN, DNS, AdBlock | Cần test máy | Tor fallback, loopback (B2, B3) |
| FC13 | Lỗi chương/ảnh Novel & Comic, cuộn vô hạn | Cần test máy | Gộp log ảnh (B9) |
| FC14 | Ổn định ebook và PDF | Cần test máy | Không có thay đổi mã |
| FC15 | PiP và PiP cho extension | DONE (mã) | Công tắc PiP, mini player (NOTES_P3); sheet Website Extension không còn trong xlsx mới |
| FC16 | Web Scanner ổn định | DONE (mã) | Ghi log lỗi quét (PROGRESS_0571, mục x2_scan; B21) |
| FC17 | Đổi URL/tên miền | Cần test máy | Không có thay đổi mã |
| FC18 | Thống nhất ngôn ngữ, bố cục Windows–Android | Cần test máy | |
| FC19 | Cloudflare và bypass | PARTIAL | Client Hints và "đã giải" (B4) sửa trong mã; chưa tái hiện được; anti-bot chưa làm |
| FC20 | Check For Update theo URL sheet | DONE (mã) | Song song, thử lại (B6) |
| FC21 | Quét 13 website, gợi ý kho | DONE (mã) | Không đổi ở 0.5.7 ngoài thông báo lỗi; chưa xác thực chỉ mục trước khi gợi ý |
| FC22 | Thư mục cục bộ | DONE (mã) | Không đổi ở 0.5.7 |
| FC23 | Splash 5 s, logo bo tròn | DONE (mã) | Cần quay video (FC43) |
| FC24 | AirDrop và Quick Share | DONE (mã) | Nhật ký và xử lý tệp dở (B17, B21); cần thử 2 máy |
| FC25 | Tracker | Cần test máy | Không đổi ngoài Zenshin (NOTES_P3) |
| FC26 | Short Video và Video Short Scroll | DONE (mã) | = U9 |
| FC27 | Biên dịch văn bản sang mọi ngôn ngữ | PARTIAL | 1645 khóa x 18; còn tệp chưa quét (mục d); chất lượng dịch chưa rà |
| FC28 | Tối ưu mã, dung lượng, tốc độ | PARTIAL | Chưa đo APK và cold start; chưa analyze toàn phần |
| FC29 | Dịch ảnh trong trình đọc | Cần test máy | Không đổi |
| FC30 | Tìm chuỗi chưa dịch | PARTIAL | Đã quét 5 tệp (I18); 4 tệp còn lại chưa quét |
| FC31 | So khớp GitHub | DONE (mã) | = U2 |
| FC32 | Ghi mọi lỗi vào Nhật Ký | PARTIAL | Đã thêm log cho nhiều nhánh (B2, B9, B16–B21); còn catch rỗng ở `download_provider` |
| FC33 | Bộ tính năng Hợp Nhất Tiện Ích | Cần test máy | |
| FC34 | Ngôn ngữ và NSFW của extension | Cần test máy | Sheet không còn trong xlsx mới |
| FC35 | Health Connect ổn định | DONE (mã) | Gọi hàm ghi và nhắc nghỉ mắt (B18); cần Android 14+ |
| FC36 | Google Play Books, đối chiếu 21 ảnh | DONE (mã) | Thanh dưới và tab (B22); avatar và nội dung trang Google không làm được trong WebView |
| FC37 | Giao diện sau hợp nhất; ký hiệu; thử extension repo | PARTIAL | Chọn "Nguồn đọc" có nhớ (mục a.3); nút Tiếp tục chưa theo nguồn; chưa thử repo |
| FC38 | Hợp Nhất Tiện Ích gom về một mục | DONE (mã) | Mục a.2 |
| FC39 | Lưu/tiếp tục vị trí video | DONE (mã) | = U7 |
| FC40 | Booru App đầy đủ | Cần test máy | Công tắc và lỗi JSON (B19); chưa thử từng site |
| FC41 | Bật/tắt Comic, Film, Novel và kho | DONE (mã) | Công tắc (mục a.1); cần test máy |
| FC42 | Sao lưu Telegram | Cần test máy | Nhật ký, che token (B21); chưa gửi/khôi phục thật |
| FC43 | Hiệu năng; quay video và chụp ảnh | Cần test máy | Chưa quay video, chưa chụp đủ ảnh Android/TV/Windows |
| TV | APK Android TV bỏ Comic/Novel/Play Books/Booru | Cần test máy | Mã đã có từ 0.5.6 (`IS_TV_BUILD`); APK 0.5.7 chưa dựng; cờ chưa xác minh trong APK |

## Ghi chú về số liệu

- MATRIX ghi Tor kẹt 11 lần; NOTES_F1 ghi 10 lỗi. Nên dùng một con số khi đưa vào changelog, hoặc ghi "10–11 lần".
- "40× Null check" là tổng theo MATRIX (1 lần ở /mangaReaderView và ×34 ở /MangaLibrary, cộng các lần khác); đối chiếu lại với log gốc nếu cần con số chính xác.
- Số 118 trong manifest đồng bộ là của lúc 17:10, không phải số hiện tại.
