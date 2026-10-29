# Kiểm tra trực tiếp YomiHub 0.3.9

Ngày 25/10/2026. Chỉ ghi thao tác đã quan sát; không suy rộng thành toàn bộ tính năng đạt.

| Nền tảng/bản | Ca kiểm tra | Kết quả |
| --- | --- | --- |
| Windows cuối 0.3.9+31 | Khởi động với dữ liệu sẵn có | Mở được, tiến trình phản hồi; dữ liệu lịch sử hiện có còn xuất hiện. |
| Windows cuối | Lưới Lịch sử | Tên nội dung hiện dưới thẻ sau sửa; một số ảnh bìa vẫn lỗi tải mạng. |
| Windows cuối | Thông báo gợi ý hợp nhất | Có nút đóng; tự biến mất khi tiếp tục điều hướng, không còn che lâu như trước. |
| Windows cuối | EPUB thử 3 chương | Mở lại chương 2 đã lưu, hiển thị nội dung. |
| Windows cuối | Mục lục EPUB 3 | Hiện đúng Chapter 1/2/3; chọn Chapter 3 mở đúng chương. |
| Windows cuối | Nút quay lại EPUB | Trở về Ebook & PDF, không phải đóng cả ứng dụng. |
| Windows cuối | PDF thử 3 trang | Kết xuất trong WebView2 bên trong ứng dụng, hiển thị 1 of 3. |
| Windows cuối | Cuộn và zoom PDF | Cuộn sang trang 2; nhấn + phóng to nội dung. |
| Android trước nâng cấp | Metadata | 0.3.8, code 4030; chưa cài bản cuối tại mốc này. |
| Android QA riêng | Nâng cấp giữ dữ liệu thử | Cài 0.3.8, lưu chương 2, nâng bằng `-r` thành công lên 0.3.9/code 4031. Không lặp onboarding. |
| Android 0.3.9 | EPUB sau nâng cấp | Còn trong Đọc gần đây, mở đúng Chapter 2/33,3%; mục lục hiện Chapter 1/2/3, chuyển chương 3 được. |
| Android 0.3.9 | Thêm dấu trang | **Lỗi đã tái hiện:** báo thêm thành công nhưng danh sách rỗng trong phiên đọc; thoát/mở lại thì có Chapter 3 • 0%. Đang sửa làm mới giao diện. |
| Windows sau sửa dấu trang | Thêm dấu trang và mở tab ngay | **Đạt:** thông báo thêm thành công; tab hiển thị Chapter 3 • 0% trong cùng phiên đọc, chọn dấu trang trở lại đúng chương. |
| Windows sau sửa dấu trang | Lưu vị trí cuộn EPUB | **Đạt:** đóng ở đoạn 13/chương 3/79,8%, mở lại vẫn ở đúng đoạn và tiến độ. |
| Windows sau sửa dấu trang | Phiên bản hiển thị | Trang Giới thiệu: Beta (0.3.9). |

Lỗi công cụ Windows `foreground window did not report a process id` đã được khắc phục bằng khởi tạo lại phiên công cụ; không phải kết luận ứng dụng crash.

Video đã ghi: `output/yomihub-039-reader-check.mp4` (gốc) và `output/yomihub-039-reader-check-playback.mp4` (bản khung hình đều để phát lại). Ghi cả lỗi dấu trang, không phải chứng nhận toàn bộ chức năng đạt.

Sau sửa dấu trang: `tests-bookmark-after-r2.log` đạt 3/3 test, Windows dựng lại thành công (`build-windows-bookmark.log`), Android đang dựng lại (`build-android-bookmark.log`). Đây là bằng chứng tự động và biên dịch; chưa thay đổi kết quả lỗi quan sát trên bản cũ trong bảng.

Tìm kiếm EPUB Windows đã mở được hộp nhập, nhưng công cụ nhập liệu báo `element ... is not available in cached app state` kể cả sau khởi tạo lại. Không ghi nhận tìm kiếm đạt hoặc kết luận lỗi ứng dụng từ lỗi công cụ này.

Chưa kiểm tra trực tiếp đầy đủ: resume/đổi server/chất lượng video; hợp nhất/tách trên repo thực; tracker và Play Books có tài khoản; chia sẻ hai thiết bị; Health Connect native; toàn bộ website/extension; UI RTL và mọi ngôn ngữ.

## Mốc bổ sung 26/10/2026 — kết quả mới thay cho trạng thái đang chờ ở trên

- Android bản sau sửa dấu trang đã cài nâng cấp thành công; giữ dấu trang cũ, dấu trang Chapter 1 mới hiện ngay và mở đúng chương. Video `output/yomihub-039-bookmark-fixed.mp4`.
- Android tìm `paragraph 30` trả ba chương, chọn kết quả Chapter 2 mở đúng chương.
- Android nhập video cục bộ được; decoder mặc định kẹt 00:00. Chọn phần mềm trong QA thì phát đến 02:59,9 nhưng điều khiển giao diện không phản hồi bình thường. Chưa đạt kiểm tra trình phát/resume. Giữ cả hai video lỗi; không thay đổi mặc định bản phát hành.
- Chốt đóng gói nhanh theo yêu cầu người dùng; không áp dụng bản vá mpv chưa xác minh. Những hàng lỗi cũ được giữ để ghi lịch sử, không phải kết quả hiện tại của dấu trang.

## Trình phát — kiểm tra rút gọn bản snapshot, 26/10/2026

- Đính chính: XML lấy sau khi controls tự ẩn không chứng minh nút bị treo. PNG cũ có controls hiện. Trên APK QA, hiện controls, đợi hoạt ảnh 0,5 giây rồi bấm pause: đứng yên 01:07.400 ở hai ảnh liên tiếp; Back trở lại chi tiết.
- Mở lại cùng video trên APK QA quay về đầu, chế độ ẩn danh tắt. Overlay thêm guard bỏ lưu trước khi Player.open để bảo vệ tiến độ trong khởi tạo/lifecycle. Chờ kiểm tra APK cuối; không đánh dấu resume đạt từ test đơn vị.
- Snapshot và lưu tiến độ: 9/9 test đạt; kiểm tra mã hai tệp 0 error/0 warning/1 info. Android cuối đã dựng đủ ba ABI, metadata và chữ ký đạt. Windows đang dựng lại sau khôi phục C++ wrapper thiếu trong thư mục ephemeral.
- Kết quả cuối: Windows dựng lại thành công, ZIP/Setup đã kiểm chứng. APK cuối nâng cấp thành công và giữ video thử; pause 00:41.400 và Back đạt, mở lại vẫn từ đầu. Guard khởi tạo chưa giải quyết resume. Video `output/yomihub-039-player-final-check.mp4` ghi nguyên diễn biến; chưa chứng nhận toàn bộ trình phát hoạt động đúng. Hash năm gói/CRC ZIP/chữ ký ba APK đã đạt.
