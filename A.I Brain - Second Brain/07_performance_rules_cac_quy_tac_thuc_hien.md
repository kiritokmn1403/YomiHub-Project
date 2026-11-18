# Các quy tắc thực hiện (bắt buộc)

## Mã & dữ liệu
1. Chỉ sửa trong `overlay/`; đồng bộ sang bản dựng bằng script, không sửa bản sao rồi bỏ quên overlay.
2. Giữ dữ liệu người dùng và bản gốc: không thao tác phá hủy thư viện thật; kiểm thử sao lưu/hợp nhất bằng dữ liệu tạm hoặc đổi tên thư mục dữ liệu.
3. Không chạy script dọn/mirror trước khi kiểm tra phạm vi xóa/ghi đè. Thư mục cần xóa thì chuyển vào `_to_delete/`.
4. Sau khi tác nhân bị ngắt giữa chừng: chạy analyze + test các tệp đã đổi trước khi dựng.
5. Mỗi khẳng định tính năng (README, trang chủ, mô tả cửa hàng) phải kiểm bằng grep mã (`overlay/lib`, Kotlin) trước khi đăng.

## Bảo mật
6. Không ghi mật khẩu, token, Client Secret, keystore (`yomihub-release.jks`, `keystore-password.txt`), tài khoản trong sheet Excel vào ghi chú, log chia sẻ, Second Brain hay GitHub. `secrets/`, `logs/`, `*.log`, `output/`, `evidence/` đã bị `.gitignore`.
7. Không nhập mật khẩu/mã xác minh, không giải CAPTCHA/Cloudflare thay chủ dự án; không tự tạo tài khoản – chủ dự án tự đăng ký/đăng nhập.
8. Không bổ sung liên kết công cụ tấn công (hack Wi-Fi, WPS, AMSI bypass…) vào "Dự án GitHub đã sử dụng".

## Phát hành & công khai
9. Đăng công khai (GitHub Release, push repo tiện ích, gửi duyệt APKPure, bật Pages) cần chủ dự án xác nhận rõ trong lượt chat; chủ dự án đã cho phép tự push tiến độ (commit có chọn lọc) lên GitHub.
10. Ảnh công khai không chứa bìa 18+ hoặc nội dung có bản quyền.
11. Xếp hạng nội dung trung thực (YomiHub: Mature 17+ vì người dùng có thể thêm nguồn 18+; `showNSFW` mặc định tắt).

## Ghi chép & báo cáo
12. Đọc toàn bộ Second Brain (00–12) + `AGENTS.md` + `TECHNICAL_UPDATE_NOTES.md` trước khi làm.
13. Sau mỗi bước ghi tiến độ; sau mỗi đợt cập nhật ghi chú kỹ thuật (không xóa lịch sử thất bại) và Second Brain đúng tệp.
14. Không chấp nhận "ĐẠT" khi chưa có bằng chứng thật (xem 05).
15. Báo cáo chủ dự án bằng tiếng Việt, mỗi bước 1 câu; nói rõ việc chủ dự án cần tự làm.
16. Tắt lịch hẹn/tiến trình nền khi xong việc (lịch nhắc, autosave, theo dõi của Antigravity).
17. Cuối mỗi phiên: thêm mục vào nhật ký phiên (12) và làm bước bàn giao (11).
