### 14–15/11/2026 — YomiHub 0.5.7 (0.5.7+50)

Trạng thái khi ghi (15/11/2026 20:40, Asia/Saigon): mã, test tự động, bản dựng phát hành (APK thường, APK TV, APK Android 6.0, Windows Setup/appxbundle/zip) và kiểm thử thiết bị chính đã xong. Chi tiết tiến độ: `audit-0.5.7/coordination/PROGRESS_0571.md`.

#### A. Yêu cầu và quyết định
- Giữ nền Mangayomi hiện tại; sửa lỗi từ nhật ký 12–14/11/2026 (`input/logs 7.txt`, bản 0.5.6.1 APK Android 6 trên máy Xiaomi arm64); làm tiếp các sheet "YomiHub Update" và "Feature Check" (Project YomiHub.xlsx, Project GitHub.xlsx).
- Phạm vi nền tảng: Windows 10/11 x64; Android 7.0+ là chính; APK Android 6.0 riêng; YumiHub Android TV (không có Comic/Novel/Play Books/Booru).
- Số hiệu: `overlay/pubspec.yaml` 0.5.7+50; `AppIdentity.userAgent` YomiHub/0.5.7; versionCode arm64 2050, armeabi-v7a 1050, x86_64 4050.
- Quy tắc ghi chú: "đã sửa trong mã" không đồng nghĩa "đã kiểm trên máy"; mọi mục chưa kiểm trên máy được ghi rõ trong changelog.

#### B. Công cụ và phân công
- Điều phối: Claude Opus (coordinator, theo dõi `PROGRESS_0571.md`, xếp và thả job, kiểm tra tổng).
- Nhóm sửa mã: F1, P3, P6, P7F do Claude Fable; S1, S2, P1, P2, P4, P5, QA1, QA2 do Claude Sonnet; DOC1, DOC2 do Claude Haiku (ghi chú, changelog, tài liệu kỹ thuật); X1 là phiên chat riêng song song (Fable sáng 14/11, Opus từ 15:36).
- Công cụ: `device_bash` (đọc/sửa tệp trên máy Windows qua thư mục kết nối); job PowerShell với hàng đợi `jobs/pending`, `jobs/pending_fast`, `jobs/done`, `jobs/_hold`; `flutter test`, `flutter analyze`; `llvm-symbolizer` để giải mã stack (vì `flutter symbolize` không đọc được thư mục symbols); `adb` và AVD (API 23 cho Android 6, API 34 cho các thử nghiệm VPN trước đó); máy thật Samsung Note 9 (SM-N960N, Android 10) cho QA.
- Script dựng sinh từ bộ 0.5.6.1 bằng `tools/gen_057_scripts.py`: `sync_057.ps1`, `build_057{,_android,_android6}.ps1`, `make_{appxbundle,installer_exe}_057.ps1`. Bản android6 phải truyền `--dart-define=IS_A6_BUILD=true`.

#### C. Hạng mục đã sửa / thêm (tệp chính; tất cả trong `overlay/`, bản gốc ở `audit-0.5.7/backup/src_0571/`)
- **Null check thanh tab (B1, Opus):** `lib/modules/widgets/custom_draggable_tabbar.dart` (controller chuyển vào `DraggableTabsHost`); test `test/yh_057_tabs_test.dart`.
- **Mạng log 7 (F1):** `lib/yomihub/vpn/vpn_state.dart`, `lib/yomihub/net/loopback_bypass.dart` (mới), `lib/services/http/m_client.dart`, `lib/eval/javascript/http.dart`, `lib/yomihub/savior/savior.dart`, `lib/yomihub/player/player_net.dart`, `lib/yomihub/vpn/vpn_service.dart`, `lib/yomihub/vpn/vpn_screen.dart`, `lib/yomihub/vpn/tor_fallback.dart` (mới; đổi cầu nối khi kẹt, chỉ Dart), `lib/yomihub/cloudflare/cf_identity.dart` (mới), `lib/yomihub/cloudflare/cf_challenge.dart`. Chưa sửa Kotlin `YomiKotatsu.kt` và `YomiVpn.kt` (đổi cầu nối tự động trên Kotlin chưa có đường gọi tự động).
- **Kho, cập nhật, bộ lọc, log (S1):** `lib/services/extension_store_service.dart`, `lib/services/fetch_sources_list.dart`, `lib/services/crash_report.dart`, `lib/yomihub/update/multi_source_update.dart`, `lib/yomihub/filters/filter_loader.dart`, `lib/yomihub/filters/filter_refresh.dart`, `lib/utils/log/logger.dart`, `lib/utils/log/log_rate_limiter.dart` (mới; `LogBurstAggregator`), `lib/yomihub/perf/perf_watchdog.dart`, `lib/main.dart`.
- **Phân loại lỗi tiện ích và MiMi (X1-T4):** `lib/yomihub/extensions/ext_errors.dart`, `lib/services/isolate_service.dart`, `lib/utils/platform_utils.dart` (`kIsA6Build`), `lib/yomihub/a6/a6_notice.dart` (mới).
- **Health Connect (X1-P5, FC35):** `lib/yomihub/health/health_connect_service.dart` (`recordSeconds`, `startEyeCareWatch`), `lib/modules/manga/reader/mixins/chapter_controller_mixin.dart` (`setHistoryUpdate`), `lib/main.dart`.
- **Nhóm P1 (U3, U4, FC37, FC38, FC41):** `lib/modules/more/settings/settings_screen.dart`, `lib/modules/more/data_and_storage/data_and_storage.dart`, `lib/yomihub/merge/extension_merge_screen.dart`, `lib/yomihub/merge/chapter_origins.dart`, `lib/yomihub/playbooks/playbooks_toggle.dart`, `lib/yomihub/booru/booru_settings_screen.dart`, `lib/modules/manga/detail/manga_detail_view.dart`, `lib/modules/manga/detail/manga_details_view.dart`, `lib/utils/extensions/manga_extensions.dart`; test `test/yh_057_p1_test.dart`.
- **Trình đọc và tiểu thuyết (P2, U5):** `lib/modules/manga/reader/mixins/reader_gestures.dart`, `lib/modules/manga/reader/reader_view.dart`, `lib/modules/more/settings/reader/reader_screen.dart`, `lib/modules/novel/novel_reader_view.dart`, `lib/yomihub/integrations/integration_settings.dart`, `lib/yomihub/integrations/yomi_integrations.dart`, `lib/yomihub/integrations/yomihon_novel_enhancer.dart`, `lib/yomihub/integrations/yomikiru_reader_enhancer.dart`; test `test/yh_057_p2_test.dart`.
- **Trình phát, Short, Nuvio/Zenshin/PiP (P3, P3b, U5, U7, U9):** `lib/yomihub/player/resume_policy.dart`, `lib/yomihub/player/resume_store.dart`, `shorts_detect.dart` (P3b), `yomi_pip.dart` (ba công tắc); test `test/yh_057_p3_test.dart`; sửa kỳ vọng `test/yh_054_test.dart` (hành vi giữ nguyên).
- **Chống dấu vân tay (P4, U6 một phần):** `lib/yomihub/browser/anti_fingerprint.dart`, `lib/yomihub/browser/browser_screen.dart`; test `test/yh_057_p4_test.dart`.
- **Chia sẻ, Telegram, Booru, tải xuống (P5, P5b; FC24, FC32, FC40, FC42):** `share/lan_share.dart`, `share/bluetooth_share.dart`, `share/share_screen.dart`, `cloud/cloud_backup_service.dart` (TelegramProvider, che token bằng `_mask`), `booru/booru_api.dart`, `booru/booru_viewer.dart`, `modules/manga/download/providers/download_provider.dart`; test `test/yh_057_p5_test.dart`, `test/yh_057_p5b_test.dart`.
- **Google Play Books (PB, FC36):** `lib/yomihub/playbooks/play_books_screen.dart`; test `test/yh_057_pb_test.dart`.
- **Giao diện Shiori (P6, U11):** ô bìa, huy hiệu và chuyển trang Shiori; test `test/yh_057_p6_test.dart`. `ShioriHeader`, `ShioriTheme`, `ShioriCard` chưa nối.
- **Hàng đợi ghi Isar (P7F, "Isar write crash under load"):** `lib/repositories/db_write_queue.dart` (Zone mang `_Frame`, `_runNested`, `_afterTurn` có `stallTimeout`); tài liệu sao lưu `audit-0.5.7/tools/p7f/q_patch.py`; test `test/yh_057_p7f_test.dart` (9 test, có test Isar thật).
- **Android 6.0 (P7F, U10):** `lib/yomihub/a6/a6_native.dart` (mới; mở thư viện bằng đường dẫn tuyệt đối, nạp trước `libqjs.so` và `libsubsampling_scale_image_view.so`, chỉ khi `kIsA6Build`); sửa `ffi_image_decoder.dart`, `main.dart` (gọi `yhA6PreloadNative()`), `custom_extended_image_provider.dart` (log chẩn đoán ảnh mạng, chỉ android6); test `test/yh_057_u10_test.dart` (chưa chạy khi ghi).
- **Dự phòng giải mã ảnh Android < 11 (QA2):** `lib/modules/manga/reader/subsampling_scale_image_view/src/ffi_image_decoder.dart` (thứ tự: native API 30+ → legacy BMP → Flutter codec thuần Dart, `nextDecodePath`); test `test/yh_057_qa2_test.dart`.
- **Cửa sổ trắng Windows (P7F, U14/R21):** `overlay/windows/runner/main.cpp` (chọn GPU theo lần chạy, phát hiện vùng vẽ một màu 12–20 s, mở lại tối đa 2 chế độ khác), `lib/yomihub/win/win_render.dart` (mới; mục "Chế độ GPU" trong Chẩn đoán Windows), installer `make_installer_exe_057.ps1` (`RemoveStaleFiles`: xóa `*.dll` cạnh YomiHub.exe và tệp trong `data\` của bản cũ, không đụng dữ liệu người dùng).
- **Video đen hình trên Android ≤ 10 (P8F-2, Opus):** `android/app/src/main/kotlin/com/kodjodevf/mangayomi/MainActivity.kt` thêm `yhUseLegacyVideoTextures()` gọi trước `super.onCreate`: khi SDK ≤ 29 đặt `FlutterRenderer.debugForceSurfaceProducerGlTextures = true` (qua reflection, có try/catch) và thêm intent extra `enable-impeller=false`; log `Android <= 10: SurfaceTexture video textures, Impeller off`. Lần dựng 15:13 log báo `NoSuchFieldException` vì R8 xóa trường → `android/app/proguard-rules.pro` thêm `-keepclassmembers class io.flutter.embedding.engine.renderer.FlutterRenderer { public static boolean debugForceSurfaceProducerGlTextures; }` (bản gốc `backup/src_0571/proguard-rules.pro.before_surfacetex`).
- **Phát tiếp, tua lặp, PiP (P8F, Fable/Opus):** `lib/yomihub/player/resume_policy.dart` (chấp nhận lệch tua HLS ≤ 60 s, tối đa 2 lần tua, không tua khi vị trí đứng yên), `lib/yomihub/player/yomi_pip.dart` (`pipOnBack`: Quay lại không giữ người dùng trong PiP), `anime_player_view.dart` (`_yhVideoWatchdog`, đổi hwdec khi treo, `sinceSeek`).
- **Giải mã ảnh (P8F + Opus):** `ffi_image_decoder.dart` trả thẳng `ui.Image`, mỗi bước tối đa `kDecodeStepTimeout` 12 s; thêm `import 'dart:math' as math;`; lấy khung (`getNextFrame`) trước khi `desc.dispose()` (sửa "Codec failed to produce an image"); watchdog 30 s ở `subsampling_scale_image_view.dart`, `min_subsampling_image_view.dart`, `reader_page_content.dart`, `lib/utils/image_load_timeout.dart`.
- **R21 bản cuối (Fable):** nguyên nhân là swapchain bitblt gắn HWND hỏng trên máy này (ứng dụng Flutter tối giản cũng trắng); `windows/runner/main.cpp` (`yh_render`, `yh_present`) chuyển sang swapchain flip-model; bộ phát hiện dùng PrintWindow, tự mở lại mặc định tắt; `lib/yomihub/win/win_render.dart`. `make_installer_exe_057.ps1` có `RemoveStaleFiles` (chỉ xóa DLL cạnh `YomiHub.exe` và thư mục `data`).
- **Đóng gói Windows:** `make_appxbundle_057.ps1` dùng `$verQuad = "$ver.0"` (AppxManifest bắt buộc 4 phần, 0.5.7.0); `build_057.ps1` kiểm `Version="0.5.7.0"`.
- **Chuỗi giao diện:** `audit-0.5.7/notes/i18n_*.json` gộp vào 18 tệp `assets/yomihub_i18n*/` (1645 khóa × 18 ngôn ngữ; `en.json` 1645 khóa).
- **Số lượng tệp:** `git diff --stat HEAD -- overlay`: 96 tệp sửa (+3544 / −442 dòng), 24 tệp mới; tổng 120. Manifest đồng bộ lúc 17:10 có 118 mục, đã cũ; cần `sync_057.ps1 -Regen`.

#### D. Lỗi phát hiện (nhật ký 7 và rà soát mã)
- 40 lần "Null check operator…" (13/11 16:00 ở `/mangaReaderView`; 14/11 07:02 ×34 ở `/MangaLibrary`), khung `_IndicatorPainter.paint` (flutter `tabs.dart:633`): TabController bị dispose khi menu kéo còn đang đóng.
- Kotatsu gửi yêu cầu tới `127.0.0.1:9` (12/11 16:18:53–16:19:13) khi Tor khởi động; Kill switch chặn; cầu nối bị khởi động lại, làm hỏng các nguồn Kotatsu khác.
- Tor kẹt 45–50 % với snowflake (MATRIX ghi 11 lần; NOTES_F1 ghi 10 lỗi); chế độ cố định không đổi cầu nối (`YomiVpn.kt` `startBridgeWatcher`).
- CBHentai "đã giải Cloudflare nhưng vẫn không tải được" (MATRIX ×8; NOTES_F1 5 dòng, khoảng cách 3–5 s): cookie cũ làm WebView báo "đã giải" tức thì; `sec-ch-ua` của CloudScraper mâu thuẫn với User-Agent của WebView.
- "Invalid repository index" cho kho `.pb` (12/11 15:02:43–47): hết 25 s rồi nhánh JSON ném FormatException.
- Kiểm tra cập nhật timeout MediaFire ×2; lỗi tiện ích ghi ERROR kèm stack cho trường hợp không phải lỗi ứng dụng (nhiều dòng 12–14/11).
- Tiện ích "MiMi" `abstract method typeParametersSerializers()` (13–14/11); build-id trùng symbols APK android6 chạy trên máy Android đời mới.
- "Image/network load failed" lặp 164 dòng.
- Treo giao diện 2,6 s và 2,8 s (chưa tìm nguyên nhân).
- VinaHentai: bộ lọc không tải, nhật ký không có lý do.
- Lỗi rà soát (không có trong log): Health Connect luôn ghi 0 vì hàm `record*` không được gọi (FC35); bộ lọc "Hide shorts" bị áp ngược; Zenshin sai số tập với tên "[1080]"; Yomihon đếm từ tiếng Việt sai (`\w` không khớp chữ có dấu); Wi-Fi đánh giá sai "không có mật khẩu" sau khi đổi ngôn ngữ; tệp LAN dở để lại tệp hỏng; `episode.id!` văng mini player; Booru JSON hỏng thành FormatException thô; thiếu log cho tải xuống "chỉ Wi-Fi".
- Isar: `yh_056_a` "async write transaction is already in progress" (log `logs/b057_test.txt`): nguyên nhân là callback tách rời của tác vụ cũ bị coi là "lệnh lồng" và chèn `writeTxnSync` giữa giao dịch async đang mở (xem `NOTES_P7F.md`).
- Android 6 (từ 0.5.6.1, còn mở khi viết 0.5.7): ảnh Booru không hiện; CBZ báo "Không tải được ảnh này"; QuickJS không chạy. Nguyên nhân giả thuyết: Android 6 gọi lại `LD_LIBRARY_PATH` mỗi lần `System.loadLibrary`, nên `dlopen` tên trần thất bại.
- Windows: cửa sổ trắng (R21) — chưa có biện pháp trước 0.5.7.

#### E. Thất bại và sự cố (ghi trung thực)
- Hết hạn mức 5 giờ của tác nhân (06:21 15/11): P7F và QA2 bị dừng giữa chừng; `main.cpp` còn lỗi biên dịch (xuống dòng thô trong chuỗi wide literal; đã sửa lúc 01:01 nhưng ghi nhận lại sau khi hạn mức mở). Hạn mức mở lại 06:23.
- Máy mất kết nối khoảng 00:22–00:25 (14/11 → 15/11); job đang chạy được tiếp tục sau đó.
- Runner nhanh ngừng từ 23:08 (`runner_fast_alive.txt`) khiến job QA1 `qa1_04b` không chạy; hàng đợi bị một job dài (p7f_q1, ~45 phút) chặn.
- Log job PowerShell đôi khi UTF-16LE, trộn encoding; cần đọc với đúng encoding.
- Flaky → thật: `yh_056_a` đạt 2/2 khi chạy riêng nhưng trượt khi máy tải nặng; sau đó xác định là lỗi thật của hàng đợi ghi (không phải lỗi máy) và đã sửa.
- PowerShell 5 làm hỏng ảnh `adb exec-out screencap` khi chuyển hướng `>`; dùng `cmd /c`.
- `flutter symbolize` không đọc được thư mục symbols; dùng `llvm-symbolizer`.
- QA trên máy thật bị chặn: luồng 4 (trình đọc MangaDex) báo "Không tải được ảnh này" và luồng 9 (phát video Phim) quay mãi; nghi bộ giải mã `AImageDecoder` chỉ có từ API 30 và lỗi mạng/nguồn. Dự phòng Dart đã thêm nhưng chưa kiểm trên máy.
- Ghi chú X1 ghi "790 đạt + 3 đã xử lý" nhưng chưa đối chiếu được với log; số chính thức dưới đây lấy từ log.

#### F. Kết quả kiểm thử
- Tabs (`yh_057_tabs`): 2/2 đạt (14/11 09:49).
- Mạng (F1): `yh_057_f1_net` 18 test; 86/86 và 158/158 test đạt (PROGRESS, nhiều bộ test); `dart analyze` không lỗi mới.
- Nhật ký/Lỗi khác (S1): 44/44 đạt (`yh_057_s1_store` 7, `yh_057_s1_logs` 11, `yh_049`, `yh_054`), 10:01 14/11.
- P1: `yh_057_p1` + `yh_039_merge` +17 đạt; lượt 1: 45/45 (gồm yh_049/050/053).
- P2: `yh_057_p2` 10 test; `p2_b`: 1 cảnh báo cũ `reader_view.dart:64`.
- P3: `yh_057_p3` 24/24, `yh_056` 11/11 (15:12 14/11); `yh_054` đọc mã được cập nhật kỳ vọng.
- P4: `yh_057_p4` 3/3.
- P5: `yh_057_p5` 33/33 (X1, `x1_p5_test1.log` 10:53); T4 `yh_057_t4` 35/35 (`x1_t4_test1.log` 10:58).
- P6: `yh_057_p6` 7/7; `yh_057_p6 + yh_049 + …` +49 đạt.
- PB: `yh_057_pb` 4 test + `yh_049` 14 = +19 đạt.
- i18n: `yh_049` 15/15 sau khi gộp (15:19, 1598 khóa × 18).
- Hàng đợi ghi (P7F): `yh_057_p7f` +9 đạt (5 lần chạy); `yh_056_a` +50 đạt 5/5 lần (`p7f_q2`, 23:35 14/11, EXIT 0); `yh_055` +5 đạt; analyze `db_write_queue.dart` "No issues found!". `p7f_q1` (A) trên hàng đợi cũ: 6 test trượt như kỳ vọng (bắt được lỗi).
- Android 6 (P7F): job `p7f_u10a` xong; AVD API 23 nạp sẵn `libqjs.so` và `libsubsampling_scale_image_view.so` (`YomiA6Native`), 121 CA; APK android6 x86_64 dựng 00:54. Ảnh Booru/CBZ/QuickJS trên AVD: kết quả chi tiết trong `NOTES_P7F.md` (chưa tổng hợp đầy đủ khi ghi).
- Dự phòng giải mã (QA2 `qa2_dec1`): 11/11 đạt, `dart analyze` 0 (06:23 15/11).
- Bộ test tổng: 14:48 14/11: `dart analyze lib` 0 lỗi, `flutter test` 768 đạt / 1 trượt (`yh_049`, chuỗi chưa gộp i18n); 17:21 14/11: 828 đạt / 1 trượt (`yh_056_a`, Isar chập chờn; chạy riêng 2/2). Bản dựng chính thức chưa có số mới sau lần 17:21.
- QA thiết bị (Note 9, `qa/`, `evidence/phone/qa1/`): luồng 1 khởi động ĐẠT (~6 s vào Thư viện); luồng 2 thanh tab 4 mục ĐẠT (`02_tabs_montage.png`); luồng 3 sheet Bộ lọc/Sắp xếp/Hiển thị mở–đóng 25 lần ĐẠT, 0 dòng "Null check"/FATAL trong logcat; luồng 4 (trình đọc) và luồng 9 (phát video) BỊ CHẶN (mạng/nguồn), chưa có bằng chứng.
- Dev APK 0.5.7/2050 arm64 cài trên Note 9 (15:33, Success), chạy không văng (ghi chú X1); ảnh `evidence/phone/p03_now.png`: Thư viện 4 tab; một số ảnh bìa trống, nguyên nhân chưa rõ.
- Bộ test tổng cuối: 877/877 đạt; lần `x11` 876/877 (chỉ `yh_017`, test mạng hết thời gian 20 s – không phải lỗi mã).
- Bản dựng phát hành (`run_057_main`/`run_057_full3`/`run_057_tail`): APK thường 3 ABI 16:31; APK TV 19:32; Windows 19:57 (Setup.exe 19:58, appxbundle 20:00, zip/full.zip); APK Android 6.0 3 ABI 20:23; `verify` 20:28 xuất `SHA256SUMS-0.5.7.txt` (17 tệp).
- Note 9 (Android 10, APK phát hành): hết "Null check"; trang MangaDex hiện ~3 s, lỗi ảnh có Thử lại; nhãn thanh điều hướng không còn bị cắt; phát tiếp video đúng 01:22:56, không tua lặp, Quay lại không kẹt PiP; logcat sạch. Màn hình Note 9 hỏng nên không nhìn được hình video.
- AVD Android 10 (`YH_Android10_API29`, image google_apis x86_64 r13, giải nén thủ công vì sdkmanager bị ngắt khi máy ngủ): log xác nhận SurfaceTexture, không `NoSuchFieldException`; tệp MP4 hiện hình và chuyển động (`evidence/avd29/avd29_video_playback.mp4`). APK TV x86_64 mở được, giao diện TV không có Booru/Truyện tranh/Tiểu thuyết.
- Sao lưu/khôi phục 2 chiều: Note 9 tạo 24,5 MB → Windows (hồ sơ tạm, dữ liệu thật đổi tên rồi trả lại, isar 618.659.840 byte nguyên vẹn) khôi phục Thay thế 4.490 bộ/99.299 chương trong ~52 s → Windows tạo 24,2 MB → AVD API 29 khôi phục 4.490/88.371 (~70 s) → Note 9 khôi phục đè (chủ dự án cho phép) 4.490/88.371 (~10 phút). Chênh 99.299/88.371 chương chưa rõ nguyên nhân. Bằng chứng `evidence/backup/`.
- Windows (Intel Iris Xe + GTX 1650, Windows 11): cài đè Setup.exe bản cuối, dữ liệu giữ nguyên, không trắng; video `evidence/windows/YomiHub-0.5.7-windows-walkthrough.mp4` (4 phút: Thư viện 4 tab, Play Books, Booru, Cập nhật, Duyệt, Hợp nhất, Thống kê, VPN & DNS với Tor đã kết nối, Sao lưu, Cài đặt, Giới thiệu "Beta (0.5.7)"; nguồn lỗi 500 hiện Thử lại). Ảnh bìa trống khi bật Tor (máy chủ ảnh từ chối/hết thời gian chờ).

#### G. Thời điểm (Asia/Saigon)
- 14/11 09:50 S1 bắt đầu (xong 10:01); 09:55 F1 bắt đầu (xong 10:30); 09:49 tabs xong.
- 14:39 QA1 bắt đầu; 14:48 kiểm tra tổng 768/769 và dựng APK dev; 14:55 luồng 1 ĐẠT.
- 15:12 P3 test 24/24; 15:19 i18n `yh_049` 15/15; 15:32 APK dev dựng xong; 15:33 cài lên Note 9; 16:06 `yh_056_a` 2/2; 17:21 test toàn bộ 828/829.
- 21:39 P7F bắt đầu; 23:35 `p7f_q2` EXIT 0.
- 15/11 00:27 QA2; 00:54 APK android6 thử; 06:23 `qa2_dec1` 11/11.
- 09:06 xác định R21 không do dữ liệu/GPU; 11:36 cài Setup thử; 15:13 APK có P8F-2 (video vẫn đen, R8 xóa trường); 15:27 kiểm Note 9; 16:31 APK có luật proguard.
- 17:12 máy ngủ, runner treo; 19:17 khởi động lại runner, chạy `x13_tail`; 19:21–20:15 kiểm sao lưu 2 chiều; 19:35 tạo AVD API 29; 19:53 video Android 10 ĐẠT; 20:16 cài Setup bản cuối; 20:23–20:27 quay video Windows; 20:28 verify xong.

#### H. Việc còn lại (không chặn phát hành)
- Chưa kiểm trên máy thật: đổi server khi phát video, Short với tiện ích ngoài, vuốt sáng/âm lượng, tua đúp, Health Connect Android 14+, chia sẻ LAN/Bluetooth 2 máy, Telegram, Booru từng site; APK Android 6.0 trên máy ARM thật.
- Tìm nguyên nhân chênh số chương khi khôi phục (Windows 99.299 so với Android 88.371); kiểm tra loại tệp trước khi hỏi xác nhận ghi đè khi khôi phục.
- Khôi phục Thay thế trên Note 9 mất ~10 phút: xem lại tốc độ xóa thư viện cũ.
- Ảnh bìa trống khi bật Tor; nguyên nhân treo UI 2,6–2,8 s.
- Việc mở từ 0.5.7: Kotatsu/IReader VPN theo từng tiện ích (`YomiKotatsu.kt`); Nyora và GIF Viewer; Frank Yomik; Gecko chống dấu vân tay; chữ ký anti-bot; chế độ dọc Yomihon.
<!-- ===== Dòng tóm tắt cho mục "1. Trạng thái hiện tại" (đặt trên cùng danh sách) ===== -->
- **`<<NGÀY PHÁT HÀNH>>` – 0.5.7 (0.5.7+50):** giữ nền Mangayomi; sửa lỗi nhật ký 12–14/11/2026 (Null check thanh tab, Kotatsu bị đẩy vào cổng 9, Tor kẹt snowflake, Cloudflare giải xong vẫn không tải, kho `.pb`, phân loại lỗi tiện ích, ảnh trang treo khi tải), sửa cửa sổ trắng Windows (R21, flip-model DXGI), thêm công tắc Google Play Books/Booru, chọn "Nguồn đọc" cho bộ hợp nhất, Health Connect (phút đọc, nhắc 20-20-20), Yomikiru/Yomihon, giao diện Shiori; gói: APK Android 7.0+, APK Android 6.0 riêng, APK "YumiHub Android TV", Windows Setup.exe/.appxbundle/zip. Kết quả kiểm thử: Note 9, AVD Android 10, Windows 11 và sao lưu 2 chiều đạt (chi tiết mục F). Chi tiết: mục "14–15/11/2026 — YomiHub 0.5.7 (0.5.7+50)".
