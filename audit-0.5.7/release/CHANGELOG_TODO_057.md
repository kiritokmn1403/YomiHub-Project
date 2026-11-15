# CHANGELOG_TODO_057 – việc còn lại của bản nháp `YomiHub-0.5.7-changelog.md`

Ngày: 14/11/2026 (DOC1). Chỉ đọc; không sửa changelog gốc. Bản nháp hiện còn 2 chỗ `<<…>>`, và `build_057.ps1` sẽ báo cảnh báo khi còn `<<`; `release_057_publish.ps1` (chưa có) được thiết kế để chặn khi `-Execute`.

## A. Chỗ trống phải điền

| Vị trí trong bản nháp | Nội dung | Điền từ đâu |
|---|---|---|
| Dòng 3: `> Ngày phát hành: <<NGÀY PHÁT HÀNH>>` | Ngày phát hành thật | Ngày đăng Release v0.5.7 |
| Mục "Đã biết / chưa kiểm": `<<ĐIỀN SAU KIỂM THỬ THIẾT BỊ>>` | Kết quả kiểm thử máy và các lỗi còn mở | Xem mục C bên dưới; chỉ ghi những gì đã kiểm trên máy |

Ngoài hai chỗ này, cần thêm các nội dung sau vào mục "Đã biết / chưa kiểm" (chưa có trong bản nháp):
- Chưa dựng xong gói 0.5.7 tại thời điểm soạn (xem `STATS_0.5.7_vs_0.5.6.1.md`, mục "Tình trạng bản dựng").
- Chưa kiểm trên thiết bị: phát tiếp video (VOD, HLS, đổi server), Short với tiện ích ngoài, PiP, vuốt sáng/âm lượng, tua đúp, Health Connect trên Android 14+, chia sẻ LAN/Bluetooth giữa 2 máy, Telegram thật, Booru từng site, Windows.
- Giao diện Shiori: chưa có ảnh thật Cũ/Mới; chuyển trang cần khởi động lại; `ShioriHeader`, `ShioriTheme`, `ShioriCard` chưa nối.
- Treo UI 2,6 s và 2,8 s: chưa tìm được nguyên nhân (đã thêm tên màn hình vào log).
- Android 6.0: APK 0.5.7 chưa dựng/kiểm; lỗi A6 của 0.5.6.1 (ảnh Booru, CBZ, QuickJS) chưa kiểm lại.
- Windows: cửa sổ trắng (R21) chưa xử lý.
- Nyora và GIF Viewer không tích hợp; Frank Yomik chưa làm; Gecko chưa áp chống dấu vân tay.

## B. Chỗ bản nháp nói khác với ghi chú

| # | Bản nháp viết | Ghi chú nói | Đề xuất sửa |
|---|---|---|---|
| 1 | "Hợp nhất: … bộ hợp nhất có ô 'Nguồn đọc' được nhớ theo từng bộ, nút Đọc và chương kế tiếp theo nguồn đã chọn." | NOTES_P1: nút Đọc chỉ ở lần đầu; chương kế tiếp trong trình đọc; nút Tiếp tục không đổi nguồn; không áp dụng khi tải chương; không có dự phòng khi nguồn lỗi; bộ chọn chỉ hiện khi bộ có từ 2 nguồn | Ghi rõ: "nút Đọc lần đầu và chương kế tiếp trong trình đọc"; thêm câu "Tiếp tục và tải chương chưa theo nguồn đã chọn" |
| 2 | "Giao diện Mới (Shiori): ô bìa và huy hiệu kiểu Shiori, chuyển trang Shiori; ẩn ô 'gộp thư viện'…" | NOTES_P6: chuyển trang chỉ có hiệu lực sau khi khởi động lại; huy hiệu nguồn ở góc chưa đổi; ShioriHeader/Theme/Card chưa nối; chưa có ảnh thật | Thêm "có hiệu lực sau khi khởi động lại"; bỏ hoặc nêu rõ "chuyển trang Shiori" |
| 3 | "Bản APK Android 6.0 cài trên máy Android 7.0+ nay được nhận ra … (nguyên nhân lỗi tiện ích 'MiMi')." | NOTES_X1: "nhiều khả năng", CHƯA chạy thật để xác nhận | Đổi thành "có thể là nguyên nhân lỗi tiện ích 'MiMi' (chưa xác nhận)" hoặc bỏ phần trong ngoặc |
| 4 | "Tiện ích Kotatsu bị đẩy vào 127.0.0.1:9 … cầu nối không còn tự khởi động lại làm hỏng các nguồn khác." | NOTES_F1: lỗi vẫn xảy ra trên Windows (JVM không có proxy); CBHentai (Kotatsu) với Tor theo từng tiện ích vẫn không dùng được, chỉ báo đúng lý do; chưa sửa Kotlin | Thêm: "Kotatsu/IReader đi VPN theo từng tiện ích và trên Windows vẫn chưa hỗ trợ; khi bị chặn để tránh rò IP, ứng dụng báo lý do rõ ràng." |
| 5 | "Tor kẹt 45–50 % … tự đổi sang cầu nối khác khi không tiến triển (có công tắc tắt)." | NOTES_F1: chỉ Android; chỉ khi chọn snowflake/obfs4/meek; Windows chưa có; chế độ "Tự động" giữ nguyên; kiểm bằng test, chưa trên máy | Thêm phạm vi (Android, cầu nối cố định) và "Windows chưa có" |
| 6 | "Cloudflare 'đã giải xong nhưng vẫn không tải được': chỉ coi là đã giải khi WebView rời trang xác minh; gửi đúng dấu hiệu trình duyệt…" | NOTES_F1: không tái hiện được hentaicube.xyz; có thể trang đã đổi tên miền; `interactive` có thể bật trang xác minh khi tìm kiếm | Thêm "chưa tái hiện được; nếu vẫn lỗi hãy dùng Đổi URL" |
| 7 | "Health Connect: thời lượng đọc/xem được ghi thật; nhắc nghỉ mắt 20-20-20…" | NOTES_X1: mã đã gọi hàm ghi, CHƯA kiểm trên Android 14+; "ghi thật" là chưa kiểm | Đổi "được ghi thật" thành "được gửi vào Health Connect (chưa kiểm trên máy)" |
| 8 | "Trình duyệt: công tắc 'Bảo vệ dấu vân tay' nay hoạt động (Canvas, Audio, WebGL, navigator)." | NOTES_P4: chỉ trình duyệt Chromium/WebView; không áp cho Gecko và WebView giải Cloudflare; chưa thử trên trang thử | Thêm phạm vi "(trình duyệt Chromium; chưa áp cho Firefox)" |
| 9 | "Trình phát: … sửa văng khi mở cửa sổ nổi với tập chưa lưu." | NOTES_P3: lỗi là `episode.id!` khi tập chưa có id | Sửa thành "khi tập chưa có mã định danh" |
| 10 | "Trình phát: phát tiếp từ vị trí cũ ổn định hơn (giữ vị trí khi đổi server/chất lượng, mini player, ghi CSDL chậm)." | NOTES_P3: mã và test có; CHƯA kiểm trên máy (VOD/HLS, đổi server) | Thêm "(chưa kiểm trên máy)" |
| 11 | "Short Video: … công tắc 'Ép chế độ Short' theo nguồn." | NOTES_P3b: chỉ nguồn anime; genre "short" trơn không được nhận | Thêm "chỉ với nguồn anime" |
| 12 | "Nhật Ký … sao lưu Telegram (che token)…" | NOTES_P5b: mã đã che token; CHƯA gửi/khôi phục Telegram thật | Thêm "(chưa thử Telegram thật)" nếu chưa kiểm |
| 13 | "Yomikiru (phím tắt) và Yomihon (giãn dòng, thời gian đọc)…" | NOTES_P2: Yomikiru ghép trang đôi và kiểu căn không nối (đã có sẵn); Yomihon dọc chưa làm; mặc định tắt đúng | Đúng; có thể thêm "chưa có chế độ dọc cho tiểu thuyết" |
| 14 | "Google Play Books: thanh dưới …" | NOTES_PB: khớp 21 ảnh ở phần điều hướng; avatar và các màn hình (giá sách, tạo giá, chọn nhiều sách) là của trang Google, không làm được trong WebView | Đúng; thêm nếu muốn "giao diện do trang Google tạo" |
| 15 | "40 lỗi 'Null check…' khi đóng bảng chọn có thanh tab" | MATRIX: 40 lần ghi trong log (13/11 + 14/11); sửa dựa trên giải mã stack và test widget `yh_057_tabs`; chưa kiểm máy | Giữ; thêm "(đã sửa trong mã, chưa kiểm lại trên máy)" nếu cần |
| 16 | Tiêu đề: "Android 7.0+ (Điện thoại/Máy tính bảng và 'YumiHub Android TV')" | Mục TV trong MATRIX: DONE từ 0.5.6; cờ `IS_TV_BUILD` chưa xác minh trong APK 0.5.7; APK chưa dựng | Giữ nếu TV được phát hành; kiểm APK TV trước khi đăng |
| 17 | Phần "Số phiên bản": "Cài đè 0.5.6.1 giữ dữ liệu" | Chưa kiểm nâng cấp; bước kiểm trong `build_057_android.ps1` chưa chạy | Ghi "(sẽ kiểm trước khi phát hành)" hoặc kiểm rồi giữ |
| 18 | Phần "Số phiên bản": "Windows FileVersion 0.5.7.50" | Script đặt ProductVersion từ `FLUTTER_VERSION "0.5.7+50"`; FileVersion chưa xác minh | Kiểm bằng `Get-Item YomiHub.exe` sau khi dựng |
| 19 | "Kho tiện ích `.pb` không tải được không còn báo 'Invalid repository index' gây hiểu nhầm." | NOTES_S1: đúng là không còn FormatException; nguyên nhân gốc vẫn là timeout 25 s (nay 60 s khi thử lại) và kho vẫn có thể không tải được | Thêm "kho vẫn có thể không tải được nếu máy chủ kho chậm hoặc chặn" |
| 20 | "Kiểm tra cập nhật chạy song song các nguồn, thử lại 1 lần." | NOTES_S1: đúng; chưa chạy thật | Đúng |

## C. Số liệu cần đối chiếu trước khi đăng

- Tor kẹt: MATRIX ghi 11 lần, NOTES_F1 ghi 10 lỗi. Chọn một con số (hoặc "10–11 lần").
- "40× Null check": đối chiếu lại với log gốc.
- Số tệp: 120 tệp thay đổi (96 sửa + 24 mới) và manifest đồng bộ 118 (17:10) không khớp; cập nhật lại sau `sync_057.ps1 -Regen`. Nếu changelog có số tệp thì phải dùng số mới.
- Số test: lượt cuối 828 đạt / 1 trượt (`yh_056_a`, chập chờn). Chỉ ghi số test nếu lượt dựng chính thức đạt.
- Bản nháp không nêu số tính năng/lỗi; nếu thêm, dùng số trong STATS (13 tính năng; 22 mục lỗi, 21 đã sửa, 1 còn mở).

## D. Trước khi đăng (kiểm tra kỹ thuật)

1. Không còn `<<` trong changelog (`build_057.ps1` cảnh báo; `release_057_publish.ps1` chặn).
2. Tên tệp trong changelog và README khớp với `output\0.5.7` sau khi dựng (xem `README_release_section_057.md`).
3. Các mục "chưa kiểm" đã được ghi rõ trong bản đăng.
4. `TECHNICAL_UPDATE_NOTES.md` có mục 0.5.7 (NOTES_X1 ghi có mục 14/11; cần đối chiếu với mục mới).
