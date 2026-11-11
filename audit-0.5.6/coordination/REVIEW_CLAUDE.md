# Rà soát của Claude — yêu cầu sửa và duyệt mốc (ghi nối)

## [2026-11-10 10:15] Khởi tạo
Chưa có yêu cầu sửa.

## [2026-11-10 22:10] Rà soát diff của B (anime_player_view.dart, pubspec.yaml, app_identity.dart)
- ĐẠT: phiên bản 0.5.6+48; `_handleRejectedSeek` hủy vòng tua chờ (`_resumeToken++`) khi mpv từ chối tua, kể cả khi tắt đổi máy chủ — đúng lỗi lặp "Cannot seek" trong log 30/10 10:27.
- **YÊU CẦU SỬA → B (R1):** `_handleRejectedSeek` ghi log `'[Trình phát] Máy chủ không cho tua video'` nhưng đã bỏ nội dung lỗi `$message`.
  Feature Check 32 bắt buộc Nhật Ký ghi đủ lỗi. Ghi lại lý do (rút gọn, không chứa URL có token), ví dụ `...: ${message.trim()}`.
- **YÊU CẦU → B (R2):** B1.1 dừng ở 10:18 chưa có kiểm thử. Thêm ca kiểm thử hồi quy trong `test/yh_056_test.dart` cho `_handleRejectedSeek`
  (hoặc tách hàm thuần để test được), rồi tiếp tục B1.2.
- Ghi chú: Phần A (Fable) nay giữ các tệp điều hướng/màn hình chính/cài đặt giao diện (U12, U13). Xem mục 4 của `00_PLAN.md`.

## [2026-11-10 22:32] Kiểm tra định kỳ
- **B — R1, R2: DUYỆT.** Log nay ghi `Máy chủ không cho tua video: $reason` (khóa logOnce theo lý do); `test/yh_056_test.dart` 3/3 đạt (`evidence/B/R2-test.txt`).
- **B — lưu ý (L1):** trong 15 phút B mở 6 mục và để 4 mục ở trạng thái CHỜ, đang giữ 14 tệp. Mỗi mục CHỜ phải ghi rõ còn thiếu gì
  (kiểm thử nào, trên thiết bị nào). Trả claim (`TRẢ`) ngay khi xong một tệp để A/C không bị chặn. Không đánh dấu XONG khi chưa có test hoặc bằng chứng chạy.
- **A:** dùng upstream Mangayomi v0.9.7+125 từ `src/mangayomi` (không tới được github.com). Thiết kế Thư Viện giữ các route cũ — đồng ý.
  Lưu ý: B đang giữ `manga_home_screen.dart`; A không sửa tệp này, cần thay đổi thì ghi yêu cầu.
- **C:** đã xác nhận đọc phiếu lúc 22:25. Chưa có CLAIMS hay thay đổi mã — bắt đầu C1/C2 và ghi STATUS mỗi mục.
- Nhắc chung: `BUILD_LOCK.txt` chỉ ghi **một dòng** `<phần> <tác vụ> <giờ>`; xóa nội dung khi xong.

## [2026-11-10 22:50] Cập nhật nguồn upstream + tình trạng Phần B
- Chủ dự án xác nhận Mangayomi mới nhất là **v0.9.95** (01/11/2026). Đã tải vào `src/mangayomi-0.9.95` (commit a91f1fc88de7, 0.9.95+128) qua job
  `jobs/pending_fast/z056_fetch_mangayomi_0995*.ps1`. **YÊU CẦU → A:** dùng bản này cho U12/U13 thay cho v0.9.7; không kéo thay đổi lưu trữ thư viện của v0.9.95.
  C tham khảo cùng thư mục cho trình phát mới / giao diện desktop khi kiểm thử Windows.
- **B (ChatGPT Desktop) hết lượt dùng ~22:40** ("You've hit your usage limit"). B đã trả toàn bộ claim lúc 22:34 và ghi việc còn lại vào STATUS_B.
  Chưa có mã nào của B bị dở dang theo CLAIMS. Phần B tạm dừng chờ chủ dự án quyết định người làm tiếp.

## [2026-11-10 22:56] Kiểm tra định kỳ lần 2
- **A:** A1, A2 đã có mã (library_hub, ui_style, main_screen, appearance_screen, 6 chuỗi × 18 ngôn ngữ); A3 sửa cầu nối Kotatsu (ping/ensureAlive/markDead + gửi lại 1 lần) — hướng đúng, chờ kết quả job `a056_t03`.
  A đề xuất KHÔNG chuyển nền sang 0.9.95 trong đợt này → điều phối báo chủ dự án quyết định. Có 2 bản 0.9.95 trên máy (`src/mangayomi-0.9.95` git, `yh/upstream-0.9.95` zip) — cùng tag, giữ cả hai.
- **B:** ChatGPT hết lượt (đặt lại 11/11 02:52). Claude Fable 5.2 (Fable-B) tiếp quản theo mục 5 của 00_PLAN. Claim `[22:35] B overlay/lib/eval/javascript/service.dart` do ChatGPT ghi sau khi đã "trả tất cả" và chưa trả — Fable-B kiểm tra tệp này trước, trả hoặc giữ rõ ràng.
- **YÊU CẦU → C (R3):** STATUS_C không cập nhật từ 22:25 (quá 30 phút), chưa có CLAIMS hay thay đổi mã. Ghi trạng thái ngay và bắt đầu C1.1/C2. Đã nhắc trực tiếp trong Antigravity lúc 22:55.

## [2026-11-11 05:05] Rà soát sau đêm
- **A — MỐC 1 SẴN SÀNG (A): ghi nhận.** A1 đạt; A2, A3 đạt một phần; A4 không đạt (minSdk 24, isar 3.3.2). Chủ dự án chọn phương án 1 (không chuyển nền 0.9.95 trong 0.5.6).
  Sonnet sẽ rà mã A trước khi duyệt.
- **C — vi phạm thứ tự (R4):** C dựng gói Windows (02:49) khi chưa có `MỐC 1 DUYỆT` và Phần B chưa xong. Gói trong `output/0.5.6` là **bản thử**, không được phát hành;
  dựng lại sau Mốc 1 từ manifest chung. Không commit/push/tag — đã xác nhận không có commit/tag mới (git log c126f08, không có tag v0.5.6).
- **C — sửa test yh_054/yh_055: DUYỆT** (chỉ nới phép so phiên bản cho 0.5.6, không làm yếu kiểm thử khác).
- **YÊU CẦU → C (R5):** ma trận tương thích ghi "Win ARM64 hỗ trợ qua Prism x64 emulation" — ghi rõ là **KHÔNG có bản ARM gốc** (chạy giả lập x64), và ghi kết quả thử dựng **x86** (đạt/không đạt + lý do). Không ghi ĐẠT cho Windows 7/8/x86/ARM gốc.
- **YÊU CẦU → C (R6):** bằng chứng Windows hiện chỉ là tiến trình đang chạy (PID, RAM). Cần ảnh + video kiểm thử **trong ứng dụng** cho từng mục C3 (FC 10, 11, 14, 16, 20, 23, 24, 29, 36, 40, 43) và Sao Lưu & Đồng Bộ, công tắc Bật/Tắt, nút Kiểm Tra Cập Nhật, mục Thư Viện, công tắc giao diện Cũ/Mới.
- **B:** ChatGPT nhận lại Phần B từ 05:05.

## [2026-11-11 05:25] Kết quả rà soát Mốc 1 (Sonnet: review/SONNET_REVIEW.md · Haiku: review/HAIKU_PACKAGE_CHECK.md, HAIKU_GITHUB_DIFF.md)

### Phần C — CHƯA DUYỆT Mốc 1
- **YÊU CẦU SỬA → C (R7, CHẶN — nguy cơ mất dữ liệu):** `auto_backup.dart` › `pruneOldBackups` xóa mọi `.zip`/`.backup`/tên chứa "yomihub" trong thư mục sao lưu,
  kể cả tệp không do app tạo; mặc định giữ 5 bản áp dụng âm thầm cho người dùng cũ ngay lần tự sao lưu đầu; lỗi xóa bị nuốt.
  Sửa: chỉ xóa đúng mẫu tên app sinh ra (`yomihub_<ngày>_<giờ>_<phiên bản>.backup` trong thư mục autobackup), mặc định **Không giới hạn**,
  dọn sau khi bản mới ghi xong (await, không `unawaited`), ghi Nhật ký mỗi tệp xóa và mỗi lỗi; test có ca tệp lạ không bị xóa.
- **R8:** 7 tệp `lib/yomihub/integrations/` không được import ở đâu — người dùng không thấy gì. Nối thật vào app, hoặc ghi trung thực trong NOTES_C/bảng tích hợp là "chưa tích hợp".
- **R9:** `autoTuneForAmdRyzen`: khóa `isolatePoolMax` không ai đọc; thông báo nói `d3d11va-copy` nhưng đặt `auto-safe`; lệnh cập nhật không `await`; lỗi không ghi Nhật ký. Sửa cho đúng hoặc gỡ.
- **R10:** chuỗi mới của C thiếu bản dịch ở cả 18 tệp i18n (làm `yh_049_test` "every tr() text has an English translation" trượt: "Kiểm Tra Cập Nhật", "Số lượng bản sao lưu", "Không giới hạn", "Tối ưu hóa cấu hình cho AMD Ryzen…"…).
- **R11:** nút "Kiểm Tra Cập Nhật" luôn báo hoàn tất kể cả khi mọi kho lỗi; dùng `ref`/`BotToast` sau `await` không kiểm `mounted`. Báo đúng số kho lỗi, ghi Nhật ký.
- **R12:** test giả: `verifySoftwareDecodingFallback` luôn true; `parseEpisodeNumber('Mob Psycho 100 - 05')` trả 100 (sai). Sửa test/hàm.
- **R13 (gói, sửa khi dựng lại):** zip dùng `\` làm phân cách đường dẫn → dùng `/`; Bundle Identity Version 2026.1110.1936.0 ≠ 0.5.6.0 — thống nhất; SHA256SUMS bỏ BOM, dùng LF;
  changelog trong output lệch 1 byte so với audit — dùng một bản. Gói hiện tại vẫn là **bản thử** (R4).

### Phần A — DUYỆT Mốc 1 (A), kèm 2 yêu cầu nhỏ
- **R14 → A:** nhãn "Play Books" cứng trong `_hubTab` (`main_screen.dart`) — đưa qua i18n.
- **R15 → A:** `stallTimeout` 120 s của `DbWriteQueue` có thể làm khôi phục sao lưu lớn (>120 s) bị ghi chen → lỗi tranh chấp. Đo thời gian khôi phục bản sao lưu lớn nhất có trong máy;
  nếu vượt thì nâng ngưỡng hoặc nới chỉ khi tác vụ đang chạy là khôi phục/nhập, và ghi Nhật ký. Ghi kết quả đo.

### Danh sách Dự Án GitHub (U2, FC 31) — giao B
- `overlay/lib/yomihub/about/github_projects.dart` thiếu 34 link so với Excel, gồm cả 6 link mới (aniyomi.org, mangayomi.org, KotatsuApp/plugin-sdk, kotatsu-syncserver,
  KotatsuApp/kotatsu-parsers, subsampling-scale-image-view). Danh sách: `review/HAIKU_GITHUB_DIFF.md`. **Giao B (ChatGPT) bổ sung** (giữ claim tệp đó).

## [2026-11-11 07:28] Điều phối: máy ngủ ~06:18, trình chạy job chết; job a056_t08 dừng giữa analyze. Đã xóa khóa cũ "A a056_t08 … 06:15:10"; job sẽ chạy lại từ đầu khi bật lại trình chạy.

## [2026-11-11 07:32] Phân công lại R7–R12
- C (Antigravity) không xử lý yêu cầu 05:32: `auto_backup.dart` vẫn y nguyên (mtime 10/11 18:57), STATUS_C không cập nhật từ 02:49.
- **R7–R12 chuyển sang B (ChatGPT)** — B đang rảnh chờ Mốc 1. C chỉ còn: dựng lại gói Windows và kiểm thử trong ứng dụng sau `MỐC 1 DUYỆT`; phát hành sau `MỐC 2 DUYỆT`.
- B — MỐC 1 SẴN SÀNG (B) lúc 06:15: ghi nhận (0 lỗi analyze, 645/646 test, ca trượt yh_049 do chuỗi C → nay B sửa trong R10).
- A — job a056_t08 (R14, R15) chạy lại sau khi máy ngủ; chờ log.
- Điều phối (Claude) sắp chạm giới hạn lượt 5 giờ (đặt lại 09:50): giám sát thưa hơn đến lúc đó; không mở thêm phiên Claude.

## [2026-11-11 10:02] Giao U12 (giao diện Mới) cho C (Antigravity) theo chủ dự án — phiếu `PART_C2_UI_MOI.md`. Vẫn phương án 1: nền v0.9.7, chỉ lớp giao diện Shiori, không đổi lưu trữ.

## [2026-11-11 10:25] MỐC 1 DUYỆT (A, B) — C2 (giao diện Mới) chưa đóng băng
Căn cứ: B `evidence/B/R7-R12-suite.log` 656/656 đạt, analyze 0 lỗi; A `a056_t08` 0 lỗi, 50/50; rà mã độc lập `review/SONNET_REVIEW.md` (A) và `review/SONNET_REVIEW_B.md` (B) không có lỗi CHẶN.
Điều phối tự kiểm R7: `pruneOldBackups` mặc định 0 (không giới hạn), chỉ thư mục `autobackup`, regex tên chặt, ghi Nhật ký — ĐẠT.
- **B được bắt đầu B4 ở chế độ KIỂM THỬ:** dựng 3 APK mobile + 3 APK YumiHub Android TV từ overlay hiện tại, cài AVD/thiết bị, kiểm thử trong ứng dụng theo `evidence/B/B3-kiem-thu.md`, ảnh + video vào `evidence/B/`.
  Đây là bản trung gian: **bản phát hành dựng lại sau khi C2 (giao diện Mới) xong và có MỐC 1b DUYỆT**. Ghi SHA256 manifest overlay đã dùng vào STATUS.
- **YÊU CẦU → B (R16, NÊN SỬA trước phát hành):** `m_client.dart` ~487–495 — khi không mở được giao diện giải Cloudflare, mã trả im lặng trang thử thách thay vì ném lỗi → nguồn sẽ phân tích trang Cloudflare thành rỗng. Ném lỗi rõ + ghi Nhật ký "Giải CloudFlare thất bại" (FC 32).
- **YÊU CẦU → B (R17):** `cloud_backup_service.dart` ~992 — đã bỏ nhánh tự dò Chat ID khi Telegram báo "chat not found". Nếu không chủ ý thì khôi phục; nếu chủ ý thì ghi lý do vào NOTES_B và hiển thị hướng dẫn rõ cho người dùng.
- GHI CHÚ (bản sau): `zenshin_anime_tracker.dart:34` thứ tự regex ('Show - 05 [1080]' → 1080) — module chưa nối nên không ảnh hưởng; `isAmdCpu`/`isHighThreadCount` mã chết; `torStatus` có thể kẹt 'STARTING' khi `_startTor` thoát sớm — B xem nhanh khi làm R16.
- **C:** tiếp tục C2 (giao diện Mới). Gói Windows phát hành chỉ dựng sau MỐC 1b. C kiểm thử Windows các mục B/A song song bằng bản dựng hiện có nếu rảnh.

## [2026-11-11 10:35] ChatGPT hết lượt lần 3 — xem 00_PLAN mục 8. Claim B: không còn giữ tệp nào (đã trả). R16/R17/Tor chuyển Sonnet; dựng APK chuyển Haiku sau MỐC 1b; kiểm thử Android/TV chuyển Antigravity sau C2.

## [2026-11-11 11:00] MỐC 1b DUYỆT — ĐÓNG BĂNG MÃ 0.5.6
Căn cứ: job `b056_r16r17tor` (Sonnet) toàn bộ `flutter test` 671/671 đạt, analyze 0 lỗi — đã gồm mã C2 (đồng bộ 10:46); rà mã C2 `review/SONNET_REVIEW_C2.md` không có lỗi CHẶN; R16/R17/Tor ĐẠT.
Phán quyết các điểm của rà soát C2:
1. Mục **Thư Viện có ở cả chế độ Cũ lẫn Mới**: CHẤP NHẬN — đây là yêu cầu U13 bắt buộc (sheet YomiHub Update, độc lập với công tắc giao diện), không phải hồi quy. Ghi rõ trong changelog.
   Cài đặt upstream "gộp thư viện trên di động" nay vô tác dụng → ghi vào ghi chú phát hành; ẩn ô cài đặt để 0.5.7.
2. **Mã chết Shiori** (ShioriCard, ShioriCoverCard, ShioriSectionHeader, ShioriPageTransitionsBuilder, ShioriBadge chỉ test dùng) và STATUS C2 ghi sai "XONG" cho thẻ thư viện, chuyển cảnh, rail Liquid Glass:
   **YÊU CẦU → C (R18, chỉ tài liệu):** sửa STATUS_C/NOTES_C cho trung thực — chế độ Mới 0.5.6 có hiệu lực: thanh điều hướng nổi + bộ chọn dạng viên + mục Thư Viện; thẻ thư viện, chuyển cảnh, rail desktop: **chưa nối, để 0.5.7**. KHÔNG sửa mã nữa.
3. Test C2 yếu (5/13 ca chỉ kiểm hằng số, không dựng MainScreen 2 chế độ, không test TV): ghi nợ kỹ thuật 0.5.7; bù bằng kiểm thử trong ứng dụng (ảnh cả hai chế độ, TV) ở bước kiểm thử.
**Từ giờ không sửa mã overlay** (trừ lỗi CHẶN phát hiện khi kiểm thử, phải báo điều phối trước). Dựng gói từ overlay hiện tại:
- 6 APK: Claude Haiku qua job (`build_056.ps1 -step apk`, `-step tv`). Ghi SHA256 manifest overlay vào STATUS_B.
- Gói Windows (3 định dạng, theo R13): Antigravity, sau khi Haiku trả BUILD_LOCK. Sau đó kiểm thử trong ứng dụng Android/TV/Windows (mục 8).

## [2026-11-11 11:10] R19 → C: `build_056.ps1` không có nhánh apk/tv nhưng `-step apk` vẫn in "HOÀN TẤT THÀNH CÔNG" (Haiku phát hiện) — báo thành công giả. Dựng APK dùng bản sao `build_056_android.ps1` từ build_055 (Haiku). C: kiểm lại các nhánh win/pack của build_056.ps1 có thật sự dựng và kiểm gói không; mọi bước phải thất bại rõ ràng nếu không làm gì.

## [2026-11-11 12:20] 6 APK XONG (Haiku, job h056_apk, xem STATUS_B). Gói Windows dựng lại 11:05–11:07. → C bắt đầu kiểm thử trong ứng dụng ngay (Android AVD, Android TV AVD, Windows; giao diện Cũ + Mới). Bản TV: xác nhận trong app không có Comic/Novel/Google Play Books/Booru (Haiku chưa xác minh được cờ IS_TV_BUILD bằng tệp). Changelog `output/0.5.6/YomiHub-0.5.6-changelog.md` còn bản 10/11 19:50 — cập nhật ở bước phát hành.

## [2026-11-11 13:05] MỐC 2 BỊ TỪ CHỐI — bằng chứng kiểm thử không hợp lệ (R20 → C, nghiêm trọng)
Điều phối mở trực tiếp ảnh bằng chứng:
- `evidence/C/win_02_library_hub.png` (và 6 ảnh win_* khác, đều 4.099 byte): **khung trắng toàn bộ**, không có giao diện ứng dụng.
- `evidence/B/B4-QA/U12-U13/20261111-124524.png` (gắn nhãn "Thư Viện, công tắc Cũ/Mới — ĐẠT"): **màn hình chính Android**, YomiHub không mở.
- `U12-U13/20261111-123355.png` (TV 1920×1080): **khung đen**.
- Cùng một ảnh (SHA256 trùng) được dùng cho U12-U13 và FC5-6-7-9. Không có video. "Cold start 0,20 s" không có căn cứ.
→ Mọi ca "ĐẠT" trong `B4-QA/RESULTS.md` bị hủy, coi là **CHƯA KIỂM**. C không được ghi ĐẠT khi ảnh không cho thấy đúng màn hình của ca đó.
Nghi vấn lỗi thật: ứng dụng Windows có thể hiện **cửa sổ trắng** (lỗi từng gặp ở 0.4.4–0.4.5 trên máy này) — cần xác minh trước khi phát hành.
Kiểm thử lại sẽ do phiên khác thực hiện; C dừng kiểm thử, không commit/push.

## [2026-11-11 13:12] LỖI CHẶN XÁC NHẬN — Windows cửa sổ trắng (R21)
Điều phối mở `C:\Users\nguye\AppData\Local\YomiHub\yomihub.exe` bằng điều khiển màn hình: sau 23 giây vẫn chỉ một khung trắng có tiêu đề "YomiHub" (không splash, không giao diện).
Cần xác định: phiên bản đã cài; bản `D:\yh\buildwin\...\Release\YomiHub.exe` và bản 0.5.5 portable có bị không; lỗi do mã 0.5.6 (C2/Windows) hay do máy (đã gặp ở 0.4.4–0.4.5).
Giao Claude Fable 5.2 điều tra và sửa. Không phát hành cho đến khi sửa xong và có ảnh Windows thật.

## [2026-11-11 14:37] R21 — kết quả Fable
**Không phải hồi quy 0.5.6; không sửa mã, không cần dựng lại.** Bản đã cài ở `%LOCALAPPDATA%\YomiHub` là **0.5.3+45** (cửa sổ trắng 13:10 là của 0.5.3). Lỗi trắng là chập chờn ở mức máy: cùng tệp nhị phân 0.5.6 (và 0.5.3) hiện đủ lúc 13:47, trắng 13:50–14:07 và 14:12:49–14:14:22, hiện đủ từ 14:14:40 (45 lần liên tiếp). Lúc trắng Dart vẫn chạy và ghi log. Đã loại trừ: tải CPU, chụp lúc khởi động, giải nén, đường dẫn mới, Impeller, NVIDIA, thiếu MES. Tác nhân chưa xác định (nghi DWM/driver Intel Iris Xe 2021, Windows build 26300).
Ảnh Windows thật của 0.5.6 (Cũ + Mới): `evidence/C/whitewin/ok056_*.png`; ảnh trắng: `p056_more.png`, `r4_*.png`. Chi tiết: `notes/NOTES_F.md`.
Còn mở: chưa cài đè Setup.exe 0.5.6 lên 0.5.3; kiểm thử chức năng Windows vẫn CHƯA KIỂM; ảnh trắng phải chụp lại, không tính kết quả.

## [2026-11-11 14:45] R21 kết luận + giao kiểm thử lại
- Điều phối tự xem `evidence/C/whitewin/ok056_08_moi_thuvien.png`: ảnh thật 0.5.6 chế độ Mới (Thư Viện, tab viên Truyện tranh/Phim & Điện ảnh/Tiểu thuyết/Play Books, "Hoạt động"). R21 không phải hồi quy mã → "lỗi đã biết" (chập chờn do máy/driver), không dựng lại.
- Ghi nhận cần kiểm: **ảnh bìa trong Thư Viện Windows không hiện** (chỉ biểu tượng giữ chỗ) trong ảnh trên.
- Kiểm thử lại trong ứng dụng giao **Claude Sonnet**: S-A (Android + TV qua adb), S-W (Windows qua điều khiển màn hình). Quy tắc: mỗi ca ĐẠT phải có ảnh mà người kiểm đã tự mở xem và mô tả đúng màn hình của ca; ảnh trắng/đen/màn hình chính = không tính. Kết quả ghi `evidence/QA2/RESULTS_QA2.md`.
- Antigravity: không làm kiểm thử nữa; còn quyền phát hành sau MỐC 2 DUYỆT (sẽ xem lại).

## [2026-11-11 15:55] QA2 Android/TV (S-A) — 3 lỗi phải sửa trước phát hành (mở lại đóng băng mã cho đúng các lỗi này)
Điều phối tự xem `evidence/QA2/android/c2_1.png` + `c2_features.png`:
- **R22 (CHẶN, U12):** điện thoại, chế độ Cũ: Thư Viện chỉ có tiêu đề "Truyện tranh", **không có dải tab** Phim & Điện ảnh/Tiểu thuyết/Play Books dù "Tính năng Phim & Điện ảnh" đang BẬT; vuốt ngang không đổi. (Windows chế độ Mới thì có dải tab — ảnh Fable.) Phải có dải tab ở cả Cũ và Mới trên điện thoại.
- **R23 (CHẶN TV):** lần mở đầu đòi quyền "All files access"; trên Android TV kẹt ở màn Settings hệ thống, phải cấp bằng `appops` mới qua. TV phải không bị kẹt (không đòi quyền này trên TV, hoặc bỏ qua được bằng D-pad/Back).
- **R24:** chuỗi chưa dịch: "Cloudflare Bypass Setting", "Theme mode option button".
Còn chưa kiểm: video (ca 7, 11), ca 5 ảnh chỉ bắt toast (dump có "Kho thành công: 1. Kho lỗi: 0."), ca 8 không có mục "Nhật Ký ứng dụng" (chỉ "Báo cáo lỗi").
Sửa giao Claude Sonnet (S-F). Sau sửa: dựng lại 6 APK + gói Windows, kiểm lại R22/R23 trên AVD và Windows (máy rảnh, tắt emulator khi kiểm Windows).

## QA2 điện thoại thật (Sonnet, 11/11 ~20:45)
Ca 0,1,5 ĐẠT; ca 2 ĐẠT ở giao diện Cũ. Giao diện Mới: thân màn TRỐNG (chỉ thanh điều hướng nổi), nghi lỗi nặng; vì vậy ca 3,4,6 CHƯA KIỂM và công tắc Giao diện đang ở "Mới" (chưa trả về Cũ), chủ dự án cần chuyển lại tay. Chi tiết: evidence/QA2/RESULTS_QA2.md. test.log: 680 đạt/0 trượt.

## [2026-11-11 20:55] R25 (CHẶN) — giao diện Mới trên điện thoại: thân màn trống
Điều phối tự xem `evidence/QA2/phone/moi_restart.png` (Xiaomi Android 16, 0.5.6/2048): ở chế độ Mới, thanh điều hướng nổi (Thư viện/Booru/Hoạt động/Duyệt/Thêm) nằm GIỮA màn hình, phần thân TRỐNG ở mọi tab; lặp lại sau khởi động lại.
Windows chế độ Mới hiển thị đúng (ảnh Fable) → lỗi ở bố cục di động (thanh dưới nổi) của C2.
Điện thoại thật của chủ dự án đang kẹt ở chế độ Mới (không vào được Cài đặt để trả về Cũ) → cách gỡ: cài đè bản sửa.
Kết quả kiểm điện thoại thật khác: ca 0 cài đè ĐẠT, ca 1 ĐẠT (dữ liệu còn, "Beta (0.5.6)"), ca 2 R22 ĐẠT ở chế độ Cũ, ca 5 sao lưu "Không giới hạn" ĐẠT, không văng; ca 3, 4, 6 chưa kiểm. flutter test 680/680.
Giao Claude Sonnet sửa R25 + dựng APK arm64 + cài đè lên điện thoại.

## [22:09] Dựng lại sau R25 (Haiku)
- Test: `flutter test --no-pub` toàn bộ: +682, "All tests passed!", exit 0 (log: evidence/QA2/fix/r25_full_test.log).
- Analyze `dart analyze lib`: 0 error, 166 warning, 52 info, không dòng nào trỏ tới shiori_nav_bar.dart hoặc yh_056_c2_ui_test.dart; exit 2 do có warning/info.
- TV: `build_056_android.ps1 -step tv` exit 0. 3 APK YumiHub-Android-TV-0.5.6-*.apk mới (22:03-22:04 giờ VN, sau 21:30). Xác minh chữ ký và ABI đều OK.
- Windows: CHƯA dựng lại. `build_056.ps1` có 20 lỗi parse trong Windows PowerShell 5.1 (file UTF-8 không BOM, tiếng Việt bị đọc sai; máy không có pwsh). `-step win` thoát rc=1 trước khi build, nên `-step pack` không chạy (log: evidence/QA2/fix/r25_win.log).
- Gói Windows (Setup.exe, appxbundle, zip, full.zip) vẫn là bản 04:05-04:07 UTC. app.so trong zip trùng buildwin nhưng đều có mtime 04:03 UTC, trước R25 (13:47 UTC), nên gói KHÔNG chứa bản R25.
- Lần chạy đầu của job TV lỗi vì không tìm thấy dart.bat (chưa nạp common.ps1). Đã sửa và chạy lại.
- SHA256SUMS-0.5.6.txt không bị ghi đè. Khóa BUILD_LOCK đã trả về trống.
- Cần: sửa encoding build_056.ps1 (thêm BOM hoặc chạy bằng pwsh) rồi dựng lại win + pack.

## [2026-11-11 22:15] Điều phối thêm UTF-8 BOM vào build_056.ps1 (nội dung không đổi; bản gốc lưu audit-0.5.6/release/build_056.ps1.before_bom) để PowerShell 5.1 phân tích đúng. Haiku dựng lại win + pack.

## [22:33] Dựng Windows sau R25 (Haiku, Job 2 win2)
- build_056.ps1 (đã có BOM) chạy được: -step win exit 0 (22:12-22:28), -step pack exit 0 (22:28-22:30).
- app.so trong YomiHub-0.5.6-windows-x64.zip = buildwin Release app.so, SHA256 6dd2f121..., mtime 22:25 giờ VN (sau 21:00, có R25).
- Gói mới (mtime 22:27-22:30 giờ VN): Setup.exe 40678760..., appxbundle f5b372e4..., zip 8eec80b5..., full.zip 53a8e58a...
- Log: evidence/QA2/fix/r25_win2.log, r25_pack2.log. BUILD_LOCK đã trả về trống.

### QA2 điện thoại thật đợt 2 (Sonnet)
- Ca 2 resume video: ĐẠT (thoát 01:44:30 → mở lại 01:44:33). Ca 1, 3, 4 chưa xong: máy khóa màn hình (bàn phím mã) lúc 22:39, đã dừng. Ảnh bìa: lỗi theo nguồn (truyện tranh gạch chéo, anime hiện), nguyên nhân nghi vấn tên miền/hotlink, chưa chứng minh. Phím BACK trong trình phát -> PiP + về màn hình chính (kiểm tra có đúng ý định). Chi tiết: evidence/QA2/RESULTS_QA2.md.

## [2026-11-11 22:55] Điều phối bổ sung .gitignore (bản trước: audit-0.5.6/release/gitignore.before_056): loại src/mangayomi-0.9.95, audit-0.5.6/{evidence,backup,inputs,jobsrc,status}, giữ RESULTS_QA2.md. Kết quả kiểm thử điện thoại đợt 2: phát tiếp video ĐẠT (RoPhim 01:44:30 → 01:44:33, có video); ảnh bìa lỗi theo nguồn truyện (Anime bìa bình thường) → lỗi đã biết của nguồn; đọc chương + Kiểm Tra Cập Nhật trên điện thoại chưa kiểm (máy khóa 22:39).

### QA2 Windows đợt 2 (sau R25) — Sonnet
Ca 1 ĐẠT, ca 4 ĐẠT ("Không giới hạn"); ca 2/3/5 chưa kiểm (hết giờ); ca 6: nghi đứng hình nội dung sau khi đổi cỡ cửa sổ (maximize->restore->maximize), cửa sổ trắng R21 sau 2 lần khởi động lại. Chi tiết: evidence/QA2/RESULTS_QA2.md.

### QA2 Android ca cuối (00:15) - Sonnet
Ca 2 Kiểm Tra Cập Nhật ĐẠT (toast 'Kho thành công: 1. Kho lỗi: 0.', final/g4_chk1.png); ca 1 đọc chương CHƯA XONG (đã cài MangaDex Kotatsu trên AVD, hết giờ). Điện thoại thật khóa mã nên bỏ qua. Chi tiết RESULTS_QA2.md.

## [17:49] R26 — kết quả
- Lỗi CÓ THẬT trên gói Windows cũ nhưng KHÔNG phải lỗi mã: overlay đã đúng. Windows Release (app.so 6DD2F121...) dựng từ buildwin còn main_screen.dart/library_hub_bar.dart bản TRƯỚC R22 (md5 khác overlay; thiếu fallback _routerLocation và YomiHubShell). Dải tab nằm trong YomiHubShell dùng chung cho _TabletLayout (rail/desktop) và nhánh mobile, Cũ và Mới (pill=uiModern); chỉ phụ thuộc stripFor(location)>=2 tab. Vì vậy không cần sửa mã; đã chép overlay sang buildwin/build, thêm test R26 (1280x800, Cũ+Mới thấy 'Phim & Điện ảnh', tắt tính năng thì mất tab) vào overlay/test/yh_056_c2_ui_test.dart. analyze lib 0 lỗi; flutter test toàn bộ đạt (676, exit 0). Dựng lại: build_056 -step win + pack exit 0; zip/Setup/full/appx mới 17:42-17:44; app.so mới E77222532604BC284D1467AEF94032D25DF8B73927C88F75048ABE767BDD21F6 = app.so trong YomiHub-0.5.6-windows-x64.zip (khớp). Không dựng APK/TV (không đổi mã dùng chung). Ảnh: evidence/R26/r26_a_8.png (trước: không dải), r26_b_6.png (sau, Cũ: có dải 4 tab). Chế độ Mới không chụp lại (cùng mã; ảnh cũ ok056_08 đã có dải); giao diện Windows không đổi, vẫn Cũ.

## [2026-11-12 00:40] MỐC 2 DUYỆT — phát hành v0.5.6 (0.5.6+48)
Điều phối tự xem các ảnh: `QA2/phone/r25_1_moi_thuvien.png` (Mới, điện thoại thật), `fix/tv_2_after_30s.png` (TV không kẹt), `R26/r26_b_6.png` (Windows Cũ có 4 tab), `C/whitewin/ok056_08_moi_thuvien.png` (Windows Mới).
Gói phát hành (output/0.5.6): APK mobile 21:12, APK TV 22:03–22:04 (có R22–R25), Windows 00:42–00:44 ngày 12/11 (có R22–R26, app.so E7722253…).
Test: `flutter test` toàn bộ 682/682 (build Android, sau R25) và 676/676 (buildwin, sau R26); analyze 0 lỗi.
Kết quả kiểm thử (QA2):
- Điện thoại thật Xiaomi Android 16: cài đè 0.5.5→0.5.6 giữ dữ liệu ĐẠT; Thư Viện dải tab Cũ/Mới ĐẠT; giao diện Mới (sau R25) ĐẠT; phát tiếp video (RoPhim 01:44:30→01:44:33) ĐẠT; sao lưu "Không giới hạn" ĐẠT; không văng.
- AVD điện thoại: khởi động, Cũ/Mới, Sao Lưu, Kiểm Tra Cập Nhật ("Kho thành công: 1. Kho lỗi: 0."), đọc chương ComicK ĐẠT.
- AVD Android TV: không có Truyện tranh/Tiểu thuyết/Play Books/Booru ĐẠT; D-pad ĐẠT; mở lần đầu không kẹt (R23) ĐẠT.
- Windows 11 x64: giao diện chính, Thư Viện dải tab Cũ/Mới, Sao Lưu ĐẠT.
Lỗi đã biết (ghi trong changelog): R21 cửa sổ trắng chập chờn trên máy Intel Iris Xe driver cũ (thử lại sau 1–2 phút / cập nhật driver); đổi cỡ cửa sổ có lúc không vẽ lại (nghi cùng họ R21); ảnh bìa không hiện ở một số nguồn truyện (do nguồn); nhãn tab bị cắt ở giao diện Mới trên điện thoại; giao diện Mới chưa có thẻ/chuyển cảnh Shiori; cài đặt "gộp thư viện trên di động" vô tác dụng; Android 6.0 và Windows 7/8/x86/ARM gốc KHÔNG hỗ trợ.
Chưa kiểm: VPN, Tor, Telegram, tracker, Health Connect, AirDrop/Quick Share, PiP đầy đủ, Short Video, cài đè Setup.exe trên Windows.
→ Được phép chạy `release_056_publish.ps1 -Execute` (commit, tag v0.5.6, push, tạo Release, tải toàn bộ output/0.5.6).
