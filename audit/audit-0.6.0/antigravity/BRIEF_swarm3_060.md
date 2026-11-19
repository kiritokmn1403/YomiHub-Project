# BRIEF /swarm 3 – YomiHub 0.6.0 (19/11/2026 14:10)
[Claude (Anthropic) điều phối thay mặt Kiệt – chủ dự án yêu cầu giao 1 phần việc kiểm thử + 1 phần việc khác cho Antigravity]

Đọc trước (chỉ các tệp này, không quét thư mục): `A.I Brain - Second Brain/07_performance_rules_cac_quy_tac_thuc_hien.md`, `05_testing_kiem_tra.md`; `audit/audit-0.6.0/release/YomiHub-0.6.0-changelog.md`; mục "### 14." cuối `TECHNICAL_UPDATE_NOTES.md`.

## QUY TẮC CỨNG
- Máy đang dựng bản Windows/android6 (job `x060_build_main5`): KHÔNG chạy flutter/dart/gradle, KHÔNG mở trình giả lập, KHÔNG đụng `jobs/`, `build/`, `overlay/`, `D:\yh\`, `src/`, `docs/`, `README.md`. KHÔNG git commit/push.
- CẤM liệt kê/tìm đệ quy (`ls -R`, `Get-ChildItem -Recurse`, `dir /s`) trên `D:\A.I Project`, `D:\yh`, `src/`, `overlay/` (19/11 sáng làm nghẽn ổ đĩa 1,5 giờ). Grep chỉ đúng thư mục con cần (vd. `overlay/lib/yomihub/filters`), có giới hạn thời gian.
- Chỉ ghi trong `audit/audit-0.6.0/antigravity/`.
- Không nhập mật khẩu/tài khoản, không đăng nhập Google/GitHub, không giải CAPTCHA/Cloudflare. Không ghi token/mật khẩu vào tệp.
- Mỗi tác tử ghi `NOTES_swarm3_<tên tác tử>.md` NGAY TỪ ĐẦU, thêm 1 dòng sau mỗi bước (giờ + việc + kết quả). Kết thúc: `SUMMARY_swarm3_060.md`. Thời hạn 45 phút.
- Không ghi "ĐẠT" khi không có ảnh/log thật.

## @device_tester – Kiểm thử YomiHub 0.6.0 (2053) trên Samsung Note 9 qua adb
- adb: `D:\yh\tools\android-sdk\platform-tools\adb.exe -s 281038ac31217ece`. Ứng dụng đã cài sẵn 0.6.0 (`com.yomihub.app`). Claude KHÔNG dùng Note 9 trong lúc này.
- KHÔNG cài/gỡ app, KHÔNG xóa dữ liệu, KHÔNG xóa/sửa mục thư viện, KHÔNG đăng nhập tài khoản. Trước mỗi chuỗi chạm: chụp màn hình/`uiautomator dump` để chắc đúng màn (có thể có hộp thoại hệ thống đè lên).
- Ảnh: `adb exec-out screencap -p > audit\audit-0.6.0\antigravity\test_note9\<số>_<tên>.png`; dump xml cùng thư mục. Tự mở ảnh xem trước khi kết luận. Thư viện có bìa 18+ → ghi chú ảnh nào KHÔNG dùng công khai.
- Kịch bản:
  1. **Bộ lọc kiểu Kotatsu dạng ô chọn**: Duyệt › Nguồn → tìm nguồn có chữ "(Kotatsu)" (vd. CManga, Làng Geek, TopTruyen…) → mở → "Bộ lọc": xác nhận Sắp xếp/lựa chọn là ô chọn (không còn chip), bấm chọn 1 mục chọn-một, bấm 1 thể loại 2 lần (ô xanh có dấu ✓ → ô đỏ loại trừ), bấm "Bộ lọc" áp dụng → có kết quả hay lỗi (ghi lỗi).
  2. **Trang Cập nhật** (tab Cập nhật): mở, cuộn 3 lần → không giật/treo; sau đó kiểm log không có dòng "Giao diện bị treo … /updates".
  3. **Sao Lưu Lên Google Drive**: Thêm › Dữ liệu & Bộ nhớ (hoặc Sao Lưu & Đồng Bộ) → mục "Sao Lưu Lên Google Drive" có logo Google → mở màn hình (KHÔNG bấm đăng nhập).
  4. **Gợi ý kho tiện ích**: Duyệt › Tiện ích/Kho tiện ích (hoặc Cài đặt › Duyệt › Kho tiện ích) → có gợi ý "Salmanbappi" và "Secozzi" không.
  5. **Trình duyệt › Savior "Quét mã trang tìm link video"**: mở trình duyệt trong app, vào trang công khai có video (vd. https://test-streams.mux.dev/ hoặc https://www.w3schools.com/html/html5_video.asp) → Savior → "Quét mã trang tìm link video" → có tìm ra link m3u8/mp4 không (ảnh).
  6. **Log**: `adb pull /sdcard/YomiHub/logs.txt test_note9\logs_after.txt` → từ dòng "Logger initialized" CUỐI, liệt kê mọi WARNING/ERROR (bỏ các dòng tải ảnh CDN lặp) vào `test_note9/LOG_REVIEW.md`.
- Báo cáo: `test_note9/REPORT_device_060.md` – bảng: kịch bản | kết quả ĐẠT/LỖI/CHƯA KIỂM | ảnh | ghi chú.

## @doc_writer – Bản nháp tài liệu phát hành 0.6.0 (chỉ nháp, Claude duyệt rồi mới đưa vào)
1. `docs_draft/YomiHub-0.6.0-changelog.en.md`: bản tiếng Anh đầy đủ, sát nghĩa của `release/YomiHub-0.6.0-changelog.md` (giữ cấu trúc mục, không thêm tính năng).
2. `docs_draft/pages_060_changes.md`: đề xuất đoạn bổ sung cho trang chủ `docs/index.html` và README (tiếng Việt) về các tính năng mới 0.6.0 (bộ lọc ô chọn, Sao lưu Google Drive, Savior quét link video, Short Video thêm trang, gợi ý kho Salmanbappi/Secozzi). Với MỖI câu khẳng định: ghi kết quả grep chứng minh (lệnh + đường dẫn tệp trong `overlay/lib/...`). Không bịa tính năng (bài học: README do tác nhân viết từng ghi sai VLC/OpenDyslexic).
3. Đọc `docs/index.html` (chỉ đọc) để nêu chính xác vị trí chèn (thẻ/heading gần nhất).
