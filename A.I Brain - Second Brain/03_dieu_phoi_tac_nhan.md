# Điều phối tác nhân
- 7 tác nhân chạy song song (14/11/2026) làm cạn hạn mức 5 giờ trong ~1 giờ → tối đa 2–3 tác nhân/lượt; lưu tiến độ trước khi gần hết hạn mức.
- Giao tập tệp rời nhau; test chỉ qua `pending_fast` (tuần tự) để không có 2 `flutter test` cùng lúc trong một thư mục dựng.
- Bản dịch mới ghi vào `audit-<ver>/notes/i18n_<gói>.json`, một gói gộp cuối.
- Yêu cầu tác nhân viết `notes/NOTES_<gói>.md` từ đầu và cập nhật sau mỗi bước (tác nhân bị dừng giữa chừng không để lại ghi chú).
- Không chấp nhận "ĐẠT" khi chưa có log/ảnh thật; người kiểm phải tự mở ảnh.
- (15/11) Tác nhân bị cắt giữa chừng có thể để lại mã chưa biên dịch được (vd. thiếu import) → sau mỗi lần bị cắt, chạy analyze + test tệp đã đổi TRƯỚC khi dựng.
- (15/11) Chủ dự án muốn xem quá trình làm việc của tác nhân: mở `PROGRESS_*.md` + `NOTES_*.md` trong VS Code (job PowerShell `Start-Process Code.exe ...`), yêu cầu tác nhân ghi một dòng sau mỗi bước, chia việc 15–45 phút và báo kết quả sau mỗi phần.
- (15/11) Chờ bản dựng dài: dùng hẹn giờ tự kiểm tra (send_later) thay vì hỏi trạng thái liên tục.

## Bổ sung 15/11/2026 tối
- Chủ dự án muốn THẤY quá trình: làm trực tiếp trong chat (mỗi bước 1 câu tiếng Việt + kết quả), hạn chế Agent chạy ngầm.
- Khi máy ngủ: runner treo và cửa sổ console có thể kẹt "Select" (QuickEdit) → đóng cửa sổ treo, mở lại `3_run_jobs.bat`/`3b_run_fast_jobs.bat`, chạy job dọn khóa `BUILD_LOCK.txt`.
