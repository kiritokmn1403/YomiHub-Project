# YomiHub 0.6.0 – 19/11/2026

## Tính năng mới
- **Sao Lưu Lên Google Drive**: mục riêng trong Dữ liệu & Bộ nhớ, biểu tượng logo Google; đăng nhập bằng tài khoản Google rồi sao lưu/khôi phục qua Google Drive.
- **Trình duyệt › Savior – "Quét mã trang tìm link video"**: tìm link m3u8/mp4 nằm sẵn trong mã trang, cấu hình trình phát (jwplayer `sources`, `og:video`, link bị thoát ký tự) trước khi bấm phát; không có link trực tiếp thì đề nghị mở khung trình phát nhúng để quét tiếp.
- **Short Video**: nhận diện thêm Kwai, RedGifs, xFree, Kwiky, Facebook Reels, Snapchat Spotlight, Moj.
- **Gợi ý kho tiện ích**: thêm Salmanbappi (97 nguồn anime – Aniyomi) và Secozzi (Jellyfin, Stremio, Torbox).
- **Từ Mangayomi v0.9.96**: thư viện mở lại đúng danh mục đã rời đi; bấm thẻ thể loại › "Tìm trong nguồn" nay tìm đúng thể loại đó; dòng cuối thư viện không còn bị thanh điều hướng nổi che.
- **Bản APK Android 6.0 chạy trên Android 7.0+**: hộp thoại có nút "Tải bản APK thường" mở thẳng trang phát hành mới nhất.

## Sửa lỗi (theo nhật ký 16–19/11/2026)
- Trang **Cập nhật** treo 2,7 giây (khung hình 2,8 giây): chương của từng mục được nạp ở nền thay vì truy vấn đồng bộ từng dòng trên luồng giao diện; huy hiệu số lượng chỉ còn đếm.
- Giật lúc mở app trên máy RAM lớn: tín hiệu "thiếu bộ nhớ" của hệ thống ngay sau khi mở không còn xóa ảnh bìa đang hiển thị.
- **Bộ lọc tiện ích**: một tùy chọn hỏng không còn làm mất cả danh sách bộ lọc (từ Mangayomi v0.9.96).
- **Tiện ích JavaScript**: yêu cầu PUT/DELETE/PATCH trước đây bị gửi thành POST.
- **CBHentai** đổi URL qua lại liên tục (hentaicube.xyz ↔ 2tencb.pro): thử thách Cloudflare không còn bị coi là máy chủ hỏng.
- **Ảnh nguồn Kotatsu** (vd. SAYHENTAI) qua cổng nội bộ trả trang lỗi HTML thay cho ảnh: giữ Referer của nguồn, thử lại, báo lỗi rõ; nhật ký ghi máy chủ ảnh thật thay vì 127.0.0.1.
- **Tor**: thông báo "chưa kết nối được sau 90 giây" khi Tor vẫn đang tự thử ở nền nay là cảnh báo, không còn là lỗi.
- **Health Connect**: nhắc thiếu quyền "Chánh niệm" tối đa 1 lần/ngày thay vì mỗi lần mở app.
- Thông báo "đang dùng APK Android 6.0" không hiện lại sau 0.5.7 (khóa phiên bản cũ) – đã sửa.

## Nền tảng
- Android 7.0+ (APK thường), Android 6.0 (APK android6 riêng), Android TV (YumiHub Android TV – không có Comic, Novel, Google Play Books, Booru), Windows 10/11 x64 (.appxbundle, Setup.exe, bản portable .zip).
