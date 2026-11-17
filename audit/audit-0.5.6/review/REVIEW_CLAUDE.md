
## 14:21 R25 — kết quả (Sonnet)
- Nguyên nhân gốc: ShioriFloatingNavBar dùng Center không có heightFactor trong Scaffold.bottomNavigationBar -> Center chiếm toàn bộ chiều cao, thanh nằm giữa màn, thân bị ép về 0.
- Sửa: overlay/lib/yomihub/ui/shiori/shiori_nav_bar.dart (Center heightFactor: 1). Không đổi chế độ Cũ/Windows/TV.
- Test: overlay/test/yh_056_c2_ui_test.dart nhóm 'R25' (412x915, Mới + Cũ: thân cao >700, thanh ở đáy) đạt; analyze 0 lỗi (chỉ info); flutter test toàn bộ: 681 đạt, 1 lỗi là test R25 ban đầu thiếu ProviderScope (đã sửa, tệp test chạy lại 15/15 đạt; chưa chạy lại toàn bộ).
- APK: output/0.5.6/YomiHub-0.5.6-arm64-v8a.apk (21:12), đã adb install -r thành công trên K75THMJVHA95EARO (giữ dữ liệu).
- CHƯA chụp được màn hình app: điện thoại đang khóa màn hình (keypad ngày tháng tùy biến), không thể mở khóa. Cài đặt Giao diện vẫn là 'Mới' (chưa chuyển về Cũ). Ảnh r25_khoamanhinh_chan.png là màn khóa.
