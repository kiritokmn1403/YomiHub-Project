# NOTES_swarm3_device_tester.md

- 19/11/2026 14:11: Start task, verify Note 9 connection.
- 19/11/2026 14:12: Verified Note 9 (SM-N960N), confirmed in MoeTruyen page.
- 19/11/2026 14:12: Scenario 1: Kotatsu-like filters - Located "Bộ lọc" button.
- 19/11/2026 14:12: Scenario 1: Kotatsu-like filters - Confirmed filter screen uses CheckBox, no chips. DA.
- 19/11/2026 14:52: Start Swarm 4 full re-test of all 6 scenarios on Note 9 (281038ac31217ece).
- 19/11/2026 14:53: Verified Note 9 connected, YomiHub 0.6.0 running in foreground (MainActivity).
- 19/11/2026 15:00: Scenario 1: Installed ComicK (Kotatsu) 0.1.9 parser from Tiện ích tab (s1_tienich_kotatsu.png, s1_comick_installing.png).
- 19/11/2026 15:03: Scenario 1: Opened ComicK (Kotatsu) source home (s1_comick_home.png).
- 19/11/2026 15:04: Scenario 1: Opened "Bộ lọc kiểu Kotatsu" (s1_filter_initial.png). Confirmed square CheckBox UI for Sắp xếp and Thể loại.
- 19/11/2026 15:05: Scenario 1: Tested single-choice selection - switched to "Phổ biến" (s1_filter_single_choice.png), "Mặc định" automatically unchecked.
- 19/11/2026 15:06: Scenario 1: Tested tri-state genre - 1st tap on "Action" -> blue check ✓ include (s1_filter_genre_tap1.png); 2nd tap -> red square with minus [-] exclude (s1_filter_genre_tap2_exclude.png).
- 19/11/2026 15:07: Scenario 1: Applied filter -> button active, result returned ("Không có kết quả", s1_filter_applied_result.png). Kịch bản 1: ĐẠT hoàn toàn.
- 19/11/2026 15:08: Scenario 2: Updates tab opened (s2_updates_initial.png), scrolled 3 times smoothly (s2_updates_scrolled.png). Checked logs for today 19/11/2026: 0 warning "Giao diện bị treo … /updates". Kịch bản 2: ĐẠT hoàn toàn.
- 19/11/2026 15:11: Scenario 3: Opened Thêm › Sao Lưu & Đồng Bộ, located "Sao Lưu Lên Google Drive" with Google G logo (s3_saoluu_scrolled.png). Tapped to open "Sao lưu đám mây" screen showing Google Drive (Đã kết nối) (s3_gdrive_screen.png). Strictly refrained from tapping any login. Kịch bản 3: ĐẠT hoàn toàn.
- 19/11/2026 15:21: Scenario 4: Opened Cài đặt › Duyệt › Extensions Repo › "Kho đề xuất" (s4_repo_screen.png, s4_repo_suggestions.png). Verified suggestions list: located "salmanbappi/extensions-repo (EverythingMoe)" (s4_suggestions_scroll7.png) and "x.noz.one • secozzi (Mihon & Aniyomi Extensions)" (s4_suggestions_scroll8.png). Kịch bản 4: ĐẠT hoàn toàn.
- 19/11/2026 15:35: Scenario 5: Opened in-app browser at public video page https://www.w3schools.com/html/html5_video.asp (s5_w3schools_page.png). Savior FAB detected 2 media files. Opened Savior bottom sheet (s5_savior_sheet.png) showing direct links to mov_bbb.mp4 and mov_bbb.ogg. Tapped "Quét mã trang tìm link video", parser executed HTML source scanning and detected iframe embed (s5_savior_scan_result.png). Restored IME back to Laban Key. Kịch bản 5: ĐẠT hoàn toàn.
- 19/11/2026 15:41: Scenario 6: Pulled /sdcard/YomiHub/logs.txt to test_note9/logs_after.txt. Examined from the latest session "Logger initialized" at line 1586. Found 0 ERRORs, 0 UI freeze warnings, only 1 external repository certificate warning (kohiden.xyz - documented known issue) and rate-limited CDN cover image retries handled by LogBurstAggregator. Wrote test_note9/LOG_REVIEW.md. Kịch bản 6: ĐẠT hoàn toàn.
- 19/11/2026 15:43: All 6 scenarios on Samsung Galaxy Note 9 COMPLETED - 100% PASSED with full PNG evidence.
