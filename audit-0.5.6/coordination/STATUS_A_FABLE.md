# Trạng thái Phần A — Claude Fable 5.2 (ghi nối, không xóa)

## [2026-11-10 22:06] A — ĐANG LÀM
Đã đọc 00_PLAN.md, PART_A_FABLE.md, AGENTS.md, CLAIMS.md, REVIEW_CLAUDE.md (không có YÊU CẦU SỬA → A). Đang đọc TECHNICAL_UPDATE_NOTES.md và yêu cầu gốc. Thứ tự: A1 → A2 → A3 → A4. jobs/runner_alive.txt ghi 2026-11-06T19:20:57 (cũ) — sẽ kiểm lại trước khi gửi job.

## [2026-11-10 22:16] A1 — ĐANG LÀM
Trình chạy job đã hoạt động (probe jobs/done/a056_probe.log, 22:13). Upstream: shell và container đều không tới được github.com (proxy 403); dùng `src/mangayomi` = v0.9.7+125 (BASE_VERSION v0.9.7, trùng `yh/mangayomi.zip`); trang Releases cho thấy bản phát hành mới nhất là v0.9.6 nên 0.9.7 là bản mới nhất có được.
Thiết kế A1: giữ nguyên các route /MangaLibrary, /AnimeLibrary, /NovelLibrary, /playBooks; thanh điều hướng gộp thành một đích "Thư Viện" + dải tab con. Tệp giữ chỗ: main_screen.dart, appearance_screen.dart, yomihub_i18n/*.json. Tệp mới: lib/yomihub/library/library_hub.dart, library_hub_bar.dart, lib/yomihub/ui/ui_style.dart, test/yh_056_a_test.dart.

## [2026-11-10 22:44] A1/A2 — ĐANG LÀM (mã xong, chờ khóa dựng để analyze + test)
**Đính chính upstream (quan trọng cho phiên điều phối):** job `a056_upstream` chạy trên máy Windows (có mạng) cho thấy upstream **không phải 0.9.7**:
`main` của kodjodevf/mangayomi = **0.9.95+128**, Release mới nhất **v0.9.95 (01/11/2026)**. Bằng chứng: `evidence/A/upstream_mangayomi_main.txt`.
Đã tải mã nguồn tag v0.9.95 về `D:\A.I Project\yh\upstream-0.9.95\` (zip 151.250.803 byte, SHA256 C71103DC…EB0FE1; đã giải nén `lib/`, `pubspec`).
Giao diện mới của 0.9.95: hệ thiết kế "Shiori" (`packages/shiori`), thanh điều hướng nổi, **nhóm điều hướng** (`nav_groups.dart`: Library = 3 thư viện, Activity = Updates + History) với bộ chọn dạng phân đoạn.
YomiHub đang dựa trên 0.9.7 (839 tệp overlay). Chuyển nền lên 0.9.95 (931 tệp Dart, gói shiori, isar 3.4.1) **không làm trong đợt này** — cần chủ dự án quyết định (xem báo cáo cuối).
Phần đã đưa vào overlay (viết lại bằng widget Flutter sẵn có, không thêm gói):
- A1: `lib/yomihub/library/library_hub.dart` (quy tắc gộp, thuần Dart), `library_hub_bar.dart` (dải tab con, nhận tiêu điểm D-pad), sửa `main_screen.dart` (một đích "Thư Viện" trên thanh dưới/thanh bên; nhớ thư viện vừa xem; tắt tính năng → ẩn tab; TV chỉ Phim & Điện Ảnh, không hiện dải tab; huy hiệu Cập nhật/Duyệt giữ nguyên).
- A2: `lib/yomihub/ui/ui_style.dart` (cài đặt `uiStyle` trong YomiPrefs → có trong sao lưu; mặc định Cũ), ô chọn trong Cài đặt › Giao diện (`appearance_screen.dart`). "Mới" = nhóm điều hướng kiểu 0.9.95: Cập nhật + Lịch sử gộp thành "Hoạt động", bộ chọn dạng viên; đổi ngay không khởi động lại.
- 6 chuỗi mới × 18 ngôn ngữ trong `assets/yomihub_i18n/*.json`. Kiểm thử: `test/yh_056_a_test.dart`.
Danh sách tệp để đồng bộ: `audit-0.5.6/A_changed_files.txt`. Job `a056_t01` đang chờ BUILD_LOCK (B giữ từ 22:24).

## [2026-11-10 22:44] A3 — ĐANG LÀM
Nguyên nhân "Cầu nối Kotatsu chưa chạy" (log 31/10 09:56, 09:57, `IncompleteMessage`): runtime JS chỉ gọi `KotatsuBridge.ensureStarted()` mà không chờ; khi máy chủ nội bộ đã ngừng trả lời thì cờ `_started` vẫn true nên không bao giờ khởi động lại (Android: `start()` thoát sớm khi `server != null`).
Sửa: `kotatsu_bridge.dart` (+ping, `ensureAlive`, `markDead`), `lib/eval/javascript/http.dart` (yêu cầu tới 127.0.0.1:47350 chờ cầu nối sống, lỗi kết nối → khởi động lại và gửi lại 1 lần, ghi Nhật ký), `YomiKotatsu.kt` (thay máy chủ đã chết). Đã ghi CLAIMS. B1.6 của B có nhắc cầu nối Kotatsu — A đã xử lý phần này, B không cần sửa 3 tệp trên.

## [2026-11-10 22:59] A1 — XONG (mã + kiểm thử tự động; chưa thử trên thiết bị)
Đã chỉnh theo yêu cầu điều phối 22:49: theo nhóm điều hướng của Mangayomi v0.9.95 (tab + vuốt ngang), thêm `lib/yomihub/library/side_swipe.dart`.
Tệp: main_screen.dart, library_hub.dart, library_hub_bar.dart, side_swipe.dart. Lệnh: job a056_t03. Kết quả: 20 ca A1 đạt. Bằng chứng: evidence/A/a056_t03.test.log.

## [2026-11-10 22:59] A2 — XONG MỘT PHẦN
Công tắc Cũ/Mới (mặc định Cũ, lưu + sao lưu, đổi ngay), 6 chuỗi × 18 ngôn ngữ, 7 ca đạt. "Mới" mới gồm phần điều hướng của v0.9.95 (nhóm Hoạt động, bộ chọn dạng viên, vuốt ngang);
**chưa** có toàn bộ giao diện Shiori (cần chuyển nền 0.9.7 → 0.9.95, đụng lưu trữ thư viện — chờ chủ dự án quyết định). Chi tiết: notes/NOTES_A.md mục A2.

## [2026-11-10 22:59] A3 — XONG MỘT PHẦN
Bảng 10 dự án trong NOTES_A.md. Đã sửa "Cầu nối Kotatsu chưa chạy" (6 ca đạt; phần Kotlin chưa biên dịch). kotatsu-syncserver, plugin-sdk: CHƯA tích hợp (lý do trong bảng); subsampling-scale-image-view: không áp dụng cho Flutter.

## [2026-11-10 22:59] A4 — KHÔNG ĐẠT (Android 6.0) / đã rà hàng đợi Isar
Không chạy lại thử minSdk 23: điều kiện chặn không đổi (isar 3.3.2), và quy trình thử phải vá engine Flutter/bộ đệm Gradle dùng chung trong lúc đang dựng phát hành. Giữ minSdk 24. Bằng chứng: evidence/A/A4_env_probe.txt.
Hàng đợi Isar: không sửa mã; ghi một điểm yếu (Zone rò) kèm đề xuất trong NOTES_A.md.

## [2026-11-10 22:59] MỐC 1 SẴN SÀNG (A)
`dart analyze lib`: 0 lỗi, 166 cảnh báo, 51 info (evidence/A/a056_t02.analyze.log; chạy trước khi thêm side_swipe.dart, sau đó phân tích lại thư mục A sửa: 0 lỗi — a056_t03.analyze.log).
`flutter test` toàn bộ: 615 đạt, 2 trượt — `yh_054_test.dart`, `yh_055_test.dart` so User-Agent với phiên bản cũ sau khi B nâng 0.5.6 (không thuộc tệp của A, A không sửa). `yh_056_a_test.dart`: 34/34.
Tệp cần đồng bộ vào build và buildwin: audit-0.5.6/A_changed_files.txt (28 tệp; SHA256 ở evidence/A/A_overlay_sha256.txt). Bản dựng Android đã có tệp của A (job chép, bản cũ lưu ở evidence/A/build_backup_android); **buildwin chưa**.
Đã TRẢ mọi claim. BUILD_LOCK trống. Chưa có: thử trên thiết bị/giả lập, dựng APK (phần Kotlin), ảnh/video.

## [2026-11-11 04:58] A4b (hàng đợi ghi Isar) — ĐANG LÀM
Nhận việc điều phối 05:05 (mục 6 của 00_PLAN). Không có YÊU CẦU SỬA → A mới trong REVIEW_CLAUDE.md. Đã ghi CLAIMS db_write_queue.dart, yh_056_a_test.dart.

## [2026-11-11 05:15] A4b (hàng đợi ghi Isar) — XONG (mã + kiểm thử tự động; chưa thử trên thiết bị)
Tệp: overlay/lib/repositories/db_write_queue.dart (tái nhập gắn với tác vụ đang chạy; stallTimeout 120 s chống khóa chết), overlay/test/yh_056_a_test.dart (+7 ca).
Lệnh: job a056_t04 (trượt biên dịch test), t05 (2 trượt), t06, t07. Kết quả cuối: `dart analyze lib` 0 lỗi / 166 cảnh báo / 52 info; yh_056_a 41/41; toàn bộ 644 đạt, 1 trượt (`yh_049`: 13 chuỗi của phần khác thiếu bản dịch tiếng Anh — không thuộc A).
Bằng chứng: evidence/A/a056_t06.*.log, a056_t07.*.log; log trượt giữ nguyên (t04_failed_compile, t05). Ghi chú: NOTES_A.md mục "Bổ sung".
Đã ghi quyết định phương án 1, kotatsu-syncserver, Android 6.0 (chờ MỐC 2 DUYỆT) vào NOTES_A.md. Đã TRẢ claim, BUILD_LOCK trống. A_changed_files.txt nay 29 tệp (SHA256 đã cập nhật); buildwin chưa đồng bộ.

## [2026-11-11 06:00] R14 + R15 — ĐANG LÀM (phiên Fable-A tiếp nối)
Nhận R14 (nhãn "Play Books" qua i18n) và R15 (hàng đợi ghi Isar: thao tác dài hợp lệ không bị ghi chen) từ REVIEW_CLAUDE.md mục 05:25. Đã ghi CLAIMS: main_screen.dart, yomihub_i18n/*.json, db_write_queue.dart, yh_056_a_test.dart.

## [2026-11-11 09:52] R14 + R15 — XONG (điều phối ghi thay sau khi job a056_t08 chạy lại)
Job a056_t08 chạy lại 07:29 sau khi máy ngủ, xong 08:00. `dart analyze lib`: 0 lỗi, 166 cảnh báo (218 mục gồm info).
`yh_056_a_test.dart`: 50/50 đạt (gồm 8 ca R15, ca R14). Toàn bộ `flutter test`: 654 đạt, 1 trượt — `yh_049` do chuỗi Phần C chưa dịch (R10, B đang làm).
Đo khôi phục trên DB tạm (dữ liệu sinh): 50k chương 0,77 s · 200k 3,7 s · 500k 9,5 s — thấp hơn nhiều so với ngưỡng 120 s.
Log: `evidence/A/a056_t08.*`. Claim A đã trả. Còn lại: cập nhật `evidence/A/A_overlay_sha256.txt` (giao Haiku); đồng bộ tệp A sang `buildwin` khi dựng lại Windows.
