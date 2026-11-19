# Dựng YomiHub từ mã nguồn (BUILDING)

Hướng dẫn cho người phát triển. Người dùng chỉ cần tải bộ cài ở [Releases](https://github.com/kiritokmn1403/YomiHub-Project/releases/latest).

> **Trạng thái 0.6.1:** repo chưa phải một dự án Flutter chạy được ngay bằng `flutter run`. Mã riêng của YomiHub nằm ở `overlay/` và được chép đè lên mã gốc Mangayomi trong một thư mục dựng riêng. Các mục đánh dấu **[cần hỏi tác giả]** là chỗ chưa được kiểm chứng trên máy sạch.

## 1. Cấu trúc mã

| Thư mục | Vai trò |
|---|---|
| `overlay/` | **Nguồn duy nhất được sửa**: `lib/`, `lib/yomihub/`, `android/`, `windows/`, `assets/`, `test/`, `pubspec.yaml`. Chỉ là một nửa dự án (thiếu `rust/`, `go/`, `hook/`, `proto/`, `ios/`, `l10n.yaml`, `ffigen.yaml`… – nằm ở upstream). |
| `src/` | Mã Mangayomi upstream để đối chiếu (`src/mangayomi`, `src/mangayomi-0.9.95`, `src/mangayomi-0.9.96`). |
| `scripts/` | PowerShell: `setup/` (cài công cụ), `sync/` (chép overlay → thư mục dựng), `build/`, `packaging/`, `pipeline/`, `release/`, `runner/`, `autosave/`, `lib/common.ps1`. |
| `docs/` | Trang chủ + chính sách quyền riêng tư (GitHub Pages). |

Thư mục dựng (ngoài repo, mặc định `D:\yh`, đổi bằng biến môi trường `YH_ROOT`):
`build\mangayomi` (Android/TV), `buildwin\mangayomi` (Windows), `build23\mangayomi` (Android 6.0, minSdk 23).

## 2. Công cụ cần có (Windows 10/11 x64)

`scripts\setup\1_setup_tools.bat` (gọi `setup_tools.ps1`) cài vào `%YH_ROOT%\tools`, không cần quyền admin:

| Công cụ | Phiên bản đang dùng để dựng bản phát hành |
|---|---|
| Flutter / Dart | **3.47.6** / 3.13.5 (kênh stable) – script cài "stable mới nhất", nên ghim bằng `git checkout 3.47.6` trong `tools\flutter` |
| JDK | 17 (Microsoft OpenJDK) |
| Android SDK | platform-tools, `platforms;android-35`, `android-36`, `build-tools;35.0.0`, `ndk;27.0.12077973`, `cmake;3.22.1` (`compileSdk 37` → cần thêm `platforms;android-37`) |
| Rust | stable, host `x86_64-pc-windows-gnu` + đích `aarch64/armv7/x86_64-linux-android` |
| MinGW-w64 | winlibs (dlltool/ld cho Rust GNU) |
| Visual Studio 2022 Build Tools | "Desktop development with C++" (MSVC 19.44) – **bắt buộc** cho `flutter build windows`, script không cài |
| Windows SDK | `signtool`, `makeappx` cho `.appxbundle` – script không cài |
| Git | Git for Windows (script tải thêm MinGit – không cần nếu đã có git) |

Không cần cho việc dựng nhưng cần cho kiểm thử: Android Studio (Emulator + system image) hoặc máy Android thật qua `adb`.

## 3. Lệnh dựng

Mọi lệnh chạy trong PowerShell, sau khi nạp môi trường: `. .\scripts\lib\common.ps1`.

1. **Lấy mã gốc + đồng bộ overlay** (tạo/cập nhật thư mục dựng):
   ```powershell
   .\scripts\sync\sync_060.ps1 -Regen      # đổi số theo phiên bản; 0.6.1 dùng sync_061.ps1
   ```
2. **Chạy thử khi phát triển** (sau khi đồng bộ):
   ```powershell
   cd $env:YH_ROOT\buildwin\mangayomi; flutter run -d windows
   cd $env:YH_ROOT\build\mangayomi;    flutter run -d <id thiết bị Android>
   ```
   Sửa mã ở `overlay/` rồi đồng bộ lại; hot reload chỉ thấy thay đổi đã chép sang thư mục dựng. **[cần hỏi tác giả]**: chưa có script đồng bộ tự động khi lưu tệp.
3. **Kiểm thử tự động:** `flutter test --no-pub` trong thư mục dựng (test ở `overlay/test/`).
4. **Dựng từng nền tảng** (lệnh lõi, script đã bọc sẵn trong `scripts/build/build_<ver>*.ps1`):
   ```powershell
   # APK thường (Android 7.0+), tách ABI
   flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64 --build-name 0.6.1 --build-number 54
   # APK "YumiHub Android TV" (bỏ Comic, Novel, Google Play Books, Booru)
   flutter build apk ... --dart-define=IS_TV_BUILD=true "--dart-define=APP_NAME=YumiHub Android TV"
   # Windows x64
   flutter build windows --release --build-name 0.6.1 --build-number 54
   ```
   APK Android 6.0 dựng trong `build23` bằng `scripts\build\build_<ver>_android6.ps1`.
5. **Cả bộ phát hành:** `.\scripts\pipeline\run_<ver>_main.ps1` (sync → test → apk → tv → wintest → win → pack → a6build → a6copy → verify; chọn bước bằng `-RunSteps apk,tv`). Sản phẩm ở `output\<ver>\`.

## 4. Khóa và bí mật (không có trong repo)

- Ký APK: `yomihub-release.jks` + `keystore-password.txt` ở gốc (git-ignored). Không có thì dựng bản debug hoặc tự tạo keystore riêng.
- Google Sign-In/Drive: `secrets/google_oauth.json` → `scripts/lib/yh_defines.ps1` (git-ignored) sinh `--dart-define`. Thiếu tệp này app vẫn dựng được, chỉ tắt đăng nhập Google.

## 5. Giới hạn đã biết

- Windows 7/8, x86 và Windows ARM không được Flutter/Isar hỗ trợ ở cấu hình hiện tại.
- Đường dẫn Windows dài: bật Long Paths hoặc dùng `subst Y: <thư mục>` rồi đặt `YH_ROOT=Y:`.
- Nhiều script đời cũ (≤ 0.5.x) còn ghi cứng `D:\yh`; script 0.6.x dùng `common.ps1` (`$YH` ← `YH_ROOT`).
