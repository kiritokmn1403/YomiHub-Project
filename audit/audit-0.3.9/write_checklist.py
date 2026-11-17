import json
from pathlib import Path
root=Path(__file__).resolve().parent
data=json.loads((root/'Project YomiHub.json').read_text(encoding='utf-8'))
evidence={
1:'Đã đối chiếu metadata và mã player của ba upstream chính; chưa kiểm tra hoặc tích hợp toàn bộ 469 liên kết.',
2:'Đã sửa nhóm lỗi ưu tiên và đặt phiên bản 0.3.9+31; còn chờ dựng/kiểm tra trực tiếp.',
3:'Đã đọc log và sửa lỗi lưu tiến độ, nguồn và báo cập nhật; chưa xác nhận mọi lỗi trong log đã hết.',
4:'Đã sửa mặc định bốn tên miền và lỗi tiếng Việt; chưa kiểm tra nội dung trực tiếp của mọi website.',
5:'Cùng overlay cho Android/Windows; chưa xác nhận giao diện cuối trên hai nền tảng.',
6:'Đã sửa index IReader Windows và fallback v2; chưa kiểm tra nhập/đồng bộ mọi hệ thư viện.',
7:'Các index trong yh_repos_test đã có assertion và đạt lượt chạy chọn lọc; HTTP 14 URL đạt. Không đồng nghĩa mọi tiện ích hoạt động.',
8:'Bộ kiểm thử nền bao gồm tải xuống; cần thử cài tiện ích và bộ lọc thực tế.',
9:'Chờ kiểm tra tương tác và Liquid Glass trên bản release cuối.',
10:'Đã sửa parser index và danh tính nguồn chương; còn kiểm tra cài/đọc/phát theo engine.',
11:'Chưa kiểm tra đầy đủ ba bridge/server trên bản release cuối.',
12:'Chưa kiểm tra engine trình duyệt thực tế hoặc nâng dependency Chromium/Firefox.',
13:'Chưa kiểm tra kết nối VPN/DNS/AdBlock thực tế trên bản release cuối.',
14:'Đã sửa chọn parser theo nguồn gốc chương hợp nhất; cần thử tải ảnh/chương và cuộn vô hạn thực tế.',
15:'Test lưu tiến độ/khôi phục đạt; đã sửa race đổi server/chất lượng. Chưa kiểm tra Anime47 có đăng nhập và stream thực.',
16:'Chờ kiểm tra EPUB/PDF bằng tệp thử trên bản release cuối.',
17:'Chờ kiểm tra PiP thực tế; không suy ra từ test player.',
18:'Chưa kiểm tra Web Scanner đầy đủ.',
19:'Đã sửa alias/default URL, giữ custom URL; chưa kiểm tra chuyển domain thực tế cho mọi engine.',
20:'Chờ so sánh bố cục Android/Windows sau dựng.',
21:'Chưa kiểm tra luồng Cloudflare thực tế; CAPTCHA cần thao tác người dùng khi xuất hiện.',
22:'Đã sửa DOM, thứ tự phiên bản, lọc nền tảng và báo lỗi; test mock đạt. Cần kiểm tra giao diện/tải bộ cài.',
23:'Chưa xác nhận quét đủ 12 website lúc mở và loại repo trùng bằng thử nghiệm thực tế.',
24:'Đã đọc mã hỗ trợ nhiều thư mục và loại trùng/lồng; cần thử nhập/quét nhiều thư mục.',
25:'Đã đọc mã splash có animation; cần đo thời gian và kiểm tra hiệu ứng trong video.',
26:'Đã đọc thiết kế HTTP/UDP LAN; chưa truyền file giữa hai thiết bị độc lập.',
27:'Bộ test nền có tracker; chưa xác minh đồng bộ tài khoản thực.',
28:'Chưa kiểm tra Short Video và chuyển cuộn trên bản release cuối.',
29:'Đã bổ sung bản dịch máy được cho phép: 1.189 chuỗi tĩnh, 18 bảng không thiếu khóa; cần rà soát câu chữ/ARB/native.',
30:'Đã tối ưu tìm trùng O(n²) thành gom map, giảm ghi tiến độ lặp; chưa đo hiệu năng/dung lượng toàn ứng dụng.',
31:'Chưa kiểm tra dịch ảnh thực tế.',
32:'Quét tĩnh không còn thiếu khóa/placeholder; chưa bao phủ mọi chuỗi động/native.',
33:'Đã bổ sung 252 URL thiếu vào nhóm tham khảo, phân biệt với dự án thực sự tích hợp.',
34:'Đã bổ sung/bảo toàn log lỗi cập nhật, repo, seek/lưu tiến độ và Health Connect; chưa gây lỗi thử ở toàn bộ tính năng.',
35:'Đã sửa grouping không đổi sourceId thư viện, tránh nhóm chồng lấn; test nhóm đạt, UI cần kiểm tra trực tiếp.',
36:'Đã kiểm tra metadata nguồn trong khai báo; chưa đối chiếu toàn bộ ngôn ngữ/NSFW với nội dung từng site.',
37:'Phát hiện báo khả dụng/thành công giả khi native channel lỗi/null; đã sửa. Chưa tìm thấy handler trong overlay Android, chưa hoàn tất tích hợp.',
38:'Đã đọc mã WebView Play Books và sửa ranh giới domain; chưa xác nhận giao diện khớp 21 hình mẫu hoặc luồng tài khoản.',
39:'Đang chạy full test và build. Chưa có video kiểm tra 0.3.9; chưa xác nhận ổn định toàn bộ.',
}
lines=['# Đối chiếu yêu cầu 0.3.9','',
'Bản ghi tiến độ, không phải chứng nhận hoàn tất. Cập nhật cùng TECHNICAL_UPDATE_NOTES.md sau mỗi lần kiểm tra.','']
for row in data['Feature Check']:
    cells=row['cells'];id=cells.get('A','')
    if not id.isdigit():continue
    lines += [f'## {id}. {cells.get("C","")}', '', '**Trạng thái:** '+evidence[int(id)],'']
(root/'FEATURE_CHECK_STATUS.md').write_text('\n'.join(lines),encoding='utf-8')
print('Recorded all 39 requirements with evidence and remaining work.')
