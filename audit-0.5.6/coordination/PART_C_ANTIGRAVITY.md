# Phần C — Antigravity IDE: Windows + tích hợp dự án mới + đóng gói + phát hành

Đọc `00_PLAN.md` trước (quy tắc CLAIMS, BUILD_LOCK, STATUS, ghi chú). Bản dựng của bạn: `D:\A.I Project\yh\buildwin\mangayomi`.
Bạn là phiên duy nhất được chạy lệnh ghi của git, và chỉ phát hành sau khi `REVIEW_CLAUDE.md` có `MỐC 2 DUYỆT`.

## C1. Windows (YomiHub Update dòng 11, 12; Feature Check 4, 8, 18, 28)
1. Dòng 12: bản Windows (đặc biệt AMD Ryzen 9) thiếu tính năng – tìm nguyên nhân gốc (dùng Cài đặt › Chẩn đoán Windows, log), sửa, ghi bằng chứng.
2. Treo/lag/văng trên Windows; đồng nhất ngôn ngữ thiết kế, bố cục Android ↔ Windows; Liquid Glass.
3. **Windows 7 trở lên, x64 / x86 / ARM:** thử thật và ghi kết quả từng đích. Không đạt thì ghi KHÔNG ĐẠT + giới hạn Flutter/Isar cụ thể.
4. Ba gói: `.appxbundle`, `Setup.exe`, portable (`.zip` / `-full.zip`). Cài thử từng gói, chạy ổn định, ảnh + video trong `audit-0.5.6/evidence/C/`.

## C2. YomiHub Update do C chủ trì
- Dòng 3: mục "Sao Lưu & Đồng Bộ" (Tạo/Khôi phục, Tần suất, Mức nén, Số lượng, Vị trí, Đám mây, Đồng bộ, sao lưu Booru App) ở cả Cài Đặt và Thêm – kiểm tra lại bản 0.5.3, sửa phần thiếu.
- Dòng 4 + Feature Check 41: công tắc Google Play Books, Booru App trong "Bật/Tắt tính năng & Nguồn mở rộng".
- Dòng 5: quét Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, GIF Viewer (Mangayomi Project và Kotatsu Project do Phần A làm); tích hợp phần phù hợp kiến trúc và giấy phép.
  **Mã mới đặt trong tệp/thư mục mới**; chỗ nối vào tệp có sẵn phải giữ chỗ qua CLAIMS. Lập bảng: dự án · đã lấy gì · chưa lấy gì · lý do.
- Dòng 8: nút "Kiểm Tra Cập Nhật" trong Tiện Ích ở mục Duyệt.

## C3. Feature Check do C chủ trì
10 (Mangayomi Extension Server, ApkBridge, MiHon Extension Server) · 11 (trình duyệt Chromium/Firefox) · 14 (eBook, PDF) · 16 (Web Scanner)
· 20 (Check For Update với sheet Website Update Apps: GitHub, Drive ×3, MediaFire ×3) · 23 (splash 5 giây, logo bo tròn, vuông → tròn)
· 24 (AirDrop/Quick Share: máy tính ↔ máy tính, máy tính ↔ điện thoại; cần thiết bị thứ hai thì ghi rõ) · 29 (Image Translation)
· 36 (Google Play Books theo sheet Google Play Books Screenshot) · 40 (Booru App) · 43 (hiệu năng tổng thể trên Windows).
Mọi mục B chủ trì cũng phải thử lại trên Windows sau Mốc 1 (cùng mã, khác nền tảng).

## C4. Đóng gói và phát hành (Giai đoạn 3)
- Tạo `sync_056.ps1`, `build_056.ps1`, `release_056.ps1` (UTF-8 BOM, thoát mã khác 0 khi lỗi). `SHA256SUMS-0.5.6.txt`, `YomiHub-0.5.6-changelog.md`.
- Sau `MỐC 2 DUYỆT`: commit + push `main`, tạo Release `v0.5.6` với **toàn bộ** gói trong `output/0.5.6`, sửa `README.md` có link tải từng tệp ở Releases.
- Ghi vào STATUS: danh sách tệp đã tải lên, kích thước, SHA256. Không ghi token.

## Không làm
Không sửa `pubspec.yaml`/phiên bản (B làm), không sửa tệp B đang giữ trong CLAIMS, không sửa trực tiếp `TECHNICAL_UPDATE_NOTES.md`.

## Điều chỉnh 22:10
U12 (giao diện mới Mangayomi) và U13 (mục Thư Viện) do Phần A (Claude Fable 5.2) làm. C kiểm thử lại chúng trên Windows sau Mốc 1.
