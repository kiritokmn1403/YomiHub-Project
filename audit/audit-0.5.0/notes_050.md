
### 03/11/2026 — Cập nhật phiên bản 0.5.0 (YomiHub 0.5.0+42)

Thực hiện: Claude (phiên cloud liên kết máy `kiritokmn-lap`), 03/11/2026 11:16 → 13:50 (Asia/Saigon). Người dùng xác nhận bản tóm tắt yêu cầu lúc 11:19 ("hãy tiến hành đi"); theo đề xuất đã nêu: chia giai đoạn, Windows 10+ thay cho Windows 7.

#### A. Yêu cầu
1. Nâng lên 0.5.0; Android 6.0+; mọi bản Android TV tách APK riêng `YumiHub Android TV` và **bỏ Comic, Novel, Google Play Books, Booru** (mới: thêm Play Books và Booru so với 0.4.9); Windows 7+ x64/x86/ARM với `.appxbundle`, `.exe`, portable.
2. Làm theo sheet `Feature Check` (45 mục) và `YomiHub Update` (9 mục) của `Project YomiHub.xlsx`; đối chiếu `Project GitHub.xlsx` (605 dòng).
3. Sửa lỗi trong `logs.txt` (30/10 06:09 → 03/11 11:10; 110 dòng ERROR).
4. Ghi vào tài liệu này: hạng mục sửa, lỗi phát hiện, dòng lệnh sửa, công cụ, kết quả kiểm thử, ngày.
5. Dựng, cài, kiểm thử có ảnh + video (Android SDK/Emulator, thiết bị ngoài, Windows); tải mã nguồn + Output lên GitHub (Releases + README).

#### B. Công cụ đã dùng
- Đọc/sửa mã: shell Linux của Claude trên máy người dùng (thư mục kết nối), Python 3 cho mọi phép sửa (`audit-0.5.0/edit.py`: `assert` chuỗi cũ xuất hiện đúng 1 lần, chép bản gốc sang `audit-0.5.0/before/`, ghi `audit-0.5.0/changed_files.txt`).
- Dựng/kiểm thử: `3_run_jobs.bat` + `3b_run_fast_jobs.bat` (Claude mở bằng Computer use trong File Explorer), Flutter 3.47.6 / Dart 3.13.5, Android SDK + adb, Gradle, Rust/Cargo, Visual Studio 2022 Build Tools, WiX/NuGet, ffmpeg (quay màn hình Windows), `adb screencap/screenrecord/uiautomator`.
- Script mới: `sync_050.ps1`, `build_050.ps1`, `qa050.ps1`, `release_050.ps1`, `audit-0.5.0/qa.sh` + `qatv.sh` (tạo tác vụ QA có BOM UTF-8 – PowerShell 5 đọc tệp không BOM thành mã ANSI làm hỏng chữ tiếng Việt).
- **Sửa trình chạy tác vụ** (`run_jobs.ps1`, `run_jobs_fast.ps1`): 12:10 trình chạy nhanh treo vì cửa sổ console rơi vào chế độ "Select" (QuickEdit) sau một cú nhấp. Thêm đoạn tắt QuickEdit bằng `SetConsoleMode` (kernel32, bỏ cờ 0x40) khi khởi động. Bản cũ ở `audit-0.5.0/before_scripts/`.

#### C. Lỗi trong `logs.txt` và cách xử lý

| Lỗi trong log | Nguyên nhân thật | Xử lý 0.5.0 |
| --- | --- | --- |
| 16 tiện ích vBook mã hóa (Mimimoe, GuPhim, LuPhim, MotPhim, Phim Nhựa, Phim4K, PhimTV2, RoPhim ×2, Phimtv, Phimmoir, AnimeVietsub, 210CB, CBunu Comic, Destin Team…) ghi `[ERROR] [Cập nhật tiện ích] … cài lại x.0.2` kèm stack trace, lặp lại mỗi lần bấm (03/11 10:36 → 11:08, ~25 dòng) | 0.4.9 chỉ phát hiện mã hóa *sau khi* tải plugin.zip và ném `Exception` thường → `_logUpdateFailure` ghi ERROR; danh sách không nhớ kết quả nên nút "Cài" vẫn mời bấm lại | `vbook_bridge.dart`: lớp mới `VBookEncryptedException`; `markEncrypted()` / `isKnownEncrypted()` lưu `URL@phiên bản` vào `YomiPrefs` (`vbookEncrypted`, tối đa 500). `fetch_sources_list.dart` `_logUpdateFailure`: gặp lỗi này → đánh dấu + `AppLogger.logOnce(... LogLevel.warning)` không stack, `return`. `extension_list_tile_widget.dart`: getter `_vbookLocked` → nhãn "Chỉ chạy trên vBook", biểu tượng ổ khóa, bấm chỉ hiện toast. |
| `[ERROR] Extension "MangaDex (unlocked)" … getHeaders … TypeError: not a function at <eval>:2:1` (11:09) | Script kegareta-sauces gọi `getPreference("custom_user_agent")` / `get("original_languages", [])` cho khóa **không có** trong `getSourcePreferences()`. `getSourcePreferenceEntry` ném `"Error when getting source preference"` (và `sourceRepository.getById(...)!` khi nguồn chưa lưu lúc cài) → QuickJS báo TypeError → không cài được | `lib/eval/javascript/preferences.dart`: handler `get`/`getString` bọc `try/catch` (trả `null` / giá trị mặc định); JS `SharedPreferences.get(key, defaultValue)` trả `defaultValue` khi kết quả rỗng. `toMapStringString` vốn bỏ qua header `null` nên `user-agent: null` an toàn. |
| `[Hiệu năng] Khung hình chậm: dựng 744–1164ms • màn hình: /more` | `MoreScreen` gọi `ExtensionMergeScreen.suggestIfNeeded` trong `addPostFrameCallback` → `duplicateGroups()` đọc đồng bộ mọi nguồn đã cài ngay trong khung hình đầu | `more_screen.dart`: chạy sau `Future.delayed(1200ms)`; bỏ `ref.watch(hideItemsStateProvider)` và import không dùng. Kiểm thử Windows: gợi ý "Phát hiện 14 nhóm tiện ích trùng tên miền" vẫn hiện, sau khi trang đã vẽ. |
| `Kho tiện ích chưa xác minh hoặc 0 tiện ích` (cursed-manga-repo ×2, x.noz.one, Nyora, salmanbappi) | cursed-manga-repo là định dạng `extensionList` (đã hỗ trợ); x.noz.one timeout mạng; Nyora có `"sources": null` (APK nguồn cục bộ) | Không sửa: tạo id nguồn giả cho Nyora có thể làm MES nạp sai nguồn. Ghi nhận. |
| `[Booru App] Rule34: missing authentication`, `Tor chưa kết nối được sau 90 giây`, `Cloudflare … MiMiHentai/CBHentai/LxManga`, `HentaiVN.plus tls handshake eof`, ảnh lỗi `hentaicb.help`/`nhattruyensss.com`/`i.hinhhinh.com` | Thiếu API key; nhà mạng chặn Tor/máy chủ ảnh; trang kiểm tra dấu vân tay TLS (đã phân tích 0.4.5/0.4.9) | Không phải lỗi mã (như 0.4.9 mục C). |
| Các khối `*** pid … name 1.ui … _kDartSnapshotText` | Không phải crash: là stack trace Dart (AOT, không ký hiệu) đi kèm mỗi dòng ERROR | Hết theo các lỗi trên. `adb logcat -b crash` sau kiểm thử: không có crash. |

#### D. Sheet "YomiHub Update" (9 mục) – trạng thái 0.5.0

| # | Yêu cầu | Trạng thái |
| --- | --- | --- |
| 1 | Sửa lỗi + cảnh báo trong log, tối ưu chạy mượt | Mục C. |
| 2 | Xem và sửa Website Extension | Đã đối chiếu ở 0.4.9 (mục D-2); 0.5.0 không có thay đổi sheet. |
| 3 | Bổ sung project GitHub còn thiếu | 0.4.9 đã đạt 0 liên kết thiếu (563). File mới có 605 dòng (gồm dòng tiêu đề/nhóm); **chưa chạy lại so khớp tự động trong đợt này** – việc còn lại. |
| 4 | vBook, vBook 2, LeechText – mọi kho vBook "kể cả tiện ích mã hóa" | Runtime vBook có từ 0.4.9. Tiện ích mã hóa: **không phá mã hóa của tác giả** (khóa AES riêng của ứng dụng vBook đóng nguồn). 0.5.0 khóa rõ ràng các tiện ích này thay vì báo lỗi lặp (mục C). |
| 5 | Aniyomi/Nekoyomi/Mangayomi/Kotatsu/Web Scanner + Kiểm tra cập nhật theo sheet "Website Update Apps" | Đa nguồn có từ 0.4.9. Kiểm thử 0.5.0 trên Note 9 và Windows: "Đang tìm bản cập nhật…" → không có bản mới (Release mới nhất lúc thử là v0.4.9). |
| 6 | Hotspot Shield + Windscribe trong VPN | Có từ 0.4.9 (Hotspot Shield không có cấu hình/SDK công khai). |
| 7 | sherpa-onnx | **Chưa tích hợp** – thư viện native lớn (mô hình ONNX hàng trăm MB), cần thiết kế riêng; việc còn lại. |
| 8 | Treo, lag, văng | Mục C (+ 0.4.9 Isar/Đề Xuất). Note 9: không crash trong suốt phiên kiểm thử. |
| 9 | Windows (AMD Ryzen 9) thiếu tính năng | Không có máy Ryzen 9. Trên máy kiểm thử (Intel i5-11300H + GTX 1650), **bản 0.5.0 hiển thị đầy đủ giao diện** – lỗi cửa sổ trắng ghi ở 0.4.4 F / 0.4.5 G / 0.4.9 J không còn tái hiện (không có thay đổi mã liên quan; có thể do driver/Windows đã cập nhật). |

#### E. Android TV (0.5.0)
- `main_screen.dart` `_isNotHiddenLibOnTv`: thêm `/playBooks`, `/booru` → thanh bên TV chỉ còn Phim & Điện ảnh / Cập nhật / Duyệt / Thêm.
- `router.dart`: nhánh `playBooks`/`booru` (StatefulShellRoute theo chỉ số nên giữ nhánh) dùng `_TvRemovedScreen` khi `kIsTvBuild` → tự chuyển về `/AnimeLibrary`. `main.dart`: bỏ lối tắt `/playBooks`, `/booru` trên TV. `settings_screen.dart`: ẩn `PlayBooksSettingTile`, `BooruSettingTile` khi `isTv || kIsTvBuild`.
- `tv_player_settings_panel.dart` / `tv_player_controls.dart`: "Settings", "Playback speed", "Quality", "Subtitles", "Audio", "Shaders", "Decoder", "Stats for nerds" → `tr(...)` (còn tồn từ 0.4.9 J); 9 chuỗi mới × 18 ngôn ngữ.

#### F. Kiểm thử
- `dart analyze lib`: **0 lỗi**, 210 cảnh báo/info (0.4.9: 211; không có mục mới ở tệp đã sửa).
- `flutter test` (11 tệp yh_040…yh_050): lần 1: 77 đạt / 7 lỗi – 6 test cũ ép phiên bản `0.4.x` (đã nới thành `0.`), 1 test mới phát hiện danh sách mục của bảng cài đặt TV vẫn tiếng Anh (`_categoryList`) → sửa dùng `_titleFor`. Lần 2: **84/84 đạt** (`All tests passed!`).
- **Note 9 (SM-N960N, Android 10)** – ảnh/video `audit-0.5.0/qa/`:

| Tính năng | Kết quả | Bằng chứng |
| --- | --- | --- |
| Cài đè 0.4.9 (2041) → 0.5.0 (2042), dữ liệu + lịch sử giữ nguyên | Đạt | log `f050_011`, `23_lich_su_phim` |
| Splash vuông → tròn, màn chính (điện thoại vẫn có Play Books, Booru) | Đạt | `01_splash_a/b`, `02_man_hinh_chinh`, `v01_khoi_dong.mp4` |
| Thêm kho vBook `Ivan1hai/ext/plugin.json` (6 truyện tranh / 11 phim / 61 tiểu thuyết) | Đạt | `11_kho_ivan`, `v02_vbook_ma_hoa.mp4` |
| Cài tiện ích vBook mã hóa "MotPhim" → khóa + nhãn "Chỉ chạy trên vBook"; bấm lại chỉ hiện toast | Đạt | `12_cai_motphim_vbook`, `14_motphim_bam_lai_toast`, `12_14_vbook_ma_hoa.jpg` |
| Nhật ký ứng dụng sau toàn phiên (lọc "Chỉ lỗi") | **Không có mục lỗi** | `19_nhat_ky`, `20_nhat_ky_tat_ca` |
| Giới thiệu: Beta (0.5.0); Kiểm tra cập nhật | Đạt | `17_gioi_thieu_050`, `18_kiem_tra_cap_nhat_a/b`, `v03_kiem_tra_cap_nhat.mp4` |
| Tiếp tục phát từ vị trí đã xem (Tập 04 – Goblin) | Đạt: toast "Tiếp tục phát từ 42:26", 00:42:26 → 00:42:46 / 01:14:02 | `v04_tiep_tuc_phat.mp4`, `v04_grid_tiep_tuc_phat.jpg` |
| HotPhim (HLS): Phổ biến → chi tiết → phát | Đạt (logo TOHO/ANIPLEX chạy) | `v05_hotphim.mp4` |
| MangaDex (unlocked) cài trên máy | **Chưa kiểm thử trên máy**: điều khiển ô tìm kiếm qua adb không ổn định (bàn phím Laban Key Telex đổi "MangaDex" → "MângDex"; đổi tạm sang Samsung Keyboard rồi trả lại Laban Key, nhưng chữ vẫn không vào ô). Chỉ kiểm chứng bằng mã + test. | – |

- **Android TV** (AVD `YomiHub_TV_API34`, 1920×1080, abilist `x86,armeabi-v7a` → cài APK TV armeabi-v7a, 0.4.9 → 0.5.0 versionCode 1042): thanh bên không còn Truyện tranh/Tiểu thuyết/**Play Books/Booru** (`tv02_thanh_ben`); Duyệt nguồn phim, HotPhim danh sách + chi tiết; trình phát TV: nút "Cài đặt" và bảng cài đặt tiếng Việt (`tv07_dieu_khien`, `tv08_bang_cai_dat`, `tv_grid_050.jpg`). **Không đạt trên giả lập:** luồng HotPhim không mở (00:00 / -00:00), kể cả khi đổi bộ giải mã sang phần mềm; cùng nguồn phát được trên Note 9 → nghi do môi trường (APK ARM chạy qua lớp dịch trên CPU x86 của AVD, mạng giả lập). Cần thử trên TV/Android box thật.
- **Windows 11 x64:** SHA256 cả 10 tệp khớp `SHA256SUMS-0.5.0.txt`. Portable `.zip` giải nén 330.9 MB, `YomiHub.exe` 0.5.0+42 chạy (Responding, 547 MB) và **hiển thị giao diện** (`win01_portable_050`). `Setup.exe`: bấm "Cài Đặt Ngay" → cài đè 0.4.9+41 → **0.5.0+42** vào `%LOCALAPPDATA%\YomiHub`, tự mở app; phóng to, chuyển tab Truyện tranh / Phim / Thêm / Giới thiệu (Beta 0.5.0) / Kiểm tra cập nhật / Nhật ký (chỉ INFO/WARNING) – video `win_v02_setup_va_kiem_thu.mp4`, ảnh `win02_nhat_ky_050`. `.appxbundle`: chứa `YomiHub_0.5.0_x64.appx`, ký `CN=YomiHub, O=YomiHub, C=VN` (Authenticode "UnknownError" vì chứng chỉ tự ký chưa nằm trong kho gốc của máy – chưa cài thử, cần `Install-YomiHub.bat` thêm `YomiHub-RootCA.cer`, thay đổi cài đặt bảo mật nên để chủ dự án tự chạy). Video/ảnh Windows chứa ảnh bìa trong thư viện cá nhân nên **không đưa lên GitHub**.

#### G. Không đạt / giới hạn (ghi trung thực)
- **Android 6.0:** vẫn `minSdk 24` (Android 7.0) – Isar/libmdbx `MDBX_INCOMPATIBLE` trên kernel Android 6 (0.4.3 mục D).
- **Windows 7/8, x86, ARM64:** Flutter Windows chỉ Windows 10+ x64 (ARM64 phải dựng trên máy ARM64). Gói thực tế: x64.
- sherpa-onnx chưa tích hợp; so khớp lại 605 dòng `Project GitHub.xlsx` chưa chạy lại; 45 mục Feature Check không được kiểm thử lại toàn bộ trong đợt này – chỉ các mục liên quan đến thay đổi 0.5.0 và các tính năng chính ở bảng trên.
- Tiện ích vBook mã hóa: chỉ chạy trong ứng dụng vBook (không phá mã hóa).
- Trên điện thoại, nhãn "Chỉ chạy trên vBook" bị cắt thành "Chỉ c…" khi tên kho dài (ổ khóa và toast vẫn rõ) – nên đưa nhãn xuống dòng riêng ở bản sau.
- Phát phim trên giả lập TV (mục F).

#### H. Tệp bàn giao (`output/0.5.0`)
| Tệp | MB | SHA256 |
| --- | ---: | --- |
| YomiHub-0.5.0-arm64-v8a.apk | 168.8 | `c450a1b25d6f098757bce82b11242be4b0e35b389487f016cbfd4e723f4dd083` |
| YomiHub-0.5.0-armeabi-v7a.apk | 165.6 | `5cec49c7c8202badc2449219a63cf1a137f9b397eae91c1d7dcc9b99a580bca3` |
| YomiHub-0.5.0-x86_64.apk | 178.1 | `fb6076175107057a8d6a42b4ce3f5e68b24dff54b5faa0b2e89c1143e4425f87` |
| YumiHub-Android-TV-0.5.0-arm64-v8a.apk | 168.6 | `dd8cf1a88991cd769905dbd2c60b0b9b2dcd376a1472353bf1a49127cbb185c2` |
| YumiHub-Android-TV-0.5.0-armeabi-v7a.apk | 165.4 | `80d1cada450b8e95c2c218bd87d5d0c398b0d2dae096cc2b882d09b2152c039c` |
| YumiHub-Android-TV-0.5.0-x86_64.apk | 178.0 | `68986d175de83455abf7f15e864636beed0525d565863b381a9a02b4f29bce6b` |
| YomiHub-0.5.0-windows-x64-Setup.exe | 138.6 | `d4487f5dea029a56e555531ca6ac80e9913f38c121dac46ab716d0e75d6ac213` |
| YomiHub-0.5.0-windows-x64.appxbundle | 270.9 | `0a3f8c774ec7134499880222ba72d80b4d7d41f14f64a9d4de870d81f394ff2c` |
| YomiHub-0.5.0-windows-x64.zip (portable) | 138.6 | `c718e89724c730039cdfc2090b610b592578d2628b260e97ff07926a8fcbe5fa` |
| YomiHub-0.5.0-windows-x64-full.zip (portable + MES/JRE) | 266.4 | `a55f5b6b931e3477d0fb91cdb753d0dbd6d455a0a91d4daea3e8cf23b8c97ce7` |

Kèm `SHA256SUMS-0.5.0.txt`, `YomiHub-RootCA.cer`, `Install-YomiHub.bat/.ps1`, `YomiHub-0.5.0-changelog.md`; ảnh/video kiểm thử Android/TV: `output/YomiHub-0.5.0-QA-screenshots.zip`.

#### I. GitHub
- Mã nguồn: commit trên `main` của `kiritokmn1403/YomiHub-Project` (Git for Windows + Git Credential Manager có sẵn trên máy; token không ghi ra log/tệp). Release `v0.5.0` (Latest) tải bằng `release_050.ps1`, có bước so kích thước từng tệp. README có bảng link tải 0.5.0. Kết quả: xem `jobs/done/x050_*release*.log`.
