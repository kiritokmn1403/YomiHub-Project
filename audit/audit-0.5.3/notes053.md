
### 06/11/2026 — Cập nhật phiên bản 0.5.3 (YomiHub 0.5.3+45)

Thực hiện: Claude.
- **Đợt 1** (phiên chat claude.ai, không nối với máy): phân tích log, sửa mã. Kết quả là `YomiHub-0.5.3-part1.patch` + HANDOFF (`files.zip`).
- **Đợt 2** (phiên Cowork nối máy `kiritokmn-lap`, 06/11/2026 14:40 → __END__ Asia/Saigon): áp đợt 1, làm các mục còn lại, dựng, kiểm thử, phát hành.
- Người dùng đã xác nhận bản tóm tắt yêu cầu và cho toàn quyền điều khiển máy. Các lựa chọn đã chốt:
  - Giữ **Android 7.0+** và **Windows 10/11 x64**. Android 6.0 và Windows 7/x86/ARM vẫn bị chặn bởi Isar/libmdbx, Flutter và WebView2, như ghi ở 0.4.4–0.5.2.
  - Tiện ích website: **chỉ tự thêm kho**, không tự cài tiện ích nào.
  - Thiết bị kiểm thử: **tự dò bằng adb**. Kết quả là Galaxy Note 9 SM-N960N (Android 10, Samsung DeX, màn ảo 1920×1080, display 2).

#### A. Yêu cầu
1. Nâng lên 0.5.3, gồm:
   - 3 APK điện thoại.
   - 3 APK `YumiHub Android TV` (bỏ Comic, Novel, Google Play Books, Booru).
   - Windows: `.appxbundle`, `Setup.exe`, portable.
2. `Project YomiHub.xlsx`:
   - `Feature Check` (45 mục).
   - `YomiHub Update` (9 mục, bên dưới).
   - Các sheet `Website Extension`, `Extension Repo`, `Website Update Apps`, `Website Scan`.
3. `Project GitHub.xlsx`: 605 liên kết khác nhau.
4. Sửa lỗi và cảnh báo trong `logs 3.txt`: 3.288 dòng, 30/10 06:09 → 06/11 14:10, 138 ERROR, 345 WARNING.
5. Ghi tài liệu này; dựng; kiểm thử có ảnh và video (riêng VPN kiểm tra ngoài ứng dụng); đẩy mã nguồn, Release và README lên GitHub.

YomiHub Update:
- (1) Nhật ký.
- (2) Chuyển tiện ích sheet *Website Extension* sang `Kiritokmn---Extension-Repo` và gỡ khỏi ứng dụng.
- (3) Dự án GitHub còn thiếu.
- (4) Mục "Sao Lưu & Đồng Bộ" ở Cài đặt và Thêm.
- (5) Đưa công tắc Google Play Books và Booru App vào "Bật/Tắt tính năng & Nguồn mở rộng".
- (6) Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, Mangayomi Server.
- (7) Tracker theo AnymeX, AniSync, Tankobun, Rokku; ô cài đặt và ô nhập không bị thanh hệ thống che.
- (8) Treo, lag, văng.
- (9) Windows, AMD Ryzen 9.

#### B. Công cụ
- **Git / GitHub Desktop**:
  - Git for Windows (`D:\yh\tools\git`): `git status`, `git apply --check` / `git apply` (patch đợt 1), `git rm --cached`, commit, push.
  - Credential Manager của GitHub Desktop dùng để push và gọi API Release; token không bao giờ in ra.
- **Sửa mã**:
  - `audit-0.5.3/edit.py`: thay chuỗi; `assert` chuỗi cũ xuất hiện đúng 1 lần; chép bản gốc vào `audit-0.5.3/before/`; ghi `changed_files.txt`.
  - Các kịch bản `audit-0.5.3/scripts/e01_player_proxy.py` … `e06_mal_export_sync.py`.
  - Bản dịch: `tr053a.py`, `tr053b.py` (18 ngôn ngữ).
- **Dựng**:
  - `sync_053.ps1`, `build_053.ps1` (sinh từ 0.5.2).
  - Flutter 3.47.6 / Dart 3.13.5, Gradle, Rust/Cargo, Android SDK, Visual Studio 2022 Build Tools, WiX/NuGet.
  - Runner `3_run_jobs.bat` / `3b_run_fast_jobs.bat` (`audit-0.5.3/job.sh`, `wait.sh`, `adb.sh`).
- **Kiểm thử**:
  - Thiết bị và AVD: adb (`input -d 2`, `screencap -d 2`), Android Emulator (`Medium_Phone_API_37.0` Android 17, `YomiHub_TV_API34`).
  - Video: `framerec.ps1` (screencap liên tục của màn DeX → ffmpeg MP4).
  - Kiểm tra trang và mạng: `curl.exe --doh-url`.
  - Kiểm tra JS: `node --check`.
  - `openpyxl` đọc Excel; `git clone --depth 1` để quét 9 dự án GitHub.
  - Computer use cho bản Windows.

#### C. Lỗi trong `logs 3.txt` (sau khi cài 0.5.2, 06/11 11:39 → 14:10) – nguyên nhân và cách sửa

| # | Dòng log | Nguyên nhân | Sửa (tệp) | Kiểm thử |
| --- | --- | --- | --- | --- |
| 1 | `[WARNING] [Hiệu năng] Giao diện bị treo 3.3 giây` (13:40:53, đúng lúc tự sao lưu 27,8 MB) | `writeMangayomiBackupZip` đọc ~88.000 chương bằng `findAllSync()` và `toJson()` hàng loạt trên luồng UI | `backup.dart`: `getAllAsync()` + `_toJsonInBatches()` (lô 1.000, nhường event loop) – đợt 1 | Note 9: tạo bản sao lưu 23,9 MB trong 13 s, có vòng quay chờ, log không còn "Giao diện bị treo" |
| 2 | `[WARNING]` rỗng + `Logger initialized` (73 lần) | Mốc phiên ghi ở mức WARNING kèm xuống dòng | `logger.dart`: `[INFO] ===== Logger initialized (phiên mới) =====` – đợt 1 | log Note 9 15:44: một dòng INFO |
| 3 | `[Thư mục cục bộ] Bỏ qua EPUB hỏng …Bản Lĩnh Putin…` lặp lại mỗi lần mở | Quét lúc khởi động chạy trước khi box Hive `yomihub_prefs` mở → danh sách `badEpubs` không đọc/ghi được | `file_scanner.dart`: chờ `YomiPrefs.ready` (tối đa 5 s) – đợt 1 | test `yh_053` |
| 4 | `Shorts FapReel (18+): lỗi phát video: Failed to open https://cdncontent.imctransfer.com/…?token=…` ×2 | `curl` từ PC (cùng mạng): URL đúng trong log vẫn trả **206** (token còn hạn, không chặn DNS); trang nay phát `/ig/<id>.mp4` trên chính fapreel.com. Nguyên nhân khả dĩ nhất: Tor / Mihon Proxy / proxy riêng định tuyến yêu cầu của tiện ích qua proxy, nhưng libmpv nối thẳng → token CDN gắn với IP proxy bị từ chối. Ngoài ra: lỗi do trình phát bị huỷ khi rời màn Shorts cũng bị ghi | Mới `lib/yomihub/player/player_net.dart` (`YomiPlayerNet`): đặt `http-proxy` của mpv theo đúng tuyến của nguồn, **chỉ với tệp tiến trình (mp4/webm/mkv/mov)**; Shorts: nếu phát qua proxy lỗi thì tự thử lại 1 lần nối thẳng rồi mới ghi log; bỏ lỗi phát sinh sau khi màn hình đã đóng. Trình phát chính (`anime_player_view.dart`) dùng cùng quy tắc | Note 9: Tor toàn thiết bị + HotPhim (HLS) → mpv kẹt vòng quay > 5 phút ở bản dựng 1 (áp proxy cho mọi URL) → bản dựng 2 giới hạn ở tệp tiến trình; test `yh_053` |
| 5 | `Hệ thống báo thiếu bộ nhớ`, `Image/network load failed` | Thông tin (ảnh bìa trang nguồn hỏng, hệ thống thu hồi RAM) | Không sửa | – |
| 6 | (phát hiện khi test) `[Kho tiện ích] Không tải được kho kohiden.xyz … CERTIFICATE_VERIFY_FAILED` | Chứng chỉ TLS của kohiden.xyz (trang nguồn) | Đã xử lý là lỗi mạng (WARNING, 1 lần/phiên) từ 0.5.2 | – |

Việc tồn từ 0.5.2 (đợt 1):
- **Bản Windows tự sao lưu vào đường dẫn Android.**
  - Cách sửa: `auto_backup.dart › _isUsableBackupLocation`.
  - Đợt 2 bổ sung (lỗi tìm thấy khi kiểm thử): trên Android, vị trí tự sao lưu nằm trên thẻ nhớ đã tháo (`/storage/7563-670C`) cũng bị coi là không dùng được. Khi đó ứng dụng lưu vào thư mục mặc định, còn màn "Sao Lưu & Đồng Bộ" ghi đường dẫn bằng chữ đỏ.

#### D. Sheet "YomiHub Update"

**Mục 2 – Chuyển tiện ích website sang kho Kiritokmn**

1. Kho `kiritokmn1403/Kiritokmn---Extension-Repo`, commit `4fc3839` và `152678e`:
   - Thư mục `sources-yomihub/`: 29 tiện ích + `_common.js` + `meta.json`.
   - Công cụ `tools/build/yomihub-sources.mjs` (gọi từ `build-all.mjs`) ghi `repo/yomihub/<tệp>.js`. Mỗi tệp tự chứa, kiểm tra bằng `node --check` 29/29 đạt.
   - `repo/index.json` thêm 29 mục **cùng id 920260001…** (version 0.5.3). 20 mục vBook→Mangayomi trùng trang web bị bỏ khỏi `index.json`. README, CHANGELOG và TECHNICAL_UPDATE_NOTES của kho đã cập nhật.
2. Ứng dụng:
   - `builtin_extensions.dart`: bỏ cài/cập nhật mã tích hợp (danh sách chỉ còn giữ id cho Shorts và tên miền dự phòng).
   - `install()` chạy **một lần**, trước khung hình đầu (`main.dart`, ngay sau khi mở DB). Hàm này thêm kho `…/repo/index.json` vào Truyện tranh / Phim & Điện ảnh / Tiểu thuyết (không trùng) và đổi các tiện ích đã cài sang `isLocal=false` + `repo` + `sourceCodeUrl` của kho. Kết quả được ghi log.
   - Gỡ 29 tệp khỏi `overlay/assets/yomihub_extensions` (bản gốc ở `audit-0.5.3/before/`). Chỉ giữ `_common.js`, `vbook.js`, `kotatsu.js`, `ireader.js`.
3. Kiểm thử trên Note 9:
   - Log: `[Tiện ích] 0.5.3 … đã thêm kho "Kiritokmn Extension Repo" … 29 tiện ích đã cài được chuyển sang nhận cập nhật từ kho này`.
   - "Quản lý URL kho Phim & Điện ảnh" có "Kiritokmn Extension Repo".
   - Tab Tiện ích: AVSub, Anime47, AnimeVN, HayChill, HiHiPhim, HotPhim… hiện "… – Kiritokmn Extension Repo" và "Đang chờ cập nhật". Cập nhật HotPhim và Anime47 thành công.
   - HotPhim tải Phổ biến, mở chi tiết, phát phim: mpv có luồng âm thanh `state:started`. Ảnh màn video đen vì DeX không chụp được surface video.
   - Android TV (AVD): HotPhim từ kho tải được, có viền focus.
4. Lỗi tìm thấy khi kiểm thử: ghi chú "(YomiHub 0.5.3 – Kiritokmn Extension Repo)" chạy thành dải chữ trên màn nguồn. Đã sửa trong kho, chỉ giữ ghi chú gốc.

**Mục 3 – Dự án GitHub**
- So khớp 605 liên kết của `Project GitHub.xlsx` (gồm cả hyperlink ô) với `github_projects.dart` (643 liên kết, sau khi đợt 1 thêm 19 liên kết).
- Kết quả: **0 thiếu**.

**Mục 4 – "Sao Lưu & Đồng Bộ"**
- `DataAndStorage(backupSync: true)`, route `/backupSync`, gồm:
  - Tạo / khôi phục sao lưu, Hoàn tác thay đổi gần nhất.
  - Tần suất, mã hoá, mức nén, vị trí sao lưu.
  - Sao lưu đám mây.
  - **Đồng bộ** (`/sync`).
  - **Sao lưu dữ liệu Booru App** (công tắc `backupBooru`, `YomiBackupExtras` bỏ box `yomihub_booru` khi tắt).
- Mục này có ở **Cài đặt** (thay mục "Đồng bộ" và "Sao lưu đám mây" cũ) và ở **Thêm**.
- "Dữ liệu và bộ nhớ" chỉ còn lập chỉ mục, vị trí tải, công cụ thư viện, bộ nhớ, cùng một ô dẫn sang "Sao Lưu & Đồng Bộ".
- Note 9: ảnh `n9_53_03`, `n9_53_04`, `n9_53_14`.

**Mục 5**
- Ô Google Play Books và Booru App chuyển từ Cài đặt sang "Bật/Tắt tính năng & Nguồn mở rộng › Tính năng khác" (ẩn trên Android TV).
- Note 9: ảnh `n9_53_15`.

**Mục 6 – Quét 6 dự án** (`git clone --depth 1`, đọc README và mã):

| Dự án | Kết quả |
| --- | --- |
| Mangayomi Server | Tác giả đã ngừng hỗ trợ và chuyển sang `not-akari/mangayomi-sync-server` → nút "Lấy máy chủ đồng bộ" trỏ tới máy chủ mới (`sync.dart`). Mục Đồng bộ nay nằm trong "Sao Lưu & Đồng Bộ" |
| Yomikiru (Electron, đọc offline) | Các tính năng chính (đọc dọc/LTR/RTL, 2 trang, webtoon, chủ đề, phím tắt, EPUB, CBZ/CBR/7z, AniList, lịch sử/bookmark) YomiHub đã có từ trước – không thêm |
| Yomihon (miyomi.app, không có mã nguồn công khai) | Không quét được mã |
| Zenshin (Electron + WebTorrent, AniList) | Phát torrent + AniList: YomiHub đã có máy chủ torrent (`libmtorrentserver`) và tracker AniList – không thêm |
| Nyora (fork Kotatsu: dịch cả trang, 1100+ nguồn, đồng bộ đám mây) | Nguồn Kotatsu (cầu nối Kotatsu), dịch ảnh và đồng bộ đám mây đã có; Nyora Cloud cần tài khoản dịch vụ riêng – không tích hợp |
| Nuvio (Kotlin Multiplatform, addon Stremio) | Addon Stremio là một hệ nguồn khác (API Stremio); chưa làm ở 0.5.3, ghi lại làm việc tồn |

**Mục 7 – Tracker**

| Dự án | Kết quả |
| --- | --- |
| AnymeX | AniList / MAL / Simkl: YomiHub đã có cả 3 (và Kitsu, Trakt, MangaUpdates, Shikimori, Bangumi, Kavita, Suwayomi) |
| AniSync | Client AniList (feed, forum, widget) – ngoài phạm vi theo dõi tiến độ |
| Tankobun | **Mới**: "Xuất danh sách MyAnimeList (XML)" (`lib/yomihub/trackers/mal_export.dart`, Cài đặt › Theo dõi). Mục MAL dùng MAL id; mục AniList được ghép sang MAL qua `idMal` (GraphQL, 50 mục/lần). Tệp ghi vào `…/backup/export/YomiHub_MAL_{anime,manga}_<ngày>.xml`, nhập được vào myanimelist.net/import.php, AnymeX, Taiga |
| Rokku | Màn lỗi cập nhật thư viện (`updateErrorsProvider`) và lọc NSFW đã có – không thêm |

Che bởi thanh hệ thống (yêu cầu bắt buộc):
- `tracker_search_widget.dart`: chiều cao lấy từ `MediaQuery.padding` của trang ngoài. Ở chế độ edge-to-edge (Android 15+) giá trị này bằng 0, nên ô tìm nằm dưới thanh điều hướng hoặc bàn phím. Nay dùng `SafeArea` + `LayoutBuilder` + `resizeToAvoidBottomInset`.
- `tracking_menu.dart`: lấy khoảng đệm dưới ở trang mở menu.
- `track.dart`: thêm đệm cuối danh sách; hộp Kitsu `scrollable: true`.
- `tracking_detail.dart`: `SafeArea(top: false)`.
- Emulator Android 17 (1080×2400, gesture bar): hàng cuối "Xuất danh sách MyAnimeList (XML)" nằm trên thanh cử chỉ; hộp "Đăng nhập vào Kitsu" có bàn phím mở vẫn thấy đủ 2 ô và nút. Ảnh `emu_53_05`, `emu_53_06`.
- Note 9: Xuất XML khi chưa đăng nhập tracker báo "anime 0, manga 0" → bản dựng 2 báo rõ "Không có mục nào đang theo dõi…".

**Mục 8 – Treo / lag / văng:** xem C1–C3.
- Tạo bản sao lưu không còn chặn UI.
- Không có lỗi hay văng trong log Note 9 của phiên kiểm thử.

**Mục 9 – Windows (Ryzen 9):**
- Không có máy Ryzen. 0.5.2 đã thêm VC++ runtime và gói Setup đầy đủ (Java + M-Extension-Server) cùng chẩn đoán vào log.
- 0.5.3 thêm màn **Cài đặt › Chẩn đoán Windows** (`win_diag_screen.dart`). Màn này hiện CPU, số luồng, GPU + driver, WebView2, Java, thư mục cài, các thành phần thiếu kèm tính năng bị tắt; có nút "Kiểm tra lại" và "Mở thư mục cài đặt". Người dùng máy Ryzen tự thấy được thiếu gì, không phải đọc `logs.txt`.

#### E. Dựng và kiểm thử
__BUILD__

#### F. Phát hành
__RELEASE__

#### G. Giới hạn và việc tồn
- Android 6.0, Windows 7, x86, ARM: không hỗ trợ (giữ như 0.5.2; người dùng đồng ý).
- FapReel Shorts:
  - Chưa tái hiện được lỗi trên máy thử. URL trong log vẫn phát được từ PC.
  - Bản sửa (proxy cho trình phát + tự thử lại nối thẳng) dựa trên phân tích mã.
  - Nếu còn lỗi, cần `logs.txt` kèm trạng thái VPN lúc lỗi.
- WARP trên mạng Wi-Fi hiện tại của Note 9 không bắt tay được qua cả 5 cổng UDP. Ứng dụng tắt đường hầm và báo lỗi đúng như thiết kế 0.5.2. Kiểm tra VPN ngoài ứng dụng dùng **Tor toàn thiết bị**: Chrome mở `check.torproject.org` → "Congratulations. This browser is configured to use Tor." (IP 5.2.69.82).
- Video trên Samsung DeX: `screencap` không chụp được surface video (ảnh đen). Đã xác nhận phát bằng trạng thái AudioPlayer của hệ thống.
- Nuvio (addon Stremio) và Nyora Cloud chưa tích hợp. Yomihon không có mã nguồn.
- Ảnh hoặc video có thư viện cá nhân được đặt tên `PRIVATE_*` / `n9v053_*` và không đưa vào gói QA công khai.
