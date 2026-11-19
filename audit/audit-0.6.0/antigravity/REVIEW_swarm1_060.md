# Claude duyệt kết quả /swarm 1 (19/11/2026 09:55) – CHƯA ĐẠT, làm lại (/swarm 2)

Kết quả đợt 1 chỉ là khung (FEATURE_GAP có "?", "[ ]" không kèm đường dẫn; repo_suggestions chỉ chép lại kho có sẵn; update_sources chỉ liệt kê tên; DESIGN_SPEC ~1 KB; ports/m3u8_downloader.dart là chỗ trống). Không dùng được để tích hợp.

## Tiêu chí ĐẠT cho /swarm 2 (bắt buộc)
### @project_scanner → `ports/FEATURE_GAP_060.md` (≥ 8 KB)
- Mỗi dự án: đọc README + cây thư mục thật trên GitHub (ghi URL đã đọc), liệt kê ≥ 5 tính năng cụ thể (vd. Yomikiru: đọc thư mục/CBZ/EPUB cục bộ, chế độ đọc dọc/trang đôi, AniList, phím tắt, lịch sử…; Zenshin: phát anime qua torrent/WebTorrent + AniList; Nuvio: addon Stremio, trakt; Nyora: …; Frank Yomik: OCR + dịch + chèn chữ vào ảnh).
- Với MỖI tính năng: YomiHub đã có chưa → kèm kết quả `grep -rln "<từ khóa>" overlay/lib/<thư mục con>` (đường dẫn tệp thật) hoặc "không tìm thấy (đã grep: …)".
- Đề xuất P1 ≤ 6 mục có thể làm bằng Dart/Flutter trong 1 ngày, mỗi mục: tệp overlay sẽ sửa/thêm, API dùng, rủi ro.
- KHÔNG viết mã chỗ trống. Savior (trình duyệt) đã có tải HLS/chọn chất lượng – đừng đề xuất lại.
### @repo_checker → `repo_check_060.md` + `repo_suggestions_060.json`
- Với 14 kho + Salmanbappi + Secozzi + codeberg/jsdelivr/kohiden: chạy thật `curl -sSL -m 25 -o NUL -w "%{http_code} %{size_download}"` (hoặc Invoke-WebRequest) – ghi mã HTTP, kích thước, số tiện ích đếm được trong index.
- 13 website: tải trang, trích các URL kho (`index.min.json`, `index.json`, `.pb`, `plugins.min.json`, `repo.json`, `plugin.json`), loại các kho ĐÃ CÓ trong `overlay/lib/yomihub/repos/repo_discovery.dart` → chỉ ghi kho MỚI (url, loại engine, website nguồn, HTTP OK?).
- 8 nguồn cập nhật: gọi thật (GitHub API releases/latest; Drive `embeddedfolderview?id=`; MediaFire `api/1.5/folder/get_content.php?folder_key=…&content_type=files&response_format=json`) → ghi HTTP, có thấy tệp 0.5.9 không.
### @ui_designer → `ui_new/DESIGN_SPEC_060.md` (≥ 10 KB) + mã Dart thật
- Đọc mã Mangayomi v0.9.96 (lib/modules/main_view, library, manga/detail, more/settings) – ghi đường dẫn tệp upstream đã đọc và thay đổi giao diện cụ thể so với 0.9.95.
- Đặc tả từng màn (Thư viện, Cập nhật, Lịch sử, Duyệt, Thêm, Chi tiết + "Chọn nguồn đọc" cho bộ hợp nhất, Trình đọc, Cài đặt): bố cục, kích thước (dp), màu (ColorScheme), chữ, bo góc, hiệu ứng; khác biệt Android / Android TV (D-pad, focus) / Windows (rộng ≥ 1000 px: thanh điều hướng trái).
- Mã Dart (Flutter 3.47, Material 3) cho ít nhất: thanh điều hướng mới (điện thoại + NavigationRail Windows/TV), thẻ truyện lưới, tiêu đề mục, AppBar tìm kiếm – mỗi widget nhận `bool newStyle` để giữ chuyển đổi Cũ/Mới; `INTEGRATION.md` nêu chính xác tệp overlay sẽ nối (đã grep).
Thời hạn: 60 phút. Ghi NOTES sau mỗi bước, kết thúc `SUMMARY_swarm2_060.md`.

## QUY TẮC BỔ SUNG (Claude, 19/11 11:30) – BẮT BUỘC
- 10:08 các tác tử /swarm đã chạy 3 lệnh PowerShell `ls -R` / `Get-ChildItem -Recurse` trên TOÀN BỘ `D:\A.I Project` (1.500–2.700 s CPU, ổ đĩa nghẽn 300–580 %, làm treo mọi bản dựng 1,5 giờ) → Claude đã dừng theo yêu cầu chủ dự án.
- CẤM liệt kê/tìm đệ quy cả `D:\A.I Project`, `D:\yh`, `src/`, `overlay/` không giới hạn. Chỉ grep đúng thư mục con cần (ví dụ `overlay/lib/yomihub/repos`), dùng `Select-String -Path <thư mục cụ thể>\*.dart`, luôn có giới hạn thời gian.
