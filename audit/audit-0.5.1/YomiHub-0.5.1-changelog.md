# YomiHub 0.5.1 (0.5.1+43) – 04/11/2026

## Tính năng mới
- **Thư mục cục bộ nhận được tệp đã tải của Aniyomi, Nekoyomi, Mihon và Mangayomi.**
  - Chọn thẳng thư mục lưu chung của các ứng dụng đó (ví dụ `…/downloads`). YomiHub tự đi xuống `Nguồn (VI)/Tên truyện/…` (tối đa 4 cấp) để tìm bộ truyện.
  - Nhận thêm cấu trúc của Mangayomi: `downloads/Manga|Anime|Novel/…`.
  - Mỗi tập phim của Aniyomi nằm trong thư mục riêng; tên tập lấy theo tên thư mục.
  - Bỏ qua bản tải dở `*_tmp`, các thư mục `autobackup` và `mpv-config`, và tệp sao lưu `.bk.zip` / `.tachibk`.
  - Bản sao lồng nhau của cùng một cây thư mục chỉ được nhập 1 lần.
- **Kiểm tra tệp APK tiện ích** (Cài đặt › Duyệt): đọc tệp APK của tiện ích Mihon / Aniyomi / IReader mà không cần cài.
  - Thông tin hiển thị: gói, phiên bản, lớp tiện ích, NSFW, phiên bản thư viện, quyền, các lớp nguồn và `AndroidManifest.xml`.
  - Dựa trên dự án [Decode & Extract](https://github.com/kiritokmn1403/Decode-Extract), chuyển sang Dart và sửa 2 lỗi đọc chuỗi/chỉ số của bản gốc.
- **Danh sách "Dự án GitHub đã sử dụng":** thêm 18 liên kết còn thiếu so với `Project GitHub.xlsx`: vBook (Darkrai9x, kychitoge, hieu45666), LeechText, sherpa-onnx và Decode & Extract.

## Sửa lỗi
- **Android 7–10 không đọc được thư mục ngoài bộ nhớ của ứng dụng.** Đây là nguyên nhân chính khiến thư mục cục bộ trên thẻ nhớ trống. Ứng dụng chỉ xin quyền "Truy cập mọi tệp", vốn chỉ có từ Android 11. Nay trên Android 7–10 ứng dụng xin quyền bộ nhớ, và hỗ trợ chế độ bộ nhớ cũ (legacy storage) trên Android 10.
- **Nhật ký ứng dụng không ghi được và màn "Nhật ký ứng dụng" quay vòng mãi** khi thiếu quyền bộ nhớ. Nay nhật ký tự chuyển sang thư mục riêng của ứng dụng, và màn hình nhật ký không còn treo.
- **Giật khi mở "Thêm" / "Cài đặt"** (khung hình 1–2,9 giây, treo 2,7 giây). Nguyên nhân là việc tìm tiện ích trùng tên miền, khởi động cầu nối Kotatsu, làm mới kho Aidoku/LNReader và gắn nguồn cho truyện cục bộ đều đọc **toàn bộ tiện ích kèm mã nguồn** trên luồng giao diện. Nay các việc này dùng truy vấn nhẹ, chạy ngầm.
- **Tiện ích vBook:**
  - Khi mất mạng, lệnh tải trang tự thử lại 1 lần, và thông báo lỗi nêu rõ nguyên nhân (địa chỉ + lỗi mạng / mã HTTP).
  - Nhãn "Chỉ chạy trên vBook" nằm trên dòng riêng, không còn bị cắt chữ.
  - Báo rõ khi kho không còn tệp `plugin.zip` (HTTP 404).
- Khi máy mất mạng, nhật ký chỉ ghi 1 dòng cho mỗi máy chủ thay vì 1 dòng cho mỗi kho (log cũ: 45 dòng trong 13 giây).
- **Một tệp EPUB hỏng làm dừng cả lượt quét thư mục cục bộ** (`Could not find EOCD`). Nay tệp hỏng được bỏ qua và ghi vào nhật ký.
- **Màn "Nhật ký ứng dụng" và "Kiểm tra tệp APK" báo lỗi `object is unsendable`** khi xử lý ở luồng nền. Đã sửa: việc đọc và tách nhật ký chạy ở luồng nền, chỉ giữ 3.000 mục mới nhất.
- **Android TV / Android 11+: trang hệ thống "Truy cập mọi tệp" tự mở mỗi lần khởi động** (do tab Duyệt và lượt quét nền xin quyền). Nay các việc chạy nền chỉ hỏi 1 lần; ứng dụng chỉ hỏi lại khi bạn tự bấm quét lại / thêm thư mục / tải xuống.

## Tiện ích vBook mã hóa
Đã quét lại 554 tiện ích của 18 kho vBook: 234 tiện ích vẫn bị tác giả mã hóa, chỉ chạy được trong ứng dụng vBook. YomiHub tiếp tục khóa các tiện ích này và hiện nhãn, chứ không giải mã. 313 tiện ích không mã hóa chạy bằng runtime vBook của YomiHub.

## Nền tảng
- Android 7.0+ (minSdk 24): APK arm64-v8a, armeabi-v7a, x86_64.
- YumiHub Android TV (chỉ Phim & Điện ảnh; không có Truyện tranh, Tiểu thuyết, Google Play Books, Booru): APK arm64-v8a, armeabi-v7a, x86_64.
- Windows 10/11 x64:
  - `Setup.exe`.
  - `.appxbundle`: chạy `Install-YomiHub.bat`, hoặc cài chứng chỉ `YomiHub-RootCA.cer` trước.
  - Bản portable `.zip` và `-full.zip` (kèm M-Extension-Server).
- Chưa hỗ trợ:
  - Android 6.0: cơ sở dữ liệu Isar/libmdbx không mở được.
  - Windows 7/8, x86 và ARM: Flutter Windows chỉ hỗ trợ Windows 10+ x64.

Chi tiết kỹ thuật: `TECHNICAL_UPDATE_NOTES.md`, mục "03/11/2026 — Cập nhật phiên bản 0.5.1".
