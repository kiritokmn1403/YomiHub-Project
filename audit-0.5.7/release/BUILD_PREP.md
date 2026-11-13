# Chuẩn bị dựng và phát hành YomiHub 0.5.6.1 (0.5.6+49) — 13/11/2026

Trạng thái: **chỉ chuẩn bị**. Chưa chạy flutter build, chưa lấy BUILD_LOCK, chưa bật máy ảo, chưa ghi `output/0.5.6`, chưa commit. Cả 8 script đã qua `Parser::ParseFile` không lỗi (job `p0561_syntax`, log `jobs/done/p0561_syntax.log`). `release_0561_publish.ps1` chạy khô dừng đúng ở "missing output\0.5.6.1" (chưa có gói), các kiểm git phía trước (nhánh main, origin, tag v0.5.6, pubspec +49, userAgent) đã qua.

## 1. Tệp đã sửa
| Tệp | Thay đổi |
| --- | --- |
| `overlay/pubspec.yaml` | `version: 0.5.6+49` (hiển thị 0.5.6.1 truyền bằng `--build-name 0.5.6.1 --build-number 49`) |
| `overlay/lib/yomihub/app_identity.dart` | `userAgent = 'YomiHub/0.5.6.1'` |
| `build_0561_android6.ps1` | thêm tham số `-buildNumber` (mặc định 49) → `--build-number`, kiểm `versionCode` (1000/2000/4000 + 49) ở bước verify; phần vá không đổi |
| `.gitignore` | thêm các thư mục nặng của `audit-0.5.7` (vpn/apk, vpn/evidence, android6/{evidence,work,out,orig_libisar,patched_libisar,patched_libtor,tmp}, backup). Giữ *.md, *.py, *.ps1, `build23_patch/`, `jnilibs23/MANIFEST.txt`, mã nguồn nhỏ |
Test: không cần sửa. Mọi test kiểm phiên bản dùng `startsWith('YomiHub/0.5.')`, `contains('version: 0.5.')`, `contains('version: 0.5.6')` (yh_050–055) nên vẫn đạt với 0.5.6+49 / `YomiHub/0.5.6.1`; không có test nào chứa `+48`/`'48'`.

## 2. Tệp tạo mới (gốc dự án, UTF-8 BOM)
| Tệp | Nguồn | Ghi chú |
| --- | --- | --- |
| `sync_0561.ps1` | sync_056.ps1 | manifest `audit-0.5.7/release/changed_files_0561.txt`; `-Regen` tạo lại từ git (diff HEAD + tệp mới trong overlay); kiểm pubspec +49; sao lưu `audit-0.5.7/backup`; không xóa gì |
| `build_0561_android.ps1` | build_056_android.ps1 | `-step test\|unit\|apk\|tv\|a6\|verify\|all`. apk/tv dựng thật với `--build-name 0.5.6.1 --build-number 49`, chặn APK cũ (mtime < lúc bắt đầu, R19), đối chiếu nâng cấp với `output\0.5.6`; `a6` chép + kiểm 3 APK android6 (versionName, versionCode 1049/2049/4049, minSdk 23, ABI, chữ ký) vào `output\0.5.6.1`; giữ BUILD_LOCK `B0561` |
| `build_0561.ps1` | build_056.ps1 | `-step test\|win\|pack\|verify\|all`; `apk/tv/a6` chuyển sang build_0561_android.ps1; build Windows có `--build-name/--build-number`; `version.json` = 0.5.6.1 / 49; changelog lấy `audit-0.5.7/release/YomiHub-0.5.6.1-changelog.md`; kiểm đủ 17 tệp (13 gói + 3 android6 + changelog) — `verify` chặn nếu thiếu, `pack` chỉ cảnh báo; SHA256SUMS-0.5.6.1.txt (LF, không BOM); kiểm Version=0.5.6.1 trong AppxBundleManifest |
| `make_appxbundle_0561.ps1`, `make_installer_exe_0561.ps1` | make_appxbundle.ps1, make_installer_exe.ps1 | bản gốc suy phiên bản từ pubspec (0.5.6 → appx 0.5.6.0). Bản sao này cố định `0.5.6.1` cho tên tệp, MSIX/bundle Version, AssemblyVersion; kiểm ProductVersion exe theo `0.5.6*` |
| `release_0561_publish.ps1`, `release_0561_fixed.ps1` | release_056_publish.ps1, release_056_fixed.ps1 | xem mục 5 |
| `audit-0.5.7/release/YomiHub-0.5.6.1-changelog.md`, `README_release_section_0561.md`, `TECHNICAL_NOTES_0.5.6.1_section.md` | bản nháp | chỗ trống `<<KẾT QUẢ VPN>>`, `<<KẾT QUẢ ANDROID6>>`, `<<NGÀY PHÁT HÀNH>>` |
| `audit-0.5.7/release/changed_files_0561.txt` | git | 10 tệp overlay đang khác HEAD tại 00:43 13/11 (VPN Dart/Kotlin, YomiWg.kt, 2 test VPN, pubspec, app_identity) |

## 3. Lệnh dựng theo thứ tự (PowerShell, gốc dự án; chạy qua job `jobs/pending_fast/*.ps1` với dòng đầu `# timeout: <phút>`)
Điều kiện: hai agent VPN/Android 6.0 đã xong và mã overlay đã đóng băng; BUILD_LOCK trống; chỉ một máy ảo chạy một lúc (tuần tự bên dưới không dùng máy ảo).
| # | Lệnh | Ước lượng |
| --- | --- | --- |
| 0 | `.\sync_0561.ps1 -Regen` (tạo lại manifest từ git rồi chép sang `D:\yh\build\mangayomi` và `D:\yh\buildwin\mangayomi`) | 1–2 phút |
| 1 | `.\build_0561_android.ps1 -step test` (pub get, gen-l10n, analyze, flutter test gồm 2 test VPN + yh_040–056) | 8–12 phút |
| 2 | `.\build_0561_android.ps1 -step apk` (3 APK điện thoại) | 15–25 phút |
| 3 | `.\build_0561_android.ps1 -step tv` (3 APK TV; trả `app_name` về YomiHub) | 15–25 phút |
| 4 | `.\build_0561_android6.ps1` (= all: sync build23 từ `build\mangayomi` → patch → apk → post → verify; PHẢI chạy sau 0–3 để lấy mã đã đồng bộ và build-number 49) | 16–22 phút |
| 5 | `.\build_0561_android.ps1 -step a6` (chép + kiểm 3 APK android6 vào `output\0.5.6.1`) | 1–2 phút |
| 6 | `.\build_0561.ps1 -step test` (test Windows) rồi `.\build_0561.ps1 -step win` (flutter build windows + zip + full.zip) | 5 + 15–25 phút |
| 7 | `.\build_0561.ps1 -step pack` (Setup.exe, .appxbundle, RootCA, Install-*; chép changelog; SHA256SUMS; kiểm Windows) | 5–10 phút |
| 8 | `.\build_0561_android.ps1 -step verify` và `.\build_0561.ps1 -step verify` (kiểm lại đủ 9 APK + 4 gói Windows + 17 tệp) | 3–5 phút |
| 9 | `.\release_0561_publish.ps1` (dry-run, mặc định; in kế hoạch, không đổi gì) | 1 phút |
Tổng: khoảng 1,5–2,5 giờ (chủ yếu 2, 3, 4, 6 — gradle/flutter). Có thể chạy 6–7 (Windows) song song với 2–4 chỉ khi đổi `YH_ROOT`/BUILD_LOCK được phối hợp; mặc định tuần tự vì cùng giữ BUILD_LOCK.
Phát hành thật (chỉ sau "MỐC DUYỆT 0.5.6.1" trong REVIEW_CLAUDE.md và sau khi điền chỗ trống):
`.\release_0561_publish.ps1 -Execute -ReleaseDate dd/MM/yyyy -VpnResult "<tóm tắt>" -Android6Result "<tóm tắt>"` (hoặc sửa thẳng 3 bản nháp rồi chạy không có hai tham số cuối).

## 4. Điểm cần chú ý khi dựng
1. **APK android6 hiện có trong `audit-0.5.7/android6/out/` được dựng khi pubspec còn +48** → versionCode 1048/2048/4048; bước `a6` và `verify` sẽ báo lỗi cho đến khi dựng lại bằng `build_0561_android6.ps1` (đã có build-number 49 và kiểm versionCode).
2. `build_0561_android6.ps1` bước patch sửa chặn `SDK_INT < 24` trong `YomiVpn.kt`/`YomiTunnels.kt` bằng regex; agent VPN đang đổi hai tệp này (V7/V8, `YomiWg.kt`) nên phải xem log `patch` — nếu regex không khớp script báo "VÁ THẤT BẠI" chứ không bỏ qua im lặng. Có bản tham chiếu `audit-0.5.7/android6/build23_patch/`.
3. `build23` cần `jnilibs23/` còn nguyên (bị .gitignore nhưng có trên đĩa); engine Flutter phải vẫn là 692136cb (script kiểm).
4. Windows: `flutter build windows --build-name 0.5.6.1 --build-number 49` — ProductVersion của `YomiHub.exe` có thể là `0.5.6.1` hoặc `0.5.6.49`; kiểm của installer chỉ so tiền tố `0.5.6`. Chứng chỉ `.appxbundle` lấy từ kho chứng chỉ hiện có (cùng chủ thể CN=YomiHub) nên người đã cài RootCA 0.5.6 không phải cài lại.
5. Test trong `build_0561_android.ps1`: bỏ qua (cảnh báo) test không có trong build dir, nhưng bắt buộc có `yh_0561_vpn_resume_test.dart`, `yh_057_vpn_test.dart`, `yh_055_test.dart`.
6. `build_0561.ps1 -step all` = test + win + pack (+ SHA256 + verify Windows); không dựng APK. APK/TV/android6 dựng riêng (bước 2–5).

## 5. Phát hành (`release_0561_publish.ps1`, `release_0561_fixed.ps1`)
- Mặc định dry-run; `-Execute` mới ghi. Chặn nếu còn `<<…>>` (khi -Execute), tag `v0.5.6.1` đã tồn tại (cục bộ hoặc origin), nhánh khác main, origin sai, `v0.5.6` không phải tổ tiên của HEAD, thiếu/0 byte một trong 16 tệp bắt buộc, có tệp lạ trong `output\0.5.6.1` (trừ khi `-AllowExtra`), chuỗi nhạy cảm/tệp quá 50 MB/đuôi cấm trong tập sắp commit (tập này lấy từ `git ls-files -c -o --exclude-standard`, nên thư mục nặng đã bị .gitignore không bị quét).
- Danh sách `git add` tường minh: `overlay`, README.md, TECHNICAL_UPDATE_NOTES.md, .gitignore, 8 script mới, `audit-0.5.7`, `audit-0.5.6/coordination`. Không `git add -A`. Chặn staged thuộc `output|src|jobs|fetch|logs`, apk/zip/exe/appxbundle/jks/mp4/png và các thư mục nặng của audit-0.5.7.
- Commit "release: YomiHub 0.5.6.1 (0.5.6+49)" (kèm 2 dòng ghi công), tag chú giải `v0.5.6.1`, `git push origin main` và `git push origin v0.5.6.1` (không `--force`), kiểm `v0.5.6` không đổi SHA. Release tên "YomiHub 0.5.6.1" (`release_0561_fixed.ps1`, từ chối mọi tag khác `v0.5.6.1`), assets = mọi tệp trong `output\0.5.6.1` + TECHNICAL_UPDATE_NOTES.md, SHA256SUMS-0.5.6.1.txt (LF, không BOM), kiểm tên + kích thước từng asset sau khi tải.
- README: chèn mục 0.5.6.1 (link `releases/download/v0.5.6.1/<tên>`, dòng ghi APK android6 dành cho Android 6.0) phía trên khối 0.5.6, khối cũ đổi thành "Phiên bản trước: 0.5.6". TECHNICAL_UPDATE_NOTES: chèn dòng tóm tắt đầu mục 1 và thêm mục 0.5.6.1 ở cuối (chặn chạy lại nếu đã có "0.5.6.1 (0.5.6+49)").
- Lưu ý: `TECHNICAL_UPDATE_NOTES.md` hiện đã có các mục 0.5.6.1 do các agent khác viết (chưa commit); mục chèn thêm của script là bản tổng hợp, có thể bỏ bớt trùng lặp trước khi chạy.

## 6. Còn thiếu / việc người dùng
- Điền 3 chỗ trống; viết kết quả VPN (V7/V8 chưa có bằng chứng AVD trong VPN_FIX.md) và Android 6.0 (bảng mục 6 của A6_FEASIBILITY.md còn "điền ở dưới").
- Chưa chạy bất kỳ bước dựng nào; chỉ kiểm cú pháp.
