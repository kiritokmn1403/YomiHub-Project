# GITHUB_MISSING_0571 – Dự án GitHub thiếu trong `lib/yomihub/about/github_projects.dart`

Ngày: 14/11/2026 (S2, chỉ đọc). Nguồn: `audit-0.5.7/input/Project GitHub.json` (sheet "Project GitHub", 666 hàng, 23 mục I-XXIII, 641 hàng có link) so với `overlay/lib/yomihub/about/github_projects.dart` (513 YomiGhProject, 29 nhóm, 675 URL).

## Kết quả: KHÔNG CÒN dự án nào thiếu (0 / 637 URL duy nhất)

- Cách đối chiếu: lấy mọi chuỗi `https?://...` trong cột C của sheet (cắt khoảng trắng, bỏ `/` cuối) và so khớp CHÍNH XÁC (phân biệt hoa/thường) với mọi URL trong tệp Dart: 0 URL không khớp; so khớp có chuẩn hóa (bỏ http/https, www, `.git`, #, ?, hoa/thường) cũng 0.
- Hàng duy nhất của sheet không có URL: mục VI.4 "Donut Browser" (ô link chỉ ghi tên). Mã đã bổ sung kho xác minh: github_projects.dart:262 (`https://github.com/donutbrowser/donutbrowser`) và :721 (`https://github.com/zhom/donutbrowser`).
- Tên nhóm hiển thị trong ứng dụng khác tên mục trong sheet (29 nhóm của app, gồm nhóm bổ sung 0.4.x–0.5.x; sheet có 23 mục) nhưng toàn bộ URL đều có mặt. Màn hình mở từ about_screen.dart:110-118 (`GithubProjectsScreen`).

| Mục sheet | Tên | URL thiếu |
|---|---|---|
| (không có) | – | – |

Chưa kiểm: nội dung `Project GitHub.xlsx` gốc có khác `.json` đã che hay không (chỉ dùng JSON); các URL đã chết (không gọi mạng).
