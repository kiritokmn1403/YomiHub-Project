# YomiHub 0.5.3 (0.5.3+45) – Có gì mới so với 0.5.2

Ngày phát hành: 06/11/2026 · Android 7.0+ (điện thoại và "YumiHub Android TV") · Windows 10/11 x64

## Tiện ích website chuyển sang kho Kiritokmn Extension Repo (YomiHub Update mục 2)
- 29 tiện ích website trước đây tích hợp sẵn trong ứng dụng nay nằm ở kho [Kiritokmn---Extension-Repo](https://github.com/kiritokmn1403/Kiritokmn---Extension-Repo). Danh sách: Hako, Sonako, AnimeVN, AVSub, RoPhim, HotPhim, Anime47, VTVgo, YouTube, Pornhub, FikFap, HihiSex, Tik.Porn, Kwiky, xFree, FapReel, SexVietTop, HayChill, XemPhimGi, NextPhim, Vfilm, CBHentai, Dâm Cô Nương, SayHentai, Xôi Lạc TV, Phimmoi, MotPhim, HiHiPhim, PhimMoiHD. Tệp kho: `repo/yomihub/`, `repo/index.json`.
- Lần đầu mở 0.5.3, ứng dụng **tự thêm kho** vào Truyện tranh, Phim & Điện ảnh và Tiểu thuyết, nhưng không tự cài tiện ích nào.
- Tiện ích đã cài vẫn giữ id, thư viện và cài đặt. Từ nay chúng nhận bản cập nhật từ kho (hiện "– Kiritokmn Extension Repo" và "Đang chờ cập nhật").
- Ứng dụng không còn mang mã của 29 tiện ích trong APK.

## Sao Lưu & Đồng Bộ (mục 4) và Bật/Tắt tính năng (mục 5)
- Mục mới **"Sao Lưu & Đồng Bộ"** ở cả **Cài đặt** và **Thêm**, gom các cài đặt:
  - tạo và khôi phục sao lưu, hoàn tác
  - tần suất, mã hoá, mức nén, vị trí sao lưu
  - sao lưu đám mây, đồng bộ
  - công tắc mới **"Sao lưu dữ liệu Booru App"**
- "Dữ liệu và bộ nhớ" chỉ còn phần tải xuống, lập chỉ mục, công cụ thư viện và bộ nhớ.
- Vị trí tự sao lưu nằm trên thẻ nhớ đã tháo, hoặc là đường dẫn của nền tảng khác, sẽ hiện chữ đỏ. Khi đó bản sao lưu được lưu vào thư mục mặc định.
- Công tắc **Google Play Books** và **Booru App** chuyển vào "Bật/Tắt tính năng & Nguồn mở rộng › Tính năng khác".

## Tracker (mục 7)
- Mới: **Xuất danh sách MyAnimeList (XML)** ở Cài đặt › Theo dõi (theo Tankobun / AnymeX).
  - Các mục theo dõi trên MyAnimeList và AniList được xuất ra tệp XML. Mục AniList được ghép sang MAL qua `idMal`.
  - Tệp nhập được vào myanimelist.net, AnymeX, Taiga.
- Thanh trạng thái, thanh điều hướng và bàn phím không còn che các ô của tracker:
  - ô tìm tracker
  - danh sách tracker của một bộ
  - cuối danh sách Theo dõi
  - hộp đăng nhập Kitsu
  - màn chi tiết tracker
- Đồng bộ: nút "Lấy máy chủ đồng bộ" trỏ tới máy chủ mới `mangayomi-sync-server`, vì Mangayomi Server cũ đã ngừng hỗ trợ.

## Windows (mục 9)
- Mới: **Cài đặt › Chẩn đoán Windows**.
  - Hiện CPU, số luồng, GPU + driver, WebView2, Java/M-Extension-Server và thư mục cài.
  - Liệt kê từng thành phần thiếu kèm tính năng bị tắt.
  - Có nút "Kiểm tra lại" và "Mở thư mục cài đặt".
  - Dùng để tìm lý do "thiếu tính năng" trên máy AMD Ryzen 9 mà không phải đọc nhật ký.

## Sửa lỗi từ nhật ký 0.5.2 (`logs 3.txt`) – treo, lag (mục 1, 8)
- Tự sao lưu không còn làm treo giao diện 3,3 giây. Chương được đọc bất đồng bộ và chuyển JSON theo lô.
- "Bỏ qua EPUB hỏng" không còn lặp lại mỗi lần mở ứng dụng.
- Mốc "Logger initialized" thành một dòng INFO, không còn là dòng WARNING rỗng.
- Shorts / trình phát:
  - Tệp video (mp4…) phát qua cùng tuyến Tor / Mihon Proxy / proxy riêng với tiện ích, vì link CDN có token gắn với IP.
  - Shorts tự thử lại nối thẳng nếu phát qua proxy bị lỗi.
  - Lỗi phát sinh sau khi đã đóng màn Shorts không còn bị ghi.
- Bản Windows không còn tạo bản sao lưu vào đường dẫn Android (`\storage\…`) khi cài đặt được khôi phục từ máy Android.

## Dự án GitHub (mục 3)
- Thêm 19 liên kết: Mangayomi Server, Yomikiru, Yomihon, Zenshin, Nyora (9 repo), Nuvio, Donut Browser, AnymeX, AniSync, Tankobun, Rokku.
- `Project GitHub.xlsx` (605 liên kết) không còn mục nào thiếu.

## Đã kiểm thử
- **Galaxy Note 9** (Android 10, Samsung DeX):
  - cài đè 0.5.2 → 0.5.3
  - tự thêm kho, cập nhật HotPhim và Anime47 từ kho
  - HotPhim: danh sách, chi tiết, phát phim
  - Sao Lưu & Đồng Bộ: tạo bản sao lưu 23,9 MB trong 13 s, không treo
  - Bật/Tắt tính năng, Theo dõi, xuất XML
- **VPN ngoài ứng dụng**:
  - Tor "Toàn bộ thiết bị": Chrome mở check.torproject.org → "Congratulations. This browser is configured to use Tor."
  - WARP trên mạng chặn UDP: báo lỗi rõ ràng và tự gỡ đường hầm.
- **Emulator Android 17**: hàng cuối Theo dõi nằm trên thanh cử chỉ; hộp đăng nhập Kitsu vẫn đủ ô khi bàn phím mở.
- **Android TV (AVD)**: chỉ có Phim & Điện ảnh / Cập nhật / Duyệt / Thêm; HotPhim tải từ kho, có viền focus.
- **Windows**:
  - Bản portable và Setup chạy, ghi chẩn đoán và chuyển 29 tiện ích sang kho.
  - Máy kiểm thử không chụp được nội dung cửa sổ Flutter: ảnh trắng, kể cả ứng dụng Flutter mẫu.
- `dart analyze`: 0 lỗi. `flutter test`: 122/122 đạt.

## Chưa làm / giới hạn
- Android 6.0, Windows 7/8, Windows x86/ARM: vẫn không hỗ trợ.
- Addon Stremio (Nuvio) và Nyora Cloud chưa tích hợp. Yomihon không có mã nguồn công khai.
