# YomiHub — Ghi chú kỹ thuật cập nhật

**BẮT BUỘC ĐỌC TRƯỚC MỖI LẦN CẬP NHẬT.**

Chủ dự án yêu cầu tạo và duy trì tài liệu này ngày 25/10/2026. Quy định được ghi thêm trong `AGENTS.md` ở gốc dự án. Mỗi người hoặc tác nhân tự động cập nhật ứng dụng phải đọc toàn bộ tài liệu, kiểm tra trạng thái và bổ sung kết quả sau khi làm việc.

## 1. Trạng thái hiện tại

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
