# YomiHub 0.5.6 (0.5.6+48) — Nhật Ký Thay Đổi / Release Notes

Bản phát hành **YomiHub 0.5.6** mang đến những nâng cấp lớn về giao diện người dùng, hiệu năng đa nền tảng, cơ chế sao lưu thông minh, tối ưu hóa phần cứng và ổn định hệ thống.

---

### 🌟 Tính Năng & Nâng Cấp Nổi Bật

#### 1. Giao Diện Mới Shiori & Công Tắc Chuyển Đổi Phong Cách (U12)
- Tích hợp ngôn ngữ thiết kế Shiori hiện đại từ Mangayomi v0.9.95.
- Cung cấp tùy chọn chuyển đổi linh hoạt giữa giao diện **Cũ (Classic)** và **Mới (Modern)** ngay trong *Cài Đặt → Giao Diện* mà không cần khởi động lại ứng dụng.
- **Phạm vi hiệu lực Shiori trong 0.5.6**:
  - Thanh điều hướng nổi capsule dạng viên thuốc (`ShioriFloatingNavBar`) trên di động khi bật chế độ Mới.
  - Bộ chọn tab dạng viên (`ShioriShape.pill`) với chỉ báo chuyển động 220ms mượt mà.
  - Các thành phần nâng cao (thẻ thư viện ShioriCard, tiêu đề phân mục ShioriSectionHeader, huy hiệu ShioriBadge, bộ chuyển cảnh ShioriPageTransitions, thanh điều hướng desktop Liquid Glass) đã hoàn tất mã nguồn nền tảng và sẽ được kết nối sâu vào toàn bộ các màn hình con trong bản 0.5.7.

#### 2. Hợp Nhất Thư Viện — Library Hub (U13)
- Gộp các mục riêng rẽ (Truyện Tranh, Phim & Điện Ảnh, Tiểu Thuyết, Google Play Books) thành tab **Thư Viện** duy nhất trên thanh điều hướng.
- Mục Thư Viện xuất hiện đồng nhất ở cả 2 chế độ **Cũ** và **Mới** (đây là yêu cầu bắt buộc U13 độc lập với công tắc giao diện).
- Cài đặt upstream *"gộp thư viện trên di động"* nay không còn hiệu lực do Thư Viện đã được hợp nhất mặc định (tùy chọn này sẽ được ẩn hoàn toàn trong bản 0.5.7).
- **Riêng bản YumiHub Android TV**: Thư Viện được tinh giản chuyên sâu, chỉ hiển thị mục Phim & Điện Ảnh, loại bỏ hoàn toàn Truyện Tranh, Tiểu Thuyết, Google Play Books và Booru.

#### 3. Bảo Vệ Dữ Liệu & Nâng Cấp Sao Lưu Thông Minh (U3 & R7)
- Bổ sung tùy chọn **Hạn mức sao lưu** trong *Cài Đặt → Sao Lưu & Khôi Phục*: Giữ lại 1, 2, 3, 5, 10, 20 bản gần nhất hoặc **Không giới hạn** (mặc định cho tất cả người dùng để bảo vệ an toàn dữ liệu).
- Cơ chế dọn dẹp tự động (`pruneOldBackups`) chỉ áp dụng trong thư mục `autobackup`, chỉ dọn SAU KHI tệp sao lưu mới đã ghi thành công, có ghi Nhật ký chi tiết và tuyệt đối không xóa nhầm các tệp sao lưu thủ công hoặc tệp của người dùng.

#### 4. Tối Ưu Hóa Windows & AMD Ryzen 9 / CPU Đa Luồng (C1.1, C1.2 & R9)
- Tự động nhận diện phần cứng AMD Ryzen 9 và các CPU có số luồng cao (24–32 luồng).
- Tính năng 1-chạm **"Tối ưu hóa cấu hình cho AMD Ryzen / CPU đa luồng"**: chuyển giải mã video sang chế độ an toàn `d3d11va-copy` tránh treo GPU AMD Direct3D 11; giới hạn pool worker isolate tối đa 4 luồng tránh cạn kiệt tài nguyên RAM và bộ đệm.
- Bộ công cụ chẩn đoán Windows Diag chuyên sâu.
- Nền tảng hỗ trợ: Windows 10/11 x64 gốc; Windows trên ARM (WoA) tương thích mượt mà thông qua trình giả lập Prism x64 của Microsoft.

#### 5. Kiểm Tra Cập Nhật Tiện Ích Trực Tiếp (U8, FC20 & R11)
- Bổ sung nút **"Kiểm Tra Cập Nhật"** trực tiếp trên AppBar khi xem tab Tiện ích trong mục Duyệt.
- Quét và cập nhật extension song song từ nhiều kho; xử lý lỗi mạng an toàn, thông báo trạng thái rõ ràng khi hoàn tất mà không gây treo ứng dụng.

#### 6. Tích Hợp Dự Án Mở Rộng & Ổn Định Trình Phát Video (U5, R16, R17)
- **Yomikiru Reader Enhancer**: Đọc truyện trang đôi (dual-page spread), căn chỉnh linh hoạt (Fit Width/Height/Smart).
- **Yomihon Novel Enhancer**: Định dạng typography đọc tiểu thuyết, hỗ trợ văn bản dọc CJK (Tate-gaki).
- **Zenshin Anime Tracker**: Phân tích số tập anime thông minh từ tiêu đề phức tạp, tự động đánh dấu đã xem ở ngưỡng 85%.
- **Nyora Data Bridge & Nuvio Media Hub**: Chuẩn hóa metadata và tối ưu hóa cử chỉ vuốt âm lượng/độ sáng, tỉ lệ PiP linh hoạt.
- **GIF Viewer Controller**: Điều khiển hoạt ảnh từng khung hình, tua ngược, điều chỉnh tốc độ xem (0.25x - 4x).
- Xử lý giải mã Cloudflare WebView an toàn (R16): ném lỗi và ghi Nhật ký rõ ràng khi thử thách thất bại, tránh nạp trang trống.
- Hướng dẫn cấu hình Telegram Cloud Backup (R17): ghi chú rõ ràng về Chat ID và token bot.

---

### 📦 Các Gói Phát Hành

1. **Android (Điện thoại & Máy tính bảng):**
   - `YomiHub-0.5.6-arm64-v8a.apk` (Thiết bị 64-bit hiện đại)
   - `YomiHub-0.5.6-armeabi-v7a.apk` (Thiết bị 32-bit / thiết bị cũ)
   - `YomiHub-0.5.6-x86_64.apk` (Giả lập / thiết bị nền tảng x86_64)
2. **Android TV (Chuyên dụng cho TV & TV Box):**
   - `YumiHub-Android-TV-0.5.6-arm64-v8a.apk`
   - `YumiHub-Android-TV-0.5.6-armeabi-v7a.apk`
   - `YumiHub-Android-TV-0.5.6-x86_64.apk`
   *(Giao diện tối ưu 1080p, điều hướng remote D-Pad, chỉ hiển thị Phim & Điện ảnh)*
3. **Windows (64-bit):**
   - `YomiHub-0.5.6-windows-x64-Setup.exe` (Bộ cài đặt Windows Setup có đồ họa trực quan)
   - `YomiHub-0.5.6-windows-x64.zip` (Bản Portable chạy ngay)
   - `YomiHub-0.5.6-windows-x64-full.zip` (Bản Portable Full kèm Java JRE & MExtensionServer)
   - `YomiHub-0.5.6-windows-x64.appxbundle` (Gói cài đặt Store/AppxBundle hiện đại)
   - Kèm theo: `YomiHub-RootCA.cer`, `Install-YomiHub.bat`, `Install-YomiHub.ps1`
