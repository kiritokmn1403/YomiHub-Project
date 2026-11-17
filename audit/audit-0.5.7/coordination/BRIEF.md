# YomiHub 0.5.7 — Bản giao việc chung cho tác nhân (Claude Opus điều phối, 14/11/2026)

## Bắt buộc
- Đọc `AGENTS.md`, mục 1 + các mục 0.5.6/0.5.6.1 cuối `TECHNICAL_UPDATE_NOTES.md`, `audit-0.5.7/00_DECISIONS.md`.
- Mọi sửa đổi mã nguồn chỉ trong `overlay/` (Flutter app, gốc là Mangayomi). Thư mục dựng `D:\yh\build\mangayomi` (Android), `D:\yh\buildwin\mangayomi` (Windows), `D:\yh\build23\mangayomi` (Android 6) là bản sao.
- Trước khi sửa tệp: chép bản gốc vào `audit-0.5.7/backup/src_0571/<đường dẫn tương đối>`.
- Chỉ sửa các tệp thuộc phần việc được giao. Cần sửa tệp ngoài phạm vi → ghi vào ghi chú của mình, không tự sửa.
- Sửa bằng lệnh đọc-sửa-ghi (python/sed) trên máy người dùng (device_bash), KHÔNG chép nội dung tệp từ đầu ra công cụ.
- Không ghi mật khẩu/token (Anime47 trong Excel đã che). Không xóa tệp người dùng. Không git commit/push (Opus làm khi phát hành).
- Không nói "ĐẠT" nếu chưa chạy thật. Bằng chứng ảnh phải tự mở xem.
- Chuỗi giao diện mới dùng `tr('...')` tiếng Việt và PHẢI có bản dịch trong cả 18 tệp `overlay/assets/yomihub_i18n/*.json` (test `yh_049` kiểm).

## Đường dẫn
- device_bash: `$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project` (= `D:\Claude A.I` = `D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project` trên Windows).
- Đầu vào: `audit-0.5.7/input/` (Excel, JSON đã che, `logs 7.txt`). Stack đã giải mã: `audit-0.5.7/stacks/`.
- device_bash là Linux VM, không có Flutter. Muốn chạy Flutter/adb → tạo job PowerShell.

## Chạy job trên Windows
- Ghi tệp `.ps1` (CRLF) vào `jobs/pending_fast/` (việc ngắn: test) hoặc `jobs/pending/` (việc dài: dựng). Dòng 1: `# timeout: <phút>`. Đặt tên có tiền tố riêng của bạn (vd `f1_`, `s1_`).
- Thư viện: `. "D:\Claude A.I\jobs\q057_lib.ps1"` rồi `Sync-Overlay @("lib\...dart","test\...dart")` (chép overlay → D:\yh\build\mangayomi, có sao lưu) và `Run-Tests @("test/xxx_test.dart")`.
- Log: `jobs/done/<tên>.log` (thường UTF-16LE: đọc bằng `iconv -f utf-16le -t utf-8`). Hai runner chạy tuần tự từng job; đừng chiếm runner quá lâu.
- Test mới đặt tên `test/yh_057_<phần>_test.dart`.

## Ghi chú kết quả
- Mỗi tác nhân ghi `audit-0.5.7/notes/NOTES_<mã>.md`: yêu cầu, nguyên nhân, tệp sửa (đường dẫn + mô tả dòng sửa), lệnh/công cụ đã dùng, kết quả test (trích log), việc còn lại, ngày giờ (Asia/Saigon).

## Bổ sung đợt 2 (14/11/2026 10:40) — chạy song song P1–P7
- Test CHỈ đặt vào `jobs/pending_fast/` (một runner, chạy tuần tự → không hai `flutter test` cùng lúc trong `D:\yh\build\mangayomi`). `jobs/pending/` dành cho việc dựng dài (chỉ P7, và chỉ khi Opus cho phép).
- Mỗi job chỉ Sync-Overlay tệp của chính gói mình + test của mình. Giữ job ngắn (≤ 30 phút).
- Chuỗi `tr()` mới: KHÔNG sửa 18 tệp `assets/yomihub_i18n/*.json`; ghi `audit-0.5.7/notes/i18n_<gói>.json` dạng `{"<khóa tiếng Việt>": {"en": "...", "<mã ngôn ngữ>": "..."}}` cho đủ 18 ngôn ngữ (xem tên tệp trong thư mục i18n). P8 gộp. Test có gọi yh_049 sẽ trượt cho tới khi P8 gộp — ghi rõ, không coi là lỗi của gói.
- Đã xong ở đợt 1 (không sửa lại nếu không cần, nếu phải sửa thì ghi chú): `custom_draggable_tabbar.dart` (Opus), các tệp F1 (`m_client.dart`, `lib/eval/javascript/http.dart`, `lib/eval/mihon/service.dart`, `lib/yomihub/vpn/*`, `lib/yomihub/cloudflare/*`, `cloudscraper.dart`, `savior.dart`, `player_net.dart`, `lib/yomihub/net/loopback_bypass.dart`), các tệp S1 (`extension_store_service.dart`, `fetch_sources_list.dart`, `crash_report.dart`, `multi_source_update.dart`, `lib/yomihub/filters/*`, `logger.dart`, `log_rate_limiter.dart`, `perf_watchdog.dart`, `main.dart`).
- Bảng yêu cầu + gói việc: `audit-0.5.7/coordination/MATRIX_0571.md`.
