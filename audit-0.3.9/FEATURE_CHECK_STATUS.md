# Đối chiếu yêu cầu 0.3.9

Bản ghi tiến độ, không phải chứng nhận hoàn tất. Cập nhật cùng TECHNICAL_UPDATE_NOTES.md sau mỗi lần kiểm tra.

## 1. Kiểm tra cập nhật, tính năng mới, đồng thời tiến hành tối ưu hoá code rồi bổ sung vào ứng dụng các tính năng mới, các cập nhật mới các hạng mục, các project có trong sheet Project GitHub.

**Trạng thái:** Đã đối chiếu metadata và mã player của ba upstream chính; chưa kiểm tra hoặc tích hợp toàn bộ 469 liên kết.

## 2. Nâng cấp ứng dụng, bắt buộc tối ưu hoá tất cả các đoạn code với 1 vài cập nhật mới, yêu cầu mới của các project Github và các yêu cầu sửa đổi được đưa ra trong sheet YomiHub Update, sau đó tích hợp thẳng vào ứng dụng (lưu ý toàn bộ yêu cầu trong sheet YomiHub Update là bắt buộc)

**Trạng thái:** Đã sửa nhóm lỗi ưu tiên, đặt phiên bản 0.3.9+31 và hoàn tất 438/438 test trên mã cuối. Windows đã đóng gói và thử trực tiếp; Android đang dựng lại sau sửa dấu trang. Các mục chưa xác nhận được nêu riêng bên dưới.

## 3. Đọc file nhật ký hoạt động của ứng dụng và khắc phục lỗi ghi trong đó.

**Trạng thái:** Đã đọc log và sửa lỗi lưu tiến độ, nguồn và báo cập nhật; chưa xác nhận mọi lỗi trong log đã hết.

## 4. Kiểm tra hoạt động ổn định của các extension được tạo từ các website trong sheet Website Extension, đặc biệt đối chiếu các cài đặt liên quan tới các extension đó; đối với các extension có nhiều URL thì phải tối ưu cho tất cả các URL đó.

**Trạng thái:** Đã sửa mặc định bốn tên miền và lỗi tiếng Việt; chưa kiểm tra nội dung trực tiếp của mọi website.

## 5. Kiểm tra tính tương thích, độ đồng nhất, ngôn ngữ thiết kế của bộ giao diện giữa các phiên bản ứng dụng Android và Windows.

**Trạng thái:** Cùng overlay cho Android/Windows, 58 tệp thay đổi khớp hash. Đã kiểm tra các luồng lịch sử/EPUB/PDF trên Windows và nâng cấp/EPUB trên Android; chưa bao phủ mọi màn hình, ngôn ngữ và bố cục TV.

## 6. Khả năng đồng bộ với các thư viện khác, đặc biệt là lỗi không đồng bộ Extension Repo của các project GitHub trên, đặc biệt là Aniyomi, Nekoyomi, Kotatsu, Ireader, Aidoku và LNReader

**Trạng thái:** Đã sửa index IReader Windows và fallback v2; chưa kiểm tra nhập/đồng bộ mọi hệ thư viện.

## 7. Khả năng tương thích của các Extension Repo có sẵn với ứng dụng; sử dụng các extension repo được cung cấp sẵn trong sheet Extension Repo để kiểm chứng.

**Trạng thái:** Các index trong yh_repos_test đã có assertion và đạt lượt chạy chọn lọc; HTTP 14 URL đạt. Không đồng nghĩa mọi tiện ích hoạt động.

## 8. Khả năng tải xuống ổn định, đầy đủ của các Extension; Khả năng tương thích và hoạt động ổn định, đầy đủ của bộ lọc với các Extension

**Trạng thái:** Bộ kiểm thử nền bao gồm tải xuống; cần thử cài tiện ích và bộ lọc thực tế.

## 9. Khả năng tương thích, check lỗi kỹ thuật của bộ giao diện; Kiểm tra các tính năng, độ ổn định của Liquid Glass

**Trạng thái:** Chờ kiểm tra tương tác và Liquid Glass trên bản release cuối.

## 10. Khả năng tương thích của các extension với ứng dụng.

**Trạng thái:** Đã sửa parser index và danh tính nguồn chương; còn kiểm tra cài/đọc/phát theo engine.

## 11. Độ ổn định của tính năng Mangayomi Extension Server, Mangayomi ApkBridge, MiHon Extension Server.

**Trạng thái:** Chưa kiểm tra đầy đủ ba bridge/server trên bản release cuối.

## 12. Mức độ ổn định của trình duyệt, cập nhật dựa trên nhân Chromium và Firefox.

**Trạng thái:** Chưa kiểm tra engine trình duyệt thực tế hoặc nâng dependency Chromium/Firefox.

## 13. Khả năng hoạt động, tính ổn định và cập nhật các tính năng VPN & DNS, AdBlock có trong mục Project GitHub.

**Trạng thái:** Chưa kiểm tra kết nối VPN/DNS/AdBlock thực tế trên bản release cuối.

## 14. Kiểm tra lỗi không load được chương và không load được hình của các extension Novel và Comic, kiểm tra tính năng cuộn vô hạn của các extension Comic và Novel.

**Trạng thái:** Đã sửa chọn parser theo nguồn gốc chương hợp nhất; cần thử tải ảnh/chương và cuộn vô hạn thực tế.

## 15. Kiểm tra lỗi không xem được phim, kiểm tra tính năng đổi server của các nguồn Anime, Film & Movie có sẵn; kiểm tra khả năng xem phim của tiện ích Anime47 (tài khoản: [REDACTED] , mật khẩu: [REDACTED]).

**Trạng thái:** Test lưu tiến độ/khôi phục đạt; đã sửa race đổi server/chất lượng. Chưa kiểm tra Anime47 có đăng nhập và stream thực.

## 16. Độ ổn định, check lỗi các tính năng đọc file ebook và PDF

**Trạng thái:** Windows 0.3.9 đã mở/cuộn/zoom PDF và kiểm tra mục lục/chuyển chương/quay lại EPUB. Android QA đã nâng từ 0.3.8, giữ sách và mở lại đúng chương; phát hiện danh sách dấu trang không làm mới. Đã sửa mã, 3/3 test EPUB đạt; đang dựng Android và đóng gói lại để thử dấu trang trên binary mới. Search, vị trí cuộn chi tiết và các định dạng khác chưa kiểm tra đầy đủ. Xem `RUNTIME_CHECKS.md`.

## 17. Độ ổn định, check lỗi tính năng Picture-in-Picture (PiP); Kiểm tra tính năng PiP đối với các extension trong sheet Website Extension.

**Trạng thái:** Chờ kiểm tra PiP thực tế; không suy ra từ test player.

## 18. Độ ổn định, cập nhật bộ tính năng Web Scanner.

**Trạng thái:** Chưa kiểm tra Web Scanner đầy đủ.

## 19. Kiểm tra, check lỗi tính năng đổi URL, tên miền và cưỡng chế đổi URL, tên miền của ứng dụng đối với extension; check xem sau khi đổi tên miền hoặc cưỡng chế đổi tên miền thì tiện ích có hoạt động bình thường không.

**Trạng thái:** Đã sửa alias/default URL, giữ custom URL; chưa kiểm tra chuyển domain thực tế cho mọi engine.

## 20. Đối chiếu và thống nhất ngôn ngữ, cách bố trí của bộ giao diện ứng dụng bản Windows và Android.

**Trạng thái:** Chờ so sánh bố cục Android/Windows sau dựng.

## 21. Kiểm tra độ ổn định, check lỗi của tính năng Cloudflare và Cloudflare Bypass.

**Trạng thái:** Chưa kiểm tra luồng Cloudflare thực tế; CAPTCHA cần thao tác người dùng khi xuất hiện.

## 22. Kiểm tra tính năng Check For Update, đối với đường dẫn https://drive.google.com/drive/folders/16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__?usp=sharing

**Trạng thái:** Đã sửa DOM, thứ tự phiên bản, lọc nền tảng và báo lỗi; test mock đạt. Cần kiểm tra giao diện/tải bộ cài.

## 23. Khi mở ứng dụng, hãy quét thông tin về các Extension Repo trên các website có trong sheet Website Scan - Extension Repo , khi người dùng vào mục Extension Repo thì sẽ tự động gợi ý các Extension Repo có sẵn trên các website đó, nếu Extension Repo đó đã có sẵn thì thôi không hiển thị nữa.

**Trạng thái:** Chưa xác nhận quét đủ 12 website lúc mở và loại repo trùng bằng thử nghiệm thực tế.

## 24. Kiểm tra độ ổn định và tiến hành vá lỗi, sửa đổi tính năng Thư mục cục bộ nằm trong mục Tải Xuống, cho phép thêm nhiều thư mục cục bộ khác nhau.

**Trạng thái:** Đã đọc mã hỗ trợ nhiều thư mục và loại trùng/lồng; cần thử nhập/quét nhiều thư mục.

## 25. Kiểm tra, tối ưu hóa bộ giao diện loading khi mở ứng dụng, thiết kế logo trong giao diện loading thành logo bo tròn, thêm hiệu ứng animation giữa lúc chuyển từ màn hình logo ứng dụng sang giao diện loading, cụ thể là hiệu ứng từ hình vuông bo lại thành hình tròn, vẫn giữ thời gian giao diện loading dài 5 giây.

**Trạng thái:** Đã đọc mã splash có animation; cần đo thời gian và kiểm tra hiệu ứng trong video.

## 26. Kiểm tra khả năng hoạt động, độ ổn định của tính năng AirDrop & Quicksharing, bao gồm khả năng chuyển file giữa các thiết bị với nhau, khả năng chuyển file giữa điện thoại với điện thoại, điện thoại với máy tính và giữa máy tính với máy tính.

**Trạng thái:** Đã đọc thiết kế HTTP/UDP LAN; chưa truyền file giữa hai thiết bị độc lập.

## 27. Kiểm tra khả năng hoạt động, độ ổn định của tính năng trình theo dõi (tracker) trong ứng dụng.

**Trạng thái:** Bộ test nền có tracker; chưa xác minh đồng bộ tài khoản thực.

## 28. Kiểm tra tính năng Short Video & Video Short Scroll.

**Trạng thái:** Chưa kiểm tra Short Video và chuyển cuộn trên bản release cuối.

## 29. Kiểm tra và biên dịch các văn bản trong ứng dụng sang mọi ngôn ngữ mà ứng dụng này hỗ trợ.

**Trạng thái:** Đã bổ sung bản dịch máy được cho phép: 1.189 chuỗi tĩnh, 18 bảng không thiếu khóa; cần rà soát câu chữ/ARB/native.

## 30. Kiểm tra, viết lại, tối ưu hóa code để hoạt động hiệu quả, đúng yêu cầu; đồng thời tối ưu hóa dung lượng, tốc độ xử lý, độ mượt của ứng dụng.

**Trạng thái:** Đã tối ưu tìm trùng O(n²) thành gom map, giảm ghi tiến độ lặp; chưa đo hiệu năng/dung lượng toàn ứng dụng.

## 31. Kiểm tra bộ tính năng Image Translation của ứng dụng.

**Trạng thái:** Chưa kiểm tra dịch ảnh thực tế.

## 32. Kiểm tra xem có đoạn văn bản nào trong ứng dụng chưa tiến hành phiên dịch ra các ngôn ngữ khác thì tiến hành phiên dịch.

**Trạng thái:** Quét tĩnh không còn thiếu khóa/placeholder; chưa bao phủ mọi chuỗi động/native.

## 33. Kiểm tra danh sách dự án mã nguồn mở trong Project GitHub, đối chiếu với danh sách Dự Án GitHub đã sử dụng, dự án nào chưa được thêm vào thì hãy bổ sung vào.

**Trạng thái:** Đã bổ sung 252 URL thiếu vào nhóm tham khảo, phân biệt với dự án thực sự tích hợp.

## 34. Kiểm tra bộ tính năng ghi lỗi vào Nhật Ký Ứng Dụng; bắt buộc phải ghi vào Nhật Ký Ứng Dụng các lỗi phát sinh trong quá trình sử dụng ứng dụng, đặc biệt nhưng không giới hạn ở các tính năng: Extension không load được nội dung, Giải CloudFlare thất bại, Giải CloudFlare thành công nhưng extension vẫn không load được ứng dụng, Tải xuống không thành công, Video không tải được, Video không thoát được, Trình phát video không lưu đúng vị trí đã xem, Tính năng quét bộ lọc không hoạt động, Không thể truy cập vào cài đặt Wifi thiết bị, Không thể tải nội dung trong tiện ích,...

**Trạng thái:** Đã bổ sung/bảo toàn log lỗi cập nhật, repo, seek/lưu tiến độ và Health Connect; chưa gây lỗi thử ở toàn bộ tính năng.

## 35. Kiểm tra bộ tính năng hợp nhất tiện ích.

**Trạng thái:** Đã sửa grouping không đổi sourceId thư viện, tránh nhóm chồng lấn; test nhóm đạt, UI cần kiểm tra trực tiếp.

## 36. Kiểm tra và cập nhật lại các cài đặt ngôn ngữ và NSFW của các Extension trong sheet Website Extension.

**Trạng thái:** Đã kiểm tra metadata nguồn trong khai báo; chưa đối chiếu toàn bộ ngôn ngữ/NSFW với nội dung từng site.

## 37. Kiểm tra hoạt động ổn định của bộ tính năng Health Connect tích hợp trong ứng dụng.

**Trạng thái:** Phát hiện báo khả dụng/thành công giả khi native channel lỗi/null; đã sửa. Chưa tìm thấy handler trong overlay Android, chưa hoàn tất tích hợp.

## 38. Kiểm tra hoạt động ổn định và check lại bộ giao diện dựa trên sheet Google Play Books Screenshot của bộ tính năng Google Play Books tích hợp trong ứng dụng.

**Trạng thái:** Đã đọc mã WebView Play Books và sửa ranh giới domain; chưa xác nhận giao diện khớp 21 hình mẫu hoặc luồng tài khoản.

## 39. Kiểm tra hoạt động tổng thể của ứng dụng xem có lỗi giật lag nào không, đặc biệt là các cập nhật của ứng dụng nêu ra trong sheet YomiHub Update và sheet Feature Check; nếu có hãy khắc phục; Yêu cầu quay video lại quá trình kiểm tra.

**Trạng thái:** 438/438 test toàn bộ đạt sau sửa UI/dấu trang (`tests-039-release.log`). Windows đã đóng gói lại và xác nhận dấu trang/vị trí cuộn; Android đang dựng lại. Đã quay video Android 180 giây, gồm cả lỗi dấu trang trước sửa; chưa xác nhận ổn định toàn bộ hoặc đo hiệu năng mọi luồng. Xem `RUNTIME_CHECKS.md`.

## Đối chiếu riêng 10 yêu cầu bắt buộc trong YomiHub Update

| Dòng Excel | Yêu cầu | Kết quả hiện có và phần chưa xác nhận |
| --- | --- | --- |
| 2 | Sửa lỗi/cảnh báo trong nhật ký, tối ưu | Đã đọc log và sửa các nhóm lỗi được mô tả trong ghi chú kỹ thuật; chưa loại bỏ toàn bộ cảnh báo hoặc lỗi dịch vụ ngoài. |
| 3 | Sửa hợp nhất bị lag/treo, tham khảo upstream | Đã đổi tìm trùng sang map, giữ nguồn chương, sửa backup/tách; test đạt. Chưa chạy hợp nhất trực tiếp với mọi hệ extension. |
| 4 | Giao diện sau hợp nhất theo hình Merge | Đã thêm bộ chọn nguồn ở vùng thao tác/đầu danh sách chương; cần kiểm tra với nội dung từ repo thực. |
| 5 | Tự chọn tiện ích để hợp nhất trong cài đặt | Có màn hình chọn tiện ích; sửa nhóm chồng lấn và không ghi đè sourceId thư viện. Cần kiểm tra toàn bộ thao tác giao diện. |
| 6 | Sửa treo, lag, văng | Đã sửa các nguyên nhân cụ thể: tìm trùng O(n²), vòng đời player, mounted EPUB. Chưa có bằng chứng đảm bảo không còn treo ở mọi luồng. |
| 7 | Bổ sung dự án GitHub còn thiếu | Đã thêm 252 URL còn thiếu vào danh mục tham khảo; không gắn nhãn đã tích hợp cho mã chưa dùng. |
| 8 | Lưu và tiếp tục vị trí video | Đã sửa bảo vệ resume, thứ tự stop/open, ghi tiến độ, bỏ reset tại 95%; test hồi quy đạt. Chờ video thử trực tiếp đóng/mở, đổi server/chất lượng. |
| 9 | Sửa kiểm tra cập nhật | Đã sửa DOM parser, chọn bản theo nền tảng, lỗi mạng và tên tệp; test mock và Drive thực đạt (Drive đang có 0.3.8). |
| 10 | Sửa Website Extension | Đã sửa bốn mặc định tên miền, giữ URL tùy chỉnh và sửa mã hóa; chưa kiểm chứng nội dung/phát của toàn bộ site. |
| 11 | Thay Mặc định bằng Lịch sử đọc/xem dạng lưới | Đã có luồng lịch sử; sửa tên thẻ bị mất và xác nhận tên hiện dưới ảnh trên Windows. Chưa xác nhận toàn bộ trường hợp lịch sử trên Android. |
