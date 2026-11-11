
## 2026-11-10 10:18 — Phiên bản và phát tiếp video
PowerShell, rg, chỉnh mã Dart: pubspec.yaml:5 thành 0.5.6+48, app_identity.dart:33 thành YomiHub/0.5.6. Đối chiếu evidence/B/version.txt. anime_player_view.dart:1308,1390,1530,1630: lỗi cannot seek từng bị bỏ qua khi tắt đổi server hoặc còn vòng lặp đang chạy; hủy vòng tua khi backend từ chối và kiểm tra phiên sau khi áp dụng cấu hình mạng. Chờ kiểm thử hành vi.

## 2026-11-10 22:15 — R1, R2 và B1.2
Dart, Flutter, PowerShell. rejected_seek.dart lọc lý do mpv, anime_player_view.dart ghi sự kiện hủy vòng tua; yh_056_test.dart kiểm tra 3 tình huống; 3/3 đạt (evidence/B/R2-test.txt). library_updater.dart lấy ProviderContainer trước await để hoàn tất cập nhật nền khi widget rời cây. Cần thử trên Android.

## 2026-11-10 22:29 — B1.2–B3, trạng thái xác minh
- B1.2: library_updater.dart, autoUpdateLibraryIfDue lấy ProviderContainer trước lần await đầu tiên. Null check trong log 04/11 đã được giải mã ở 0.5.2; chưa tái hiện trên 0.5.6.
- B1.3: m_client.dart và cf_challenge.dart: thay clearance cũ khi retry, xử lý không có giao diện toast, không chép cookie sau chuyển hướng ngược sang host nguồn, cập nhật danh sách cookie từ trạng thái mới nhất trong giao dịch lưu. 4/4 test Flutter ở bước này, bằng chứng B1-cookies-test.txt. Chưa thử máy chủ thật.
- B1.4: vpn_service.dart/startTor và YomiTunnels.kt/ovpnUp: hợp nhất yêu cầu Tor đang chờ, ngăn kết quả cũ đến sau tắt Tor, xóa lịch sử chẩn đoán OpenVPN giữa hai lần kết nối. Nhật ký 10/11 cho thấy bootstrap dừng 45–50%. Chưa xác lập nguyên nhân nhà mạng hay bridge.
- B1.5: cloud_backup_service.dart/completeAuth và upload: giữ đúng Chat ID đã chỉ định khi Telegram báo sai đích, báo rõ thiếu Chat ID trước khi mở file. Chưa upload thật.
- B1.6: gh_mirror.dart/mirrorsOf hỗ trợ refs/heads và refs/tags, encode tên tệp, chỉ chuyển Accept/User-Agent/Range đến CDN. yomi_suggestions.dart/load tách bộ nhớ đệm theo cài đặt NSFW; bỏ kết quả rỗng sau lỗi mạng. Chưa chạy Android.
- B1.7: get_html_content.dart và get_video_list.dart đọc thư mục bất đồng bộ. torrent_server.dart/getInfohash gửi dạng luồng thay vì đọc hết tệp trên UI. Chưa đo frame time.
- B1.8: thực thi hàm phân tích của các extension trong kho Kiritokmn cục bộ bằng Node.js. 3/3 ca đạt (B1.8-extensions.txt). Chưa thử đọc trực tuyến.
- B2: yomi_shorts.dart và menu của từng extension (manga_home_screen.dart) dùng bộ lọc Shorts thực tế; kiểm tra màn hình còn hoạt động sau khi tải clip. anime_player_view.dart để bộ điều phối duy nhất xác nhận phát tiếp, giảm dung sai và chặn cập nhật track khi phiên phát thay đổi. Đọc mã nguồn công khai, ghi commit vào B2-sources.txt.
- Công cụ: PowerShell, Dart, Flutter, Node.js, adb, GitHub API. Kịch bản thử trong ứng dụng: B3-kiem-thu.md. Chưa có APK 0.5.6 được nghiệm thu.

## 2026-11-11 06:05 — U2, FC31
PowerShell, Python/openpyxl và đối chiếu Dart. Đã thêm các liên kết còn thiếu hoặc chuyển tới đúng mục trong github_projects.dart (Ứng dụng, Trình duyệt, Tính năng khác, Dịch hình ảnh, Văn phòng). Đã kiểm tra 34/34 URL yêu cầu và 637/637 URL duy nhất trong Excel; ExcelJet trước đây nằm ở nhóm tham khảo. Màn hình cho chọn từng URL. Bằng chứng U2-projects.txt, U2-workbook.txt, B-final-analyze.log và kiểm thử giao diện mới trong yh_056_test.dart.

## 2026-11-11 06:15 — Mốc 1 phần B
Phân tích lib: 0 lỗi, 166 cảnh báo, 52 info. Toàn bộ Flutter: 645 đạt, 1 trượt yh_049 (bản dịch tiếng Anh của C, ngoại lệ đã giao). Công cụ Dart SDK, Flutter và PowerShell trên máy dự án. Chưa có Mốc 1 chung; kiểm thử APK, ảnh và video thuộc B4. Chi tiết ở B-final-analyze.log/B-final-suite.log/B-final-exits.txt.

## 2026-11-11 10:10 — R7–R12 diff evidence review
- **R7:** `auto_backup.dart` now writes under `autobackup`, prunes only matching app-generated timestamped `.backup` files when a positive limit is configured, defaults to unlimited, awaits backup/pruning, and logs each deletion/failure. `backup.dart` writes to a `.partial` path before rename and rethrows failures for background calls. Settings are in `data_and_storage.dart`. The required “foreign file remains untouched” regression test and rerun of the R7 suite are still pending; no post-change Flutter result is claimed.
- **R8:** Confirmed the `YomiIntegrations.integrationAuditTable` in `lib/yomihub/integrations/yomi_integrations.dart` names all six projects (Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, GIF Viewer) and marks each **Chưa tích hợp**. `NOTES_C.md` also records that these modules are not connected to the app runtime. This is a scope/status confirmation, not an integration test.
- **R9:** The Ryzen auto-tune action has been removed/does not exist in the current overlay: no `autoTuneForAmdRyzen` or `isolatePoolMax` references remain, and no action claims to set `d3d11va-copy`. The current diagnostic only reports CPU/video settings and suggests the existing software fallback. No R9 runtime test was run.
- **R10:** Added missing locale entries only; JSON, placeholders, all 18 locale files, and retained Play Books translations checked in `evidence/B/R10-locales.txt`.
- **R11:** `fetch_item_sources.dart` aggregates repository success/failure counts; `fetch_sources_list.dart` throws on invalid/missing repository responses and logs failures; `browse_screen.dart` reports counts/errors and checks `mounted` after awaits. Unit/UI verification remains pending.
- **R12:** Removed the always-true `verifySoftwareDecodingFallback`; `resolveHwdecMode` now resolves requested decoder modes by platform and `yh_054_test.dart` covers four mode cases. `zenshin_anime_tracker.dart` contains episode parsing cases including “Mob Psycho 100 - 05” => 5 in `yh_056_part_c_test.dart`. These tests have not been rerun after the R7–R12 edits.
- **Pending verification:** Run the relevant regression tests and analyzer later under the assigned build lock; no test is marked passed here. No Flutter command was run for this evidence update.
- **Files:** Updated `audit-0.5.6/B_changed_files.txt` with actually changed R7–R12 overlay files, including `player_decoder_state_provider.dart` and `test/yh_054_test.dart`; generated `fetch_item_sources.g.dart` is excluded because it is unchanged.

- **2026-11-11 10:05 — R7/R11/R12 run evidence:** `R7-R12-suite.log` records **656 tests passed**, test exit 0; `yh_049` “every tr() text has an English translation” passed. `R7-R12-exits.txt` records analyze exit 2 and test exit 0; analyzer log ends with 220 issues, so it is not marked clean. The suite does not include `yh_056_part_c_test.dart`: R7’s `Directory.systemTemp.createTemp` backup-retention test (isolated files including unrelated files) and R12’s episode-number test remain unverified by this run. `yh_054_test.dart` is present in the suite for decoder mode cases. R11 has suite evidence but no separate UI/device run. No common MỐC 1 approval is claimed.

## [2026-11-11 10:07] R7–R12 — XONG, MỐC 1 SẴN SÀNG (B)
ĐÃ SỬA R7: đã chạy trực tiếp ca tạo thư mục tạm autobackup, giữ nguyên tệp ZIP người dùng, Mihon/Aniyomi, tệp chưa ghi xong; giữ tất cả khi dùng mặc định.
ĐÃ SỬA R8, R9, R10: 6 mô-đun ghi chưa tích hợp; gỡ auto-tune Ryzen; 10 khóa ở 18 locale, yh_049 đạt.
ĐÃ SỬA R11: ca nhiều kho thành công/thất bại, toàn bộ lỗi và danh sách rỗng đạt. ĐÃ SỬA R12: ca tiêu đề Mob Psycho 100 - 05 cho tập 5 và kiểm tra thiết lập player đạt.
Bằng chứng bổ sung thay cho phần chưa xác minh ở mục 10:05: evidence/B/R7-R11-R12-targeted.log — 17/17 đạt khi chạy riêng; R7-R12-suite.log — toàn bộ 656/656 đạt; R7-R12-final-analyze.log — 0 lỗi, 166 cảnh báo, 52 info. Đã trả khóa tác vụ/claim B. Chờ phê duyệt chung trước B4.

## 2026-11-11 10:19 — R16, R17 và Tor (sau snapshot B4 trung gian)
R16: m_client.dart, LoggerInterceptor.interceptResponse: gặp trang xác minh mà thiếu navigator, URL, WebView khả dụng hoặc lỗi mở thông báo thì ghi Nhật ký “Giải CloudFlare thất bại” kèm host/mã HTTP và ném HttpException. URL đầy đủ không đưa vào lỗi.
R17: chủ ý giữ Chat ID người dùng nhập. Bot có thể nhận tin từ nhiều chat; dùng chat mới nhất sau lỗi getChat có thể gửi bản sao lưu nhầm người. Khi getChat báo chat not found, giao diện hiển thị cách sửa ID, nhắn /start hoặc thêm bot vào nhóm/kênh; người dùng có thể xóa ô ID để chủ động bật tự dò. Lỗi xác minh giữ cấu hình chưa kết nối.
Tor: stopTor hủy thế hệ khởi động và công bố OFF trước khi chờ native; callback muộn khi người dùng đã tắt Tor không thể đưa giao diện về STARTING. Vẫn cần thử bằng thiết bị.
