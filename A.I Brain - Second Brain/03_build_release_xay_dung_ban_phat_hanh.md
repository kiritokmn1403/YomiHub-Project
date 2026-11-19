# Xây dựng bản phát hành

## Dây chuyền dựng
- Job dài `jobs/pending/x<ver>_build_main.ps1` → `scripts/pipeline/run_<ver>_main.ps1` chạy tuần tự: **sync → test → apk → tv → wintest → win → pack → a6build → a6copy → verify** (lọc bước bằng `-RunSteps pack,a6build,...`, tách chuỗi theo dấu phẩy).
- Script con nằm trong **`scripts/build/`**: `scripts/build/build_<ver>.ps1` (Windows: test, win, pack, verify; chuyển tiếp tác vụ Android), `scripts/build/build_<ver>_android.ps1` (test, apk, tv, a6 copy + kiểm chữ ký/ABI/nhãn), `scripts/build/build_<ver>_android6.ps1` (dựng APK Android 6 trong `D:\yh\build23`). `$root` = thư mục cha của `$PSScriptRoot`. Phụ trợ ở gốc: `scripts/sync/sync_<ver>.ps1` (`-Regen`), `scripts/packaging/make_installer_exe_<ver>.ps1` (Setup.exe C# tự viết, nhúng zip, ký Authenticode chứng chỉ nội bộ), `scripts/packaging/make_appxbundle_<ver>.ps1`, `scripts/release/release_<ver>.ps1`.
- Trạng thái: `audit/audit-<ver>/release/main_build_status_<ver>.txt` (+ transcript `.log`); khóa `audit/audit-0.5.6/coordination/BUILD_LOCK.txt` (giết tiến trình dựng thì phải xóa nội dung khóa).
- Lệnh Flutter cốt lõi (đã bọc trong script): `flutter build apk --no-pub --release --split-per-abi --target-platform android-arm,android-arm64,android-x64 --build-name <x.y.z> --build-number <N> --split-debug-info D:\yh\symbols_<ver> <dart-defines>`; TV thêm `--dart-define=IS_TV_BUILD=true --dart-define=APP_NAME=YumiHub Android TV`; `flutter build windows --release`.
- Mốc thời gian 0.5.9: test 10' → APK 24' → TV 33' → wintest 9' → win 19' → pack 5' → a6build 37' → verify 2' (~2 giờ 20).

## Sản phẩm (`output/<ver>/`)
- `YomiHub-<ver>-{arm64-v8a,armeabi-v7a,x86_64}.apk`, `YomiHub-<ver>-android6-*.apk`, `YumiHub-Android-TV-<ver>-*.apk`
- `YomiHub-<ver>-windows-x64-Setup.exe`, `.appxbundle` (phiên bản 4 phần `x.y.z.0`), `.zip` (portable), `-full.zip` (kèm Java cho máy chủ tiện ích)
- `YomiHub-RootCA.cer`, `Install-YomiHub.bat/.ps1`, `SHA256SUMS-<ver>.txt`, `YomiHub-<ver>-changelog.md` (thân Release lấy từ đây; không còn `<<placeholder>>`)

## Phát hành
1. **Chủ dự án xác nhận rõ trong chat** (bộ phân loại an toàn chặn nếu không).
2. Đẩy repo tiện ích nếu có thay đổi (`git push` trong Kiritokmn - Extension Repo).
3. `scripts/release/release_<ver>.ps1` (job dài): token từ Git Credential Manager lúc chạy; tạo Release `v<ver>` (make_latest), tải asset bằng curl (thử lại), tự đối chiếu kích thước; đính kèm `TECHNICAL_UPDATE_NOTES.md`. 19 tệp ~2,9 GB mất ~19 phút. Lỗi 409 bật Pages = đã bật sẵn.
4. Xác minh độc lập: API `releases/tags/v<ver>` (số asset, size khớp `output/`).
5. README chỉ giới thiệu + nút Download → `releases/latest`; trang chủ GitHub Pages tự lấy link bản mới nhất (không cần sửa mỗi bản).
6. **APKPure** (`developer.apkpure.com`, tài khoản "Kiritokmn", dùng Cốc Cốc): tab "Phiên bản quản lý" → tải APK arm64 mới (versionCode phải > bản trước, 0.5.9 = 2052) + "What's new" → chờ xác minh → "Công bố" → chờ duyệt. Tư liệu trang: `audit/audit-0.5.9/apkpure/`.
7. Ghi kết quả vào ghi chú kỹ thuật (mục 1 + nhật ký), Second Brain; tự lưu push.

## Bổ sung 19/11/2026 (0.6.0)
- Đường dẫn mới: `scripts/pipeline/run_<ver>_main.ps1` → `scripts/sync/`, `scripts/build/`, `scripts/packaging/`; phát hành `scripts/release/release_<ver>.ps1`. Script trong `scripts/<nhóm>/` lấy gốc dự án = 2 cấp trên `$PSScriptRoot`; `scripts/lib/common.ps1` đặt `$KIT` = gốc dự án.
- Khi tạo bộ script cho bản mới bằng cách chép bản trước: grep chuỗi phiên bản cũ trong mọi script mới (0.6.0 còn `Version="0\.5\.9\.0"` ở verify AppxBundle → sửa trước khi chạy).
- Dừng dây chuyền giữa chừng (khi chủ dự án đổi yêu cầu): job nhanh `taskkill /T /F` PowerShell của job + xóa nội dung `BUILD_LOCK.txt`; chạy lại một phần bằng `run_<ver>_main.ps1 -RunSteps 'apk,tv,...'`.
- Thời gian 0.6.0 trên máy quá tải: test 3–26' → apk 34' → tv 30' → wintest 2–4' → win ~20' → pack 3' → a6build ~25' → verify 2'; tải 19 asset (~2,3 GB) ~7 phút (5–6 MB/s).
- Thêm phần tiếng Anh vào changelog SAU bước verify → phải cập nhật dòng băm changelog trong `SHA256SUMS-<ver>.txt` (hoặc chạy lại `-RunSteps verify`) trước khi chạy release.
- README (19/11) theo mẫu "Standard" của The Documentation Compendium: logo `assets/logo/yomihub_logo_1024.png`, huy hiệu, nút Download → `releases/latest`, Mục lục, Giới thiệu, Bắt đầu, Kiểm thử, Sử dụng, Dựng & phát hành, Công nghệ, Tác giả, Ghi nhận. Mọi tính năng ghi trong README phải grep được trong `overlay/lib`.

## Bổ sung 19/11/2026 (0.6.1)
- Trước khi chạy `release_<ver>.ps1`: README ← bản nháp `audit/audit-<ver>/release/README_<ver>.md`; `docs/index.html` đổi mọi link tĩnh + chữ "phiên bản" sang bản mới (grep không còn số bản cũ); để autosave hoặc job git đẩy lên trước khi tạo Release.
- Job phát hành: `jobs/pending/x<ver>_release.ps1` gọi `scripts\release\release_<ver>.ps1` (đường dẫn mới, không còn ở gốc). 0.6.1: 19 tệp ~2,9 GB trong ~11 phút.
- Giao Antigravity /swarm theo dõi API Release + kiểm link sau phát hành (brief mẫu `audit/audit-0.6.1/antigravity/BRIEF_swarm3_061.md`).
