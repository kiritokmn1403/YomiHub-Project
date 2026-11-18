# YomiHub 0.5.9 – tiến độ (bắt đầu 18/11/2026 07:57)

Quyết định của chủ dự án (18/11): Windows 10/11 x64 (+ ARM64 nếu dựng được), APK thường (7.0+) + APK android6 + "YumiHub Android TV" (bỏ Comic, Novel, Google Play Books, Booru); Claude tự tạo Google Cloud project; Antigravity nhận phần Extension Repo qua /swarm (công khai là Claude điều phối); Claude chia việc cho 2 tác nhân phụ.
Thiết bị đang cắm: Samsung Galaxy Note 9 SM-N960N (Android 10). Log đến từ Xiaomi 25069PTEBG Android 16 chạy APK android6.

## Phân công (tập tệp rời nhau)
- Claude (điều phối): lỗi log – Isar unsendable, updater chọn nhầm APK, DNS check update, Tor, Cloudflare/WebView, treo UI; Google Sign-In + Drive; dựng & phát hành.
- Antigravity /swarm: D:\A.I Project\A.I Project - Extension Repo\Kiritokmn - Extension Repo (Anime47, FikFap, Phimmoi, AVSub, SexVietTop, AnimeVN, Pornhub Shorts). Ghi chú: _work/NOTES_swarm_0.5.9.md.
- Tác nhân A: nhật ký kèm phiên bản/thiết bị/HĐH mỗi dòng; bản TV bỏ Google Play Books; i18n. Ghi chú: notes/NOTES_A.md
- Tác nhân B: sao lưu chọn mục + Booru (lịch sử tìm kiếm, cài đặt); danh sách Dự Án GitHub đã sử dụng. Ghi chú: notes/NOTES_B.md

## Nhật ký
- 08:02 Runner pending_fast hoạt động; flutter 3.47.6; adb thấy Note 9.
- 08:10 Google Cloud project `yomihub` đã tạo, bật Drive API, OAuth branding đang chờ chủ dự án đồng ý User Data Policy.
- 08:20 Sửa: Isar unsendable (runChapterDiffInBackground), chọn APK theo SDK (apk_variant_picker.dart + test yh_059), kiểm tra cập nhật thử lại khi DNS lỗi + gộp lần gọi đồng thời. Job q059_fix1 đang chạy.
- 08:43 q059_fix1b: yh_039 7/7, yh_059_apk_picker 6/6 ĐẠT. 08:46 q059_fix2: yh_059_tor 5/5 + yh_057_f1 23/23 ĐẠT. 08:48 analyze 8 tệp 0 lỗi.
- 08:50 Google OAuth: client Desktop (Windows) + TV (Android/TV) tạo xong, test user = tài khoản chủ dự án; secrets/google_oauth.json. Sửa Tor nhớ cầu nối tốt, Cloudflare giải cùng đường mạng với tiện ích.

## Lưu tiến độ 10:42 (chủ dự án yêu cầu lưu mỗi ~2 phút)
### Đã xong (đã test)
- Sửa lỗi log: Isar unsendable; chọn APK theo SDK (apk_variant_picker); kiểm tra cập nhật thử lại khi DNS lỗi; Tor nhớ cầu nối tốt; Cloudflare giải cùng đường mạng tiện ích; Thư viện thống kê chương bằng truy vấn chỉ mục (hết treo 3 s); trình phát canh thoát kẹt.
- Nhật ký: nhãn [YH ver • thiết bị, Android x (SDK n)] trên mọi dòng – XÁC NHẬN trên Note 9.
- Bản TV tắt Play Books (YomiPlayBooks.enabled); Tạo bản sao lưu có mục "Booru App" – XÁC NHẬN trên Note 9.
- Dự án GitHub +258 liên kết/32 dự án; i18n +108 mục (18 ngôn ngữ). yh_049 15/15.
- Google Cloud project `yomihub`: client Desktop (Windows) + TV (Android/TV), test user taolangaoso1@gmail.com. Note 9: luồng mã thiết bị chạy, Claude nhập mã (chủ dự án đồng ý) → "Kết nối thiết bị thành công", app "Google Drive: Đã kết nối".
- Tải lên Drive lần 1 LỖI 403 "Google Drive API has not been used in project 270626866153" → nút Enable lúc 08:10 đã không ăn; 10:41 bấm Enable lại (đang chờ hiệu lực) → thử lại tải lên.
- Antigravity: đợt 1 sửa 7 tiện ích, build 196/196, commit 441eba7 (chưa push); đợt 2 báo cáo audit/audit-0.5.9/antigravity/ (14/14 repo OK, 29 repo gợi ý, 8/8 nguồn cập nhật OK).
- APK release arm64 0.5.9 (2052, 169,0 MB) cài lên Note 9 (cài đè giữ dữ liệu). Bằng chứng: audit/audit-0.5.9/evidence/note9/ (ảnh 01–20, video t1_launch.mp4, t13_gdrive_upload.mp4, log).
### Đang chạy
- Dây chuyền run_059_main (job x059_build_main, bắt đầu 10:29): bước test (264+ test đạt tới 10:38) → apk → tv → wintest → win → pack → a6build → a6copy → verify.
### Còn lại
- Thử lại tải lên Drive; test thêm trên Note 9 (mở truyện kiểm Isar, lọc thư viện, VPN, Giới thiệu, trình phát); test Windows (Setup.exe/appxbundle/portable + loopback Google); TV APK trên AVD; ghi TECHNICAL_UPDATE_NOTES phần kiểm thử; README + docs/ (Pages) + push + Release v0.5.9 + push Extension Repo; OAuth sang Production; câu hỏi 5 liên kết công cụ tấn công.
- Ghi chú: logger phân loại nhầm lỗi 403 của Google Drive thành "[Lỗi Nguồn 403 / Cloudflare]" – cần sửa classifyMessage cho mục [Đồng bộ đám mây].
- 10:44 Drive API đã bật (nút Disable API). Job x059_n9_t14: thử tải lên Drive lần 2 (quay video).
- 10:47 Dây chuyền: bước test 920/920 ĐẠT (10:40), đang bước apk. Note 9 t14 (tải lên Drive lần 2) đang chạy.
- 10:50 ĐẠT: Note 9 tải bản sao lưu lên Google Drive – Drive có thư mục YomiHub + yomihub_2026-11-18_10_43_13.154935.backup (10:43). Drive chủ dự án dùng 97%. Tiếp: kiểm Isar khi mở truyện/trình đọc.
- 10:53 ĐẠT: mở chi tiết + trình đọc trên Note 9, 0 lỗi 'unsendable' (0.5.8: >10 lần). Comick (m2k3a) lỗi mạng 10:49 – đang xem.
- 10:55 Trình đọc: Comick (m2k3a) lỗi kết nối api.comick.fun + URL thừa '//' (lỗi nguồn bên thứ ba); app hiện màn lỗi + Thử lại, ghi log đúng.
- 10:58 Bộ lọc Thư viện: chọn được (Đã tải/Chưa đọc), không có log treo/khung chậm. Chủ dự án báo (10:52): nhiều mục trong bộ lọc không bấm chọn được → đang tái hiện ở bộ lọc tiện ích.

## Lưu tiến độ 10:55
- Note 9 (0.5.9/2052): ĐẠT – khởi động 5 s, nhãn log từng dòng, mục Booru trong Tạo bản sao lưu, đăng nhập Google Drive (mã thiết bị) + tải bản sao lưu lên Drive (thư mục YomiHub, 10:43), trình đọc không còn "unsendable", bộ lọc Thư viện chọn được, không log treo.
- Job x059_n9_t19 (10:53) đã chạy hết: bộ lọc Thư viện "Đã tải" bấm lại (khôi phục), thử sắp xếp "Số chương chưa đọc" rồi đặt lại "Theo bảng chữ cái"; "Chưa đọc" CÓ THỂ còn đang bật → cần kiểm ảnh 34_filter_tab.png và tắt nếu còn.
- VIỆC MỚI (chủ dự án 10:52–10:53): "nhiều mục trong bộ lọc/filter không bấm chọn được" → chưa rõ bộ lọc nào; bộ lọc Thư viện chọn được → nghi bộ lọc của tiện ích (Duyệt › nguồn › Bộ lọc: Mihon/Kotatsu/vBook/Aidoku). Bước tiếp: tái hiện trên Note 9, tìm widget lọc trong overlay/lib (grep FilterWidget), sửa, test.
- Dây chuyền run_059_main: test 920/920 ĐẠT, đang bước apk (từ 10:40). Thay đổi overlay sau 10:29 sẽ KHÔNG có trong lượt dựng này → sau khi sửa bộ lọc phải dựng lại (RunSteps sync,apk,tv,win,pack,a6build,a6copy,verify).
- 11:02 Lỗi bộ lọc Thể loại (mọi tiện ích Truyện tranh): đọc filter_widget.dart, filter_profiles.dart, filter_sheet.dart, manga_home_screen.dart, filter.dart – logic nhìn đúng → tái hiện trên Note 9.
