# NOTES_P3 — Trình phát & Short Video (YomiHub 0.5.7)

Tác nhân: P3 (Fable), chạy lần 2 (tiếp tục sau khi lần 1 bị dừng ~15:00 14/11/2026). Giờ ghi theo Asia/Saigon.

## 0. Trạng thái (cập nhật sau mỗi bước)
- [15:12 14/11] Bắt đầu lần 2. Đã đọc Second Brain, BRIEF, MATRIX (P3, U5, U7, U9, FC15, FC26, FC32, FC39).
- [15:12] Kết quả job lần 1 `jobs/done/p3_t01.log` (kết thúc 15:10:28): `yh_057_p3_test` 24/24 đạt, `yh_056_test` 11/11 đạt, analyze 12 tệp: 0 error, 2 warning, 1 info (exit 1 là do warning/info):
  - info `anime_player_view.dart:1290:7` curly_braces_in_flow_control_structures
  - warning `anime_player_controller_provider.dart:145:19` unused_catch_stack
  - warning `manga_home_screen.dart:88:44` unnecessary_non_null_assertion
- Đang làm: rà soát diff lần 1.

## 1. Yêu cầu
(sẽ điền)
## 2. Nguyên nhân gốc (tệp:dòng)
## 3. Thay đổi (cả hai lần chạy)
## 4. Công cụ / lệnh
## 5. Kết quả test / analyze (trích log)
## 6. Cần kiểm trên máy thật
## 7. Việc còn mở

## Rà soát của Opus 5.5 (14/11/2026 ~15:50, tác nhân P3 lượt 2 dừng sau 15:12 không ghi thêm)
- Đã đọc diff `anime_player_view.dart` (326 dòng khác so với `backup/src_0571`) và `anime_player_controller_provider.dart` (50): nhận.
  - U7 phát tiếp: logic quyết định tách sang `lib/yomihub/player/resume_policy.dart` (`step`, `isNear`, `carryOver`, `openTarget`, `persistBlocker`, `storedPosition`, `shouldSyncTracker`) – có test; `resume_store.dart` giữ vị trí ở bộ nhớ phụ khi lệnh ghi Isar còn chờ trong hàng đợi; vị trí được giữ khi đổi server/chất lượng; vị trí từ mini player được ưu tiên; ngân sách 45 s không tính thời gian tải luồng (giới hạn cứng 3 phút); người xem tự tua sau khi tới đích thì dừng điều phối.
  - FC32: ghi log "video không tải được" (open() lỗi, lỗi phát khi không có tự đổi server), "không lưu đúng vị trí đã xem" (hết hạn phát tiếp – WARNING, lưu khi thoát lỗi, ghi Isar > 20 s).
  - FC15: mini player không còn `episode.id!` (văng khi tập chưa có id).
  - U5 Zenshin: đồng bộ tracker khi đạt ngưỡng xem, một lần mỗi lượt phát.
- Test: `jobs/done/p3_t01.log` yh_057_p3 24/24, yh_056 11/11. Toàn bộ test 15:4x: 2 test đọc mã của `yh_054` vỡ vì cấu trúc mới → Opus sửa kỳ vọng (`test/yh_054_test.dart`, hành vi giữ nguyên), `x2_retest2` 30/30.
- CHƯA rà: `anime/widgets/mobile.dart`, `manga_home_screen.dart`, `nuvio_media_hub.dart`, `player/{shorts_store,yomi_pip,yomi_shorts,shorts_detect}.dart` (U9 nhận diện Short cho extension ngoài). CHƯA thử trên máy: phát tiếp VOD/HLS, đổi server, PiP, Short.

## Lượt P3b (Sonnet) — 14/11/2026 16:1x (Asia/Saigon)
Phạm vi: rà phần P3 chưa rà (so `diff -u` với `backup/src_0571`).
- `anime/widgets/mobile.dart`: chỉ đổi 2 chỗ (tua đúp qua `NuvioMediaHub.resolveDoubleTapSeconds`, vuốt qua `applySwipe`). Đã kiểm toán học: travel 500 → h = 500/0.7, delta = -dy/(h*0.7) = -dy/500 = đúng hành vi cũ khi công tắc bật; tắt công tắc → trả null, không đổi gì. Khóa Nuvio chưa đặt (0) → dùng cài đặt trình phát cũ. NHẬN, không sửa.
- `manga_home_screen.dart`: thêm mục menu 3 "Ép chế độ Short" (chỉ nguồn anime, cả nhánh TV lẫn PopupMenu, chỉ số 2 khớp), setState sau khi đổi. Cảnh báo analyze `unnecessary_non_null_assertion` dòng 88 là CŨ (có y nguyên ở bản gốc). Chuỗi đều qua tr() và đã có trong en.json. NHẬN.
- `nuvio_media_hub.dart`: `pipVideoSize` (thiếu/0 → 16:9, kẹp 0.42–2.39), `applySwipe`, `resolveDoubleTapSeconds` – đúng. NHẬN.
- `shorts_store.dart`: `forceKey/isForced/setForced` (YomiPrefs.set(null) = xóa khóa, đúng). NHẬN.
- `yomi_shorts.dart`: `supports` → `ShortsDetect.reason`; `_shortsFilters` dùng `scanFilters(apply:true)` (cả CheckBox/TriState/Sort/nhóm lồng); nhánh sort "trending" khi không khớp vẫn giữ. NHẬN.
- `shorts_detect.dart` (mới, U9): đã nhận diện SelectFilter, SortFilter, CheckBox, TriState, GroupFilter lồng, cờ `additionalParams/notes`, trang web đã biết, và công tắc ép từng nguồn. LỖI tìm thấy: bộ lọc kiểu "Hide shorts / No shorts / Ẩn video ngắn" bị coi là Short và còn bị BẬT khi áp dụng (ngược ý). SỬA: thêm `_negations`, `isShortWord` trả false khi có từ phủ định. Test mới "a filter that switches shorts OFF is never applied".
  - Về genre "short" trơn: CỐ Ý không nhận ("Short (<4 min)", "TV Short" là lọc thời lượng/định dạng, đã có test chặn); extension nào có thể dùng công tắc "Ép chế độ Short" từng nguồn.
- `yomi_pip.dart` (FC15): thêm 3 công tắc Nuvio/Zenshin, đúng khóa, `mounted` có kiểm. Lưu ý nhỏ: `open()` ép kiểu `as bool` trong try nên giá trị hỏng chỉ làm dừng nạp giữa chừng (không văng). Không sửa. PiP thật cần thử trên máy (Android 8+, Note 9).
- `test/yh_057_p3_test.dart`: thêm 1 test phủ định + 1 expect nối dây (`ShortsStore.setForced`).
- `i18n_P3.json`: 9 khóa, cả 9 đã có trong `overlay/assets/yomihub_i18n/en.json`. Lượt này không thêm chuỗi tr() mới → không cần i18n_P3b.
- Tệp sửa lượt này: `shorts_detect.dart`, `yh_057_p3_test.dart`.
- Kết quả analyze/test: (đang chờ job p3b_a)
- KẾT QUẢ job `p3b_a` (log `jobs/done/p3b_a.log`, 16:21): analyze lib/yomihub/player, manga_home_screen, mobile.dart, lib/yomihub/integrations: `1 issue found` = chỉ warning CŨ `manga_home_screen.dart:88:44 unnecessary_non_null_assertion` (0 error, không warning mới). Test (yh_057_p3 + yh_056 + yh_054 + yh_049): `00:21 +61: All tests passed!`, `### TEST EXIT 0`.
- Còn lại cần máy thật: PiP (Android 8+), nút Short với extension ngoài thật, công tắc Ép chế độ Short, vuốt sáng/âm lượng, tua đúp.
