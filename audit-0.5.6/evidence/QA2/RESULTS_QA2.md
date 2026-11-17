
## Windows (S-W)

Bản dựng: D:\yh\buildwin\...\Release\YomiHub.exe (0.5.6+48). Môi trường: máy đang chạy emulator Android (qemu, CPU rất cao) song song. KHÔNG ca nào đủ bằng chứng ĐẠT.

| Ca | Kết quả | Mô tả | Ảnh |
|---|---|---|---|
| 1 Khởi động/splash | CHƯA KIỂM | Cửa sổ chỉ trắng (độ trắng 64-73%, chỉ có góc chuyển màu hồng nhạt), không thấy màn khởi động hay logo bo tròn trong 10 s đầu; ảnh trắng KHÔNG tính ĐẠT | evidence/QA2/windows/ca1_a.png, ca1_c.png, ca1b_*.png, ca1c_*.png |
| 2 Thư Viện/4 tab/ảnh bìa | CHƯA KIỂM (có quan sát) | Thư Viện hiện lưới truyện, thanh tab thể loại (Lịch Sử Đọc, 00 - Tất Cả, Cosplay - R34, Hentai, Game...), nhưng bấm đổi tab/thanh điều hướng không phản hồi (khung hình đứng). Mọi ảnh bìa là biểu tượng giữ chỗ; nhật ký có "Image/network load failed" cho hentaicb.help, vvcz.store, truyenhentai18.net; frama.io không phân giải DNS, vài kho GitHub trả 404 => mạng chỉ hoạt động một phần/ảnh tải lỗi, chưa mở được Duyệt để xác nhận | evidence/QA2/windows/ca2_1.png, ca2_2.png |
| 3-8 | CHƯA KIỂM | Giao diện không nhận thao tác (xem lỗi bên dưới) nên không thực hiện được | - |

Lỗi/quan sát riêng:
- R21 gặp 5/5 lần khởi động: cửa sổ trắng từ giây đầu (không thấy splash), kéo dài >3 phút; một lần (khởi động bằng computer_open_application) sau ~2 phút hiện Thư Viện nhưng khung hình đứng: nhấp tab, nhấp Booru, cuộn, nút thu nhỏ đều không phản hồi, dù tiến trình báo Responding=True và nhật ký vẫn ghi hoạt động (tải ảnh lỗi lúc 15:02, 15:04). Nghi: raster/GPU bị nghẽn do qemu chiếm máy, hoặc lỗi vẽ lại của Flutter trên cửa sổ không được kích hoạt.
- Nút X cửa sổ đóng chậm/không đóng ngay; bản chạy trước vẫn sống khi job dừng tiến trình lọc theo đường dẫn D:\yh\* (đường dẫn thực là D:\A.I Project\yh\...), nên có thể từng có nhiều thể hiện chồng nhau trong các lần thử đầu.
- Đề nghị chạy lại các ca khi emulator Android tắt.

## Android/TV (S-A)
Điện thoại: AVD YomiHub056_Phone_API34 (720x1280, x86_64 APK, versionName 0.5.6). TV: AVD YomiHub_TV_API34 là x86 32-bit nên bản x86_64 bị INSTALL_FAILED_NO_MATCHING_ABIS; dùng APK TV armeabi-v7a (cài được, chạy được). Ảnh trong evidence/QA2/android/.

| Ca | Nền tảng | Kết quả | Mô tả ảnh | Đường dẫn |
|---|---|---|---|---|
| 1 Cài đè + khởi động | Phone | ĐẠT (cài mới/pm clear, không phải cài đè bản cũ) | Nền xanh đen, logo tròn bo (sách mở + nút play) giữa màn | c1_splash_1.png; sau đó c1_after.png = Thư viện |
| 2 Thư viện tab/vuốt | Phone | KHÔNG ĐẠT / cần xác minh | Thư viện chỉ có tiêu đề "Truyện tranh", "Thư viện trống"; không thấy thanh tab Phim/Tiểu thuyết/Play Books dù Phim đang bật; vuốt ngang không đổi gì | c2_1.png, c2_3.png, c2_features.png |
| 3 Giao diện Cũ→Mới→Cũ | Phone | ĐẠT | Cũ (nút Cũ sáng) → Mới (mô tả đổi thành "Hoạt động...", nút Mới sáng) → Cũ | c3_cu_1.png, c3_moi.png, c3_cu_2.png |
| 4 Số bản sao lưu | Phone | ĐẠT | Sao Lưu & Đồng Bộ: "Số lượng bản sao lưu: Không giới hạn" | c4_backup.png |
| 5 Kiểm Tra Cập Nhật tiện ích | Phone | ĐẠT (bằng chứng toast = uiautomator dump) | Ảnh c5_check_1 có toast "Đang kiểm tra cập nhật tiện ích…"; toast kết quả "Kho thành công: 1. Kho lỗi: 0." chỉ bắt được trong dump (ảnh chụp trễ khung) | c5_check_1.png, c5_u1.xml |
| 6 Nguồn→danh sách→truyện→đọc | Phone | ĐẠT (nguồn tiếng Anh) | Cài ComicK (Kotatsu); lưới bìa tải đủ (Blue Lock, Hero Killer); chi tiết Hero Killer 182 chương; trình đọc trang 1/102 rồi 3/102 hiện tranh | c6_list.png, c6_detail.png, c6_reader3.png, c6_reader4.png |
| 7 Video resume | Phone | CHƯA KIỂM — chưa cài tiện ích Phim/nguồn video, hết thời gian | | |
| 8 Nhật ký ứng dụng | Phone | ĐẠT một phần | Không có mục tên "Nhật Ký ứng dụng"; có Giới thiệu › "Báo cáo lỗi" (log lỗi) mở được, trống "Chưa có lỗi nào" | c8_log.png |
| 9 TV không Truyện tranh/Tiểu thuyết/Play Books/Booru | TV | ĐẠT | Rail: Thư viện, Cập nhật, Duyệt, Thêm; nội dung "Thư viện Phim & Điện ảnh đang trống". grep tv*.xml không khớp 4 tên | tv9_home.png, tv9_home.xml |
| 10 D-pad | TV | ĐẠT một phần | Left+Down+Enter chuyển sang Cập nhật ("Không có cập nhật gần đây"); chưa đi hết Duyệt/Thêm (chuỗi phím lệch, hiện hộp "Xóa tất cả") | tv10_nav_browse.png, tv10_nav_more.png |
| 11 TV phát video | TV | CHƯA KIỂM — không có nguồn video, hết thời gian | | |

### Lỗi/ghi chú thấy được
- Lần mở đầu cả phone lẫn TV chuyển sang màn hệ thống "Allow access to manage all files"; trên TV bị kẹt ở màn Settings (D-pad), phải cấp bằng `appops set --uid ... MANAGE_EXTERNAL_STORAGE allow`.
- Thư viện không hiện thanh tab loại nội dung (ca 2).
- Chữ chưa dịch: "Cloudflare Bypass Setting", "Theme mode option button", tên theme "Material 2 default/high contrast/Blue delight".
- Duyệt › Tiện ích: tìm kiếm chỉ ra kết quả sau khi bấm Enter (gõ xong để trống).
- Trình đọc trang 1 trống nửa dưới khi vừa mở (ảnh đang tải).
- Hạ tầng: emulator bị chết 3 lần giữa chừng (có thể do tiến trình khác trên máy); "System UI isn't responding" xuất hiện một lần khi emulator tải nặng (c1_after.png), không phải lỗi app.

## Điện thoại thật (Xiaomi, Android 16)
Máy K75THMJVHA95EARO, 25069PTEBG, màn 1280x2772. Ảnh/dump trong evidence/QA2/phone/. Lưu ý: cửa sổ nổi của ứng dụng khác (video "MEMEL...", không phải YomiHub) che góc trên phải mọi ảnh.
flutter test sau sửa R22-R24 (fix/test.log): 680 đạt, 0 trượt.

| Ca | Kết quả | Mô tả ảnh | Đường dẫn |
|---|---|---|---|
| 0 Cài đè 0.5.6 | ĐẠT | trước 0.5.5/2047, sau 0.5.6/2048 (theo điều phối, log qp_02) | jobs/done/qp_02.log |
| 1 Mở app + Giới thiệu + thư viện | ĐẠT | Thư Viện còn đủ truyện (lưới bìa, nhiều bìa lỗi ảnh); Giới thiệu: "Phiên bản Beta (0.5.6)" | c1_home.png, c1_about.png |
| 2 R22 tab loại nội dung | ĐẠT (giao diện Cũ) / KHÔNG ĐẠT (giao diện Mới) | Cũ: dải tab "Truyện tranh | Phim & Điện ảnh..." hiện; bấm sang Phim & Điện ảnh ra lưới phim/tập, tiêu đề "Phim & Điện ảnh". Mới: Thư Viện/Thêm/Duyệt chỉ hiện thanh điều hướng nổi giữa màn (y~1200-1380), phần thân TRỐNG, uiautomator chỉ có 5 nút; lặp lại sau khởi động lại app | c2_phim.png, c2_moi_lib.png, c2_moi_lib2.png, moi_restart.png, moi_more2.png |
| 3 Đọc 1 chương | CHƯA KIỂM | bị chặn: máy đang ở giao diện Mới (thân trống) | |
| 4 Phim resume | CHƯA KIỂM | như ca 3 | |
| 5 Số bản sao lưu | ĐẠT | Sao Lưu & Đồng Bộ: "Số lượng bản sao lưu: Không giới hạn" (tần suất Mỗi 6 giờ) | c5_backup.xml (png lỗi chụp) |
| 6 Kiểm Tra Cập Nhật tiện ích | CHƯA KIỂM | như ca 3 | |
| 7 Văng app | Không thấy app văng | crash buffer có 0 dòng yomihub ngày 11/11 (xem crash.txt) | crash.txt |

### CẢNH BÁO: công tắc Giao diện CHƯA ĐƯỢC TRẢ LẠI
Ban đầu "Giao diện ứng dụng" = Cũ. Đã chuyển sang Mới (c2_moi_set.png) và không thể trả lại vì giao diện Mới không hiện thân màn nên không mở được Cài đặt. Chủ dự án cần tự vào Thêm > Cài đặt > Giao diện > chọn "Cũ" (hoặc mở lại màn Mới nếu hiện được). Tôi không xoay màn hình/đổi cài đặt hệ thống (bị chặn), không bấm mò.
Lỗi nghi vấn: giao diện Mới trên Android 16 (1280x2772) không vẽ nội dung các tab (có thể mới từ 0.5.6).
Ghi chú hạ tầng: job .ps1 thường chết (EXIT 1) ngay sau `monkey`/`input keyevent`; chụp ảnh sau uiautomator dump không lưu được, nên chụp trước.

## Điện thoại thật — đợt 2 (Xiaomi K75THMJVHA95EARO, Android 16, giao diện Cũ)
DỪNG GIỮA CHỪNG: máy bị khóa màn hình bằng bàn phím nhập mã (qa3_b2.png) lúc 22:39 nên không làm tiếp (theo quy định).
| Ca | Kết quả | Ghi chú | Ảnh (evidence/QA2/phone/) |
|---|---|---|---|
| 1 Đọc chương | CHƯA KIỂM | Chạm vào ô "Chúng Ta Sốn..." ở Truyện tranh › Lịch Sử Đọc: sau 3 và 180 s màn vẫn là lưới, không mở trang đọc, không có thông báo lỗi (có thể chạm không ăn hoặc đang tải; chưa kết luận). Chưa thử mục thứ 2-3. | qa3_c1_detail.png, qa3_c2.png |
| 2 Phát tiếp video | ĐẠT | "Tên Cậu Là Gì?" (RoPhim VI) phát bình thường, thanh tiến độ 01:31:38 → 01:31:43 (play1/play2). Thoát bằng nút mũi tên trong trình phát ở 01:44:30 (e1_time), mở lại tập "Full": vào ngay 01:44:33, đang phát (v4_resume). Có quay video 25 s (qa3_resume.mp4, đã rm trên máy). Lưu ý: nhấn phím BACK hệ thống trong trình phát đưa app ra màn hình chính với cửa sổ PiP, video vẫn phát (v3_*); lần đó chạm mù đã mở nhầm ứng dụng GitHub (không đổi dữ liệu gì), đã thoát. | qa3_v2_play1/2.png, qa3_e1_time.png, qa3_v4_resume.png, qa3_resume.mp4 |
| 3 Kiểm Tra Cập Nhật | CHƯA KIỂM | máy khóa | |
| 4 Ảnh bìa | MỘT PHẦN | xem dưới | qa3_s0.png, qa3_t2.png, qa3_t3.png, qa3_v1_detail.png |

### Ảnh bìa (bằng chứng một phần, nguyên nhân CHƯA chứng minh)
- Truyện tranh (Lịch Sử Đọc): hầu hết ô là biểu tượng ảnh gạch chéo (qa3_s0.png).
- Phim & Điện ảnh › Anime: bìa hiện bình thường gần như toàn bộ (qa3_t3.png); trang chi tiết RoPhim cũng hiện bìa (qa3_v1_detail.png). Lịch Sử Xem: một số hiện, một số gạch chéo (qa3_t2.png).
=> Lỗi phụ thuộc NGUỒN/tên miền ảnh, không phải ảnh bìa nói chung hỏng, không phải mất mạng/DNS toàn máy (Wi-Fi vẫn tải được video và bìa anime). Nghi vấn: tên miền ảnh của nguồn truyện đã đổi/chặn hotlink/Cloudflare. Chưa có log xác nhận: `logcat -d | grep ...` trả về 0 dòng (qa3_logcat.txt rỗng, bộ đệm đã quay vòng). Chưa mở nguồn trong Duyệt, chưa lấy Nhật ký ứng dụng.
Việc tiếp: mở khóa máy, bật logcat -c rồi mở Thư Viện/Duyệt cuộn để ghi lại lỗi tải ảnh; xem URL ảnh bìa của 1 truyện (Webview/chi tiết).

## Windows — đợt 2 (sau R25) — build Release 0.5.6+48 (22:25)
Chạy ~30 phút, chưa hết các ca (bị chặn bởi đóng băng giao diện + cửa sổ trắng R21 sau khi khởi động lại). Máy không có qemu/emulator.
| Ca | Kết quả | Ghi chú |
|---|---|---|
| 1 Giao diện chính | ĐẠT (lần mở đầu) | Mở 22:39:44; giao diện hiện đủ (thanh bên Thư viện/Booru/Cập nhật/Duyệt/Thêm/Theo dõi, lưới truyện) khi chụp lúc ~22:45 (chưa đo chính xác thời gian chờ, <=5 phút). Không có ảnh lưu bản sao (chỉ xem trực tiếp). |
| 2 Thư Viện dải tab loại nội dung | KHÔNG KIỂM ĐƯỢC | Ở chế độ giao diện hiện tại (thanh bên trái) Thư viện chỉ có tiêu đề "Truyện tranh" + dải danh mục người dùng (Lịch Sử Đọc, Tất Cả...), không thấy dải Truyện tranh/Phim/Tiểu thuyết/Play Books; chưa thử chuyển chế độ khác. Chưa bấm sang Phim. |
| 3 Đổi Giao diện | CHƯA KIỂM | hết thời gian, không đổi cài đặt nào (không cần trả lại). |
| 4 Sao Lưu & Đồng Bộ | ĐẠT | "Số lượng bản sao lưu" = "Không giới hạn" (zoom xác nhận). Ảnh: windows2/c4_saoluu.png (đã bị cửa sổ khôi phục nên nội dung cắt, xem lại bản chụp màn hình). |
| 5 Kiểm Tra Cập Nhật | CHƯA KIỂM | |
| 6 Phản hồi thao tác | KHÔNG ĐẠT (nghi lỗi) | Sau khi cửa sổ chuyển Phóng to -> Khôi phục (công cụ chụp gọi ShowWindow restore) rồi Phóng to lại, nội dung Flutter không vẽ lại: layout kẹt kích thước cũ bị cắt, vùng đen, bấm nút Quay lại không phản ứng dù Responding=True (đứng hình). Khởi động lại 2 lần: cửa sổ trắng > 2,5 phút (lần 1) và >2 phút (lần 2, chưa hết) -> R21, không tính. Cần người dùng xác minh trực tiếp thao tác đổi cỡ cửa sổ. Ngoài ra máy đang có cửa sổ khác (ChatGPT, Antigravity) chen foreground làm gián đoạn. |

## Ca cuối Android (23:xx - 00:15, Sonnet)
Thiết bị: điện thoại thật K75THMJVHA95EARO đang khóa bằng bàn phím mã (a_home.png) -> bỏ qua, không đụng. Dùng AVD YomiHub056_Phone_API34 (APK x86_64 0.5.6 build 21:12, cài Success). Ghi chú: job cũ 0_qa3_avd1 thực ra cài nhầm vào điện thoại thật (chỉ có 1 thiết bị) và bị INSTALL_FAILED_NO_MATCHING_ABIS (không thay đổi gì); emulator khởi động từ job bị chết khi job kết thúc nên phải chạy trong một job "server" sống lâu.
- Ca 2 Kiểm Tra Cập Nhật: ĐẠT. Toast "Kho thành công: 1. Kho lỗi: 0." -> evidence/QA2/final/g4_chk1.png (g4_chk2.png).
- Ca 1 Đọc chương: KHÔNG HOÀN THÀNH (hết giờ). Đã cài tiện ích MangaDex (Kotatsu) thành công (h2_inst.png) và mở tab Nguồn có MangaDex (i1_src.png); chưa mở truyện/chương/ảnh trang. Không có kết luận ĐẠT/KHÔNG ĐẠT.
AVD đã tắt (emu kill).
