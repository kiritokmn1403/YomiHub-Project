
#### I. Bản dựng cuối (lần 5, 04/11 07:48 → __END__) và kiểm thử xác nhận
- Thêm sửa lỗi (07:46, máy ảo Android TV 14): trang "Allow access to manage all files" **vẫn** mở ở mọi lần khởi động dù đã có cờ chỉ hỏi một lần. Nguyên nhân: lượt quét nền chạy **trước** khi `_postLaunchInit` mở `YomiPrefs` (`main.dart`: `AppLogger.init` → … → `YomiPrefs.open()`). Lúc đó `get()` trả về mặc định `false` và `set()` không có hộp lưu, nên cờ không bao giờ được ghi. Sửa `storage_provider.dart`: lời gọi không có `force` chờ `YomiPrefs.ready` (tối đa 10 s); nếu kho vẫn chưa mở thì **không hỏi**. Test bổ sung.
- `build_051.ps1 -step test` (07:48): `dart analyze lib` **0 lỗi**; `flutter test` 12 tệp yh_040…yh_051 **102/102 đạt**.
- `-step apk` / `tv` / `pack`: __BUILDTIMES__
- Kiểm thử xác nhận trên bản cuối: __FINALTESTS__
