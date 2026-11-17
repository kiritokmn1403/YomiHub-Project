# Rà mã C2 (giao diện Mới) — Sonnet, 11/11/2026

| Mức | Tệp:dòng | Mô tả | Đề xuất |
|---|---|---|---|
| NÊN SỬA (cần điều phối phán quyết) | lib/modules/main_view/main_screen.dart (khối build, buildMainNav) + library/library_hub.dart | Chế độ Cũ KHÁC 0.5.5: Manga/Anime/Novel/Play Books gộp thành mục "Thư Viện" + dải tab con ở cả Cũ lẫn Mới (libraryHubTabs không phụ thuộc `modern`); logic cũ `mergeLibraryNavMobile`/`isLibSwitch`/`_enableLibSwitch` không còn được dùng (cài đặt "gộp thư viện" vô tác dụng). Có thể là chủ ý theo sheet hàng 12-13 (việc của A), nhưng trái yêu cầu C2 #4 "Cũ giữ nguyên 0.5.5". | Điều phối xác nhận: hoặc chấp nhận (ghi rõ trong NOTES), hoặc gate hub theo `modern`. |
| NÊN SỬA | lib/yomihub/ui/shiori/shiori_card.dart, shiori_header.dart, shiori_transitions.dart, shiori_badge.dart | Mã chết: không có nơi nào ngoài test dùng ShioriCard/ShioriCoverCard/ShioriSectionHeader/ShioriPageTransitionsBuilder. STATUS ghi "thẻ thư viện", "chuyển cảnh" XONG nhưng thực tế chưa gắn vào Thư Viện/theme. Chỉ nav bar nổi + pill tab thật sự có hiệu lực. | Sửa STATUS/NOTES cho đúng (phần còn lại = 0.5.7) hoặc gắn thật. |
| NÊN SỬA | main_screen.dart (_MobileBottomNavigation, nhánh Shiori) | Nhánh Shiori không có test dựng MainScreen; STATUS C2.6 nói "NavigationRail bọc Liquid Glass trên desktop" nhưng diff không có thay đổi nào cho rail ở chế độ Mới. | Sửa mô tả STATUS. |
| NÊN SỬA | test/yh_056_c2_ui_test.dart | 13 ca: 5 ca chỉ kiểm hằng số token (ShioriSpace/Shape/Motion/Colors) — yếu; không có test dựng MainScreen/màn hình chính ở 2 chế độ, không có test TV (yêu cầu #7). Test Cũ/Mới chỉ kiểm YomiUi.parse/set. | Thêm ít nhất 1 widget test nav ở TV (isTv) không ra Shiori và test đổi Cũ↔Mới tại chỗ. |
| GHI CHÚ | shiori/*.dart dòng 1-2 | Ghi nguồn "Inspired by ... (Apache-2.0 / MIT)" mơ hồ; mã tự viết, không thấy chép nguyên văn. | Ghi rõ giấy phép thật của Mangayomi (Apache-2.0) nếu có chép ý tưởng. |
| GHI CHÚ | shiori_nav_bar.dart | LiquidGlassBar + BackdropFilter lồng (2 lớp blur), màu cứng hex thay vì ColorScheme; chỉ để ý hiệu năng. Không có focus order D-pad riêng nhưng TV không dùng nhánh này (`!isTv` đúng). | Không chặn. |
| GHI CHÚ | main_screen.dart:_onPrefsChanged | Đổi Cũ/Mới tại chỗ qua YomiPrefs.changes, listener add/remove đúng, Column cùng hình dạng nên giữ trạng thái trang. Tốt. | — |

Đã kiểm, KHÔNG có vấn đề: i18n 18 tệp đều 1575 khóa; pubspec chỉ đổi version (không thêm gói); không đụng Isar/mô hình/lưu trữ; TV: Booru/Comic(Manga)/Novel/Play Books vẫn bị loại (libraryHubTabs tv chỉ Anime; `tv && /booru` bỏ; nhánh Shiori `!isTv`); không thấy ref/context sau await hay controller rò rỉ trong tệp mới; không có chuỗi cứng trong shiori/*.

## Kết luận: **cần sửa nhẹ / chờ điều phối phán quyết mục 1** (không có lỗi CHẶN biên dịch/dữ liệu). Nếu điều phối chấp nhận hub ở chế độ Cũ như ý định sheet và STATUS được chỉnh cho đúng thực tế, thì đủ điều kiện MỐC 1b.
