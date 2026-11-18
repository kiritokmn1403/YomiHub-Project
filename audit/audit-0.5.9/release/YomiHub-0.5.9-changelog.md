# YomiHub 0.5.9 – 18/11/2026

## Tính năng mới
- **Đăng nhập bằng tài khoản Google để sao lưu Google Drive**: để trống Client ID là dùng cấu hình sẵn của YomiHub. Windows: mở trình duyệt, đăng nhập rồi tự quay lại app (OAuth loopback + PKCE). Android/Android TV: mở google.com/device và nhập mã. Chỉ dùng quyền `drive.file` (chỉ thấy thư mục sao lưu do YomiHub tạo), hiển thị email tài khoản đã đăng nhập.
- **Nhật ký ứng dụng**: mỗi dòng ghi kèm phiên bản ứng dụng, thiết bị và hệ điều hành (`[YH 0.5.9 (52) • Hãng Model, Android x (SDK n)]`).
- **Tạo bản sao lưu**: thêm mục chọn "Booru App (lịch sử tìm kiếm, yêu thích, cài đặt)".
- **Tor nhớ cầu nối chạy được**: nếu lần trước cầu nối đã chọn (vd. snowflake) bị kẹt và cầu nối khác (obfs4) kết nối được, lần mở sau thử cầu nối đó trước (nhớ 3 ngày).
- **Cloudflare**: khi WebView và tiện ích đi hai đường mạng khác nhau (VPN/proxy vs đi thẳng), YomiHub giải thử thách trên cùng đường mạng với tiện ích để cookie `cf_clearance` dùng được.
- **Giới thiệu › Dự án GitHub đã sử dụng**: bổ sung 258 liên kết / 32 dự án từ danh sách Project GitHub.
- **Bản "YumiHub Android TV"** không có Comic, Novel, Google Play Books, Booru.

## Sửa lỗi (theo nhật ký 16–18/11/2026)
- Trình cập nhật trong app cài nhầm **APK Android 6.0** lên máy Android 7.0+ (log: Android 16 chạy bản android6 → hàng loạt tiện ích Keiyoushi/Project Nox lỗi `typeParametersSerializers`). Nay chọn bản theo phiên bản Android + kiến trúc CPU + TV. *Máy đang chạy bản android6 trên Android 7+ hãy cài lại bản APK thường 0.5.9 một lần.*
- Mở trình đọc truyện báo lỗi "object is unsendable – IsarImpl" (cập nhật chi tiết truyện thất bại).
- Giao diện treo 2,6–3,1 giây ở Thư viện khi lọc/sắp xếp (thư viện lớn ~88.000 chương): thay việc nạp toàn bộ chương trên luồng giao diện bằng truy vấn chỉ mục.
- Kiểm tra cập nhật báo lỗi DNS (`api.github.com`) khi Tor/VPN còn đang kết nối và ghi lỗi trùng 2–3 lần: nay tự thử lại sau 30 giây, gộp các lần kiểm tra đồng thời.
- Trình phát video: ghi nhật ký khi thoát chậm/không thoát được và buộc đóng nếu bị kẹt.

## Tiện ích (Kiritokmn Extension Repo)
- Cập nhật Anime47, FikFap, Phimmoi, AVSub – AnimeVietsub, SexVietTop, AnimeVN, Pornhub (Shorts) theo các lỗi 404/TLS trong nhật ký.
- Sửa nhãn ngôn ngữ/18+: HentaiVN, Mimimoe, NetTruyen18, VinaHentai bật NSFW; E-Hentai đổi ngôn ngữ sang toàn cầu.

## Khác
- README mới chỉ giới thiệu ứng dụng, nút Download dẫn tới bản phát hành mới nhất; trang chủ + chính sách quyền riêng tư trên GitHub Pages (dùng cho đăng nhập Google).

## Nền tảng
- Android 7.0+ (APK thường), Android 6.0 (APK android6 riêng), Android TV (YumiHub Android TV), Windows 10/11 x64 (.appxbundle, Setup.exe, bản portable .zip).
