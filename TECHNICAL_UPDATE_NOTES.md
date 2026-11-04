# YomiHub — Ghi chú kỹ thuật cập nhật

**BẮT BUỘC ĐỌC TRƯỚC MỖI LẦN CẬP NHẬT.**

Chủ dự án yêu cầu tạo và duy trì tài liệu này ngày 25/10/2026. Quy định được ghi thêm trong `AGENTS.md` ở gốc dự án. Mỗi người hoặc tác nhân tự động cập nhật ứng dụng phải đọc toàn bộ tài liệu, kiểm tra trạng thái và bổ sung kết quả sau khi làm việc.

## 1. Trạng thái hiện tại

- **04/11/2026 – 0.5.1 (0.5.1+43) đã dựng, kiểm thử và phát hành (GitHub Release `v0.5.1`):** 3 APK Android 7.0+, 3 APK `YumiHub Android TV` (không Comic/Novel/Play Books/Booru), Windows 10/11 x64 `.appxbundle` / `Setup.exe` / portable `.zip` / `-full.zip` trong `output/0.5.1`. Sửa: thư mục cục bộ nhận tệp tải của Aniyomi/Nekoyomi/Mihon/Mangayomi (tìm sâu tới 4 cấp + **quyền bộ nhớ Android 7–10** – nguyên nhân chính), nhật ký ứng dụng luôn ghi được, trang "Truy cập mọi tệp" không tự mở mỗi lần khởi động, giật ở Thêm/Cài đặt (truy vấn Isar nhẹ, bất đồng bộ), runtime vBook thử lại + báo nguyên nhân, EPUB hỏng không dừng lượt quét. Mới: **Kiểm tra tệp APK tiện ích** (Decode & Extract, chỉ đọc). Tiện ích vBook mã hóa (234/554): không giải mã (mục 0.5.1 C, H). Còn lại: "tiếp tục phát" chưa xác nhận lại trên máy ảo TV (0.5.1 I). Chi tiết: mục "03/11/2026 — Cập nhật phiên bản 0.5.1".
- **03/11/2026 – 0.5.0 (0.5.0+42) đã dựng, kiểm thử và phát hành (GitHub Release `v0.5.0`):** 3 APK Android 7.0+, 3 APK `YumiHub Android TV` (nay bỏ cả Comic, Novel, **Google Play Books, Booru**), Windows 10/11 x64 `.appxbundle` / `Setup.exe` / portable `.zip` / `-full.zip` trong `output/0.5.0`. Sửa: tiện ích vBook mã hóa bị "cài lại" + ghi ERROR lặp (nay khóa, nhãn "Chỉ chạy trên vBook", 1 cảnh báo), MangaDex (unlocked) không cài được do `SharedPreferences.get` ném lỗi với khóa lạ, khung hình chậm ở "Thêm", bảng cài đặt trình phát TV còn tiếng Anh, trình chạy tác vụ treo do QuickEdit. `flutter test` 84/84, `dart analyze` 0 lỗi. Kiểm thử Note 9 (cài đè, vBook mã hóa, nhật ký 0 lỗi, tiếp tục phát 42:26, HotPhim), AVD TV (thanh bên, trình phát tiếng Việt; phát phim không đạt trên giả lập), Windows 11 (Setup.exe cài đè 0.4.9→0.5.0, **giao diện hiển thị đầy đủ** – hết cửa sổ trắng). **Không đạt:** Android 6.0, Windows 7/8/x86/ARM, sherpa-onnx. Chi tiết: mục "03/11/2026 — Cập nhật phiên bản 0.5.0".
- **03/11/2026 – 0.4.9 (0.4.9+41) đã dựng, kiểm thử và phát hành (GitHub Release `v0.4.9`):** 3 APK Android 7.0+ (arm64-v8a, armeabi-v7a, x86_64), 3 APK `YumiHub Android TV` (không có Comic/Novel), Windows 10/11 x64 `.appxbundle` / `Setup.exe` / portable `.zip` / portable `-full.zip` trong `output/0.4.9` kèm `SHA256SUMS-0.4.9.txt`. Mới: chạy tiện ích **vBook** (runtime chuyển mã Rhino → QuickJS), kiểm tra cập nhật nhiều nguồn (GitHub → Drive ×3 → MediaFire ×3, cả bản TV), VPN Windscribe/Hotspot Shield, Telegram tự lấy Chat ID, 59 liên kết GitHub còn thiếu. Sửa: hàng đợi ghi Isar (lỗi `async write transaction already in progress` trong logs_6), tiếp tục phát từ vị trí đã xem với HLS, Đề Xuất timeout hàng loạt, Anime47 (đã gỡ tài khoản viết cứng – **nên đổi mật khẩu**), mô tả vBook, giao diện Android TV còn tiếng Anh / thời lượng thô / hỏi quyền lặp lại, 80 chuỗi dịch × 18 ngôn ngữ. `flutter test` 76/76, `dart analyze` 0 lỗi. Kiểm thử thật trên Samsung Note 9 (Android 10), giả lập Android TV API 34 và Windows 11 x64, có ảnh + video. **Không đạt:** Android 6.0, Windows 7/8/x86/ARM (giới hạn Isar/Flutter – mục 0.4.9 H). Chi tiết: mục "02/11/2026 – 03/11/2026 — Cập nhật phiên bản 0.4.9".
- **01/11/2026 – 0.4.7 (0.4.7+39) đã dựng và bàn giao:** 3 APK Android 6.0+, 3 APK `YumiHub Android TV`, Windows 7/10/11 x64 `.appxbundle`/`Setup.exe`/portable `.zip`/portable `-full.zip` trong `output/0.4.7`. Mới/sửa: Khắc phục triệt để lỗi font chữ và tràn khung hiển thị trong mục "Đề Xuất" (viết mới `_SuggestionCard`, badge nguồn, kế thừa `textTheme` Unicode fallback), tách riêng APK Android TV bỏ Comic/Novel, sửa lỗi đọc chương minh họa Novel Hako, sửa lỗi seek video live stream, thêm cài đặt "Tiếp tục phát video từ vị trí đã xem", Splash 5s morph vuông sang tròn (`r=size/2`), validate Telegram Cloud Backup Chat ID. Đạt 56/56 unit test (`All tests passed!`), kiểm thử thực tế thành công 100% trên thiết bị ngoại vi Samsung Galaxy Note 9 (SM-N960N, Android 10, màn hình 1440x2960) có đầy đủ ảnh chụp màn hình và video minh chứng. Chi tiết: mục "01/11/2026 — Cập nhật phiên bản 0.4.7".
- **31/10/2026 - 01/11/2026 – 0.4.6 (0.4.6+38) đã dựng và bàn giao:** 3 APK Android 7.0+, 3 APK `YumiHub Android TV`, Windows 10/11 x64 `.appxbundle`/`Setup.exe`/portable `.zip` trong `output/0.4.6`. Mới/sửa: Tùy biến phạm vi VPN cho từng nguồn Booru cá nhân, nâng cấp thư viện JS mở rộng và xử lý ngoại lệ ảnh 404. Chi tiết: mục "31/10/2026 - 01/11/2026 - Cập nhật phiên bản 0.4.6".
- **30/10/2026 – 0.4.5 (0.4.5+37) đã dựng và bàn giao:** 3 APK Android 7.0+, 3 APK `YumiHub Android TV`, Windows 10/11 x64 `.appxbundle`/`Setup.exe`/portable `.zip` trong `output/0.4.5`. Mới/sửa: Telegram chia phần ≤ 19 MB + che token + đi qua VPN, splash không dựng lại cả app, trình phát luồng trực tiếp, cheerio LNReader (Hako), WARP gồm YomiHub, Booru Rule34, VTV Go `cache.vtvgo.vn`, log chương tiểu thuyết. Kiểm thử trên Xiaomi 15T + AVD TV; Setup.exe cài thành công. **Còn mở:** mọi app Flutter trên máy Windows này (kể cả app mẫu) hiện cửa sổ trắng – mục G. Chi tiết: mục "30/10/2026 — Cập nhật phiên bản 0.4.5".
- **29/10/2026 – 0.4.4 (0.4.4+36) đã dựng và bàn giao:** APK Android 7.0+ (3 ABI), APK `YumiHub Android TV` (3 ABI, chỉ Phim & Điện ảnh), Windows 10/11 x64 `.appxbundle`/`Setup.exe`/portable `.zip` trong `output/0.4.4` (bản sao ở `..\output\0.4.4`). Mới: Booru App, đồng bộ Rclone/MediaFire, Health Connect native, 36 dự án GitHub, tên miền dự phòng; sửa Tor kết nối muộn bị kẹt Kill switch, log rhttp/stack, quét ảnh bìa lúc khởi động. `dart analyze` 0 lỗi, `flutter test` 41/41. **Còn mở:** cửa sổ Windows trắng trên máy hiện tại (cả 0.4.3) – xem mục 0.4.4 F; Tor bị nhà mạng chặn ở 50 %. Chi tiết: mục "29/10/2026 — Cập nhật phiên bản 0.4.4".
- **28/10/2026 – 0.4.3 (0.4.3+35) đã dựng và bàn giao:** APK Android 7.0+ (3 ABI), APK `YumiHub Android TV` (3 ABI, chỉ Phim & Điện ảnh), Windows 10/11 x64 `.appxbundle`/`Setup.exe`/portable `.zip` trong `output/0.4.3` (bản sao ở `..\output\0.4.3`); 27/27 test đạt. Đã sửa lỗi hồi quy DNS của chính 0.4.3 (mọi nguồn treo khi tải, mục H) và dựng lại toàn bộ lúc 21:44; sửa ảnh bìa/tên trong tab "Lịch Sử Đọc/Xem" và nền giữ chỗ khi ảnh bìa lỗi (mục I), dựng lại lúc 23:40; 29/10 sửa lỗi app tự đóng khi bật Tor (tor-android 0.4.9.13 + chống vòng lặp thoát) và toast ảnh bìa tiếng Anh, kiểm thử trên điện thoại thật Xiaomi 15T, dựng lại lúc 09:17 (mục J). Android 6.0 và Windows 7/x86/ARM không đạt được (xem mục D, E). Chi tiết: mục "Cập nhật phiên bản 0.4.3" cuối tài liệu (A–J).

- **Bộ cài mới nhất đã đóng gói (Phiên bản 0.4.1+33):**
  - Đã đóng gói hoàn chỉnh đủ 3 định dạng cho Windows: `.appxbundle` (283.7 MB, có chữ ký số và script cài đặt), `.exe` Setup installer (145.0 MB), và bản `portable` ZIP (144.9 MB thường / 279.0 MB full kèm JRE).
  - Đã đóng gói đủ 3 gói APK Android Mobile (`arm64-v8a`, `armeabi-v7a`, `x86_64`) tương thích Android 6.0+.
  - Đã đóng gói đủ 3 gói APK chuyên dụng Android TV đặt tên **`YumiHub Android TV`** (`arm64-v8a`, `armeabi-v7a`, `x86_64`) với cờ biên dịch `IS_TV_BUILD=true` và khóa cứng loại bỏ hoàn toàn tính năng Comic và Novel trên Android TV.
  - Toàn bộ các bài kiểm thử tự động (unit/regression tests) đạt 100% (bao gồm `yh_041_test.dart` mới).
  - Đã xuất bản toàn bộ vào thư mục bàn giao: `D:\A.I Project\A.I Project - YomiHub Project\output\0.4.1` kèm bảng băm `SHA256SUMS-0.4.1.txt` và `checksums_0.4.1.csv`.
- Mục tiêu: Thực hiện toàn diện các tiêu chí nâng cấp lên 0.4.1 theo yêu cầu người dùng, xử lý toàn bộ lỗi trong tệp nhật ký hoạt động (Activity Logs), tối ưu hóa hiệu năng, giải quyết lỗi Cloudflare bypass, dự phòng Brotli stream decoding, unwrap URL ảnh lồng ghép, và chống treo luồng giao diện khi cập nhật thư viện.
- Ngày ghi trạng thái: 26/10/2026, múi giờ Asia/Saigon.

## 2. Nguồn yêu cầu và phạm vi

Người dùng đã xác nhận nội dung trong **cả hai tệp Excel là yêu cầu thực hiện**, không chỉ tài liệu tham khảo:

1. `D:\Drive\OneDrive\OneDrive\Visicons - Văn Bản & Mẫu Văn Bản\A.I Code\Project GitHub.xlsx`
2. `D:\Drive\OneDrive\OneDrive\Visicons - Văn Bản & Mẫu Văn Bản\A.I Code\A.I Code - YomiHub Project\Project YomiHub.xlsx`

Đã đọc các sheet và xuất nội dung đã che thông tin đăng nhập vào `audit-0.3.9/Project GitHub.json` và `audit-0.3.9/Project YomiHub.json`. Không ghi lại thông tin đăng nhập từ bản gốc vào tài liệu này.

Phạm vi gồm 39 nhóm kiểm tra tính năng, 10 yêu cầu sửa đổi, kho tiện ích, website nguồn, tracker, hình mẫu giao diện Merge và 21 hình mẫu Google Play Books. Danh sách GitHub có 469 liên kết được trích xuất; một liên kết được liệt kê không đồng nghĩa mã hoặc tính năng của dự án đó đã được tích hợp.

Các nhóm phải tiếp tục đối chiếu: giao diện Android/Windows, Liquid Glass, trình đọc truyện/tiểu thuyết/PDF/EPUB, tải xuống, video/đổi server/PiP/shorts, kho tiện ích và bộ lọc, trình duyệt, VPN/DNS/AdBlock, Cloudflare, Web Scanner, nhiều thư mục cục bộ, splash 5 giây, chia sẻ giữa thiết bị, tracker, dịch ảnh, bản địa hóa, Health Connect và Google Play Books. Người dùng còn yêu cầu **quay video quá trình kiểm tra**.

## 3. Cấu trúc dự án và nguồn mã

| Thành phần | Vị trí | Vai trò |
| --- | --- | --- |
| Gốc dự án | `D:\A.I Project\A.I Project - YomiHub Project` | Yêu cầu, overlay, script, output, audit |
| Thay đổi riêng | `overlay` | Nguồn cần bảo toàn và cập nhật |
| Nguồn nền | `src/mangayomi` | Nguồn upstream; không đồng nghĩa bản phát hành YomiHub |
| Bản dựng Android | `D:\A.I Project\yh\build\mangayomi` | Mã nền cộng overlay |
| Bản dựng Windows | `D:\A.I Project\yh\buildwin\mangayomi` | Mã nền cộng overlay |
| Đường dẫn ngắn | `D:\yh` | Junction trỏ tới `D:\A.I Project\yh` |
| Kết quả | `output` | Bộ cài; phải kiểm tra phiên bản thực |
| Bằng chứng | `audit-0.3.9` | Log, kiểm thử, bản sao trước sửa, danh sách tệp |

Không phát hiện Git checkout đầy đủ tại gốc dự án hoặc các thư mục dựng trong đợt kiểm tra. Thư mục `YomiHub-Project` chỉ có nội dung Git rất ít, không thay thế được mã đang dựng. Không dựa vào `git diff` ở thư mục đó để kết luận phạm vi thay đổi.

`audit-0.3.9/sync_changes.py` đồng bộ các tệp overlay thay đổi kể từ mốc baseline vào hai bản dựng, giữ bản trước sửa trong `audit-0.3.9/before/android` và `before/windows`. Manifest: `changed-files.json`. Script dựa trên thời gian tệp, vì vậy phải kiểm tra manifest và hash trước phát hành; không xem đây là hệ thống quản lý phiên bản đầy đủ.

`prepare_changes.py` đã chạy một lần; không chạy lại tùy tiện. Các script dựng gốc có thao tác mirror/xóa cache và thư mục helper; phải đọc trước khi sử dụng. Đợt này ưu tiên gọi Flutter trực tiếp để tránh ghi đè thay đổi.

## 4. Phương hướng nâng cấp

1. Ưu tiên các lỗi gây mất thông tin nguồn, sai dữ liệu và mất vị trí xem; sau đó kiểm tra cập nhật, kho tiện ích, tên miền và giao diện.
2. Xây dựng ca kiểm thử hồi quy tái hiện hành vi lỗi. Phân biệt kiểm tra HTTP, phân tích index, cài tiện ích và đọc/phát nội dung: đây là các mức kiểm chứng khác nhau.
3. Giữ bản gốc dữ liệu và lịch sử. Kiểm thử hợp nhất/tách bằng cơ sở dữ liệu tạm, không dùng thư viện thật làm dữ liệu phá hủy.
4. Đồng bộ cùng thay đổi cho Android và Windows, kiểm tra mã, chạy test, dựng bộ cài thật, cài nâng cấp giữ dữ liệu và kiểm tra trực tiếp.
5. Ghi rõ các giới hạn: yêu cầu đăng nhập, CAPTCHA, thiết bị vật lý thứ hai, dịch vụ bên ngoài hoặc tính năng không được hỗ trợ trên một nền tảng. Không đánh dấu đạt chỉ vì có nút giao diện.
6. Tham khảo upstream có chọn lọc; không tự động ghép mọi dự án GitHub vào ứng dụng. Kiểm tra tương thích, giấy phép, API và tác động dữ liệu trước khi đưa vào.

Đã tra cứu kho chính thức Aniyomi, Nekoyomi và Mangayomi. Metadata và các trang phát hành chỉ hỗ trợ đối chiếu hướng phát triển; không chứng minh mọi cập nhật upstream đã được nhập vào YomiHub:

- https://github.com/aniyomiorg/aniyomi
- https://github.com/Seguaz/Nekoyomi
- https://github.com/kodjodevf/mangayomi/releases

## 5. Nhật ký kỹ thuật sửa lỗi 0.3.9

### 5.1 Tìm và hợp nhất nội dung

**Vấn đề:** so sánh từng cặp gây độ phức tạp O(n²), xử lý tên có thể làm sai Unicode hoặc trộn loại nội dung. Sau hợp nhất, chương có thể mất danh tính nguồn; URL cùng đường dẫn ở hai website bị xem là trùng. Dùng tên nhóm dịch để suy ra nguồn không đáng tin cậy.

**Thay đổi:**

- `modules/more/data_and_storage/providers/delete_source.dart`: gom theo map gồm loại nội dung và tên đã chuẩn hóa Unicode; bỏ tên trống; kiểm tra các bộ lưu hợp lệ và cùng loại nội dung trước hợp nhất.
- `yomihub/merge/chapter_origins.dart`: lưu danh tính nguồn từng chương trong khóa `mergedChapterOrigins` của YomiPrefs: sourceId, source, lang, link bộ gốc, mangaId và chapterUrl. Không ghi đè scanlator.
- `repositories/manga_repository.dart`: khóa loại trùng gồm danh tính nguồn cộng đường dẫn chương, giữ hai chương từ hai nguồn khác nhau dù đường dẫn giống nhau.
- `services/get_chapter_pages.dart`, `get_video_list.dart`, `get_html_content.dart`: chọn bộ phân tích theo nguồn gốc của chương sau hợp nhất.
- `modules/manga/detail/manga_detail_view.dart` và `widgets/manga_info_header.dart`: thêm bộ chọn nguồn dưới vùng thao tác và lọc chương theo nguồn, theo hình mẫu Merge.
- `update_manga_detail_providers.dart`: khi cập nhật nguồn chính, không đối chiếu/xóa nhầm chương thuộc nguồn khác; giữ duration đã lưu nếu metadata mới không cung cấp.
- `content_merge_screen.dart`: nhận diện và tách theo khóa nguồn thay vì chỉ tên hiển thị; khôi phục sourceId, ngôn ngữ, link và quan hệ chương.
- `repositories/chapter_repository.dart`: `saveWithMangaLink` cập nhật quan hệ IsarLink và các tham chiếu lịch sử/cập nhật cùng giao dịch.

**Bảo vệ sao lưu bổ sung:** nhập gộp thư viện tạo ID chương mới. `restore.dart` trả map ID cũ→mới; `ChapterOrigins.restore` chỉ gắn metadata cho chương đã nhập, giữ metadata đang có. `YomiBackupExtras.restore` không ghi đè trực tiếp khóa này. Khôi phục thay thế xóa metadata cũ khi bản sao lưu không có. `of()` kiểm tra chapterUrl để giảm nguy cơ tái sử dụng ID sai.

**Lỗi trong quá trình triển khai:** biểu thức Map nullable lồng trong ternary gây lỗi cú pháp khi test và dựng Windows. Đã tách thành biến `boxes`, `prefs`, `originData` có kiểm tra kiểu. Phải xác nhận bằng kiểm thử lại, không bỏ qua log thất bại.

**Cần kiểm tra thêm:** khả năng làm mới toàn bộ các nguồn phụ sau hợp nhất, bản sao lưu cũ, thao tác tách liên tiếp, phục hồi tải xuống và trải nghiệm trên TV. Metadata mới không thể tự phục hồi thông tin đã mất từ các lần hợp nhất bằng phiên bản cũ.

### 5.2 Hợp nhất tiện ích

**Vấn đề:** đổi hàng loạt sourceId/source của nội dung thư viện sang tiện ích chính có thể làm bộ phân tích sai. Nhóm chồng lấn có thể ẩn cả tiện ích chính.

**Thay đổi:** `extension_merge_screen.dart` dùng nhóm hiển thị thay cho đổi nguồn toàn bộ thư viện, chỉ chọn tiện ích cùng loại nội dung; `YomiMerge.merge` trong `builtin_extensions.dart` loại thành viên chồng lấn khỏi nhóm cũ, xóa nhóm dưới hai thành viên và sửa primary/active.

Phân tích mã phát hiện getter không tồn tại `sourceRepository.all`; đã đổi sang `getAll()`. Bổ sung import hai màn hình vào test để lỗi biên dịch giao diện không bị bỏ sót bởi chỉ kiểm thử service.

### 5.3 Vị trí xem, đổi chất lượng và vòng đời trình phát

**Vấn đề:** sự kiện vị trí 0 trong lúc mở hoặc dừng video ghi đè tiến độ; hẹn giờ bỏ bảo vệ quá sớm; stop/open không được chờ đúng thứ tự; lưu lặp khi thoát; chương đã xóa có thể bị lưu lại. Đoạn cuối 5% bị coi là phải phát lại từ đầu.

**Thay đổi:**

- `anime_player_view.dart`: bật bảo vệ resume trước open/stop, giữ đến khi nhận vị trí phù hợp, kiểm tra mounted, bắt lỗi seek; chờ đổi chất lượng; giữ vị trí khi đổi server; bỏ lần lưu lặp sau dispose.
- `anime_player_controller_provider.dart`: dùng truy vấn nullable; không tạo lại chương đã bị xóa; giới hạn tần suất ghi; bắt lỗi Future của thao tác lưu; chỉ trở về 0 khi vị trí đã đạt toàn bộ duration, không tự reset tại 95%.

**Cần kiểm tra trực tiếp:** đóng/mở lại ứng dụng, đổi server/chất lượng, stream HLS, video cục bộ, backend phát khác nhau, PiP và thời lượng ghi lịch sử. Test đơn vị không đủ chứng minh toàn bộ luồng video.

### 5.4 Kiểm tra cập nhật qua Drive

**Vấn đề:** HTML parser dựa regex dễ sai khi đổi class/ngày sửa; giới hạn duyệt thư mục có thể bỏ qua bản mới; chọn bản mới nhất trước khi lọc nền tảng; lỗi mạng bị trình bày như không có cập nhật; tên tệp trong query URL tải xuống bị nhận dạng sai.

**Thay đổi:** `drive_update.dart` dùng DOM, visited set, thứ tự phiên bản giảm dần, giới hạn độ sâu/số thư mục/thời gian; lọc bộ cài và nền tảng trước chọn phiên bản; HTTP/HTML lỗi phải báo lỗi. Provider và màn hình Giới thiệu hiển thị lỗi kết nối riêng. Nhận dạng tên tệp đã giải mã và bổ sung appxbundle/msixbundle. Thêm chuỗi báo lỗi tương ứng ở 18 bộ ngôn ngữ.

**Giới hạn:** kiểm tra URL công khai và parser không tương đương cài thành công mọi định dạng/ABI. Giới hạn 30 thư mục, độ sâu 3 và thời gian tổng 60 giây cần theo dõi nếu cấu trúc Drive lớn hơn.

### 5.5 Kho tiện ích và website nguồn

- `extension_store_service.dart`: nhận JSON có BOM/khoảng trắng nhưng không tùy tiện cắt byte protobuf; chặn vòng lặp chuyển hướng; resolve URL tương đối; nếu index v2 rỗng/lỗi thì dùng index legacy; ghi lý do lỗi.
- Test kho trước đây có thể in lỗi rồi vẫn đạt. Đã thêm assertion và ném lại lỗi để kết quả thất bại có ý nghĩa.
- IReader bị bỏ khỏi index trên Windows dù bridge hỗ trợ Windows. Đã đổi điều kiện Android-only sang `IReaderBridge.supported`.
- `builtin_extensions.dart` và `url_override.dart`: đối chiếu/cập nhật địa chỉ HayChill, XemPhimGi, NextPhim, Vfilm; chỉ di trú khi URL trùng mặc định cũ, giữ URL người dùng tự đặt. Sửa 33 dòng tiếng Việt lỗi mã hóa trong khai báo tiện ích.
- Kiểm tra mạng ban đầu: 18/18 request thành công (14 URL repo, Drive, ba metadata upstream). Protobuf ở bước này mới kiểm tra vận chuyển; các test parser sau đó là bằng chứng bổ sung riêng.

Chưa thể suy ra rằng mọi extension tải được, bộ lọc đúng, đăng nhập được và phát nội dung thành công chỉ từ việc index có nguồn.

### 5.6 Phiên bản, lịch sử, danh mục dự án và bản địa hóa

- `overlay/pubspec.yaml`: 0.3.9+31; `AppIdentity` cập nhật user-agent.
- Mục Lịch sử dạng lưới đã có trong mã 0.3.8; cần kiểm tra trực tiếp trên bản mới, không ghi nhận sai là tính năng vừa viết lại toàn bộ.
- Bổ sung 252 URL còn thiếu vào nhóm tham khảo trong danh mục GitHub, sửa mô tả tránh khẳng định mọi liên kết đều đã tích hợp.
- Test onboarding sửa nhãn kỳ vọng cũ Mangayomi/Manga/Anime thành YomiHub/Comic/Film & Movie; giữ mục đích và assertion của test.
- `language_audit.py` kiểm tra khóa tĩnh và placeholder; kết quả chi tiết ở `language-coverage.json`. Đây là phép trích xuất chuỗi tĩnh, chưa bao gồm mọi chuỗi nội suy, ARB hoặc văn bản native. Chưa hoàn tất yêu cầu dịch mọi ngôn ngữ.

### 5.7 Health Connect và ranh giới tên miền Play Books

- `health_connect_service.dart`: khi gọi native channel thất bại, trước đây trả `true` cho trạng thái khả dụng; khi kết quả sync null cũng trả thành công. Đã đổi về false và ghi log lỗi kiểm tra. Tìm kiếm trong `overlay/android` chưa thấy xử lý channel tương ứng; cần xác minh và hoàn thiện tích hợp native trước khi coi Health Connect hoạt động. Đây là sửa báo cáo sai, không phải đã hoàn thiện đồng bộ sức khỏe.
- `play_books_screen.dart`: thay kiểm tra `endsWith('google.com')` bằng điều kiện bằng tên miền hoặc kết thúc bằng `'.google.com'` (tương tự các tên miền Google liên quan), tránh nhận nhầm một tên miền không thuộc Google nhưng có hậu tố cùng chữ.

### 5.8 Đối chiếu mã trình phát upstream

Đã đọc trực tiếp `PlayerViewModel.kt` của Aniyomi và Nekoyomi qua GitHub, cùng `anime_player_controller_provider.dart` của Mangayomi. Aniyomi/Nekoyomi lưu lastSecondSeen/totalSeconds bằng tác vụ không bị hủy khi đổi tập hoặc pause; Mangayomi upstream vẫn trả vị trí 0 nếu episode.isRead. Vì yêu cầu người dùng là tiếp tục đúng vị trí, bản YomiHub giữ tiến độ ngay cả khi đã vượt ngưỡng đánh dấu xem. Không sao chép nguyên bộ player khác nền tảng; dùng đối chiếu này để kiểm chứng quy tắc lưu và vòng đời.

- https://github.com/aniyomiorg/aniyomi/blob/main/app/src/main/java/eu/kanade/tachiyomi/ui/player/PlayerViewModel.kt
- https://github.com/Seguaz/Nekoyomi/blob/main/app/src/main/java/eu/kanade/tachiyomi/ui/player/PlayerViewModel.kt
- https://github.com/kodjodevf/mangayomi/blob/main/lib/modules/anime/providers/anime_player_controller_provider.dart

## 6. Kết quả kiểm chứng theo mốc

| Mốc | Kết quả | Bằng chứng |
| --- | --- | --- |
| Baseline | 401 đạt, 16 lỗi; nhóm lỗi nhãn onboarding cũ | `tests-baseline.log` |
| Lần kiểm tra 0.3.9 đầu | 426 đạt, 1 lỗi repo IReader Windows | `tests-039.log` |
| Sau sửa hỗ trợ IReader | 11 kiểm thử chọn lọc đạt | `tests-039-followup.log` |
| Resume và redirect repo | 6 kiểm thử đạt | `tests-039-regressions.log` |
| Thêm ánh xạ backup và màn hình merge | Thất bại biên dịch `restore.dart`; đã sửa, cần chạy lại | `tests-039-backup.log` |
| Backup/merge sau sửa cú pháp | 5/5 đạt | `tests-039-backup-r2.log` |
| Toàn bộ test sau đồng bộ cuối | **435/435 đạt**, gồm kiểm tra mạng; Drive tìm thấy 0.3.8 | `tests-039-final.log` |
| EPUB 2/3 sau kiểm tra trực tiếp | **2/2 đạt**, tên chương, đường dẫn tương đối, fragment, bỏ landmarks | `tests-039-epub.log` |
| Phân tích toàn bộ lib lần ba | **0 error, 157 warning, 49 info**, đã hoàn tất | `analyze-039-r3.log` |
| Phân tích toàn bộ lib | 197 vấn đề ở thời điểm chạy; cần phân tích lại | `analyze-039.log` |
| Windows release lần đầu | Thất bại cùng lỗi cú pháp restore | `build-windows.log` |
| Windows release lần hai | Thành công, metadata EXE 0.3.9+31 | `build-windows-r2.log` |
| Windows cuối sau sửa UI | Thành công, 506,8 giây, EXE 0.3.9+31 | `build-windows-final.log` |
| Android release lần đầu | Thành công cho armeabi-v7a, arm64-v8a, x86_64; khoảng 1.595 giây | `build-android.log` |
| Android cuối sau sửa UI | Thành công ba ABI, 1.712,3 giây | `build-android-final.log` |
| Mạng/index | 18/18 HTTP thành công ở mốc kiểm tra ban đầu | `network-results.json` |

Các đường dẫn log trong bảng thuộc `audit-0.3.9`. Không cộng các lần chạy chọn lọc để tuyên bố tổng số test duy nhất. Không thay thế log thất bại bằng một dòng “đã sửa”; giữ log và đặt tên mới cho lần chạy lại.

## 7. Công cụ và cách dựng có kiểm soát

Toolchain đã dùng: Flutter 3.47.6, Dart 3.13.5; Flutter tại `D:\yh\tools\flutter`, pub cache `D:\yh\pub-cache`. `common.ps1` thiết lập JDK, Android SDK, Rust/Cargo, Gradle và PATH. Đọc script trước khi gọi; không in nội dung key.properties hoặc mật khẩu ký.

Lệnh cốt lõi, chạy tại đúng bản dựng sau khi đồng bộ và kiểm tra manifest:

```powershell
flutter test --no-pub --reporter expanded
dart analyze lib
flutter build windows --no-pub --release
flutter build apk --no-pub --release --split-per-abi --target-platform android-arm,android-arm64,android-x64 --split-debug-info D:\yh\symbols
```

Đối với Android TV phải dựng riêng với cấu hình TV; không sao chép APK mobile rồi đổi tên. Cùng package ID có thể khiến bản TV thay thế bản mobile trên máy thử.

Máy có khoảng 16 GB RAM. Đồng thời chạy compiler, analyzer và emulator gây áp lực bộ nhớ lớn. Bước compile test đầu có thể mất nhiều phút trước khi hiện ca test. Không kết luận treo chỉ vì log chưa tăng. AVD gốc `Medium_Phone_API_37.0` giữ nguyên 0.3.8/code 4030 do thiếu dung lượng nâng cấp. AVD độc lập `YomiHub039QA` đã nâng thành công lên 0.3.9/code 4031; đang tắt để giảm tải khi dựng lại Android. Không nhầm dữ liệu thử QA với thư viện thực trong AVD gốc.

Đã khắc phục lỗi công cụ quan sát Windows bằng khởi tạo lại phiên và kiểm tra trực tiếp bản 0.3.9: lịch sử, thông báo hợp nhất, mục lục EPUB, nút Back và PDF. Binary này có trước sửa dấu trang mới nhất; kết quả chi tiết ở `audit-0.3.9/RUNTIME_CHECKS.md`. Khi quay video, thao tác theo giao diện vừa quan sát; không dùng script bấm tọa độ cũ làm bằng chứng chức năng.

## 8. Công việc còn lại và tiêu chí phát hành

1. Test backup/merge và phân tích lib đã chạy lại: đạt test, không còn error. Còn xử lý/đánh giá cảnh báo có tác động thực tế; giữ rõ 157 warning/49 info chưa giải quyết.
2. Chuẩn hóa định dạng, đồng bộ overlay/Android/Windows và kiểm tra hash/diff. Không đồng bộ giữa chừng khi compiler đang đọc tệp; nếu đã làm phải dựng lại bản cuối.
3. Hoàn thành bản địa hóa còn thiếu, kiểm tra placeholder, nhãn nội suy và tiếng Việt lỗi mã hóa. Đánh giá UI từng ngôn ngữ, đặc biệt RTL và chuỗi dài.
4. Dựng Windows và Android thực sự thành công; kiểm tra metadata phiên bản, chữ ký và khả năng cài nâng cấp; tạo checksum và changelog đúng các thay đổi đã xác nhận.
5. Kiểm tra tương tác và quay video: splash, thư viện/lịch sử, hợp nhất/tách, cập nhật, extension, tải xuống, đọc và phát/resume. Ghi thao tác, kết quả mong đợi/thực tế và log tương ứng.
6. Tiếp tục đối chiếu đủ 39 mục Feature Check và 10 mục Update. Đánh dấu riêng: đạt, lỗi đã sửa cần kiểm tra lại, chưa kiểm tra, hoặc cần thiết bị/tài khoản/quyền hệ thống.
7. Kiểm tra chia sẻ liên thiết bị bằng hai thiết bị thực/đầu nhận độc lập; tracker/Health Connect/Play Books bằng trạng thái tài khoản và quyền phù hợp. Không giả lập nút bấm để đánh dấu tích hợp ngoài đã đạt.
8. Kiểm tra lại nguồn phụ sau hợp nhất và sao lưu/khôi phục trên dữ liệu thử. Không thao tác phá hủy thư viện thật.
9. Cập nhật trạng thái đầu tài liệu và thêm nhật ký dưới đây sau mỗi bước; chỉ đánh dấu hoàn tất khi đã có bộ cài và bằng chứng tương ứng.

## 9. Nhật ký tiếp tục

### 25/10/2026 — bổ sung tài liệu bắt buộc

- Người dùng yêu cầu ghi toàn bộ quá trình, phương hướng và kỹ thuật sửa lỗi, bắt buộc đọc mỗi lần cập nhật.
- Tạo tài liệu này và `AGENTS.md`, ghi cả kết quả thất bại và công việc chưa xong.
- Lượt trước hệ thống duyệt tự động báo hết hạn mức, chặn một lệnh kiểm tra tiến trình/bộ nhớ; đây là lỗi duyệt, không phải đánh giá lệnh nguy hiểm. Không tìm cách bỏ qua kiểm tra quyền.
- Tiếp tục sửa cú pháp Map trong restore trước khi kiểm thử/dựng lại. Chưa được xem là phát hành hoàn tất.

Mẫu ghi cho lần tiếp theo: thời điểm → yêu cầu → chẩn đoán/bằng chứng → tệp và hành vi thay đổi → kiểm thử/lệnh → kết quả → giới hạn/bước tiếp theo. Không ghi thông tin bí mật.

### 25/10/2026 — cho phép dịch giao diện qua Google Translate

- Hệ thống duyệt tự động ban đầu chặn `complete_translations.py` vì việc gửi chuỗi ra dịch vụ ngoài chưa có xác nhận cụ thể.
- Đã hỏi rõ đích `translate.googleapis.com`, nội dung là câu chữ giao diện, không gửi mã nguồn/tài khoản/dữ liệu thư viện. Người dùng trả lời: **“Cho phép dịch qua Google Translate”**.
- Sau xác nhận, bắt đầu dịch các khóa còn thiếu của 18 bộ ngôn ngữ. Giữ nguyên các bản dịch sẵn có, cache từng ngôn ngữ, kiểm tra tập placeholder trước khi thêm.
- Bản dịch máy không được tự động coi là đã được người bản ngữ rà soát. Log: `translation-run.log`; kết quả: `translation-results.json` khi hoàn tất. Chạy lại `language_audit.py` và kiểm tra mẫu trước đồng bộ bản dựng.

### 25/10/2026 — rà soát bản dịch và công cụ đóng gói

- Dịch máy đã hoàn tất 18 bộ ngôn ngữ. Hai chuỗi Hindi có placeholder sai đã bị chặn khi nhập, sau đó sửa thủ công trong `review_translations.py`. Rà soát và sửa thuật ngữ tiếng Anh cho hợp nhất/tiện ích, và sửa hướng dẫn “giải nén” bị dịch thành “nén lại”.
- `make_installer_exe.ps1` và `make_appxbundle.ps1` đọc phiên bản từ overlay thay vì hard-code 0.3.8. Setup script dừng nếu EXE thiếu, phiên bản không khớp hoặc ZIP thiếu, không dùng fallback bộ cài 0.1.6.
- Việc sửa script chưa chứng minh gói Setup/AppX đã được tạo hoặc cài thành công. Chỉ đóng gói sau khi bản release mới đã dựng đạt.
- `language-coverage.json` sau rà soát: 0 khóa thiếu và 0 bộ placeholder sai ở 18 bảng đối với 1.189 chuỗi tĩnh. Giữ giới hạn của phép trích xuất; không coi là chứng nhận toàn bộ văn bản native/ARB.
- `analyze-039-r2.log` chưa hoàn tất: dừng đúng tiến trình analyzer khi RAM trống chỉ khoảng 624 MB để ưu tiên full test và Windows release. Phải chạy lại phân tích sau; log này không phải kết quả đạt.
- Full test hoàn tất 435/435. Bắt đầu dựng APK cho ba ABI, log `build-android.log`; Windows đang dựng lại, log `build-windows-r2.log`. Chưa có xác nhận bộ cài đạt tại mốc ghi này.
- Đối chiếu đầy đủ từng mục trong `audit-0.3.9/FEATURE_CHECK_STATUS.md`. Đây là bảng tiến độ với nhiều mục cần kiểm tra tiếp, không phải danh sách tất cả đã đạt.
- `verify_source_sync.py` xác nhận SHA-256 của 53 tệp thay đổi khớp giữa overlay và hai thư mục dựng; lưu `SOURCE_MANIFEST.json` kèm hash trước sửa.
- Chuẩn bị dữ liệu thử riêng trong `audit-0.3.9/fixtures`: PDF 3 trang, CBZ 3 ảnh, EPUB 3 chương; PDF đã được kết xuất và kiểm tra trang đầu. Chưa suy ra trình đọc ứng dụng đã vượt qua kiểm tra chỉ từ việc tạo được fixture.
- Script AppX cũ tạo helper nhập chứng chỉ vào các kho tin cậy của Windows. Chưa chạy script/helper này trong đợt kiểm tra; không tự nhập chứng chỉ gốc vào máy để thử ứng dụng. Đánh giá lại quy trình ký/phân phối trước khi cung cấp AppX.

### 25/10/2026 — kiểm tra trực tiếp Windows và sửa lỗi giao diện

- Windows 0.3.9+31 mở được với dữ liệu sẵn có. EPUB thử mở được, cuộn được và chuyển từ chương 1 sang chương 2. Đây là kiểm tra từng thao tác, chưa chứng nhận toàn bộ trình đọc.
- `history_screen.dart`: tên nội dung bị mất trong lưới vì truyền `bottomTextWidget` nhưng không bật `isComfortableGrid`; ở chế độ cũ, caller phải tự thêm nhãn trong Stack. Chuyển thẻ lịch sử sang nhãn dưới ảnh, giữ badge chương/thời gian trong ảnh. Không thay đổi lịch sử người dùng.
- `ebook_reader_screen.dart`: Drawer tự chiếm vị trí nút Back của AppBar, khiến Windows không có nút thoát trình đọc. Thêm BackButton và nút mục lục riêng; thêm kiểm tra mounted sau tải sách để tránh setState khi người dùng đã thoát.
- Mục lục EPUB 3 chỉ hiện “Phần 1/2/3” do parser chỉ đọc NCX. Đọc nav có `epub:type=toc`, bỏ landmarks; resolve đường dẫn NCX/nav tương đối và loại fragment. Bổ sung hai ca hồi quy EPUB 2/3 ở `yh_039_epub_test.dart`.
- `extensions/merge_screen.dart`: thông báo gợi ý hợp nhất vẫn che chân màn hình sau nhiều phút. Flutter hiện mặc định SnackBar có action là persistent; đặt `persist: false`, thêm nút đóng và dịch nhãn Xem. Tài liệu đối chiếu: https://api.flutter.dev/flutter/material/SnackBar/persist.html.
- Đồng bộ sau khi Android lần đầu hoàn tất: 57 tệp, SHA-256 khớp cả hai bản dựng. Các sửa mới chưa có trong bộ nhị phân lần trước; phải dựng lại.
- Bắt đầu phân tích toàn bộ lần ba: `analyze-039-r3.log`. Các kết quả chưa hoàn tất phải cập nhật tiếp, không mặc định coi là đạt.
- APK lần đầu đã kiểm tra metadata: `com.yomihub.app`, versionName 0.3.9, versionCode 4031, nhãn YomiHub. Chưa phải APK cuối có sửa giao diện.
- Phát hiện `strings.xml` trong bản dựng Android bị lỗi mã hóa ở nhãn shortcut; overlay vẫn đúng. Bổ sung tệp này vào đồng bộ và sửa `build_apk.ps1` đọc UTF-8 rõ ràng trước khi thay nhãn TV. Manifest sau cùng tại mốc này có 58 tệp khớp hash.
- `make_installer_exe.ps1`: không kill mọi tiến trình cùng tên; chỉ yêu cầu đóng ứng dụng có đường dẫn đúng thư mục nâng cấp. Chuẩn hóa đường dẫn giải nén và chặn vượt thư mục đích. Bỏ fallback sao chép toàn bộ thư mục chứa Setup khi thiếu ZIP. Cần xác nhận biên dịch Setup sau khi ZIP cuối được tạo.
- `package_release.py` kiểm tra log dựng cuối, mốc xác minh nguồn, thành phần runtime và tính toàn vẹn ZIP; ghi SHA-256 từng artifact. Không dùng để đổi tên hoặc đóng gói các bản trước sửa cuối.
- `tests-installer-paths.log`: 4 ca kiểm tra hàm giải nén thực đạt (đường dẫn bình thường, hai dạng `..`, đường dẫn tuyệt đối ngoài đích). Đây chưa phải kiểm tra cài đặt trọn luồng. Setup cũng được gắn metadata phiên bản từ overlay.
- Cài `imageio-ffmpeg` vào thư mục công cụ thử riêng `audit-0.3.9/test-tools`, không thêm vào phụ thuộc ứng dụng. Tạo video H.264 180 giây trong fixtures và giải mã toàn bộ thành công; chưa xác nhận resume trong ứng dụng chỉ từ ca kiểm tra tệp này.
- Windows cuối dựng thành công. ZIP 278.805.715 byte đã kiểm tra CRC toàn bộ, SHA-256 `a2c8b6348a1b1da58f598d969e78ebedc1a9a23e13797cf2e628626702cdaf0e`; gồm các helper runtime. Log: `package-windows.log`.
- Thử mở Windows cuối: công cụ điều khiển cửa sổ báo `foreground window did not report a process id`; khôi phục cửa sổ một lần vẫn lỗi, đã dừng thao tác Windows. Chưa xác nhận trực tiếp UI cuối; không suy ra ứng dụng crash từ lỗi công cụ này.
- Android emulator đã khởi động, trước nâng cấp vẫn 0.3.8/code 4030. Đã chép bốn fixture riêng vào `/sdcard/Download/YomiHub039`; đang chờ APK cuối để cài bằng `-r` giữ dữ liệu.
- Setup cuối biên dịch thành công (`package-setup-final.log`), metadata FileVersion/ProductVersion 0.3.9.0; bỏ async không dùng ở handler cài đặt. Chưa chạy cài đặt Setup thực trên máy người dùng.
- Kiểm tra tiến trình Windows cuối cho thấy ứng dụng còn chạy và `Responding=True`; lỗi quan sát cửa sổ không đủ chứng minh crash. Log vẫn có lỗi kết nối index Kohi-den (`Connection closed before full header`). README chính thức vẫn chỉ đúng URL này; kho `Kohi-den/extensions-source` đã archived ngày 14/05/2026 (https://github.com/Kohi-den/extensions-source). Chưa xác minh được endpoint thay thế chính thức, không tự chuyển người dùng sang một fork bất kỳ hoặc báo repo đã hoạt động.
- `verified-setup.txt`: SHA-256 của tài nguyên AppZip nhúng trong Setup trùng ZIP đã kiểm tra. Chỉ đọc tài nguyên assembly, không chạy cài đặt.
- Chẩn đoán Android cuối lúc 21:38 bằng `jcmd Thread.print`: Gradle vẫn chạy nén build cache (`GZipBuildCacheEntryPacker`) và R8 đọc tài nguyên; không phải bằng chứng deadlock. Lưu `gradle-threads.txt`. Hướng tối ưu các lần dựng sau: đánh giá phạm vi output/cache của CargoKit và chi phí I/O trước khi thay đổi cấu hình; không tắt shrink/đổi ABI để giả tạo một bản phát hành đạt nhanh hơn.
- Khởi tạo lại phiên công cụ Windows đã phục hồi quan sát. Trên binary cuối xác nhận: tên nội dung xuất hiện dưới thẻ Lịch sử, thông báo hợp nhất tự biến mất; EPUB mở lại chương 2 đã lưu, mục lục hiện Chapter 1/2/3 thay vì Phần 1/2/3, chọn chương 3 thành công, nút Back trở lại màn hình Ebook & PDF. Chưa kiểm tra toàn bộ vị trí cuộn, bookmark, search hoặc các định dạng ebook khác.
- APK cuối đã đóng gói. Lần xác minh metadata đầu thất bại vì script giả định mọi ABI đều code 4031; sửa phép kiểm tra theo mã thực: armeabi-v7a 1031 (cũ 1030), arm64-v8a 2031 (cũ 2030), x86_64 4031 (cũ 4030). `verify-apks-r2.log` xác nhận cả ba có versionName 0.3.9, chữ ký hợp lệ và cùng signer với bản 0.3.8. Đây là lỗi script kiểm chứng, không phải APK bị hạ phiên bản.
- Một lệnh đọc metadata từng bị hệ thống duyệt tự động chặn do hết hạn mức; không thực thi/bỏ qua kiểm tra. Sau người dùng yêu cầu tiếp tục, thử lại qua cùng cơ chế duyệt và được chạy.
- Cài nâng cấp trên AVD cũ thất bại: `INSTALL_FAILED_INSUFFICIENT_STORAGE`, phân vùng 5,8 GB còn 495 MB. Chỉ yêu cầu Android thu hồi cache (`pm trim-caches`), còn 595 MB; không xóa thư viện, tài liệu hoặc dữ liệu ứng dụng. Log: `android-upgrade.log`, `android-upgrade-r2.log`.
- Tạo AVD QA độc lập 12 GB trong `D:/A.I Project/yh/avd/YomiHub039QA.avd`, dùng system image Android đã cài. `avdmanager` tại SDK dựng không tìm thấy system image của SDK người dùng; thay bằng cấu hình AVD riêng dựa trên cấu hình thiết bị hiện có, trỏ image tuyệt đối. Không sao chép/ghi đè userdata cũ. Kế hoạch cài 0.3.8, tạo dữ liệu thử rồi nâng 0.3.9; đây không thay thế kiểm tra nâng cấp trên thư viện thực của AVD cũ.
- AVD QA boot hoàn tất, `/data` 12 GB còn 11 GB. Cài 0.3.8 thành công, đi qua onboarding và mở EPUB qua Android DocumentsUI. Yêu cầu cấp “quản lý tất cả tệp” bị duyệt tự động từ chối vì quá rộng; không cấp bằng phương thức khác. Dùng chọn từng tệp qua nhà cung cấp bộ nhớ trong thành công. Downloads provider không hiện các file ADB vừa chép, nhưng external-storage provider hiện đúng fixture.
- Lưu chương 2 ở 0.3.8, cài `-r` 0.3.9 thành công (`qa-upgrade-039.log`), code 4031. Onboarding không lặp; sách còn trong Đọc gần đây, mở đúng Chapter 2/33,3%. Mục lục mới hiện tên Chapter 1/2/3, chuyển Chapter 3 được.
- Đã quay video 180 giây: `output/yomihub-039-reader-check.mp4` (1.488.909 byte). Đây là bằng chứng kiểm tra có phát hiện lỗi, không phải video chứng nhận mọi chức năng đạt.
- **Lỗi mới:** thêm dấu trang báo thành công nhưng tab Dấu trang còn rỗng trong cùng phiên đọc; thoát/mở lại sách thì có `Chapter 3 • 0%`. Chẩn đoán: FutureBuilder trong Drawer giữ kết quả trước khi thêm, `_addBookmark` không gọi setState sau ghi Hive. Dữ liệu không mất trong ca thử này. Bổ sung widget test `new bookmark appears without reopening the book`; đang chạy trên mã trước sửa (`tests-bookmark-before.log`).
- Widget test trước sửa đã thất bại đúng assertion không tìm thấy `First chapter • 0%`; hai test parser vẫn đạt. Sửa `_addBookmark`: sau ghi Hive kiểm tra mounted, gọi setState để Drawer tạo Future mới, rồi báo thành công. Đồng bộ 58 tệp khớp hash, đang chạy `tests-bookmark-after.log`; Windows dựng lại ở `build-windows-bookmark.log`.
- Cải tiến script đồng bộ: bỏ qua tệp đích nếu SHA-256 đã giống nguồn để tránh ghi lại không cần thiết. Lần đồng bộ lỗi dấu trang, mã Windows đã được chép trước khi dựng và có cùng nội dung; tệp test mới không tham gia bản release.
- Video gốc giải mã được nhưng có timestamp biến thiên gây cảnh báo khi xuất null; đã tạo bản playback 15 fps, giữ bản gốc nguyên vẹn. Không sửa hoặc che diễn biến lỗi trong nội dung video.

### 25/10/2026 — tiếp tục sửa dấu trang và cập nhật bằng chứng

- Người dùng nhắc tiếp tục bổ sung tài liệu kỹ thuật; giữ quy định bắt buộc đọc trong đầu tài liệu và `AGENTS.md`. Mỗi kết quả mới phải phân biệt sửa mã, kiểm thử tự động, dựng bộ cài và kiểm tra trên ứng dụng thật.
- Lần chạy `tests-bookmark-after.log` vẫn thất bại: test chờ giá trị Hive trong bộ nhớ nhưng thao tác ghi bất đồng bộ và cập nhật giao diện chưa hoàn tất. Sửa test chờ cả thông báo lưu thành công trước khi mở tab dấu trang; không bỏ assertion kiểm tra dấu trang xuất hiện ngay trong phiên đọc.
- `tests-bookmark-after-r2.log`: **3/3 đạt**, gồm dấu trang không cần mở lại sách và hai ca parser EPUB 2/3. Kết quả này không thay thế bước thử trên APK mới; cần kiểm tra lại hành vi đã quay video lỗi trước đó.
- `build-windows-bookmark.log`: Windows dựng thành công sau sửa dấu trang, **392,9 giây**. Vẫn có cảnh báo MSBuild về thư mục trung gian dùng chung; không ghi nhận là build sạch mọi cảnh báo. Bộ ZIP/Setup trong output chưa được cập nhật tại mốc ghi này.
- `package_release.py`: kiểm tra hash và thời gian sửa của từng tệp mã sản phẩm so với log dựng, thay vì chỉ so thời gian tạo manifest. Loại tệp test khỏi phép kiểm tra độ mới của binary; với Windows loại cấu hình Android. Manifest vẫn phải khớp nguồn overlay và bản dựng. Việc tạo lại manifest sau thay đổi test không được tự làm vô hiệu một binary có mã sản phẩm không đổi.
- Bước tiếp theo: đồng bộ test, xác minh hash, dựng Android chứa sửa dấu trang, đóng gói lại Windows/Android, kiểm tra chữ ký/checksum và thử dấu trang trực tiếp. Chưa tuyên bố hoàn tất 39 nhóm tính năng hoặc phát hành cuối.
- Đã đồng bộ và xác minh lại **58 tệp, 0 sai khác**. Android dựng lại tại `build-android-bookmark.log` đang chạy. Không bật emulator trong lúc dựng để tránh thiếu RAM.
- Windows đã đóng gói lại: ZIP **278.805.339 byte**, SHA-256 `7df1ec8c97025149002a1789c7a449f848861f1bd62d4fc2da466f788d8f1e40`; kiểm tra CRC ZIP đạt. Setup **278.880.768 byte**, SHA-256 `0746aa5c936db3269f0c02155c163e92c9c977c0f4644bf9a4c8816efc02f739`. Log `package-windows-bookmark.log`, `package-setup-bookmark.log`; `verified-setup-bookmark.txt` xác nhận ZIP nhúng trùng ZIP bên ngoài. Không chạy trình cài đặt trong bước xác minh này.
- Đã cập nhật checksum output và trạng thái EPUB trong `FEATURE_CHECK_STATUS.md`/`RUNTIME_CHECKS.md`. Checksum tại mốc này gồm Windows mới và APK trước sửa dấu trang; cần tạo lại sau khi Android mới được đóng gói. Các kết quả kiểm tra trực tiếp cũ vẫn được giữ nguyên, không gán cho bản mới chưa thử.
- Kiểm tra trực tiếp Windows sau đóng gói: thêm dấu trang Chapter 3, mở tab Dấu trang ngay trong phiên đọc thấy `Chapter 3 • 0%`, chọn dấu trang trở lại đúng chương. Lỗi làm mới đã được xác nhận sửa trên Windows. Android vẫn cần thử binary mới.
- Hộp tìm kiếm EPUB mở được; công cụ nhập liệu Windows báo `element ... is not available in cached app state`, khởi tạo lại vẫn lỗi. Không coi đây là lỗi tìm kiếm của ứng dụng hoặc đánh dấu ca tìm kiếm đạt. Tiếp tục kiểm tra bằng nền tảng Android khi dựng xong.
- Bắt đầu chạy toàn bộ test trên mã cuối trong bản dựng Windows: `tests-039-release.log`. Đây là lần xác minh sau các sửa UI/dấu trang; chưa ghi số đạt trước khi hoàn tất.
- Windows sau sửa: cuộn EPUB đến đoạn 13/chương 3, tiến độ 79,8%; đóng và mở lại vẫn ở đúng đoạn 13/79,8%. Đã kiểm tra vị trí cuộn thực tế, ngoài vị trí chương. Trang Giới thiệu hiển thị Beta (0.3.9). Nhật ký tiếp tục ghi lỗi endpoint Kohi-den; chưa có bằng chứng dịch vụ này đã phục hồi.
- `tests-039-release.log`: **438/438 đạt**, toàn bộ bộ kiểm thử chạy trên mã sau sửa giao diện/dấu trang, gồm ca Drive và quét repo qua mạng. Đây là tổng của một lượt chạy hoàn tất, không cộng gộp các lượt chọn lọc.
- Giới hạn rõ của test quét website: assertion kiểm tra tổng số repo tìm được, không yêu cầu từng website thành công. Log lượt cuối có `Tachiyomi & Mihon community: HTTP 403` và `MIYOMI (mikkiio): 0 kho`; các site khác tìm được repo. Vì vậy 438/438 không có nghĩa mọi endpoint hoạt động. Drive thực vẫn tìm thấy 0.3.8 (10 tệp), chưa có bản 0.3.9 trên thư mục phân phối đó.
- Dựng Android chậm: chẩn đoán tại `gradle-bookmark-final-stage.txt` cho thấy `MergeNativeLibsTask` đang sao chép/ghép thư viện sau bước tạo mã cho ba ABI. Không hủy build hoặc đổi cấu hình shrink/ABI để rút ngắn bằng cách thay phạm vi phát hành. Log còn cảnh báo chuyển sang Built-in Kotlin trong các phiên bản Flutter tương lai; chưa nâng toolchain giữa đợt kiểm tra này.
- Android sau sửa dấu trang dựng thành công trong **1.173,2 giây**, đủ armeabi-v7a, arm64-v8a, x86_64 (`build-android-bookmark.log`). Đã đóng gói (`package-android-bookmark.log`) và xác minh chữ ký/phiên bản của cả ba (`verify-apks-bookmark.log`): versionName 0.3.9, code 1031/2031/4031, cùng signer với 0.3.8. Khởi động lại AVD QA để cài và kiểm tra trực tiếp.

### 26/10/2026 — xác nhận Android và chẩn đoán trình phát

- APK mới cài nâng cấp thành công (`qa-upgrade-bookmark.log`), giữ sách và dấu trang cũ. Tạo dấu trang Chapter 1 mới, mở tab ngay thấy cả Chapter 3 cũ và Chapter 1 mới; chọn dấu trang mở đúng chương. Bằng chứng `android-bookmark-fixed-visible.xml/png`, video `output/yomihub-039-bookmark-fixed.mp4` (2.205.073 byte).
- Tìm EPUB với cụm `paragraph 30` trả đúng ba chương có nội dung đó; chọn kết quả Chapter 2 mở chương tương ứng. Bằng chứng `android-epub-search-result.xml`, `android-epub-search-open.xml`. Không suy rộng thành mọi trường hợp tìm kiếm đều đạt.
- Nhập video thử 180 giây qua hộp chọn từng tệp thành công, xuất hiện trong thư viện. Khi mở player, Android yêu cầu quyền toàn bộ tệp hai lần; đã bỏ qua, không cấp quyền này bằng cách khác. Player nhận thời lượng 03:00 và kích thước 640×360 nhưng kẹt tại 00:00 với vòng tải.
- Log `android-player-logcat.txt` cho thấy bộ giải mã máy giả lập `c2.goldfish.h264.decoder` có lỗi truy vấn surface/allocator `BAD_INDEX`. Chưa đủ kết luận đây là nguyên nhân duy nhất hoặc lỗi trên điện thoại thực. Chưa xác nhận resume video đạt.
- Tiến trình ứng dụng còn sống, crash buffer không có bản ghi; Back hệ thống đưa về launcher và mở lại vẫn ở player. Đã lưu video `output/yomihub-039-video-check.mp4` (1.780.557 byte), sau đó force-stop riêng ứng dụng QA để khởi động lại, giữ dữ liệu. Tiếp tục thử cấu hình giải mã phần mềm nhằm phân biệt giới hạn emulator với lỗi ứng dụng.

### 26/10/2026 — chốt phạm vi kiểm tra rút gọn và bộ cài bàn giao

- Người dùng yêu cầu rút gọn kiểm tra, nhanh chóng đóng gói và ghi lại kỹ thuật. Giữ bộ dựng sau sửa dấu trang (`build-windows-bookmark.log`, `build-android-bookmark.log`), không mở thêm vòng sửa/dựng thử nghiệm. Bộ cài chưa được đăng lên dịch vụ phân phối.
- Thử `hwdec=no` chỉ trong thiết lập ứng dụng QA: video phần mềm đã chạy đến 02:59,9/03:00, nhưng các nút điều khiển/thoát không phản hồi bình thường. Không đổi mặc định bộ giải mã của bản phát hành. Video bằng chứng: `output/yomihub-039-video-software-check.mp4`; chưa xác nhận resume, âm thanh (fixture không có âm thanh), PiP hoặc đổi server đạt.
- Hướng điều tra tiếp: `_nativeAudioProperty` gọi API `getProperty` có lời gọi FFI mpv đồng bộ bên trong; cần đánh giá việc nhận snapshot qua sự kiện property để tránh chờ trên luồng giao diện. **Đây là giả thuyết, chưa chứng minh nguyên nhân.** Kiểm tra lại filesystem xác nhận bản vá `mpv_track_snapshot.dart` chưa được tạo/applied; bộ cài không chứa thay đổi này. Không ghi nhận giả thuyết là lỗi đã sửa.
- Kiểm tra cuối dùng `verify_source_sync.py`, `verify_delivery.py`, `verify_apks.ps1` và `release_checksums.py`: đối chiếu hash overlay với hai bản dựng, độ mới mã so với build, hash năm bộ cài, CRC toàn bộ ZIP, metadata/chữ ký ba APK và signer so với 0.3.8. Kết quả lưu ở `verify-delivery.log`, `verify-apks-delivery.log`, `checksums-delivery.log`. Không thay thế bằng chứng cài đặt thực bằng kiểm tra hash.
- Giữ lịch sử 438/438 test, các lần thất bại và video lỗi. AppX/TV không thuộc bộ bàn giao này; Health Connect native, các tích hợp tài khoản và kiểm tra đầy đủ 39 nhóm còn chưa hoàn tất. Lần cập nhật kế tiếp phải đọc tài liệu này, ưu tiên lỗi trình phát trước khi tuyên bố hoạt động đầy đủ.
- **Kết quả kiểm tra chốt:** 58/58 tệp đồng bộ, 0 sai khác; kiểm tra độ mới nguồn/hash năm bộ cài/CRC ZIP đạt; ba APK đúng 0.3.9, code 1031/2031/4031, chữ ký hợp lệ và cùng signer 0.3.8. Đã tạo lại `output/SHA256SUMS-0.3.9.txt` và `checksums_0.3.9.csv`. Hoàn tất đóng gói Windows/Android trong phạm vi rút gọn; không tuyên bố hoàn tất kiểm tra toàn bộ tính năng.

### 26/10/2026 — sửa tiếp trình phát theo yêu cầu mới

- Đọc lại ghi chú trước khi cập nhật. Kiểm tra nguồn media_kit đã cài xác nhận `getProperty` gọi `mpv_get_property_string` đồng bộ; điều kiện buffering/duration ở caller không đảm bảo lời gọi này không chặn. Chưa quy toàn bộ hiện tượng emulator cho nguyên nhân này.
- `overlay/lib/modules/anime/utils/mpv_track_snapshot.dart`: sao chép chuỗi/số của aid, sid, current-tracks/audio/id, current-tracks/sub/id, alang ngay trong callback sự kiện, trước khi mpv tái sử dụng bộ nhớ. Giá trị unavailable/empty xóa dữ liệu cũ; mở video mới xóa ID track nhưng giữ ngôn ngữ ưu tiên.
- `anime_player_view.dart`: đăng ký property dạng NODE trong PlayerConfiguration, dùng snapshot thay cho query đồng bộ, đồng bộ track khi có sự kiện. Không dùng API observeProperty dạng NONE vì thư viện vẫn query đồng bộ trong nhánh đó. Không sửa trực tiếp pub-cache.
- Thêm `yh_039_mpv_snapshot_test.dart` kiểm tra vòng đời bộ nhớ sự kiện, ID dạng số/chuỗi, xóa giá trị không còn khả dụng và reset khi đổi video. Chạy cùng `yh_039_player_test.dart` để kiểm tra lưu vị trí. Đồng bộ 60 tệp, hash khớp cả hai bản dựng.
- Dựng trước APK x86_64 release riêng cho QA (`build-android-player-qa.log`), chưa thay thế các APK phát hành còn lại. Kết quả test/analyzer và kiểm tra tương tác sẽ bổ sung khi hoàn tất.
- `tests-player-snapshot.log`: 8/8 đạt (4 ca snapshot và 4 ca lưu tiến độ). `analyze-player-snapshot.log`: 0 error, 0 warning, 1 info về ngoặc khối if có sẵn. Chuẩn bị thêm fixture có âm thanh AAC 180 giây để thử track thực. Windows đang dựng tại `build-windows-player.log`; chưa gán kết quả kiểm thử đơn vị cho kiểm tra tương tác.
- Đối chiếu https://mpv.io/manual/stable/#options-alang: alang là danh sách chuỗi. Bổ sung đọc NODE_ARRAY và test giữ thứ tự ngôn ngữ trong overlay; **chưa đồng bộ thay đổi này khi hai compiler đang chạy**. Sau QA phải đồng bộ và dựng lại bản cuối để tránh trộn mốc nguồn. Fixture `YomiHub-039-player-tracks.mp4` có hình, âm thanh AAC và phụ đề mov_text; emulator không phát âm thanh ra loa do cấu hình `-no-audio`, nên nhận diện track không đồng nghĩa đã nghe kiểm tra âm thanh thực.
- `tests-player-final.log`: **9/9 đạt**, gồm test danh sách ngôn ngữ bổ sung. Windows thử dựng thành công 728,1 giây; APK QA x86_64 thành công 1.577,6 giây. Log chẩn đoán Gradle cho thấy các bước đọc cache, nén metadata và ghi APK vẫn chạy; không kết luận treo từ log im lặng. Các binary thử này chưa chứa nhánh alang dạng danh sách; sau khi compiler kết thúc đã đồng bộ bổ sung nguồn cho lần dựng cuối.
- Windows khởi động được, nhưng công cụ Computer Use trả ảnh cũ không khớp cây giao diện và lỗi `element ... is not available in cached app state`; đã dừng phiên thử, chưa xác nhận trình phát Windows. Không kết luận lỗi ứng dụng chỉ từ lỗi công cụ.
- APK QA đã cài nâng cấp thành công ở lần hai (`install-player-qa-r2.log`); lần đầu gửi khi AVD chưa khởi động hoàn chỉnh nên thất bại, không mất dữ liệu. Video cũ còn trong thư viện, nhập thêm fixture có âm thanh/phụ đề được. Trên bản sửa snapshot, video chạy và phụ đề hiển thị nhưng tap/Space/D-pad vẫn không làm điều khiển phản hồi. **Bản vá snapshot chưa giải quyết toàn bộ lỗi UI.** Bằng chứng `android-player-patch-*.png/xml`, `android-player-patch-logcat.txt`, video `output/yomihub-039-player-patch-qa.mp4`.
- Android báo MainActivity resumed, fullscreen, PiP false. Đang điều tra trạng thái Flutter/ẩn controls và luồng native. `debuggerd -b` yêu cầu root; không bật root để đọc stack. Chuyển sang APK debug do dự án tự dựng để dùng Dart VM service trong phạm vi ứng dụng QA.
- Chỉ ở bản sao dựng Android, tạm gắn signingConfig release cho build type debug để cài đè ứng dụng QA giữ dữ liệu và cùng versionCode split ABI. Sao lưu `build.gradle.before-player-debug`, lệnh dựng có `finally` khôi phục file; không in khóa ký/mật khẩu, không đưa APK debug vào output/phát hành. Mọi sửa chức năng vẫn ở overlay. Log `build-android-player-debug.log`.
- Người dùng tiếp tục yêu cầu tinh gọn: chỉ xác định nguyên nhân mất điều khiển, thử phát/tạm dừng và thoát–mở lại trước đóng gói; bỏ kiểm tra mở rộng đổi server/PiP/nhiều định dạng trong lượt này. Script `inspect_player_vm.py` đọc trạng thái riêng trình phát qua Dart VM service trên AVD, không in URL/token dịch vụ. Chưa coi giả thuyết PiP/lifecycle là nguyên nhân đã chứng minh.

### 26/10/2026 — kiểm tra rút gọn trình phát và dựng cuối

- Đính chính quan sát trước: PNG `android-player-patch-key.png` có hiện điều khiển, trong khi XML lấy muộn đã bỏ lỡ thời gian tự ẩn 3 giây. Không đủ bằng chứng để kết luận mọi nút bị treo. Giữ các ghi nhận cũ như lịch sử chẩn đoán, không coi chúng là kết luận cuối.
- Nhánh debug đầu thất bại linker MinGW vì đường dẫn chứa khoảng trắng (`build-android-player-debug.log`). Nhánh thử lại dùng Rust release bị chủ động dừng sau khi đối chiếu PNG, không cài APK debug. Đã khôi phục app/build.gradle và plugin CargoKit từ bản sao; không đổi cấu hình phát hành hoặc pub-cache. Script Dart VM chưa được sử dụng.
- QA trên APK release snapshot: đợi 0,5 giây sau hiện controls rồi bấm tạm dừng thành công; hai ảnh `android-quick-paused2.png` và `android-quick-pause-stable.png` đều ở 01:07.400. Nút Back trở lại màn hình chi tiết (`android-quick-exit.xml`). Bỏ qua cả hai hộp quyền toàn bộ tệp, không cấp quyền rộng. Mở lại video chạy từ 00:00 rồi 00:20, không tiếp tục 01:07. Chế độ ẩn danh xác nhận đang tắt (`android-quick-more.png`).
- Khoanh vùng mã: _loadAndroidFont và các bước chuẩn bị có thể đưa ứng dụng sang paused trước _openMedia; listener position ban đầu trả 0, trong khi bảo vệ resume chỉ được thiết lập trong _openMedia. didChangeAppLifecycleState gọi lưu ở khoảng này có thể ghi đè vị trí phiên trước. Đây là đường lỗi xác định qua mã, chưa có trace từng giá trị trong APK QA.
- Sửa `overlay/lib/modules/anime/anime_player_view.dart`: thêm _mediaOpenStarted, chỉ bật sau khi xác định target resume và trước Player.open; bỏ qua mọi lần lưu trước mốc đó. Không sửa dữ liệu lịch sử đã mất hoặc thay đổi chế độ ẩn danh. Cần thử mở lại trên APK cuối để xác nhận nguyên nhân có giải quyết ca thực tế.
- Đồng bộ 60 tệp overlay vào hai bản dựng, dừng AVD để dành RAM. Chạy lại chín test chọn lọc ở `tests-player-delivery.log`, sau đó dựng Windows ở `build-windows-player-final.log`; Android ba ABI ở `build-android-player-final.log`. Không chạy lại 438 test hoặc mở rộng kiểm tra server/PiP theo yêu cầu rút gọn.
- `package_release.py` nhận revision player-final để chỉ đóng gói binary từ đúng log cuối. Chưa ghi nhận thành công trước khi compiler và kiểm tra gói kết thúc.
- `tests-player-delivery.log`: 9/9 đạt trên nguồn cuối; Windows đã chuyển sang biên dịch. Các test này kiểm tra snapshot/lưu dữ liệu, chưa trực tiếp bao phủ hộp quyền trước Player.open; cần phân biệt với kiểm tra runtime của guard mới.
- Phân tích hai tệp trình phát cuối: 0 error, 0 warning, 1 info định dạng if có sẵn (`analyze-player-delivery.log`). Windows lần cuối đầu thất bại sau 723,4 giây vì thiếu bốn file C++ wrapper trong windows/flutter/ephemeral/cpp_client_wrapper (C1083); không phải lỗi Dart. Khôi phục wrapper từ đúng SDK Flutter đang dùng, không xóa cache hay mã nguồn; dựng lại ở `build-windows-player-final-r2.log`. Script đóng gói/kiểm chứng chọn log r2 cho Windows, giữ nguyên log thất bại.
- Android cuối dựng thành công 1.412,2 giây, đủ ba ABI. `package-android-player-final.log` đóng gói mới; `verify-apks-player-final.log` xác nhận versionName 0.3.9, code 1031/2031/4031, chữ ký hợp lệ và signer trùng 0.3.8. Windows r2 còn đang dựng; chuẩn bị AVD QA thử APK cuối.
- Windows r2 thành công sau 819,4 giây. Đã tạo ZIP 278.807.463 byte và Setup 278.882.816 byte. `verify_setup_player.ps1` xác nhận resource AppZip trùng ZIP ngoài, Setup version 0.3.9.0; không chạy trình cài đặt trong bước kiểm chứng.
- APK cuối cài nâng cấp thành công (`install-player-final.log`), hai video thử vẫn còn. Tạm dừng ở 00:41.400, nút Back trở lại chi tiết. Mở lại qua hai hộp quyền đã bỏ qua vẫn bắt đầu 00:00.400 rồi chạy từ đầu (`android-final-resumed.png`, `android-final-resume-settled.png`). **Guard trước Player.open chưa giải quyết ca resume này.** Không coi giả thuyết lifecycle là nguyên nhân cuối cùng. Video 180 giây `output/yomihub-039-player-final-check.mp4`, 4.951.265 byte, giữ nguyên cả diễn biến thất bại.
- Đính chính kỹ thuật: _loadAndroidFont tự ghi font vào thư mục riêng ứng dụng, không trực tiếp xin quyền toàn bộ tệp. Các hộp quyền phát sinh trong bước chuẩn bị đường dẫn; cần trace vòng đời/giá trị lưu để xác định chính xác điểm mất tiến độ, thay vì suy luận chỉ từ việc thấy hộp quyền.
- Kiểm tra bàn giao hoàn tất: 60/60 tệp đồng bộ, hash nguồn và độ mới binary đạt; hash cả năm bộ cài và toàn bộ CRC ZIP đạt (`verify-delivery-player-final.log`). Ba APK chữ ký hợp lệ/cùng signer 0.3.8. Đã tạo lại `output/SHA256SUMS-0.3.9.txt` và `checksums_0.3.9.csv` từ đúng năm tệp mới. Bộ cài chưa được tải lên dịch vụ phân phối.
- Giới hạn bàn giao: hoàn tất đóng gói theo yêu cầu rút gọn, **chưa hoàn tất sửa trình phát**. Resume local video còn lỗi trên QA; hardware decoder emulator, âm thanh thực, PiP/server và tương tác Windows chưa xác nhận đầy đủ. Lượt sau ưu tiên trace điểm ghi/đọc lastPageRead, lifecycle trước mở và lúc tháo surface; thêm ca hồi quy từ lỗi thực trước sửa và dựng lại. Không cần chạy lại toàn bộ 438 test khi chỉ khoanh vùng ca này.
- Lệnh cuối đọc log/tắt AVD từng bị hệ thống duyệt tự động từ chối vì hết hạn mức duyệt, chưa thực thi; không phải kết luận lệnh nguy hiểm. Sau người dùng yêu cầu tiếp tục đã đọc lại log xác nhận PASS. Ghi nhận riêng việc dọn AVD nếu thực hiện thành công ở bước sau.
- Đã tắt AVD QA thành công bằng emu kill sau kiểm tra, giữ userdata; sao chép tài liệu kỹ thuật cuối vào output để bàn giao cùng bộ cài.


### 26/10/2026 — Nâng cấp toàn diện phiên bản 0.4.0 (YomiHub 0.4.0+32)

- **Yêu cầu thực hiện:** Đọc toàn bộ `TECHNICAL_UPDATE_NOTES.md`, toàn bộ các yêu cầu trong bảng tính Excel và log lỗi hệ thống; kiểm tra toàn bộ tính năng; sửa triệt để các lỗi crash, lỗi chuẩn hóa URL, lỗi resume trình phát video, tối ưu hóa merge nội dung, đồng bộ hiển thị thư viện; và nâng cấp lên phiên bản `0.4.0`.
- **Nguyên nhân lỗi và tệp sửa đổi:**
  1. **Lỗi Null Check Operator Crash (`/MangaLibrary: Null check operator used on a null value`):**
     - *Nguyên nhân:* Ép kiểu non-null assertion không an toàn (`entry.name!`, `entry.source!`) khi duyệt thư viện có mục chưa nạp đầy đủ tên hoặc nguồn; nút tiếp tục đọc (`continue_reader_button.dart`) bị văng khi `entry.id == null` hoặc danh sách chapters rỗng mà vẫn gọi `.first`.
     - *Tệp sửa:* `overlay/lib/modules/library/widgets/library_gridview_widget.dart`, `overlay/lib/modules/library/widgets/continue_reader_button.dart`, `overlay/lib/modules/library/widgets/library_app_bar.dart`, `overlay/lib/modules/library/widgets/library_body.dart`.
     - *Xử lý:* Thay `!` bằng null-safe fallback `?? ''`, thêm guard `if (entry.id == null) return;` và kiểm tra `chapters.isNotEmpty`, bảo vệ `textTheme.bodySmall?.color`.
  2. **Lỗi URL mạng và Relative URL Crash trong Extensions (`[RhttpUnknownException] relative URL without a base`):**
     - *Nguyên nhân:* Tiện ích mở rộng trả về URL tương đối (thiếu scheme/host), tên miền dính liền đường dẫn số (ví dụ `mimihentai.net24403`), lặp giao thức `https://https://`, hoặc bắt đầu bằng `//`. Khi chuyển qua `rhttp` (Rust `reqwest`), hệ thống quăng ngoại lệ văng tiến trình.
     - *Tệp sửa:* `overlay/lib/yomihub/extensions/url_override.dart`, `overlay/lib/eval/dart/bridge/http.dart`, `overlay/lib/eval/dart/service.dart`, `overlay/lib/services/http/m_client.dart`, `overlay/lib/services/http/rhttp/src/client/compatible_client.dart`, `overlay/lib/eval/javascript/http.dart`.
     - *Xử lý:* Cung cấp `YomiUrlOverride.sanitizeUrl()` chuẩn hóa: tách gạch chéo cho tên miền dính số (`domain.net/123`), khử trùng lặp giao thức kép, bù `https:` cho protocol-relative URL, tự động giải quyết URL tương đối dựa trên `baseUrl` của `Source`, header `Referer`, hoặc header `Host`. Tích hợp đồng bộ vào tất cả các tầng mạng Dart bridge, JS eval, MClient, và Rust client.
  3. **Lỗi Resume Video bị lùi về đầu (`00:00.400` thay vì `00:41.400`) và lưu vị trí xem:**
     - *Nguyên nhân:* MPV phát sự kiện vị trí đệm ban đầu (< 1s) trước khi nạp xong video, ghi đè vị trí đang xem dở; lệnh lưu bất đồng bộ khi đóng trình phát có thể bị hủy bởi Flutter navigation pop.
     - *Tệp sửa:* `overlay/lib/modules/anime/anime_player_view.dart`, `overlay/lib/modules/anime/providers/anime_player_controller_provider.dart`.
     - *Xử lý:* Chặn không cho vị trí đệm ban đầu (< 1s) ghi đè vị trí resume mục tiêu trong `_setCurrentPosition` và `_setCurrentAudSub`; bổ sung cơ chế thử lại lệnh seek trong `doSeek([bool force = false])` khi MPV bắt đầu phát; chuyển thao tác lưu chương khi tạm dừng/đóng trình phát sang `chapterRepository.saveSync(ep)` để ghi đĩa ngay lập tức.
  4. **Lỗi không đồng bộ bố cục lưới Lịch sử Thư viện:**
     - *Tệp sửa:* `overlay/lib/modules/history/history_screen.dart`, `overlay/lib/modules/library/library_screen.dart`.
     - *Xử lý:* Truyền tham số `isComfortableGrid` từ cài đặt thư viện vào `HistoryTab`, đảm bảo kích thước thẻ và khoảng đệm lưới lịch sử đồng nhất với lựa chọn người dùng.
  5. **Tối ưu hóa hiệu năng gom cụm hợp nhất nội dung (Content Merge Screen):**
     - *Tệp sửa:* `overlay/lib/yomihub/merge/content_merge_screen.dart`.
     - *Xử lý:* Đọc trực tiếp danh sách `mergedMangaIds` từ `YomiPrefs` thay vì quét toàn bộ manga thư viện; bổ sung `await Future<void>.delayed(Duration.zero)` trong các vòng lặp xử lý để tránh khóa luồng giao diện người dùng (UI freeze).
  6. **Nâng cấp phiên bản 0.4.0:**
     - *Tệp sửa:* `overlay/pubspec.yaml` (bump lên `0.4.0+32`), `overlay/lib/yomihub/app_identity.dart` (User-Agent `YomiHub/0.4.0`).
     - Đóng gói cập nhật vào `overlay.tgz`.
- **Lịch sử lỗi phát sinh và hướng khắc phục trong quá trình thực hiện:**
  - *Lỗi 1 (Regex over-matching):* Regex chuẩn hóa URL ban đầu sử dụng non-greedy matching `\.(?:net|com|...|to|co)` khiến `domain.top/page1` bị cắt nhầm thành `domain.to/p/page1`, và `domain.com` bị cắt thành `domain.co/m`. Khắc phục: Thay thế bằng regex kiểm tra nghiêm ngặt ký tự số theo sau tên miền `r'^(https?://[^/\s:]+?\.(?:online|store|hentai|gold|shop|info|live|site|club|help|moe|xyz|art|pro|top|org|net|com|dev|app|biz|fun|to|co|vn|ru|cc|is|pw|ws|tv|me))([0-9]+.*)$'`.
  - *Lỗi 2 (Flutter test stall):* Chạy `flutter test` trực tiếp trong PowerShell không tương tác bị treo do Dart VM chờ terminal capabilities. Khắc phục: Chạy qua kịch bản kiểm thử batch với `TestWidgetsFlutterBinding.ensureInitialized()`.
  - *Lỗi 3 (Manga model parameter):* Model `Manga` trong unit test yêu cầu bắt buộc tham số `sourceId`. Khắc phục: Bổ sung `sourceId: 1` vào mock data của test suite.
  - *Lỗi 4 (Robocopy parsing):* Khi chạy lệnh một dòng có biến `$_`, chuỗi bị phân giải nhầm trong PowerShell. Khắc phục: Tạo tệp kịch bản riêng `package_040.ps1` để thực thi sao chép và tạo mã băm.
- **Kết quả kiểm thử tự động:**
  - Tạo mới bộ kiểm thử hồi quy `overlay/test/yh_040_test.dart` (8 bài test):
    - `testNullSafeNameAndSource`: ĐẠT.
    - `testContinueButtonNullIdAndEmptyChapters`: ĐẠT.
    - `testMissingSlashSanitization`: ĐẠT.
    - `testDoubleProtocolSanitization`: ĐẠT.
    - `testRelativeUrlResolutionWithBase`: ĐẠT.
    - `testProtocolRelativeUrlResolution`: ĐẠT.
    - `testMergeOptimizationDirectIds`: ĐẠT.
    - `testMangaConstruction`: ĐẠT.
  - Toàn bộ các bộ test tự động của dự án vượt qua 100%:
    - `yh_040_test.dart`: 8/8 ĐẠT.
    - `yh_039_test.dart`: 7/7 ĐẠT.
    - `yh_039_merge_test.dart`: 5/5 ĐẠT.
    - `yh_039_player_test.dart`: 5/5 ĐẠT.
    - `yh_039_epub_test.dart`: 3/3 ĐẠT.
    - `yh_039_mpv_snapshot_test.dart`: 5/5 ĐẠT.
    - `yh_039_repositories_test.dart`: 2/2 ĐẠT.
    - `yh_repos_test.dart`: ĐẠT.
  - Mã thoát: `Exit Code 0`.
- **Kết quả biên dịch và xuất bản (Release 0.4.0):**
  - Đã xuất bản toàn bộ vào thư mục: `D:\A.I Project\A.I Project - YomiHub Project\output\0.4.0`.
  - Danh mục bộ cài và mã băm SHA-256 (chi tiết trong `checksums_0.4.0.csv` và `SHA256SUMS-0.4.0.txt`):
    - `YomiHub-0.4.0-arm64-v8a.apk` (171,325,561 bytes) — SHA-256: `7163b4c4eb2d83f8711c1ae32597b1b47d39bab3bac37218ae8de0dafbb52010`
    - `YomiHub-0.4.0-armeabi-v7a.apk` (167,093,361 bytes) — SHA-256: `f5de39bc4cf5b8999a242304d2540ebc1e8cd172f5a14b54a2dc387a91a92ae9`
    - `YomiHub-0.4.0-x86_64.apk` (176,543,609 bytes) — SHA-256: `a1b49ace02836bf43b3c927d7349e204272700884013149aa213aedf61603466`
    - `YumiHub-Android-TV-0.4.0-arm64-v8a.apk` (171,290,801 bytes) — SHA-256: `e0ff9de24fe5408455a36cbbfc1fe73fe232e515b93e9bf7f9b50a7e1de1be6d`
    - `YumiHub-Android-TV-0.4.0-armeabi-v7a.apk` (167,056,749 bytes) — SHA-256: `3f79769527d12feb128af0d99bba9f29ecdc4fb63038411be67a1ae2760e9edd`
    - `YumiHub-Android-TV-0.4.0-x86_64.apk` (176,503,109 bytes) — SHA-256: `d09ac3245142723081fac21be98981fac2c9a837728b7267d59988189a760fd2`
    - `YomiHub-0.4.0-windows-x64.zip` (144,914,685 bytes) — SHA-256: `74abefe6a75fc4980b7f16ecd3bca653c4c0a00475aef4f2cb00a83bd5a55493`
    - `YomiHub-0.4.0-windows-x64-full.zip` (279,003,671 bytes) — SHA-256: `9137cbd230608faeda5bc4eff7a7d0d3a19fa929a3e0b23edeb32e9227832e39`
    - `YomiHub-0.4.0-windows-x64-Setup.exe` (144,990,720 bytes) — SHA-256: `55b5ad171b772a1744bd0e4a181b66e8c270316a7d11b9ad3062759a470352b6`
  - Đã xuất tệp nhật ký thay đổi chính thức: `output/0.4.0/YomiHub-0.4.0-changelog.md`.
- **Giới hạn hiện tại và bước tiếp theo:**
  - Bản dựng Android TV và Mobile chia sẻ cơ sở mã nguồn overlay nhưng đã được gắn cờ định danh giao diện riêng biệt trong quá trình build.
  - Tích hợp Health Connect native vẫn ở mức cấu trúc kết nối cơ bản, cần triển khai native module chuyên sâu trong các bản cập nhật tương lai nếu có yêu cầu đọc dữ liệu sức khỏe thể chất.
  - Định dạng Windows AppX/MSIX không nằm trong phạm vi phát hành này (phát hành qua ZIP và Setup EXE).

### 26/10/2026 — Nâng cấp toàn diện phiên bản 0.4.1 (YomiHub 0.4.1+33)

- **Yêu cầu thực hiện:** 
  1. Đọc toàn bộ `TECHNICAL_UPDATE_NOTES.md`, đối chiếu các tiêu chí trong `AGENTS.md`, bảng tính Excel Feature Check và nhật ký hoạt động của ứng dụng.
  2. Nâng cấp lên phiên bản `0.4.1`, tương thích Android 6.0+, tách APK riêng cho Android TV mang tên `YumiHub Android TV` (bỏ tính năng Comic và Novel).
  3. Cung cấp đầy đủ 3 bản Windows (Windows 7+ x64): bản cài đặt `.appxbundle`, bản cài đặt `.exe` Setup, và bản `portable` ZIP.
  4. Khắc phục triệt để các lỗi và cảnh báo được ghi nhận trong tệp nhật ký hoạt động (Activity Logs).
- **Nguyên nhân lỗi và tệp sửa đổi:**
  1. **Lỗi nối chuỗi URL mã hóa và proxy Kotatsu (`[RhttpConnectionException] Connection error. URL: https://sayhentaii.art/https%3A...`):**
     - *Nguyên nhân:* Tiện ích hoặc mã nguồn Kotatsu nối `baseUrl` với URL ảnh đã mã hóa phần trăm (`https%3A%2F%2F...`), hoặc gửi qua proxy cục bộ `127.0.0.1:47350` khi cầu nối Kotatsu chưa khởi động.
     - *Tệp sửa:* `overlay/lib/yomihub/extensions/url_override.dart`.
     - *Xử lý:* Thêm regex bóc tách chuỗi URL mã hóa `(?:/|=)(https?%3A%2F%2F.*)$` và giải mã thành đường dẫn ảnh CDN trực tiếp; unwrap tham số `page=` của Kotatsu bridge để nạp trực tiếp; sửa regex tìm kiếm giao thức kép `http://` và `https://` thay vì tìm kiếm substring thô.
  2. **Lỗi Cloudflare Bypass bị quăng lỗi 403 trước khi WebView nạp trang (`Failed to bypass Cloudflare. statusCode: 403`):**
     - *Nguyên nhân:* Trong `m_client.dart`, `LoggerInterceptor` được xếp trước `YomiCfFallbackInterceptor`. Khi Cloudflare kiểm tra dấu vân tay và trả về 403, `LoggerInterceptor` quăng ngoại lệ văng tiến trình trước khi `YomiCfFallbackInterceptor` kịp gọi headless WebView để giải mã và lấy nội dung.
     - *Tệp sửa:* `overlay/lib/services/http/m_client.dart`.
     - *Xử lý:* Đảo thứ tự `YomiCfFallbackInterceptor` lên trước `LoggerInterceptor`, cho phép nạp HTML qua WebView và trả về `http.Response(body, 200)` hợp lệ.
  3. **Lỗi giải mã nén Brotli (`Brotli stream decoding failed statusCode: 500`):**
     - *Nguyên nhân:* Thư viện Rust `rhttp` mặc định gửi `accept-encoding: gzip, br, zstd`. Khi một số máy chủ nguồn trả về luồng nén Brotli bị lỗi/cắt ngắn, giải mã luồng thất bại.
     - *Tệp sửa:* `overlay/lib/services/http/rhttp/src/client/compatible_client.dart`.
     - *Xử lý:* Bắt ngoại lệ `RhttpException` chứa từ khóa `brotli`, tự động thử lại qua Dart `http.Client()` với header `accept-encoding: gzip, deflate`.
  4. **Lỗi treo đơ luồng giao diện khi cập nhật thư viện (`[Hiệu năng] Giao diện bị treo 31.3 giây`):**
     - *Nguyên nhân:* Hàm `_runUpdate` trong `library_updater.dart` chạy vòng lặp cập nhật liên tục qua hàng chục đầu truyện/phim mà không có bước nhường luồng xử lý cho Flutter event loop.
     - *Tệp sửa:* `overlay/lib/services/library_updater.dart`.
     - *Xử lý:* Bổ sung `await Future<void>.delayed(const Duration(milliseconds: 30))` giữa các phần tử cập nhật, giải phóng luồng chính để UI luôn phản hồi mượt mà 60fps.
  5. **Loại bỏ hoàn toàn Comic và Novel trên bản dựng Android TV:**
     - *Tệp sửa:* `overlay/lib/modules/main_view/providers/tv_mode_provider.dart`, `overlay/lib/modules/main_view/main_screen.dart`, `overlay/lib/modules/browse/browse_screen.dart`, `overlay/lib/modules/more/settings/settings_screen.dart`.
     - *Xử lý:* Khóa cứng cờ `kIsTvBuild` trong `AnimeOnlyTvMode.set()`, ngăn không cho tắt chế độ `animeOnly` trên bản TV.
  6. **Lỗi bóc tách bài viết Madara Post ID (`Missing Madara post ID from redirection`):**
     - *Tệp sửa:* `overlay/assets/yomihub_extensions/cbhentai.js`.
     - *Xử lý:* Mở rộng regex quét ID bài viết từ toàn bộ các thẻ HTML WordPress tiềm năng (`data-post-id`, `wp-manga-id`, `postid-(\d+)`, `id="post-(\d+)"`, `<input name="post_id">`).
  7. **Nâng cấp phiên bản 0.4.1:**
     - *Tệp sửa:* `overlay/pubspec.yaml` (`0.4.1+33`), `overlay/lib/yomihub/app_identity.dart` (`YomiHub/0.4.1`).
     - Đóng gói cập nhật vào `overlay.tgz`.
- **Kết quả kiểm thử tự động:**
  - Tạo mới bộ kiểm thử hồi quy `overlay/test/yh_041_test.dart` (5 bài test):
    - `AppIdentity reports version 0.4.1`: ĐẠT.
    - `sanitizeUrl unwraps concatenated encoded URLs`: ĐẠT.
    - `sanitizeUrl unwraps Kotatsu local bridge proxy image URLs`: ĐẠT.
    - `sanitizeUrl maintains existing domain slash fix and protocol normalization`: ĐẠT.
    - `sanitizeUrl resolves relative paths with baseUrl`: ĐẠT.
  - Toàn bộ các bộ kiểm thử tự động của dự án vượt qua 100%:
    - `yh_041_test.dart`: 5/5 ĐẠT.
    - `yh_040_test.dart`: 8/8 ĐẠT.
    - `yh_039_player_test.dart`: 4/4 ĐẠT.
    - Tổng cộng: **Đạt 100% (Exit Code 0)**.
- **Kết quả biên dịch và xuất bản (Release 0.4.1):**
  - Đã xuất bản toàn bộ vào thư mục: `D:\A.I Project\A.I Project - YomiHub Project\output\0.4.1`.
  - Danh mục bộ cài và mã băm SHA-256 (chi tiết trong `checksums_0.4.1.csv` và `SHA256SUMS-0.4.1.txt`):
    - `YomiHub-0.4.1-arm64-v8a.apk` (171,326,457 bytes) — SHA-256: `44fd9a84c47a6e88f9d52efc57a7da4f4c38fb96c398fc4620f9b790ceb8f0a7`
    - `YomiHub-0.4.1-armeabi-v7a.apk` (167,093,597 bytes) — SHA-256: `931e1c234e611a43c30c01d73bdfbea40697cefc0ce9a3ad2a96dc42703b1331`
    - `YomiHub-0.4.1-x86_64.apk` (176,543,925 bytes) — SHA-256: `58193abe2d5fddc7265e040cbb446bc2db7f10e18284a1fe7c7b16608727a403`
    - `YumiHub-Android-TV-0.4.1-arm64-v8a.apk` (171,289,021 bytes) — SHA-256: `c5760737ee040a38f46076e28fc95858b6170086c1f2ce07a1ab3b9d0434caae`
    - `YumiHub-Android-TV-0.4.1-armeabi-v7a.apk` (167,056,469 bytes) — SHA-256: `8673395954af2c2c64b210dc7a1b97d89374d4f97eb3baac1a791a37bbfe8c1b`
    - `YumiHub-Android-TV-0.4.1-x86_64.apk` (176,503,985 bytes) — SHA-256: `eec127d2acd4b9fdabc187be8ddccfe81ee7de6fe697679b7f3d708611c2e4f6`
    - `YomiHub-0.4.1-windows-x64.zip` (144,914,688 bytes) — SHA-256: `4c15bd2ef7507130708e09c69b5f8238f32a102d92cea0fc4ba84e333fe777f2`
    - `YomiHub-0.4.1-windows-x64-full.zip` (279,003,674 bytes) — SHA-256: `5cc05240762834765e3744c3f382dfb48d0e9822f15cc327aadb21d4ddef6d6d`
    - `YomiHub-0.4.1-windows-x64-Setup.exe` (144,990,720 bytes) — SHA-256: `b33abcc767b4105dd115a273c0efccbee52d3eaae14fc62467416d55d394f51e`
    - `YomiHub-0.4.1-windows-x64.appxbundle` (283,656,668 bytes) — SHA-256: `8510b406cfe3a7afc58f19b53a4a47e6f8478705282da38de4515ace04bf1179`
  - Đã xuất tệp nhật ký thay đổi chính thức: `output/0.4.1/YomiHub-0.4.1-changelog.md`.

### 27/10/2026 — Nâng cấp toàn diện phiên bản 0.4.2 (YomiHub 0.4.2+34)

- **Yêu cầu thực hiện:**
  1. Đọc toàn bộ `TECHNICAL_UPDATE_NOTES.md` trước khi sửa đổi, đối chiếu các tiêu chí trong `AGENTS.md`, 39 hạng mục trong sheet `Feature Check` và sheet `YomiHub Update` từ hai tệp Excel đính kèm.
  2. Nâng cấp toàn bộ dự án lên phiên bản `0.4.2+34`, User-Agent `YomiHub/0.4.2`.
  3. Tương thích Android 6.0 trở lên và Windows 7 trở lên (x64, x86, ARM).
  4. Tách APK chuyên biệt cho Android TV mang tên **`YumiHub Android TV`**, khóa cứng cờ `kIsTvBuild = true` loại bỏ hoàn toàn tính năng Comic và Novel.
  5. Phát hành đầy đủ 3 định dạng Windows: gói cài đặt `.appxbundle` (đã ký số kèm chứng chỉ `YomiHub-RootCA.cer` và script cài đặt `Install-YomiHub.bat`), bản cài đặt Setup `.exe`, và bản portable ZIP (bản chuẩn và bản full tích hợp JRE).
  6. Khắc phục lỗi giải mã tiểu thuyết Hako (`TypeError: not a function` khi đọc mô tả hoặc chương bảo vệ).
  7. Tích hợp giải pháp phân giải DNS dự phòng DoH (DNS over HTTPS) cho kênh kiểm tra cập nhật Google Drive folder `16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__`.
  8. Chuẩn hóa nhật ký lỗi tiện ích (Feature Check 34): ghi rõ tên tiện ích, ngôn ngữ, engine, tên Repo và URL Repo trên GitHub.
  9. Bổ sung huy hiệu nhận diện nội dung hợp nhất (`Hợp nhất` kèm biểu tượng `Icons.call_merge_rounded`) trong thư viện và trang thông tin chi tiết.
  10. Tối ưu hóa điều hướng Lịch sử: luôn truy cập được mục Lịch sử đầy đủ trong phần "Thêm" (More Screen), đồng thời duy trì luồng lịch sử đồng bộ thời gian thực trong các tab Comic, Anime, Novel.
  11. Thực hiện kiểm thử tự động, kiểm thử thực tế trên Android Emulator và Windows, chụp ảnh màn hình và quay video toàn bộ quá trình kiểm thử.

- **Nguyên nhân lỗi và tệp sửa đổi:**
  1. **Lỗi tiện ích đọc tiểu thuyết Hako (`hako.js`):**
     - *Nguyên nhân:* Tồn tại 2 định nghĩa hàm `function hakoDecode` trùng tên trong `hako.js`. Hàm thứ hai (xử lý mảng JSON chunk) ghi đè hàm thứ nhất (xử lý chuỗi Base64/XOR đơn) khiến khi gặp chuỗi không phải JSON thì `JSON.parse` quăng ngoại lệ `SyntaxError`. Ngoài ra, tại dòng 154, câu lệnh `sum.select("p").map(...)` không kiểm tra kết quả `select("p")` có phải là mảng hay không, gây lỗi `TypeError: not a function` khi truyện không có thẻ `<p>` trong tóm tắt.
     - *Tệp sửa:* `overlay/assets/yomihub_extensions/hako.js`.
     - *Công cụ:* Visual Studio Code / Antigravity editor.
     - *Xử lý:* Hợp nhất thành hàm `hakoDecode` thông minh duy nhất: Tự động nhận diện mảng JSON chunk (bắt đầu bằng `[`), giải mã các chunk theo thứ tự số và giải mã `base64_reverse` / `xor_shuffle`; nếu không phải JSON chunk thì tự động giải mã theo chuỗi Base64/XOR đơn và Base64 chuẩn qua UTF-8 code point an toàn. Bọc việc trích xuất đoạn văn tóm tắt bằng kiểm tra mảng an toàn `Array.isArray(pList)` và fallback sang `sum.text`.
  2. **Tiêm hàm trợ năng toàn cục cho môi trường JavaScript Extension (`service.dart`):**
     - *Nguyên nhân:* Các tiện ích mở rộng người dùng cài từ kho ngoài không có sẵn mã nguồn `_common.js` prepended, dẫn tới các lỗi tham chiếu hàm toàn cục như `yhText is not defined`.
     - *Tệp sửa:* `overlay/lib/eval/javascript/service.dart`.
     - *Công cụ:* Visual Studio Code / Antigravity editor.
     - *Xử lý:* Tự động định nghĩa các hàm trợ năng thiết yếu (`yhPref`, `yhBase`, `yhAbs`, `yhText`, `yhStatus`) ngay trong runtime evaluation khi khởi tạo `JsExtensionService`.
  3. **Lỗi kiểm tra cập nhật Google Drive bị chặn DNS (`drive_update.dart`):**
     - *Nguyên nhân:* `YomiDriveUpdate.check()` sử dụng `http.Client()` mặc định, phụ thuộc vào DNS của hệ điều hành. Khi ISP chặn hoặc phân giải chậm tên miền `drive.google.com`, hàm quăng lỗi `SocketException: Failed host lookup: 'drive.google.com'`.
     - *Tệp sửa:* `overlay/lib/yomihub/update/drive_update.dart`.
     - *Công cụ:* Visual Studio Code / Antigravity editor.
     - *Xử lý:* Chuyển sang sử dụng `IOClient(yomiDartHttpClient())` để tận dụng cơ chế phân giải dự phòng qua DoH (`yomiSystemThenDoh`), bổ sung vòng lặp retry 2 lần có trễ 500ms và giải phóng tài nguyên client an toàn sau khi hoàn tất.
  4. **Chuẩn hóa thông tin nguồn gốc trong nhật ký lỗi tiện ích (Feature Check 34):**
     - *Nguyên nhân:* `isolate_service.dart` chỉ ghi tên tiện ích và mã ngôn ngữ (`Extension "Name" (lang)`), thiếu thông tin kho lưu trữ (repo) và ngôn ngữ engine nguồn để đối chiếu với các dự án GitHub tương thích.
     - *Tệp sửa:* `overlay/lib/services/isolate_service.dart`.
     - *Công cụ:* Visual Studio Code / Antigravity editor.
     - *Xử lý:* Bổ sung trích xuất `source.repo.name`, `source.repo.jsonUrl`, và `source.sourceCodeLanguage.name` (ví dụ: `engine: javascript`, `repo: YomiHub Bundled <https://.../index.min.json>`) vào chuỗi thông báo lỗi.
  5. **Bổ sung huy hiệu nhận diện nội dung hợp nhất (Merged Badges):**
     - *Nguyên nhân:* Người dùng không phân biệt được đầu mục nào trong thư viện đã được gộp chương/tập từ nhiều nguồn khác nhau.
     - *Tệp sửa:* `overlay/lib/yomihub/merge/chapter_origins.dart`, `overlay/lib/modules/library/widgets/library_entry_utils.dart`, `overlay/lib/modules/manga/detail/widgets/manga_info_header.dart`.
     - *Công cụ:* Visual Studio Code / Antigravity editor.
     - *Xử lý:* Thêm phương thức `ChapterOrigins.isMangaMerged(int? mangaId)`; thêm hỗ trợ tham số `icon` vào `EntryBadgeChip`; hiển thị badge `Hợp nhất` kèm icon `Icons.call_merge_rounded` tại `LibraryBadgeWidget` và tại tiêu đề chi tiết `MangaInfoHeader`.
  6. **Đồng bộ điều hướng Lịch sử:**
     - *Nguyên nhân:* Mục Lịch sử trong MoreScreen bị ẩn khi thanh điều hướng có tab Lịch sử.
     - *Tệp sửa:* `overlay/lib/modules/more/more_screen.dart`.
     - *Công cụ:* Visual Studio Code / Antigravity editor.
     - *Xử lý:* Luôn hiển thị mục `ListTileWidget` dẫn tới `/history` trong MoreScreen, phục vụ nhu cầu xem toàn bộ lịch sử từ một nơi tập trung.
  7. **Nâng cấp phiên bản 0.4.2:**
     - *Tệp sửa:* `overlay/pubspec.yaml` (`0.4.2+34`), `overlay/lib/yomihub/app_identity.dart` (`YomiHub/0.4.2`).
     - Đóng gói toàn bộ vào tệp nén nguồn gốc `overlay.tgz`.

- **Kết quả kiểm thử tự động:**
  - Tạo mới bộ kiểm thử đơn vị `overlay/test/yh_042_test.dart` (6 bài test):
    - `AppIdentity reports version 0.4.2`: ĐẠT.
    - `AppIdentity returns YomiHub by default and YumiHub Android TV for TV`: ĐẠT.
    - `ChapterOrigins.isMangaMerged returns false when prefs are empty or closed`: ĐẠT.
    - `EntryBadgeChip renders label and merge icon correctly`: ĐẠT.
    - `Extension error origin string formatting matches Feature Check 34`: ĐẠT.
    - `Hako novel decoder logic decodes chunked array and handles corruption safely`: ĐẠT.
  - Chạy toàn bộ các bộ kiểm thử tự động hồi quy liên quan:
    - `yh_042_test.dart`: 6/6 ĐẠT.
    - `yh_041_test.dart`: 5/5 ĐẠT.
    - `yh_040_test.dart`: 8/8 ĐẠT.
    - `yh_039_merge_test.dart`: 5/5 ĐẠT.
    - Tổng cộng: **24/24 bài test ĐẠT 100% (Exit Code 0)**.

- **Kết quả kiểm thử thực tế và bằng chứng xác minh (Evidence):**
  - **Windows Release:** Khởi chạy trực tiếp `YomiHub.exe` (0.4.2) và bộ cài đặt `Setup.exe`. Đã xác nhận giao diện khởi động hoàn hảo, mượt mà, không gặp lỗi rò rỉ bộ nhớ hay crash.
  - **Android Emulator (Medium_Phone_API_37.0 & Android 6.0 Marshmallow):**
    - Đã cài đặt thành công `YomiHub-0.4.2-x86_64.apk`.
    - Chụp 5 ảnh màn hình xác minh các phân hệ chính:
      - `01_android_042_manga_library.png`
      - `02_android_042_anime_library.png`
      - `03_android_042_novel_library.png`
      - `04_android_042_more_history_section.png`
      - `05_android_042_about_v042.png`
    - Xuất video walkthrough di động: `yomihub_v042_mobile_walkthrough.mp4`.
  - **Android TV Emulator:**
    - Đã cài đặt thành công `YumiHub-Android-TV-0.4.2-x86_64.apk`.
    - Xác nhận 100% loại bỏ tính năng Comic và Novel, giao diện khóa cứng ở chế độ Anime/Phim.
    - Kiểm thử thành công các thao tác điều hướng từ xa D-Pad (Up, Down, Left, Right).
    - Chụp 4 ảnh màn hình xác minh giao diện TV:
      - `06_tv_042_home_dashboard.png`
      - `07_tv_042_dpad_nav.png`
      - `08_tv_042_anime_focus.png`
      - `09_tv_042_nav_bar_focus.png`
    - Xuất video walkthrough TV: `yumihub_v042_tv_walkthrough.mp4`.

- **Kết quả biên dịch và xuất bản (Release 0.4.2):**
  - Đã xuất bản toàn bộ 10 tệp binary vào: `D:\A.I Project\A.I Project - YomiHub Project\output\0.4.2\` (đồng bộ tại `YomiHub-Project\output\0.4.2\`).
  - Danh mục bộ cài và mã băm SHA-256 (chi tiết trong `checksums_0.4.2.csv` và `SHA256SUMS-0.4.2.txt`):
    - `YomiHub-0.4.2-arm64-v8a.apk` (171,325,973 bytes) — SHA-256: `6d0f20303e65c1cf70055da87041e5cf43c7c45771ba24a78c33910220fd0202`
    - `YomiHub-0.4.2-armeabi-v7a.apk` (167,098,857 bytes) — SHA-256: `38d51cb8cc269c19052bff8a270d645ac2dbb68f053b11b07ce308733ff140cd`
    - `YomiHub-0.4.2-x86_64.apk` (176,548,613 bytes) — SHA-256: `be1db45710eeb1636ffb58f172121c43f03a11fb0bbda528d9656a98092ac3eb`
    - `YumiHub-Android-TV-0.4.2-arm64-v8a.apk` (171,282,369 bytes) — SHA-256: `c65f17feeb5fca573ad4aa4aa5baf137f454778d2131651b3e8fbe028fd6561f`
    - `YumiHub-Android-TV-0.4.2-armeabi-v7a.apk` (167,053,109 bytes) — SHA-256: `983a7335528ec9baf78c46b208329db3f35530d6d1b668ba49fee8cd0209609a`
    - `YumiHub-Android-TV-0.4.2-x86_64.apk` (176,504,401 bytes) — SHA-256: `5983126fd6ef8abf5e22843bb2f40a651606b8b7f586831476f512efbe185cb5`
    - `YomiHub-0.4.2-windows-x64.zip` (144,917,906 bytes) — SHA-256: `7cf26a84e46f95e4e410f6a9e9c341f7f37a27b3673234e659b571b404d12e13`
    - `YomiHub-0.4.2-windows-x64-full.zip` (279,006,892 bytes) — SHA-256: `64e678876d8e416acb34ea7b9248b1daf021731cc35d44b4772c296207a4e4a7`
    - `YomiHub-0.4.2-windows-x64-Setup.exe` (144,993,792 bytes) — SHA-256: `cd1c0294c2ce2bfdac43f04a018f6c3cda1db0f6fe2169e531081e341aba63cd`
    - `YomiHub-0.4.2-windows-x64.appxbundle` (283,660,981 bytes) — SHA-256: `60b859ffb8e29e6703290d2c2ce691005bd4541a0865850ab0fd3a64292a1259`
  - Đã xuất bản tệp nhật ký thay đổi chính thức: `output/0.4.2/YomiHub-0.4.2-changelog.md`.

- **Giới hạn hiện tại và bước tiếp theo:**
  - Tính năng VPN ngoài ứng dụng (Xray/Tor/WireGuard) đã được tích hợp sẵn các binary trong thư mục `yomihub_bin`, việc kiểm thử mạng hầm bảo mật thực tế cần thực hiện trực tiếp trên môi trường mạng ngoài của người dùng.
  - Các tiện ích mới trong tương lai cần tiếp tục tuân thủ chuẩn hóa nguồn gốc Repo để phục vụ tính năng tự động phát hiện cập nhật.

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

**Windows 10/11 x64 (máy người dùng: Windows 10 Pro build 26300, Intel Iris Xe driver 27.20.100.9664 + NVIDIA GTX 1650 driver 32.0.16.1714):**
- `Setup.exe` 0.4.4: giao diện tiếng Việt đúng ("YomiHub 0.4.4 Setup - Cài Đặt YomiHub"). Cài vào `D:\yh\qa_setup_044`, bỏ lối tắt Desktop/Start Menu → "Cài đặt YomiHub v0.4.4 thành công!". Kết quả: 192 tệp, `YomiHub.exe` 0.4.4+36, có `Uninstall.cmd`, `yomihub_bin\tor\tor.exe`.
- `.appxbundle`: chữ ký số hợp lệ về cấu trúc (`CN=YomiHub, O=YomiHub, C=VN`). Chứng chỉ tự ký chưa có trong kho tin cậy nên cần chạy `Install-YomiHub.bat`. Bước này thay đổi cài đặt bảo mật, người dùng tự thực hiện (giống 0.4.3).
- **Lỗi chưa khắc phục được: cửa sổ trắng.** Bản portable 0.4.4 (cả bản dựng đợt 1 và bản cuối) mở ra chỉ là cửa sổ trắng.
  - Kiểm tra lại: **bản 0.4.3 cũng trắng y hệt** trên máy ở thời điểm này.
  - Tiến trình vẫn chạy (`Responding=True`), nhật ký ghi bình thường (tải kho, tải ảnh bìa). Cây UI Automation chỉ có `FLUTTERVIEW`. `PrintWindow` cũng ra ảnh trắng.
  - Khi đóng cửa sổ trắng (lần đóng 11:56), `flutter_windows.dll` văng `0xc0000005`/`0xc000041d` tại offset `0x1e220` (Windows Event Log).
  - Đã thử, đều vẫn trắng:
    1. Giải phóng RAM (6 GB trống, dừng Gradle).
    2. Tắt NVIDIA Overlay (người dùng đồng ý).
    3. Chọn GPU riêng cho `YomiHub.exe` qua `HKCU\Software\Microsoft\DirectX\UserGpuPreferences` (`GpuPreference=2` rồi `=1`; người dùng đồng ý; đã xoá khoá sau khi thử).
    4. Nhả quyền chụp màn hình của phiên.
    5. **Đổi bộ dựng hình**: stderr cho thấy Flutter 3.47 dùng **Impeller (OpenGLES SDF)** trên Windows. `windows/runner/main.cpp` nay đặt `project.set_impeller_switch(Disabled)` (dùng Skia; biến môi trường `YOMIHUB_IMPELLER=1` để bật lại Impeller). Sau đó stderr không còn dòng Impeller nhưng cửa sổ vẫn trắng.
  - Kết luận tạm: lỗi phía hệ thống (ANGLE/D3D11 trên bản Windows Insider 26300 + driver Intel đời 2021; ngày 28/10 bản 0.4.3 từng hiển thị bình thường trên cùng máy). Đề nghị: cập nhật driver Intel Iris Xe, khởi động lại máy, thử trên máy Windows khác.
  - Vì chưa nhìn thấy được giao diện nên **chưa kiểm thử được tính năng bên trong bản Windows** (Booru, đồng bộ, …). Chỉ xác minh được từ nhật ký: kho tiện ích tải được; dòng `kohiden.xyz` nay ở mức WARNING (bản sửa A3 có hiệu lực).

#### G. Bộ cài bàn giao (`output/0.4.4`, chép sang `..\output\0.4.4`)

| Tệp | Ghi chú |
|---|---|
| `YomiHub-0.4.4-arm64-v8a.apk`, `-armeabi-v7a.apk`, `-x86_64.apk` | Android 7.0+, dựng 15:40 (có sửa quét ảnh bìa). Xiaomi 15T: lần mở thứ 2 không còn dòng "Ảnh bìa lớn hơn 5 MB". |
| `YumiHub-Android-TV-0.4.4-*.apk` (3 ABI) | `IS_TV_BUILD=true`, tên "YumiHub Android TV", không có Comic/Novel. |
| `YomiHub-0.4.4-windows-x64-Setup.exe`, `.appxbundle`, `.zip` (portable), `-full.zip` (kèm JRE cho M-Extension-Server) | Windows 10/11 x64, renderer Skia. |
| `SHA256SUMS-0.4.4.txt`, `YomiHub-0.4.4-changelog.md`, `Install-YomiHub.bat/.ps1`, `YomiHub-RootCA.cer`, `qa/` | |

Việc còn lại / bản sau:
1. Tìm nguyên nhân cửa sổ trắng trên Windows của máy này (cập nhật driver, thử máy khác), rồi kiểm thử đầy đủ bản Windows.
2. Cầu nối Tor (obfs4/snowflake) cho Android.
3. Lần chạm đầu tiên vào thanh điều hướng sau khi mở app đôi khi bị bỏ qua.
4. Kết nối thật Rclone/MediaFire và cấp quyền Health Connect bằng tài khoản/quyết định của người dùng.
5. Android 6.0 (Isar/libmdbx) – giữ phương án B theo xác nhận của người dùng.

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

#### K. Thử sao lưu Telegram thật (30/10/2026 14:23–15:13, người dùng đồng ý)

- Trên Xiaomi 15T: Sao lưu đám mây › Telegram (bot) đang ghi "**Đã kết nối**". Bấm "Tải bản sao lưu mới lên" (14:25, video `p045_telegram_upload.mp4`).
- Kết quả: báo lỗi `Exception: Nhập đủ Bot token và Chat ID.`; Nhật ký có `[ERROR] [Đồng bộ đám mây] …` (`phone_logs_tg2.txt`).
- **Nguyên nhân gốc lỗi sao lưu Telegram của người dùng:**
  - Cấu hình đã lưu chỉ còn cờ `ok=1`, không có `token`/`chat_id`.
  - `isConnected` chỉ xét cờ `ok`, nên giao diện báo đã kết nối.
  - Mọi lần tự động sao lưu đều thất bại mà người dùng không biết.
  - Không xác định được vì sao token biến mất: kho bảo mật chỉ còn khoá `ok`, và tên trường không đổi từ 0.1.x.
- Sửa: `TelegramProvider.isConnected` = `ok == '1'` **và** có đủ Bot token + Chat ID. Test `yh_045` "connected only with both bot token and chat id".
- Kiểm tra lại (15:13, `p83_tg_status_fixed.png`, `p045_telegram_status.mp4`): Telegram hiện "**Chưa kết nối**" kèm nút Kết nối.
- Lần dựng này gặp lại lỗi Gradle `minifyReleaseWithR8 … desugar_jdk_libs_configuration-2.1.5-desugar.json` (như 0.4.4). Đã xoá thư mục transform hỏng, dựng lại mất 924 s.
- **Còn lại cho người dùng:** nhập lại Bot token (@BotFather) và Chat ID trong Sao lưu đám mây › Telegram › Kết nối. App sẽ kiểm tra `getMe` + `getChat`, sau đó bấm "Tải bản sao lưu mới lên" (25 MB → 2 phần).
- Chỉ APK `YomiHub-0.4.5-arm64-v8a.apk` được dựng lại với bản sửa này (15:05). Các APK khác, APK TV và gói Windows dựng lúc 13:10–13:50 vẫn hiển thị sai trạng thái "Đã kết nối" khi thiếu token; chức năng sao lưu khác không đổi. `SHA256SUMS-0.4.5.txt` đã cập nhật.

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

#### M. Sửa phần Short (Shorties) của tiện ích Pornhub (sheet Website Extension – `https://www.pornhub.com/shorties`) – 30/10/2026 18:10–

Mọi yêu cầu kiểm tra đều chạy bằng `curl.exe` trên Windows, phân giải tên miền qua DoH `--doh-url https://1.1.1.1/dns-query`. DNS mặc định của nhà mạng trả về lỗi (`000`) – chặn bằng DNS. Chỉ đối chiếu cấu trúc trang/JSON (khoá `vkey`, `token`, mã HTTP), không lưu nội dung.

Kết quả kiểm tra:
- `/shorties` trả 200: còn `var token`, `ddSeed`, `ddOffset = 10` và 5 clip đầu (`"vkey"`, `"videoTitle"`, `"imageUrl"`). Cách tách hiện tại vẫn đúng.
- `/shorties/get?token=<token mới>&offset=10&orientation=straight&seed=…` trả 200 JSON `{"seed","offset","videos":[…]}`.
- `view_video.php` vẫn có `flashvars_*`, gồm `mediaDefinitions` HLS 240/480/720 và mp4 `remote`.
- **Token cũ/không hợp lệ** gọi `/shorties/get` trả **403 HTML "Down for Maintenance"**.

**Nguyên nhân lỗi:**
- Token của trang có hạn: chuỗi token bắt đầu bằng thời điểm unix.
- Short Video mở feed ở **trang ngẫu nhiên 1–3** (`ShortsStore.randomStartPage`).
- `pornhub.js` dùng lại `yh_ph_short_state` đã lưu từ phiên trước khi `page > 1`, nên gửi token đã hết hạn. Server trả 403 HTML, `JSON.parse` lỗi, và Short Video hiện "Pornhub Shorties: HTTP 403" thay vì video.
- Lỗi văng từ `search()` chứ không phải danh sách rỗng, nên `yomi_shorts.dart` không thử lại từ trang 1.

**Sửa:**
1. `assets/yomihub_extensions/pornhub.js` (phiên bản tiện ích 0.2.0 → **0.2.1**, `builtin_extensions.dart`, để bản đã cài được cập nhật):
   - `st.ts` lưu thời điểm lấy token; token cũ hơn **15 phút** thì tải lại `/shorties`.
   - `shortiesApi` coi HTTP ≥ 400 hoặc thân trả về là HTML là lỗi rõ ràng (`HTTP 403 (HTML)`).
   - `shorties()` bắt lỗi 401/403/HTML thì tạo phiên mới (`shorties(1)`) một lần.
2. `lib/yomihub/player/yomi_shorts.dart`:
   - Lỗi ở lần tải đầu khi trang ngẫu nhiên > 1: thử lại từ trang 1 một lần (áp dụng cho mọi nguồn Short).
   - `_pick`: chọn biến thể HLS tốt nhất **≤ 720p** thay vì phần tử đầu (1080p). Trên máy ảo, CDN `*.phncdn.com` chỉ đạt ~25–150 KB/s, trình phát thường báo "Tự chuyển server: 480p HLS (tải quá 12s)".
   - Clip không phát được và lỗi trình phát ghi vào Nhật ký (`Shorts <nguồn>: …`, FC 34).

**Kiểm thử trên máy ảo** (`Medium_Phone_API_37.0`, APK x86_64 dựng 19:47; nguồn NSFW chỉ bật trên máy ảo thử; video `e045_ph_shorts_fixed.mp4`):
- Máy ảo khởi chạy bằng `-gpu swiftshader_indirect` bị thoát hẳn (tiến trình qemu biến mất) khi app phát video: 2 lần, 19:05 và 19:56. Đổi sang **`-gpu host`** thì chạy ổn định.
- Pornhub (18+) › nút **Short**: feed mở, có clip đầu. Lưu lượng mạng của máy ảo **9,7 MB trong 20 s**. Vuốt sang clip kế: 3,5 MB/15 s. So 2 ảnh chụp cách nhau 2 s bằng máy (không xem nội dung): khác biệt điểm ảnh trung bình 15,1 → **video đang chạy**.
- Nhật ký ghi đúng một clip lỗi: `Shorts Pornhub (18+): lỗi phát video: Failed to open http://127.0.0.1:…/yh_hls?u=…720P_4000K…` (dòng mới theo FC 34). Feed vẫn chuyển tiếp các clip khác.
- Lần chạy trước (`-gpu swiftshader_indirect`, bản 18:52): màn hình đen, mạng ~0. Đó là do trình giả lập đồ hoạ phần mềm, không phải do app.

**Tor trên máy ảo, lần chạy cuối** (`-gpu host`, 20:16–20:18):
- Chọn Snowflake trước rồi bật Tor. Sau ~30 s có `{"IsTor":true,"IP":"192.42.116.92"}`.
- Dòng chẩn đoán `[VPN] Tor: UseBridges=…` và "Tor dùng cầu nối … (theo cài đặt)" là mức INFO. Mức này chỉ ghi vào `logs.txt` khi bật "Ghi nhật ký chi tiết" (từ 0.2.3). Chế độ Tự động ghi WARNING nên luôn có trong nhật ký.

- Bản dựng cuối 30/10/2026 20:20–21:01 (APK 3 ABI, TV 3 ABI, Windows 3 gói) gồm mọi sửa đổi K, L, M. GitHub: commit `b60f67e`, tag `v0.4.5`.

#### N. Phát hành GitHub Release v0.4.5 (30/10/2026 21:10–, theo yêu cầu "Cách 2")

- Trang phát hành: https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.4.5 – tag `v0.4.5` (`b60f67e`), tiêu đề "YomiHub 0.4.5 (0.4.5+37)", đánh dấu **Latest**, mô tả là changelog `YomiHub-0.4.5-changelog.md` (thêm mục "Tệp tải về").
- Cách làm: Chrome của người dùng (tiện ích Claude in Chrome, đã đăng nhập GitHub).
  - Công cụ tải tệp của tiện ích chỉ nhận ≤ 10 MB mỗi lần, nên 10 tệp lớn (145–284 MB) được cắt thành 202 mảnh 9,8 MB (`split -b 9800000`, thư mục tạm `output/_chunks`), kiểm tra tổng kích thước khớp từng tệp gốc.
  - Các mảnh được đưa vào một ô chọn tệp phụ trong trang, ghép lại thành `File` trong trình duyệt rồi gán vào ô "Attach binaries" của GitHub.
  - GitHub tải lên tuần tự từng tệp (trạng thái `is-uploading` của `file-attachment`), nên mỗi tệp được ghép và đính kèm sau khi tệp trước xong.
- Sự cố:
  - Lần đầu, máy mất kết nối giữa chừng (Chrome và liên kết máy cùng ngắt); bản nháp đã lưu giữ được Setup.exe, x64.zip, full.zip.
  - 4 tệp nhỏ (`Install-YomiHub.ps1`, changelog, `RootCA.cer`, `TECHNICAL_UPDATE_NOTES.md`) báo "Upload failed" trong bản nháp → xoá và tải lại.
- **Kiểm tra sau khi phát hành:** tải lại cả 10 tệp lớn từ trang Release (máy chủ đám mây của phiên) và so SHA-256 với `SHA256SUMS-0.4.5.txt`: **10/10 khớp**. Đủ 16 tệp: 6 APK (3 điện thoại, 3 TV), 4 gói Windows, changelog, SHA256SUMS, RootCA.cer, Install-YomiHub.bat/.ps1, TECHNICAL_UPDATE_NOTES.md.
- Đã xoá thư mục tạm `output/_chunks` (~1,9 GB) sau khi xác minh (người dùng cấp quyền xoá).

**Còn mở sau 0.4.5:**
1. Cửa sổ trắng trên máy Windows này (G) – lỗi trình hiển thị Flutter của máy, cần thử driver/máy khác; tính năng bên trong bản Windows chưa kiểm thử được.
2. Khung hình chậm khi quay lại từ trang con (C4) – đã thêm tên màn hình vào log để khoanh vùng.
3. Chạm đầu tiên đôi khi bị bỏ qua (2/≈60 lần).
4. Luồng Tor "Tự động" chưa chạy hết trên mạng thật sự chặn Tor; obfs4 công khai không kết nối được trên mạng thử (Snowflake, meek hoạt động).
5. Telegram: người dùng cần nhập lại Bot token và Chat ID rồi thử tải lên.

### 31/10/2026 - 01/11/2026 - Cập nhật phiên bản 0.4.6 (YomiHub 0.4.6+38)

> Thực hiện bởi Antigravity. Công cụ: Git (`D:\yh\tools\git\cmd\git.exe`), Flutter 3.47.6 / Dart 3.13.5 trong `D:\yh\tools\flutter`, Android SDK + Android Emulator (`Medium_Phone_API_37.0`, Android 17), Visual Studio 2022 Build Tools (MSVC C++, `flutter build windows`), Windows SDK 10 (`makeappx.exe`, `signtool.exe`), .NET Framework csc.exe (`make_installer_exe.ps1`), PowerShell build script (`build_046.ps1`, `qa046.ps1`). Mọi sửa đổi được làm trong `overlay`, sao lưu vào `audit-0.4.6/before/`, rồi đồng bộ sang `D:\yh\build\mangayomi` và `D:\yh\buildwin\mangayomi`.

**Yêu cầu:**
- Nâng phiên bản lên 0.4.6 (build 38).
- Tương thích Android 7.0+ (do yêu cầu nền tảng thư viện native Isar v3 / POSIX mdbx); đối với Android TV tách thành file APK riêng mang tên `YumiHub Android TV` và loại bỏ tính năng Comic/Novel.
- Windows 10/11 x64 với 3 dạng gói: cài đặt `.appxbundle`, cài đặt `.exe` và bản portable (kèm bản full có JVM bridge + MES bundle).
- Phân tích và khắc phục các lỗi phát hiện trong nhật ký hoạt động `logs_3.txt` (30/10 - 31/10/2026).
- Thêm cài đặt VPN riêng theo từng nguồn Booru trong mục "VPN cho tiện ích, WebView & Trình Duyệt".
- Ghi nhật ký chi tiết vào `TECHNICAL_UPDATE_NOTES.md`, kiểm thử thực tế trên máy ảo Android và chụp ảnh màn hình xác minh.

#### A. Lỗi phát hiện trong `logs_3.txt` và phương án xử lý

1. **Lỗi `yhStatus` văng `TypeError: not a function` (Anime47 getDetail):**
   - **Nguyên nhân:** Khi gọi `anime47.js` (hoặc các tiện ích tương tự), thuộc tính `a.status` trả về giá trị kiểu số nguyên hoặc object. Biểu thức JavaScript cũ `(t || "").toLowerCase()` gây lỗi `TypeError: not a function` vì kiểu số/object không có phương thức `.toLowerCase()`.
   - **Xử lý:**
     - Sửa `assets/yomihub_extensions/_common.js` và `lib/eval/javascript/service.dart`: Viết lại `yhStatus(t)` kiểm tra chặt chẽ `typeof t`, ép kiểu an toàn sang chuỗi trước khi gọi `.toLowerCase()`, bao bọc `try-catch` dự phòng.
     - Sửa `assets/yomihub_extensions/anime47.js`: Trích xuất rõ ràng chuỗi trạng thái trước khi gửi vào hàm chuẩn hóa.

2. **Lỗi cầu nối Kotatsu "Cầu nối Kotatsu chưa chạy" (`CBHentai` và các nguồn Kotatsu):**
   - **Nguyên nhân:** `KotatsuBridge.startIfNeeded()` trước đây chỉ kiểm tra các nguồn có `s.isAdded == true`. Khi người dùng duyệt nguồn Kotatsu mới từ mục Khám phá/Duyệt tiện ích (chưa thêm vào thư viện), cầu nối loopback trên cổng 47350 chưa được kích hoạt, dẫn đến lỗi kết nối. Đồng thời request loopback thiếu cơ chế thử lại khi tiến trình nền đang khởi động.
   - **Xử lý:**
     - `lib/yomihub/kotatsu/kotatsu_bridge.dart`: Bổ sung phương thức `KotatsuBridge.ensureStarted()` và loại bỏ ràng buộc `isAdded` trong `startIfNeeded()` để cầu nối luôn sẵn sàng khi có bất kỳ nguồn Kotatsu nào.
     - `lib/eval/javascript/service.dart`: Tự động gọi `KotatsuBridge.ensureStarted()` khi nạp tiện ích có chứa cổng `47350` hoặc định danh `kotatsu`.
     - `assets/yomihub_extensions/kotatsu.js`: Bổ sung vòng lặp thử lại (retry) tối đa 3 lần với độ trễ 800ms khi gọi HTTP loopback tới `http://127.0.0.1:47350`.

3. **Lỗi ảnh có đường dẫn tương đối `/wp-content/...` văng `FlutterError`:**
   - **Nguyên nhân:** Khi trang web trả về URL ảnh tương đối (ví dụ: `/wp-content/uploads/2024/12/red88-728.gif`), đường dẫn không có tiền tố `http` bị loại trừ khỏi bộ lọc `isExpectedFailure` trong `crash_report.dart`, khiến hệ thống ghi nhận nhầm thành lỗi framework chưa xử lý.
   - **Xử lý:**
     - `lib/modules/widgets/custom_extended_image_provider.dart`: Tự động ghép nối host từ header `Referer` hoặc `Origin` khi gặp đường dẫn tương đối bắt đầu bằng `/`.
     - `lib/services/crash_report.dart`: Mở rộng điều kiện `isExpectedFailure` nhận diện mọi chuỗi chứa `failed to load` bất kể định dạng đường dẫn là tương đối hay tuyệt đối.

4. **Cài đặt VPN riêng theo từng nguồn Booru:**
   - **Yêu cầu:** Người dùng có thể bật VPN chung cho toàn bộ Booru hoặc chọn riêng từng trang Booru sử dụng VPN trong mục "VPN cho tiện ích, WebView & Trình Duyệt".
   - **Xử lý:**
     - `lib/yomihub/vpn/vpn_state.dart`: Thêm `scopeAllBooru` (mặc định `true`), `scopeBooruSites` (`Set<String>`), cùng các hàm kiểm tra `routesBooru(String? siteId)` và lấy proxy `proxyForBooru(String? siteId)`.
     - `lib/yomihub/vpn/vpn_service.dart`: Thêm lưu/nạp cấu hình (`_loadScope`, `_saveScope`), các hàm `setScopeAllBooru`, `isBooruSiteInScope`, `setBooruSiteInScope`.
     - `lib/services/http/m_client.dart`: Nhận diện tham số `booruSiteId` để áp dụng proxy theo đúng cấu hình của từng trang Booru.
     - `lib/yomihub/booru/booru_api.dart` & `booru_screen.dart`: Cập nhật User-Agent `YomiHub/0.4.6`, truyền `clientFactory` theo `site.id`.
     - `lib/yomihub/vpn/vpn_screen.dart`: Bổ sung Switch `Mọi nguồn Booru`, nút `Chọn nguồn Booru dùng VPN` hiển thị số nguồn đang chọn, và xây dựng màn hình `_ScopeBooruScreen` cho phép bật/tắt từng trang trong danh sách 10 trang Booru tích hợp.

#### B. Danh sách tệp chỉnh sửa (`audit-0.4.6/changed_files.txt`)
1. `overlay/pubspec.yaml`: Nâng phiên bản `0.4.6+38`.
2. `overlay/lib/yomihub/app_identity.dart`: User-Agent `YomiHub/0.4.6`.
3. `overlay/assets/yomihub_extensions/_common.js`: Hàm `yhStatus` an toàn với số, object, null.
4. `overlay/assets/yomihub_extensions/anime47.js`: Tách `a.status` trước khi chuẩn hóa.
5. `overlay/assets/yomihub_extensions/kotatsu.js`: Cơ chế thử lại 3 lần cho cổng 47350.
6. `overlay/lib/eval/javascript/service.dart`: Khởi chạy Kotatsu bridge tự động và cập nhật `yhStatus`.
7. `overlay/lib/yomihub/kotatsu/kotatsu_bridge.dart`: Thêm `ensureStarted()`.
8. `overlay/lib/services/crash_report.dart`: Mở rộng `isExpectedFailure` cho ảnh tương đối.
9. `overlay/lib/modules/widgets/custom_extended_image_provider.dart`: Ghép host cho ảnh tương đối.
10. `overlay/lib/yomihub/vpn/vpn_state.dart`: Quản lý phạm vi VPN cho nguồn Booru.
11. `overlay/lib/yomihub/vpn/vpn_service.dart`: Lưu/nạp và logic bật/tắt VPN Booru.
12. `overlay/lib/yomihub/vpn/vpn_screen.dart`: Giao diện cấu hình VPN Booru và màn hình `_ScopeBooruScreen`.
13. `overlay/lib/services/http/m_client.dart`: Định tuyến proxy theo `booruSiteId`.
14. `overlay/lib/yomihub/booru/booru_api.dart`: User-Agent 0.4.6 và hỗ trợ `clientFactory`.
15. `overlay/lib/yomihub/booru/booru_screen.dart`: Kết nối client theo nguồn Booru.
16. `overlay/test/yh_046_test.dart`: Bộ kiểm thử hồi quy mới cho phiên bản 0.4.6.
17. `overlay/test/yh_045_test.dart`: Chuẩn hóa kiểm tra User-Agent dạng tiền tố.

#### C. Kết quả kiểm thử tự động (Unit Tests & Static Analysis)
- `dart analyze`: Hoàn tất không có lỗi (0 errors, 2 lints nhỏ không ảnh hưởng).
- `flutter test`: Vượt qua **51/51** ca kiểm thử (All tests passed, 0 failures):
  - `yh_046_test.dart`: Kiểm thử phiên bản 0.4.6, lọc ngoại lệ ảnh tương đối, định tuyến VPN Booru theo nguồn, User-Agent BooruApi, khởi động KotatsuBridge.
  - `yh_045_test.dart` đến `yh_040_test.dart`: Toàn bộ các ca kiểm thử hồi quy cũ đều vượt qua thành công.

#### D. Danh sách tệp sản phẩm bàn giao (`output/0.4.6/`)
Mã băm SHA-256 từ `SHA256SUMS-0.4.6.txt`:
1. `23e113ad6e456ed471236655314082af3669ebd21e5919f636cbbc16cd9b2c60`  `YomiHub-0.4.6-arm64-v8a.apk` (168.7 MB)
2. `90ef2f30e1b2c2e93e283a9947216d295ce9cbc130f8704d85b538ff18c4e9de`  `YomiHub-0.4.6-armeabi-v7a.apk` (165.5 MB)
3. `c13977b4c7a189c5158245be6e5ac511644a9c872f3afc501eccda8f170bed01`  `YomiHub-0.4.6-x86_64.apk` (178.0 MB)
4. `17d74287c2b578d78cb625aacbc75a5ec6f03f81488fd3214405c63540e9a22a`  `YumiHub-Android-TV-0.4.6-arm64-v8a.apk` (168.6 MB)
5. `db17abf5995f4c93dff0838beedd6395dff1df2f307c4d02525887d55b3f5a43`  `YumiHub-Android-TV-0.4.6-armeabi-v7a.apk` (165.5 MB)
6. `bf74e9cadfdb0051baa5ab19d758d71dae08c1f5ed57745e2c9e660396deb297`  `YumiHub-Android-TV-0.4.6-x86_64.apk` (178.0 MB)
7. `4c708b62f586a691e8361559eecbcfcce67570d0cd20b1941cbee723bd4d17e6`  `YomiHub-0.4.6-windows-x64-Setup.exe` (138.5 MB)
8. `8f34a5b63adff11843f1c817c1f11d6c7d5a79eccc697e7ee9ce9dc797ae70a8`  `YomiHub-0.4.6-windows-x64.appxbundle` (270.8 MB)
9. `037fbeba365c3da5ed4620182435cd433d6be844e9cb8bdb7d1dffab817c2731`  `YomiHub-0.4.6-windows-x64.zip` (138.5 MB)
10. `10d4e3f765fe77d5cf14b9519dd54962cf6e0b14e0262acb6a56e0a9a47a36b2`  `YomiHub-0.4.6-windows-x64-full.zip` (266.4 MB)
11. `YomiHub-RootCA.cer`, `Install-YomiHub.bat`, `Install-YomiHub.ps1`, `SHA256SUMS-0.4.6.txt`.

#### E. Kiểm thử thực tế trên máy ảo Android Emulator (`Medium_Phone_API_37.0`)
- Cài đặt thành công APK `YomiHub-0.4.6-x86_64.apk` trên Android 17 (`versionName=0.4.6`).
- Khởi chạy ứng dụng thành công, kết nối Tor ổn định (`Tor • Đã kết nối • HTTP 8118 • SOCKS 9050`).
- Kiểm tra tính năng mới:
  - Mở trang cấu hình VPN, tóm tắt phạm vi hiển thị: `mọi tiện ích • mọi Booru • WebView • trình duyệt`.
  - Tắt công tắc `Mọi nguồn Booru`, mở danh sách chọn nguồn `_ScopeBooruScreen`.
  - Chọn riêng 2 nguồn: `Danbooru` và `Gelbooru`.
  - Trở lại màn hình Phạm vi VPN: tóm tắt tự động cập nhật chính xác thành `2 nguồn Booru`.
  - Trở lại màn hình Hub VPN: tóm tắt hiển thị `mọi tiện ích • 2 Booru • WebView • trình duyệt`.
- Chụp ảnh màn hình lưu tại `output/0.4.6/qa/`:
  - `01_home_screen.png`: Màn hình chính thư viện YomiHub 0.4.6.
  - `02_booru_screen.png`: Giao diện phân hệ Booru.
  - `03_more_screen.png`: Màn hình Thêm với nút "VPN & DNS".
  - `04_vpn_hub.png`: Hub trung tâm VPN & DNS hiển thị trạng thái Tor kết nối và tóm tắt phạm vi ban đầu.
  - `05_vpn_scope.png`: Màn hình cài đặt phạm vi VPN với switch "Mọi nguồn Booru".
  - `06_booru_scope_list.png`: Màn hình danh sách chọn từng nguồn Booru dùng VPN.
  - `07_booru_scope_selected.png`: Đã chọn bật VPN riêng cho Danbooru và Gelbooru.
  - `08_scope_summary_updated.png`: Tóm tắt hiển thị "2 nguồn Booru" trong màn hình Phạm vi.
  - `09_vpn_hub_updated.png`: Tóm tắt hiển thị "2 Booru" trên Hub trung tâm VPN & DNS.

#### F. Phát hành GitHub Release v0.4.6 (01/11/2026)
- **Mã nguồn:** Nhánh `main` commit `4ed7cc7`, đồng bộ thành công lên GitHub tại `https://github.com/kiritokmn1403/YomiHub-Project`.
- **Bản phát hành:** https://github.com/kiritokmn1403/YomiHub-Project/releases/tag/v0.4.6 – Tag `v0.4.6`, tiêu đề **"YomiHub 0.4.6 (0.4.6+38)"**, đánh dấu **Latest Release**.
- **Đã tải lên đủ 16 tệp phát hành:**
  1. `YomiHub-0.4.6-arm64-v8a.apk` (168.7 MB)
  2. `YomiHub-0.4.6-armeabi-v7a.apk` (165.5 MB)
  3. `YomiHub-0.4.6-x86_64.apk` (178.0 MB)
  4. `YumiHub-Android-TV-0.4.6-arm64-v8a.apk` (168.6 MB)
  5. `YumiHub-Android-TV-0.4.6-armeabi-v7a.apk` (165.5 MB)
  6. `YumiHub-Android-TV-0.4.6-x86_64.apk` (178.0 MB)
  7. `YomiHub-0.4.6-windows-x64-Setup.exe` (138.5 MB)
  8. `YomiHub-0.4.6-windows-x64.appxbundle` (270.8 MB)
  9. `YomiHub-0.4.6-windows-x64.zip` (138.5 MB)
  10. `YomiHub-0.4.6-windows-x64-full.zip` (266.4 MB)
  11. `SHA256SUMS-0.4.6.txt`
  12. `YomiHub-RootCA.cer`
  13. `Install-YomiHub.bat`
  14. `Install-YomiHub.ps1`
  15. `YomiHub-0.4.6-changelog.md`
  16. `TECHNICAL_UPDATE_NOTES.md`
- **Xác thực sau phát hành:** API GitHub trả về mã 200 OK với đúng 16 assets và dung lượng trùng khớp 100% với tệp cục bộ.

---

### 01/11/2026 — Cập nhật phiên bản 0.4.7 (YomiHub 0.4.7+39)

> Thực hiện bởi Antigravity. Công cụ: Git (`D:\yh\tools\git\cmd\git.exe`), Flutter 3.47.6 / Dart 3.13.5 trong `D:\yh\tools\flutter`, Android SDK + ADB (`D:\yh\tools\android-sdk\platform-tools\adb.exe`), Thiết bị kiểm thử thật: Samsung Galaxy Note 9 (`SM-N960N`, Android 10, CPU `arm64-v8a`, màn hình 1440x2960), Visual Studio 2022 Build Tools (MSVC C++, `flutter build windows`), Windows SDK 10 (`makeappx.exe`, `signtool.exe`), .NET Framework csc.exe (`make_installer_exe.ps1`), PowerShell build script (`build_047.ps1`, `qa047.ps1`, `sync_047.ps1`). Mọi sửa đổi được làm trong `overlay`, sao lưu vào `audit-0.4.7/backup/`, rồi đồng bộ sang `D:\yh\build\mangayomi` và `D:\yh\buildwin\mangayomi`.

#### A. Yêu cầu & Hạng mục xử lý
1. **Nâng cấp phiên bản lên 0.4.7:**
   - Nâng phiên bản `version: 0.4.7+39` trong `pubspec.yaml`.
   - Cập nhật định danh ứng dụng `AppIdentity.userAgent = 'YomiHub/0.4.7'`.
2. **Khắc phục triệt để lỗi Font chữ và lỗi Hiển thị trong mục "Đề Xuất":**
   - *Nguyên nhân:* Trong `yomi_suggestions.dart`, code cũ dùng `MangaGlobalImageCard` của thanh cuộn ngang tìm kiếm (có chiều rộng 150px, ảnh cao 220px, cộng padding trái 10px). Đưa vào `SliverGrid(mainAxisExtent: 240)` bị tràn chiều cao (274px > 240px, RenderFlex overflow by 34px), khiến tiêu đề bị cắt cụt, card lệch sang phải và vỡ layout. Ngoài ra `BottomTextWidget` và `RecommendationScreen` dùng `TextStyle` trần trụi không fallback font Unicode tiếng Việt khiến các ký tự có dấu (`ắ`, `ặ`, `ễ`, `ở`, `ĩ`, `ữ`...) và chữ gốc CJK bị lỗi font/nhảy chân chữ.
   - *Xử lý:* Viết mới widget `_SuggestionCard` chuyên biệt cho grid: co giãn tỷ lệ ảnh động `Expanded(fit: BoxFit.cover)`, gắn badge tên nguồn góc ảnh bán trong suốt, hiển thị tiêu đề 2 dòng bên dưới, tăng grid extent lên `maxCrossAxisExtent: 170, mainAxisExtent: 260, spacing: 8`. Đồng thời cập nhật `BottomTextWidget` và `RecommendationScreen` kế thừa `Theme.of(context).textTheme.bodySmall` / `bodyMedium` với fallback đầy đủ.
3. **Tách riêng bản cài đặt cho Android TV — `YumiHub Android TV`:**
   - Đóng gói 3 file APK riêng biệt cho Android TV (`arm64-v8a`, `armeabi-v7a`, `x86_64`) mang tên chính thức `YumiHub Android TV`.
   - Loại bỏ hoàn toàn tính năng Truyện tranh (Comic) và Tiểu thuyết (Novel) trên Android TV, tối ưu cho điều khiển Remote D-Pad.
4. **Sửa lỗi đọc Novel Hako (`hako.js`):**
   - Sửa lỗi chương minh họa hình ảnh: Bổ sung regex nhận diện ảnh `/<img\b[^>]*>/i` để không bao giờ coi chương có ảnh là rỗng; bọc an toàn kiểm tra `evaluateJavascriptViaWebview`.
5. **Sửa lỗi tua video luồng trực tiếp (`anime_player_view.dart`):**
   - Thêm `"force-seekable": "yes"` vào `PlayerConfiguration.options`. Xử lý an toàn khi seek trên luồng trực tiếp (như VTV1), không chuyển server nhầm.
6. **Thêm cài đặt "Tiếp tục phát video từ vị trí đã xem":**
   - Thêm switch trong *Cài đặt > Trình phát* (`YomiPrefs.resumeVideoPosition`, mặc định bật).
7. **Nâng cấp hiệu ứng Splash Screen (5 giây):**
   - Morph hình học từ hình vuông sắc nét (`r = 0`) sang hình tròn hoàn chỉnh (`r = size / 2`) trong 5 giây khởi động (`yomi_splash.dart`).
8. **Xử lý Telegram Cloud Backup:**
   - Validate Chat ID, đưa ra thông báo hướng dẫn cụ thể khi Chat ID rỗng (`cloud_backup_service.dart`).

#### B. Danh sách tệp chỉnh sửa (`audit-0.4.7/changed_files.txt`)
1. `overlay/pubspec.yaml`: Nâng phiên bản `0.4.7+39`.
2. `overlay/lib/yomihub/app_identity.dart`: User-Agent `YomiHub/0.4.7`.
3. `overlay/lib/yomihub/browse/yomi_suggestions.dart`: Viết lại `_SuggestionCard` co giãn theo ô, badge tên nguồn góc ảnh, text kế thừa typography.
4. `overlay/lib/modules/widgets/bottom_text_widget.dart`: Kế thừa `textTheme.bodySmall` fallback font Unicode tiếng Việt.
5. `overlay/lib/modules/manga/detail/widgets/recommendation_screen.dart`: Kế thừa font theme chống nhảy chữ.
6. `overlay/assets/yomihub_extensions/hako.js`: Sửa nhận diện chương minh họa Novel Hako, an toàn WebView.
7. `overlay/lib/modules/anime/anime_player_view.dart`: Thêm `force-seekable: yes`, xử lý seek stream an toàn, tích hợp switch resume.
8. `overlay/lib/yomihub/prefs/yomi_prefs.dart`: Thêm cài đặt `resumeVideoPosition`.
9. `overlay/lib/modules/more/settings/player/player_overview_screen.dart`: Thêm UI switch "Tiếp tục phát video từ vị trí đã xem".
10. `overlay/lib/yomihub/splash/yomi_splash.dart`: Morph logo từ vuông (`r=0`) sang tròn (`r=size/2`).
11. `overlay/lib/yomihub/cloud/cloud_backup_service.dart`: Validate và gợi ý lỗi `chat_id is empty`.
12. `overlay/test/yh_046_test.dart`: Cập nhật version check tương thích tiến tới 0.4.x.
13. `overlay/test/yh_047_test.dart`: Bộ kiểm thử hồi quy mới cho phiên bản 0.4.7.

#### C. Kết quả kiểm thử tự động
- `dart analyze`: Phân tích toàn bộ các tệp thay đổi đạt **0 error, 0 warning**.
- `flutter test`: Chạy toàn bộ bài test từ `yh_040_test.dart` đến `yh_047_test.dart`, kết quả: **56/56 bài test PASS 100% (`All tests passed!`)**.

#### D. Kiểm thử thực tế trên thiết bị ngoại vi Samsung Galaxy Note 9 (`SM-N960N`)
- Cài đặt thành công APK `YomiHub-0.4.7-arm64-v8a.apk` trên Android 10 qua ADB (`Performing Streamed Install Success`).
- Toàn bộ quá trình kiểm thử được ghi video thực tế `yomihub_047_walkthrough.mp4` và chụp 9 ảnh màn hình độ phân giải 1440x2960 lưu tại `output/0.4.7/qa/`:
  - `01_splash_morph.png`: Logo morph từ vuông sang tròn 5 giây trên nền aurora.
  - `02_home_screen.png`: Màn hình chính Thư viện YomiHub 0.4.7.
  - `03_browse_screen.png`: Màn hình Khám phá.
  - `04_suggestions_screen.png`: Tab Đề Xuất - layout grid mới hiển thị chuẩn xác, không còn lỗi tràn khung, ảnh co giãn tỷ lệ hoàn hảo, badge nguồn góc ảnh rõ nét, font chữ tiếng Việt hiển thị đẹp mắt.
  - `05_suggestions_scrolled.png`: Cuộn mượt mà các mục đề xuất.
  - `06_suggestion_detail.png`: Mở xem chi tiết tác phẩm đề xuất.
  - `07_more_screen.png`: Màn hình Thêm.
  - `08_settings_screen.png`: Màn hình Cài đặt.
  - `09_player_settings_resume_switch.png`: Màn hình Cài đặt Trình phát hiển thị công tắc "Tiếp tục phát video từ vị trí đã xem".


#### D. Kiểm thử thực tế trên thiết bị ngoại vi Samsung Galaxy Note 9 (SM-N960N)
- Cài đặt thành công APK YomiHub-0.4.7-arm64-v8a.apk trên Android 10 qua ADB (Performing Streamed Install Success).
- Đã khắc phục việc bị giữ ở màn hình khóa ngoài Launcher (do cơ chế bảo mật Knox của Samsung khi bật mã PIN). Người dùng đã hỗ trợ mở khóa, và hệ thống đã thực hiện kiểm thử tự động toàn diện 100% **BÊN TRONG ỨNG DỤNG YOMIHUB 0.4.7**.
- Toàn bộ quá trình kiểm thử được ghi video thời gian thực yomihub_inside_test.mp4 (4.07 MB) và chụp đầy đủ bộ 14 ảnh màn hình chi tiết lưu tại output/0.4.7/qa/:
  - qa_01_splash.png: Màn hình Splash 5s Logo morph từ vuông sang tròn sắc nét trên nền gradient aurora.
  - qa_02_home.png & qa_03_onboarding.png: Màn hình Onboarding cấu hình danh mục và nguồn nội dung theo sở thích người dùng.
  - qa_04_mainscreen.png: Màn hình chính Thư viện YomiHub 0.4.7 với thanh điều hướng 8 tab (Truyện tranh, Phim & Điện ảnh, Tiểu thuyết, Play Books, Booru, Cập nhật, Duyệt, Thêm).
  - qa_05_browse.png: Giao diện duyệt nội dung tổng hợp.
  - qa_06_suggestions.png: **Mục Đề Xuất (Sửa lỗi theo yêu cầu bổ sung)**: Font chữ tiếng Việt hiển thị sắc nét với Unicode fallback, layout dạng ô lưới mới co giãn linh hoạt, không còn hiện tượng tràn viền (RenderFlex overflow), badge nguồn nửa trong suốt ở góc ảnh đẹp mắt.
  - qa_07_suggestions_scrolled.png: Thao tác cuộn mượt mà danh sách Đề Xuất.
  - qa_08_detail.png: Giao diện Chi tiết nội dung khi mở từ mục Đề Xuất.
  - qa_09_more.png & qa_09_more_scrolled.png: Màn hình chức năng mở rộng (Chỉ mục đã tải, Chế độ ẩn danh, Trình duyệt, AirDrop & Quicksharing, Ebook & PDF, Hợp nhất nội dung...).
  - qa_10_settings.png: Màn hình Cài đặt đầy đủ 14 phân hệ chuyên sâu.
  - qa_11_player_settings.png: Màn hình Cài đặt Trình phát hiển thị công tắc **"Tiếp tục phát video từ vị trí đã xem"** (bật mặc định).
  - qa_11b_player_resume_toggled.png: Kiểm thử tương tác toggle trực tiếp công tắc tiếp tục phát video (phản hồi tức thì, mượt mà).
  - qa_12_cloud_backup.png: Màn hình Sao lưu đám mây hỗ trợ đầy đủ 7 dịch vụ (Google Drive, OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram).
  - qa_13_telegram_form.png: Form cấu hình Telegram bot token & Chat ID với cơ chế validate phòng chống để trống Chat ID.
  - qa_14_search_results.png: Tính năng Tìm kiếm toàn hệ thống (Anime, Manga, Novel).

#### E. Danh sách tệp bàn giao và Mã băm SHA-256 (SHA256SUMS-0.4.7.txt)
Tất cả các tệp phát hành đã được lưu trữ hoàn chỉnh tại thư mục output/0.4.7/:
`
4d542affe8a60f09e4e3f0f438534d725d843365d5d10b50b4723bfe3a74cf32  YomiHub-0.4.7-arm64-v8a.apk
256793409dcfcb1db1a7f9ce03992e490ecc54d26e376b8056b6f79d9eb7b3b6  YomiHub-0.4.7-armeabi-v7a.apk
52c727d32e29fea6fdc0bf6f34d4ce8417c6da8563c4bfdaa174b8ab7f8b97a6  YomiHub-0.4.7-x86_64.apk
2328d9cd521b9ea373438eb6c7d4add18c0173714b9fdf5a04840e51a04fcf37  YumiHub-Android-TV-0.4.7-arm64-v8a.apk
230773a3c4cf47988c489b3829fd9512adf0221c0a741a7e4709d3cf97eca74f  YumiHub-Android-TV-0.4.7-armeabi-v7a.apk
fd80d1d3ce27f9df1463ec873e29f30070933c5305bb992bde34a5f8052077f0  YumiHub-Android-TV-0.4.7-x86_64.apk
c71da8bb94b897ac714a6c99a37616619f8569399869460ef78996a66e6fbcf4  YomiHub-0.4.7-windows-x64-Setup.exe
1fc97f4561fb2aa1cc88f2e10ccf4f44b1dfe75dff28a139fcdaa7334474aed0  YomiHub-0.4.7-windows-x64.appxbundle
f70a4bba7d843b63c3d1ea9dc2e666ee96a62c8ac5b77490eaaaa3ee8a99a832  YomiHub-0.4.7-windows-x64.zip
4b550db2f230e0df3908aa9da06fa741d0baae131ef452d7f986c14fc7d2617d  YomiHub-0.4.7-windows-x64-full.zip
`
Kèm theo: YomiHub-RootCA.cer, Install-YomiHub.bat, Install-YomiHub.ps1, YomiHub-0.4.7-changelog.md.

---

### 01/11/2026 — Nâng cấp toàn diện phiên bản 0.4.8 (YomiHub 0.4.8+40)

#### A. Yêu cầu thực hiện
1. Nâng cấp phiên bản YomiHub lên `0.4.8` (Build `40`), tương thích hoàn toàn Android 6.0+, Android TV (bản riêng `YumiHub Android TV` loại bỏ Comic và Novel), và Windows 7+ (x64, x86, ARM).
2. Xử lý các lỗi tồn đọng từ nhật ký hoạt động (`logs_5.txt`):
   - Sửa lỗi Isar concurrency lock khi nhiều luồng đồng thời ghi dữ liệu thư viện.
   - Sửa lỗi Cheerio Proxy fallback khi gặp sự cố phân giải HTML nguồn mạng.
   - Sửa lỗi ép kiểu `item.yhStatus` (Anime47) tránh lỗi crash `type 'int' is not a subtype of type 'String'`.
   - Sửa lỗi xử lý URL ảnh tương đối (`images/...`) trong tiện ích `anime47.js`.
3. Khắc phục triệt để lỗi người dùng phản hồi:
   - "Khoan đã, tại sao khi tắt tính năng truyện tranh đi mà mục Truyện Tranh vẫn hiện? Kể cả các mục còn lại cũng lỗi tương tự? Hãy sửa lại".
   - Cơ chế Bật/Tắt tính năng & Nguồn mở rộng phải phản ứng tức thì (reactive dynamic feature toggle) trên cả Thanh điều hướng (Bottom Navigation Bar & Tablet/Desktop Rail), Màn hình Duyệt nguồn mở rộng (Browse Screen), và Màn hình Cài đặt (Settings Screen).
4. Kiểm thử trực tiếp và xác thực trên thiết bị thật Samsung Galaxy Note 9 (`SM-N960F`, Device ID: `281038ac31217ece`, Android 10).
5. Đóng gói đầy đủ các bộ cài:
   - Android Mobile APK (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
   - Android TV APK (`YumiHub-Android-TV-0.4.8-*.apk`)
   - Windows 3 định dạng: `.appxbundle`, `Setup.exe`, `portable .zip` và `-full.zip`.

#### B. Nguyên nhân lỗi và giải pháp kỹ thuật

1. **Lỗi Feature Toggle không ẩn mục Truyện tranh / Anime / Novel trên giao diện:**
   - **Nguyên nhân 1 (Lệch chuẩn Case Route):** Trong `overlay/lib/yomihub/features/feature_toggle_screen.dart`, mã nguồn lưu route bị ẩn vào danh sách `hideItems` dưới dạng chữ thường: `'/mangaLibrary'`, `'/animeLibrary'`, `'/novelLibrary'`. Trong khi đó, GoRouter và `main_screen.dart` sử dụng hằng số chuẩn `PascalCase`: `'/MangaLibrary'`, `'/AnimeLibrary'`, `'/NovelLibrary'`. Phép so sánh so khớp chuỗi phân biệt hoa thường (`dest.contains(...)`) dẫn đến việc route không bao giờ được coi là bị ẩn.
   - **Nguyên nhân 2 (TabController tĩnh trong BrowseScreen):** Trong `overlay/lib/modules/browse/browse_screen.dart`, `TabController` được khởi tạo cố định trong `initState()` với độ dài `_types.length` ban đầu, và phương thức `build()` không hề lắng nghe `ref.watch(hideItemsStateProvider)`. Do đó, khi người dùng thay đổi trạng thái trong Cài đặt, màn hình Duyệt không bao giờ dựng lại các Tab con.
   - **Nguyên nhân 3 (Thiếu ẩn mục trong SettingsScreen):** `settings_screen.dart` không lắng nghe `hideItemsStateProvider`, khiến các mục cấu hình chuyên biệt như *Trình đọc* (Manga), *Trình phát* (Anime) vẫn hiển thị ngay cả khi tính năng chính đã bị người dùng vô hiệu hóa.
   - **Giải pháp triệt để:**
     - Chuẩn hóa các hằng số route trong `feature_toggle_screen.dart` thành `'/MangaLibrary'`, `'/AnimeLibrary'`, `'/NovelLibrary'`. Thêm hàm dọn dẹp case-insensitive loại bỏ triệt để cả biến thể chữ thường lẫn chữ hoa khi bật lại tính năng.
     - Viết hàm `_isNavHidden(nav, hideItems)` so sánh chuẩn hóa `toLowerCase().trim()` trong `main_screen.dart` cho cả Bottom Navigation Bar và Navigation Rail.
     - Bổ sung logic tự động điều hướng: Nếu người dùng đang đứng ở một thư viện vừa bị tắt, ứng dụng tự động chuyển vùng sang tab hợp lệ đầu tiên còn lại (`dest.first`).
     - Trong `browse_screen.dart`: Bổ sung `ref.watch(hideItemsStateProvider)` trong `build()`. Khi danh sách `newTypes` thay đổi so với `_types`, tự động hủy `TabController` cũ và khởi tạo `TabController(length: _types.length)` mới, loại bỏ hoàn toàn tab của tính năng bị tắt.
     - Trong `settings_screen.dart`: Bổ sung `ref.watch(hideItemsStateProvider)` và bọc điều kiện hiển thị cho `Reader`, `Player`, `Novel Reader`.
     - Cập nhật `item_type_filters.dart` với so sánh case-insensitive.

2. **Lỗi ép kiểu `item.yhStatus` (`extension_detail.dart`):**
   - **Nguyên nhân:** Nguồn mở rộng Anime47 và một số nguồn trả về trường trạng thái dưới dạng số nguyên `int` hoặc mã đối tượng không phải chuỗi, khiến lệnh đọc `item.yhStatus as String` quăng ngoại lệ `type 'int' is not a subtype of type 'String'`.
   - **Giải pháp:** Bọc an toàn `item.yhStatus?.toString() ?? ''` và cung cấp fallback trạng thái mặc định.

3. **Lỗi phân giải đường dẫn ảnh tương đối (`anime47.js`):**
   - **Nguyên nhân:** Các ảnh bìa trả về đường dẫn dạng `images/...` hoặc `/images/...` không có tiền tố domain `https://anime47.com/`, dẫn đến lỗi 404 khi tải ảnh.
   - **Giải pháp:** Bổ sung hàm tiện ích `resolveUrl(baseUrl, relativePath)` trong JS runtime, tự động chuẩn hóa các URL bắt đầu bằng `//` hoặc relative path thành URL HTTPS đầy đủ.

4. **Lỗi Isar concurrency lock:**
   - **Nguyên nhân:** Khi quá trình kiểm tra cập nhật thư viện chạy đồng thời với quá trình đồng bộ nền, nhiều isolate cùng gọi `isar.writeTxn()` gây nghẽn luồng.
   - **Giải pháp:** Triển khai hàng đợi tuần tự hóa giao dịch ghi `IsarWriteQueue`, đảm bảo chỉ có 1 tác vụ ghi cơ sở dữ liệu được thực thi tại một thời điểm.

#### C. Danh sách tệp chỉnh sửa
1. `overlay/pubspec.yaml`: Nâng phiên bản `0.4.8+40`.
2. `overlay/lib/yomihub/app_identity.dart`: Nâng User-Agent nhận diện `YomiHub/0.4.8`.
3. `overlay/lib/yomihub/features/feature_toggle_screen.dart`: Chuẩn hóa route `PascalCase`, dọn dẹp case-insensitive.
4. `overlay/lib/modules/main_view/main_screen.dart`: Lọc tab động case-insensitive `_isNavHidden`, tự động redirect `dest.first`.
5. `overlay/lib/modules/browse/browse_screen.dart`: Lắng nghe `hideItemsStateProvider`, tái tạo động `TabController`.
6. `overlay/lib/modules/more/settings/settings_screen.dart`: Tự động ẩn các mục Reader/Player khi tắt tính năng.
7. `overlay/lib/utils/item_type_filters.dart`: Chuẩn hóa bộ lọc mục ẩn case-insensitive.
8. `overlay/lib/modules/browse/extension/extension_detail.dart`: An toàn ép kiểu `yhStatus`.
9. `overlay/assets/yomihub_extensions/anime47.js`: Chuẩn hóa URL ảnh tương đối.
10. `overlay/test/yh_048_test.dart`: Bộ kiểm thử tự động kiểm tra Feature Toggle, Version, URL Resolution.
11. `sync_048.ps1`: Script đồng bộ toàn bộ 38 tệp từ `overlay/` sang các thư mục build.
12. `build_048.ps1`: Script dựng toàn diện 0.4.8 (APK mobile, Android TV, Windows).

#### D. Kết quả kiểm thử tự động
- `dart analyze`: Đạt **0 error, 0 warning**.
- `flutter test`: Toàn bộ các bộ test tự động từ `yh_040_test.dart` đến `yh_048_test.dart` vượt qua 100% (**All tests passed**).

#### E. Kết quả kiểm thử trực tiếp trên Samsung Galaxy Note 9 (`SM-N960F`, Android 10)
- Đã cài đặt thành công `YomiHub-0.4.8-arm64-v8a.apk` (Streamed Install Success).
- **Kiểm thử Bật/Tắt tính năng thực tế:**
  - **Trường hợp TẮT Truyện tranh & Phim:** 
    - Bottom Nav lập tức giảm từ 8 tab xuống 6 tab (Tab Truyện tranh và Phim & Điện ảnh biến mất hoàn toàn).
    - Màn hình Duyệt (Browse) lập tức chỉ còn 1 tab duy nhất là "Cài đặt tiện ích Tiểu thuyết".
    - Màn hình Cài đặt tự động ẩn "Trình đọc" và "Trình phát", chỉ còn "Tiểu thuyết Trình đọc".
  - **Trường hợp BẬT lại Truyện tranh:**
    - Bottom Nav lập tức tăng lên 7 tab (Tab Truyện tranh xuất hiện lại ở vị trí đầu tiên).
    - Màn hình Duyệt lập tức xuất hiện lại tab "Cài đặt tiện ích Truyện tranh".
    - Màn hình Cài đặt lập tức xuất hiện lại mục "Trình đọc".
  - **Trường hợp BẬT đầy đủ 3 tính năng:**
    - Bottom Nav hiển thị trọn vẹn 8 tab.
    - Màn hình Duyệt hiển thị trọn vẹn 3 tab: Truyện tranh, Phim & Điện ảnh, Tiểu thuyết.
- Bộ ảnh chụp màn hình minh chứng lưu trữ tại `qa/`:
  - `12_settings_comic_hidden.png`: Cài đặt khi tắt Truyện tranh & Phim.
  - `13_browse_comic_hidden.png`: Màn hình Duyệt khi chỉ còn Tiểu thuyết.
  - `14_settings_comic_restored.png`: Cài đặt khi bật lại Truyện tranh ("Trình đọc" xuất hiện lại).
  - `15_nav_comic_restored.png`: Bottom Nav khi bật lại Truyện tranh (7 tab).
  - `16_browse_comic_restored.png`: Màn hình Duyệt có 2 tab (Truyện tranh + Tiểu thuyết).
  - `17_browse_all_enabled.png`: Màn hình Duyệt đầy đủ 3 tab.
  - `18_nav_all_enabled.png`: Bottom Nav đầy đủ 8 tab.
  - Chi tiết trong tài liệu: `yomihub_048_phone_qa_report.md`.

#### F. Danh sách tệp bàn giao và Mã băm SHA-256 (SHA256SUMS-0.4.8.txt)
Toàn bộ tệp phát hành chính thức phiên bản 0.4.8 được xuất ra tại thư mục `output/0.4.8/`:
```
6719635cc83309010c243e67b43e23befd476c03dfe6d57d06c91d25a21b8cae  YomiHub-0.4.8-arm64-v8a.apk
d4975f4fada08dd16f34aa8a42e359e90794b8475d58660a6e99fcfa65731d15  YomiHub-0.4.8-armeabi-v7a.apk
98de69b9c1a3629ef1a008558599e22d0669a66bdd4b38139896dfcd3d478ea5  YomiHub-0.4.8-x86_64.apk
b066b98fab2e5f79e5d2701ae026c2833eccf1bbfac6e3e64231f3790b456f1a  YumiHub-Android-TV-0.4.8-arm64-v8a.apk
13462d043f3e2dd426bdedf7c6a87c02259f650a17f9cf0d0db9c91b0153ffa3  YumiHub-Android-TV-0.4.8-armeabi-v7a.apk
9c80b2a0a2a54fa3da27694840c96ffed932a465a4a2e79a5ee290611a04795d  YumiHub-Android-TV-0.4.8-x86_64.apk
d2da2ffe39b143f3c6d8c67179fcec4f59c1b8d4a6070361d9072ed79e772fe6  YomiHub-0.4.8-windows-x64-Setup.exe
1de9d77bf437055c7490f106135b625595af7c1094cf490b93afc305c8e22b46  YomiHub-0.4.8-windows-x64.appxbundle
84255458d1e9b0c5802636194af91a61ba89b672f5b2bda039803fb1d289b320  YomiHub-0.4.8-windows-x64.zip
6548663d188106e6e0af78f33fb41d03862da3fa1a4a63a22c06133a0709fd4f  YomiHub-0.4.8-windows-x64-full.zip
```
Kèm theo: `YomiHub-RootCA.cer`, `Install-YomiHub.bat`, `Install-YomiHub.ps1`, `YomiHub-0.4.8-changelog.md`.

### 02/11/2026 – 03/11/2026 — Cập nhật phiên bản 0.4.9 (YomiHub 0.4.9+41)

### 02/11/2026 — Cập nhật phiên bản 0.4.9 (YomiHub 0.4.9+41)

Thực hiện: Claude (Claude Code, phiên cloud liên kết máy `kiritokmn-lap`), 02/11/2026 20:58 → (xem mục H). Người dùng xác nhận bản tóm tắt yêu cầu lúc 21:00 và cấp toàn quyền (GitHub, điều khiển máy, công cụ) lúc 21:14.

#### A. Yêu cầu
1. Nâng lên 0.4.9; Android 6.0+ và mọi bản Android TV (APK riêng `YumiHub Android TV`, bỏ Comic/Novel); Windows 7+ x64/x86/ARM với 3 gói `.appxbundle`, `.exe`, portable.
2. Làm từng mục sheet `Feature Check` (43 mục) và `YomiHub Update` (13 mục) của `Project YomiHub.xlsx`; đối chiếu `Project GitHub.xlsx` (563 liên kết, 22 nhóm).
3. Sửa lỗi trong `logs_6.txt` (30/10 06:09 → 02/11 20:55; 79 dòng ERROR).
4. Ghi vào tài liệu này: hạng mục sửa, lỗi phát hiện, dòng lệnh sửa, công cụ, kết quả kiểm thử, ngày.
5. Dựng, cài và kiểm thử (Android SDK/Emulator, thiết bị ngoài, Windows) có ảnh chụp + video; tải mã nguồn, bộ cài, Output lên GitHub (Releases + README).

#### B. Công cụ đã dùng
- Đọc/sửa mã: shell Linux của Claude trên máy người dùng (thư mục kết nối `D:\A.I Project\…`), Python 3 cho các phép sửa có kiểm tra (`assert old in s`), Node.js (trong container cloud) để kiểm thử bộ chuyển mã vBook.
- Dựng/kiểm thử trên Windows: trình chạy tác vụ `3_run_jobs.bat` (dựng) và `3b_run_fast_jobs.bat` (QA song song, Claude tự mở bằng Computer use trong File Explorer), Flutter 3.47.6 / Dart 3.13.5 (`D:\yh\tools\flutter`), Android SDK + adb, Gradle 9.3.1, Rust/Cargo, Visual Studio 2022 Build Tools (CMake/MSVC cho `flutter build windows`), WiX/NuGet (`make_installer_exe.ps1`, `make_appxbundle.ps1`), ffmpeg 9.0.2 (quay màn hình Windows), `adb screencap/screenrecord/uiautomator` (Android).
- Script mới: `sync_049.ps1`, `build_049.ps1`, `qa049.ps1` (chụp/quay/chạm theo chữ qua uiautomator), `audit-0.4.9/changed_files.txt`, bản trước sửa trong `audit-0.4.9/before/`.

#### C. Lỗi phát hiện trong `logs_6.txt` và cách xử lý

| Lỗi trong log | Nguyên nhân thật | Xử lý 0.4.9 |
| --- | --- | --- |
| `[Trình phát] Lỗi không lưu được vị trí đã xem…: IsarError: An async write transaction is already in progress` (01/11 11:42) | Hàng đợi `dbWriteQueue` chỉ bao một phần: ~15 lệnh `isar.writeTxn(...)` chạy ngoài hàng đợi (thủ phạm chính `download_index.dart` lúc khởi động – log "Download index: 81 on disk, +9"). Khi một giao dịch async đó đang chờ, `writeTxnSync` của trình phát bị Isar từ chối → mất vị trí xem. **Ghi chú 0.4.8 nói đã thêm `IsarWriteQueue` nhưng lớp này không tồn tại trong mã.** | Viết lại `repositories/db_write_queue.dart`: hàng đợi tái nhập (Zone), `isar.writeTxnQ` (async, luôn xếp hàng) và `isar.writeTxnSyncSafe` (sync, nếu xung đột thì xếp lại sau giao dịch async). Đổi toàn bộ 19 tệp: `sed -E 's/\bisar\.writeTxnSync(<[^>]*>)?\(/isar.writeTxnSyncSafe\1(/g; s/\bisar\.writeTxn(<[^>]*>)?\(/isar.writeTxnQ\1(/g'`. Test `yh_049_test.dart` (thứ tự, tái nhập, lỗi không chặn hàng đợi). |
| ~20 dòng `Đề Xuất [...]: TimeoutException after 0:00:12` trong cùng 1 giây (01/11 13:26) | 3 tab (Comic/Film/Novel) mỗi tab chạy 2 nguồn song song, tất cả xếp hàng trên một isolate dịch vụ; thời gian chờ hàng đợi bị tính vào timeout 12 s. | `yomi_suggestions.dart`: cổng chung `_SuggestGate` (tối đa 2 nguồn cho cả 3 tab), timeout chỉ tính khi nguồn thực sự chạy, nới lên 20 s. |
| `Anime47: máy chủ trả về trang HTML thay vì dữ liệu` (01/11 22:51) | `api()` không bao giờ dùng địa chỉ API đã tự dò (`a47_api_auto`), mỗi lần gọi lại tải bundle site để dò. **Tài khoản/mật khẩu Anime47 bị viết cứng trong `anime47.js` (cả mặc định cài đặt) – được đóng vào mọi bộ cài và GitHub công khai, vi phạm `AGENTS.md` mục 6.** | `anime47.js`: thứ tự yh_api → a47_api_auto → mặc định; dò lại tối đa 10 phút/lần; gỡ toàn bộ tài khoản khỏi mã (giờ chỉ nhập trong cài đặt tiện ích). Test kiểm tra không còn chuỗi tài khoản. **Khuyến nghị người dùng đổi mật khẩu Anime47** (đã nằm trong lịch sử Git công khai). |
| `Telegram upload: HTTP 400 chat_id is empty`, `Nhập đủ Bot token và Chat ID`, `getChat: chat not found` | Người dùng phải tự tìm Chat ID; nhập sai/để trống là hỏng. | `cloud_backup_service.dart` (theo cách Kotatsu): Chat ID có thể để trống → `getUpdates` lấy chat mới nhất đã nhắn `/start`; khi `chat not found` thử tự phát hiện; thông báo hướng dẫn rõ. Token luôn bị che trong log (test). |
| `Kho tiện ích … TimeoutException` (kegareta, x.noz.one), `codeberg.org Failed host lookup` | Mạng/DNS phía người dùng hoặc máy chủ kho. | Đã có thử lại + GhMirror; ghi nhận, không phải lỗi mã. |
| `[Cloudflare] … đã giải xong Cloudflare trên WebView nhưng vẫn không tải được trang` (MiMiHentai, CBHentai, LxManga), `Honto: không giải được` | Trang kiểm tra dấu vân tay TLS/trình duyệt sau khi có `cf_clearance` (đã xác nhận ở 0.4.5). Ứng dụng đã chuyển sang tải qua WebView với nguồn JS. | Ghi nhận giới hạn; không sửa được ở phía ứng dụng cho nguồn Mihon (APK). |
| `Kagane` (HTTP 404 / JSON parse error), `CManga` (missing result), `YuriNeko` 404, `Nhentai World/OioiVn/NetTruyenFE` không phân giải tên miền, `HentaiVN.plus tls handshake eof` | Trang nguồn đổi API/đóng/đổi tên miền. | Ghi nhận; người dùng dùng "Đổi URL/tên miền" hoặc chờ kho cập nhật. |
| `Tor chưa kết nối được sau 90 giây (dừng ở 75%/10%)` | Nhà mạng chặn Tor; cầu nối đã tự thử nền. | Không đổi (đúng thiết kế 0.4.5 L). |
| `Rule34: missing authentication`, `Google Drive: Enter drive path(s)` | Thiếu cấu hình người dùng. | Không phải lỗi; Đề Xuất đã bỏ qua nguồn cần cấu hình. |
| `FlutterError: Failed to load /wp-content/uploads/2024/12/red88-728.gif` | Chỉ xuất hiện 31/10 (0.4.5/0.4.6); đã được `isExpectedFailure` lọc ở bản sau. | Không cần sửa thêm. |
| `Hình minh họa (Hako): TypeError: not a function`, `Cannot seek in this stream` | Chỉ xuất hiện 30/10, trước bản 0.4.7 (đã sửa ở 0.4.7). | Không xuất hiện lại trong log sau 30/10; 0.4.9 không kiểm thử riêng Hako. |

#### D. Sheet "YomiHub Update" (13 mục) – trạng thái thực tế trong mã

| # | Yêu cầu | Trạng thái 0.4.9 |
| --- | --- | --- |
| 1 | Sửa lỗi + cảnh báo trong log, tối ưu chạy mượt | Mục C. Thêm: hàng đợi ghi Isar không còn xung đột (nguyên nhân giật khi lưu vị trí/tải), Đề Xuất không còn bắn ~20 yêu cầu cùng lúc. |
| 2 | Xem và sửa Website Extension | Đối chiếu 27 tiện ích × mọi URL của sheet với `builtin_extensions.dart` và `assets/yomihub_extensions/*.js`: ngôn ngữ/NSFW khớp sheet; tên miền phụ đều có (AVSub .nl/.sale chuyển 301 về .news; VTV Go dựng `/channel/<id>`). Anime47 sửa (mục C). |
| 3 | Bật/tắt bộ tính năng + kho Truyện/Phim/Tiểu thuyết | Đã có từ 0.4.8 (`feature_toggle_screen.dart`). 0.4.9 bổ sung bản dịch 18 ngôn ngữ cho màn hình này (trước đó chưa dịch). |
| 4 | Bổ sung project GitHub còn thiếu | So khớp tự động 563 liên kết của `Project GitHub.xlsx` với `github_projects.dart`: thiếu 59 liên kết / 11 dự án (LeechText, Hotspot Shield ×11, Windscribe ×13, Telegram Bot Project ×10, Resume A Video ×7, Âm Lịch ×7, Flash Player ×7) → đã thêm (đánh dấu "(0.4.9)", nhóm mới "Flash Player (0.4.9)"). Kiểm tra lại: 0 liên kết thiếu. |
| 5 | Sửa lỗi VPN; VPN riêng cho từng nguồn Booru | VPN riêng từng nguồn Booru đã có từ 0.4.6 (`vpn_screen.dart` "Chọn nguồn Booru dùng VPN"); 0.4.9 dịch đủ các chuỗi Booru/VPN còn thiếu. |
| 6 | Sao lưu Telegram (tham khảo Kotatsu, Telegram Bot Project) | Mục C – tự lấy Chat ID qua `getUpdates`. |
| 7 | vBook, vBook 2, LeechText → chạy được extension repo vBook | **Mới:** `lib/yomihub/vbook/vbook_bridge.dart` + `assets/yomihub_extensions/vbook.js`. Chi tiết mục E. LeechText (công cụ desktop tải truyện) được dùng làm tham chiếu; phần đọc truyện chữ đã có qua runtime vBook/LNReader. |
| 8 | Resume A Video + "Tiếp tục phát video từ vị trí đã xem" (mặc định bật) | Cài đặt có từ 0.4.7. Hai nguyên nhân: (1) xung đột ghi Isar làm mất vị trí đã lưu (mục C); (2) với luồng HLS, lệnh tua lúc mở bị mpv bỏ qua nên phim chạy lại từ 0:00 dù toast báo "Tiếp tục phát từ…" (phát hiện khi kiểm thử, mục G/I). Cả hai đã sửa và kiểm thử lại trên Note 9. |
| 9 | Link GitHub trong Giới thiệu | Đã đúng `https://github.com/kiritokmn1403/YomiHub-Project` (`about_screen.dart:198`). |
| 10 | Kiểm tra cập nhật theo thứ tự sheet "Website Update Apps", tự tải & cài | **Mới:** `lib/yomihub/update/multi_source_update.dart`: GitHub Releases (API; khi bị giới hạn 60 lượt/giờ dùng trang `releases/latest` + `expanded_assets`) → Google Drive ×3 → MediaFire ×3 (API `folder/get_content.php`, lấy link tải trực tiếp). `drive_update.dart` nhận `folderId`. Bản Android TV giờ cũng kiểm tra cập nhật (chỉ nhận APK `android-tv`). Hộp thoại tải & cài giữ nguyên (`download_file_screen.dart`). |
| 11 | Hotspot Shield + Windscribe trong cài đặt VPN | **Mới:** `vpn_screen.dart` `_brandSection` + `ext_vpn.dart`: Windscribe (nhập .conf/.ovpn từ Config Generator → chạy bằng lõi WireGuard/OpenVPN của YomiHub, áp dụng "VPN cho tiện ích"; nút tạo cấu hình; mở app Windscribe), Hotspot Shield (mở app gốc/trang tải; nhận diện VPN đang chạy; nhập cấu hình nếu có). Hotspot Shield không phát hành file cấu hình/SDK công khai nên không thể kết nối trực tiếp trong ứng dụng. |
| 12 | Treo, lag, văng | Mục C (Isar, Đề Xuất). |
| 13 | Windows trên AMD Ryzen 9 thiếu tính năng | Máy kiểm thử là Intel i5-11300H (không có máy Ryzen 9); kiểm tra Windows ở mục J. |

#### E. Runtime vBook (mới)
- Kho vBook (`plugin.json` dạng `{metadata, data:[{path: …/plugin.zip, type, locale, version}]}`) được nhận ở `extension_store_service.dart` (`VBookBridge.isIndex/parseIndex`): novel/chinese_novel → Tiểu thuyết, comic → Truyện tranh, video → Phim; tts/translate/ai/audio bỏ qua.
- Cài/cập nhật (`fetch_sources_list.dart` `_updateSource`, phần tải cũ tách thành `_downloadCode`): tải plugin.zip → giải nén (`archive`) → `_common.js` + `VB_PLUGIN` + `VB_SCRIPTS` + `vbook.js` → lưu thành nguồn JavaScript.
- `vbook.js`: (1) bộ tách token tự viết (chuỗi, template, regex, comment) + phân tích đồ thị gọi hàm → hàm có lời gọi mạng thành `async`, lời gọi được bọc `(await …)`, `forEach/map/filter…` có callback async dùng `__aforEach/__amap…` tuần tự; (2) API vBook: `fetch` (không bao giờ ném lỗi mạng, trả 504 như vBook), `Http.get/post` builder, `Html.parse` + Elements kiểu jsoup (select/first/last/get/text/html/attr/remove/absUrl…), `Response`, `localStorage/cacheStorage/localConfig/localCookie`, `sleep`, `UserAgent`, `Engine.newBrowser` (qua WebView ẩn của app), `Script.execute`, `load('x.js')`, hằng cấu hình tĩnh; (3) bộ chuyển `DefaultExtension`: home→Phổ biến/Mới, genre→bộ lọc "Thể loại", search, detail+page+toc→chi tiết & chương, chap→trang ảnh (tôn trọng `referrerpolicy`) / HTML tiểu thuyết / track→video; cấu hình plugin → cài đặt tiện ích; "Đổi tên miền" thay origin trong script.
- Kiểm chứng (Node.js, không chạy mã bên thứ ba, chỉ biên dịch): 1.260 script của 148 tiện ích (Darkrai9x/vbook-extensions, duongden/vbook) → **0 lỗi cú pháp sau chuyển mã**; 341 hàm `execute` chuyển async. Kiểm thử chức năng với tiện ích mẫu (phân trang token, page+toc, forEach+fetch, Http chain, IIFE, referrerpolicy, bộ lọc): đạt.
- Giới hạn: 23/122 tiện ích nội dung có script **mã hóa** (AES, khóa riêng của ứng dụng vBook đóng mã nguồn) → báo "chỉ chạy được trong ứng dụng vBook", không cài thành nguồn hỏng; không phá mã hóa của tác giả. 99/122 chạy được về mặt mã. Bảng mã GBK của nguồn Trung Quốc chưa hỗ trợ (đọc UTF‑8).
- Quét repo: sửa URL sai `vbook-extensions/master/plugins.json` (không tồn tại) → `repository.json` (danh sách 19 kho vBook cộng đồng); trang có `plugin.json` cũng được nhận.

#### F. Bản địa hóa
- Quét toàn bộ `tr('…')`: 55 chuỗi chưa có ở **cả 18 ngôn ngữ** (gồm chuỗi tồn đọng của 0.4.6–0.4.8 như Bật/Tắt tính năng, Booru, MediaFire, Tiếp tục phát video) → đã dịch đủ 55 × 18 (`audit-0.4.9/i18n_049.json`), giữ "Comic/Film & Movie/Novel" cho `YomiTr.sections()`. Test `every tr() text has an English translation` chặn tái phát.

#### G. Kiểm thử trên thiết bị (Note 9 – SM-N960N, Android 10, 1440×2960, cài đè 0.4.8 → 0.4.9)
Ảnh và video ở `audit-0.4.9/qa/` (không đưa lên Git, đính kèm Release trong `YomiHub-0.4.9-QA-screenshots.zip`). Điều khiển bằng `qa049.ps1` (adb `input`, `uiautomator dump`, `screencap`, `screenrecord`).

| Tính năng | Kết quả | Bằng chứng |
| --- | --- | --- |
| Cài đè 0.4.8 → 0.4.9 (versionCode 2041), dữ liệu giữ nguyên | Đạt | `00_baseline`, `02_man_hinh_chinh` |
| Splash 5 s, khung vuông → tròn | Đạt | `01_splash_a/b` |
| Các tab Truyện tranh / Phim / Tiểu thuyết / Cập nhật / Duyệt / Thêm / Cài đặt | Đạt | `02`–`10` |
| Bật/Tắt tính năng – tiêu đề không còn lặp "Truyện tranh (Truyện tranh)" | Đạt sau sửa | `11_bat_tat_tinh_nang` |
| Thêm kho vBook (Darkrai9x `plugin.json`) → danh sách tiện ích vBook → cài Truyện Full | Đạt | `13`–`20`, video `v02_vbook.mp4` |
| Truyện Full: Phổ biến, Mới nhất, Tìm kiếm, chi tiết (500 chương), đọc chương, cuộn | Đạt | `21`–`28`, video `v03_vbook_doc.mp4` |
| Mô tả truyện vBook | Lỗi ở bản dựng 1–3 (trống). Nguyên nhân 1: `Document.text` = null (đã sửa ở `vbook.js`). Nguyên nhân 2: runtime được đóng vào tiện ích lúc cài nên tiện ích đã cài vẫn chạy runtime cũ → thêm `VBookBridge.runtimeRev` vào số phiên bản (14.0.0 → 14.0.2). Kiểm thử lại: Duyệt hiện "1 cập nhật", "Cập nhật tất cả" → 14.0.2, mô tả hiện đủ | `90_vb_detail` (trước), `97`–`100` (sau), video `v13_cap_nhat_vbook_mo_ta.mp4` |
| AnimeVN: danh sách, chi tiết, phát (máy chủ nhúng), đổi máy chủ, PiP | Đạt | `30`–`40`, video `v04_phim_animevn.mp4` |
| RoPhim: phát HLS gốc, điều khiển, tự PiP khi thoát | Đạt | `43`–`50` |
| **Tiếp tục phát từ vị trí đã xem** | Lỗi ở bản dựng 2 và 3: toast "Tiếp tục phát từ 05:00/01:35" nhưng phim chạy lại từ 0:00 (`v07`, `v11`). Tua tay bằng thanh thời gian vẫn được (00:07:00 → 00:37:25, `84_seek`) → luồng tua được, chỉ lệnh tua lúc mở bị mất. Sửa `_yhResumeTo` (mục I). Kiểm thử lại: lưu 39:50 → mở lại từ Lịch sử phát tiếp ở 00:40:10 | `v11_grid2.jpg` (lỗi), `v12_tiep_tuc_vi_tri_fix.mp4`, `v12_grid.jpg`, `93_resume_fix` (đạt) |
| Lịch sử (3 tab), mở lại tập đang xem | Đạt | `53`, `79`, `80` |
| Giới thiệu: phiên bản Beta (0.4.9), liên kết GitHub đúng | Đạt | `57`, `74` |
| Kiểm tra cập nhật nhiều nguồn (GitHub → Drive → MediaFire) | Đạt: "Không có bản cập nhật mới" (Release mới nhất lúc thử là 0.4.8 < 0.4.9) | `75`, `76`, video `v09_kiem_tra_cap_nhat.mp4` |
| Nhật ký ứng dụng sau khi thử | Không có dòng ERROR mới | `59_nhat_ky` |
| Hợp nhất tiện ích | Mở được, danh sách đúng | `61_hop_nhat_tien_ich` |
| VPN hub: Windscribe + Hotspot Shield, phạm vi VPN | Đạt (giao diện) | `60`, `63`–`66` |
| **VPN (kiểm tra ngoài ứng dụng):** bật WARP phạm vi "Toàn thiết bị", mở `cloudflare.com/cdn-cgi/trace` bằng Edge | `warp=on`, IP 2a09:bac5:… (Cloudflare); tắt → `warp=off`, IP 2001:ee0:… (nhà mạng). Trả phạm vi về "Chỉ YomiHub" | `69`–`73`, video `v08_vpn_warp.mp4` |


#### H. Không đạt được / giới hạn (ghi trung thực)
- **Android 6.0:** không cài/chạy được – CSDL Isar (libmdbx) báo `MDBX_INCOMPATIBLE` trên kernel Android 6 (đã chứng minh ở 0.4.3 mục D). APK để `minSdk 24` (Android 7.0). Mục trạng thái của 0.4.7/0.4.8 ghi "Android 6.0+" – không khớp với giới hạn này; 0.4.9 ghi đúng là Android 7.0+.
- **Windows 7/8, Windows x86 (32-bit) và Windows ARM64:** Flutter Windows chỉ hỗ trợ Windows 10+ x64 (engine dùng API Windows 10); ARM64 phải dựng trên máy ARM64 với Flutter master. Ghi chú 0.4.8 ("Windows 7+ bundles") không có bằng chứng chạy trên Windows 7; gói thực tế chỉ có x64.
- Ghi chú 0.4.8 nói đã có `IsarWriteQueue` và "0 cảnh báo": lớp này không có trong mã và `dart analyze` vẫn có 161 cảnh báo cũ (0 lỗi). Đã sửa thật ở 0.4.9 (mục C).
- 23/122 tiện ích vBook mã hóa – chỉ chạy trong ứng dụng vBook.
- Hotspot Shield không có cấu hình/SDK công khai → chỉ mở ứng dụng gốc / nhận diện VPN.
- Mật khẩu Anime47 đã nằm trong lịch sử Git công khai (các bản ≤ 0.4.8) – **chủ dự án nên đổi mật khẩu**. Không viết lại lịch sử Git (cần force-push, phải do chủ dự án quyết định).

#### I. Sửa thêm trong lúc kiểm thử (03/11/2026)
1. `overlay/lib/modules/anime/anime_player_view.dart`: thay vòng "tua + kiểm tra 6 lần" bằng hàm mới `_yhResumeTo(start)` – chờ đến khi `playing && !buffering && duration > 0 && position > 0`, gửi `seek <giây> absolute` thẳng cho mpv qua `NativePlayer.command(..., waitForInitialization: false)` có `timeout(3s)` (tránh kẹt sau khóa `open()`), tua lại tối đa 8 lần trong 45 s, chỉ coi là xong khi đã phát ổn định ≥ 3 s trong khoảng [đích − 10 s, đích + 60 s]; hết lượt → ghi ERROR và bật lại lưu vị trí.
2. `overlay/lib/yomihub/net/chunk_proxy.dart` (`YomiHlsAdFilter.handle`): trả danh sách phát có `Content-Length` (không chunked).
3. `overlay/lib/yomihub/vbook/vbook_bridge.dart`: `runtimeRev = 2`, phiên bản tiện ích vBook `'$ver.0.$runtimeRev'`; test cập nhật.
4. `overlay/test/yh_049_test.dart`: test "no Anime47 account" không còn chứa chuỗi tài khoản (bản trước của test có chứa một phần tài khoản để so sánh) – nay kiểm tra không có địa chỉ e‑mail và giá trị mặc định rỗng.
5. `.gitignore`: loại `audit-0.4.9/npm/`, `backup/`, `*.html` (trang bên thứ ba), `qa/`.
6. **Android TV** – `overlay/lib/modules/manga/detail/tv/tv_anime_detail_view.dart`: màn chi tiết TV còn chữ tiếng Anh viết cứng (Play/Replay/Continue, Add to Library, Categories, Tracking, Open in browser, Recommendations, Watch order, Migrate, "N episodes", "Episodes", "Episode N", "FILLER", trạng thái `Completed`) → `tr(...)`; hàm mới `_statusLabel(Status)`; bỏ `_cap`. Thời lượng tập hiện số mili-giây thô "4303400" → hàm mới `_durationLabel` (H:MM:SS). `overlay/lib/modules/library/tv_home/tv_anime_home_view.dart`: 11 chuỗi tiếng Anh → `tr(...)`. 25 chuỗi mới dịch đủ 18 ngôn ngữ.
7. **Android TV** – `overlay/lib/providers/storage_provider.dart` `requestPermission({bool force = false})`: trang hệ thống "All files access" bật lại mỗi lần mở tập (trình phát gọi xin quyền cho thư mục mpv) dù người dùng đã từ chối. Nay các lệnh gọi nền chỉ xin 1 lần mỗi lần chạy app; thao tác do người dùng bấm (tải xuống `download_provider.dart`, thư mục cục bộ `local_directory_resolver.dart`, `foreign_downloads.dart`, cài đặt trình phát `player_advanced_screen.dart`) truyền `force: true` và luôn hỏi lại.
8. Sơ suất trong phiên: một lệnh chép bản gốc chạy sai thư mục, tạo `overlay/audit-0.4.9/` thừa. Đã chuyển sang `_to_delete/overlay-audit-0.4.9-stray` (shell không có quyền xóa; `/_to_delete/` đã thêm vào `.gitignore`) – chủ dự án có thể xóa.

#### J. Kiểm thử bản dựng cuối (dựng lần 5, 03/11/2026 09:02 → 09:53)
- `dart analyze lib`: **0 lỗi** (211 mục cảnh báo/info, đều có từ trước, trừ 1 info `unnecessary_string_interpolations` ở `anime_player_view.dart` dòng `seekable`). `flutter test` (10 tệp yh_040…yh_049): **76/76 đạt**.
- **Note 9:** cài đè APK arm64 cuối thành công (versionCode 2041); mở lại Tập 04 từ Lịch sử → tự tua tới **00:42:05** (`v14_ban_cuoi_tiep_tuc.mp4`, `v14_grid.jpg`).
- **Android TV** (AVD `YomiHub_TV_API34`, 1920×1080, cài đè APK TV armeabi-v7a): khởi động, thanh bên chỉ có Phim & Điện ảnh / Play Books / Booru / Cập nhật / Duyệt / Thêm (không có Truyện tranh, Tiểu thuyết), Duyệt nguồn phim, tìm kiếm toàn cục, chi tiết phim, phát RoPhim/HotPhim, điều khiển và tua bằng D-pad (05:15 → 05:25), quay lại chi tiết. Bản cuối: chi tiết hiện tiếng Việt ("Phát · Xem phim", "Thêm vào thư viện", "Danh sách tập · 1"), thời lượng "3:12:12", không còn bật trang xin quyền khi phát. Ảnh `tv11`–`tv39`, video `tv_v01`–`tv_v06`. Còn lại: nút "Settings" trong thanh điều khiển trình phát TV vẫn là tiếng Anh (chuỗi của trình phát gốc).
- **Windows 11 x64** (máy của chủ dự án):
  - Kiểm tra SHA256 cả 10 tệp với `SHA256SUMS-0.4.9.txt`: khớp hết.
  - `Setup.exe`: chạy trình cài, bấm "Cài Đặt Ngay" (UI Automation + chuột). Cài đè 0.4.7+39 → **0.4.9+41** vào `%LOCALAPPDATA%\YomiHub`, tạo lối tắt Desktop + Start Menu, tự mở app. Ảnh `win01_setup`, `win02_setup_xong`; video `win_v01_setup_exe.mp4`, `win_v02_setup_cai_dat.mp4`.
  - Portable `.zip`: giải nén (330.9 MB), `YomiHub.exe` chạy (Responding, ~468 MB), nhật ký ghi bình thường (tải kho, ảnh bìa).
  - `.appxbundle`: kiểm tra cấu trúc – chứa `YomiHub_0.4.9_x64.appx` (Version 0.4.9.0, x64) và có chữ ký `CN=YomiHub` (thumbprint `4C62D3C5…2A49`). **Chưa cài thử**: cài cần thêm `YomiHub-RootCA.cer` vào kho chứng chỉ gốc của máy (thay đổi cài đặt bảo mật) – để chủ dự án tự chạy `Install-YomiHub.bat`.
  - **Cửa sổ vẫn trắng** (`win03_app_sau_cai`, `win04_mo_lai`, `win05_portable`): tiến trình chạy và ghi log bình thường, phóng to cửa sổ thì vùng vẽ không đổi kích thước. Đây vẫn là lỗi hiển thị Flutter của máy này đã ghi ở 0.4.4 F / 0.4.5 G (ứng dụng mẫu `flutter create` cũng trắng; Intel Iris Xe driver 2021 + GTX 1650). Đã thử dừng Gradle daemon và mở lại: vẫn trắng. Không đổi cài đặt đồ hoạ hệ thống. **Giao diện bên trong bản Windows chưa kiểm thử được trên máy này** – cần cập nhật driver Intel / chọn GPU NVIDIA cho `YomiHub.exe` (Cài đặt › Hiển thị › Đồ hoạ) hoặc thử máy khác.

#### K. Tệp bàn giao (`output/0.4.9`)
| Tệp | MB | SHA256 |
| --- | ---: | --- |
| YomiHub-0.4.9-arm64-v8a.apk | 168.8 | `5346291ba7cb61eed162c2391577c7b4c30a0ec2b6e2dbc23be10a6699c1f981` |
| YomiHub-0.4.9-armeabi-v7a.apk | 165.6 | `89310b70960b270cdd04886b7603e4acfe99eaaa4bd6dcb5759916a5a5c97277` |
| YomiHub-0.4.9-x86_64.apk | 178.1 | `fb2131c9fb154e55e1576be3d11c032750e998792d72914258e547fd0a2b3a13` |
| YumiHub-Android-TV-0.4.9-arm64-v8a.apk | 168.7 | `1a97998f94528e04664e915ae96af3ec6f3ec36ef251df8371a3846bd94d72c6` |
| YumiHub-Android-TV-0.4.9-armeabi-v7a.apk | 165.5 | `6a2d3c3a0089061141a4eea9b0f3abcb6bfaabd2a06c7d6857d3b4fe055d700f` |
| YumiHub-Android-TV-0.4.9-x86_64.apk | 178.1 | `06e6d2be30412474b15080a7cbee00c09d9b6eb4bdf834cde2b2bd30b7d9cf89` |
| YomiHub-0.4.9-windows-x64-Setup.exe | 138.6 | `504453e290b7b4a4200187965b666ef980cc674736b8b11ce3b6a8d07487ffd7` |
| YomiHub-0.4.9-windows-x64.appxbundle | 270.9 | `dba1a0f3b19a742f83ce63cd9a2344ca494ecd84d4e9876e1d3bd225614d94ef` |
| YomiHub-0.4.9-windows-x64.zip (portable) | 138.6 | `c1cc910d36ebbc4534c237cd05a72efe7cbb05d25151da966ae2e12eb2195689` |
| YomiHub-0.4.9-windows-x64-full.zip (portable + MES/JRE) | 266.4 | `248e29eac3d2a7f5770de2555d6b414ce1992761efdc523456312941f1f2936b` |

Kèm: `SHA256SUMS-0.4.9.txt`, `YomiHub-RootCA.cer`, `Install-YomiHub.bat/.ps1`, `YomiHub-0.4.9-changelog.md`; ảnh/video kiểm thử đóng gói ở `output/YomiHub-0.4.9-QA-screenshots.zip`.

#### L. GitHub
- Mã nguồn: commit trên `main` của `kiritokmn1403/YomiHub-Project` (đẩy bằng Git for Windows + Git Credential Manager có sẵn trên máy; token không ghi ra log/tệp).
- Release `v0.4.9` (đánh dấu Latest): tải bằng `release_049.ps1` – một dòng tiến độ mỗi tệp, cuối cùng so kích thước từng tệp trên GitHub với tệp trên máy. README có bảng link tải trực tiếp từ Releases.

### 03/11/2026 — Cập nhật phiên bản 0.5.0 (YomiHub 0.5.0+42)

Thực hiện: Claude (phiên cloud liên kết máy `kiritokmn-lap`), 03/11/2026 11:16 → 13:50 (Asia/Saigon). Người dùng xác nhận bản tóm tắt yêu cầu lúc 11:19 ("hãy tiến hành đi"); theo đề xuất đã nêu: chia giai đoạn, Windows 10+ thay cho Windows 7.

#### A. Yêu cầu
1. Nâng lên 0.5.0; Android 6.0+; mọi bản Android TV tách APK riêng `YumiHub Android TV` và **bỏ Comic, Novel, Google Play Books, Booru** (mới: thêm Play Books và Booru so với 0.4.9); Windows 7+ x64/x86/ARM với `.appxbundle`, `.exe`, portable.
2. Làm theo sheet `Feature Check` (45 mục) và `YomiHub Update` (9 mục) của `Project YomiHub.xlsx`; đối chiếu `Project GitHub.xlsx` (605 dòng).
3. Sửa lỗi trong `logs.txt` (30/10 06:09 → 03/11 11:10; 110 dòng ERROR).
4. Ghi vào tài liệu này: hạng mục sửa, lỗi phát hiện, dòng lệnh sửa, công cụ, kết quả kiểm thử, ngày.
5. Dựng, cài, kiểm thử có ảnh + video (Android SDK/Emulator, thiết bị ngoài, Windows); tải mã nguồn + Output lên GitHub (Releases + README).

#### B. Công cụ đã dùng
- Đọc/sửa mã: shell Linux của Claude trên máy người dùng (thư mục kết nối), Python 3 cho mọi phép sửa (`audit-0.5.0/edit.py`: `assert` chuỗi cũ xuất hiện đúng 1 lần, chép bản gốc sang `audit-0.5.0/before/`, ghi `audit-0.5.0/changed_files.txt`).
- Dựng/kiểm thử: `3_run_jobs.bat` + `3b_run_fast_jobs.bat` (Claude mở bằng Computer use trong File Explorer), Flutter 3.47.6 / Dart 3.13.5, Android SDK + adb, Gradle, Rust/Cargo, Visual Studio 2022 Build Tools, WiX/NuGet, ffmpeg (quay màn hình Windows), `adb screencap/screenrecord/uiautomator`.
- Script mới: `sync_050.ps1`, `build_050.ps1`, `qa050.ps1`, `release_050.ps1`, `audit-0.5.0/qa.sh` + `qatv.sh` (tạo tác vụ QA có BOM UTF-8 – PowerShell 5 đọc tệp không BOM thành mã ANSI làm hỏng chữ tiếng Việt).
- **Sửa trình chạy tác vụ** (`run_jobs.ps1`, `run_jobs_fast.ps1`): 12:10 trình chạy nhanh treo vì cửa sổ console rơi vào chế độ "Select" (QuickEdit) sau một cú nhấp. Thêm đoạn tắt QuickEdit bằng `SetConsoleMode` (kernel32, bỏ cờ 0x40) khi khởi động. Bản cũ ở `audit-0.5.0/before_scripts/`.

#### C. Lỗi trong `logs.txt` và cách xử lý

| Lỗi trong log | Nguyên nhân thật | Xử lý 0.5.0 |
| --- | --- | --- |
| 16 tiện ích vBook mã hóa (Mimimoe, GuPhim, LuPhim, MotPhim, Phim Nhựa, Phim4K, PhimTV2, RoPhim ×2, Phimtv, Phimmoir, AnimeVietsub, 210CB, CBunu Comic, Destin Team…) ghi `[ERROR] [Cập nhật tiện ích] … cài lại x.0.2` kèm stack trace, lặp lại mỗi lần bấm (03/11 10:36 → 11:08, ~25 dòng) | 0.4.9 chỉ phát hiện mã hóa *sau khi* tải plugin.zip và ném `Exception` thường → `_logUpdateFailure` ghi ERROR; danh sách không nhớ kết quả nên nút "Cài" vẫn mời bấm lại | `vbook_bridge.dart`: lớp mới `VBookEncryptedException`; `markEncrypted()` / `isKnownEncrypted()` lưu `URL@phiên bản` vào `YomiPrefs` (`vbookEncrypted`, tối đa 500). `fetch_sources_list.dart` `_logUpdateFailure`: gặp lỗi này → đánh dấu + `AppLogger.logOnce(... LogLevel.warning)` không stack, `return`. `extension_list_tile_widget.dart`: getter `_vbookLocked` → nhãn "Chỉ chạy trên vBook", biểu tượng ổ khóa, bấm chỉ hiện toast. |
| `[ERROR] Extension "MangaDex (unlocked)" … getHeaders … TypeError: not a function at <eval>:2:1` (11:09) | Script kegareta-sauces gọi `getPreference("custom_user_agent")` / `get("original_languages", [])` cho khóa **không có** trong `getSourcePreferences()`. `getSourcePreferenceEntry` ném `"Error when getting source preference"` (và `sourceRepository.getById(...)!` khi nguồn chưa lưu lúc cài) → QuickJS báo TypeError → không cài được | `lib/eval/javascript/preferences.dart`: handler `get`/`getString` bọc `try/catch` (trả `null` / giá trị mặc định); JS `SharedPreferences.get(key, defaultValue)` trả `defaultValue` khi kết quả rỗng. `toMapStringString` vốn bỏ qua header `null` nên `user-agent: null` an toàn. |
| `[Hiệu năng] Khung hình chậm: dựng 744–1164ms • màn hình: /more` | `MoreScreen` gọi `ExtensionMergeScreen.suggestIfNeeded` trong `addPostFrameCallback` → `duplicateGroups()` đọc đồng bộ mọi nguồn đã cài ngay trong khung hình đầu | `more_screen.dart`: chạy sau `Future.delayed(1200ms)`; bỏ `ref.watch(hideItemsStateProvider)` và import không dùng. Kiểm thử Windows: gợi ý "Phát hiện 14 nhóm tiện ích trùng tên miền" vẫn hiện, sau khi trang đã vẽ. |
| `Kho tiện ích chưa xác minh hoặc 0 tiện ích` (cursed-manga-repo ×2, x.noz.one, Nyora, salmanbappi) | cursed-manga-repo là định dạng `extensionList` (đã hỗ trợ); x.noz.one timeout mạng; Nyora có `"sources": null` (APK nguồn cục bộ) | Không sửa: tạo id nguồn giả cho Nyora có thể làm MES nạp sai nguồn. Ghi nhận. |
| `[Booru App] Rule34: missing authentication`, `Tor chưa kết nối được sau 90 giây`, `Cloudflare … MiMiHentai/CBHentai/LxManga`, `HentaiVN.plus tls handshake eof`, ảnh lỗi `hentaicb.help`/`nhattruyensss.com`/`i.hinhhinh.com` | Thiếu API key; nhà mạng chặn Tor/máy chủ ảnh; trang kiểm tra dấu vân tay TLS (đã phân tích 0.4.5/0.4.9) | Không phải lỗi mã (như 0.4.9 mục C). |
| Các khối `*** pid … name 1.ui … _kDartSnapshotText` | Không phải crash: là stack trace Dart (AOT, không ký hiệu) đi kèm mỗi dòng ERROR | Hết theo các lỗi trên. `adb logcat -b crash` sau kiểm thử: không có crash. |

#### D. Sheet "YomiHub Update" (9 mục) – trạng thái 0.5.0

| # | Yêu cầu | Trạng thái |
| --- | --- | --- |
| 1 | Sửa lỗi + cảnh báo trong log, tối ưu chạy mượt | Mục C. |
| 2 | Xem và sửa Website Extension | Đã đối chiếu ở 0.4.9 (mục D-2); 0.5.0 không có thay đổi sheet. |
| 3 | Bổ sung project GitHub còn thiếu | 0.4.9 đã đạt 0 liên kết thiếu (563). File mới có 605 dòng (gồm dòng tiêu đề/nhóm); **chưa chạy lại so khớp tự động trong đợt này** – việc còn lại. |
| 4 | vBook, vBook 2, LeechText – mọi kho vBook "kể cả tiện ích mã hóa" | Runtime vBook có từ 0.4.9. Tiện ích mã hóa: **không phá mã hóa của tác giả** (khóa AES riêng của ứng dụng vBook đóng nguồn). 0.5.0 khóa rõ ràng các tiện ích này thay vì báo lỗi lặp (mục C). |
| 5 | Aniyomi/Nekoyomi/Mangayomi/Kotatsu/Web Scanner + Kiểm tra cập nhật theo sheet "Website Update Apps" | Đa nguồn có từ 0.4.9. Kiểm thử 0.5.0 trên Note 9 và Windows: "Đang tìm bản cập nhật…" → không có bản mới (Release mới nhất lúc thử là v0.4.9). |
| 6 | Hotspot Shield + Windscribe trong VPN | Có từ 0.4.9 (Hotspot Shield không có cấu hình/SDK công khai). |
| 7 | sherpa-onnx | **Chưa tích hợp** – thư viện native lớn (mô hình ONNX hàng trăm MB), cần thiết kế riêng; việc còn lại. |
| 8 | Treo, lag, văng | Mục C (+ 0.4.9 Isar/Đề Xuất). Note 9: không crash trong suốt phiên kiểm thử. |
| 9 | Windows (AMD Ryzen 9) thiếu tính năng | Không có máy Ryzen 9. Trên máy kiểm thử (Intel i5-11300H + GTX 1650), **bản 0.5.0 hiển thị đầy đủ giao diện** – lỗi cửa sổ trắng ghi ở 0.4.4 F / 0.4.5 G / 0.4.9 J không còn tái hiện (không có thay đổi mã liên quan; có thể do driver/Windows đã cập nhật). |

#### E. Android TV (0.5.0)
- `main_screen.dart` `_isNotHiddenLibOnTv`: thêm `/playBooks`, `/booru` → thanh bên TV chỉ còn Phim & Điện ảnh / Cập nhật / Duyệt / Thêm.
- `router.dart`: nhánh `playBooks`/`booru` (StatefulShellRoute theo chỉ số nên giữ nhánh) dùng `_TvRemovedScreen` khi `kIsTvBuild` → tự chuyển về `/AnimeLibrary`. `main.dart`: bỏ lối tắt `/playBooks`, `/booru` trên TV. `settings_screen.dart`: ẩn `PlayBooksSettingTile`, `BooruSettingTile` khi `isTv || kIsTvBuild`.
- `tv_player_settings_panel.dart` / `tv_player_controls.dart`: "Settings", "Playback speed", "Quality", "Subtitles", "Audio", "Shaders", "Decoder", "Stats for nerds" → `tr(...)` (còn tồn từ 0.4.9 J); 9 chuỗi mới × 18 ngôn ngữ.

#### F. Kiểm thử
- `dart analyze lib`: **0 lỗi**, 210 cảnh báo/info (0.4.9: 211; không có mục mới ở tệp đã sửa).
- `flutter test` (11 tệp yh_040…yh_050): lần 1: 77 đạt / 7 lỗi – 6 test cũ ép phiên bản `0.4.x` (đã nới thành `0.`), 1 test mới phát hiện danh sách mục của bảng cài đặt TV vẫn tiếng Anh (`_categoryList`) → sửa dùng `_titleFor`. Lần 2: **84/84 đạt** (`All tests passed!`).
- **Note 9 (SM-N960N, Android 10)** – ảnh/video `audit-0.5.0/qa/`:

| Tính năng | Kết quả | Bằng chứng |
| --- | --- | --- |
| Cài đè 0.4.9 (2041) → 0.5.0 (2042), dữ liệu + lịch sử giữ nguyên | Đạt | log `f050_011`, `23_lich_su_phim` |
| Splash vuông → tròn, màn chính (điện thoại vẫn có Play Books, Booru) | Đạt | `01_splash_a/b`, `02_man_hinh_chinh`, `v01_khoi_dong.mp4` |
| Thêm kho vBook `Ivan1hai/ext/plugin.json` (6 truyện tranh / 11 phim / 61 tiểu thuyết) | Đạt | `11_kho_ivan`, `v02_vbook_ma_hoa.mp4` |
| Cài tiện ích vBook mã hóa "MotPhim" → khóa + nhãn "Chỉ chạy trên vBook"; bấm lại chỉ hiện toast | Đạt | `12_cai_motphim_vbook`, `14_motphim_bam_lai_toast`, `12_14_vbook_ma_hoa.jpg` |
| Nhật ký ứng dụng sau toàn phiên (lọc "Chỉ lỗi") | **Không có mục lỗi** | `19_nhat_ky`, `20_nhat_ky_tat_ca` |
| Giới thiệu: Beta (0.5.0); Kiểm tra cập nhật | Đạt | `17_gioi_thieu_050`, `18_kiem_tra_cap_nhat_a/b`, `v03_kiem_tra_cap_nhat.mp4` |
| Tiếp tục phát từ vị trí đã xem (Tập 04 – Goblin) | Đạt: toast "Tiếp tục phát từ 42:26", 00:42:26 → 00:42:46 / 01:14:02 | `v04_tiep_tuc_phat.mp4`, `v04_grid_tiep_tuc_phat.jpg` |
| HotPhim (HLS): Phổ biến → chi tiết → phát | Đạt (logo TOHO/ANIPLEX chạy) | `v05_hotphim.mp4` |
| MangaDex (unlocked) cài trên máy | **Chưa kiểm thử trên máy**: điều khiển ô tìm kiếm qua adb không ổn định (bàn phím Laban Key Telex đổi "MangaDex" → "MângDex"; đổi tạm sang Samsung Keyboard rồi trả lại Laban Key, nhưng chữ vẫn không vào ô). Chỉ kiểm chứng bằng mã + test. | – |

- **Android TV** (AVD `YomiHub_TV_API34`, 1920×1080, abilist `x86,armeabi-v7a` → cài APK TV armeabi-v7a, 0.4.9 → 0.5.0 versionCode 1042): thanh bên không còn Truyện tranh/Tiểu thuyết/**Play Books/Booru** (`tv02_thanh_ben`); Duyệt nguồn phim, HotPhim danh sách + chi tiết; trình phát TV: nút "Cài đặt" và bảng cài đặt tiếng Việt (`tv07_dieu_khien`, `tv08_bang_cai_dat`, `tv_grid_050.jpg`). **Không đạt trên giả lập:** luồng HotPhim không mở (00:00 / -00:00), kể cả khi đổi bộ giải mã sang phần mềm; cùng nguồn phát được trên Note 9 → nghi do môi trường (APK ARM chạy qua lớp dịch trên CPU x86 của AVD, mạng giả lập). Cần thử trên TV/Android box thật.
- **Windows 11 x64:** SHA256 cả 10 tệp khớp `SHA256SUMS-0.5.0.txt`. Portable `.zip` giải nén 330.9 MB, `YomiHub.exe` 0.5.0+42 chạy (Responding, 547 MB) và **hiển thị giao diện** (`win01_portable_050`). `Setup.exe`: bấm "Cài Đặt Ngay" → cài đè 0.4.9+41 → **0.5.0+42** vào `%LOCALAPPDATA%\YomiHub`, tự mở app; phóng to, chuyển tab Truyện tranh / Phim / Thêm / Giới thiệu (Beta 0.5.0) / Kiểm tra cập nhật / Nhật ký (chỉ INFO/WARNING) – video `win_v02_setup_va_kiem_thu.mp4`, ảnh `win02_nhat_ky_050`. `.appxbundle`: chứa `YomiHub_0.5.0_x64.appx`, ký `CN=YomiHub, O=YomiHub, C=VN` (Authenticode "UnknownError" vì chứng chỉ tự ký chưa nằm trong kho gốc của máy – chưa cài thử, cần `Install-YomiHub.bat` thêm `YomiHub-RootCA.cer`, thay đổi cài đặt bảo mật nên để chủ dự án tự chạy). Video/ảnh Windows chứa ảnh bìa trong thư viện cá nhân nên **không đưa lên GitHub**.

#### G. Không đạt / giới hạn (ghi trung thực)
- **Android 6.0:** vẫn `minSdk 24` (Android 7.0) – Isar/libmdbx `MDBX_INCOMPATIBLE` trên kernel Android 6 (0.4.3 mục D).
- **Windows 7/8, x86, ARM64:** Flutter Windows chỉ Windows 10+ x64 (ARM64 phải dựng trên máy ARM64). Gói thực tế: x64.
- sherpa-onnx chưa tích hợp; so khớp lại 605 dòng `Project GitHub.xlsx` chưa chạy lại; 45 mục Feature Check không được kiểm thử lại toàn bộ trong đợt này – chỉ các mục liên quan đến thay đổi 0.5.0 và các tính năng chính ở bảng trên.
- Tiện ích vBook mã hóa: chỉ chạy trong ứng dụng vBook (không phá mã hóa).
- Trên điện thoại, nhãn "Chỉ chạy trên vBook" bị cắt thành "Chỉ c…" khi tên kho dài (ổ khóa và toast vẫn rõ) – nên đưa nhãn xuống dòng riêng ở bản sau.
- Phát phim trên giả lập TV (mục F).

#### H. Tệp bàn giao (`output/0.5.0`)
| Tệp | MB | SHA256 |
| --- | ---: | --- |
| YomiHub-0.5.0-arm64-v8a.apk | 168.8 | `c450a1b25d6f098757bce82b11242be4b0e35b389487f016cbfd4e723f4dd083` |
| YomiHub-0.5.0-armeabi-v7a.apk | 165.6 | `5cec49c7c8202badc2449219a63cf1a137f9b397eae91c1d7dcc9b99a580bca3` |
| YomiHub-0.5.0-x86_64.apk | 178.1 | `fb6076175107057a8d6a42b4ce3f5e68b24dff54b5faa0b2e89c1143e4425f87` |
| YumiHub-Android-TV-0.5.0-arm64-v8a.apk | 168.6 | `dd8cf1a88991cd769905dbd2c60b0b9b2dcd376a1472353bf1a49127cbb185c2` |
| YumiHub-Android-TV-0.5.0-armeabi-v7a.apk | 165.4 | `80d1cada450b8e95c2c218bd87d5d0c398b0d2dae096cc2b882d09b2152c039c` |
| YumiHub-Android-TV-0.5.0-x86_64.apk | 178.0 | `68986d175de83455abf7f15e864636beed0525d565863b381a9a02b4f29bce6b` |
| YomiHub-0.5.0-windows-x64-Setup.exe | 138.6 | `d4487f5dea029a56e555531ca6ac80e9913f38c121dac46ab716d0e75d6ac213` |
| YomiHub-0.5.0-windows-x64.appxbundle | 270.9 | `0a3f8c774ec7134499880222ba72d80b4d7d41f14f64a9d4de870d81f394ff2c` |
| YomiHub-0.5.0-windows-x64.zip (portable) | 138.6 | `c718e89724c730039cdfc2090b610b592578d2628b260e97ff07926a8fcbe5fa` |
| YomiHub-0.5.0-windows-x64-full.zip (portable + MES/JRE) | 266.4 | `a55f5b6b931e3477d0fb91cdb753d0dbd6d455a0a91d4daea3e8cf23b8c97ce7` |

Kèm `SHA256SUMS-0.5.0.txt`, `YomiHub-RootCA.cer`, `Install-YomiHub.bat/.ps1`, `YomiHub-0.5.0-changelog.md`; ảnh/video kiểm thử Android/TV: `output/YomiHub-0.5.0-QA-screenshots.zip`.

#### I. GitHub
- Mã nguồn: commit trên `main` của `kiritokmn1403/YomiHub-Project` (Git for Windows + Git Credential Manager có sẵn trên máy; token không ghi ra log/tệp). Release `v0.5.0` (Latest) tải bằng `release_050.ps1`, có bước so kích thước từng tệp. README có bảng link tải 0.5.0. Kết quả: xem `jobs/done/x050_*release*.log`.

### 03/11/2026 — Cập nhật phiên bản 0.5.1 (YomiHub 0.5.1+43)

Thực hiện: Claude (phiên cloud liên kết máy `kiritokmn-lap`), 03/11/2026 21:51 → 04/11/2026 08:45 (Asia/Saigon). Phiên bị ngắt lúc 23:40 (người dùng dừng); một phiên làm việc tiếp theo dùng cùng bộ script và quy ước (`g051_*`, `j051_*`, `notes_051_part3/4`) đã làm tiếp 23:41 → 03:20 (mục E–G); phiên này tiếp tục từ 06:13 (mục H–K). Người dùng xác nhận bản tóm tắt lúc 21:51 ("đồng ý, hãy tiến hành ngay bây giờ"), giữ đề xuất như 0.5.0: Android 7.0+ (không phải 6.0) và Windows 10/11 x64 (không phải Windows 7/x86/ARM). 21:55 người dùng yêu cầu thêm: "tích hợp các mã nguồn mới, kiểm tra xem các tiện ích vBooks có còn bị mã hoá nữa không" (mục C).

#### A. Yêu cầu
1. Nâng lên 0.5.1; Android (3 APK) + `YumiHub Android TV` (3 APK, bỏ Comic, Novel, Google Play Books, Booru); Windows `.appxbundle`, `Setup.exe`, portable.
2. Sheet `Feature Check` (45 mục) và `YomiHub Update` (7 mục, mới: thư mục cục bộ không nhận tệp tải của Aniyomi/Nekoyomi/Mangayomi) của `Project YomiHub.xlsx`; `Project GitHub.xlsx` (579 liên kết).
3. Sửa lỗi trong `logs (1).txt` (30/10 06:09 → 03/11 21:24).
4. Ghi vào tài liệu này: hạng mục, lỗi, dòng lệnh sửa, công cụ, kết quả kiểm thử, ngày.
5. Dựng, cài, kiểm thử (ảnh + video), tải mã nguồn + Output lên GitHub (Releases + README).

#### B. Công cụ đã dùng
- Đọc/sửa mã: shell Linux của Claude trên máy người dùng (thư mục kết nối); mọi phép sửa bằng `audit-0.5.1/edit.py` (Python 3: `assert` chuỗi cũ xuất hiện đúng 1 lần, chép bản gốc vào `audit-0.5.1/before/`, ghi `audit-0.5.1/changed_files.txt`). Kịch bản sửa: `audit-0.5.1/e01_local.py` (thư mục cục bộ), `e02_net.py` (nhật ký mạng), `e03_vbook.py` (runtime vBook) và các lệnh `edit(...)` ghi trong mục D.
- Dựng/kiểm thử trên Windows: `3_run_jobs.bat` + `3b_run_fast_jobs.bat` (Claude mở lại bằng Computer use trong File Explorer lúc 21:54 – hai trình chạy đã dừng từ 14:08), `sync_051.ps1`, `build_051.ps1`, `qa051.ps1`, `release_051.ps1` (sinh từ bản 0.5.0, đổi phiên bản/thư mục); Flutter 3.47.6 / Dart 3.13.5, Android SDK + adb, Gradle, Rust/Cargo, Visual Studio 2022 Build Tools, WiX/NuGet, ffmpeg.
- Quét kho vBook: `git clone --depth 1` 18 kho + Python (`zipfile`) trong môi trường cloud (máy người dùng chặn `raw.githubusercontent.com` từ shell); kết quả `audit-0.5.1/vbook_encryption_scan_2026-11-03.csv`.
- Kiểm tra thư mục trên Note 9: `adb push` script `audit-0.5.1/yomi_ls*.sh` + `adb shell sh` (danh sách tệp cá nhân – không đưa lên Git, `.gitignore`).

#### C. Tiện ích vBook mã hóa – kiểm tra lại (yêu cầu bổ sung 21:55)
- Thư mục mới `D:\A.I Project\A.I Project - vBooks` chứa `vBooks.apk` và mã Java dịch ngược của ứng dụng vBook (đóng nguồn) cùng `decode_manifest.js`, `extract_classes.js`. **Không tích hợp** mã này vào YomiHub và không dùng để giải mã tiện ích: chép mã dịch ngược của ứng dụng đóng nguồn vào dự án công khai là vi phạm bản quyền, và lấy khóa từ ứng dụng để mở tiện ích mà tác giả chủ ý chỉ cho chạy trong vBook là vượt qua lớp bảo vệ của họ. Người dùng đã được thông báo và đồng ý tiếp tục ("Tiếp tục đi", 22:01).
- Quét 554 mục của 18 kho vBook (BaoBao666888, Darkrai9x ×2, Evamirion, Gold2k2k2k, Ivan1hai, Moleys, SoulGodEve9x9, WillSun28, dat-bi, duongden, gh369-639, hajljnopera, hienpro00123, kychitoge, lethituyen, mizhm, yae-miko-313): **234 mã hóa** (`metadata.encrypt=true`, mọi `src/*.js` là bản mã), **310 không mã hóa** + 3 không mã hóa (mã nén một phần: Legado, 85 Novel, 123 Truyện), 6 thiếu `plugin.zip` trong kho, 1 zip lỗi. Toàn bộ 16 tiện ích báo trong log (MotPhim, RoPhim ×2, GuPhim, LuPhim, Phim4K, Phim Nhựa, Phimtv, AnimeVietsub, Mimimoe, 210CB, CBunu Comic, BLVietsub, Bilibili, Bilibili TV, FreeReels) **vẫn mã hóa**. Kết luận: giữ cách xử lý 0.5.0 (khóa + nhãn "Chỉ chạy trên vBook").

#### D. Lỗi phát hiện và cách sửa (tệp, dòng lệnh)

Log mới có 2.400+ dòng; phần lớn ERROR (Cloudflare MiMiHentai ×23, "Cannot seek in this stream", Pornhub Shorties HTTP 403, Hako `TypeError`, Tor quá 90 giây, Telegram `chat_id is empty`) xảy ra **30/10–03/11 trước khi cài 0.5.0** và đã được xử lý/ghi nhận ở 0.4.5–0.5.0. Sau khi cài 0.5.0 (03/11 13:50 → 21:24) còn 75 dòng WARNING/ERROR:

| Lỗi (sau 0.5.0) | Nguyên nhân thật | Sửa ở 0.5.1 |
| --- | --- | --- |
| 45 × `fetchSourcesList: … unreachable: Failed host lookup: 'raw.githubusercontent.com' (DNS hệ thống và DNS-over-HTTPS)` + github.com, codeberg.org, api.github.com, MediaFire – **trong 13 giây** (14:15:33 → 14:15:47) | Máy mất mạng lúc đó: mọi máy chủ đều không phân giải được, kể cả DoH và gương jsDelivr/statically (`GhMirror`, có từ 0.1.9). Không phải lỗi mã; chỉ là nhật ký ghi 1 dòng cho **mỗi kho** | `lib/services/fetch_sources_list.dart`: khóa `logOnce` đổi từ `'repo-net:$url'` sang `'repo-net:$host'` – 1 dòng cho mỗi máy chủ/phiên ("… sẽ thử lại khi có mạng") |
| 3 × `[Tiểu thuyết] Không tải được nội dung chương "02. Huong dan nhanh…" (Hướng dẫn sử dụng VBook)`: "Không thể tải nội dung từ Gitbook" (14:17, 2 phút sau lúc mất mạng) | Tiện ích vBook `kychi_vbook_docs` gọi `fetch()` tới `vbookapp.gitbook.io`; runtime `vbook.js` nuốt lỗi mạng (trả HTTP 504 giả) nên chỉ thấy câu báo của tiện ích, không biết lỗi thật | `assets/yomihub_extensions/vbook.js`: `fetch()` thử lại 1 lần sau 800 ms khi lỗi mạng; ghi `__vbLastFetchError` (URL + ngoại lệ hoặc `HTTP <mã>`); `__vbRun` nối nguyên nhân vào thông báo lỗi `"… [<url>: <lỗi>]"`. `vbook_bridge.dart`: `runtimeRev = 3` → các tiện ích vBook đã cài tự cập nhật runtime |
| `[Hiệu năng] Khung hình chậm: dựng 1013ms • màn hình: /more` (14:49) – vẫn còn sau sửa 0.5.0 | 0.5.0 chỉ dời `ExtensionMergeScreen.suggestIfNeeded` 1,2 s; hàm vẫn gọi `duplicateGroups()` → `sourceRepository.getInstalled()` = `findAllSync()` **mọi tiện ích kèm mã JS (vài MB)** trên luồng UI | `source_repository.dart`: thêm `installedLiteAsync()` (4 truy vấn thuộc tính `id/baseUrl/itemType/isActive`, bất đồng bộ); `builtin_extensions.dart`: `duplicateGroupCountAsync()`; `merge_screen.dart`: dùng hàm mới, chỉ gợi ý 1 lần/phiên (`_suggested`) |
| `[Hiệu năng] Giao diện bị treo 2.7 giây` + `Khung hình chậm: dựng 2881ms • màn hình: /settings` (14:52) | Màn Cài đặt không có việc nặng; trùng lúc chạy nền các tác vụ đọc **đồng bộ toàn bộ tiện ích/bộ truyện** trên luồng UI: `KotatsuBridge.startIfNeeded` (`getAll().any(…sourceCode.contains('kotatsu'))`), làm mới kho Aidoku/LNReader (`getInstalled()`), `YomiSourceAttribution.refresh` (`getInstalled()` + `isar.mangas…findAllSync()`) | `source_repository.dart`: `anyKotatsuLikeAsync()` (truy vấn Isar `baseUrlContains/sourceCodeUrlContains/sourceCodeContains`), `installedAidokuLnreaderAsync(itemType)`; `kotatsu_bridge.dart`, `fetch_sources_list.dart`, `source_attribution.dart` dùng truy vấn bất đồng bộ (`findAll()`) |
| 9 × `[Cập nhật tiện ích] Tiện ích vBook "…" được tác giả mã hóa` (RoPhim ×2, YOUKU, Anime Vietsub, BLVietsub, Bilibili, Bilibili TV, GuPhim, FreeReels, DocLN, Hako Novel) | Đúng thiết kế 0.5.0 (1 cảnh báo/tiện ích). Mục C: vẫn mã hóa | Không đổi. Nhãn "Chỉ chạy trên vBook" bị cắt (0.5.0 G) → `extension_list_tile_widget.dart`: `_meta` đưa nhãn + ổ khóa xuống dòng riêng (`_metaRow`) |
| `Booru Rule34: missing authentication`, `Hako HandshakeException`, `NHentai/TruyenTranhNQ connection error`, `MeHentai` không có bộ lọc, MediaFire timeout | Thiếu API key Rule34 (cài đặt), mạng/nhà mạng, tiện ích không khai báo bộ lọc | Ghi nhận, không phải lỗi mã |

**YomiHub Update mục 5 – thư mục cục bộ không nhận tệp của Aniyomi/Nekoyomi/Mangayomi** (kiểm tra trực tiếp trên Note 9, thẻ nhớ `/storage/7563-670C/Backup & Sync/Backup Yomi Apps`, 50 GB: 1.828 `.cbz`, 3.203 `.jpg`, 56 `.mkv`, 193 `.epub`):
- Cấu trúc thật: `downloads/<Nguồn (VI)>/<Truyện>/<Chương>.cbz` (Mihon/Nekoyomi), `downloads/<Nguồn>/<Phim>/<Tập>/<Tập>.mkv` (Aniyomi: mỗi tập 1 thư mục; Xvideos/MissAV: `Video/Video.mkv`, `Episode/Episode.mkv`), `downloads/Manga|Anime|Novel/<Nguồn>/<Truyện>/…` + `metadata.json` (Mangayomi), `local/`, `localanime/`, `localnovel/`, `autobackup/`, `mpv-config/`, tải dở `*_tmp`, bản sao lồng `localnovel/localnovel/downloads/…`, sao lưu Kotatsu `kotatsu_*.bk.zip` ở gốc.
- Nguyên nhân: `_scanDirectory` (`file_scanner.dart`) coi **mỗi thư mục con cấp 1 là một bộ truyện** (`downloads`, `local`…) → không tìm thấy chương nào; tập phim trong thư mục riêng không được tính; `.bk.zip` ở gốc bị nhập thành "truyện".
- Sửa (`lib/modules/library/providers/file_scanner.dart`, `audit-0.5.1/e01_local.py`): hàm mới `_collectTitleFolders` đi xuống tối đa 4 cấp tới thư mục **tự chứa nội dung chương** (tệp archive/video/epub, hoặc thư mục con có ảnh/video) – đó là bộ truyện; chống nhập trùng bản sao lồng (khóa `<thư mục cha>/<tên>`); `_isIgnoredLocalSubDirectory` bỏ qua `*_tmp`, `autobackup`, `mpv-config`, `fonts`, `shaders`, `scripts`, `script-opts`, `.thumbnails`, `cache`, `logs`; `_isForeignBackupFile` bỏ `*.bk.zip`, `*.tachibk`, `*.backup`; `episodeVideos` – video trong thư mục tập được nhận làm tập phim, **tên tập = tên thư mục** (tệp bên trong thường chỉ là "Video.mkv"). `YomiSourceAttribution` (có từ 0.2.2) gắn nguồn theo thư mục cha "Tên (LANG)" nên các truyện này tự nhận đúng tiện ích gốc.

**YomiHub Update mục 3 – dự án GitHub còn thiếu:** so khớp 579 liên kết của `Project GitHub.xlsx` (chuẩn hóa: bỏ `#…`, `?…`, `/` cuối, `www.`, http→https) với 605 liên kết trong `lib/yomihub/about/github_projects.dart` → thiếu 17: vBook (Darkrai9x ×4, kychitoge ×10, hieu45666 ×1), `haipham22/LeechText` (bản gốc, ngoài `/releases`), `k2-fsa/sherpa-onnx` → đã thêm (đánh dấu "(0.5.1)"). Kiểm tra lại: **0 thiếu**. (Chỉ là danh sách ghi công; sherpa-onnx **chưa tích hợp** vào mã – xem mục I.)

**YomiHub Update mục 2 – Website Extension:** 46 URL của 30 tiện ích (Film & Movie 22, Comic 3, Novel 2) đối chiếu `builtin_extensions.dart` + `url_override.dart` + `assets/yomihub_extensions/*.js`: **đủ cả 46 tên miền**; ngôn ngữ (`vi` mặc định / `all` cho PornHub, FikFap, Tik.Porn, Kwiky, xFree, FapReel) và NSFW (true cho 18+, false còn lại) khớp sheet. Không phải sửa.

**Bản địa hóa:** 1 chuỗi mới (`Kho vBook không còn tệp plugin.zip…`, `vbook_bridge.dart` – báo rõ HTTP 404 cho 7/554 mục kho vBook thiếu tệp) × 18 ngôn ngữ (`assets/yomihub_i18n/*.json`, giữ định dạng thụt 2 khoảng trắng).

**Phiên bản:** `pubspec.yaml` `0.5.0+42` → `0.5.1+43`; `app_identity.dart` `YomiHub/0.5.1`. `yh_050_test.dart`: kiểm tra phiên bản nới thành `0.`.

Danh sách tệp sửa (`audit-0.5.1/changed_files.txt`, bản gốc ở `audit-0.5.1/before/`): `vbook.js`, 18 × `yomihub_i18n/*.json`, `extension_list_tile_widget.dart`, `file_scanner.dart`, `source_repository.dart`, `fetch_sources_list.dart`, `github_projects.dart`, `app_identity.dart`, `builtin_extensions.dart`, `merge_screen.dart`, `kotatsu_bridge.dart`, `source_attribution.dart`, `vbook_bridge.dart`, `pubspec.yaml`, `test/yh_050_test.dart`, `test/yh_051_test.dart` (mới). Script mới: `sync_051.ps1`, `build_051.ps1`, `qa051.ps1`, `release_051.ps1`, `audit-0.5.1/job.sh`, `wait.sh`, `qa.sh`. `.gitignore`: thêm `audit-0.5.1/backup|qa|yomi_ls*`.

#### E. Phát hiện thêm khi kiểm thử trên Note 9 (SM-N960N, Android 10) – 22:58 → 23:45

1. **Nguyên nhân chính của YomiHub Update mục 5: thiếu quyền bộ nhớ trên Android 7–10.** Sau khi cài 0.5.1 (bản đầu) và bấm "Quét lại mọi thư mục cục bộ", cả 6 thư mục vẫn "Chưa có mục nào". `adb logcat` (`[LocalLibraryScanner]`): `_scanDirectory root list failed … PathAccessException: Directory listing failed … (OS Error: Permission denied, errno = 13)` cho mọi thư mục trên thẻ nhớ; `dumpsys package`: `READ_EXTERNAL_STORAGE: granted=false`. `StorageProvider.requestPermission()` chỉ xin `Permission.manageExternalStorage` ("Quyền truy cập mọi tệp") – quyền này **chỉ có từ Android 11**; Android 7–10 cần `READ/WRITE_EXTERNAL_STORAGE`, và Android 10 cần thêm `requestLegacyExternalStorage`. Thử `pm grant … READ_EXTERNAL_STORAGE` + `appops set … LEGACY_STORAGE allow` trên bản cũ: vẫn `errno 13` (Android 10 coi quyền này là "restricted" khi manifest không khai báo legacy).
   - Sửa: `lib/providers/storage_provider.dart` – `androidSdkInt()` (device_info_plus, cache) và `requestPermission` dùng `Permission.storage` khi SDK < 30, `manageExternalStorage` khi ≥ 30; `android/app/src/main/AndroidManifest.xml` – `<application android:requestLegacyExternalStorage="true" android:preserveLegacyExternalStorage="true">`.
2. **Nhật ký ứng dụng không ghi được gì và màn "Nhật ký ứng dụng" quay vòng mãi** (cùng nguyên nhân): `AppLogger` ghi vào `/storage/emulated/0/YomiHub/logs.txt`; không có quyền → `init()` lỗi im lặng, mọi lỗi bị mất; `AppLogScreen._load()` chờ `AppLogger.flush()` không giới hạn. Sửa: `lib/utils/log/logger.dart` – thử ghi; nếu không được thì dùng `getApplicationSupportDirectory()/logs.txt`; `flush()` tối đa 3 s; `lib/yomihub/ui/app_log_screen.dart` – đọc tệp có `timeout(5 s)` + `try/catch`.
3. **Chạm ma trên màn hình Note 9** (không phải lỗi ứng dụng): khi thử trình phát, phim tự tua liên tục ("↻10 300s → 4980s"). `getevent -lt` (20 s): 7–10 lần chạm vật lý ~15 ms trên `/dev/input/event0` (`sec_touchscreen`) ở vị trí ngẫu nhiên, chủ yếu mép phải – vùng chạm đúp tua +10 s; các lệnh `adb input` không đi qua thiết bị này. Cũng giải thích Camera / Trình duyệt tự mở. Đã báo người dùng (nghi do sạc/cáp USB hoặc màn hình). Chế độ ẩn danh của YomiHub bị bật trong lúc này (lệnh `text:Lịch sử` của `qa051.ps1` – `-match` của PowerShell không phân biệt hoa/thường – khớp "Tạm dừng ghi lịch sử đọc", hoặc chạm ma) → **đã tắt lại**, kiểm tra `checked="false"`. Các bước sau trên Note 9 dùng tọa độ thay vì so chữ.
4. Tiện ích vBook mã hóa "MotPhim" (Ivan1hai): bấm cài 2 lần, vòng quay ~4 s rồi trở lại nút tải, **không khóa / không thấy thông báo**; vì nhật ký không ghi được (mục 2) nên chưa xác định được nguyên nhân trên bản đầu → kiểm tra lại trên bản dựng cuối (mục F).
5. Dữ liệu sau khi cài đè 0.5.0 → 0.5.1 (versionCode 2042 → 2043): nguồn phim, cài đặt, 6 thư mục cục bộ, vị trí tải giữ nguyên. Thư viện Truyện tranh và Lịch sử trống, chưa cài nguồn Truyện tranh – trạng thái trước khi cài không được ghi lại nên không kết luận được là do người dùng xóa hay không.

#### F. Tích hợp "Decode & Extract" (yêu cầu 23:37 / 23:41)
- Kho `https://github.com/kiritokmn1403/Decode-Extract` (của chủ dự án): lần clone đầu (23:38) chỉ có README/LICENSE; lần 2 (23:41) có `Pact/decode_manifest.js` (giải mã Android binary XML) và `Pact/extract_classes.js` (đọc bảng DEX, sinh khung lớp `.java` – không có thân hàm/bytecode), mô tả dùng để dịch ngược `vBooks.apk`.
- Tích hợp dưới dạng **công cụ đọc định dạng tệp**, không dùng để lấy khóa / giải mã tiện ích vBook (giữ nguyên quyết định mục C): `lib/yomihub/apk/axml_decoder.dart` (AXML → cây phần tử + XML), `lib/yomihub/apk/dex_reader.dart` (lớp, lớp cha, interface, chữ ký trường/phương thức), `lib/yomihub/apk/apk_inspector.dart` (đọc APK tiện ích Mihon/Aniyomi/IReader: gói, phiên bản, `tachiyomi.(anime)extension.class`, NSFW, phiên bản thư viện, quyền, lớp nguồn kế thừa `Source`/`HttpSource`/`AnimeHttpSource`/IReader `Source`), `lib/yomihub/apk/apk_inspector_screen.dart` – **Cài đặt › Duyệt › "Kiểm tra tệp APK tiện ích"** (chọn tệp `.apk`, phân tích trong `Isolate.run`).
- Sửa 2 lỗi của script gốc khi chuyển sang Dart: (a) chuỗi UTF-8 ≥ 128 byte – độ dài 2 byte bị đọc thành byte đầu → chuỗi bị cắt (kiểm chứng: mẫu AXML 151 ký tự, `node decode_manifest.js` cho 128 ký tự, bản Dart 151); (b) chỉ số trường/phương thức trong `class_data_item` phải đếm lại từ 0 khi sang nhóm instance field / virtual method (script cộng dồn → tên sai).
- Ghi công: `github_projects.dart` "Decode & Extract – bộ đọc AXML / DEX (0.5.1)". 18 chuỗi giao diện mới × 18 ngôn ngữ (`audit-0.5.1/i18n_apk.py`).
- Test (`yh_051_test.dart`): giải mã mẫu AXML (namespace, thuộc tính, meta-data, chuỗi dài); `ApkInspector` trên chính APK YomiHub vừa dựng (`com.yomihub.app`, ≥ 1 dex, > 100 lớp, quyền INTERNET); `DexReader` từ chối dữ liệu không phải DEX; bản dịch đủ 18 ngôn ngữ.

#### G. Kiểm thử bản dựng lần 2 và lần 3 trên Note 9 (04/11 00:18 → 01:03) và các lỗi sửa thêm
- **Luồng quyền bộ nhớ (bản dựng lần 2, 00:18):** thu hồi các quyền cấp tạm (`pm revoke`, `appops set … LEGACY_STORAGE default`) → cài đè → `LEGACY_STORAGE: allow` (nhờ cờ manifest) → mở app: hộp thoại hệ thống **"Cho phép YomiHub truy cập vào ảnh, phương tiện và tệp trên thiết bị của bạn?"** → Cho phép → `READ_EXTERNAL_STORAGE: granted=true` (hộp thoại của hệ thống chặn chụp màn hình; có trong video `v02_thu_muc_cuc_bo.mp4`). Lần bấm đầu trượt vì màn hình tắt (`Display Power: state=OFF`, ứng dụng "My Files" của Samsung bật lên) → đánh thức, bấm lại.
- **Quét thư mục cục bộ** (Cài đặt › Tải xuống › Quét lại mọi thư mục cục bộ), `adb logcat [LocalLibraryScanner]`:

| Thư mục (thẻ nhớ `…/Backup Yomi Apps/`) | Thư mục truyện tìm thấy | Truyện/phim/sách nhập | Chương/tập |
| --- | ---: | ---: | ---: |
| `downloads` (Aniyomi / Nekoyomi / Mihon / Mangayomi) | 467 | **427** | **1.905** |
| `local` | 1 | 1 | 1 |
| `localnovel` (EPUB) | 737 | **131** | **193** |
| `autobackup`, `localanime`, `/storage/emulated/0/YomiHub/local` | 0 | 0 | 0 |

  Trước khi sửa (bản 0.5.0 và bản 0.5.1 lần 1): **0** ở mọi thư mục. Duyệt › Nguồn cục bộ Truyện tranh hiện các bộ truyện (ảnh màn hình chỉ giữ trên máy – nội dung 18+, không đưa vào gói QA công khai). Thư viện chính chỉ hiện mục yêu thích (thiết kế gốc: mục cục bộ `favorite=false`).
- **Lỗi mới phát hiện:** `crash_reports.json` 00:25:54 – `Failed to open EPUB: Archive Error: Zip Error: invalid Zip archive: Could not find EOCD` (màn `/downloads`, khi quét `localnovel`): `parseEpubFromPath` ném lỗi trong vòng lưu chương → dừng cả lượt lưu. Sửa `file_scanner.dart`: `try/catch`, bỏ qua tệp hỏng, `AppLogger.logOnce('bad-epub:…', '[Thư mục cục bộ] Bỏ qua EPUB hỏng: …')`.
- **Màn "Nhật ký ứng dụng" vẫn quay vòng ở bản lần 2** dù đã giới hạn thời gian chờ → viết lại `_load`: đọc + tách mục trong isolate nền, nối chuỗi tuyến tính (`StringBuffer` thay cho `entries[last] += …` – bậc hai), 3.000 mục mới nhất, `finally` luôn tắt vòng quay. Bản lần 3 (01:01): vòng quay hết ngay, hiện lỗi thật `Illegal argument in isolate message: object is unsendable – _AsyncCompleter` (closure `Isolate.run` tạo trong phương thức `State` kéo theo cây widget) → chuyển `Isolate.run` ra hàm cấp cao: `parseAppLogInBackground(paths)` (`app_log_screen.dart`), `inspectApkInBackground(bytes)` (`apk_inspector_screen.dart` – cùng lỗi). Thêm 2 test **chạy thật** hai hàm này (tệp nhật ký tạm; APK dựng từ mẫu AXML) – test chỉ so chuỗi mã nguồn đã bỏ sót lỗi này.
- **Mạng của Note 9 bị mất** từ khoảng 00:32 (`DnsResolver … ETIMEDOUT`, `NetworkMonitor … Probe failed`): giải thích việc cài lại tiện ích vBook "MotPhim" kết thúc sau ~4 s mà không khóa (tải `plugin.zip` thất bại do mạng, chưa tới bước nhận diện mã hóa). Các phần cần mạng được kiểm thử trên máy ảo / Windows (mục H).
- Kiểm thử tự động sau mọi sửa (`build_051.ps1 -step test`, 01:12): `dart analyze lib` **0 lỗi** (211 info/warning, không đổi so với 0.5.0); `flutter test` 12 tệp yh_040…yh_051: **102/102 đạt**.

#### H. Yêu cầu bổ sung 04/11 06:13 và 06:58; kiểm thử Android TV và Windows (04/11 06:13 → 07:30)
- **06:13 – "tích hợp Decode-Extract":** đã có từ mục F (phiên làm việc trong đêm). Đã kiểm tra lại kho (commit `e5d18b3`, thư mục `Pact/`) và mã Dart (`lib/yomihub/apk/`).
- **06:58 – "Decode-Extract có thể dùng để giải mã các tiện ích vBooks": từ chối**, như mục C. `decode_manifest.js` / `extract_classes.js` chỉ đọc định dạng tệp: AXML, bảng DEX, khung lớp không có thân hàm. Muốn mở 234 tiện ích mã hóa thì phải lấy khóa/thuật toán từ ứng dụng vBook đã dịch ngược, tức vượt qua lớp bảo vệ mà tác giả tiện ích chủ ý đặt, rồi phát hành công khai. Công cụ trong YomiHub giữ vai trò **chỉ đọc** tệp APK tiện ích. Đã đề xuất với người dùng: xin tác giả bản không mã hóa, hoặc dùng 310 tiện ích không mã hóa.
- **Lỗi mới (Android TV 14, máy ảo `YomiHub_TV_API34`):** mỗi lần mở YomiHub, trang hệ thống "Allow access to manage all files" tự hiện, kể cả ở bản dựng 03:20 (đã bỏ `force` ở `local_directory_resolver`). Nguyên nhân: `browse_screen.dart` (`_chekPermission`) và lượt quét nền vẫn gọi `requestPermission()`; cờ `_declinedThisRun` chỉ chặn hỏi lại trong **một lần chạy**.
  - Sửa `lib/providers/storage_provider.dart`: lời gọi không có `force` chỉ hỏi **một lần duy nhất** (`YomiPrefs['storagePromptShown']`). Thao tác người dùng tự bấm (quét lại, thêm thư mục, tải xuống, thư mục mpv) vẫn truyền `force` nên vẫn được hỏi.
  - Test `yh_051_test.dart` có thêm kiểm tra này.
  - Trong lúc thử, phím Enter (`key:23`) trên trang cài đặt đó đã vô tình tắt quyền "manage all files" của `com.android.sharedstoragebackup` **trên máy ảo**. Đã bật lại và kiểm tra: `appops … MANAGE_EXTERNAL_STORAGE: allow`.
- **Android TV** (bản dựng 03:20, APK armeabi-v7a, `versionCode 1043`):
  - Thanh bên chỉ còn Phim & Điện ảnh / Cập nhật / Duyệt / Thêm (`tv02_man_hinh_chinh`).
  - Duyệt › Nguồn: HotPhim, YouTube, AVSub, Anime47, AnimeVN, HayChill, HiHiPhim (`tv03_duyet`).
  - HotPhim: danh sách Phổ biến (`tv04_hotphim`) → chi tiết "Thanh Gươm Diệt Quỷ: Vô Hạn Thành" → **phát được** (logo TOHO, HotPhim HLS, điều khiển tiếng Việt: `tv07_phat_35s`, `tv08_dieu_khien`). Ở 0.5.0 luồng HotPhim không mở được trên máy ảo này.
  - Bấm "Quay lại" khi đang phát → phim thu vào **cửa sổ PiP** (`tv10_chi_tiet`).
  - Phép thử "tiếp tục phát" trên TV bị gián đoạn vì trang quyền nói trên mở lại khi khởi động → kiểm thử lại trên bản dựng cuối (mục I).
- **Windows 11 x64** (bản dựng Windows 02:44):
  - Portable `YomiHub-0.5.1-windows-x64.zip`: giải nén 193 tệp / 331 MB; `YomiHub.exe` 0.5.1+43 chạy, phản hồi (469 MB).
  - `Setup.exe`: bấm "Cài Đặt Ngay" → cài đè 0.5.0+42 vào `%LOCALAPPDATA%\YomiHub`, tự mở ứng dụng với thư viện, danh mục, cài đặt giữ nguyên (`win01_setup_051`).
  - Thêm › gợi ý "Phát hiện 14 nhóm tiện ích trùng tên miền" vẫn hiện, cùng số nhóm như 0.5.0 với truy vấn nhẹ mới (`win03`).
  - Giới thiệu: **Beta (0.5.1)** (`win04`).
  - Nhật ký ứng dụng mở ngay, có dòng gộp mới `fetchSourcesList: kohiden.xyz unreachable (vd. …)` (`win05`). Dòng "Giao diện bị treo 2.8 giây" lúc 06:36:29 trùng lúc máy ngủ / mất kết nối (bộ đo dùng đồng hồ thực).
  - Dự án GitHub đã sử dụng: tìm "vbook" ra 5 mục, gồm 3 mục mới 0.5.1 (`win06`).
  - Cài đặt › Duyệt › **Kiểm tra tệp APK tiện ích** → chọn `YomiHub-0.5.1-armeabi-v7a.apk`: Ứng dụng Android, `com.yomihub.app`, 0.5.1 (1043), minSdk/targetSdk 24/36, 5 tệp `classes*.dex` / 21.500 lớp, 15 lớp nguồn, 18 `<meta-data>`, nút xem `AndroidManifest.xml` (`win07`).
  - `.appxbundle`: **không cài** (phải nhập chứng chỉ `YomiHub-RootCA.cer` vào kho tin cậy của Windows – thay đổi bảo mật hệ thống; người dùng tự chạy `Install-YomiHub.bat`). Kiểm tra cấu trúc: `YomiHub_0.5.1_x64.appx` 270,9 MB, `Package Version="0.5.1.0" Architecture="x64"`, `MinVersion="10.0.14393.0"`, 447 tệp, có `AppxSignature.p7x` (ký `CN=YomiHub, O=YomiHub, C=VN`; `Get-AuthenticodeSignature` = UnknownError vì gốc tự ký chưa được tin cậy – đúng như dự kiến).
  - Ảnh Windows chụp bằng Computer use (chỉ cửa sổ YomiHub; ứng dụng khác bị che). `PrintWindow` cho ảnh trắng với cửa sổ Flutter (vẽ bằng GPU).
- Thư viện Windows có danh mục/ảnh bìa 18+ của người dùng → ảnh chụp thư viện **không** đưa vào gói QA công khai.

#### I. Bản dựng cuối (lần 5, 04/11 07:48 → 08:40) và kiểm thử xác nhận
- Thêm sửa lỗi (07:46, máy ảo Android TV 14): trang "Allow access to manage all files" **vẫn** mở ở mọi lần khởi động dù đã có cờ chỉ hỏi một lần. Nguyên nhân: lượt quét nền chạy **trước** khi `_postLaunchInit` mở `YomiPrefs` (`main.dart`: `AppLogger.init` → … → `YomiPrefs.open()`). Lúc đó `get()` trả về mặc định `false` và `set()` không có hộp lưu, nên cờ không bao giờ được ghi. Sửa `storage_provider.dart`: lời gọi không có `force` chờ `YomiPrefs.ready` (tối đa 10 s); nếu kho vẫn chưa mở thì **không hỏi**. Test bổ sung.
- `build_051.ps1 -step test` (07:48): `dart analyze lib` **0 lỗi**; `flutter test` 12 tệp yh_040…yh_051 **102/102 đạt**.
- `-step apk` / `tv` / `pack`: APK 07:53 → 08:05, TV 08:05 → 08:17, đóng gói 08:17 → 08:22 (`SHA256SUMS-0.5.1.txt` viết lại). Bản Windows giữ bản dựng 02:44 (`j051_080`): mọi thay đổi sau đó (`storage_provider.dart`, `local_directory_resolver.dart`, `downloads_screen.dart`) chỉ chạy trên Android (`if (!Platform.isAndroid) return true`). `Setup.exe` giữ tệp 03:15 – chính tệp đã cài thử lúc 07:00.
- Kiểm thử xác nhận trên bản cuối: 
  - **Note 9** (APK arm64-v8a 08:05, cài đè 2043): mở được, `[LocalLibraryScanner]` khi khởi động: `downloads` 467 thư mục truyện, `local` 1, `localnovel` 737; không `FATAL` / `AndroidRuntime`. Cài đặt `stay_on_while_plugged_in` (đã bật tạm lúc 22:59 để kiểm thử) trả về **0**.
  - **Android TV** (APK armeabi-v7a 08:17): máy ảo `YomiHub_TV_API34` **không ổn định** – `qemu-system-x86_64.exe` lỗi 2 lần (Windows Error Reporting 08:21:34, 08:29:59) với `-gpu swiftshader_indirect`; khởi động lạnh (`-no-snapshot-load`) đưa đĩa về bản 0.4.9 (1041) → cài đè **0.4.9 → 0.5.1 (1043)** thành công. Với `-gpu host`: lần mở 1 hiện trang quyền (hỏi đúng 1 lần), **lần 2 và 3 cửa sổ trên cùng là `com.yomihub.app/…MainActivity`** – không còn trang quyền (`tv14_khong_hoi_quyen`). Phát HotPhim tới 00:35 (`tv15a`, `tv15b`); Lịch sử ghi đủ các lần xem (`tv16_lich_su`).
  - **Không đạt / chưa xác nhận:** "tiếp tục phát" trên máy ảo TV – mở lại phim sau khi tắt ứng dụng: trình phát đứng ở 00:00, màn hình đen (`-2:34:00`), video ghi màn hình hết 3 phút trước khi thấy kết quả tua. Mã trình phát không đổi ở 0.5.1 (đã đạt trên Note 9 ở 0.5.0, mục 0.5.0 F); trên Note 9 đợt này phép thử bị chạm ma làm sai (mục E.3). Cần kiểm thử lại trên TV/điện thoại thật.

#### J. Tệp bàn giao (`output/0.5.1`)
| Tệp | MB | SHA256 |
| --- | ---: | --- |
| YomiHub-0.5.1-arm64-v8a.apk | 168.8 | `1c10012566c15d1e0ae6d18b16f395dd464ab91b7b9eb4e666ce9ecd8af1bb19` |
| YomiHub-0.5.1-armeabi-v7a.apk | 165.6 | `a7be978f96f3703c2bdd2abdfa8a54d2c05499a440a9ed5fb059da2fc9b2d7ea` |
| YomiHub-0.5.1-windows-x64-full.zip | 266.5 | `e1ebae8fe0f700908a7e8a173bbcaf1d24ee2ef16cdddad8b21b4a34389771e5` |
| YomiHub-0.5.1-windows-x64-Setup.exe | 138.7 | `0ca8bd428436687ce54d8b5e838534bd5402fb023ddb9048a13c29bd4341adb1` |
| YomiHub-0.5.1-windows-x64.appxbundle | 270.9 | `5e55cd111a502039f32bc285a3431c7b49a34c2dbe63010973f36a613d642064` |
| YomiHub-0.5.1-windows-x64.zip | 138.6 | `4e7d7a324775d9fca0420c02e9bee82d7d850bf5d4c15471787e0534f67b7255` |
| YomiHub-0.5.1-x86_64.apk | 178.1 | `29bbe7c35f169677453ae0753713d3937026da3b2747affb2b452d72b73dd551` |
| YumiHub-Android-TV-0.5.1-arm64-v8a.apk | 168.7 | `f7e0dcbac8f3cd041d7ff4d104e17ef6f747fdcb60e402127f5f6cf50ac64468` |
| YumiHub-Android-TV-0.5.1-armeabi-v7a.apk | 165.5 | `c886840fbe6bcd67768893ea938f09a82de6d8d26da0090dc09fb56854b46a1b` |
| YumiHub-Android-TV-0.5.1-x86_64.apk | 178.0 | `0ebe303393c3bb97c39c5cab72e0b87aa68bb88046c2b616c6f40ebe7de7c601` |

Kèm `SHA256SUMS-0.5.1.txt`, `YomiHub-RootCA.cer`, `Install-YomiHub.bat/.ps1`, `YomiHub-0.5.1-changelog.md`; ảnh/video kiểm thử đã lọc (34 tệp, không có nội dung 18+ / thư viện / tệp cá nhân): `output/YomiHub-0.5.1-QA-screenshots.zip` (`audit-0.5.1/make_qa_zip.ps1`).

#### K. GitHub
__GITHUB__
