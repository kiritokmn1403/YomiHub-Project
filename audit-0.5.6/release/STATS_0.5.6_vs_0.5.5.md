# Thống kê YomiHub 0.5.6 so với 0.5.5

Nguồn: `coordination/00_PLAN.md`, `REVIEW_CLAUDE.md`, `notes/NOTES_A|B|C|F.md`, `review/*.md`, `inputs/Project_YomiHub_dump.txt`. Mức đánh giá do biên soạn đối chiếu ghi chú; có kết quả kiểm thử thiết bị QA2 (Mốc 2 duyệt 12/11/2026 00:40; xem changelog). Chưa kiểm: VPN, Tor, Telegram, tracker, Health Connect, AirDrop/Quick Share, PiP đầy đủ, Short Video, cài đè Setup.exe Windows.
Chú giải: **Đạt\*** = đạt ở mức mã + test tự động, chưa có kiểm thử trong ứng dụng hợp lệ; **Một phần**; **Không đạt**; **Chưa kiểm** = không có thông tin trong ghi chú.

## 1. Tổng quan
| Chỉ số | 0.5.5 | 0.5.6 |
| --- | --- | --- |
| Phiên bản | 0.5.5+47 | 0.5.6+48 |
| Số bài test tự động đạt | 175 (15 bộ) | 682/682 Android, 676/676 Windows |
| `dart analyze lib` | – | 0 lỗi (166 cảnh báo, 52 info) |
| Số khóa i18n mỗi ngôn ngữ | 1558 | 1575 (18 ngôn ngữ) |
| Tệp trong `output/` | 15 | 15 (6 APK, 4 gói Windows, RootCA, 2 kịch bản, SHA256SUMS, changelog) |
| Kích thước APK arm64-v8a | 176.976.319 B | 177.008.999 B |
| Tệp overlay thay đổi (manifest) | 21 | 78 (`changed_files.txt`) |

## 2. Tính năng mới (6)
| # | Tính năng | Tham chiếu |
| --- | --- | --- |
| 1 | Mục Thư Viện gộp 4 thư viện (TV: chỉ Phim & Điện Ảnh) | U12, A1 |
| 2 | Công tắc giao diện Cũ ↔ Mới (điều hướng nổi, tab viên, "Hoạt động") | U11, A2, C2 |
| 3 | Hạn mức sao lưu tự động (1–20 / không giới hạn) | U3, R7 |
| 4 | Nút Kiểm Tra Cập Nhật ở tab Tiện ích | U8, FC20, R11 |
| 5 | 34 liên kết Dự Án GitHub mới, chọn từng URL | U2, FC31 |
| 6 | Hàng đợi ghi Isar chống ghi chen + chống khóa chết | A4b, R15 |

## 3. Lỗi đã sửa theo khu vực
| Khu vực | Lỗi đã sửa (1 câu) | Tham chiếu |
| --- | --- | --- |
| Trình phát | Hủy vòng tua lặp "Cannot seek" khi mpv từ chối, ghi lý do vào Nhật ký | R1, R2, FC32, FC39 |
| Trình phát | Phát tiếp do một bộ điều phối xác nhận; chặn cập nhật track khi phiên đổi | B2, FC39, U7 |
| CSDL | Tác vụ không chờ bỏ qua hàng đợi gây "async write transaction already in progress" | A4b, R15, U10 |
| CSDL | Khôi phục sao lưu lớn không bị ghi chen (đo 500 nghìn chương 9,5 s < 120 s) | R15 |
| Sao lưu | Dọn bản cũ chỉ đúng tệp của app, mặc định không giới hạn, ghi Nhật ký (trước đó nguy cơ xóa tệp lạ) | R7, U3 |
| Sao lưu | Ghi tệp `.partial` rồi đổi tên; lỗi nền được ném lại | R7 |
| Sao lưu | Telegram giữ đúng Chat ID, hướng dẫn khi "chat not found", báo thiếu ID | B1.5, R17, FC42 |
| Mạng | Cloudflare: thay clearance cũ, không chép cookie sai host | B1.3, FC19 |
| Mạng | Không mở được giao diện giải Cloudflare: ném lỗi + ghi "Giải CloudFlare thất bại" | R16, FC32 |
| VPN | Tor: hợp nhất yêu cầu, kết quả muộn không kéo giao diện về STARTING; xóa lịch sử OpenVPN | B1.4, FC12 |
| Tiện ích | Cầu nối Kotatsu chết nay được ping, khởi động lại, gửi lại 1 lần | A3, FC5 |
| Tiện ích | Nút Kiểm Tra Cập Nhật báo đúng số kho lỗi, kiểm `mounted`, ghi Nhật ký | R11, U8 |
| Tiện ích | Gương GitHub (refs/heads, tags), bộ nhớ đệm gợi ý theo NSFW | B1.6, FC21 |
| Tiện ích | Bộ lọc Shorts thật cho từng tiện ích | B2, U9, FC26 |
| Hiệu năng | Cập nhật thư viện nền lấy ProviderContainer trước await (null check log 04/11) | B1.2, U13 |
| Hiệu năng | Đọc thư mục bất đồng bộ; infohash torrent theo luồng | B1.7, U13 |
| Giao diện | Nhãn "Play Books" qua i18n | R14 |
| Bản dịch | 10 khóa còn thiếu × 18 ngôn ngữ (yh_049 đạt) | R10, FC30 |
| Windows | Gỡ thao tác "Tối ưu Ryzen" mô tả sai/khóa không ai đọc | R9, U14 |
| Kiểm thử | Gỡ test luôn-true; sửa `parseEpisodeNumber('Mob Psycho 100 - 05')` = 5 | R12 |
| Gói | Zip dùng `/`, version.json, Bundle Version 0.5.6.0, SHA256SUMS LF không BOM | R13 |
| Gói | Script dựng không còn báo thành công giả khi không dựng gì | R19 |

## 4. Yêu cầu Excel – YomiHub Update (U1–U14)
| Mục | Yêu cầu | Mức | Ghi chú |
| --- | --- | --- | --- |
| U1 | Đọc nhật ký, sửa lỗi/cảnh báo | Một phần | Đã sửa các lỗi tìm thấy (seek, Isar, Cloudflare, Kotatsu, Tor, Telegram...); chỉ có test tự động, chưa thử thiết bị. Lỗi nguồn/parsers upstream không sửa (A3). |
| U2 | Bổ sung Dự Án GitHub còn thiếu | Đạt* | 34/34 URL, 637/637 URL Excel; test widget (FC31). |
| U3 | Gộp cài đặt Sao Lưu & Đồng Bộ | Một phần | Mục có từ 0.5.3; 0.5.6 thêm Số lượng bản sao lưu (R7). Chưa kiểm lại trong ứng dụng 0.5.6. |
| U4 | Công tắc Play Books/Booru vào Bật/Tắt tính năng | Chưa kiểm | Có từ 0.5.3 (theo ghi chú kỹ thuật); 0.5.6 chưa kiểm lại. |
| U5 | Quét/tích hợp Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, Mangayomi Project, Kotatsu Project, GIF Viewer | Không đạt | 6 mô-đun C viết xong nhưng CHƯA nối vào app (R8); Mangayomi: chỉ điều hướng nhóm; Kotatsu: sửa cầu nối, syncserver/plugin-sdk chưa tích hợp, subsampling không áp dụng. |
| U6 | Quét Frank Yomik, Browser Fingerprint, Anti-bot Signature | Chưa kiểm | Không có ghi chú/bằng chứng trong NOTES A/B/C/F. |
| U7 | Resume A Video (phát từ vị trí thoát) | Một phần | Sửa vòng tua/phát tiếp (R1, R2, B2), test 3/3; chưa thử trên thiết bị. |
| U8 | Nút Kiểm Tra Cập Nhật ở Tiện ích/Duyệt | Đạt | Mã + test nhiều kho (R11); QA2 (AVD): "Kho thành công: 1. Kho lỗi: 0." ĐẠT. |
| U9 | Short Video Scroll cho mọi extension hỗ trợ | Một phần | Bộ lọc Shorts thật (B2); chưa chạy trên Android. |
| U10 | Isar libmdbx + Android 6.0 | Không đạt | Android 6.0 KHÔNG ĐẠT (minSdk 24, isar 3.3.2). Hàng đợi ghi Isar: đạt ở mức test (A4b, R15). |
| U11 | Giao diện mới + chuyển Cũ/Mới | Một phần | Công tắc + điều hướng nổi + tab viên có; Shiori đầy đủ (thẻ, chuyển cảnh, rail) để 0.5.7 (R18). Ảnh Windows thật có ở evidence/C/whitewin. |
| U12 | Mục Thư Viện (Library) | Đạt | Hub + test 34/34; QA2: điện thoại thật, AVD và Windows Cũ/Mới ĐẠT; TV không có Truyện tranh/Tiểu thuyết/Play Books/Booru ĐẠT. |
| U13 | Treo, lag, văng | Một phần | Sửa Isar, Tor, cập nhật nền, IO đồng bộ; chưa đo lag trên thiết bị. |
| U14 | Windows/AMD Ryzen 9 thiếu tính năng | Một phần | R9: gỡ auto-tune; chỉ chẩn đoán + gợi ý giải mã. Cửa sổ trắng R21 là lỗi đã biết trên máy Intel. Chưa thử máy Ryzen. |

Tổng: Đạt 2 · Đạt\* 1 · Một phần 7 · Không đạt 2 · Chưa kiểm 2 (tổng 14)

## 5. Yêu cầu Excel – Feature Check (FC1–FC43)
| Mục | Yêu cầu | Mức | Ghi chú |
| --- | --- | --- | --- |
| FC1 | Cập nhật/tối ưu/tích hợp theo Project GitHub | Một phần | Xem U5. |
| FC2 | Nâng cấp theo YomiHub Update (bắt buộc toàn bộ) | Một phần | Xem bảng U1–U14: U5, U10 không đạt. |
| FC3 | Đọc log và sửa lỗi | Một phần | Xem U1. |
| FC4 | Tương thích/đồng nhất giao diện Android–Windows | Chưa kiểm | Chưa có kiểm thử đối chiếu hợp lệ. |
| FC5 | Đồng bộ thư viện khác (Aniyomi, Nekoyomi, Kotatsu, IReader, Aidoku, LNReader) | Một phần | Sửa cầu nối Kotatsu (A3); các kho khác chưa kiểm trực tuyến. |
| FC6 | Tương thích Extension Repo | Một phần | Chạy cục bộ 3/3 hàm phân tích tiện ích kho Kiritokmn (B1.8); chưa kiểm trực tuyến. |
| FC7 | Tải extension/bộ lọc ổn định | Chưa kiểm | Không có kết quả. |
| FC8 | Tương thích giao diện, Liquid Glass | Chưa kiểm | Không sửa Liquid Glass; chưa kiểm. |
| FC9 | Tương thích extension | Chưa kiểm | Không có kết quả. |
| FC10 | Mangayomi Extension Server, ApkBridge, MiHon Extension Server | Chưa kiểm | Có sẵn trong app (A3); chưa kiểm 0.5.6. |
| FC11 | Trình duyệt Chromium/Firefox | Chưa kiểm | Không có kết quả. |
| FC12 | VPN, DNS, AdBlock | Một phần | Sửa Tor/OpenVPN (B1.4); chưa thử thiết bị, chưa xác lập nguyên nhân Tor dừng 45–50%. |
| FC13 | Lỗi tải chương/ảnh; cuộn vô hạn | Chưa kiểm | Không có kết quả. |
| FC14 | Ebook/PDF | Chưa kiểm | Không có kết quả. |
| FC15 | PiP | Chưa kiểm | Không có kết quả. |
| FC16 | Web Scanner | Chưa kiểm | Không có kết quả. |
| FC17 | Đổi URL/tên miền, cưỡng chế | Chưa kiểm | Không có kết quả. |
| FC18 | Thống nhất ngôn ngữ/bố cục Windows–Android | Chưa kiểm | Chưa kiểm. |
| FC19 | Cloudflare và Bypass | Một phần | Cookie + R16 (test 4/4 + toàn bộ suite); chưa thử máy chủ thật. |
| FC20 | Check For Update theo Website Update Apps | Chưa kiểm | Chưa kiểm (khác nút U8). |
| FC21 | Quét và gợi ý Extension Repo | Một phần | Sửa bộ nhớ đệm gợi ý (B1.6); chưa kiểm quét thật. |
| FC22 | Thư mục cục bộ nhiều thư mục | Chưa kiểm | Không có kết quả. |
| FC23 | Màn hình loading bo tròn + animation, 5 giây | Chưa kiểm | Không sửa trong 0.5.6; chưa kiểm. |
| FC24 | AirDrop / Quick Share | Chưa kiểm | Không có kết quả (cần 2 thiết bị). |
| FC25 | Tracker | Chưa kiểm | Không có kết quả. |
| FC26 | Short Video / Scroll | Một phần | Xem U9. |
| FC27 | Biên dịch văn bản ra mọi ngôn ngữ | Một phần | 18 tệp cùng 1575 khóa; yh_049 đạt; chất lượng bản dịch chưa rà. |
| FC28 | Tối ưu mã, dung lượng, tốc độ | Chưa kiểm | Chưa đo so với 0.5.5; APK 173–187 MB. |
| FC29 | Image Translation | Chưa kiểm | Không có kết quả. |
| FC30 | Đoạn văn chưa dịch | Một phần | R10: thêm 10 khóa × 18 ngôn ngữ. |
| FC31 | Đối chiếu Dự Án GitHub | Đạt* | Xem U2. |
| FC32 | Ghi lỗi vào Nhật Ký | Một phần | Có: lý do từ chối tua (R1), Cloudflare thất bại (R16), kho lỗi (R11), xóa sao lưu (R7). Các tình huống còn lại chưa kiểm. |
| FC33 | Bộ tính năng hợp nhất tiện ích | Chưa kiểm | Không có kết quả. |
| FC34 | Ngôn ngữ/NSFW của Website Extension | Chưa kiểm | Không có kết quả. |
| FC35 | Health Connect | Chưa kiểm | Không có kết quả. |
| FC36 | Google Play Books (giao diện theo ảnh mẫu) | Chưa kiểm | Play Books là tab trong Thư Viện (R14 i18n); chưa đối chiếu ảnh mẫu. |
| FC37 | Giao diện sau hợp nhất + ký hiệu | Chưa kiểm | Không có kết quả. |
| FC38 | Hợp Nhất Tiện Ích: cài đặt tự chọn | Chưa kiểm | Không có kết quả. |
| FC39 | Lỗi không lưu vị trí xem | Một phần | Xem U7. |
| FC40 | Booru App | Chưa kiểm | Không có kết quả. |
| FC41 | Bật/tắt bộ tính năng và repo Truyện/Phim/Tiểu Thuyết | Một phần | Thư Viện tôn trọng công tắc (test A1); chưa kiểm trong app. |
| FC42 | Sao lưu Telegram | Một phần | Giữ Chat ID + hướng dẫn + báo thiếu ID (B1.5, R17); chưa upload thật. |
| FC43 | Kiểm tra tổng thể, quay video/ảnh trong ứng dụng | Một phần | QA2 12/11 đạt trên điện thoại thật, AVD, TV, Windows (xem changelog); còn chưa kiểm: VPN, Tor, Telegram, tracker, Health Connect, Quick Share, PiP đầy đủ, Short Video, Setup.exe. |

Tổng: Đạt\* 1 · Một phần 16 · Không đạt 0 · Chưa kiểm 26 (tổng 43)

## 6. Ghi chú
- Đánh số U theo thứ tự hàng của sheet YomiHub Update (A2=U1 … A15=U14). Ghi chú điều phối trước đây gọi nhầm giao diện mới/Thư Viện là "U12/U13"; đúng là **U11** (giao diện mới + chuyển Cũ/Mới) và **U12** (Thư Viện); U13 = treo/lag/văng, U14 = Windows/AMD Ryzen 9. Các mã U12/U13 trong NOTES_A/C và REVIEW_CLAUDE.md theo cách gọi cũ.
- "Chưa kiểm" nghĩa là không có thông tin trong ghi chú; không đồng nghĩa với lỗi.
- Kiểm thử trong ứng dụng (QA2, 12/11/2026) đã xong; chỉ các mục có trong danh sách ĐẠT của Mốc 2 được nâng từ Đạt\* lên Đạt (U8, U12).
- Bằng chứng QA2: `evidence/QA2/`, `evidence/fix/`, `evidence/R26/`, `evidence/C/whitewin/`. Lượt 11/11 12:48 đã bị hủy (R20).
