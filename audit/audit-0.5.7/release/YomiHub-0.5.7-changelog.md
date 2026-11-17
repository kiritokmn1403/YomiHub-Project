# YomiHub 0.5.7 (0.5.7+50)

> Ngày phát hành: `<<NGÀY PHÁT HÀNH>>` · Android 7.0+ (Điện thoại/Máy tính bảng và "YumiHub Android TV") · Android 6.0 (APK riêng) · Windows 10/11 x64

Giữ nền Mangayomi hiện tại; sửa lỗi trong nhật ký 12–14/11/2026 và làm tiếp các yêu cầu của sheet "YomiHub Update" / "Feature Check".

Mục nào chưa kiểm trên máy thật được ghi "(chưa kiểm trên máy thật)".

## Sửa lỗi từ nhật ký ứng dụng (logs 12–14/11/2026)
- Khi đóng bảng chọn có thanh tab (Thư viện, trình đọc), ứng dụng từng báo "Null check operator used on a null value" (khoảng 40 lần trong nhật ký). Đã sửa; đã kiểm trên Galaxy Note 9 (Android 10): mở/đóng bảng Thư viện và bảng cài đặt trình đọc nhiều lần, logcat không còn "Null check".
- Tiện ích Kotatsu không còn bị đẩy vào `127.0.0.1:9` khi Tor đang khởi động, và cầu nối Kotatsu không còn tự khởi động lại làm hỏng các nguồn Kotatsu khác. Khi có nguy cơ rò IP, ứng dụng chặn và báo lý do bằng tiếng Việt. Kotatsu/IReader đi VPN theo từng tiện ích và trên Windows vẫn chưa hỗ trợ (chưa làm).
- Tor kẹt ở 45–50 % với cầu nối snowflake: trên Android, khi chọn cầu nối snowflake, obfs4 hoặc meek và Tor không tiến triển, ứng dụng tự thử cầu nối khác. Có công tắc "Tự đổi cầu nối khi Tor bị kẹt" (mặc định bật). Chế độ "Tự động" giữ nguyên; Windows chưa có. (chưa kiểm trên máy thật)
- Cloudflare "đã giải xong nhưng vẫn không tải được" (một trang CBHentai): chỉ coi là đã giải khi trình duyệt đã rời trang xác minh; gửi đúng dấu hiệu trình duyệt đã vượt xác minh. Chưa tái hiện được lỗi; nếu vẫn gặp, hãy dùng "Đổi URL" của nguồn. (chưa kiểm trên máy thật)
- Kho tiện ích `.pb` không tải được không còn báo "Invalid repository index" gây hiểu nhầm. Kho vẫn có thể không tải được nếu máy chủ kho chậm hoặc chặn. Kiểm tra cập nhật chạy song song các nguồn và thử lại 1 lần. (chưa chạy thật)
- Phân loại lại lỗi tiện ích: Kavita chưa cấu hình, HTTP 530/"HTTP 0" của trang đã chết, tiện ích "(Ngừng hoạt động)", nguồn Aidoku không có kết quả… không còn ghi ERROR kèm stack.
- Tiện ích "MiMi" báo lỗi `typeParametersSerializers()`: nay được ghi là cảnh báo kèm gợi ý. APK Android 6.0 cài trên máy Android 7.0+ được nhận ra và nhắc cài bản APK thường; đây có thể là nguyên nhân lỗi "MiMi" (chưa xác nhận).
- Gộp các dòng "Image/network load failed" lặp lại (nhật ký ghi 1 dòng đầu, các dòng sau gộp thành 1 dòng tổng mỗi phút); ghi tên màn hình khi giao diện bị treo. Nguyên nhân treo 2,6 s và 2,8 s chưa tìm được.
- Ghi cơ sở dữ liệu (Isar) có thể báo lỗi "async write transaction is already in progress" và văng khi máy tải nặng: đã sửa hàng đợi ghi. Đã kiểm bằng test Isar thật trên máy phát triển; chưa kiểm trên máy thật.
- Trình đọc ảnh trên Android dưới 11: bộ giải mã gốc dùng API chỉ có từ Android 11 nên trang treo hoặc báo "Không tải được ảnh này". Nay giải mã bằng bộ giải mã của Flutter, mỗi bước giới hạn 12 giây, quá 30 giây thì báo lý do và cho Thử lại. Đã kiểm trên Galaxy Note 9 (Android 10): trang MangaDex hiện sau khoảng 3 giây.
- Chỉ APK Android 6.0: sửa nạp thư viện native cho QuickJS (tiện ích JavaScript) và bộ giải mã ảnh (trang CBZ), sửa đường dẫn ảnh Booru; thêm log chẩn đoán ảnh mạng. Trên AVD Android 6.0 (API 23) hai thư viện nạp được; chưa kiểm trên điện thoại Android 6 thật. (chưa kiểm trên máy thật)
- Video đen hình trên Android 10 trở xuống (vẫn có tiếng, thanh điều khiển vẫn hiện): trên các máy này ứng dụng nay dùng SurfaceTexture cho video và tắt Impeller; đã giữ lại trường cấu hình này khi R8 thu gọn mã (lần dựng trước bị R8 xóa nên bản sửa không có hiệu lực). Đã kiểm trên AVD Android 10 (API 29): tệp MP4 hiện hình và chuyển động, logcat không lỗi; nhật ký Note 9 xác nhận bản sửa được áp dụng (màn hình Note 9 hỏng nên không nhìn được hình).
- Windows: cửa sổ trắng (lỗi R21 từ 0.4.5). Nguyên nhân nằm ở khâu trình chiếu khung hình (swapchain kiểu bitblt gắn cửa sổ) trên một số máy, không phải ở mã ứng dụng – cả một ứng dụng Flutter tối giản cũng trắng. YomiHub nay dùng swapchain kiểu flip-model. Đã kiểm trên máy của chủ dự án (Intel Iris Xe + NVIDIA GTX 1650, Windows 11): cài đè Setup.exe lên bản cũ, giao diện hiện đủ (Thư Viện, Play Books, Thêm, VPN & DNS, Cài đặt).

## Tính năng và thay đổi
- Bật/Tắt tính năng: công tắc Google Play Books và Booru App nằm ngay trong "Bật/Tắt tính năng & Nguồn mở rộng".
- Hợp nhất: các công cụ hợp nhất gom về "Hợp Nhất Tiện Ích". Bộ hợp nhất có ô "Nguồn đọc" được nhớ theo từng bộ (chỉ hiện khi bộ có từ 2 nguồn); nút Đọc lần đầu và chương kế tiếp trong trình đọc mở theo nguồn đã chọn. Nút Tiếp tục và việc tải chương chưa theo nguồn đã chọn. (chưa kiểm trên máy thật)
- Giao diện Mới (Shiori): ô bìa và huy hiệu kiểu Shiori; ẩn ô "gộp thư viện" khi dùng giao diện Mới. Chuyển trang Shiori có hiệu lực sau khi khởi động lại; huy hiệu nguồn ở góc chưa đổi. Giao diện Cũ và Android TV không đổi. (chưa kiểm trên máy thật; chưa có ảnh so sánh)
- Trình phát: phát tiếp từ vị trí cũ ổn định hơn (giữ vị trí khi đổi server/chất lượng, mini player, ghi CSDL chậm); không còn tua lặp khi phát tiếp HLS; nút Quay lại trở về ứng dụng thay vì bị kẹt trong cửa sổ nổi. Đã kiểm trên Note 9: phát tiếp đúng 01:22:56, không tua lặp. (chưa kiểm: đổi server)
- Trình phát: ghi nhật ký khi video không tải được hoặc không lưu được vị trí; sửa văng khi mở cửa sổ nổi (mini player) với tập chưa có mã định danh.
- Trình phát: nối module Nuvio (vuốt sáng/âm lượng, tua đúp, tỉ lệ PiP) và Zenshin (đồng bộ tracker khi xem đạt 85 %, một lần mỗi lượt phát); ba công tắc Nuvio, Zenshin, PiP nằm trong cài đặt. (chưa kiểm trên máy thật)
- Short Video: nhận diện thêm tiện ích ngoài; công tắc "Ép chế độ Short" theo nguồn, chỉ với nguồn anime; bộ lọc "Ẩn video ngắn" không còn bị bật ngược. (chưa kiểm trên máy thật với tiện ích ngoài)
- Trình đọc: phím tắt A/D/Space/Home/End (Yomikiru); thời gian đọc ước tính cho tiểu thuyết (Yomihon). Các tùy chọn giãn dòng và thời gian đọc mặc định tắt, bật trong cài đặt trình đọc. Chưa có chế độ dọc cho tiểu thuyết.
- Health Connect: thời lượng đọc/xem được gửi vào Health Connect; nhắc nghỉ mắt 20-20-20 khi đọc/xem liên tục. (chưa kiểm trên máy thật, đặc biệt Android 14+)
- Trình duyệt: công tắc "Bảo vệ dấu vân tay" nay hoạt động với trình duyệt Chromium/WebView (Canvas, Audio, WebGL, navigator). Chưa áp cho Firefox. (chưa kiểm trên trang thử thật)
- Google Play Books: thanh dưới Trang chủ / Thư viện / Yêu thích / Cửa hàng, tab Sách điện tử / Sách nói theo ảnh mẫu. Phần nội dung do trang Google tạo, không sửa được trong ứng dụng. (chưa kiểm trên máy thật)
- Nhật Ký Ứng Dụng ghi thêm lỗi của Web Scanner, chia sẻ LAN/Bluetooth, sao lưu Telegram (token được che), Booru, tải xuống chỉ qua Wi-Fi; nhận tệp LAN bị ngắt không còn để lại tệp hỏng. (chưa thử Telegram thật)
- Sao lưu & khôi phục giữa điện thoại và máy tính: đã kiểm cả hai chiều. Note 9 tạo bản sao lưu 24,5 MB → Windows khôi phục (Thay thế) 4.490 bộ; Windows tạo bản sao lưu 24,2 MB → khôi phục vào Android 10 (AVD) và vào Note 9. Khi nguồn trong bản sao lưu chưa cài, ứng dụng hỏi cách xử lý (giữ tên gốc) thay vì báo lỗi.
- Trình đọc truyện: ảnh trang không còn quay mãi khi máy chủ ảnh không trả lời: sau 30 giây báo lý do và cho tải lại; lỗi được ghi vào Nhật Ký Ứng Dụng.
- Nhãn thanh điều hướng giao diện Mới và Play Books không còn bị cắt / đè biểu tượng (đã kiểm trên Note 9).
- Bản dịch: bổ sung chuỗi mới cho 18 ngôn ngữ.

## Đã biết / chưa kiểm
- Chưa kiểm trên thiết bị: đổi server khi phát video, Short với tiện ích ngoài, vuốt sáng/âm lượng, tua đúp, Health Connect trên Android 14+, chia sẻ LAN/Bluetooth giữa 2 máy, Telegram thật, Booru từng site.
- Sao lưu: khi khôi phục cùng một bản sao lưu điện thoại, Windows ghi 99.299 chương còn Android ghi 88.371 chương (số bộ khớp: 4.490); nguyên nhân chênh lệch chưa rõ. Nếu chọn nhầm tệp không phải bản sao lưu, ứng dụng hỏi xác nhận ghi đè trước khi kiểm tra loại tệp. Khôi phục kiểu Thay thế trên Note 9 (thư viện lớn sẵn có) mất khoảng 10 phút, trên Windows khoảng 1 phút; trong lúc đó màn hình hiện "Đang khôi phục thư viện…" – đừng tắt ứng dụng.
- Giao diện Shiori: chưa có ảnh thật Cũ/Mới; chuyển trang cần khởi động lại.
- Treo giao diện 2,6 s và 2,8 s: chưa tìm được nguyên nhân (đã thêm tên màn hình vào nhật ký).
- Android 6.0: kiểm lại ảnh Booru, CBZ và QuickJS trên máy thật chưa làm.
- Windows: Kotatsu/IReader đi VPN theo từng tiện ích chưa hỗ trợ.
- Nyora và GIF Viewer không tích hợp; Frank Yomik chưa làm; Gecko chưa áp chống dấu vân tay.
- Ảnh bìa trống trên Note 9 và Windows của chủ dự án khi bật VPN Tor: nhật ký cho thấy máy chủ ảnh (raw.githubusercontent.com, CDN của nguồn) từ chối hoặc hết thời gian chờ; cùng thư viện trên hồ sơ không bật VPN thì hiện bìa. Chưa xác nhận đây là nguyên nhân duy nhất.
- Kết quả kiểm thử thiết bị: Galaxy Note 9 (Android 10): hết lỗi "Null check", trang truyện hiện khoảng 3 giây, phát tiếp video đúng vị trí, không tua lặp, Quay lại không kẹt cửa sổ nổi. Máy ảo Android 10: video hiện hình (trước đây đen), APK TV mở được. Windows 11 (Intel Iris Xe + GTX 1650): hết cửa sổ trắng, cài đè giữ dữ liệu. Sao lưu/khôi phục hai chiều điện thoại ↔ máy tính: 4.490 bộ khôi phục đủ. Chưa kiểm trên máy thật: APK Android 6.0 trên máy ARM, đổi server khi phát video, Health Connect Android 14+, chia sẻ LAN/Bluetooth, Telegram.

## Số phiên bản
Phiên bản 0.5.7, versionCode cơ sở 50 (arm64-v8a 2050, armeabi-v7a 1050, x86_64 4050). Windows ProductVersion 0.5.7+50; FileVersion 0.5.7+50 (đã kiểm trên bản cài). User-Agent `YomiHub/0.5.7`. Cài đè 0.5.6.1 giữ dữ liệu (đã kiểm trên Note 9 và Windows).
