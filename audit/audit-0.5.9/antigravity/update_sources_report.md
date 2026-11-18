# Báo Cáo Kiểm Chứng Các Nguồn Kiểm Tra Cập Nhật Ứng Dụng (Update Sources Report)

**Phiên bản YomiHub:** v0.5.9  
**Thời gian kiểm tra:** 18/11/2026 09:43  
**Tài liệu đầu vào:** Sheet `Website Update Apps` trong `input_0.5.9.json`  
**Phương pháp kiểm thử:** Truy vấn API GitHub Release chính thức, phân tích HTML `embeddedfolderview` của Google Drive và gọi REST API `api/1.5/folder/get_content.php` của MediaFire.

---

## 1. Bảng Tổng Hợp Trạng Thái 8 Nguồn Cập Nhật Ứng Dụng

| STT | Phân Loại | Tên Nguồn / Thư Mục | URL / Định Danh | Trạng Thái HTTP | Bản Mới Nhất Tìm Thấy | Số Tệp / Thư Mục | Tình Trạng Hoạt Động |
|:---:|:---|:---|:---|:---:|:---:|:---:|:---:|
| 1 | Nguồn chính | **GitHub Releases (API)** | `api.github.com/.../releases/latest` | ✅ 200 OK | **v0.5.8** | 19 tệp cài đặt & tài liệu | Hoạt động hoàn hảo |
| 2 | Nguồn chính | **GitHub Releases (Web)** | `github.com/.../releases` | ✅ 200 OK | **v0.5.8** | Trang web hiển thị đầy đủ | Hoạt động hoàn hảo |
| 3 | Nguồn phụ | **Google Drive Primary** | `16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__` | ✅ 200 OK | Thư mục `Alpha`, `Beta` | 2 thư mục con | Khả dụng (cần duyệt đệ quy) |
| 4 | Nguồn phụ | **Google Drive Secondary 1** | `1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn` | ✅ 200 OK | Thư mục `0.1`, `0.2`, `0.3`, `0.4` | 4 thư mục con | Khả dụng (chứa build cũ) |
| 5 | Nguồn phụ | **Google Drive Secondary 2** | `1vLWPTfFznhWko0O6YGJqecnFEU5CLr10` | ✅ 200 OK | _Chưa có tệp_ | 0 tệp | Rỗng |
| 6 | Nguồn phụ | **MediaFire YomiHub** | `kg0wfu3lpbc98` | ✅ 200 OK | _Chưa có tệp_ | 0 tệp | API khả dụng, thư mục rỗng |
| 7 | Nguồn phụ | **MediaFire Alpha** | `8s2tlcukdmw6x` | ✅ 200 OK | _Chưa có tệp_ | 0 tệp | API khả dụng, thư mục rỗng |
| 8 | Nguồn phụ | **MediaFire Beta** | `jmgm4xds8kamx` | ✅ 200 OK | _Chưa có tệp_ | 0 tệp | API khả dụng, thư mục rỗng |

---

## 2. Chi Tiết Từng Nguồn Cập Nhật

### 1. GitHub Releases API (`kiritokmn1403/YomiHub-Project`)
- **Endpoint:** `https://api.github.com/repos/kiritokmn1403/YomiHub-Project/releases/latest`
- **Trạng thái:** HTTP 200 OK
- **Thẻ phát hành mới nhất:** `v0.5.8` (Tên: *YomiHub 0.5.8*)
- **Ngày phát hành:** `2026-11-17T14:48:42Z`
- **Danh sách 19 tệp artifact đính kèm:**
  + `Install-YomiHub.bat` (0.0 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/Install-YomiHub.bat)
  + `Install-YomiHub.ps1` (0.0 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/Install-YomiHub.ps1)
  + `SHA256SUMS-0.5.8.txt` (0.0 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/SHA256SUMS-0.5.8.txt)
  + `TECHNICAL_UPDATE_NOTES.md` (0.5 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/TECHNICAL_UPDATE_NOTES.md)
  + `YomiHub-0.5.8-android6-arm64-v8a.apk` (177.7 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-android6-arm64-v8a.apk)
  + `YomiHub-0.5.8-android6-armeabi-v7a.apk` (166.4 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-android6-armeabi-v7a.apk)
  + `YomiHub-0.5.8-android6-x86_64.apk` (188.0 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-android6-x86_64.apk)
  + `YomiHub-0.5.8-arm64-v8a.apk` (168.9 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-arm64-v8a.apk)
  + `YomiHub-0.5.8-armeabi-v7a.apk` (165.8 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-armeabi-v7a.apk)
  + `YomiHub-0.5.8-changelog.md` (0.0 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-changelog.md)
  + `YomiHub-0.5.8-windows-x64-full.zip` (247.4 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64-full.zip)
  + `YomiHub-0.5.8-windows-x64-Setup.exe` (119.6 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64-Setup.exe)
  + `YomiHub-0.5.8-windows-x64.appxbundle` (251.8 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64.appxbundle)
  + `YomiHub-0.5.8-windows-x64.zip` (119.5 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-windows-x64.zip)
  + `YomiHub-0.5.8-x86_64.apk` (178.3 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-0.5.8-x86_64.apk)
  + `YomiHub-RootCA.cer` (0.0 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YomiHub-RootCA.cer)
  + `YumiHub-Android-TV-0.5.8-arm64-v8a.apk` (168.8 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YumiHub-Android-TV-0.5.8-arm64-v8a.apk)
  + `YumiHub-Android-TV-0.5.8-armeabi-v7a.apk` (165.6 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YumiHub-Android-TV-0.5.8-armeabi-v7a.apk)
  + `YumiHub-Android-TV-0.5.8-x86_64.apk` (178.1 MB) — [Tải xuống](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.8/YumiHub-Android-TV-0.5.8-x86_64.apk)

### 2. GitHub Releases Webpage
- **URL:** `https://github.com/kiritokmn1403/YomiHub-Project/releases`
- **Trạng thái:** HTTP 200 OK
- **Ghi chú:** Trang web hiển thị danh sách công khai toàn bộ các phiên bản phát hành từ 0.1.0 đến 0.5.8. Có nút Download và release notes chi tiết.

### 3–5. Các Thư Mục Google Drive (Dự phòng)
1. **Google Drive Primary (`16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__`):**
   - **URL:** `https://drive.google.com/embeddedfolderview?id=16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__#list`
   - **Trạng thái:** HTTP 200 OK
   - **Nội dung:** Chứa 2 thư mục con phân nhánh: `Alpha` và `Beta`.
   - **Lưu ý kỹ thuật:** API `embeddedfolderview` chỉ hiển thị các thư mục cấp 1; để YomiHub kiểm tra các tệp APK bên trong, ứng dụng cần quét sâu vào các ID thư mục con này (đã được tối ưu trong cơ chế quét cập nhật).

2. **Google Drive Secondary 1 (`1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn`):**
   - **URL:** `https://drive.google.com/embeddedfolderview?id=1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn#list`
   - **Trạng thái:** HTTP 200 OK
   - **Nội dung:** Chứa các thư mục lưu trữ phiên bản sơ khai: `0.1`, `0.2`, `0.3`, `0.4`.

3. **Google Drive Secondary 2 (`1vLWPTfFznhWko0O6YGJqecnFEU5CLr10`):**
   - **URL:** `https://drive.google.com/embeddedfolderview?id=1vLWPTfFznhWko0O6YGJqecnFEU5CLr10#list`
   - **Trạng thái:** HTTP 200 OK
   - **Nội dung:** Thư mục hiện tại rỗng (0 tệp). Sẵn sàng để tải lên các bản sao lưu build v0.5.9.

### 6–8. Các Thư Mục MediaFire API (Dự phòng)
- **MediaFire YomiHub (`kg0wfu3lpbc98`):** HTTP 200 OK, kết quả API `result: "Success"`, 0 tệp.
- **MediaFire Alpha (`8s2tlcukdmw6x`):** HTTP 200 OK, kết quả API `result: "Success"`, 0 tệp.
- **MediaFire Beta (`jmgm4xds8kamx`):** HTTP 200 OK, kết quả API `result: "Success"`, 0 tệp.
- **Lưu ý kỹ thuật:** API của MediaFire hoạt động phản hồi JSON rất nhanh và ổn định. Do chưa có file tải lên nên trả về danh sách rỗng `files: []`. Trong log app 0.5.8, lỗi phát sinh khi kiểm tra MediaFire là do lỗi DNS hệ thống / Tor handshake khiến việc phân giải máy chủ `www.mediafire.com` thất bại (`Failed host lookup`), không phải lỗi từ phía máy chủ MediaFire.

---

## 3. Đánh Giá & Khuyến Nghị Cho Tính Năng "Check For Update" v0.5.9

1. **Thứ tự ưu tiên kiểm tra (Priority Fallback):**
   - **Ưu tiên 1:** GitHub Releases API (`https://api.github.com/repos/kiritokmn1403/YomiHub-Project/releases/latest`). Nguồn này luôn đầy đủ và có metadata chính xác nhất (19 tệp, kích thước, liên kết trực tiếp).
   - **Ưu tiên 2:** Google Drive (`embeddedfolderview`). Cần đảm bảo cơ chế xử lý lỗi khi mạng Tor đang trong quá trình kết nối mạch để không quăng ngoại lệ làm ngắt luồng.
   - **Ưu tiên 3:** MediaFire (`api/1.5/folder/get_content.php`). Sử dụng DNS-over-HTTPS (DoH Cloudflare) làm dự phòng để tránh lỗi `SocketException: Failed host lookup` khi DNS nhà mạng chặn domain `mediafire.com`.

2. **Chuẩn bị phát hành v0.5.9:**
   - Sau khi Claude hoàn thành dây chuyền dựng 0.5.9, toàn bộ 18–19 artifacts sẽ được đưa vào GitHub Release `v0.5.9`, và đồng thời tải bản mirror lên Google Drive `16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__` và MediaFire `kg0wfu3lpbc98`.
