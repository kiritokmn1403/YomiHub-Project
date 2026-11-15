# NOTES_PB – Feature Check 36: Google Play Books (đối chiếu 21 ảnh) – 14/11/2026 (Asia/Saigon)

## Nguồn ảnh
Sheet "Google Play Books Screenshot" (xl/drawings/drawing1.xml, ảnh image1..image21; image22 thuộc sheet Merge, bỏ). Giải nén: `audit-0.5.7/evidence/playbooks_ref/x/`, bản thu nhỏ `pb_01..pb_21(.jpg|_sN.jpg)`. Đã tự mở xem từng ảnh (ảnh cao 2,3,19,21 cắt thành đoạn).
Ảnh mẫu là ứng dụng Android Google Play Sách THẬT (tiếng Việt, nền tối); ứng dụng của ta nhúng WebView trang web Play Books, nên nội dung trong trang (thẻ sách, bộ lọc, giá, trạng thái đọc) do Google tạo, không sửa được.

## Bảng đối chiếu
| Ảnh | Nội dung mẫu | Thành phần trong mã | Kết quả |
|---|---|---|---|
| 1, 2, 3 | Trang chủ: ô tìm kiếm "Tìm kiếm trên Play Sách" + avatar; băng chuyền "đang đọc" (Đã hoàn tất 40%); tab Sách điện tử / Sách nói; mục "Sách bán chạy nhất →"; thanh dưới 4 mục | Ô tìm kiếm pill (tr 'Tìm kiếm trên Play Sách') khớp; tab Sách điện tử/Sách nói TRƯỚC: không có (chip Ebook/Sách nói...) -> ĐÃ SỬA thêm dải 2 tab ở Trang chủ; nút avatar: thay bằng nút tune+menu (giữ vì cần Cài đặt/Giao diện máy tính) | Khớp sau sửa (avatar khác có chủ ý) |
| 1-3, 4-21 | Thanh dưới: Trang chủ, Thư viện, Danh sách yêu thích, Cửa hàng | TRƯỚC: Trang chủ, Thư viện, Cửa hàng, Sách nói | ĐÃ SỬA: đổi thứ tự/nhãn/biểu tượng (bookmark_add) theo mẫu; Sách nói chuyển vào tab Trang chủ |
| 4 | Thư viện > Sách của bạn: chip lọc (tune, Gần đây, Định dạng, Trạng thái), danh sách sách, tải xuống | Nội dung trang web Google | Do trang Google; mở URL /books |
| 5, 9 | Giá sách: danh sách giá, "N cuốn sách", nút "Tạo mới" | Trang web | Do trang Google |
| 6, 7, 8 | Chọn nhiều sách: Thêm vào kệ sách / Xoá cuốn đã tải xuống / Đánh dấu là đã đọc xong | Ứng dụng gốc; web khác | Không có tương đương, ngoài phạm vi WebView |
| 10 | Tạo giá sách: "Tên giá sách 0/50" | Trang web | Do trang Google |
| 11 | Loạt sách (rỗng: "Sách trong Bộ") | Trang web | Do trang Google |
| 12-16 | Sắp có: chip Trạng thái/Giá/Xoá tất cả, sheet Bộ lọc, Trạng thái, Giá (tối đa 400.000 đ) | Trang web | Do trang Google |
| 17, 18, 20, 19 | Danh sách yêu thích (Mới thêm gần đây, Định dạng, Sắp xếp, Bộ lọc: Ngôn ngữ, Tuổi, Điểm xếp hạng) | TRƯỚC: không có mục; SAU: mục điều hướng -> /store/wishlist (URL chưa xác minh trên máy) | Đã thêm lối vào |
| 21 | Mới duyệt xem gần đây (rỗng, nút Khám phá) | Trang web | Do trang Google |
| Cài đặt | Không có ảnh mẫu cho cài đặt | playbooks_settings_screen.dart (18 dự án) | Không đổi |

## Tệp sửa
- overlay/lib/yomihub/playbooks/play_books_screen.dart: đổi thanh điều hướng (4 mục theo mẫu), thêm `_wishlistUrl`, `_homeTab`, `_homeTabs()` (2 tab Sách điện tử | Sách nói trên Trang chủ), dải chip chỉ còn ở tab Cửa hàng, chiều cao AppBar động. Sao lưu: audit-0.5.7/backup/src_0571/lib/yomihub/playbooks/play_books_screen.dart.
- audit-0.5.7/notes/i18n_PB.json (2 khóa mới: "Sách điện tử", "Danh sách yêu thích") đã gộp bằng i18n_merge.py PB vào 18 tệp assets/yomihub_i18n/*.json.
- Không đụng Android TV (Play Books vẫn bị gỡ) và playbooks_toggle.dart.

## Tiến độ / còn lại
(cập nhật bên dưới)

### Kết quả (job pb_a, jobs/done/pb_a.log, 16:49)
- flutter analyze lib/yomihub/playbooks + test: 0 error; 1 info cũ (withOpacity deprecated, play_books_screen.dart:134, có từ trước, không phải warning mới). EXIT 1 chỉ do info đó.
- Test: yh_057_pb_test (4) + yh_049_test (14): "+19: All tests passed!" (gồm kiểm mọi tr() có bản dịch tiếng Anh).
- Chưa thử trên máy/thiết bị thật: giao diện mới (tab Trang chủ, mục Danh sách yêu thích) chưa chạy trên AVD; URL https://play.google.com/store/wishlist chưa xác minh sẽ mở đúng danh sách yêu thích của Play Sách.

### Còn lại
- Thử trên thiết bị: bố cục AppBar 70/108 px, tab Sách điện tử|Sách nói, mục Danh sách yêu thích.
- Avatar tài khoản (ảnh mẫu) không làm được trong WebView; giữ nút Cài đặt + menu.
- Màn chọn nhiều sách / tạo giá sách / bộ lọc là của ứng dụng gốc, ngoài phạm vi WebView.
- Có thể đổi withOpacity -> withValues (info cũ).
