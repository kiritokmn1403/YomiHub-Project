# YomiHub 0.6.0 – 19/11/2026

## Tính năng mới
- **Bộ lọc tiện ích dạng ô chọn**: mọi lựa chọn trong bộ lọc của mọi kiểu tiện ích (Mangayomi, Mihon/Aniyomi/Nekoyomi, Kotatsu) nay là ô chọn – danh sách thả xuống thành ô chọn chọn-một, Sắp xếp thành ô chọn (bấm lại ô đang chọn để đổi chiều ↑/↓), chip thể loại Kotatsu thành ô chọn 3 trạng thái (bao gồm → loại trừ → tắt); nhóm ≤ 8 mục mở sẵn, nhóm ≥ 15 mục có ô tìm.
- **Sao Lưu Lên Google Drive**: mục riêng trong Dữ liệu & Bộ nhớ, biểu tượng logo Google; đăng nhập bằng tài khoản Google rồi sao lưu/khôi phục qua Google Drive.
- **Trình duyệt › Savior – "Quét mã trang tìm link video"**: tìm link m3u8/mp4 nằm sẵn trong mã trang, cấu hình trình phát (jwplayer `sources`, `og:video`, link bị thoát ký tự) trước khi bấm phát; không có link trực tiếp thì đề nghị mở khung trình phát nhúng để quét tiếp.
- **Short Video**: nhận diện thêm Kwai, RedGifs, xFree, Kwiky, Facebook Reels, Snapchat Spotlight, Moj.
- **Gợi ý kho tiện ích**: thêm Salmanbappi (97 nguồn anime – Aniyomi) và Secozzi (Jellyfin, Stremio, Torbox).
- **Từ Mangayomi v0.9.96**: thư viện mở lại đúng danh mục đã rời đi; bấm thẻ thể loại › "Tìm trong nguồn" nay tìm đúng thể loại đó; dòng cuối thư viện không còn bị thanh điều hướng nổi che.
- **Bản APK Android 6.0 chạy trên Android 7.0+**: hộp thoại có nút "Tải bản APK thường" mở thẳng trang phát hành mới nhất.

## Sửa lỗi (theo nhật ký 16–19/11/2026)
- **Bộ lọc**: một số mục bấm không đổi dấu chọn ("không chọn được") trong khung bộ lọc kiểu Mangayomi – khung nay tự vẽ lại sau mỗi lần bấm.
- Trang **Cập nhật** treo 2,7 giây (khung hình 2,8 giây): chương của từng mục được nạp ở nền thay vì truy vấn đồng bộ từng dòng trên luồng giao diện; huy hiệu số lượng chỉ còn đếm.
- Giật lúc mở app trên máy RAM lớn: tín hiệu "thiếu bộ nhớ" của hệ thống ngay sau khi mở không còn xóa ảnh bìa đang hiển thị.
- **Bộ lọc tiện ích**: một tùy chọn hỏng không còn làm mất cả danh sách bộ lọc (từ Mangayomi v0.9.96).
- **Tiện ích JavaScript**: yêu cầu PUT/DELETE/PATCH trước đây bị gửi thành POST.
- **CBHentai** đổi URL qua lại liên tục (hentaicube.xyz ↔ 2tencb.pro): thử thách Cloudflare không còn bị coi là máy chủ hỏng.
- **Ảnh nguồn Kotatsu** (vd. SAYHENTAI) qua cổng nội bộ trả trang lỗi HTML thay cho ảnh: giữ Referer của nguồn, thử lại, báo lỗi rõ; nhật ký ghi máy chủ ảnh thật thay vì 127.0.0.1.
- **Tor**: thông báo "chưa kết nối được sau 90 giây" khi Tor vẫn đang tự thử ở nền nay là cảnh báo, không còn là lỗi.
- **Health Connect**: nhắc thiếu quyền "Chánh niệm" tối đa 1 lần/ngày thay vì mỗi lần mở app.
- Thông báo "đang dùng APK Android 6.0" không hiện lại sau 0.5.7 (khóa phiên bản cũ) – đã sửa.

## Nền tảng
- Android 7.0+ (APK thường), Android 6.0 (APK android6 riêng), Android TV (YumiHub Android TV – không có Comic, Novel, Google Play Books, Booru), Windows 10/11 x64 (.appxbundle, Setup.exe, bản portable .zip).

---

## English

## New Features
- **Checkbox-based Extension Filters**: All filters in every extension type (Mangayomi, Mihon/Aniyomi/Nekoyomi, Kotatsu) are now checkbox-based. Dropdowns are now checkbox-select, Sort is now checkbox + direction, and Kotatsu genre chips are now 3-state checkboxes (include/exclude/off). Groups ≤ 8 items are expanded, ≥ 15 items have a search box.
- **Google Drive Backup**: Dedicated section in Data & Storage with a Google logo; backup/restore directly via Google Drive account.
- **Browser › Savior – "Scan page for video links"**: Finds m3u8/mp4 links in the page source, configures player (jwplayer sources, og:video, escaped links) before playback; suggests embedded player frame scanning if no direct link is found.
- **Short Video**: Added support for Kwai, RedGifs, xFree, Kwiky, Facebook Reels, Snapchat Spotlight, Moj.
- **Extension Repo Suggestions**: Added Salmanbappi (97 anime sources – Aniyomi) and Secozzi (Jellyfin, Stremio, Torbox).
- **From Mangayomi v0.9.96**: Library reopens at the correct category; tapping a genre tag › "Search in source" now searches the correct genre; last row in library is no longer covered by the floating navigation bar.
- **Android 6.0 APK running on Android 7.0+**: Dialog with "Download standard APK" button opens the latest release page directly.

## Fixes
- **Filters**: Some items couldn't be selected in Mangayomi-style filters; the filter frame now redraws after each tap.
- **Updates**: Resolved 2.7s UI freeze in the Updates tab.
- **Performance**: Reduced lag on startup for devices with high RAM.
- **Filter Resilience**: A broken filter option no longer breaks the entire filter list.
- **JS Extensions**: Fixed PUT/DELETE/PATCH requests incorrectly sent as POST.
- **CBHentai**: Fixed Cloudflare challenge loop.
- **Kotatsu Images**: Improved Kotatsu image handling (e.g., SAYHENTAI) returning error HTML instead of images.
- **Tor**: Changed "connection failed after 90s" from error to warning.
- **Health Connect**: Mindfulness permission reminder limited to once a day.
- **Android 6.0 APK notice**: the "running the Android 6.0 APK" notice no longer stays hidden after 0.5.7 (it was keyed to an old version string).
