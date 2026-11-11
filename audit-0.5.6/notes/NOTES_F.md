# NOTES_F — R21: Windows "cửa sổ trắng" (Claude Fable 5.2)

Thời gian: 11/11/2026 13:45–14:37 (giờ máy). Không sửa mã, không dựng lại, không đóng gói, không git.

## Kết luận
- **Không phải hồi quy mã 0.5.6.** Đây là lỗi hiển thị **chập chờn ở mức máy** (cùng họ với 0.4.4 F / 0.4.5 G): cùng một tệp nhị phân lúc hiện đủ giao diện, lúc trắng, đổi trạng thái theo từng phút mà không cần khởi động lại.
- **Bản đã cài ở `%LOCALAPPDATA%\YomiHub` là 0.5.3+45** (YomiHub.exe 06/11 16:37), không phải 0.5.6. Cửa sổ trắng điều phối thấy lúc 13:10 là của 0.5.3. Event Log 13:42: 0.5.3 văng `flutter_windows.dll` `0xc0000005`/`0xc000041d` offset `0x1e220` khi đóng cửa sổ trắng — đúng chữ ký đã ghi ở 0.4.4.
- 0.5.6+48 (bản dựng `buildwin\...\Release` và bản giải nén từ `output\0.5.6\YomiHub-0.5.6-windows-x64.zip`, `app.so` trùng SHA256 `BE6D5705…`) **hiện đúng giao diện ở cả chế độ Cũ và Mới** khi máy ở trạng thái bình thường.

## Bằng chứng (job `jobs/done/f056_ww1…ww13`, `f056_n1…n6`; ảnh ở `audit-0.5.6/evidence/C/whitewin/`)
| Giờ | Bản | Kết quả |
|---|---|---|
| 13:47 | 0.5.3 đã cài; 0.5.6 buildwin | hiện đủ (`a_installed_screen.png`, `b_build_screen.png`, `b_build_pw.png`) |
| 13:50–14:07 | 0.5.6 portable, 0.5.6 buildwin, **0.5.3 đã cài** | đều trắng 98 % (`p056_more.png`, `r4_*.png`, `r7_*.png`), ~25 lần mở liên tiếp |
| 14:09–14:12 | 0.5.6 buildwin | hiện đủ ×6 |
| 14:12:49–14:14:22 | 0.5.6 buildwin | trắng ×6 |
| 14:14:40–14:36 | 0.5.6 buildwin + portable mới giải nén | hiện đủ ×45 |
- Ở trạng thái trắng: tiến trình `Responding=True`, Dart chạy bình thường (logs.txt vẫn ghi: logger, MAL, tải kho, tải ảnh bìa), stderr rỗng, cửa sổ trắng ngay từ giây thứ 4 và không bao giờ vẽ; đổi kích thước cửa sổ vùng vẽ không theo. Ở trạng thái tốt: khung hình đầu ở ~giây 6.
- Ảnh 0.5.6 đạt: `ok056_01_cu_thuvien.png`, `ok056_02_cu_them.png`, `ok056_04_caidat.png`, `ok056_05_giaodien.png` (Cũ); `ok056_06_giaodien_moi.png`, `ok056_08_moi_thuvien.png` (Mới: bộ chọn dạng viên Truyện tranh/Phim/Tiểu thuyết/Play Books, mục "Hoạt động"); `ok056_10_giaodien_tra_cu.png`, `ok056_11_cu_sau_khi_tra.png` (đã trả về Cũ).

## Đã loại trừ (thử có đối chứng, đều KHÔNG gây trắng)
Tải CPU 100 % (8 và 20 tiến trình quay vòng), chụp màn hình trong lúc khởi động, giải nén zip 125 MB, chạy exe từ đường dẫn mới, Impeller bật/tắt (`YOMIHUB_IMPELLER`), GPU NVIDIA (không dùng: chỉ nạp `igd10iumd64.dll`, nvidia-smi 0 tiến trình), thiếu `yomihub_bin\mes` ở zip nhẹ, RAM trống (2,8 GB lúc tốt lẫn lúc trắng).
## Chưa xác định
Tác nhân bật/tắt trạng thái trắng. Nghi vấn (chưa chứng minh): DWM/DirectComposition với driver Intel Iris Xe 27.20.100.9664 (06/2021) trên Windows Insider build 26300; các ứng dụng chạy nền lúc đó: Samsung DeX, NVIDIA Overlay, computer-use của Claude/Codex, Antigravity. Mọi quan sát là qua `CopyFromScreen`; chưa có người nhìn trực tiếp màn hình lúc trắng.

## Việc không làm / lưu ý
- Không sửa `overlay/`, không CLAIMS, không BUILD_LOCK, không cần dựng lại Windows/APK.
- Gói Windows 0.5.6 hiện có dùng được; ghi chú phát hành nên nêu lỗi đã biết trên máy Intel Iris Xe driver cũ (cập nhật driver / mở lại ứng dụng).
- Bản đã cài vẫn là 0.5.3 → kiểm thử "cài đè Setup.exe 0.5.6" chưa ai làm.
- Kiểm thử Windows phải chụp lại nếu ảnh trắng (thử lại sau 1–2 phút); ảnh trắng không được tính ĐẠT hay KHÔNG ĐẠT.
- Rác để lại (VM không xoá được): `D:\yh\tmp_whitewin\p056_134958`, `x056_*`. Công cụ chụp: `evidence/C/whitewin/_ww.ps1`.
- Khi thử đã chuyển Giao diện Cũ→Mới→Cũ trên dữ liệu thật (`Documents\YomiHub`); đã trả về Cũ. Các lần đóng đều bằng `Stop-Process -Force`.

## 14:21 R25 — kết quả (Sonnet)
- Nguyên nhân gốc: ShioriFloatingNavBar dùng Center không có heightFactor trong Scaffold.bottomNavigationBar -> Center chiếm toàn bộ chiều cao, thanh nằm giữa màn, thân bị ép về 0.
- Sửa: overlay/lib/yomihub/ui/shiori/shiori_nav_bar.dart (Center heightFactor: 1). Không đổi chế độ Cũ/Windows/TV.
- Test: overlay/test/yh_056_c2_ui_test.dart nhóm 'R25' (412x915, Mới + Cũ: thân cao >700, thanh ở đáy) đạt; analyze 0 lỗi (chỉ info); flutter test toàn bộ: 681 đạt, 1 lỗi là test R25 ban đầu thiếu ProviderScope (đã sửa, tệp test chạy lại 15/15 đạt; chưa chạy lại toàn bộ).
- APK: output/0.5.6/YomiHub-0.5.6-arm64-v8a.apk (21:12), đã adb install -r thành công trên K75THMJVHA95EARO (giữ dữ liệu).
- CHƯA chụp được màn hình app: điện thoại đang khóa màn hình (keypad ngày tháng tùy biến), không thể mở khóa. Cài đặt Giao diện vẫn là 'Mới' (chưa chuyển về Cũ). Ảnh r25_khoamanhinh_chan.png là màn khóa.

## 14:30 R25 (cập nhật 21:30) — Điện thoại thật
- Sau cài APK sửa lỗi: chế độ Mới thân Thư viện hiện lưới truyện, thanh nổi ở đáy (r25_1_moi_thuvien.png, r25_2_moi_them.png). Lỗi R25 đã hết.
- Đã chuyển Giao diện về 'Cũ' (r25_3_cu.png); Thư viện Cũ có dải tab (r25_4_cu_thuvien.png). Điện thoại ĐANG Ở 'Cũ'.
- Ca đọc chương: mở mục đầu thư viện (Koigokoro) -> lỗi 'statusCode: 500 / Refresh the chapter list' từ nguồn (r25_5_doc.png); chưa đọc được chương. Phim resume và Kiểm tra cập nhật: chưa làm.

## [17:49] R26 — kết quả (Sonnet)
- Lỗi CÓ THẬT trên gói Windows cũ nhưng KHÔNG phải lỗi mã: overlay đã đúng. Windows Release (app.so 6DD2F121...) dựng từ buildwin còn main_screen.dart/library_hub_bar.dart bản TRƯỚC R22 (md5 khác overlay; thiếu fallback _routerLocation và YomiHubShell). Dải tab nằm trong YomiHubShell dùng chung cho _TabletLayout (rail/desktop) và nhánh mobile, Cũ và Mới (pill=uiModern); chỉ phụ thuộc stripFor(location)>=2 tab. Vì vậy không cần sửa mã; đã chép overlay sang buildwin/build, thêm test R26 (1280x800, Cũ+Mới thấy 'Phim & Điện ảnh', tắt tính năng thì mất tab) vào overlay/test/yh_056_c2_ui_test.dart. analyze lib 0 lỗi; flutter test toàn bộ đạt (676, exit 0). Dựng lại: build_056 -step win + pack exit 0; zip/Setup/full/appx mới 17:42-17:44; app.so mới E77222532604BC284D1467AEF94032D25DF8B73927C88F75048ABE767BDD21F6 = app.so trong YomiHub-0.5.6-windows-x64.zip (khớp). Không dựng APK/TV (không đổi mã dùng chung). Ảnh: evidence/R26/r26_a_8.png (trước: không dải), r26_b_6.png (sau, Cũ: có dải 4 tab). Chế độ Mới không chụp lại (cùng mã; ảnh cũ ok056_08 đã có dải); giao diện Windows không đổi, vẫn Cũ.
