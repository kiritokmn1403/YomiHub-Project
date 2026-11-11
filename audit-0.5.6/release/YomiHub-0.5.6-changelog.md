# YomiHub 0.5.6 (0.5.6+48) – Có gì mới so với 0.5.5

> Ngày phát hành: `12/11/2026` · Android 7.0+ (Điện thoại/Máy tính bảng và "YumiHub Android TV") · Windows 10/11 x64

Bản này gồm hai nhóm thay đổi: (1) điều hướng mới – mục **Thư Viện** và công tắc giao diện **Cũ / Mới**; (2) sửa lỗi lấy từ nhật ký ứng dụng (30/10–10/11/2026) và từ rà soát mã độc lập. Phần nào mới được kiểm thử tự động mà **chưa** thử trên thiết bị thì được ghi rõ bên dưới.

## Tính năng mới

### Thư Viện (Library) – gộp Truyện Tranh, Phim & Điện Ảnh, Tiểu Thuyết, Google Play Books (U12)
- Màn hình chính chỉ còn một đích **Thư Viện**; phía trên nội dung có dải tab con để chuyển giữa các thư viện, vuốt ngang để sang thư viện kế tiếp. Bốn nhánh cũ và liên kết cũ vẫn giữ nguyên nên không mất trạng thái trang.
- Công tắc Bật/Tắt tính năng & Nguồn mở rộng vẫn có hiệu lực: tắt mục nào thì tab đó ẩn.
- Thư Viện xuất hiện ở **cả hai chế độ giao diện Cũ và Mới** (yêu cầu U12, độc lập với công tắc giao diện). Đây là thay đổi hành vi so với 0.5.5 ngay cả khi giữ giao diện Cũ.
- **YumiHub Android TV:** chỉ còn Phim & Điện Ảnh (không Truyện Tranh, Tiểu Thuyết, Google Play Books, Booru). Cờ này mới được xác nhận qua mã và nhãn ứng dụng, chưa xác nhận bằng chạy thật trên TV (xem "Kết quả kiểm thử thiết bị").

### Công tắc giao diện Cũ ↔ Mới (U11) – phạm vi 0.5.6
- *Cài đặt → Giao diện → Giao diện ứng dụng*: **Cũ** (mặc định, kể cả khi nâng cấp hay khôi phục sao lưu cũ) hoặc **Mới**. Đổi có hiệu lực ngay, không cần khởi động lại; lựa chọn nằm trong sao lưu.
- **Chế độ Mới trong 0.5.6 thực sự có:** điều hướng kiểu Mangayomi v0.9.95 (Cập nhật + Lịch sử gộp thành "Hoạt động", tab Lịch sử trên thanh điều hướng), thanh điều hướng nổi dạng viên thuốc trên di động (không áp dụng cho TV), bộ chọn tab dạng viên trong Thư Viện (chỉ báo trượt 220 ms).
- **Chưa nối vào ứng dụng (để 0.5.7):** thẻ thư viện Shiori, tiêu đề phân mục, huy hiệu, chuyển cảnh trang, thanh điều hướng desktop dạng Liquid Glass. Mã nền đã có trong `lib/yomihub/ui/shiori/` và có kiểm thử đơn vị nhưng người dùng chưa thấy.
- 0.5.6 vẫn dùng nền Mangayomi v0.9.7; **không** chuyển nền sang v0.9.95 (Shiori đầy đủ, trình phát làm lại, lưu trữ Isar mới) – để bản sau.

### Hạn mức sao lưu tự động (U3)
- *Sao Lưu & Đồng Bộ* có thêm **Số lượng bản sao lưu**: giữ 1, 2, 3, 5, 10, 20 bản gần nhất hoặc **Không giới hạn** (mặc định cho mọi người dùng).
- Dọn dẹp chỉ chạy trong thư mục `autobackup`, chỉ xóa tệp có đúng mẫu tên do ứng dụng sinh ra, chỉ sau khi bản mới đã ghi xong, ghi Nhật ký mỗi tệp xóa và mỗi lỗi. Tệp sao lưu thủ công và tệp lạ không bị đụng tới.

### Nút "Kiểm Tra Cập Nhật" ở tab Tiện ích trong Duyệt (U8)
- Làm mới danh sách kho và kiểm tra cập nhật tiện ích; thông báo số kho thành công / số kho lỗi (không còn báo "hoàn tất" khi mọi kho lỗi), ghi Nhật ký host của kho lỗi.

### Màn hình Giới thiệu – Dự Án GitHub (U2, FC31)
- Bổ sung 34 liên kết còn thiếu so với danh sách, gồm aniyomi.org, mangayomi.org, KotatsuApp/plugin-sdk, kotatsu-syncserver, kotatsu-parsers, subsampling-scale-image-view. Đối chiếu 637/637 URL duy nhất trong Excel; mục có nhiều URL cho chọn từng URL.

## Sửa lỗi

### Trình phát video
- Lỗi lặp "Cannot seek" khi mpv từ chối tua: vòng tua chờ được hủy; Nhật ký ghi lý do (rút gọn, không chứa URL có token) (R1, R2, FC32, FC39).
- Phát tiếp: một bộ điều phối duy nhất xác nhận phát tiếp, giảm dung sai, chặn cập nhật track khi phiên phát đã đổi (B2, FC39).

### Cơ sở dữ liệu Isar
- Lỗi `async write transaction already in progress`: tác vụ không chờ (timer, stream) sinh ra trong một tác vụ ghi không còn bỏ qua hàng đợi; có chống khóa chết (`stallTimeout` 120 giây, ghi cảnh báo `[Isar Queue]`). Đo khôi phục trên dữ liệu thử: 50 nghìn chương 0,77 s, 200 nghìn 3,7 s, 500 nghìn 9,5 s (A4b, R15).

### Mạng, Cloudflare, VPN
- Cloudflare: thay clearance cũ khi thử lại, không chép cookie sau chuyển hướng ngược sang host nguồn; khi không mở được giao diện giải Cloudflare thì ném lỗi rõ và ghi "Giải CloudFlare thất bại" thay vì trả trang thử thách (B1.3, R16, FC19, FC32).
- Tor/OpenVPN: hợp nhất yêu cầu Tor đang chờ, kết quả cũ đến muộn không đưa giao diện về "STARTING" sau khi đã tắt Tor; xóa lịch sử chẩn đoán OpenVPN giữa hai lần kết nối (B1.4).
- Telegram: giữ đúng Chat ID người dùng đã chỉ định (không tự đổi sang chat khác để tránh gửi sao lưu nhầm); khi Telegram báo "chat not found" thì hiển thị hướng dẫn (nhắn /start, thêm bot, hoặc để trống ô ID để tự dò); báo rõ thiếu Chat ID trước khi mở tệp (B1.5, R17, FC42).

### Tiện ích và nguồn
- "Cầu nối Kotatsu chưa chạy" (log 31/10): máy chủ cầu nối đã chết nay được phát hiện (ping), khởi động lại và gửi lại yêu cầu một lần (A3).
- Gương GitHub hỗ trợ refs/heads và refs/tags, mã hóa tên tệp; gợi ý kho tách bộ nhớ đệm theo cài đặt NSFW và bỏ kết quả rỗng sau lỗi mạng (B1.6, FC21).
- Shorts: bộ lọc Shorts thật cho từng tiện ích; màn hình còn hoạt động sau khi tải clip (B2, U9, FC26).

### Hiệu năng và ổn định
- Cập nhật thư viện nền không còn dùng ngữ cảnh đã rời cây widget (null check trong log 04/11) (B1.2).
- Đọc thư mục bất đồng bộ trong `get_html_content`/`get_video_list`; tính infohash torrent theo luồng thay vì đọc cả tệp trên luồng giao diện (B1.7).

### Bản dịch
- Thêm 10 khóa còn thiếu ở cả 18 ngôn ngữ (18 tệp cùng 1575 khóa); nhãn "Play Books" trong Thư Viện đi qua i18n (R10, R14).

### Gói phát hành
- Zip dùng `/` làm phân cách; thêm `data/flutter_assets/version.json`; Bundle Identity của `.appxbundle` khớp 0.5.6.0; `SHA256SUMS` không BOM, ngắt dòng LF (R13). Đã kiểm lại trên gói trong `output/0.5.6`.

## Thay đổi
- Cài đặt upstream **"Gộp thư viện trên di động"** nay **không còn tác dụng** vì Thư Viện luôn gộp; ô cài đặt sẽ ẩn ở 0.5.7.
- Đã **gỡ** thao tác "Tối ưu hóa cho AMD Ryzen / CPU đa luồng" (R9): nó đặt khóa không ai đọc và mô tả sai chế độ giải mã. Màn hình Chẩn đoán Windows chỉ báo CPU/cấu hình video và gợi ý chế độ giải mã phần mềm.
- Phiên bản nâng lên 0.5.6+48; User-Agent `YomiHub/0.5.6`.
- Android 7.0+ (minSdk 24) vẫn giữ nguyên; thư viện Isar vẫn 3.3.2.

## Gói phát hành (`output/0.5.6/`)
| Tệp | Dùng cho |
| --- | --- |
| `YomiHub-0.5.6-arm64-v8a.apk` | Điện thoại/máy tính bảng ARM 64-bit |
| `YomiHub-0.5.6-armeabi-v7a.apk` | ARM 32-bit đời cũ |
| `YomiHub-0.5.6-x86_64.apk` | Máy ảo / Chromebook x86_64 |
| `YumiHub-Android-TV-0.5.6-arm64-v8a.apk` | Android TV / TV box 64-bit |
| `YumiHub-Android-TV-0.5.6-armeabi-v7a.apk` | Android TV 32-bit |
| `YumiHub-Android-TV-0.5.6-x86_64.apk` | Máy ảo TV x86_64 |
| `YomiHub-0.5.6-windows-x64-Setup.exe` | Bộ cài Windows |
| `YomiHub-0.5.6-windows-x64.appxbundle` | Gói MSIX/AppxBundle ký số (cần `YomiHub-RootCA.cer`) |
| `YomiHub-0.5.6-windows-x64.zip` | Bản portable (không kèm Java/M-Extension-Server) |
| `YomiHub-0.5.6-windows-x64-full.zip` | Bản portable đầy đủ (kèm JRE + M-Extension-Server) |
| `YomiHub-RootCA.cer`, `Install-YomiHub.bat`, `Install-YomiHub.ps1` | Chứng chỉ và kịch bản cài `.appxbundle` |
| `SHA256SUMS-0.5.6.txt`, `YomiHub-0.5.6-changelog.md` | Băm kiểm tra và ghi chú này |

## Yêu cầu hệ thống
- **Android 7.0 trở lên (minSdk 24).** **Android 6.0 KHÔNG ĐẠT:** thư viện Isar 3.3.2 không chạy trên API 23; thử `isar_community_flutter_libs` 3.4.1 trên giả lập API 23 chưa thực hiện, để sau.
- **Windows 10/11 x64.** **KHÔNG ĐẠT:** Windows 7/8/8.1 (Flutter 3.x cần API Windows 10), Windows x86 32-bit (Flutter không có engine x86; lệnh dựng x86 thất bại, chỉ có artifact windows-x64), Windows ARM64 **gốc** (không có bản dựng ARM64; chỉ có thể chạy bản x64 qua lớp giả lập của Windows 11, chưa kiểm thử).

## Lỗi đã biết
- **Windows – cửa sổ trắng chập chờn (R21):** trên máy Intel Iris Xe với driver cũ (27.20.100.9664, 2021), cửa sổ YomiHub có lúc hiện trắng dù ứng dụng vẫn chạy; cùng một tệp nhị phân lúc hiện đủ, lúc trắng, đổi theo từng phút. Không phải hồi quy của 0.5.6 (0.5.3 cũng bị). Tác nhân chưa xác định. Cách thử: mở lại ứng dụng sau 1–2 phút, cập nhật driver đồ họa.
- Cài đặt "Gộp thư viện trên di động" vô tác dụng (xem trên).
- Đổi cỡ cửa sổ Windows có lúc không vẽ lại (nghi cùng họ R21).
- Ảnh bìa không hiện ở một số nguồn truyện (do nguồn).
- Giao diện Mới trên điện thoại: nhãn tab bị cắt.
- Giao diện Mới mới có điều hướng nổi, bộ chọn viên và Thư Viện; thẻ, chuyển cảnh, rail desktop để 0.5.7.
- Tiện ích **vBook** mã hóa: còn hạn chế, chưa chạy được đầy đủ (không thuộc phạm vi sửa của 0.5.6).
- **Chưa tích hợp** (mã có sẵn nhưng chưa nối vào ứng dụng, không có hiệu lực với người dùng): Yomikiru Reader Enhancer, Yomihon Novel Enhancer, Zenshin Anime Tracker, Nyora Data Bridge, Nuvio Media Hub, GIF Viewer Controller (U5). **Chưa tích hợp:** kotatsu-syncserver, plugin-sdk (không có máy chủ/tài khoản thử, khác kiến trúc), subsampling-scale-image-view (thư viện View Android, không áp dụng cho Flutter). Mangayomi Project: chỉ lấy phần điều hướng nhóm/vuốt ngang; Shiori đầy đủ, trình phát mới, tracker trên máy chưa lấy.
- Phần Kotlin của cầu nối Kotatsu và các sửa Tor/Telegram/Cloudflare **chưa thử trên thiết bị thật hoặc máy chủ thật**.

## Kiểm thử đã thực hiện
- `dart analyze lib`: 0 lỗi (166 cảnh báo, 52 info). Toàn bộ `flutter test`: **682/682 đạt** (Android, sau R25) và **676/676 đạt** (Windows, sau R26). Đây là kiểm thử tự động, không thay thế kiểm thử trong ứng dụng.
- Kiểm thử trong ứng dụng lượt QA2 (12/11/2026): xem mục "Kết quả kiểm thử thiết bị" bên dưới.
- Lưu ý: "ĐẠT" của lượt ngày 11/11 12:48 đã bị hủy (ảnh không hợp lệ); kết quả hiện hành là lượt QA2 (ảnh được người kiểm tự mở xem).

## Kết quả kiểm thử thiết bị
Mốc 2 duyệt 12/11/2026 00:40. Đạt: điện thoại thật Xiaomi Android 16 (cài đè 0.5.5→0.5.6 giữ dữ liệu, Thư Viện Cũ/Mới, giao diện Mới, phát tiếp video, sao lưu "Không giới hạn", không văng); AVD điện thoại (khởi động, Cũ/Mới, Sao Lưu, Kiểm Tra Cập Nhật "Kho thành công: 1. Kho lỗi: 0.", đọc chương ComicK); AVD Android TV (không có Truyện tranh/Tiểu thuyết/Play Books/Booru, D-pad, mở lần đầu không kẹt); Windows 11 x64 (giao diện chính, Thư Viện Cũ/Mới, Sao Lưu). Test tự động: 682/682 (Android) và 676/676 (Windows), analyze 0 lỗi.

**Chưa kiểm:** VPN, Tor, Telegram, tracker, Health Connect, AirDrop/Quick Share, PiP đầy đủ, Short Video, cài đè Setup.exe trên Windows.
