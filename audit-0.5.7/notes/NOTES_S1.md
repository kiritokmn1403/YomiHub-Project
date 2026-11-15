# NOTES_S1 - YomiHub 0.5.7: lỗi/cảnh báo không phải mạng trong `logs 7.txt` (12-14/11/2026)

Tác nhân S1 (Claude Sonnet). Bắt đầu 09:50, xong mã + test 10:01 (Asia/Saigon, 14/11/2026).

## Việc làm theo từng mục

### 1. `Invalid repository index` (x.noz.one/yuzono/cursed/index.pb)
- Nguyên nhân (log 12/11 15:02:43-47): `ExtensionStoreService.fetchStore` hết 25 s -> trả `null` (đã ghi WARNING "Không tải được kho ... TimeoutException"); sau đó `fetch_sources_list.dart` (nhánh dự phòng JSON, cũ dòng ~63-75) tải lại, vì URL kết thúc `.pb` nên gán `decoded = null` và ném `FormatException('Invalid repository index')` -> ERROR + stack. Tức là KHÔNG phải định dạng proto sai: chỉ mục không tải được, rồi lỗi thứ hai gây hiểu nhầm. Không có HTML/gzip thật trong log; phát hiện HTML được thêm để phòng.
- Sửa `lib/services/extension_store_service.dart`: lớp `StoreFailure` + `lastFailure[url]`; `looksLikeHtml()` / `htmlMessage()` (nhận Cloudflare "Just a moment", trang HTML chuyển hướng/nhà mạng chặn -> WARNING tiếng Việt rõ ràng, không còn FormatException); `_getIndex()` thử lại 1 lần với thời gian chờ dài hơn (25 s -> 60 s, `indexTimeout`/`indexRetryTimeout`), không thử lại khi lỗi DNS; ghi lý do cho HTTP != 200 / protobuf hỏng. Chuyển hướng: client Dart đã tự theo (tối đa 15); không đổi.
- Sửa `lib/services/fetch_sources_list.dart`: với URL `.pb` (hoặc fetchStore đã ghi lỗi) không chạy nhánh JSON dự phòng nữa mà ném `YomiLoggedError(FormatException('Không đọc được kho <url>: <lý do>'))`, chỉ ghi WARNING một lần nếu fetchStore chưa ghi.
- Thử lại cả chuỗi bằng test có MockClient (xem mục Test).

### 2. Kiểm tra cập nhật (MediaFire/Drive timeout)
- Đã đối chiếu `Project YomiHub.json` sheet "Website Update Apps": đủ 8 nguồn đang cấu hình trong `multi_source_update.dart` (GitHub repo + /releases qua API `releases/latest`, dự phòng trang `releases/latest`; 3 thư mục Drive `16PCPorl...`, `1EF_4MJQ...`, `1vLWPTfF...`; 3 thư mục MediaFire `kg0wfu3lpbc98`, `8s2tlcukdmw6x`, `jmgm4xds8kamx`). `yh_049` đã kiểm hằng số.
- Nguyên nhân: các nguồn chạy TUẦN TỰ, mỗi nguồn chờ tới 75 s, không thử lại; lỗi thứ cấp ghi WARNING ngay.
- Sửa `lib/yomihub/update/multi_source_update.dart`: cả 7 lượt kiểm chạy song song (`_runSource`), mỗi nguồn thử lại 1 lần (chờ 2 s, bỏ qua nếu "Failed host lookup"), không bao giờ ném lỗi; kết quả vẫn chọn theo đúng thứ tự trong sheet và GitHub (nguồn I) được trả ngay khi có bản mới mà không đợi nguồn phụ; WARNING chỉ ghi sau khi thử lại cũng lỗi ("(đã thử lại 1 lần)"); client chỉ đóng khi mọi nguồn xong.
- Giới hạn: `drive_update.dart` vẫn có 3 lần thử bên trong (không đổi); nếu GitHub báo "đã mới nhất" thì kết quả vẫn phải đợi các nguồn phụ (tối đa ~2x75 s) vì còn có thể có bản mới hơn ở Drive/MediaFire.

### 3. Bộ lọc VinaHentai
- Nguyên nhân: `filter_refresh.dart` `_load` chỉ coi "danh sách rỗng" là hợp lệ từ lần hỏi thứ 2; còn `fetchFilterListDalvik` nuốt mọi ngoại lệ trả `null` nên log chỉ có "không trả về danh sách bộ lọc (sau 3 lần thử)" mà không có lý do.
- Sửa `fetch_sources_list.dart`: biến `yomiLastFilterFetchError` ghi lý do ngoại lệ. `filter_refresh.dart`: trả lời rỗng -> `noFilters` ngay, KHÔNG thử lại; timeout/ngoại lệ ghi lý do vào `lastError`. `filter_loader.dart`: rỗng -> INFO "không có bộ lọc" (logOnce); lỗi thật -> WARNING kèm lý do (ngoại lệ hoặc "hết thời gian chờ 20 giây").
- Chưa có test tự động cho nhánh này (cần YomiMes/Dalvik); chỉ kiểm bằng `dart analyze`.

### 4. Phân loại `NHentai ... Bad state: No element` + cập nhật tiện ích DocTruyen3Q
- `lib/utils/log/logger.dart` `classifyMessage`: tin bắt đầu `Extension "` bỏ qua quy tắc "Lỗi Ứng Dụng" (Bad state...), vẫn xét 404/403/mạng, còn lại gắn `[Lỗi Nguồn]`. Lỗi `FlutterError: Bad state` thật vẫn là Lỗi Ứng Dụng (test).
- `fetch_sources_list.dart` `_logUpdateFailure`: dòng đầu nay có `• lỗi: <dòng đầu của ngoại lệ>`; timeout/lỗi mạng ghi mức WARNING (trước là ERROR); lỗi khác vẫn ERROR + stack. (Thực ra log cũ có lý do ở dòng 3 "Lỗi: TimeoutException after 25 s" - đã bổ sung ở dòng đầu để lọc/đọc nhanh.)

### 5. Treo giao diện 2.6/2.8 giây
- `perf_watchdog.dart` đã có `route` (do MainScreen đặt, chỉ khi ở khung chính) nhưng thông điệp treo KHÔNG ghi màn hình. Thêm `YomiPerf.currentScreen` (ưu tiên `CrashReports.screen` do `CrashRouteObserver` cập nhật cả trang đẩy như trình đọc/chi tiết, dùng phân đoạn đầu của đường dẫn nên không lộ id; dự phòng `route`) và ghi ` • màn hình: ...` cạnh ` • đang chạy: ...` (đã có). `lib/services/crash_report.dart`: thêm getter `screen`.
- Không tối ưu hiệu năng; nguyên nhân treo thật vẫn chưa biết (cần log mới có màn hình).

### 6. 164 dòng `Image/network load failed`
- Phân tích log: mỗi host chỉ 1 lần/phiên (đã có logOnce) nhưng có 19 phiên x nhiều host = 164 dòng INFO (chỉ ghi khi bật "Enable logs").
- Thêm `lib/utils/log/log_rate_limiter.dart` (`LogBurstAggregator`): dòng đầu cửa sổ 1 phút ghi ngay (nguyên văn), các lần sau chỉ đếm theo host, hết cửa sổ ghi 1 dòng tổng "thêm N lần tương tự trong 1 phút qua từ M máy chủ (host x n, ...)". `main.dart` dùng nó thay `logOnce`. Không mất sự kiện (test kiểm tổng = 164).
- Khác với yêu cầu gốc "mỗi host 1 lần/phút": chọn gộp theo mọi host vì dedupe theo host đã có sẵn và không giảm được số dòng.

## Tệp đã sửa (đường dẫn trong overlay/)
lib/services/extension_store_service.dart, lib/services/fetch_sources_list.dart, lib/services/crash_report.dart, lib/yomihub/update/multi_source_update.dart, lib/yomihub/filters/filter_loader.dart, lib/yomihub/filters/filter_refresh.dart, lib/utils/log/logger.dart, lib/utils/log/log_rate_limiter.dart (mới), lib/yomihub/perf/perf_watchdog.dart, lib/main.dart; test mới: test/yh_057_s1_store_test.dart, test/yh_057_s1_logs_test.dart. Không thêm chuỗi `tr()` nên không đổi 18 tệp i18n. Bản gốc ở `audit-0.5.7/backup/src_0571/<đường dẫn>` (tạo mới, chưa có từ trước). Không đụng `custom_draggable_tabbar.dart`, Kotatsu, VPN/Tor, Cloudflare, `m_client.dart`, `http.dart`.

## Công cụ / lệnh
device_bash (python đọc-sửa-ghi), job `jobs/pending_fast/s1_test1.ps1` (Sync-Overlay + test + `dart analyze`) và `s1_test2.ps1` (chạy lại test, không bắt đầu ra). Lượt 1 chạy `$c = Run-Tests` nên đầu ra test bị nuốt (chỉ thấy `TEST EXIT 0`); lượt 2 mới có số đếm.

## Kết quả
- `jobs/done/s1_test2.log`: `00:15 +44: All tests passed!` / `### TEST EXIT 0` cho yh_057_s1_store (7 test), yh_057_s1_logs (11 test), yh_049, yh_054 (tổng 44).
- `jobs/done/s1_test1.log`: `dart analyze` các tệp đã sửa: 4 info (không lỗi, không cảnh báo): `main.dart:125` curly_braces, `extension_store_service.dart:205` curly_braces (dòng gốc), `perf_watchdog.dart` 2 import thừa (gốc); `### EXIT 0 2026-11-14T10:00:10`.
- Chỉ đã chạy trong bản dựng `D:\yh\build\mangayomi`; CHƯA chạy toàn bộ `flutter test`, CHƯA dựng APK, CHƯA thử trên thiết bị.

## Còn lại / rủi ro
- Nhánh bộ lọc (#3) và `_logUpdateFailure` (#4) chưa có test; cần xác nhận khi chạy thật.
- Cloudflare thật trên x.noz.one chưa xác định (log chỉ có timeout): nếu máy chủ chặn IP Việt/Tor, cần VPN/WARP hoặc kho thay thế.
- `http.dart`/`m_client.dart` (F1): nếu muốn theo chuyển hướng thủ công hoặc phát hiện Cloudflare ở lớp client thì F1 làm; S1 không cần thay đổi ở đó.
- Nếu muốn dòng "đã thử lại" cho cả Drive nội bộ cần sửa `drive_update.dart` (chưa làm).
