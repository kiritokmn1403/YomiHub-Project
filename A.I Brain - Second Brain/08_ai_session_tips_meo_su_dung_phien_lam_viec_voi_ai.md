# Mẹo sử dụng phiên làm việc với AI (Claude)

## Bắt đầu / tiếp tục phiên
- Phiên mới: đưa cho Claude tệp log mới + 2 tệp Excel, câu lệnh "kiểm tra phiên trước làm tới đâu và tiếp tục". Claude đọc Second Brain, ghi chú kỹ thuật, `main_build_status`, `jobs/done`, NOTES của Antigravity để dựng lại trạng thái.
- Gắn thư mục máy cho phiên (Add folder): `D:\A.I Project`, `...YomiHub Project`, `yh`, `GitHub`, `Claude outputs`.

## Quyền
- Quyền điều khiển máy (computer use) hết hạn sau ~30 phút không dùng hoặc khi app desktop cập nhật → nói "xin cấp lại đầy đủ quyền" để Claude xin lại (Antigravity, Cốc Cốc, VS Code, Android Studio, File Explorer, YomiHub, clipboard, phím hệ thống). IDE/Explorer chỉ được cấp mức bấm.
- Trình duyệt tích hợp có hồ sơ đăng nhập riêng; trang chặn bot (APKPure) → dùng Cốc Cốc qua computer use. Khi cần đăng nhập: bấm Ctrl+Shift+B để hiện khung trình duyệt rồi tự đăng nhập.
- Đăng công khai: trả lời bằng câu xác nhận rõ (vd. "Phát hành v0.5.9 lên GitHub Release và đẩy Kiritokmn Extension Repo") – câu chung chung có thể bị bộ phân loại an toàn chặn.

## Hạn mức & thời gian
- Nhiều tác nhân song song làm cạn hạn mức nhanh (7 tác nhân hết hạn mức 5 giờ trong ~1 giờ) → tối đa 2–3; giao bớt cho Antigravity.
- Chờ bản dựng/tải lên dài: dùng lịch hẹn tự kiểm tra (send_later) thay vì hỏi liên tục; chủ dự án có thể yêu cầu nhịp (vd. Claude 10 phút, Antigravity 40 giây).
- Lịch hẹn gắn máy: đổi được giờ/tên/bật-tắt, KHÔNG đổi được nội dung lời nhắc từ chat. Tắt lịch khi xong.
- Lệnh chờ dài (sleep) bị ngắt khi chủ dự án nhắn – không hỏng gì, Claude kiểm tra lại trạng thái.
- Ngắt (interrupt) lệnh của Claude cũng dừng tác nhân nền; sau đó cần kiểm tra lại.

## Cách giao việc hiệu quả
- Một tin nhắn = một mục tiêu rõ ("Phát hành…", "Đưa link vào About…", "Tắt nhắc hẹn").
- Muốn thấy quá trình: yêu cầu làm trực tiếp trong chat, mỗi bước 1 câu; mở `PROGRESS_*.md`/`NOTES_*.md` trong VS Code.
- Muốn lưu thường xuyên: bật autosave (3 phút) – nhớ dừng bằng `jobs/STOP_AUTOSAVE`.
- Cuối đợt: yêu cầu "cập nhật kiến thức" → Claude cập nhật ghi chú kỹ thuật + Second Brain + push.
