# HAIKU_PACKAGE_CHECK - Kiểm gói Windows YomiHub 0.5.6

Thư mục: `output/0.5.6/`. Không sửa tệp nào. Tổng 9 tệp, trong đó 8 tệp có dòng trong SHA256SUMS-0.5.6.txt.

## Bảng tệp

| Tệp | Kích thước (byte) | SHA256 | Khớp? | Ghi chú |
|---|---|---|---|---|
| Install-YomiHub.bat | 1094 | cfffb268f8e479f16685b1131df2ccf53aa67bde833753b50c10f635382d7232 | Khớp |  |
| Install-YomiHub.ps1 | 1189 | ffa6cb7bed0da19d858b7eff99712e5d724721761b5263975fc7f688a3b2e728 | Khớp |  |
| YomiHub-0.5.6-changelog.md | 5414 | e4966740b7c86d2a27a9f421b02444e6fc23c39f39827afdbd389d7f416e0ff8 | Khớp | Bản sao trong audit-0.5.6/ dài 5415 byte, SHA256 fd75162a... (khác 1 byte) |
| YomiHub-0.5.6-windows-x64-Setup.exe | 259329536 | c6e517d54a69531d48a96363d15be8f6dc2853006381f8f77bcc6336b12d1ed0 | Khớp | Chưa kiểm cấu trúc (theo phạm vi) |
| YomiHub-0.5.6-windows-x64-full.zip | 259254314 | ae73d8eb883de8afb6f1badde7299eaa5fc37018f63f9f59989c400ff2bf654a | Khớp | Xem vấn đề 1, 2 |
| YomiHub-0.5.6-windows-x64.appxbundle | 263878259 | 8254316264d1937273ce774556d33e1971044fbe56f127fb2667cc35d52c0e06 | Khớp | Xem vấn đề 3, 4 |
| YomiHub-0.5.6-windows-x64.zip | 125165328 | 4d9e6824e587d2cb51c5c5e46519347a96e50492a7f272d2dd13a3e4206c5d1f | Khớp | Xem vấn đề 1, 2, 5 |
| YomiHub-RootCA.cer | 822 | a9bb1c0d81675c183481ea35fac290cbc907b62154d27d63a323396db8019950 | Khớp |  |
| SHA256SUMS-0.5.6.txt | 763 | (tệp băm, không tự liệt kê) | n/a | UTF-8 có BOM, CRLF (xem vấn đề 6) |

## Kết quả so với SHA256SUMS

- Khớp: 8/8 tệp. Thiếu dòng: không. Dòng thừa: không.
- Tệp `SHA256SUMS-0.5.6.txt` không tự liệt kê chính nó, đây là bình thường.

## Kiểm cấu trúc gói

| Gói | Số entry | YomiHub.exe | data/flutter_assets | Số DLL | version.json | Chuỗi 0.5.6 |
|---|---|---|---|---|---|---|
| windows-x64.zip | 160 | có | có (tên dùng `\`) | 40 | không có | chỉ trong `data\app.so` |
| windows-x64-full.zip | 406 | có | có (tên dùng `\`) | 122 | không có | chỉ trong `data\app.so` |
| windows-x64.appxbundle | 5 entry (bundle), 399 entry trong .appx lồng | có (trong .appx) | có (trong .appx) | 122 (trong .appx) | n/a | AppxManifest: Version=0.5.6.0 |

- Nội dung .appxbundle: `AppxMetadata/AppxBundleManifest.xml`, `AppxBlockMap.xml`, `[Content_Types].xml`, `AppxSignature.p7x`, và `YomiHub_0.5.6_x64.appx` (bên trong có `AppxManifest.xml`, Identity Name=YomiHub, Publisher=CN=YomiHub, O=YomiHub, C=VN, Executable=YomiHub.exe).
- Bundle manifest: Identity Version=2026.1110.1936.0; Package Version=0.5.6.0; Architecture=x64; Resource en-US, vi-VN.

## Vấn đề

1. **Zip dùng dấu `\` làm phân cách đường dẫn.** `windows-x64.zip` có 119/160 entry và `full.zip` có 365/406 entry chứa `\`, không entry nào dùng `/`. Windows Explorer đọc được, nhưng unzip/7z trên Linux/macOS hoặc Python zipfile không chuẩn hóa sẽ giải nén thành tệp phẳng có tên chứa `\`, không tạo thư mục `data/flutter_assets/`. Nên đóng gói lại với `/` (chuẩn ZIP).
2. **Không có `data/flutter_assets/version.json`** trong cả hai zip. Chuỗi `0.5.6` chỉ thấy trong `data\app.so` (snapshot AOT nhị phân), nên không xác nhận được phiên bản từ tệp JSON. Cần thêm version.json hoặc có cách xác nhận khác.
3. **Lệch phiên bản trong appxbundle:** Bundle Identity Version=2026.1110.1936.0, trong khi Package Version=0.5.6.0. Cần xác nhận đây là số build có chủ đích.
4. **Chữ ký appxbundle chưa kiểm:** có `AppxSignature.p7x`, Publisher khớp giữa bundle và package. Chưa xác minh chuỗi chứng chỉ (không có signtool/openssl trong phạm vi kiểm này). Cài đặt sideload cần `YomiHub-RootCA.cer`, nên cần kiểm chuỗi tin cậy riêng.
5. **Zip thường thiếu JRE và MES:** `windows-x64.zip` không có `yomihub_bin/mes/` (không có JRE, không có `MExtensionServer-v1.0.8-r1.jar`), trong khi `full.zip` và `.appxbundle` có. Đây có thể là chủ đích (bản không kèm MES), nhưng cần xác nhận vì `m_extension_server_plugin.dll` có mặt trong bản zip thường.
6. **SHA256SUMS có BOM UTF-8 và CRLF.** Công cụ `sha256sum -c` trên Linux có thể báo dòng đầu sai định dạng. So khớp thủ công vẫn đúng 8/8.
7. **Bản changelog lệch 1 byte:** `output/0.5.6/YomiHub-0.5.6-changelog.md` (5414 byte, khớp băm trong SUMS) khác `audit-0.5.6/YomiHub-0.5.6-changelog.md` (5415 byte). Cần xác định bản nào đúng.

Phạm vi: không mở `Setup.exe`, không kiểm nội dung `Install-YomiHub.*`, không chạy cài đặt.
