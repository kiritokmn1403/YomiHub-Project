# NOTES_P1 – Cài đặt & Hợp nhất (U3, U4, FC37, FC38, FC41)

Hai lượt chạy: lượt 1 (cắt do giới hạn tốc độ ~10:50, không ghi ghi chú) và lượt 2 (tiếp tục, ghi chú này). Giờ Asia/Saigon, ngày 14/11/2026.

## Yêu cầu
- U3: câu chữ sai ở booru_settings_screen; mọi cài đặt sao lưu (gồm Booru) chỉ ở "Sao Lưu & Đồng Bộ" (Cài đặt + Thêm).
- U4: Google Play Books và Booru App bật/tắt bằng công tắc thật ngay trong "Bật/Tắt tính năng & Nguồn mở rộng".
- FC38: một mục "Hợp Nhất Tiện Ích"; bỏ các ô hợp nhất trùng lặp ở "Dữ liệu và bộ nhớ"; "Hợp nhất nội dung" là mục con; người dùng tự chọn tiện ích để hợp nhất.
- FC37: ở màn chi tiết bộ đã hợp nhất, bộ chọn "Nguồn đọc" (gồm "Tất cả") giữa nút Đề xuất/Liên quan và tiêu đề "N chương"; lưu theo bộ; điều khiển danh sách chương và chương mà nút Đọc/Tiếp tục mở; có ký hiệu hợp nhất.
- FC41: công tắc Truyện / Phim & Điện Ảnh / Tiểu Thuyết và kho.

## Đã có từ trước
Màn "Hợp Nhất Tiện Ích" (extension_merge_screen), bộ chọn nguồn dạng bộ lọc cục bộ (mất khi thoát), chip "Hợp nhất", khối "Tính năng khác" trong feature_toggle_screen chứa hai ô (chỉ là mũi tên), 6 công tắc FC41 + quản lý kho.

## Thay đổi (đường dẫn tính từ overlay/)
Lượt 1:
- lib/yomihub/booru/booru_settings_screen.dart: câu "Sao lưu" đổi thành "(Cài đặt › Sao Lưu & Đồng Bộ)"; thêm `setBooruEnabled(ref,on)`; BooruSettingTile có Switch thật (key booruSwitch).
- lib/yomihub/playbooks/playbooks_toggle.dart: thêm `YomiPlayBooks.setEnabled` (pref playBooksEnabled + ẩn/hiện route cùng lúc, cùng khóa pref cũ); PlayBooksSettingTile có Switch thật (key playBooksSwitch).
- lib/yomihub/merge/chapter_origins.dart: `preferredSource`, `setPreferredSource` (lưu theo bộ trong YomiPrefs khóa `mergedReadSource`, nằm trong hộp pref được sao lưu), `pickForReading` (bản của nguồn ưu tiên thắng khi trùng số chương, nguồn khác lấp chương thiếu).
- lib/modules/manga/detail/manga_detail_view.dart: khôi phục lựa chọn khi mở, lưu khi đổi, bỏ lọc nếu nguồn đã biến mất, thêm helperText.
- lib/modules/manga/detail/manga_details_view.dart: nút Đọc (lần đầu) mở chương đầu theo nguồn ưu tiên.
- lib/utils/extensions/manga_extensions.dart: `getChapterListForReading` dùng `pickForReading` khi có nguồn ưu tiên (ảnh hưởng chương kế tiếp trong trình đọc).
- lib/yomihub/merge/extension_merge_screen.dart: thẻ "Công cụ hợp nhất" gồm CustomMergeSourcesTile, MergeDuplicateMangaTile, ManualMergeMangaTile, "Hợp nhất nội dung" (/contentMerge).
- lib/modules/more/data_and_storage/data_and_storage.dart: bỏ 3 ô hợp nhất, thay bằng một lối tắt "Hợp Nhất Tiện Ích" (/mergeExtensions).
- test/yh_057_p1_test.dart (mới), notes/i18n_P1.json (chuỗi mới).
Lượt 2:
- lib/modules/more/settings/settings_screen.dart (đã sao lưu vào audit-0.5.7/backup/src_0571/lib/modules/more/settings/): bỏ mục "Hợp nhất nội dung" riêng; mục "Hợp nhất tiện ích" dùng phụ đề mới.
- lib/modules/manga/detail/manga_detail_view.dart: nhãn "Chọn nguồn" -> "Nguồn đọc", thêm biểu tượng call_merge.
- test/yh_057_p1_test.dart: thêm 3 test (Cài đặt không còn lối /contentMerge thứ hai; nhãn + vị trí bộ chọn sau _DetailActions; FC41 các công tắc).
- audit-0.5.7/notes/i18n_P1.json: thêm khóa "Nguồn đọc" (18 ngôn ngữ). Tổng 5 khóa mới; KHÔNG sửa 18 tệp i18n (P8 gộp).
- feature_toggle_screen.dart không sửa (đã chứa hai ô, giờ có Switch thật). more_screen.dart không sửa (đã có lối /mergeExtensions).

## Công cụ
git diff, python đọc-sửa-ghi, job `jobs/pending_fast/p1b_test1.ps1` (Sync-Overlay + `flutter.bat analyze --no-pub` + Run-Tests).

## Kết quả (trích log jobs/done/p1b_test1.log, 14/11/2026)
- Analyze 10 tệp: "17 issues found" – 0 error; toàn warning/info có sẵn (unnecessary_non_null_assertion, unused_import ở extension_merge_screen, curly_braces...). Exit 1 do cảnh báo.
- Test: "00:03 +17: All tests passed!" (yh_057_p1_test + yh_039_merge_test), TEST EXIT 0.
- Lượt 1 (x1_p1_test1.log): 45/45 đạt, gồm yh_049/050/053 khi các tệp i18n đã có chuỗi.
- Lượt 2 KHÔNG chạy lại yh_049 (chuỗi mới "Nguồn đọc" chưa gộp vào 18 tệp i18n nên sẽ trượt cho tới khi P8 gộp).

## Còn lại / hạn chế
- Các kiểm chứng giao diện là test đọc mã nguồn + logic thuần; chưa có test widget/chạy trên máy thật, chưa thử với extension repo của sheet Merge.
- Nút "Tiếp tục" (resume) mở đúng chương lịch sử gần nhất, không đổi nguồn; chỉ nút Đọc lần đầu và chương kế tiếp trong trình đọc theo nguồn ưu tiên. Chưa áp dụng cho tải chương, TV anime view, chưa có dự phòng khi nguồn lỗi.
- Nhãn "Hợp nhất" trong chip còn là chuỗi không qua tr() (có sẵn từ trước).
- Bộ chọn chỉ hiện khi bộ có ≥2 nguồn.
- Mục "Bật/Tắt tính năng" vẫn chỉ ở Cài đặt, chưa ở menu Thêm (cần chủ dự án xác nhận).
- Cảnh báo analyze có sẵn chưa dọn (ngoài phạm vi).
