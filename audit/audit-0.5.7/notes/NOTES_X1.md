# NOTES_X1 – phiên chat riêng (Claude Fable sáng 14/11, Claude Opus 5.5 từ 15:36)

Giờ Asia/Saigon. Chỉ sửa `overlay/`; bản gốc ở `audit-0.5.7/backup/src_0571/`. Công cụ: `audit-0.5.7/tools/{ed.py,p1_patch*.py,p5_patch.py,t4_patch.py,i18n_merge.py}` (đọc-sửa-ghi có kiểm số lần khớp).

## 1. FC35 Health Connect (lượt 1 của gói P5)
- Nguyên nhân: `recordReadingMinutes/recordWatchingMinutes/startContinuousSession` không được gọi ở đâu → thống kê luôn 0, không gửi Health Connect, nhắc 20-20-20 không chạy.
- Sửa:
  - `lib/yomihub/health/health_connect_service.dart`: `recordSeconds(seconds, watching:)` cộng dồn giây lẻ thành phút, bỏ báo cáo ≤0 hoặc >12 h; `startEyeCareWatch` (đồng hồ 1 phút toàn app, tính khi app ở nền trước và màn hình là `/mangaReaderView`, `/novelReaderView`, `/animePlayerView`), `eyeCareTick` (2 phút liền rời trình đọc = nghỉ); `_onActivityTime` chỉ còn đồng bộ, không đếm phút liên tục nữa (tránh đếm hai lần).
  - `lib/modules/manga/reader/mixins/chapter_controller_mixin.dart` `setHistoryUpdate`: sau kiểm tra ẩn danh, gọi `recordSeconds(elapsedSeconds, watching: itemType == anime)`.
  - `lib/main.dart`: khởi động `startEyeCareWatch` (màn hình lấy từ `CrashReports.screen`), nhắc bằng `botToast` 8 s.
- Test `test/yh_057_p5_test.dart` 33/33 (cùng yh_049, yh_057_s1_logs) – `jobs/done/x1_p5_test1.log` 10:53. Analyze: 1 info có sẵn (`main.dart` curly braces).
- Chưa: thử trên Android 14+ thật (ghi phiên Chánh niệm), Windows.

## 2. Lỗi còn sót trong logs 7 (gói T4, PROGRESS gọi là P7)
| Dòng log | Trước | Sau |
|---|---|---|
| Kavita "OPDS URL required / Please configure…" (ERROR + stack) | ERROR | `isSetupError` → WARNING một lần/nguồn "(needs setup)" |
| HTTP 530 (HentaiVN.plus, Phim Nhựa), "HTTP 0 <url>" (Rổ Phim, AVSub) | ERROR + stack | lỗi trang/mạng: WARNING 1 dòng + gợi ý 52x/530 |
| Tiện ích tên "(Ngừng hoạt động)" | ERROR | INFO một lần/phiên, nền bỏ qua 30 phút |
| "MiMi" `abstract method … typeParametersSerializers()` | ERROR + stack | WARNING + gợi ý cập nhật / dùng APK thường |
| Aidoku `SourceError: missing result` khi tìm kiếm, NHentai `Bad state: No element` khi tìm | ERROR + stack | INFO "nguồn không có kết quả" |
| `SourceError: JSON parse error`, CSRF, "No value for img", "End of input", 405 | ERROR + stack | WARNING 1 dòng |
- Tệp: `lib/yomihub/extensions/ext_errors.dart`, `lib/services/isolate_service.dart` (thứ tự nhánh: ngừng hoạt động → cấu hình → mạng → không tương thích → không kết quả → dữ liệu nguồn → ERROR+stack).
- Bản android6 trên máy mới: log 13–14/11 có build-id `d6bf8bd5…` = `D:\yh\build23\symbols` (APK android6) nhưng chạy trên máy Android đời mới. Thêm `kIsA6Build` (`--dart-define=IS_A6_BUILD=true`, `lib/utils/platform_utils.dart`) và `lib/yomihub/a6/a6_notice.dart` (WARNING mỗi lần mở + toast một lần/phiên bản khi SDK ≥ 24). **Script dựng android6 0.5.7 phải truyền cờ này.**
- Test `test/yh_057_t4_test.dart` 35/35 (cùng yh_049, yh_052) – `jobs/done/x1_t4_test1.log` 10:58. Analyze: 2 warning có sẵn (`isolate_service.dart:235`), 1 info.
- Giải mã stack: `flutter symbolize` báo "Cannot locate isolate instructions section" với cả hai thư mục symbols; Opus lượt trước đã giải bằng llvm-symbolizer (xem PROGRESS).

## 3. Gói P1 (U3, U4, FC37, FC38) – lượt 1
Xem `NOTES_P1.md` (P1 lượt 2 đã ghi đủ cả lượt 1).

## 4. i18n
Khóa mới ở `notes/i18n_{P1,P5,T4}.json`, đã gộp vào 18 tệp (nối cuối, không đổi khóa cũ). 15:19 `yh_049` 15/15 đạt với 1598 khóa.

## 5. Nhật ký phiên Opus (từ 15:36)
- 15:36 lưu mốc vào `coordination/PROGRESS_0571.md`.
- 15:38 dev APK 0.5.7/2050 đã cài Note 9 (Success 15:33); ảnh của job z057_dev_apk hỏng (PS5) → job `x2_shot` chụp lại bằng `cmd /c`. Job `x2_fulltest` chạy toàn bộ test sau gộp i18n.
