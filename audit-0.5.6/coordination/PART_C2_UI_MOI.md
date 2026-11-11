# Phần C2 — Antigravity IDE: Giao diện Mới (U12) — giao lúc 11/11/2026 10:02 theo yêu cầu chủ dự án

## Hiện trạng (Fable-A đã làm, đạt test)
- Công tắc "Giao diện ứng dụng: Cũ / Mới" ở Cài đặt › Giao diện (`lib/yomihub/ui/ui_style.dart`, `appearance_screen.dart`), mặc định Cũ, đổi ngay, lưu trong YomiPrefs (có trong sao lưu).
- "Mới" hiện chỉ có phần điều hướng kiểu v0.9.95: mục Thư Viện (tab con + vuốt ngang — `lib/yomihub/library/*`), Cập nhật + Lịch sử gộp thành "Hoạt động", bộ chọn dạng viên (`main_screen.dart`).
- Test: `test/yh_056_a_test.dart` (50/50). Đọc `audit-0.5.6/notes/NOTES_A.md` mục A1, A2.

## Việc của C2
Làm cho chế độ "Mới" mang ngôn ngữ thiết kế Shiori của Mangayomi **v0.9.95** (nguồn: `src/mangayomi-0.9.95`, gói `packages/shiori`, `lib/.../nav_groups.dart`):
1. Đối chiếu v0.9.95 với nền `src/mangayomi` (v0.9.7). Lập bảng trong `NOTES_C.md`: thành phần giao diện · tệp v0.9.95 · đã đưa / chưa · lý do.
2. Đưa phần **giao diện thuần** vào overlay, chỉ có hiệu lực khi `uiStyle == Mới`: thanh điều hướng nổi, chủ đề/màu/bo góc/khoảng cách, thẻ thư viện, thanh tiêu đề, chuyển cảnh. Ưu tiên các màn hình hay dùng: Thư Viện, Duyệt, Hoạt động, Thêm, Cài đặt.
   Mã mới đặt trong `overlay/lib/yomihub/ui/shiori/` (tệp mới). Nếu chép mã từ `packages/shiori` thì giữ ghi chú nguồn và giấy phép.
3. **Không** đưa thay đổi lưu trữ thư viện/Isar, mô hình dữ liệu, trình phát video mới, hay gói phụ thuộc mới nếu không bắt buộc (cần thêm gói thì ghi CHỜ để điều phối duyệt).
4. Chế độ "Cũ" phải giữ nguyên như 0.5.5. Đổi qua lại không cần khởi động lại, không mất trạng thái điều hướng.
5. Đồng nhất Android ↔ Windows; bản Android TV: nếu thành phần nào không hợp D-pad thì TV luôn dùng giao diện Cũ cho phần đó và ghi rõ.
6. Chuỗi mới: đủ 18 tệp `assets/yomihub_i18n/*.json` (chỉ nối khóa mới cuối tệp).
7. Test widget trong tệp mới `overlay/test/yh_056_c2_ui_test.dart`: công tắc Cũ/Mới, dựng được các màn hình chính ở cả hai chế độ, TV không vỡ bố cục.
8. `dart analyze lib` 0 lỗi + test qua (BUILD_LOCK). Sau Mốc 1: kiểm thử trong ứng dụng trên Windows, chụp ảnh **cả hai chế độ** từng màn hình + một video chuyển đổi Cũ ↔ Mới → `audit-0.5.6/evidence/C/ui_moi/`.

## Quy tắc
- Tệp do A làm (`main_screen.dart`, `appearance_screen.dart`, `ui_style.dart`, `lib/yomihub/library/*`) nay giao C2 — ghi CLAIMS trước khi sửa. Không sửa tệp B (ChatGPT) đang giữ trong CLAIMS.
- Ghi STATUS_C_ANTIGRAVITY.md khi bắt đầu/xong từng bước và ít nhất 30 phút/lần (mã mục: C2.1 … C2.8). Không commit/push.
- Nếu một bước quá lớn cho 0.5.6, làm phần cốt lõi (bước 2 cho Thư Viện + điều hướng + chủ đề) rồi ghi rõ phần còn lại.
