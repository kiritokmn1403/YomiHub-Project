# NOTES_QA1

- 14:39 bat dau; doc tai lieu.
- 14:55 flow01 OK (video+timeline anh, splash~2s + loading~4s)

## Phuong phap (14/11/2026, may that Note 9 SM-N960N, serial 281038ac31217ece)
- qa/qa_lib.ps1: thu vien adb (Shot, Ui dump, TapText theo regex nhan semantics, Back, Swipe, Launch/Stop, Result...). Moi flow la mot "body" qa/flow_NN_*.ps1; qa/submit.sh <ten> <phut> <body> ghep tieu de + CRLF/BOM thanh jobs/pending_fast/qa1_<ten>.ps1 roi doi log.
- Chay lai tren APK moi: qa/run_all.sh (xem cuoi tep). Ket qua: qa/results_qa1.txt, qa/run_qa1.log, anh trong evidence/phone/qa1/.
- Van de: runner fast chung, job dai cua tac nhan khac (p7f_q1 45 phut) chan hang doi -> flow cho.
- Luu y: ung dung khoi phuc ve trang chi tiet 1 tieu de 18+ trong thu vien chu (anh 00_probe.png co bia 18+; khong mo them tieu de 18+).
## Flow 1 - khoi dong
- Quay video 01_launch.mp4 + timeline 01_launch_timeline.png (ffmpeg 1 fps): man native splash ~2 s -> man tai YomiHub "Dang khoi dong..." ~4 s -> Thu vien (~6 s tu luc bam mo). Anh 01_launch_t03s.png (man tai), t05s (da vao Thu vien). Da xem. KET QUA: DAT. Ghi chu: 2 bia truyen hien icon loi anh (mang/bia).
## Flow 2 (lan 1) - SAI KICH BAN: app dang o trang "Them" nen 4 anh tab deu la trang Them. Da sua flow_02 (bam 'Thu vien Tab 1' truoc). Thanh tab Truyen tranh/Phim/Tieu thuyet/Play Books KHONG co trong cay uiautomator -> bam toa do (y=158).
## Flow 3 - Bo loc/Sap xep/Hien thi sheet mo-dong x25 (nut loc o 1187,343): anh 03_montage.png (truoc | mo lan 1 | mo lan 25 | sau vong lap) da xem: sheet hien Bo loc/Sap xep/Hien thi, khong sap. logcat -c truoc, logcat -d sau: 0 dong 'Null check'/FATAL/_IndicatorPainter (03_logcat.txt). KET QUA: DAT (build dev 0.5.7+50).
## Flow 2 (lan 2) DAT: 02_tabs_montage.png (4 tab: Truyen tranh/Phim & Dien anh/Tieu thuyet/Play Books; Play Books = Google Play Sach WebView, nav Trang chu/Thu vien/Cua hang/Sach noi - dev build chua co goi PB).
- 23:08 tiep tuc (phien 2): flow2 4 tab da DAT truoc do; con doi Cu<->Moi; flow4 reader chua co bang chung
- 23:11 Flow 2 DAT (xem 02_tabs_montage, 02_ui_new_montage, 02_ui_new_library, 02_ui_old_home). Flow 4 lan 1: 04_reader_1 = man 'Da xay ra loi RhttpConnectionException api.comick.fun' (khong phai reader) -> KHONG tinh dat; thu lai tu Lich su
- 23:27 Flow 4: CHUA DAT/CHUA CHAY. Lan truoc loi mang; thu lai qa/flow_04b_reader.ps1 (da xep qa1_04b trong pending_fast) nhung runner fast ngung tu 23:08. Chua lam vong 10 lan mo/dong cai dat reader, chua logcat.
- 00:02 Flow4 va Flow9: CHUA DAT/bi chan - xem RESULTS_QA1_dev.md (anh MangaDex khong tai; player Phim khong phat)
- 07:54 [release] Bắt đầu test APK phát hành 0.5.7+50 trên Note 9: cài đè giữ dữ liệu.
- 07:58 [release] Flow 1 cài đè OK (versionName 0.5.7, code 2050, update 07:55), video khởi động + timeline đã xem: splash -> màn tải YomiHub -> Thư viện.
- 07:59 [release] Flow 4: Lịch sử giờ có 4 mục truyện (không còn Shirley Madison); mở mục đầu 'Chị Gái Tôi Và Người Khổng Lồ' Ch.15.6.
- 08:00 [release] Flow 4: mục Lịch sử mở ra 'Lỗi: không có trang nào' (r04d_a); chuyển sang duyệt MangaDex (VI) để mở chương mới.
- 08:01 [release] Flow 4: MangaDex (VI) tải được danh sách (Tôi Thăng Cấp Một Mình, Slime, Frieren...); mở 'Slime' để chọn chương.
- 08:02 [release] Flow 4: Slime (MangaDex VI) có 0 chương nên không đọc được; thử 'Tôi Thăng Cấp Một Mình'.
- 08:03 [release] Flow 4: Solo Leveling (MangaDex VI) cũng 0 chương sau kéo-làm-mới; thử tìm 'Shirley Madison' qua tìm kiếm nguồn.
- 08:04 [release] Flow 4: Shirley Madison (MangaDex VI) có 12 chương; mở Vol.2 Ch.11 để xem ảnh trang.
- 08:05 [release] Flow 4: reader mở được (13 trang, menu hiện khi chạm giữa) nhưng trang 1 vẫn quay spinner sau ~20 s; đang chờ thêm + xem logcat.
- 08:05 [release] Flow 4: trang 1 vẫn spinner ~40 s, không có lỗi flutter trong logcat; thử ping CDN + nút tải lại.
- 08:06 [release] Flow 4: ảnh trang vẫn không tải (spinner treo, không báo lỗi); điện thoại ping api.mangadex.org = unknown host (DNS hệ thống), ping google OK. Chuyển sang vòng mở/đóng cài đặt reader x10.
- 08:08 [release] Flow 4b: sheet cài đặt reader mở/đóng x10 ĐẠT (đã xem ảnh r04q_settings_open1/open10, logcat không có Null check/FATAL). Nhưng ẢNH TRANG vẫn spinner treo (13 trang) -> chưa PASS phần hiển thị ảnh.
- 08:09 [release] Flow 3: sheet Bộ lọc thư viện mở/đóng x10 ĐẠT (đã xem r03_sheet_open_10.png; logcat không có Null check/FATAL). Bắt đầu Flow 9 (video).
- 08:11 [release] Flow 9: mở Phim 'Goblin Tập 04' (lịch sử 13:08) -> màn đen toàn bộ ở screencap (uiautomator dump không lấy được); kiểm tra bằng screenrecord + dumpsys media_session.
- 08:12 [release] Flow 9: màn đen là do điện thoại tắt màn hình/khoá (screen off) chứ chưa chắc lỗi player; đã bật stayon + timeout 10 phút (cần hoàn nguyên sau test), chạy lại.
- 08:14 [release] Flow 9: BLOCKED - mở Phim Goblin Tập 04, sau 22 s vẫn màn đen + spinner mờ, không thanh điều khiển/không phát (r09g_t22.png); giống bản dev, do nguồn phim. Chuyển Flow 7/15/13/12.
- 08:16 [release] Flow 7 ĐẠT từng phần (đã xem ảnh): Hợp Nhất Tiện Ích, Sao Lưu & Đồng Bộ; Flow 12 VPN & DNS mở được (VPN tắt, 5 mục) ĐẠT. Tiếp: Cài đặt > Bật/Tắt tính năng.
- 08:19 [release] Flow 7 ĐẠT (đã xem r07g_features_bottom: công tắc Google Play Books + Booru App đang bật). Tiếp Flow 15 Play Books.
- 08:19 [release] Flow 15 ĐẠT (đã xem r15_pb.png): tab Play Books có Sách điện tử/Sách nói, nav Trang chủ/Thư viện/Danh sách yêu thích/Cửa hàng; lỗi nhỏ: nhãn 'Danh sách yêu thích' xuống dòng, đè lên biểu tượng. Tiếp Flow 13 nhật ký.
- 08:21 [release] Flow 13 ĐẠT (đã xem r13c_applog.png): Nhật ký ứng dụng + Báo cáo lỗi mở được; log lặp cảnh báo CERTIFICATE_VERIFY_FAILED khi tải kho kohiden.xyz (Android 10); không có dòng nào cho lỗi ảnh reader. Tiếp Flow 2.
- 08:24 [release] Flow 2 ĐẠT (đã xem r02_montage.png): giao diện Mới (thẻ Shiori + thanh nav nổi, nhãn 'Hoạt độ...' bị cắt) và đã khôi phục giao diện Cũ. Thử thêm Booru để cô lập lỗi tải ảnh.
- 08:25 [release] Hoàn tất: ghi audit-0.5.7/qa/RESULTS_QA1_release.md. PASS flow 1,2,3,4b,7,12,13,15; FAIL 4a (ảnh MangaDex treo spinner); BLOCKED 9.

## Retest 12:02 (Sonnet)
- 4a FAIL, 9 BLOCKED, nhãn nav PASS, logcat sạch. Xem qa/RESULTS_QA1_retest.md

## Kiểm lần cuối 0.5.7+50 (13:18-13:38)
Reader MangaDex ĐẠT (page1 ~3 s, reader lật dọc), Thử lại hoạt động (Comick). Video FAIL: vẫn 8 lần tua, đen, Back->PiP. Chi tiết qa/RESULTS_QA1_final.md; bằng chứng evidence/phone/qa1v/.
