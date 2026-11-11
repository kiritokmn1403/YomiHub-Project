# Phần A — Claude Fable 5.2: các yêu cầu phức tạp

Đọc `00_PLAN.md` (đặc biệt mục 2 và mục 4), `AGENTS.md`, toàn bộ `TECHNICAL_UPDATE_NOTES.md`. Nguồn: `overlay/` (duy nhất).
Bản dựng: Android `D:\A.I Project\yh\build\mangayomi`, Windows `D:\A.I Project\yh\buildwin\mangayomi`. Mã nền upstream: `src/mangayomi`.

## A1. U13 — mục "Thư Viện (Library)"
Gộp Truyện Tranh, Phim & Điện Ảnh, Tiểu Thuyết, Google Play Books ở màn hình chính thành một mục Thư Viện có tab con, theo cách Mangayomi làm.
Giữ: công tắc Bật/Tắt tính năng (mục bị tắt thì ẩn tab), thứ tự/huy hiệu, điều hướng D-pad trên TV, bản TV chỉ Phim & Điện Ảnh. Có kiểm thử widget.

## A2. U12 — giao diện mới Mangayomi + chuyển đổi cũ ↔ mới
Đối chiếu bản Mangayomi mới nhất với `src/mangayomi`; đưa phần giao diện mới vào overlay sau một cài đặt "Giao diện ứng dụng: Cũ / Mới"
(Cài đặt › Giao diện), đổi ngay không cần khởi động lại, lưu vào cài đặt, có trong sao lưu. Mặc định: giao diện cũ cho người nâng cấp.
Mọi chuỗi mới có bản dịch đủ các ngôn ngữ app hỗ trợ. Giữ Liquid Glass, splash 5 giây, bố cục đồng nhất Android ↔ Windows.

## A3. U5 — Mangayomi Project + Kotatsu Project
Mangayomi: M-Extension-Server, ApkBridge, custom-buttons, mangayomi-server. Kotatsu: kotatsu-parsers, plugin-sdk, kotatsu-syncserver,
subsampling-scale-image-view, kotatsu-multi-parsers. Lập bảng dự án · phần đã tích hợp · chưa tích hợp · lý do (kiến trúc, giấy phép, nền tảng).
Ưu tiên: đồng bộ qua kotatsu-syncserver, sửa "Cầu nối Kotatsu chưa chạy" và lỗi Kotatsu trong log.

## A4. U10 — Isar libmdbx + Android 6.0
Thử minSdk 23 thật: dựng, cài trên AVD API 23, mở app, đọc/ghi thư viện. Đạt → giữ; không đạt → ghi KHÔNG ĐẠT kèm log và nguyên nhân, không đổi tên gói cho giống đạt.
Kiểm lại hàng đợi ghi Isar (`db_write_queue.dart`) với lỗi "async write transaction already in progress" khi lưu vị trí tập (log ngày 30/10–10/11).

## Quy tắc
CLAIMS trước khi sửa tệp có sẵn; BUILD_LOCK trước tác vụ nặng; không chạy lệnh ghi của git; không sửa trực tiếp `TECHNICAL_UPDATE_NOTES.md`;
không ghi mật khẩu/token. Chỉ ghi ĐẠT khi có bằng chứng trong `audit-0.5.6/evidence/A/`. Đọc `REVIEW_CLAUDE.md` trước và sau mỗi mục.
