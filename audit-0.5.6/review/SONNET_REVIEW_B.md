# Sonnet rà mã độc lập — Phần B (0.5.6+48), đợt 10/11 và R7–R12 (11/11)

Phạm vi: đọc diff từng tệp B, không sửa mã, không chạy test (chỉ đọc mã). "Nghi vấn" = chưa xác nhận bằng chạy thật.

## Kết luận: ĐỦ ĐIỀU KIỆN MỐC 1 (không có lỗi CHẶN). Có 3 mục NÊN SỬA nhỏ, có thể làm ở bản sau.

## R7–R12
| Yêu cầu | Kết quả |
|---|---|
| R7 pruneOldBackups | ĐẠT. Chỉ xóa tệp khớp regex `yomihub_YYYY-MM-DD_HH_mm_ss.(ms\|µs).backup` (khớp đúng tên `writeMangayomiBackupZip` sinh ra); chỉ chạy khi thư mục tên đúng `autobackup`, đường dẫn tuyệt đối, không theo symlink, chỉ `File`; mặc định `backupMaxCount`=0 = không giới hạn; dọn sau `await doBackUp(...).future` (bản mới ghi xong, lỗi ghi thì không dọn); `.partial` không khớp nên không bị xóa; log mỗi tệp xóa và mỗi lỗi. `automaticBackupDirectory` luôn thêm `autobackup` nên gốc bộ nhớ/ổ đĩa không bị quét. Test có ca tệp lạ, `.partial`, thư mục không phải autobackup, giới hạn 0. |
| R8 | ĐẠT (trung thực). 7 tệp không được import trong `lib/` ngoài chính chúng; bảng `integrationAuditTable` ghi "Chưa tích hợp" cho cả 6 dự án, NOTES_C đã đính chính. |
| R9 | ĐẠT. `autoTuneForAmdRyzen` và `verifySoftwareDecodingFallback` đã gỡ; còn `detectedCpu/isAmdCpu/isHighThreadCount` (xem GHI CHÚ). |
| R10 | 18 tệp i18n cùng 1575 khóa, bằng nhau. |
| R11 | ĐẠT. `refreshExtensionRepos` đếm ok/failed, `fetchSourcesList` nay ném lỗi khi URL rỗng / HTTP khác 200 / chỉ mục không phải List; nút báo "Kho thành công/Kho lỗi", kiểm `mounted` sau await, `finally` nhả cờ, ghi Nhật ký chỉ có host (không lộ URL đầy đủ). Test `refreshExtensionRepos` thật (ok 1/failed 1). |
| R12 | ĐẠT. Lần theo regex: 'Mob Psycho 100 - 05' khớp mẫu 4 (`\s[-–—]\s*(\d+)`) = 5; hàm luôn-true đã gỡ, test tương ứng gỡ theo. |

## Bảng phát hiện
| Mức | Tệp:dòng | Mô tả | Đề xuất |
|---|---|---|---|
| NÊN SỬA | integrations/zenshin_anime_tracker.dart:34 | Mẫu 2 `\[(\d{1,4})\]` chạy trước mẫu " - NN": 'Show - 05 [1080]' hoặc 'Show [2023] - 05' trả 1080/2023 thay vì 5. Hiện chưa nối vào app nên chưa ảnh hưởng. | Đặt mẫu " - NN" trước, hoặc loại số 4 chữ số giống năm/độ phân giải (480/720/1080/2160); thêm test. |
| NÊN SỬA | m_client.dart (LoggerInterceptor, ~dòng 487-495) | Trước đây khi không mở được UI Cloudflare thì ném lỗi; nay nuốt và trả phản hồi 403/503 HTML thử thách cho extension. Có log `logOnce`, nhưng extension có thể phân tích trang thử thách như dữ liệu hoặc vòng lặp thử lại phía extension. Nghi vấn (cần chạy thật với nguồn có CF). | Thử một nguồn CF ở nền (cập nhật thư viện); nếu extension lỗi khó hiểu, ném lỗi có thông điệp thay vì trả im lặng. |
| NÊN SỬA | cloud_backup_service.dart:~992 | Đã bỏ nhánh "chat not found → tự dò Chat ID từ getUpdates". Chat ID nhập sai nay báo lỗi thay vì tự sửa (hành vi 0.5.2/0.5.3 đã ghi trong log). Có thể là chủ ý (chặn đổi Chat ID âm thầm). | Xác nhận chủ ý; nếu có, ghi vào changelog. |
| GHI CHÚ | auto_backup.dart:127-132 | Nếu người dùng tự đặt thư mục sao lưu tên `autobackup` và để tệp tên đúng mẫu (hoặc sao lưu thủ công cùng mẫu) vào đó và đặt giới hạn, các tệp ấy cũng bị xóa. Xác suất rất thấp; vì khớp tên 100% với bản của app nên không phân biệt được. | Chấp nhận, hoặc ghi chú trong mô tả tùy chọn. |
| GHI CHÚ | auto_backup.dart:~137 | Sắp theo tên (thời gian cục bộ); đồng hồ lùi / đổi múi giờ có thể khiến bản "mới" bị coi là cũ. So sánh `basename == 'autobackup'` phân biệt hoa/thường (Windows "AutoBackup" thì không dọn: an toàn). | Chấp nhận. |
| GHI CHÚ | data_and_storage.dart:~366 | Chọn "1/2/3… bản" xóa ngay các bản cũ không hỏi lại. Chỉ trong thư mục autobackup, mẫu tên app, nên chấp nhận. | Tùy chọn: thêm lời nhắc xác nhận. |
| GHI CHÚ | win_diag.dart:34-38 | `isAmdCpu`, `isHighThreadCount` không ai dùng (chỉ test dùng `isAmdCpu`) — mã chết. | Gỡ khi tiện. |
| GHI CHÚ | yomi_shorts.dart:~286 | `_pendingLoads` giữ Future lỗi; `_loaded[slot]` đã gán nên clip lỗi không thử lại cho tới khi đổi slot. Hành vi cũ tương tự. | Chấp nhận. |
| GHI CHÚ | backup.dart:111 | `rethrow` khi `context == null` khiến `checkAndBackup` thất bại thật (đã ghi Nhật ký trước đó) — đúng ý, bản sao lưu lỗi nay không còn được coi là xong, và không dọn. | Không cần. |
| GHI CHÚ | vpn_service.dart | Tor: thêm generation + `_pendingTorStart` loại chồng chéo; không thấy vòng lặp vô hạn; `stopTor` tăng generation. Nếu `_startTor` thoát sớm do generation lệch thì `torStatus` giữ 'STARTING' cho tới khi stopTor đặt lại (nghi vấn, nhỏ). | Chấp nhận. |

## Các mục đã soát, không thấy lỗi
- Telegram: token luôn qua `_mask`/`maskToken`; `LoggerInterceptor` nay chỉ log method + host (hết lộ URL có token); test upload rỗng Chat ID là thật.
- library_updater.dart: bỏ `ref as BuildContext` (lỗi ép kiểu thật), dùng `container` lấy trước await.
- cf_challenge.dart: cờ `_checking`, kiểm `mounted` sau await, `forget/forgetAll` dọn đủ bản đồ; không vòng lặp vô hạn (poll Timer có hủy ở dispose — theo diff, chưa đọc dispose đầy đủ).
- anime_player_view.dart: `mounted`/`_mediaSessionId` được kiểm sau các await; `_isCompleted` không còn sai khi tổng thời lượng 0; `_handleRejectedSeek` tăng `_resumeToken`.
- gh_mirror.dart: chỉ gửi Accept/User-Agent/Range tới CDN (không rò Cookie/Authorization); test thật.
- torrent_server.dart, get_video_list/get_html_content (list bất đồng bộ), yomi_suggestions (cache theo (type,showNsfw), không cache kết quả rỗng), YomiTunnels.kt (xóa log OpenVPN cũ, `ovpnLog` có tồn tại và đồng bộ): ổn.
- github_projects.dart: đủ mọi link trong HAIKU_GITHUB_DIFF.md (0 thiếu).
- Isar: các tệp B không ghi Isar trực tiếp ngoài hàng đợi (m_client dùng `settingsRepository.update`, vốn có sẵn). Android TV: nút mới ở browse_screen có `focusColor` như các nút cạnh bên; không thấy hồi quy.
- Test: không thấy test giả trong yh_056_test / phần prune / refresh repos / mergeClearanceCookie.
