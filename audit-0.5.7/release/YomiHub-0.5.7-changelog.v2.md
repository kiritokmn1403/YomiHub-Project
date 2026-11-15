# YomiHub 0.5.7 (0.5.7+50)

> Ngày phát hành: `<<NGÀY PHÁT HÀNH>>` · Android 7.0+ (Điện thoại/Máy tính bảng và "YumiHub Android TV") · Android 6.0 (APK riêng) · Windows 10/11 x64

Giữ nền Mangayomi hiện tại; sửa lỗi trong nhật ký 12–14/11/2026 và làm tiếp các yêu cầu của sheet "YomiHub Update" / "Feature Check".

Mục nào chưa kiểm trên máy thật được ghi "(chưa kiểm trên máy thật)".

## Sửa lỗi từ nhật ký ứng dụng (logs 12–14/11/2026)
- Khi đóng bảng chọn có thanh tab (Thư viện, trình đọc), ứng dụng từng báo "Null check operator used on a null value" (khoảng 40 lần trong nhật ký). Đã sửa trong mã và có test; chưa kiểm lại trên máy thật.
- Tiện ích Kotatsu không còn bị đẩy vào `127.0.0.1:9` khi Tor đang khởi động, và cầu nối Kotatsu không còn tự khởi động lại làm hỏng các nguồn Kotatsu khác. Khi có nguy cơ rò IP, ứng dụng chặn và báo lý do bằng tiếng Việt. Kotatsu/IReader đi VPN theo từng tiện ích và trên Windows vẫn chưa hỗ trợ (chưa làm).
- Tor kẹt ở 45–50 % với cầu nối snowflake: trên Android, khi chọn cầu nối snowflake, obfs4 hoặc meek và Tor không tiến triển, ứng dụng tự thử cầu nối khác. Có công tắc "Tự đổi cầu nối khi Tor bị kẹt" (mặc định bật). Chế độ "Tự động" giữ nguyên; Windows chưa có. (chưa kiểm trên máy thật)
- Cloudflare "đã giải xong nhưng vẫn không tải được" (một trang CBHentai): chỉ coi là đã giải khi trình duyệt đã rời trang xác minh; gửi đúng dấu hiệu trình duyệt đã vượt xác minh. Chưa tái hiện được lỗi; nếu vẫn gặp, hãy dùng "Đổi URL" của nguồn. (chưa kiểm trên máy thật)
- Kho tiện ích `.pb` không tải được không còn báo "Invalid repository index" gây hiểu nhầm. Kho vẫn có thể không tải được nếu máy chủ kho chậm hoặc chặn. Kiểm tra cập nhật chạy song song các nguồn và thử lại 1 lần. (chưa chạy thật)
- Phân loại lại lỗi tiện ích: Kavita chưa cấu hình, HTTP 530/"HTTP 0" của trang đã chết, tiện ích "(Ngừng hoạt động)", nguồn Aidoku không có kết quả… không còn ghi ERROR kèm stack.
- Tiện ích "MiMi" báo lỗi `typeParametersSerializers()`: nay được ghi là cảnh báo kèm gợi ý. APK Android 6.0 cài trên máy Android 7.0+ được nhận ra và nhắc cài bản APK thường; đây có thể là nguyên nhân lỗi "MiMi" (chưa xác nhận).
- Gộp các dòng "Image/network load failed" lặp lại (nhật ký ghi 1 dòng đầu, các dòng sau gộp thành 1 dòng tổng mỗi phút); ghi tên màn hình khi giao diện bị treo. Nguyên nhân treo 2,6 s và 2,8 s chưa tìm được.
- Ghi cơ sở dữ liệu (Isar) có thể báo lỗi "async write transaction is already in progress" và văng khi máy tải nặng: đã sửa hàng đợi ghi. Đã kiểm bằng test Isar thật trên máy phát triển; chưa kiểm trên máy thật.
- Trình đọc ảnh trên Android dưới 11: khi bộ giải mã gốc không dùng được, ứng dụng dùng bộ giải mã dự phòng bằng Dart thay vì báo "Không tải được ảnh này". Có một dòng cảnh báo mỗi phiên khi dùng dự phòng. (chưa kiểm trên máy thật; dự phòng chậm hơn và không cắt viền trang)
- Chỉ APK Android 6.0: sửa nạp thư viện native cho QuickJS (tiện ích JavaScript) và bộ giải mã ảnh (trang CBZ), sửa đường dẫn ảnh Booru; thêm log chẩn đoán ảnh mạng. Trên AVD Android 6.0 (API 23) hai thư viện nạp được; chưa kiểm trên điện thoại Android 6 thật. (chưa kiểm trên máy thật)
- Windows: cửa sổ trắng (lỗi R21 từ 0.4.5). Nguyên nhân nằm ở khâu trình chiếu khung hình (swapchain kiểu bitblt gắn cửa sổ) trên một số máy, không phải ở mã ứng dụng: cả một ứng dụng Flutter tối giản cũng bị. Nay YomiHub dùng swapchain kiểu flip-model; đã kiểm trên máy Windows 11 (Intel Iris Xe) đang bị lỗi: giao diện hiện đủ, kể cả khi đổi kích thước. Mục "Chế độ GPU" trong Chẩn đoán Windows vẫn còn để thử khi cần. Trình cài đặt dọn tệp chương trình cũ của bản trước, không xóa dữ liệu người dùng.

## Tính năng và thay đổi
- Bật/Tắt tính năng: công tắc Google Play Books và Booru App nằm ngay trong "Bật/Tắt tính năng & Nguồn mở rộng".
- Hợp nhất: các công cụ hợp nhất gom về "Hợp Nhất Tiện Ích". Bộ hợp nhất có ô "Nguồn đọc" được nhớ theo từng bộ (chỉ hiện khi bộ có từ 2 nguồn); nút Đọc lần đầu và chương kế tiếp trong trình đọc mở theo nguồn đã chọn. Nút Tiếp tục và việc tải chương chưa theo nguồn đã chọn. (chưa kiểm trên máy thật)
- Giao diện Mới (Shiori): ô bìa và huy hiệu kiểu Shiori; ẩn ô "gộp thư viện" khi dùng giao diện Mới. Chuyển trang Shiori có hiệu lực sau khi khởi động lại; huy hiệu nguồn ở góc chưa đổi. Giao diện Cũ và Android TV không đổi. (chưa kiểm trên máy thật; chưa có ảnh so sánh)
- Trình phát: phát tiếp từ vị trí cũ ổn định hơn (giữ vị trí khi đổi server/chất lượng, mini player, ghi CSDL chậm). (chưa kiểm trên máy thật: VOD/HLS, đổi server)
- Trình phát: ghi nhật ký khi video không tải được hoặc không lưu được vị trí; sửa văng khi mở cửa sổ nổi (mini player) với tập chưa có mã định danh.
- Trình phát: nối module Nuvio (vuốt sáng/âm lượng, tua đúp, tỉ lệ PiP) và Zenshin (đồng bộ tracker khi xem đạt 85 %, một lần mỗi lượt phát); ba công tắc Nuvio, Zenshin, PiP nằm trong cài đặt. (chưa kiểm trên máy thật)
- Short Video: nhận diện thêm tiện ích ngoài; công tắc "Ép chế độ Short" theo nguồn, chỉ với nguồn anime; bộ lọc "Ẩn video ngắn" không còn bị bật ngược. (chưa kiểm trên máy thật với tiện ích ngoài)
- Trình đọc: phím tắt A/D/Space/Home/End (Yomikiru); thời gian đọc ước tính cho tiểu thuyết (Yomihon). Các tùy chọn giãn dòng và thời gian đọc mặc định tắt, bật trong cài đặt trình đọc. Chưa có chế độ dọc cho tiểu thuyết.
- Health Connect: thời lượng đọc/xem được gửi vào Health Connect; nhắc nghỉ mắt 20-20-20 khi đọc/xem liên tục. (chưa kiểm trên máy thật, đặc biệt Android 14+)
- Trình duyệt: công tắc "Bảo vệ dấu vân tay" nay hoạt động với trình duyệt Chromium/WebView (Canvas, Audio, WebGL, navigator). Chưa áp cho Firefox. (chưa kiểm trên trang thử thật)
- Google Play Books: thanh dưới Trang chủ / Thư viện / Danh sách yêu thích / Cửa hàng, tab Sách điện tử / Sách nói theo ảnh mẫu. Phần nội dung do trang Google tạo, không sửa được trong ứng dụng. (chưa kiểm trên máy thật)
- Nhật Ký Ứng Dụng ghi thêm lỗi của Web Scanner, chia sẻ LAN/Bluetooth, sao lưu Telegram (token được che), Booru, tải xuống chỉ qua Wi-Fi; nhận tệp LAN bị ngắt không còn để lại tệp hỏng. (chưa thử Telegram thật)
- Trình đọc truyện: ảnh trang không còn quay mãi khi máy chủ ảnh không trả lời: sau 30 giây báo lý do và cho tải lại; lỗi được ghi vào Nhật Ký Ứng Dụng.
- Nhãn thanh điều hướng giao diện Mới và Play Books không còn bị cắt / đè biểu tượng.
- Bản dịch: bổ sung chuỗi mới cho 18 ngôn ngữ.

## Đã biết / chưa kiểm
- Chưa kiểm trên thiết bị: phát tiếp video (VOD, HLS, đổi server), Short với tiện ích ngoài, PiP, vuốt sáng/âm lượng, tua đúp, Health Connect trên Android 14+, chia sẻ LAN/Bluetooth giữa 2 máy, Telegram thật, Booru từng site, Windows.
- Giao diện Shiori: chưa có ảnh thật Cũ/Mới; chuyển trang cần khởi động lại.
- Treo giao diện 2,6 s và 2,8 s: chưa tìm được nguyên nhân (đã thêm tên màn hình vào nhật ký).
- Android 6.0: kiểm lại ảnh Booru, CBZ và QuickJS trên máy thật chưa làm.
- Windows: Kotatsu/IReader đi VPN theo từng tiện ích chưa hỗ trợ.
- Nyora và GIF Viewer không tích hợp; Frank Yomik chưa làm; Gecko chưa áp chống dấu vân tay.
- Ảnh bìa trống trên máy thử Note 9: nguyên nhân chưa rõ.
- Kết quả kiểm thử thiết bị: <<KẾT QUẢ KIỂM THỬ THIẾT BỊ>>

## Số phiên bản
Phiên bản 0.5.7, versionCode cơ sở 50 (arm64-v8a 2050, armeabi-v7a 1050, x86_64 4050). Windows ProductVersion 0.5.7+50; FileVersion (chưa kiểm, sẽ kiểm sau khi dựng). User-Agent `YomiHub/0.5.7`. Cài đè 0.5.6.1 giữ dữ liệu (sẽ kiểm trước khi phát hành).
