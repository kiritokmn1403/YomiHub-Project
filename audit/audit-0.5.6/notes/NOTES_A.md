# NOTES_A — Phần A (Claude Fable 5.2), YomiHub 0.5.6+48

Ghi lúc 2026-11-10 22:59 (Asia/Saigon). Mẫu: hạng mục · lỗi phát hiện · tệp và dòng đã sửa · công cụ dùng · kết quả kiểm thử · ngày giờ.
Danh sách tệp overlay của Phần A: `audit-0.5.6/A_changed_files.txt` (SHA256: `evidence/A/A_overlay_sha256.txt`). Bản trước khi sửa: `evidence/A/before/`.

## 0. Upstream đã dùng
- Nền hiện tại của overlay: Mangayomi **v0.9.7+125** (`src/mangayomi`, `src/BASE_VERSION.txt`).
- Upstream mới nhất: **v0.9.95+128** (Release 01/11/2026). Bằng chứng `evidence/A/upstream_mangayomi_main.txt` (job `a056_upstream`, 22:23).
  Mã nguồn tag v0.9.95: `src/mangayomi-0.9.95` (phiên điều phối tải) và `D:\A.I Project\yh\upstream-0.9.95` (A tải, zip SHA256 C71103DC788DD8E86FEBEC3C6163B12295B719AD8CB139288434D62899EB0FE1).
- Shell Linux và container của A không tới được github.com (proxy 403); mọi lần tải đều chạy bằng job trên máy Windows.
- Tệp v0.9.95 đã đọc và dùng làm mẫu: `lib/modules/main_view/nav_groups.dart`, `nav_actions.dart`, `widgets/nav_group_switcher.dart`, `widgets/nav_group_swipe.dart`,
  `lib/modules/widgets/side_swipe_detector.dart`, `main_screen.dart`. **Không** đưa vào: gói `packages/shiori` (33 tệp Dart), thanh điều hướng nổi, trình phát làm lại, tracker trên máy, thay đổi lưu trữ thư viện/Isar 3.4.1.

## A1 — U13 "Thư Viện (Library)"
- Yêu cầu: gộp Truyện Tranh, Phim & Điện Ảnh, Tiểu Thuyết, Google Play Books thành một mục; TV chỉ Phim & Điện Ảnh.
- Cách làm (theo nhóm điều hướng của v0.9.95, mở rộng thêm Play Books): giữ nguyên 4 route và 4 nhánh StatefulShell (không mất trạng thái, liên kết cũ vẫn chạy); thanh dưới/thanh bên chỉ còn một đích "Thư Viện" (`l10n.library`), mở thư viện vừa xem; phía trên nội dung có dải tab con; vuốt ngang để sang thư viện kế (vuốt quá trang danh mục đầu/cuối mới tính, như upstream).
- Tệp mới: `lib/yomihub/library/library_hub.dart` (quy tắc thuần Dart), `library_hub_bar.dart` (dải tab, InkWell nhận tiêu điểm D-pad), `side_swipe.dart` (chuyển từ `side_swipe_detector.dart` v0.9.95, sửa để cây widget không đổi khi bật/tắt).
- Tệp sửa: `lib/modules/main_view/main_screen.dart` — import (dòng 4–8), trạng thái + `_hubTab` (sau `isLibSwitch`), khối tính `dest` trong `build` (thay khối `uniqueSwitch`/`mergeLibraryNavMobile`), `shellChild` (dải tab + vuốt), xử lý chạm ở thanh dưới và `_TabletLayout._onDestinationTapped`, thêm đích `kLibraryHubNav`/`kActivityNav` trong hai hàm dựng đích.
- Giữ: công tắc Bật/Tắt tính năng (mục tắt → ẩn tab; tắt hết → không có mục Thư Viện), thứ tự theo "Sắp xếp điều hướng", huy hiệu Cập nhật/Duyệt, Liquid Glass của thanh dưới/thanh bên, D-pad (TV chỉ một thư viện nên không hiện dải tab; tự chuyển về Phim & Điện Ảnh nếu đang ở thư viện bị ẩn).
- Thay đổi hành vi cần biết: công tắc upstream "Gộp thư viện trên di động" (`mergeLibraryNavMobile`) nay không còn tác dụng (Thư Viện luôn gộp).
- Công cụ: python (đọc-sửa-ghi), job `a056_t01`/`t03` (dart analyze, flutter test).
- Kết quả: `evidence/A/a056_t03.test.log` — 34/34 đạt (20 ca A1: quy tắc, widget, D-pad, màn hẹp 320 px, vuốt ngang). **Chưa** chạy trên thiết bị/giả lập; `MainScreen` chưa có kiểm thử widget riêng (chỉ biên dịch + phân tích).

## A2 — U12 giao diện mới Mangayomi + chuyển Cũ ↔ Mới
- Cài đặt › Giao diện › "Giao diện ứng dụng": **Cũ** (mặc định, kể cả khi nâng cấp/khôi phục sao lưu cũ) / **Mới**. Lưu ở YomiPrefs khóa `uiStyle` → nằm trong sao lưu (`YomiPrefs.dump()`); đổi là áp dụng ngay (MainScreen nghe `YomiPrefs.changes`).
- "Mới" hiện gồm phần điều hướng của v0.9.95: Cập nhật + Lịch sử gộp thành "Hoạt động" (cần cả hai đang hiện; chạm đúp để đọc/xem tiếp), tab Lịch sử trở lại thanh điều hướng, bộ chọn nhóm dạng viên. "Cũ": Lịch sử chỉ trong Thêm (quy tắc 0.4.3), dải tab gạch chân.
- **Giới hạn (nói rõ):** đây chưa phải toàn bộ giao diện Shiori của v0.9.95. Shiori là một gói thiết kế riêng + viết lại hầu hết màn hình trên nền 0.9.95; đưa vào sau một công tắc đòi hỏi chuyển nền overlay (839 tệp) từ 0.9.7 lên 0.9.95, kéo theo thay đổi lưu trữ thư viện. Cần chủ dự án quyết định làm thành một đợt riêng.
- Tệp mới: `lib/yomihub/ui/ui_style.dart`. Tệp sửa: `lib/modules/more/settings/appearance/appearance_screen.dart` (import + `YomiUiStyleTile` trước `LiquidGlassSettings`), 18 tệp `assets/yomihub_i18n/*.json` (6 khóa mới ghi nối cuối tệp, mỗi tệp 1558 → 1564 khóa).
- Kết quả: 7 ca A2 đạt (mặc định, lưu/sao lưu/khôi phục, điều hướng Cũ/Mới, đổi không khởi động lại, đủ 18 ngôn ngữ). Splash 5 giây và Liquid Glass không bị sửa.

## A3 — U5 Mangayomi Project + Kotatsu Project
Thông tin kho lấy bằng job `a056_k3` (`evidence/A/A3_kotatsu_projects.txt`, 22:48).

| Dự án | Giấy phép · trạng thái | Đã tích hợp trong YomiHub | Chưa tích hợp · lý do |
| --- | --- | --- | --- |
| kodjodevf/mangayomi | Apache-2.0 · đang phát triển (0.9.95) | Nền 0.9.7 + overlay; điều hướng nhóm, vuốt ngang (0.5.6) | Giao diện Shiori, trình phát mới, tracker trên máy, lưu trữ mới của 0.9.95 — cần chuyển nền |
| kodjodevf/M-Extension-Server | MPL-2.0 · hoạt động | Có (`lib/services/m_extension_server.dart`, màn hình cài đặt, Windows kèm Java) | Chưa đối chiếu bản đẩy 01/11/2026 |
| Schnitzel5/ApkBridge | Apache-2.0 · hoạt động | Có (`lib/yomihub/mes/yomi_mes.dart`, màn hình Extension Server) | — |
| Schnitzel5/mangayomi-custom-buttons | MIT | Có (nút tùy chỉnh trình phát, có trong sao lưu) | Bộ nút mẫu của kho chưa nhập sẵn |
| Schnitzel5/mangayomi-server | MIT · **đã lưu trữ, ghi DEPRECATED** | Có máy khách đồng bộ (`lib/services/sync_server.dart`) | Máy chủ đã ngừng phát triển — không mở rộng |
| KotatsuApp/kotatsu-parsers | GPL-3.0 · đã lưu trữ | Có: thư viện Kotlin nhúng, cầu nối 127.0.0.1:47350 (Android, Windows qua JVM) | iOS/macOS/Linux: không có JVM/dex |
| Shebyyy/kotatsu-multi-parsers | không ghi giấy phép · hoạt động | Có: nạp jar/dex fork (`KotatsuBridge.addFork`) | Chỉ Android (dex); Windows dùng Kotatsu-Redo |
| KotatsuApp/kotatsu-syncserver | GPL-3.0 · đã lưu trữ | **Chưa** | Cần tài khoản + máy chủ để thử; mã định danh truyện của Kotatsu là băm riêng của parsers nên ghi ngược có thể làm hỏng dữ liệu người dùng; chưa có máy chủ thử → không viết khi không kiểm chứng được |
| KotatsuApp/plugin-sdk | GPL-3.0 · đã lưu trữ | **Chưa** | SDK cho plugin APK Android của Kotatsu (ContentProvider); khác kiến trúc tiện ích của YomiHub; chỉ Android |
| KotatsuApp/subsampling-scale-image-view | Apache-2.0 · đã lưu trữ | **Không áp dụng** | Thư viện View Android (AAR); trình đọc YomiHub là Flutter (extended_image/photo_view) |

**Sửa lỗi "Cầu nối Kotatsu chưa chạy"** (log 31/10/2026 09:56 và 09:57, `IncompleteMessage`):
- Nguyên nhân: `JsExtensionService._init` gọi `KotatsuBridge.ensureStarted()` không chờ; `_started` vẫn true khi máy chủ nội bộ đã chết; `YomiKotatsu.start()` thoát sớm khi `server != null` dù socket đã đóng. Tiện ích JS thử 3 lần trong ~2,4 giây rồi báo lỗi.
- Sửa: `lib/yomihub/kotatsu/kotatsu_bridge.dart` (`isBridgeUrl`, `ensureAlive` có ping `/kotatsu/ping`, tin 15 giây, gộp lời gọi đồng thời, `markDead`);
  `lib/eval/javascript/http.dart` (`_toHttpResponse`: yêu cầu tới cầu nối chờ `ensureAlive`; lỗi kết nối → khởi động lại, ghi Nhật ký, gửi lại một lần);
  `android/.../YomiKotatsu.kt` `start()` (thay máy chủ không còn `isAlive`).
- Kết quả: 6 ca A3 đạt (`a056_t03.test.log`). **Chưa kiểm:** phần Kotlin chưa biên dịch (cần dựng APK); chưa thử trên thiết bị.
- Các lỗi Kotatsu khác trong log (404 khi tìm ở MimiHentai/YuriNeko, "No value for img" ở Làng Geek, tên miền nhentaiworld/nettruyen đổi) là lỗi phía trang nguồn/parsers upstream — không sửa trong đợt này.

## A4 — U10 Isar libmdbx + Android 6.0
- **Android 6.0 (minSdk 23): KHÔNG ĐẠT — chưa chạy lại trong đợt này.** Điều kiện chặn không đổi so với 0.4.3 mục D: vẫn `isar_community` / `isar_community_flutter_libs` **3.3.2** (`evidence/A/A4_env_probe.txt`), `minSdkVersion yhMinSdk = 24`.
  Thử thật cần vá engine Flutter và bộ đệm Gradle dùng chung (quy trình `audit-0.4.3/compat23`), không an toàn khi B và C đang dựng gói phát hành trên cùng máy. AVD `OOS_Android6_API23` có sẵn.
  Hướng tiếp: sau Mốc 2, thử `isar_community_flutter_libs` 3.4.1 (bản upstream 0.9.95 dùng) trên AVD API 23 bằng quy trình compat23; nếu vẫn `MDBX_INCOMPATIBLE` thì phải tự biên dịch libisar.
- **Hàng đợi ghi Isar:** log chỉ có **1** lần "async write transaction already in progress" (01/11/2026 11:42, trước bản sửa 0.5.5). Rà mã: trong overlay không còn `writeTxn`/`writeTxnSync` gọi thẳng; mọi tệp upstream có ghi CSDL đều đã bị overlay thay; còn 2 chỗ `writeTxnSyncDirect` (`changed_part_repository.dart` dòng 63, 126 — đồng bộ máy chủ).
  Điểm yếu còn lại (chưa sửa, cần quyết định): `DbWriteQueue.run` coi lời gọi là "lồng nhau" theo giá trị Zone; tác vụ không chờ (timer, stream) sinh ra trong một tác vụ sẽ mang theo Zone đó và về sau **bỏ qua hàng đợi**. Đề xuất: gắn mã thông báo theo từng tác vụ; chưa áp dụng vì có nguy cơ khóa chết và không có lỗi mới nào trong log sau 0.5.5.
  `db_write_queue.dart` không bị sửa.

## Kiểm thử và phân tích (job trên Windows, bản dựng `D:\yh\build\mangayomi`)
| Lần | Nội dung | Kết quả | Log |
| --- | --- | --- | --- |
| a056_t01 22:44 | analyze tệp A + `yh_056_a_test.dart` | 0 lỗi; 29/29 | `evidence/A/a056_t01.*.log` |
| a056_t02 22:50 | `dart analyze lib` + toàn bộ `flutter test` | **0 lỗi**, 166 cảnh báo, 51 info; **615 đạt, 2 trượt** | `evidence/A/a056_t02.*.log` |
| a056_t03 22:53 | analyze thư mục A sửa + `yh_056_a_test.dart` (có vuốt ngang) | 0 lỗi (4 cảnh báo + 1 info có từ trước); **34/34** | `evidence/A/a056_t03.*.log` |

2 ca trượt ở t02 không thuộc tệp của A: `yh_054_test.dart` và `yh_055_test.dart` còn so chuỗi User-Agent với 0.5.4/0.5.5 trong khi B đã nâng lên 0.5.6. A không sửa (tệp kiểm thử của đợt trước; cần phiên điều phối quyết định).
`dart analyze lib` toàn bộ chạy trước khi thêm `side_swipe.dart`; sau đó chỉ phân tích lại các thư mục A sửa. Bản dựng Windows (`buildwin`) chưa được đồng bộ tệp của A.

---
# Bổ sung 2026-11-11 05:15 — quyết định của chủ dự án và sửa hàng đợi ghi Isar

## Quyết định (00_PLAN mục 6, 11/11/2026 04:55–05:05)
- **Phương án 1:** 0.5.6 giữ nền Mangayomi **v0.9.7**; giao diện "Mới" là phần điều hướng kiểu v0.9.95 đã làm ở A1/A2. **Không** chuyển nền sang v0.9.95 (Shiori, lưu trữ mới) trong đợt này — để bản sau.
- **kotatsu-syncserver:** không tích hợp trong 0.5.6 — không có máy chủ/tài khoản thử, kho đã lưu trữ, ghi ngược có nguy cơ hỏng dữ liệu (bảng A3 giữ nguyên).
- **Android 6.0:** chỉ thử lại sau khi REVIEW_CLAUDE.md có "MỐC 2 DUYỆT"; trước đó giữ minSdk 24.
- Hai ca `yh_054`/`yh_055` so phiên bản: Antigravity đã nới (đã duyệt) — A không sửa.

## A4b — Hàng đợi ghi Isar: tác vụ không chờ bỏ qua hàng đợi
- **Lỗi:** `DbWriteQueue.run` nhận biết lời gọi lồng nhau bằng giá trị Zone (`Zone.current[key] == this`). Việc mà một tác vụ để lại không chờ (timer, `then`, stream) thừa hưởng Zone đó; sau khi tác vụ đã xong, lời gọi ghi của nó vẫn bị coi là "lồng" nên chạy ngay, chen vào giữa giao dịch của tác vụ khác → "async write transaction already in progress".
- **Sửa — `overlay/lib/repositories/db_write_queue.dart`** (lớp `DbWriteQueue`, dòng 21–139; phần `YhSafeIsarWrite` không đổi):
  1. Mỗi tác vụ có một `_QueueTask` riêng đặt vào Zone, cờ `active` chỉ bật trong lúc thân tác vụ chạy. Chỉ lời gọi từ tác vụ **đang chạy** mới đi thẳng (`isInsideActiveTask`); việc bị bỏ lại sau khi tác vụ kết thúc phải xếp hàng.
  2. Chống khóa chết: tham số `stallTimeout` (mặc định 120 giây). Tác vụ chờ quá hạn (trường hợp tác vụ đang chạy lại chờ chính tác vụ đang xếp hàng) được chạy ngoài lượt, ghi cảnh báo `[Isar Queue]` vào Nhật ký, `stallCount` tăng. Nếu lúc đó còn giao dịch mở thật thì Isar trả lỗi rõ ràng (sau 10 lần thử lại) thay vì treo.
     Mỗi tác vụ chỉ chạy đúng một lần (cờ `started`), bộ hẹn giờ bị hủy khi tác vụ bắt đầu.
- **Giới hạn phát hiện thêm (của Isar, không phải của hàng đợi):** việc được khởi tạo *bên trong* callback giao dịch (`writeTxn(() async { ... })`) mang theo Zone giao dịch của chính Isar; ghi về sau bị Isar từ chối "does not support nesting transactions" — lỗi rõ, không treo. Việc như vậy phải khởi tạo ngoài callback. Đã có ca kiểm thử ghi lại hành vi này.
- **Tác động:** ghi trong lúc một giao dịch dài hơn 120 giây (ví dụ khôi phục sao lưu rất lớn) sẽ được chạy ngoài lượt và có thể nhận lỗi tranh chấp của Isar, thay vì chờ tiếp như 0.5.5. Chưa đo trên thiết bị.
- **Kiểm thử mới** trong `overlay/test/yh_056_a_test.dart`, nhóm "A4 / U10 – DbWriteQueue" (7 ca, mỗi ca có `Timeout` 20 giây + `.timeout(5 giây)` trên từng lần chờ):
  ghi lồng 3 tầng · việc bị bỏ lại phải chạy sau tác vụ kế · việc bị bỏ lại khi tác vụ còn chạy thì đi thẳng · FIFO + cô lập lỗi · **vòng chờ được giải sau stallTimeout (200 ms trong test)** · tác vụ dài không bị quấy trước hạn · Isar thật (async + sync + lồng + bị bỏ lại, giao dịch giữ 500 ms).
- **Công cụ:** python đọc-sửa-ghi; job trên Windows có BUILD_LOCK.
- **Kết quả:**
  | Job | Nội dung | Kết quả | Log (`evidence/A/`) |
  | --- | --- | --- | --- |
  | a056_t04 05:00 | biên dịch lần đầu | **TRƯỢT** — test trùng tên `Size` (dart:ffi / dart:ui); đã sửa import | `a056_t04_failed_compile.*.log` |
  | a056_t05 05:06 | analyze + 4 tệp test | analyze 0 vấn đề; **2 trượt**: ca Isar thật của A (giới hạn Zone của Isar nêu trên → sửa lại ca kiểm thử cho đúng kịch bản, thêm ca ghi nhận giới hạn) và `yh_049` (xem dưới) | `a056_t05.*.log` |
  | a056_t06 05:09 | analyze `lib/repositories` + test A, 054, 055 | **No issues found**; **56/56** (yh_056_a: 41/41) | `a056_t06.*.log` |
  | a056_t07 05:12 | `dart analyze lib` + toàn bộ `flutter test` | **0 lỗi**, 166 cảnh báo, 52 info; **644 đạt, 1 trượt** | `a056_t07.*.log` |
- **Ca còn trượt (không thuộc A):** `yh_049_test.dart` "every tr() text has an English translation" — 13 chuỗi của phần khác chưa có trong `en.json`: "Kiểm Tra Cập Nhật", "Đang kiểm tra cập nhật tiện ích…", "Đã kiểm tra cập nhật tiện ích hoàn tất.", "Lỗi kiểm tra cập nhật: {p0}", "Số lượng bản sao lưu", "Không giới hạn", "{p0} bản gần nhất (tự động dọn dẹp các bản cũ hơn)", "{p0} bản gần nhất", "Tối ưu hóa cấu hình cho AMD Ryzen / CPU đa luồng", câu mô tả Direct3D 11, "Tối ưu". Chuỗi của A không nằm trong danh sách.
- Chưa có: thử trên thiết bị/giả lập; đo với khôi phục sao lưu lớn. `buildwin` chưa đồng bộ tệp của A (danh sách nay 29 tệp).
