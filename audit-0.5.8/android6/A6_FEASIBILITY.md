# YomiHub 0.5.6.1 — APK riêng cho Android 6.0 (API 23): khả thi, cách vá, kết quả

Cập nhật: 13/11/2026 (giờ máy dựng, UTC+7). Người làm: Claude (tiếp nối agent A6 trước).
APK Android 7.0+ chính **không đổi** (minSdk 24, engine/Isar gốc). APK Android 6.0 dựng riêng trong `D:\yh\build23`.

## 1. Kết luận ngắn

- 3 APK `YomiHub-0.5.6.1-android6-<abi>.apk` (arm64-v8a, armeabi-v7a, x86_64) dựng tự động bằng `build_0561_android6.ps1`,
  ký bằng khóa phát hành (cùng chứng chỉ SHA-256 `2c746646…202b0198` với APK chính), `minSdkVersion 23`, versionName `0.5.6.1`.
- Trên AVD Android 6.0 x86_64 (kernel 3.10): app mở tới màn chính, đọc tiểu thuyết EPUB, phát video mpv, Play Books chạy; lỗi lớn còn lại: HTTPS từ Dart báo `CERTIFICATE_VERIFY_FAILED` (kho CA gốc của Android 6 cũ) → WARP/Booru (và nguồn online) chưa dùng được. Xem bảng mục 6. arm64-v8a / armeabi-v7a **chưa chạy thật** (AVD API 23 không có dịch ARM) —
  chỉ kiểm tĩnh (ký hiệu thiếu = 0, xem mục 4.3).

## 2. Nguyên nhân MDBX_INCOMPATIBLE (-30784)

- Isar (`isar_community_flutter_libs` 3.3.2) dùng libmdbx 0.13.8 (`v0.13.8-temp-upstream-fix`). Khi tạo môi trường,
  libmdbx kiểm phiên bản kernel: chuỗi trong libisar.so `"too old linux kernel %u.%u.%u.%u, the >= 3.16 is required"`;
  kernel < 3.16 → `mdbx_env_create()` trả `MDBX_INCOMPATIBLE` → app hiện "Không khởi động được YomiHub" (ảnh `evidence/r1b_orig_25s.png`).
- Android 6.0 chạy kernel 3.4–3.18 (AVD: 3.10.0+). Định dạng tệp CSDL không phụ thuộc kernel; ngưỡng là chính sách an toàn của libmdbx
  (các lỗi kernel cũ đã biết với mmap/OFD-lock), không phải khác biệt định dạng.

## 3. Cách vá (tất cả chỉ trong build23 / bản sao, không đụng bộ đệm Flutter/Gradle dùng chung)

| # | Vấn đề trên API 23 | Cách vá | Tệp |
|---|---|---|---|
| 1 | libmdbx từ chối kernel < 3.16 | Hạ hằng so sánh 3.16 → 3.0 (1 lệnh `cmp`, 4 ABI; không đổi kích thước) | `patch_libisar_kernel.py`, `patch_log.txt` |
| 2 | libflutter.so (engine 3.47.6, 692136cb) cần `__fwrite_chk`, `__write_chk`, `getifaddrs`, `freeifaddrs` (API 24) | `libyhcompat.so` (forward sang libc nếu có, dự phòng trên 6.0) + thêm `DT_NEEDED` (x86_64, arm64-v8a; armeabi-v7a không cần) | `compat/yhcompat.c`, `elf_add_needed.py` |
| 3 | libtor.so cần `__write_chk`, `getifaddrs`, `freeifaddrs` | `DT_NEEDED libyhcompat.so` (3 ABI) | như trên |
| 4 | libmpv.so armeabi-v7a cần `fseeko64`, `ftello64` (API 24) → phát video hỏng trên ARM 32-bit | thêm 2 hàm vào yhcompat (32-bit) + `DT_NEEDED` | như trên |
| 5 | Linker Android 6.0 từ chối PT_LOAD kết thúc đúng tại EOF ("load segment … past end of file") | `elf_add_needed.py` chừa 16 byte đệm cuối tệp | `elf_add_needed.py` |
| 6 | Embedding Java gọi API 24 không kiểm tra: `Configuration.getLocales`, `Context.getDataDir`, `EditorInfo.hintLocales`, `setDrawingOrder` (0.4.3) **+ `AccessibilityNodeInfo.setImportantForAccessibility` (AccessibilityBridge → app chết khi có dịch vụ trợ năng/uiautomator) + `View.setPointerIcon` (MouseCursorPlugin)** | Biên dịch lại 6 lớp có kiểm tra `SDK_INT` → `flutter_embedding_release-yh23.jar`; build23 loại `io.flutter:flutter_embedding_release` và dùng jar này | `embedding/src`, `embedding/build_embedding.ps1` |
| 7 | ART 6.0 (dex2oat tối ưu) biên dịch sai `tc0.onMethodCall` (R8 gộp handler kênh `yomihub/vpn` + `yomihub/tunnels`, 19,8 KB mã máy) → SIGSEGV ngay khi mở app | `android:vmSafeMode="true"` (Android 6 biên dịch APK ở chế độ interpret-only; đã kiểm bằng `dalvik.vm.dex2oat-filter=interpret-only`: hết lỗi) | `build_0561_android6.ps1` (bước patch) |
| 8 | Rust (cargokit) không dựng được trong build23: mingw gcc resolve junction `D:\yh` → `D:\A.I Project\…` (có dấu cách) → `ld: cannot find D:/A.I` | Tắt cargokit trong build23, dùng `librust_lib_mangayomi.so` của APK chính (cùng mã Rust; 0 ký hiệu thiếu ở API 23). Ghi chú: đặt `GCC_EXEC_PREFIX=D:/yh/tools/mingw64/lib/gcc/` cũng sửa được (đã thử với gcc) | `prepare_jnilibs23.py` |
| 9 | `.flutter-plugins-dependencies` sao từ thư mục chính trỏ plugin `rust_builder`, `packages/*` về `D:\yh\build\mangayomi` | Bước patch đổi sang build23; xóa `.dart_tool\flutter_build` để Dart dựng lại từ mã build23 | `build_0561_android6.ps1` |
| 10 | WireGuard/WARP bị chặn `SDK_INT < 24` (0.4.3) | Bước patch bỏ chặn WireGuard/WARP (`-keepVpnGuard` để giữ). **Tor vẫn chặn**: tor-android 0.4.9.13 gọi `FileObserver(File)` (API 29) → `NoSuchMethodError`, app thoát (đã kiểm, mục 6) | `build_0561_android6.ps1` |

Tính năng hệ thống không thể có trên 6.0 đã có kiểm tra phiên bản sẵn trong mã: PiP (`MainActivity`, API 26), GeckoView (`YomiGecko.MIN_SDK = 26`;
libxul/libmozglue cần RELR + `AHardwareBuffer`… API 26–28), IReader (API 26), Health Connect (API 28/34).

## 4. Công cụ / lệnh

### 4.1 Chuẩn bị thư viện đã vá (chạy lại khi engine Flutter/plugin đổi)
```
python3 -I audit-0.5.7/android6/prepare_jnilibs23.py output/0.5.6 0.5.6 audit-0.5.7/android6/jnilibs23
```
Đọc thư viện từ APK chính (đã strip), vá, ghi `jnilibs23/<abi>/*.so` + `MANIFEST.txt` (sha256 gốc → sau vá).
libyhcompat: `compat/yhcompat.c`, NDK 28.2 clang `--target=<abi>-linux-android23 -shared -fPIC -O2 -fvisibility=hidden`, llvm-strip (job `a6_22_compat`).
Embedding: `audit-0.5.7/android6/embedding/build_embedding.ps1` (javac --release 11 trên jar gốc 692136cb).

### 4.2 Dựng 3 APK
```
powershell -NoProfile -ExecutionPolicy Bypass -File build_0561_android6.ps1            # = -step all
   [-step sync|patch|apk|post|verify] [-abis arm64-v8a,x86_64] [-keepVpnGuard] [-refApk <APK chính>]
```
- Giữ `audit-0.5.6/coordination/BUILD_LOCK.txt` = `A6 <giờ>` trong sync/patch/apk (chờ tối đa 60 phút nếu bận), luôn trả khóa (try/finally).
- sync: `robocopy D:\yh\build\mangayomi → D:\yh\build23\mangayomi /MIR` (trừ build/.gradle/.dart_tool\flutter_build).
- apk: `flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64 --build-name 0.5.6.1`
  (ký bằng `android\key.properties` → khóa phát hành; mật khẩu không in ra).
- verify: aapt2 (`minSdkVersion:'23'`, versionName, ABI, nhãn), aapt v1 `sdkVersion:'23'`, `vmSafeMode=true`, sha256 từng thư viện
  đã vá trong APK = MANIFEST (không bị thay/strip), apksigner + chứng chỉ = APK chính; ghi `out/SHA256SUMS-0.5.6.1-android6.txt`.
- Thời gian: ~16–22 phút (incremental) trên máy dựng.

### 4.3 Kiểm tĩnh ký hiệu (Linux, nm)
Với mỗi ABI: ký hiệu `U` (bắt buộc) của từng .so trong APK, trừ ký hiệu có trong stub API 23 của NDK (libc/libm/libdl/liblog/libandroid/
libmediandk/libEGL/GLES/OpenSLES/libz) và các .so khác trong APK. Sau vá: libflutter/libtor/libmpv/libisar/librust/libyhcompat = **0 thiếu** (3 ABI).
Còn thiếu (chấp nhận): GeckoView (libxul, libmozglue, libnss3, libcrashhelper, libmozavcodec — không nạp trên < API 26), `libwg-quick.so`
(`strchrnul`, chỉ dùng ở chế độ root; app dùng GoBackend `libwg-go.so` — đủ ký hiệu).

## 5. Đường dẫn
- APK: `audit-0.5.7/android6/out/YomiHub-0.5.6.1-android6-{arm64-v8a,armeabi-v7a,x86_64}.apk` + `SHA256SUMS-0.5.6.1-android6.txt`
- Script: `build_0561_android6.ps1` (gốc dự án), `audit-0.5.7/android6/{prepare_jnilibs23.py,patch_libisar_kernel.py,elf_add_needed.py,repack_apk.py,a6_lib.ps1,a6_t.ps1}`
- Thư viện đã vá: `audit-0.5.7/android6/jnilibs23/`; shim: `compat/`; embedding: `embedding/`; dữ liệu thử: `testdata/`; ảnh/log: `evidence/`
- Log dựng: `logs/b0561_android6_apk.txt`, `logs/build0561_android6_all_*.txt`; job: `jobs/done/a6_*.ps1/.log`

## 6. Kết quả kiểm thử thật (AVD `OOS_Android6_API23`, x86_64, Google APIs, kernel 3.10.0+)

Tất cả trên APK `YomiHub-0.5.6.1-android6-x86_64.apk` bản dựng 01:59 (13/11; bản dựng lại 06:2x chỉ khác: giữ chặn Tor + mã VPN mới nhất từ thư mục chính) (vmSafeMode, embedding mới); ảnh đã tự xem (riêng `f17_warp.png` đối chiếu qua dump UI). Job: `jobs/done/a6_80…a6_103`.

| Tính năng | Kết quả | Ghi chú / ảnh (`evidence/`) |
|---|---|---|
| Cài + mở app, màn chính, CSDL Isar | **ĐẠT (VÁ 1–9)** | `f02_main.png`; log `IsarCore using libmdbx v0.13.8`; odex 37,8 MB (interpret-only do vmSafeMode) |
| Trợ năng / uiautomator | **VÁ** | trước vá: `NoSuchMethodError setImportantForAccessibility` → app chết (`r5_full_logcat.txt`); sau vá dump UI bình thường |
| Duyệt nguồn cục bộ, chi tiết truyện, "Thêm vào thư viện" | **ĐẠT** | quét `/sdcard/YomiHub/local` (CBZ/EPUB/MP4) |
| Đọc truyện (CBZ cục bộ) | **CHƯA ĐẠT – chưa rõ nguyên nhân** | trình đọc mở, 1/3 trang, nhưng "Không tải được ảnh này" (`f07_reader.png`); không có lỗi trong logcat; ảnh PNG tự tạo, chưa đối chiếu cùng tệp trên Android 7+ |
| Tiểu thuyết (EPUB cục bộ, Rust epub) | **ĐẠT** | `f12_novel.png` (chữ tiếng Việt hiển thị đúng) |
| Phát video (mpv, x86_64) | **ĐẠT** | `f08_video.png` (khung giây 14/15); armeabi-v7a đã VÁ `fseeko64/ftello64` nhưng chưa chạy thật |
| Play Books (WebView hệ thống) | **ĐẠT** | `f19_playbooks.png` |
| Booru (Safebooru) | **KHÔNG ĐẠT** | chỉ ô trống sau 15 s (`f18_booru.png`); nghi cùng lỗi TLS bên dưới |
| Kotatsu bridge | **ĐẠT một phần** | danh sách nguồn Kotatsu (ComicK, Cubari…) hiện; chưa duyệt online |
| Cloudflare WARP | **KHÔNG ĐẠT (TLS)** | hộp xin quyền VpnService hiện và bấm OK được; đăng ký tài khoản lỗi `HandshakeException CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` (`f17_warp.png`) |
| WireGuard (hồ sơ có sẵn) | chưa kiểm | GoBackend `libwg-go.so` đủ ký hiệu API 23 |
| Tor | **KHÔNG THỂ (chưa vá)** | `java.lang.NoSuchMethodError: FileObserver.<init>(File)` trong `org.torproject.jni.TorService` → cả app thoát; lần mở sau app tự tắt Tor. Bản dựng 06:2x giữ chặn Tor trên API 23 (thông báo, không thoát) |
| Sao lưu | **ĐẠT một phần** | màn Sao lưu & tùy chọn đầy đủ; "Tạo" mở bộ chọn thư mục hệ thống (SAF) — chưa chọn xong; khôi phục chưa kiểm |
| Tải về, OCR (ML Kit), thông báo, sinh trắc học | chưa kiểm | không đủ thời gian AVD (agent VPN chờ máy ảo) |
| TTS | đạt phần khởi tạo | log `TextToSpeech: Sucessfully bound to com.svox.pico`; chưa đọc thử |
| GeckoView, PiP, IReader, Health Connect | **KHÔNG THỂ** (API 26/28) | mã đã có kiểm tra phiên bản (`YomiGecko.supported`, `MainActivity`, `YomiIReader`, `YomiHealth`) |
| Mở lại sau khi thoát bằng Back (tiến trình còn sống) | **lỗi** | kẹt màn logo (`f10_after`/`f09_novel.png`); mở nguội (force-stop) thì bình thường; chưa đối chiếu Android 7+ |


## 7. Tương thích dữ liệu

- **Chưa chạy chéo thật** (máy ảo API 34 bận / hết thời gian). Lập luận: bản vá libisar chỉ đổi 1 hằng số so sánh phiên bản kernel trong
  `mdbx_env_create`; mã đọc/ghi trang, định dạng tệp `default.isar`, phiên bản Isar (3.3.2) và schema Dart giống hệt APK chính
  (cùng `libapp.so` nguồn) → tệp CSDL tạo bởi bản vá mở được bởi bản thường và ngược lại; tệp sao lưu (.backup) là dữ liệu ứng dụng, không phụ thuộc libmdbx.
- Cách kiểm (đề xuất, ~10 phút mỗi chiều): API 23 (`adb root`) dùng app → `am force-stop` → `adb pull /data/data/com.yomihub.app/app_flutter/*.isar`;
  AVD `YomiHub056_Phone_API34` (google_apis, root được) cài APK chính, mở 1 lần, force-stop, `adb push` tệp vào cùng chỗ, `chown` theo uid app,
  mở → thư viện phải có "A6 Test Manga/Novel/Video". Làm ngược lại. Song song: Tạo bản sao lưu ở API 23 → Khôi phục ở API 34.


## 8. Rủi ro / việc còn lại

1. **TLS trên Android 6 (ưu tiên 1):** Dart `HttpClient` dùng kho CA hệ thống; Android 6 thiếu CA gốc mới (vd. ISRG Root X1 có từ 7.1.1, các gốc GTS…)
   → `CERTIFICATE_VERIFY_FAILED` (WARP; nghi Booru, nguồn online, kiểm tra cập nhật). Hướng vá (chỉ build23): đóng gói `cacert.pem` (Mozilla)
   và khi `sdkInt < 24` gọi `SecurityContext.defaultContext.setTrustedCertificatesBytes(...)` ở `main()`; phía Java (OkHttp của Kotatsu/M-Extension-Server)
   cần TrustManager riêng nạp cùng bộ CA. Rust/reqwest dùng rustls (gốc webpki đóng gói) — cần kiểm.
2. Tor: vá `org.torproject.jni.TorService` (dùng `FileObserver(String)` khi `SDK_INT < 29`) rồi mới bỏ chặn.
3. Trang ảnh trình đọc truyện "Không tải được ảnh này": kiểm cùng CBZ (ảnh JPEG/WebP thật) trên Android 7+ để phân biệt lỗi chung hay lỗi API 23.
4. arm64-v8a / armeabi-v7a chưa chạy trên máy thật Android 6 (AVD API 23 không dịch ARM) — cần một máy Android 6 thật.
5. `vmSafeMode=true`: mã Java chạy thông dịch (ART 6 không có JIT) → phần Java (Kotatsu, M-Extension-Server, OkHttp/jsoup) chậm hơn. Thay thế: tìm lớp
   R8 gộp gây lỗi dex2oat (`tc0.onMethodCall`) và chặn gộp bằng quy tắc ProGuard riêng cho build23.
6. libmdbx đặt ngưỡng kernel 3.16 vì lỗi kernel cũ đã biết; kiểm thử trên 3.10 chưa thấy lỗi nhưng rủi ro hỏng CSDL hiếm gặp trên kernel rất cũ (3.4) chưa loại trừ — khuyên người dùng bật sao lưu định kỳ.
7. Mở lại app khi tiến trình còn sống bị kẹt màn logo; việc chưa kiểm: tải về, OCR, thông báo, sinh trắc học, WireGuard, khôi phục sao lưu, tương thích dữ liệu chéo.
8. `prepare_jnilibs23.py` lấy thư viện từ `output/0.5.6`; nếu 0.5.6.1 đổi engine/plugin (tor, mpv, isar, rust) phải chạy lại (script dựng kiểm engine hash + sha256).
9. Phối hợp: các job A6 dùng khóa BUILD_LOCK/AVD_LOCK; một lần (00:59–01:01, 13/11) job a6_50 chạy AVD khi AVD_LOCK đang là "VPN" do lỗi hàm `AvdTake` (đã sửa: chỉ trả về true/false).

