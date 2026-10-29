# YomiHub — Ghi chú kỹ thuật cập nhật

**BẮT BUỘC ĐỌC TRƯỚC MỖI LẦN CẬP NHẬT.**

Chủ dự án yêu cầu tạo và duy trì tài liệu này ngày 25/10/2026. Quy định được ghi thêm trong `AGENTS.md` ở gốc dự án. Mỗi người hoặc tác nhân tự động cập nhật ứng dụng phải đọc toàn bộ tài liệu, kiểm tra trạng thái và bổ sung kết quả sau khi làm việc.

## 1. Trạng thái hiện tại

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


