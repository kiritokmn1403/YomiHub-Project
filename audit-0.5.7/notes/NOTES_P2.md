# NOTES_P2 - U5 phần trình đọc (Sonnet, 14/11/2026)

## Yêu cầu
Nối các mô-đun `lib/yomihub/integrations/` (Yomikiru, Yomihon, GIF Viewer, Nyora) vào trình đọc theo cài đặt YomiPrefs, mặc định không đổi hành vi; thêm công tắc cài đặt; cập nhật `integrationAuditTable`.

## Hiện trạng / quyết định (sau khi đọc mã)
- Yomikiru: reader_view.dart ĐÃ có phím tắt (`ReaderKeyboardHandler`: mũi tên, N/P, PageUp/Down = đổi chương, F11, Esc), ghép trang đôi tự động theo chiều ngang (`doublePageAutoStateProvider`), scale type. => Chỉ nối phần còn thiếu: phím A/D/Space/Home/End (công tắc `yomikiru_extra_keys`, mặc định tắt). Ghép trang đôi + kiểu căn trang: bỏ (trùng tính năng có sẵn).
- Yomihon: novel_reader_view có sẵn line-height riêng. Nối: preset typography (chỉ line-height) khi bật `yomihon_typography_enabled`, và chip "thời gian đọc ước tính" theo WPM khi bật `yomihon_show_reading_time`. Chế độ dọc (Tate-gaki): bỏ (cần engine bố cục mới).
- GIF Viewer: không có màn xem ảnh/GIF độc lập; trình đọc dùng ExtendedImage tự phát GIF. Điều khiển từng khung cần viewer mới => không nối gượng, ghi rõ trong bảng.
- Nyora: manifest chỉ là siêu dữ liệu nguồn, không có mã cài đặt được => không thể thêm vào repo_importer (định dạng index Mangayomi khác). Không nối, ghi rõ lý do.

## Tệp sửa (overlay/, bản gốc sao lưu ở backup/src_0571/)
- lib/yomihub/integrations/yomikiru_reader_enhancer.dart: thêm `prefExtraKeys`, `extraKeysEnabled` (mặc định false), `extraKeyAction`.
- lib/modules/manga/reader/mixins/reader_gestures.dart: `ReaderKeyboardHandler` thêm `extraKeys`, `onFirstPage`, `onLastPage`; nhánh default xử lý A/D/Space/Home/End (A/D đảo khi đọc phải-sang-trái); phím cũ không đổi.
- lib/modules/manga/reader/reader_view.dart: truyền `extraKeys` + `_yhJumpEdgePage` (Home/End nhảy trang đầu/cuối, tính cả chế độ trang đôi).
- lib/yomihub/integrations/yomihon_novel_enhancer.dart: pref `yomihon_typography_enabled`, `yomihon_show_reading_time`, `presetLineHeight`, `effectiveLineHeight`, `plainTextFromHtml`, `wpmChoices`; `formatReadingTime` dùng `tr()`; SỬA LỖI đếm từ (`\w` Dart chỉ ASCII nên tiếng Việt có dấu bị tách đôi, đếm dư; nay dùng `\p{L}\p{N}` unicode + CJK từng ký tự).
- lib/modules/novel/novel_reader_view.dart: line-height qua `effectiveLineHeight`; chip "Ước tính: X" (góc phải trên thanh dưới) khi thanh công cụ mở và bật công tắc.
- lib/yomihub/integrations/integration_settings.dart (MỚI): `YomikiruSettingsSection`, `YomihonSettingsSection`.
- lib/modules/more/settings/reader/reader_screen.dart (thêm mục Yomikiru cuối trang), novel_reader_screen.dart (thêm mục Yomihon dưới tab Chung).
- lib/yomihub/integrations/yomi_integrations.dart: bảng cập nhật: Yomikiru/Yomihon "Đã tích hợp một phần", Nyora/GIF Viewer "Không tích hợp" + lý do. Zenshin/Nuvio giữ nguyên (P3 phụ trách).
- test/yh_057_p2_test.dart (MỚI, 10 test); notes/i18n_P2.json (16 chuỗi x 18 ngôn ngữ) đã gộp bằng i18n_merge.py P2 (+15 mỗi ngôn ngữ, 1 khóa đã có sẵn).

## Không nối (lý do)
- Yomikiru ghép trang đôi / kiểu căn trang: trình đọc đã có trang đôi tự động theo chiều ngang + scale type.
- Yomihon chế độ dọc (Tate-gaki): cần bộ bố cục mới, chưa làm.
- Nyora: manifest chỉ là siêu dữ liệu nguồn, không có mã cài được, khác định dạng index của repo_importer.
- GIF Viewer: không có màn xem ảnh/GIF độc lập; điều khiển khung hình cần viewer riêng.
- Chưa kiểm tra trên thiết bị thật (chỉ analyze + test đơn vị/kiểm điểm nối mã).

## Job / kết quả
- p2_a: analyze 0 error; 1 test trượt (đếm từ tiếng Việt) -> sửa bug thật.
- p2_b (analyze 7 mục + test yh_057_p2 + yh_056_part_c + yh_049): `1 issue found` = warning CŨ `reader_view.dart:64:44 unnecessary_non_null_assertion` (có sẵn từ bản gốc, dòng 63 cũ); không có error/warning mới. `00:36 +41: All tests passed!` `### TEST EXIT 0`.

## Còn lại
- Thử tay trên Windows: bật công tắc, bấm A/D/Space/Home/End trong trình đọc truyện; xem chip thời gian đọc và preset giãn dòng ở trình đọc tiểu thuyết.
- Zenshin/Nuvio: P3. Yomihon vertical mode, GIF viewer: để dành nếu chủ dự án muốn.
