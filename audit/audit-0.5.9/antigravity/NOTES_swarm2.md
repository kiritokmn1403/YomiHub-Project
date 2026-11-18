# Nhật ký kiểm chứng Đợt 2 YomiHub 0.5.9 (Swarm Verification Phase 2)

**Thời gian khởi tạo:** 18/11/2026 09:37  
**Cập nhật lần cuối:** 18/11/2026 09:49  
**Phạm vi:** Kiểm chứng kỹ thuật mạng độc lập, quét kho tiện ích và kiểm tra nguồn cập nhật cho phiên bản YomiHub 0.5.9.  
**Thư mục lưu trữ báo cáo:** `D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\audit\audit-0.5.9\antigravity\`  
**Quy tắc an toàn tuyệt đối:**  
- ✅ KHÔNG chỉnh sửa `overlay/`, `jobs/`, `D:\yh` hay các script build (Claude đang chạy dây chuyền dựng).  
- ✅ KHÔNG push git.  
- ✅ Chỉ ghi dữ liệu và báo cáo vào thư mục `audit-0.5.9\antigravity\`.  

---

## 1. Tiến độ thực hiện các hạng mục

| Thời gian | Hạng mục | Phương pháp / Lệnh | Trạng thái / Kết quả |
|:---:|:---|:---|:---:|
| 09:37 | Khởi tạo thư mục và nhật ký | `New-Item -ItemType Directory ...` | ✅ Hoàn thành |
| 09:40 | (1) Kiểm tra 14 URL trong sheet `Extension Repo` | Truy vấn HTTP độc lập, kiểm tra Content-Type, giải mã Protobuf / JSON, đếm số tiện ích | ✅ Hoàn thành (`extension_repos_report.md` & `extension_repos_report.json`) |
| 09:43 | (2) Quét 13 trang web trong sheet `Website Scan` | Phân tích HTML/API, trích xuất biểu thức chính quy (Regex) các URL repo, phân loại Comic/Film/Novel | ✅ Hoàn thành (`website_scan_repos.json`) |
| 09:48 | (3) Kiểm tra 8 nguồn trong sheet `Website Update Apps` | Truy vấn GitHub Releases API, cào dữ liệu Google Drive embeddedfolderview, gọi MediaFire REST API | ✅ Hoàn thành (`update_sources_report.md`) |
| 09:49 | (4) Rà soát toàn bộ tệp kết xuất & nghiệm thu | Kiểm tra tính đầy đủ, cấu trúc JSON và Markdown chuẩn UTF-8 | ✅ Hoàn thành 100% |

---

## 2. Chi tiết kết quả kiểm chứng

### (1) Báo cáo Kho tiện ích (`extension_repos_report.md` + `.json`):
- Đã kiểm tra đầy đủ 14 URL từ sheet `Extension Repo`.
- **Kết quả HTTP:** 13/14 URL khả dụng (HTTP 200), 1 URL lỗi (CodeKK bị timeout do máy chủ Trung Quốc).
- **Phát hiện quan trọng:**
  + `IReader repov2 index.min.json`: Hoạt động bình thường (HTTP 200, **147 nguồn**), không bị 404 như lo ngại. Cảnh báo trong nhật ký 0.5.8 là do YomiHub tìm tệp `repo.json` (metadata) và tệp này không tồn tại trên nhánh `repov2`.
  + `Keiyoushi`: Tệp `index.min.json` chỉ chứa 2 tiện ích tượng trưng; toàn bộ **>1,000 tiện ích** nằm trong tệp nhị phân `index.pb` (127 KB Protobuf).
  + `Kotatsu Shebyyy`: Là trang web GitHub Repository chứa 13 parsers mã nguồn mở, cần tải qua GitHub API/Releases.
  + `Aidoku Community`: Trả về đối tượng JSON chứa mảng `sources` gồm **176 nguồn**.
  + `Mangayomi`: Manga (335 tiện ích), Anime (64 tiện ích), Novel (9 tiện ích).
  + `LNReader`: **372 plugins** (v3.0.0).
  + `Yūzōnō Anime`: **248 tiện ích** anime/video.
  + `Kegareta Sauces`: **272 tiện ích** truyện tranh NSFW.

### (2) Báo cáo Quét Website (`website_scan_repos.json`):
- Đã quét 13 trang web từ sheet `Website Scan - Extension Repo`.
- 11/13 trang truy cập thành công (HTTP 200). 2 trang không tải được: `bio.link/iitachiyomi` (HTTP 403 do Cloudflare bảo vệ trang cá nhân) và `p.codekk.com` (ETIMEDOUT kết nối máy chủ).
- Trích xuất được tổng cộng **29 kho tiện ích duy nhất (Unique Repositories)**, phân loại đầy đủ thành các nhóm `Comic`, `Film`, `Novel` kèm danh sách trang nguồn phát hiện.

### (3) Báo cáo Nguồn kiểm tra cập nhật (`update_sources_report.md`):
- Đã kiểm tra đầy đủ 8 nguồn từ sheet `Website Update Apps`.
- **GitHub Releases (API & Web):** Hoạt động hoàn hảo (HTTP 200), bản mới nhất hiện tại trên kho là **`v0.5.8`** (`2026-11-17T14:48:42Z`), đính kèm đủ **19 artifacts** (APK Android thường, Android TV, Android 6.0, bản cài Windows EXE/Appx/Portable, chứng chỉ và SHA256 checksums).
- **Google Drive (3 thư mục):** Cả 3 thư mục đều phản hồi HTTP 200. Thư mục chính `16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__` chứa 2 nhánh `Alpha` và `Beta`; thư mục `1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn` chứa các bản build `0.1` - `0.4`; thư mục `1vLWPTfFznhWko0O6YGJqecnFEU5CLr10` hiện tại rỗng.
- **MediaFire (3 thư mục qua REST API):** Cả 3 thư mục đều phản hồi HTTP 200 với mã kết quả `Success`. Hiện tại cả 3 thư mục đều rỗng (`files: []`). Lỗi trong log 0.5.8 xuất phát từ việc máy người dùng lỗi DNS phân giải tên miền `mediafire.com`, không phải do máy chủ MediaFire bị lỗi.

---

## 3. Danh sách tệp đã tạo trong thư mục `audit-0.5.9\antigravity\`

1. `NOTES_swarm2.md` (Nhật ký tiến độ và quy trình thực hiện)
2. `extension_repos_report.md` (Báo cáo Markdown chi tiết 14 kho tiện ích)
3. `extension_repos_report.json` (Dữ liệu JSON cấu trúc của 14 kho tiện ích)
4. `website_scan_repos.json` (Kết quả quét 13 website và 29 kho tiện ích trích xuất được)
5. `update_sources_report.md` (Báo cáo trạng thái 8 nguồn kiểm tra cập nhật ứng dụng)
