# Ghi chú Kỹ thuật UI Features — YomiHub 0.5.8

**Tác nhân thực hiện**: @ui-features  
**Thời gian bắt đầu**: 17/11/2026 12:15 (UTC+7)  
**Phạm vi**: 6 hạng mục giao diện và tính năng UI của YomiHub 0.5.8.

---

## 1. Màn hình chờ & Animation Loading (Loading Screen Animation)
- **Yêu cầu**: Thời lượng chính xác 5 giây, logo bo tròn, hiệu ứng morph mượt mà chuyển đổi hình học từ hình vuông sang hình tròn.
- **Hiện trạng & Phân tích**:
  + `overlay/lib/yomihub/splash/yomi_splash.dart` định nghĩa thời lượng `YomiSplash.total = Duration(milliseconds: 5000)`.
  + Tiến trình `t` chạy từ 0.0 đến 1.0 trong 5.000 ms.
  + Giai đoạn 0.05–0.35 s thực hiện morph hình học từ hình vuông sắc nét (`r = 0.0`) sang hình tròn hoàn chỉnh (`r = size / 2 = 66.0`) sử dụng đường cong mượt `Curves.easeInOutCubic`.
- **Nâng cấp thực hiện**:
  + Đóng gói hàm tính bán kính chuyển đổi `YomiSplash.morphRadius(double t, [double size = 132.0])` cho phép kiểm thử toán học chính xác và tái sử dụng.
  + Đảm bảo sau giai đoạn morph (t >= 0.35), logo duy trì trạng thái tròn hoàn hảo (`r = 66.0`), kết hợp hiệu ứng hào quang (aurora background), quỹ đạo 3 badge và hiệu ứng thoát mở rộng hình tròn `_HoleClipper`.

---

## 2. Tích hợp Giao diện Mới Mangayomi (Shiori Design System) & Công tắc Cũ/Mới
- **Yêu cầu**: Tích hợp bộ giao diện Mangayomi New Version (Shiori Design System) kèm công tắc chuyển đổi giữa Bản Cũ (Classic YomiHub) và Bản Mới (Modern Mangayomi).
- **Hiện trạng & Phân tích**:
  + `overlay/lib/yomihub/ui/ui_style.dart` quản lý `YomiUiStyle.classic` và `YomiUiStyle.modern` lưu trong `YomiPrefs` khóa `uiStyle`.
  + Giao diện Cài đặt > Giao diện (`appearance_screen.dart`) nhúng `YomiUiStyleTile()`.
  + Thư viện Shiori Design System hoàn chỉnh tại `overlay/lib/yomihub/ui/shiori/`.
  + Bản 0.5.7 trước đó còn tồn đọng: `ShioriHeader`, `ShioriTheme`, `ShioriCard` chưa được kết nối đầy đủ.
- **Nâng cấp thực hiện**:
  + Kết nối `ShioriSectionHeader`, `ShioriCard` và `ShioriShape.card` vào `overlay/lib/yomihub/merge/extension_merge_screen.dart`.
  + Tự động kích hoạt kiểu dáng Shiori hiện đại khi `YomiUi.isModern == true`, bảo toàn 100% giao diện truyền thống khi ở chế độ `classic`.

---

## 3. Thư mục cục bộ trong mục Tải Xuống (Local Folders in Downloads)
- **Yêu cầu**: Cho phép thêm và quản lý nhiều thư mục tải cục bộ riêng biệt khác nhau, hoạt động ổn định.
- **Hiện trạng & Phân tích**:
  + `overlay/lib/modules/more/settings/downloads/downloads_screen.dart` và `overlay/lib/yomihub/library/local_folders.dart` quản lý các thư mục nguồn cục bộ.
  + Cơ chế `YomiLocalFolders.validateNew` ngăn chặn trùng lặp tuyệt đối, ngăn thư mục con lồng nhau hoặc thư mục cha bao bọc.
  + `_normalizeLocalFolders` chuẩn hóa đường dẫn, gán tên duy nhất (`Local`, `Local 2`, hoặc tên người dùng đặt), cho phép thêm vô số thư mục riêng biệt.
  + Hỗ trợ quét đồng thời hoặc từng thư mục, đổi tên di chuyển liên kết, tính dung lượng trống bằng Win32 API / Android channel và hiển thị trực quan.

---

## 4. Lịch sử tìm kiếm & Cài đặt Booru trong App Backup/Restore
- **Yêu cầu**: Đảm bảo toàn bộ lịch sử tìm kiếm, danh sách yêu thích và cài đặt của Booru App được bao gồm đầy đủ trong bản sao lưu và khôi phục của ứng dụng.
- **Hiện trạng & Phân tích**:
  + `overlay/lib/yomihub/booru/booru_store.dart` quản lý dữ liệu Booru qua Hive box `yomihub_booru` gồm:
    * `history`: Lịch sử các từ khóa tìm kiếm (List<String>).
    * `favourites`: Danh sách các bài đăng yêu thích (List<Map>).
    * `customSites`: Các trang Booru do người dùng thêm vào.
    * `activeSite`: Trang Booru đang chọn.
    * `columns`, `fullQuality`, `autoplayVideo`, `blacklist`, `downloads`: Cấu hình hiển thị và vận hành.
    * `creds`: Thông tin đăng nhập và API key (thuộc nhóm nhạy cảm, chỉ sao lưu khi người dùng chọn).
  + `overlay/lib/yomihub/backup/yomi_backup_extras.dart` đã theo dõi `yomihub_booru` trong danh sách `boxes`.
- **Nâng cấp thực hiện**:
  + Bổ sung phương thức `onRestored()` trong `BooruStore` để phát tín hiệu thông báo `notifyListeners()`.
  + Khi `YomiBackupExtras.restore` khôi phục xong box `yomihub_booru`, tự động gọi `BooruStore.instance.onRestored()`, giúp giao diện người dùng cập nhật tức thì dữ liệu đã khôi phục mà không cần khởi động lại ứng dụng.

---

## 5. Hợp nhất cấu hình Widget Merging
- **Yêu cầu**: Tự chọn tiện ích để hợp nhất; gom toàn bộ cài đặt liên quan vào một mục cài đặt riêng mang tên "Hợp Nhất Tiện Ích".
- **Hiện trạng & Phân tích**:
  + `overlay/lib/yomihub/merge/extension_merge_screen.dart` là trung tâm cấu hình Hợp Nhất Tiện Ích (`/mergeExtensions`).
  + Màn hình tập trung:
    * Banner hướng dẫn.
    * Công cụ "Tự chọn các tiện ích để hợp nhất" (`_pickAndMergeExtensions`).
    * Nhóm công cụ: `CustomMergeSourcesTile()`, `MergeDuplicateMangaTile()`, `ManualMergeMangaTile()`, và lối dẫn sang `ContentMergeScreen` (`/contentMerge`).
    * Danh sách các nhóm tiện ích đã hợp nhất với nút hủy hợp nhất từng nhóm.
  + Đã loại bỏ các tile trùng lặp phân tán trong "Dữ liệu và bộ nhớ", gom thành một lối vào duy nhất đến `/mergeExtensions`.
- **Nâng cấp thực hiện**:
  + Nâng cấp giao diện `ExtensionMergeScreen` với `ShioriSectionHeader` và `ShioriCard` khi bật giao diện Mới.

---

## 6. Rà soát & Đồng bộ i18n trên 18 ngôn ngữ
- **Yêu cầu**: Rà soát và đồng bộ toàn bộ chuỗi giao diện trên 18 ngôn ngữ được ứng dụng hỗ trợ trong `assets/yomihub_i18n/*.json`.
- **Kết quả kiểm toán thực tế**:
  + 18 tệp ngôn ngữ: `ar`, `as`, `de`, `en`, `es`, `es_419`, `fr`, `hi`, `id`, `it`, `ja`, `ko`, `pt`, `pt_BR`, `ru`, `th`, `tr`, `zh`.
  + Tổng số chuỗi `tr()` tĩnh được sử dụng trong `overlay/lib`: **1.474 chuỗi**.
  + Tổng số khóa trong mỗi tệp ngôn ngữ: **1.657 khóa**.
  + Số khóa thiếu trong `en.json`: **0**.
  + Độ đối xứng giữa 18 ngôn ngữ: **100% đối xứng hoàn hảo (18/18 tệp có cùng 1.657 khóa, 0 khóa lệch)**.

---

## 7. Bộ kiểm thử tự động (Test Suite)
- Đã xây dựng `overlay/test/yh_058_ui_features_test.dart` bao phủ toàn diện cả 6 hạng mục với 12 test case chuyên sâu:
  1. `Splash duration is exactly 5 seconds`
  2. `Morph radius transitions smoothly from square (r=0) to full circle (r=size/2)`
  3. `YomiSplash builds correctly with child and animation controller`
  4. `Toggle between Old Version (classic) and New Version (modern)`
  5. `YomiUiStyleTile renders toggle switch with Old (Cũ) and New (Mới) options`
  6. `ShioriSectionHeader and ShioriCard adapt to theme`
  7. `Cover and Badge adapt between Classic and Modern styles`
  8. `Multiple distinct local folders can be validated and added`
  9. `Path normalization and disk space formatting`
  10. `BooruStore manages search history and settings in Hive`
  11. `YomiBackupExtras collects and restores Booru search history and settings`
  12. `ExtensionMergeScreen consolidates all merge tools and group management`
  13. `Data & Storage contains single consolidated entry to mergeExtensions`
  14. `All 18 language translation files exist and have identical symmetric keys`
  15. `All static tr() calls in overlay/lib exist in en.json`
