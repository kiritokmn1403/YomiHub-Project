# Bản vá 0.5.6.1 — quyết định (12/11/2026 21:00, người dùng chọn)
- Số hiệu: **0.5.6.1** = sửa lỗi VPN + thêm APK Android 6.0. 0.5.7 vẫn dành cho chuyển nền Mangayomi 0.9.95. (Thư mục làm việc tạm dùng `audit-0.5.7/`.)
- Đóng gói Android 6.0: **APK riêng** (engine Flutter + Isar đã vá) bên cạnh APK Android 7.0+ (engine gốc). Không hạ minSdk của APK chính.
- Không sửa tag/Release v0.5.6. Phát hành chỉ sau "MỐC DUYỆT 0.5.6.1" trong REVIEW_CLAUDE.md.
- (12/11/2026 23:18, người dùng) Sau khi kiểm thử, vá lỗi và tạo file xong: tải lên GitHub. Kế hoạch phát hành: commit + tag `v0.5.6.1` (không sửa v0.5.6), Release mới gồm 3 APK Android 7.0+, 3 APK `YumiHub Android TV`, 4 gói Windows (dựng lại vì mã VPN Dart dùng chung), 3 APK `YomiHub-0.5.6.1-android6-*`, SHA256SUMS, changelog; README thêm link tải v0.5.6.1; kiểm tên + kích thước từng asset sau khi tải. Chỉ chạy sau "MỐC DUYỆT 0.5.6.1" trong REVIEW_CLAUDE.md.
