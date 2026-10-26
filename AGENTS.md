# Hướng dẫn bắt buộc khi cập nhật YomiHub

Theo yêu cầu trực tiếp của chủ dự án ngày 25/10/2026:

1. **BẮT BUỘC đọc toàn bộ `TECHNICAL_UPDATE_NOTES.md` trước mỗi lần cập nhật**, sửa lỗi, thay đổi phiên bản, đồng bộ mã nguồn hoặc tạo bản phát hành.
2. Đọc mục trạng thái hiện tại và công việc còn lại trước khi thực hiện. Không coi thay đổi mã hoặc kiểm thử đơn vị thành công là bằng chứng đã kiểm tra toàn bộ tính năng.
3. Sau mỗi đợt làm việc, cập nhật chính file ghi chú này: yêu cầu, hướng xử lý, nguyên nhân lỗi, tệp sửa, kiểm thử, kết quả thực tế, giới hạn và bước tiếp theo. Không xóa lịch sử thất bại.
4. `overlay` là nguồn các thay đổi riêng của YomiHub; các thư mục dựng Android/Windows là bản sao phục vụ biên dịch. Không chỉ sửa bản sao rồi bỏ quên `overlay`.
5. Giữ dữ liệu người dùng và bản gốc. Không chạy các script dọn hoặc sao chép dạng mirror trước khi kiểm tra chính xác phạm vi xóa/ghi đè.
6. Không đưa thông tin đăng nhập, khóa ký, token hoặc mật khẩu vào ghi chú, log chia sẻ hay bản phát hành.

File bắt buộc: [TECHNICAL_UPDATE_NOTES.md](TECHNICAL_UPDATE_NOTES.md).
