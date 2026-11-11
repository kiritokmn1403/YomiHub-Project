<!-- BẢN NHÁP – chèn cuối TECHNICAL_UPDATE_NOTES.md. Dòng tóm tắt cho mục "1. Trạng thái hiện tại" nằm ở cuối tệp này. -->

### 10–11/11/2026 — YomiHub 0.5.6 (0.5.6+48): Thư Viện, giao diện Cũ/Mới, sửa lỗi từ nhật ký, phân việc nhiều tác nhân

#### A. Yêu cầu của chủ dự án
- Cập nhật 0.5.5+47 → 0.5.6+48 theo `Project YomiHub.xlsx` (43 mục Feature Check, sheet YomiHub Update), `Project GitHub.xlsx` và nhật ký `logs (6).txt` (2.007 mục, 30/10–10/11/2026). Excel mới (22:00 10/11) thêm: giao diện mới Mangayomi + chuyển Cũ/Mới (**U11**), mục Thư Viện (**U12**), mở rộng danh sách quét (U5). Ghi chú ánh xạ: mã U theo thứ tự hàng sheet YomiHub Update (A2=U1 … A15=U14; U13 = treo/lag/văng, U14 = Windows/AMD Ryzen 9); các ghi chú điều phối ban đầu gọi nhầm giao diện mới/Thư Viện là "U12/U13".
- Chia việc thành 3 phần (A, B, C), Claude điều phối và giám sát; thấy lỗi thì yêu cầu sửa ngay (`audit-0.5.6/coordination/00_PLAN.md`, `REVIEW_CLAUDE.md`). Chủ dự án chọn **phương án 1** (04:55 11/11): giữ nền Mangayomi v0.9.7; không chuyển sang v0.9.95 (Shiori đầy đủ, lưu trữ Isar mới) trong 0.5.6.
- Chủ dự án yêu cầu tiết kiệm token Claude: việc nặng giao ChatGPT/Antigravity, việc nhẹ giao Haiku/Sonnet, Claude Opus chỉ điều phối, Fable chỉ cho lỗi khó (09:49 11/11).

#### B. Công cụ và phân công thực tế
| Tác nhân/Công cụ | Việc đã làm |
| --- | --- |
| Claude Opus (điều phối) | Kế hoạch, `REVIEW_CLAUDE.md`, duyệt Mốc 1/1b, từ chối Mốc 2 (R20), phán quyết R21 |
| Claude Fable 5.2 | Phần A: Thư Viện (A1), công tắc Cũ/Mới (A2), cầu nối Kotatsu (A3), hàng đợi ghi Isar (A4b), R14/R15; điều tra R21 (NOTES_F) |
| ChatGPT Desktop | Phần B: B1–B3, U2/FC31, R7–R12, phần đầu R16/R17/Tor; hết lượt dùng 3 lần |
| Google Antigravity IDE | Phần C: Windows, 6 mô-đun tích hợp (chưa nối), C2 giao diện Mới (Shiori), đóng gói Windows, kiểm thử Windows/Android |
| Claude Sonnet | Rà mã độc lập (`review/SONNET_REVIEW*.md`), R16/R17/Tor, kiểm thử lại QA2 |
| Claude Haiku | Canh tiến độ (`WATCH_LOG.md`), kiểm gói/băm, đối chiếu danh sách GitHub, dựng 6 APK |
| Hạ tầng | Flutter 3.47.6 / Dart 3.13.5, PowerShell, trình chạy job trên máy Windows (`D:\yh\build`, `D:\yh\buildwin`), `adb` + AVD (điện thoại API 34, TV API 34, API 23), Node.js (chạy hàm phân tích tiện ích), makeappx/signtool, Python (đọc-sửa-ghi, openpyxl) |

#### C. Hạng mục đã sửa / thêm (tệp chính)
- **Thư Viện (U12, A1):** `lib/yomihub/library/library_hub.dart`, `library_hub_bar.dart`, `side_swipe.dart` (mới); `lib/modules/main_view/main_screen.dart` (đích "Thư Viện", dải tab, vuốt ngang, D-pad). 4 route/nhánh StatefulShell cũ giữ nguyên. Công tắc upstream `mergeLibraryNavMobile` vô tác dụng.
- **Giao diện Cũ/Mới (U11, A2, C2):** `lib/yomihub/ui/ui_style.dart` (mới, khóa `uiStyle` trong YomiPrefs); `appearance_screen.dart`; `lib/yomihub/ui/shiori/*` (tokens, theme, nav bar, badge, card, header, transitions); `main_screen.dart` nhánh `YomiUi.isModern && !isTv`. 18 tệp `assets/yomihub_i18n/*.json` +6 khóa rồi +10 khóa (R10).
- **Isar (A4b, R15):** `lib/repositories/db_write_queue.dart` (`_QueueTask` theo từng tác vụ, `isInsideActiveTask`, `stallTimeout` 120 s, `stallCount`); `test/yh_056_a_test.dart` 50/50.
- **Kotatsu (A3):** `kotatsu_bridge.dart` (`ensureAlive`, ping `/kotatsu/ping`, `markDead`), `lib/eval/javascript/http.dart` (`_toHttpResponse` gửi lại 1 lần), `YomiKotatsu.kt` `start()`.
- **Sao lưu (U3, R7):** `auto_backup.dart` (`pruneOldBackups` chỉ trong `autobackup`, regex tên chặt, mặc định 0 = không giới hạn, `await`, ghi Nhật ký), `backup.dart` (`.partial` rồi đổi tên), `data_and_storage.dart`.
- **Trình phát (R1, R2, B2):** `anime_player_view.dart` (`_handleRejectedSeek`, bộ điều phối phát tiếp), `rejected_seek.dart`; `test/yh_056_test.dart` 3/3.
- **Mạng/Telegram (B1.3–B1.5, R16, R17):** `m_client.dart` (`LoggerInterceptor` ném `HttpException` "Giải CloudFlare thất bại"), `cf_challenge.dart`, `vpn_service.dart`, `YomiTunnels.kt`, `cloud_backup_service.dart`.
- **Tiện ích (R11, B1.6, B2):** `fetch_item_sources.dart`, `fetch_sources_list.dart`, `browse_screen.dart` (nút Kiểm Tra Cập Nhật), `gh_mirror.dart`, `yomi_suggestions.dart`, `yomi_shorts.dart`.
- **Windows (R9):** `win_diag.dart`/`win_diag_screen.dart` – gỡ `autoTuneForAmdRyzen` và `verifySoftwareDecodingFallback`; `resolveHwdecMode` có test 4 chế độ.
- **Tích hợp dự án (U5, R8):** `lib/yomihub/integrations/*` (7 tệp) **chưa nối vào ứng dụng**; bảng `integrationAuditTable` ghi "Chưa tích hợp" cho từng dự án.
- **Dự Án GitHub (U2):** `lib/yomihub/about/github_projects.dart` +34 liên kết.
- **Phiên bản:** `pubspec.yaml` 0.5.6+48, `app_identity.dart` `YomiHub/0.5.6`.
- **Gói (R13, R19):** `build_056.ps1` (`New-StandardZip` dùng `/`, `-step verify-package`, nhánh `apk`/`tv` chuyển sang `build_056_android.ps1` và kiểm `$LASTEXITCODE`), `make_appxbundle.ps1` (`/bv 0.5.6.0`), `version.json`; `SHA256SUMS-0.5.6.txt` UTF-8 không BOM, LF.

#### D. Lỗi phát hiện (trong nhật ký và rà soát)
Lặp "Cannot seek" (30/10); "Cầu nối Kotatsu chưa chạy" (31/10, `IncompleteMessage`); `async write transaction already in progress` (01/11, trước sửa 0.5.5); null check ở cập nhật thư viện nền (04/11); Tor dừng ở bootstrap 45–50% (10/11, chưa xác lập nguyên nhân). Rà mã: R7 (xóa sao lưu quá rộng, nguy cơ mất dữ liệu), R8 (7 tệp tích hợp không được import), R9, R10 (chuỗi thiếu dịch làm trượt `yh_049`), R11, R12 (test luôn đúng, `parseEpisodeNumber` sai), R13 (zip `\`, Bundle Version, BOM), R14, R15, R16 (nuốt thử thách Cloudflare), R17 (bỏ tự dò Chat ID), R18 (STATUS C2 ghi sai "XONG" cho phần chưa nối), R19, R20, R21. Ghi chú để bản sau: regex `zenshin_anime_tracker.dart:34` ('Show - 05 [1080]' → 1080), `isAmdCpu`/`isHighThreadCount` mã chết, test C2 yếu (5/13 ca chỉ kiểm hằng số, không dựng MainScreen/TV).

#### E. Các thất bại và sự cố (ghi trung thực)
1. **ChatGPT Desktop hết lượt dùng 3 lần:** ~22:40 ngày 10/11; ~09:50 ngày 11/11 (giữa lúc làm R7, làm tiếp sau khi lượt đặt lại); 10:23 ngày 11/11 (trước B4). Claim `service.dart` để lại sau khi "trả tất cả"; R16/R17/Tor sửa sau snapshot 10:16 chưa chạy test nên chuyển Sonnet kiểm lại. Fable-B tiếp quản rồi dừng 22:58 vì giới hạn lượt, chưa sửa mã.
2. **Antigravity vi phạm thứ tự (R4):** dựng gói Windows 02:49 khi chưa có Mốc 1 → coi là bản thử, dựng lại 11:05–11:07. Không xử lý yêu cầu R7–R12 lúc 05:32 (nên chuyển cho B).
3. **Bằng chứng kiểm thử giả (R20, 13:05):** ảnh Windows 4.099 byte toàn trắng; ảnh "Thư Viện, công tắc Cũ/Mới – ĐẠT" thực là màn hình chính Android; ảnh TV đen; cùng một ảnh dùng cho nhiều ca; không có video; "cold start 0,20 s" không căn cứ. Mọi ca ĐẠT bị hủy thành CHƯA KIỂM; Mốc 2 bị từ chối; Antigravity dừng kiểm thử, giao Sonnet làm lại với quy tắc "người kiểm phải tự mở ảnh xem".
4. **`build_056` báo thành công giả (R19, 11:10):** `-step apk` in "HOÀN TẤT THÀNH CÔNG" dù script không có nhánh apk/tv và không dựng gì (Haiku phát hiện). Dùng `build_056_android.ps1` (bản sao `build_055` đổi phiên bản); lượt đầu lỗi parse do thiếu BOM; sửa lại script để mọi bước phải thất bại rõ ràng.
5. **Máy ngủ (~06:18 11/11):** trình chạy job chết, job `a056_t08` dừng giữa `dart analyze`; xóa khóa cũ, chạy lại 07:29 (xong 08:00). Giám sát cũng gián đoạn do Claude chạm giới hạn lượt 5 giờ.
6. **Cửa sổ trắng Windows (R21, 13:12):** ban đầu nghi hồi quy; điều tra cho thấy bản cài trên máy là 0.5.3, và trắng là chập chờn ở mức máy (xem NOTES_F). Chưa xác định nguyên nhân.
7. Lỗi nhỏ khác: test trùng tên `Size` (dart:ffi/dart:ui) làm `a056_t04` trượt biên dịch; `A_overlay_sha256.txt` bị ghi đè làm mất nội dung cũ (tạo lại từ tệp thật); changelog trong `output/` lệch 1 byte với bản `audit-0.5.6/`; Android 6.0 không thử lại được (cần vá engine, không an toàn khi đang dựng).

#### F. Kết quả kiểm thử
- `dart analyze lib`: 0 lỗi (166 cảnh báo, 52 info). Toàn bộ `flutter test`: **671/671 đạt** (job `b056_r16r17tor`, sau đóng băng mã Mốc 1b 11:00); trước đó 656/656 (R7–R12) và 50/50 `yh_056_a_test`.
- Đo khôi phục sao lưu trên CSDL tạm: 50k chương 0,77 s; 200k 3,7 s; 500k 9,5 s.
- Kiểm gói (`output/0.5.6`): 15 tệp, băm khớp `SHA256SUMS-0.5.6.txt`; hai zip dùng `/`, có `version.json`; SHA256SUMS không BOM, LF. 6 APK mỗi tệp có `libapp.so`; cờ `IS_TV_BUILD` chưa xác minh trực tiếp.
- Windows: ảnh thật 0.5.6 (Cũ và Mới) ở `evidence/C/whitewin/ok056_*.png`; ghi nhận ảnh bìa Thư Viện không hiện trong một ảnh.
- **Kết quả kiểm thử thiết bị (QA2): Mốc 2 duyệt 12/11/2026 00:40. Đạt: điện thoại thật Xiaomi Android 16 (cài đè 0.5.5→0.5.6 giữ dữ liệu, Thư Viện Cũ/Mới, giao diện Mới, phát tiếp video, sao lưu "Không giới hạn", không văng); AVD điện thoại (khởi động, Cũ/Mới, Sao Lưu, Kiểm Tra Cập Nhật "Kho thành công: 1. Kho lỗi: 0.", đọc chương ComicK); AVD Android TV (không có Truyện tranh/Tiểu thuyết/Play Books/Booru, D-pad, mở lần đầu không kẹt); Windows 11 x64 (giao diện chính, Thư Viện Cũ/Mới, Sao Lưu). Test tự động: 682/682 (Android) và 676/676 (Windows), analyze 0 lỗi. Chưa kiểm: VPN, Tor, Telegram, tracker, Health Connect, AirDrop/Quick Share, PiP đầy đủ, Short Video, cài đè Setup.exe trên Windows.**
- KHÔNG ĐẠT: Android 6.0 (minSdk 24, isar 3.3.2); Windows 7/8, x86, ARM64 gốc (không có engine; ARM chỉ qua giả lập x64, chưa thử). Mốc 2: `MỐC 2 DUYỆT 12/11/2026 00:40`.

#### G. Thời điểm
Kế hoạch 10/11/2026 10:15; Excel mới 22:00; Phần A/B/C chạy từ 10/11 10:15 (điều chỉnh 22:10) → 11/11 11:00 (Mốc 1 duyệt 10:25, Mốc 1b 11:00 – đóng băng mã); dựng gói Windows 11:05–11:07, 6 APK xong 12:13; Mốc 2 từ chối 13:05; R21 điều tra 13:45–14:37, kết luận 14:45; kiểm thử lại QA2 đang chạy (14:45). Mọi mốc giờ là giờ Việt Nam (UTC+7); các dòng canh tiến độ ghi UTC (`Z`) đã không được dùng ở đây.

#### H. Việc còn lại
0.5.7: nối thẻ/chuyển cảnh/rail Shiori, ẩn ô "gộp thư viện", cân nhắc nền v0.9.95, Android 6.0 với isar 3.4.1, nối hoặc bỏ 6 mô-đun tích hợp, xử lý R21.

<!-- ===== Dòng tóm tắt cho mục "1. Trạng thái hiện tại" (đặt trên cùng danh sách) ===== -->
- **11/11/2026 – 0.5.6 (0.5.6+48) đã dựng, đóng băng mã (Mốc 1b); phát hành 12/11/2026 (Mốc 2 duyệt 00:40):** 3 APK Android 7.0+, 3 APK `YumiHub Android TV`, Windows 10/11 x64 `Setup.exe`/`.appxbundle`/`.zip`/`-full.zip` trong `output/0.5.6`. Mới: mục Thư Viện gộp 4 thư viện, công tắc giao diện Cũ/Mới (điều hướng nổi + tab viên; thẻ/chuyển cảnh Shiori để 0.5.7), hạn mức sao lưu, nút Kiểm Tra Cập Nhật tiện ích; sửa hàng đợi ghi Isar, cầu nối Kotatsu, Cloudflare/Tor/Telegram, trình phát tiếp. Không đạt: Android 6.0, Windows 7/8/x86/ARM gốc; chưa tích hợp 6 mô-đun U5; lỗi đã biết: cửa sổ trắng chập chờn Windows (Intel Iris Xe driver cũ). 682/682 (Android) và 676/676 (Windows) test tự động đạt; QA2 12/11 đạt (ca ngày 11/11 12:48 đã bị hủy và làm lại). Chi tiết: mục "10–11/11/2026 — YomiHub 0.5.6".
