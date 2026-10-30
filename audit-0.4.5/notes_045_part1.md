
### 30/10/2026 — Cập nhật phiên bản 0.4.5 (YomiHub 0.4.5+37) — đang thực hiện

> Thực hiện bởi Claude (Cowork). Công cụ:
> - **GitHub Desktop 3.6.7**: Fetch `origin/main` lúc 09:24. Kết quả `43461ac`, trùng bản trên máy, không cần Pull.
> - Flutter 3.47.6 / Dart 3.13.5, Gradle 9.3.1, Android SDK `adb` (Xiaomi 15T `K75THMJVHA95EARO`, Android 16 / HyperOS 3.0.303).
> - PowerShell job runner (`3_run_jobs.bat`, `3b_run_fast_jobs.bat`); `curl.exe` trên Windows để kiểm tra trang/API thật.
> - Python 3 trong máy ảo Linux của phiên, dùng để sửa mã, quét bản dịch, so khớp sheet Excel.
>
> Cách làm: mọi sửa đổi làm trong `overlay`, sao lưu bản trước khi sửa ở `audit-0.4.5/before/` (`audit-0.4.5/bk.sh`), danh sách tệp ở `audit-0.4.5/changed_files.txt`, rồi chép sang `D:\yh\build` / `D:\yh\buildwin` bằng `audit-0.4.5/sync.sh`. Script dựng: `build_045.ps1`, sao từ `build_044.ps1`; danh sách `dart analyze` lấy tự động từ `changed_files.txt`, thêm bước `-step apk64` để dựng nhanh bản arm64 cho kiểm thử.

**Yêu cầu (người dùng xác nhận 30/10/2026):**
- Nâng lên 0.4.5, giữ **Android 7.0+** (Android 6.0 vẫn bị chặn bởi Isar/libmdbx).
- APK riêng `YumiHub Android TV`, bỏ Comic/Novel.
- Windows 10/11 x64 đủ 3 gói `.appxbundle`, `Setup.exe`, portable. Người dùng để Claude chọn phạm vi Windows → giữ x64 như 0.4.4.
- Làm sheet `YomiHub Update` (6 mục) và `Feature Check` (43 mục); sửa lỗi trong `logs 2.txt`.
- Kiểm thử có ảnh/video; VPN kiểm tra bên ngoài ứng dụng; đẩy mã lên GitHub.

#### A. Lỗi trong `logs 2.txt` (30/10/2026 06:09–09:12, 27 dòng)

| # | Dòng log | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | `[ERROR] [Booru App] Không tải được danh sách (Rule34, api.rule34.xxx): Rule34: missing authentication` | Rule34/Gelbooru bắt buộc API key. App vẫn gửi yêu cầu, rồi ghi ERROR mỗi lần mở tab. | `lib/yomihub/booru/booru_screen.dart`: trang `needsKey` chưa có key thì không gửi yêu cầu, ném `BooruException(needsKey)` ngay. Màn hình hiện nút mới **"Nhập API key"**, mở `/booruSettings` rồi tải lại khi quay về. `booruLog()`: lỗi cấu hình (`needsKey`, `cloudflare`, `blocked`) ghi **WARNING**, chỉ 1 lần cho mỗi trang/loại lỗi trong một phiên (`_booruLogged`). |
| 2 | `[Hiệu năng] Khung hình chậm: dựng 421ms, vẽ 434ms` (09:10:59, ~1 s sau khi mở app) | `YomiSplash.build()` trả `Stack[app, splash]` trong 5 s đầu rồi trả `widget.child` trơn. Kiểu widget gốc đổi → **toàn bộ ứng dụng (Navigator, thư viện 41 tab, lưới bìa) bị huỷ và dựng lại từ đầu** ngay sau màn hình loading, đồng thời mất trạng thái điều hướng. | `lib/yomihub/splash/yomi_splash.dart`: luôn trả cùng một `Stack`, ứng dụng nằm trong `KeyedSubtree(GlobalKey)`, lớp splash chỉ bị bỏ khỏi `children` (`if (!_removed)`). |
| 3 | `[Hiệu năng] Hệ thống báo thiếu bộ nhớ (RAM máy 11.1 GB) – … không còn bộ đệm nào khác` | Android gửi `onTrimMemory` khi app ở nền; bộ đệm ảnh đã trống. | Thông tin, không phải lỗi; không đổi. |
| 4 | `Image/network load failed` (i.hinhhinh.com, i.hinhgg.com, nhattruyensss.com, hentaicb.help) | Máy chủ ảnh hỏng hoặc chặn (403/521/TLS), đã phân tích ở 0.4.3 mục I. | Không đổi (ghi INFO, 1 lần/máy chủ). |
| 5 | `Refreshed MAL token!`, `Refreshed Trakt.tv token!`, `Download index: 81 on disk, +9, -0` | Thông tin. | — |
