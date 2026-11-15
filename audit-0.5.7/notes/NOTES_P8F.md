# NOTES P8F (Fable) - 2 lỗi treo trên Note 9 (Android 10, APK 0.5.7+50 cài 10:42) - 15/11/2026

Bằng chứng: `audit-0.5.7/evidence/phone/p8f/` (logs_r3.txt = /sdcard/YomiHub/logs.txt, r2_*/v1_* ảnh + logcat), script `audit-0.5.7/qa/p8f/`.
Lưu ý công cụ: bản release KHÔNG in gì ra logcat cho phần reader; nhật ký ứng dụng nằm ở `/sdcard/YomiHub/logs.txt` (adb pull được, không cần run-as).

## Lỗi 1 - Reader quay vô hạn (MangaDex VI, Shirley Madison Vol.2 Ch.11)
### Nguyên nhân gốc
KHÔNG phải mạng/nguồn. Ảnh tải xong, treo ở khâu GIẢI MÃ:
- logs.txt: `[15/11/2026 12:08:04][WARNING] [Reader] Image decoder fallback: native decoder returned no image (Android < 11?) - using Flutter codec (slower, no border crop)` rồi im lặng (cũng thấy lúc QA1 11:49:03 và 12:15:40). Không có dòng "Không tải được ảnh từ ...mangadex..." nào.
- meminfo (job p8f_r5): chi tiết truyện `Native Heap 48208 / Graphics 322359` -> 6 s sau khi mở chương `Native Heap 388484 / Graphics 498202`, rồi t18, t38 đứng yên tuyệt đối (388336/497590, 388292/498202). Tức 13 trang đã được giải mã (codec Flutter) nhưng bước kế tiếp không bao giờ trả lời.
- Đường mã: `SubsamplingScaleImageView._initImage` -> `ffiImageDecoder.getImageDimensionsAsync` -> native `init_decoder` trả NULL (AImageDecoder chỉ có từ API 30) -> nhánh "legacy BMP" (P7F) `_convertToLegacyBmp` -> `image.toByteData(rawStraightRgba)` (đọc ngược điểm ảnh từ GPU) -> không hoàn tất trên Note 9 (Impeller/GLES, Mali-G72). Nhánh Dart của QA2 cũng dùng `toByteData`. KHÔNG bước nào có hạn giờ; backstop 45 s của QA3 chỉ bọc luồng tải mạng (`completer.future.timeout`), không bọc `_initImage`/ô ảnh; lỗi ô ảnh (`onTileError`) cũng không đổi trạng thái -> spinner mãi, "Tải lại" đi lại đúng đường treo đó.
- Chưa chứng minh trực tiếp được dòng lệnh treo là `toByteData` (không có bản debug); kết luận dựa trên log + bộ nhớ. Bản vá không phụ thuộc giả thuyết này (xem dưới) và sẽ ghi WARNING tên bước nếu còn bước nào quá hạn.
### Sửa
- `ffi_image_decoder.dart`:
  - đường "direct" mới cho Android khi native trả null / không nạp được: trang được giải mã MỘT lần bằng `ImageDescriptor.encoded -> instantiateCodec -> getNextFrame` (cùng đường với ảnh bìa) và trao cho viewer dưới dạng `ui.Image` (`DecodeResult.image`), không `toByteData`, không BMP, không tệp tạm. Cắt vùng (tách trang rộng) bằng `Picture.toImage`. Giữ tối đa 4 trang; ảnh > 8192 px cạnh hoặc > 32 Mpx được giảm cỡ. Không cắt viền (cropBorders) ở chế độ này.
  - `kDecodeStepTimeout = 12 s` cho MỌI bước: khởi động isolate, từng job native (trước đây 3 job không trả lời là khoá hàng đợi vĩnh viễn), codec Flutter, BMP, RGBA. Quá hạn -> WARNING `[Reader] Giải mã ảnh quá hạn 12s ở bước <tên bước> (<tệp>)` (mỗi bước 1 lần/phiên) và thử bước kế.
  - `forget(path)` để "Thử lại" giải mã lại thật.
- `subsampling_scale_image_view.dart`: watchdog `kImageDecodeBackstop = 30 s` tính từ lúc tệp có trên đĩa; hết hạn -> `LoadState.failed` + lý do "Không giải mã được ảnh sau 30 giây" + WARNING `[Reader] Không hiển thị được ảnh trang: ...`; ô ảnh nền lỗi / không đọc được kích thước -> failed + "Tệp ảnh hỏng hoặc định dạng không hỗ trợ" (trước đây im lặng). Trang ngoài màn hình không bị tính. `SubsamplingImageState.autoRetry=false` khi quá hạn giải mã.
- `reader_page_content.dart`: không tự thử lại 2 lần khi `autoRetry=false` (lỗi hiện ngay, nút Thử lại vẫn chạy).
- `min_subsampling_image_view.dart` (webtoon + cắt viền): nhận `DecodeResult.image`, thêm hạn 30 s.
- `image_load_timeout.dart`: hằng `kImageDecodeBackstop`.
- i18n: `notes/i18n_P8F.json` 2 khoá x 18 ngôn ngữ, đã gộp (merge_i18n: da them 36).

## Lỗi 2 - Video đen, không điều khiển, Back -> PiP đen -> launcher
### Nguyên nhân (đã chứng minh phần A, B; phần C chưa)
Không phải nguồn: luồng mở được, có tiếng, bộ giải mã phần cứng chạy.
- logcat v1 (12:30:56-12:31:20): `VideoOutputManager.create`, `ACodec: [OMX.Exynos.avc.dec] Now Executing`, `VideoOutput: onSurfaceAvailable`, `flutter : VideoOutput.Resize {... width: 1920, height: 1080 ...}`.
- A. Vòng phát tiếp tua lại 8 lần: `AudioTrack: stop(130): called with N frames delivered` + `ACodec signalFlush` lúc 12:31:01.97, 04.53, 07.22, 09.98, 12.52, 15.08, 17.60, 20.12 (cách ~2,5 s, mỗi lần 1,6-2 s tiếng), rồi logs.txt: `[15/11/2026 12:31:22][WARNING] [Trình phát] ... không phát tiếp được tại 32:52 sau 8 lần tua (tập "Xem phim"), phát từ vị trí hiện tại 33:14` (giống 11:54:41 và 3 dòng 08:10-08:14). Lý do: `YomiResumePolicy.isNear` chỉ cho lệch +2 s; sau mỗi lần tua vòng lặp ngủ 2 s + 0,5 s nên vị trí = đích + 2,5 s -> "chưa tới" -> tua tiếp. Mỗi lần tua xả bộ giải mã => màn đen + vòng quay suốt ~20 s đầu.
- B. Back: `PopScope` (0.1.9) vào PiP hễ `player.state.playing` = true, kể cả khi chưa có hình -> cửa sổ PiP đen, app về launcher (dumpsys: `mPinnedStack ... mode=pinned`, `mResumedActivity ...launcher`).
- C. CHƯA rõ: 15 s sau lần tua cuối (ảnh v1_t30) màn vẫn đen dù tiếng chạy, và chạm 1 lần chỉ thấy vòng quay đệm (v1_t19_tap.png), không thấy thanh điều khiển. uiautomator không dump được lúc phát. Cần xem lại sau khi hết vòng tua (bản dựng mới).
### Sửa
- `resume_policy.dart`: `isNear`/`step` thêm `sinceSeek` (thời gian từ lần tua gần nhất được cộng vào biên "đi trước"); `anime_player_view.dart` truyền `now - baselineAt`.
- `yomi_pip.dart`: `YomiPip.pipOnBack(playing, buffering, width, height)`; `anime_player_view.dart`: Back chỉ vào PiP khi đang phát, không đệm và đã có kích thước hình; còn lại quay về màn trước.

## Tệp đã sửa (overlay/) - sao lưu `audit-0.5.7/backup/src_0571/...<tên>.p8f`
lib/modules/manga/reader/subsampling_scale_image_view/src/{ffi_image_decoder,subsampling_scale_image_view,min_subsampling_image_view}.dart, lib/modules/manga/reader/widgets/reader_page_content.dart, lib/utils/image_load_timeout.dart, lib/yomihub/player/{resume_policy,yomi_pip}.dart, lib/modules/anime/anime_player_view.dart, test/yh_057_p8f_test.dart (mới), assets/yomihub_i18n/*.json (gộp 2 khoá).

## Kết quả test / analyze
- Job `p8f_zt3` (jobs/done/p8f_zt3.log): `flutter test` yh_057_p8f + yh_057_qa2 + yh_057_qa3 + yh_057_p7f + yh_057_p3 + yh_054 -> `00:13 +74: All tests passed!`, `### TEST EXIT 0`.
- Job `p8f_t2`: `flutter analyze --no-pub` 9 tệp đã sửa -> 0 error; 4 warning + 1 info đều CŨ (ffi_image_decoder.dart:982 `image == null` của QA2, min_subsampling_image_view.dart:501 và reader_page_content.dart:341 `!` thừa, anime_player_view.dart:1290 curly_braces đã ghi ở NOTES_P3).
- Job `p8f_t1` (lần đầu) hỏng biên dịch do `String?` ở subsampling_scale_image_view.dart:1094 - đã sửa trước p8f_t2.
- CHƯA dựng APK, CHƯA thử trên máy sau khi vá.

## Cần kiểm sau khi dựng lại (Note 9)
1. Reader MangaDex Shirley Madison Vol.2 Ch.11: trang 1 phải hiện trong vài giây; lật 13 trang; phóng to/thu nhỏ; tách trang rộng. logs.txt chỉ nên có 1 dòng "Image decoder fallback"; nếu có `[Reader] Giải mã ảnh quá hạn 12s ở bước ...` hay `[Reader] Không hiển thị được ảnh trang` -> gửi lại tên bước.
2. Nếu vẫn không hiện: sau <= 30 s phải thấy "Không tải được ảnh này" + "Không giải mã được ảnh sau 30 giây" + nút Thử lại.
3. Bộ nhớ: `dumpsys meminfo` khi đọc 13 trang (Native Heap không còn nhảy +340 MB).
4. Video lịch sử (Kungfu Nữ Túc, Thanh Gươm Diệt Quỷ): logcat không còn chuỗi `AudioTrack: stop(...)` cách 2,5 s; logs.txt không còn "sau 8 lần tua"; có toast "Tiếp tục phát từ ...". Kiểm phần C: hình có hiện không, chạm có ra thanh điều khiển không (nếu vẫn đen: cần bản debug / thử hwdec=no).
5. Back khi đang đệm/chưa có hình -> về Lịch sử, không PiP; Back khi hình đang phát -> PiP (thiết kế 0.1.9, tắt được trong Cài đặt PiP).
- Trạng thái máy khi bàn giao: app đã force-stop (để đóng cửa sổ PiP đen do tái hiện), đang ở launcher; không xoá dữ liệu/đổi cài đặt. Vị trí xem "Kungfu Nữ Túc" đã tăng (28:34 -> ~33:xx) do các lần tái hiện.
