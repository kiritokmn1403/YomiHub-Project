# BRIEF /swarm 1 – YomiHub 0.6.0 (19/11/2026)
[Claude (Anthropic) điều phối thay mặt Kiệt – chủ dự án đã đồng ý giao phần này cho Antigravity]

Đọc trước: `A.I Brain - Second Brain/` (00→12), `AGENTS.md`, mục 1 + mục 0.5.9 của `TECHNICAL_UPDATE_NOTES.md`.
Đầu vào (đã che tài khoản): `audit/audit-0.6.0/input/input_0.6.0.json` (sheet Feature Check, YomiHub Update, Project GitHub…), log `audit/audit-0.6.0/input/logs_10.txt`.

## QUY TẮC CỨNG
- KHÔNG sửa `overlay/`, `jobs/`, `build/`, `D:\yh\...`, `src/`. KHÔNG git commit/push. KHÔNG chạy flutter build.
- Chỉ ghi trong `audit/audit-0.6.0/antigravity/` (kể cả mã Dart đề xuất → thư mục `ui_new/`, `ports/`).
- Không ghi mật khẩu/token/tài khoản. Không thêm công cụ tấn công, không viết mã giải CAPTCHA/Turnstile.
- Mỗi tác tử ghi `NOTES_swarm1_<tên tác tử>.md` NGAY TỪ ĐẦU và thêm 1 dòng sau mỗi bước (giờ + việc + kết quả).
- Mọi khẳng định "YomiHub đã có/chưa có" phải grep `overlay/lib` (giới hạn thư mục con, tránh quá 2 phút) và ghi đường dẫn tệp.

## TÁC TỬ & VIỆC
### @ui_designer – Giao diện "YomiHub New Version" dựa trên Mangayomi mới nhất (v0.9.96, 14/11/2026, Flutter 3.50 + Material UI)
1. Đọc changelog/ mã UI Mangayomi v0.9.96 (https://github.com/kodjodevf/mangayomi – thư mục lib/modules, lib/utils/…; mã cũ để đối chiếu: `src/mangayomi-0.9.95`, `src/mangayomi`).
2. Đối chiếu với giao diện hiện tại của YomiHub (`overlay/lib/yomihub/ui/` – công tắc Cũ/Mới `YomiUiStyleTile`, Shiori, Liquid Glass; thanh điều hướng `overlay/lib/modules/main_view/`).
3. Viết `ui_new/DESIGN_SPEC_060.md`: màn chính (Thư viện, Cập nhật, Lịch sử, Duyệt, Thêm), thanh điều hướng nổi, thẻ truyện, trang chi tiết (có khu "Chọn nguồn đọc" cho bộ hợp nhất – xem `input/merge_sheet.jpg`), trình đọc/phát, Cài đặt; màu/typography/bo góc/khoảng cách; hành vi trên Android, Android TV (D-pad, không Comic/Novel/Play Books/Booru) và Windows (chuột, cửa sổ rộng) để 2 nền tảng đồng nhất ngôn ngữ thiết kế (Feature Check 4, 18).
4. Viết mã Dart đề xuất (Flutter 3.47 – không dùng API chỉ có ở 3.50) trong `ui_new/lib/...` theo đúng đường dẫn sẽ thay trong overlay, kèm `ui_new/INTEGRATION.md` (tệp nào thay/thêm, chỗ nối với `YomiUiStyle.newVersion`). Giữ được chuyển đổi Cũ (YomiHub Old Version) ↔ Mới (YomiHub New Version).

### @project_scanner – Quét dự án GitHub (sheet YomiHub Update dòng 4–6, 9)
Dự án: Yomikiru (mienaiyami/yomikiru), Yomihon (miyomi.app/software/yomihon), Zenshin (hitarth-gg/zenshin), Nyora (Nyora-Manga/*), Nuvio (NuvioMedia/NuvioMobile), GIF Viewer (danh sách trong sheet), Frank Yomik (akitaonrails/FrankYomik – dịch ảnh), Browser Fingerprint / Anti-bot Signature (chỉ phần đồng nhất UA/cookie/đường mạng giữa WebView và tiện ích – KHÔNG giả mạo vân tay để vượt CAPTCHA), Video Short Scroll (ShortStream, scrolly-video, VideoShorts…), Get Video URL & Download Video (m3u8_StreamSniper, media-extractor, Unrud/video-downloader…).
→ `ports/FEATURE_GAP_060.md`: mỗi dự án: tính năng chính, YomiHub đã có chưa (tệp overlay), mức ưu tiên (P1/P2/P3), cách chuyển sang Dart/Flutter, giấy phép. Với P1 viết mã Dart đề xuất trong `ports/lib/...` + test đề xuất `ports/test/yh_060_*_test.dart`.

### @repo_checker – Kho tiện ích & nguồn cập nhật (Feature Check 5, 6, 20, 21)
1. Kiểm 14 kho sheet "Extension Repo" + kho Salmanbappi, Secozzi: HTTP, định dạng index, số tiện ích, lỗi (vd. codeberg.org, cdn.jsdelivr.net, kohiden.xyz chứng chỉ).
2. Quét 13 website sheet "Website Scan - Extension Repo" → danh sách kho mới chưa có trong `overlay/lib/yomihub/repos/repo_discovery.dart` → `repo_suggestions_060.json` (url, loại: mihon/aniyomi/mangayomi/kotatsu/lnreader/ireader/aidoku/vbook, nguồn website).
3. Kiểm 8 nguồn "Website Update Apps" (GitHub Releases + Drive ×3 + MediaFire ×3) → `update_sources_060.md`.

Báo cáo cuối: `SUMMARY_swarm1_060.md` (việc xong, tệp đã tạo, việc chưa xong). Claude sẽ duyệt và tích hợp vào overlay.
