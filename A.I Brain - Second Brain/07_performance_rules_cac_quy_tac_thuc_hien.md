# Các quy tắc thực hiện (bắt buộc)

## Mã & dữ liệu
1. Chỉ sửa trong `overlay/`; đồng bộ sang bản dựng bằng script, không sửa bản sao rồi bỏ quên overlay.
2. Giữ dữ liệu người dùng và bản gốc: không thao tác phá hủy thư viện thật; kiểm thử sao lưu/hợp nhất bằng dữ liệu tạm hoặc đổi tên thư mục dữ liệu.
3. Không chạy script dọn/mirror trước khi kiểm tra phạm vi xóa/ghi đè. Thư mục cần xóa thì chuyển vào `_to_delete/`.
4. Sau khi tác nhân bị ngắt giữa chừng: chạy analyze + test các tệp đã đổi trước khi dựng.
5. Mỗi khẳng định tính năng (README, trang chủ, mô tả cửa hàng) phải kiểm bằng grep mã (`overlay/lib`, Kotlin) trước khi đăng.

## Bảo mật
6. Không ghi mật khẩu, token, Client Secret, keystore (`yomihub-release.jks`, `keystore-password.txt`), tài khoản trong sheet Excel vào ghi chú, log chia sẻ, Second Brain hay GitHub. `secrets/`, `logs/`, `*.log`, `output/`, `evidence/` đã bị `.gitignore`.
7. Không nhập mật khẩu/mã xác minh, không giải CAPTCHA/Cloudflare thay chủ dự án; không tự tạo tài khoản – chủ dự án tự đăng ký/đăng nhập.
8. Không bổ sung liên kết công cụ tấn công (hack Wi-Fi, WPS, AMSI bypass…) vào "Dự án GitHub đã sử dụng".

## Phát hành & công khai
9. Đăng công khai (GitHub Release, push repo tiện ích, gửi duyệt APKPure, bật Pages) cần chủ dự án xác nhận rõ trong lượt chat; chủ dự án đã cho phép tự push tiến độ (commit có chọn lọc) lên GitHub.
10. Ảnh công khai không chứa bìa 18+ hoặc nội dung có bản quyền.
11. Xếp hạng nội dung trung thực (YomiHub: Mature 17+ vì người dùng có thể thêm nguồn 18+; `showNSFW` mặc định tắt).

## Ghi chép & báo cáo
12. Đọc toàn bộ Second Brain (00–12) + `AGENTS.md` + `TECHNICAL_UPDATE_NOTES.md` trước khi làm.
13. Sau mỗi bước ghi tiến độ; sau mỗi đợt cập nhật ghi chú kỹ thuật (không xóa lịch sử thất bại) và Second Brain đúng tệp.
14. Không chấp nhận "ĐẠT" khi chưa có bằng chứng thật (xem 05).
15. Báo cáo chủ dự án bằng tiếng Việt, mỗi bước 1 câu; nói rõ việc chủ dự án cần tự làm.
16. Tắt lịch hẹn/tiến trình nền khi xong việc (lịch nhắc, autosave, theo dõi của Antigravity).
17. Cuối mỗi phiên: thêm mục vào nhật ký phiên (12) và làm bước bàn giao (11).
18. **Tự lưu tiến độ 3 phút/lần** (yêu cầu chủ dự án 19/11/2026 11:34, thay mức 5 phút đặt lúc 09:24): `scripts/autosave/autosave_progress_<ver>.ps1` chạy nền từ đầu đến khi xong đợt; dừng bằng `jobs/STOP_AUTOSAVE_<ver>`.
19. Tác nhân (Antigravity/Claude) KHÔNG được liệt kê/tìm đệ quy cả `D:\A.I Project`, `D:\yh`, `src/`: 19/11 ba lệnh `ls -R`/`Get-ChildItem -Recurse` của Antigravity làm nghẽn ổ đĩa 1,5 giờ. Khi máy chậm: liệt kê cmd/PowerShell nền (Win32_Process + CommandLine) và dừng tiến trình thừa trước khi kết luận.
20. **Tự lưu tiến độ (0.6.1)**: 19/11 17:18 chủ dự án đặt 5 phút/lần, 20:08 đổi lại **3 phút/lần** – `scripts/autosave/autosave_progress_061.ps1`, dừng bằng `jobs/STOP_AUTOSAVE_061`. Mỗi lần chủ dự án đổi nhịp: sửa `Start-Sleep`, dừng tiến trình cũ (Win32_Process theo CommandLine) rồi chạy lại.
21. **Mã phát hành = mã đã dựng**: sửa phát sinh SAU bước sync của dây chuyền mà không dựng lại → cất vào `audit/audit-<ver>/pending_<ver+1>/`, trả `overlay/` về bản trong thư mục dựng (so `cmp`) để mã đẩy lên GitHub khớp tệp cài.

## Website (chủ dự án 20/11/2026)
22. Website gồm đúng 4 trang **Trang Chủ · Tải Về · Hướng Dẫn · Chính Sách** với cùng menu mấu đánh dấu trang, chuyển trang liền mạch; thiết kế lấy **logo ứng dụng** (`icon-512.png` = icon launcher thật) và **banner ứng dụng** (`assets/logo/tv_banner.png`, gradient #5a2cb6 → #2371e1 → #00bda6) làm nền tảng.
23. Link bản cài CHỈ nằm ở trang Tải Về; Trang Chủ chỉ có nút dẫn sang `download.html`.
24. `privacy.html` giữ nguyên URL (Google OAuth); đổi giao diện phải giữ nguyên văn mọi đoạn chính sách (kiểm bằng so sánh văn bản).
25. Không tải tài nguyên từ máy chủ ngoài trên website (phông tự lưu trữ; ngoại lệ duy nhất: script đọc API GitHub Releases).
26. Mã SHA-256, dung lượng, tên menu trên website phải lấy từ tệp thật/mã nguồn, không chép từ bản mẫu của tác nhân (Antigravity từng điền SHA giả trong nhóm mẫu).
27. Website **song ngữ Việt / Anh** (chủ dự án 20/11/2026 20:50): mỗi trang VI ở gốc `docs/` có bản EN cùng tên trong `docs/en/` (dùng `../assets/`). Sửa nội dung một bản thì sửa luôn bản kia; giữ nguyên mọi `id` (mục lục, `#anchor` khi chuyển ngôn ngữ) và 18 link `data-pat` ở cả hai trang Tải Về.
28. Nút **VI | EN** (`.lang-switch` trong `.top-actions`, trước `.btn-top`) + 3 thẻ `hreflang` (vi, en, x-default → bản VI) + `og:locale` trên cả 8 trang. Không tự chuyển trang theo ngôn ngữ trình duyệt – chỉ dải gợi ý; lựa chọn nhớ ở `localStorage['yh-lang']`. Chuỗi do JS hiển thị nằm trong từ điển `I18N {vi,en}` của `site.js` – không viết cứng chuỗi tiếng Việt ngoài từ điển.
29. Bản EN dùng đúng nhãn tiếng Anh của app (`overlay/assets/yomihub_i18n/en.json`, `overlay/lib/l10n/app_en.arb`); đầu cột CSV Tủ Sách (`Tên bộ,Tập,…`) giữ tiếng Việt vì app đọc đúng chuỗi đó. Bảng thuật ngữ: `audit/audit-0.6.3/web/antigravity_i18n_p2/GLOSSARY_en.md`. Nút trên thanh trên cùng phải vừa 390px (EN: "Download latest", "Source on GitHub").

30. **Tự lưu phiên 5 phút/lần cho mọi tác nhân** (chủ dự án 21/11/2026 19:33): ngoài commit + push phần Claude, chụp NOTES/REVIEW/BRIEF của Antigravity/Codex + PROGRESS vào `audit/audit-<ver>/backup/autosave/<giờ>/` và lưu `git diff` chưa commit của repo tiện ích (`autosave_progress_064b.ps1`). Không đưa `audit/` lên GitHub.
31. **Không sửa `docs/` trước khi phát hành** khi autosave đang đẩy `docs/` – soạn ở `audit/audit-<ver>/release/docs_<ver>/` rồi chép lúc phát hành.

## Bổ sung 25/11/2026 (0.6.5)
32. **Không tác nhân nào chạy kịch bản tự động trên thiết bị cá nhân** của chủ dự án nếu chưa có rào chắn kiểm ứng dụng đang ở trước; vi phạm → `STOP_DEVICE.txt`, kết quả = không hợp lệ.
33. **ĐẠT chỉ khi Claude đã xem bằng chứng** (ảnh thật, đúng màn, đúng bản dựng – thời gian tệp sau mốc dựng).
34. Lịch kiểm tra do chủ dự án đặt được ưu tiên; nếu giờ đặt đã qua (ví dụ "10:15" lúc 11:06) hiểu là giờ gần nhất phía sau (11:15) và nói rõ.
