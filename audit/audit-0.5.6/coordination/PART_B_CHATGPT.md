# Phần B — ChatGPT Desktop: lõi Dart dùng chung + Android + Android TV

Đọc `00_PLAN.md` trước (quy tắc CLAIMS, BUILD_LOCK, STATUS, ghi chú, git chỉ Phần C). Bản dựng của bạn: `D:\A.I Project\yh\build\mangayomi`.
Nâng phiên bản lên **0.5.6+48** trong overlay (một mình Phần B sửa `pubspec.yaml` và hằng số phiên bản).

## B1. Sửa lỗi theo log (YomiHub Update dòng 1, 11; Feature Check 3, 32, 43)
Dùng `LOG_FINDINGS.md` do Claude lập (sẽ có trong thư mục này). Ưu tiên:
1. Trình phát: `Cannot seek in this stream` lặp lại khi tiếp tục xem luồng trực tiếp; `[Player] has been disposed`; `Could not open codec`;
   `IsarError: An async write transaction is already in progress` khi lưu vị trí tập (vẫn còn sau `DbWriteQueue` 0.5.5).
2. `Null check operator used on a null value` ở `/AnimeLibrary`; `Using "ref" when a widget is about to or has been unmounted`.
3. Cloudflare: giải xong trên WebView nhưng trang vẫn không tải (nhiều nguồn); `Failed to bypass Cloudflare` ném ra `runZonedGuarded`.
4. Tor: không kết nối sau thời gian chờ, Tor làm ứng dụng thoát khi khởi động; OpenVPN từ chối đăng nhập phải báo rõ.
5. Telegram: `chat_id is empty` / `chat not found` – chặn tải lên khi thiếu Chat ID, hướng dẫn rõ (Feature Check 42; tham khảo Kotatsu + Telegram Bot Project).
6. Kho tiện ích: `Failed host lookup raw.githubusercontent.com` 45 lần; Đề Xuất timeout hàng loạt; bộ lọc không tải; cầu nối Kotatsu chưa chạy.
7. Hiệu năng: "Giao diện bị treo N giây", khung hình chậm ở `/more`, `/mangaReaderView`, `/animePlayerView`, `/AnimeLibrary`; cảnh báo thiếu bộ nhớ.
8. `TypeError: not a function` (Hako "Hình minh họa", Anime47 getDetail); `SyntaxError: unexpected token: 'https'` (FikFap getDetail).
Mỗi lỗi: tìm nguyên nhân gốc, sửa trong `overlay/`, thêm test hồi quy `test/yh_056_test.dart`.

## B2. YomiHub Update
- Dòng 6: quét Frank Yomik, Browser Fingerprint, Anti-bot Signature; tích hợp phần phù hợp (liên quan B1.3).
- Dòng 7 + Feature Check 39: Resume A Video – phát tiếp đúng vị trí đã thoát; đối chiếu Aniyomi, Nekoyomi, Mangayomi, Resume A Video.
- Dòng 9 + Feature Check 26: mở khóa Short Video cho mọi extension bên ngoài có hỗ trợ (tham khảo Video Short Scroll).
- ~~Dòng 10 (Isar libmdbx, Android 6.0)~~ — **chuyển sang Phần A (Claude Fable 5.2) lúc 22:10**. B chỉ cung cấp APK để A thử nếu được yêu cầu.

## B3. Feature Check do B chủ trì
5, 6, 7, 9 (kho + tiện ích + bộ lọc, dùng sheet Extension Repo) · 12 (VPN/DNS/AdBlock trên Android; VPN thử thêm bên ngoài) · 13 (chương/ảnh Comic, Novel, cuộn vô hạn)
· 15 (PiP) · 17 (đổi URL/tên miền, cưỡng chế) · 19 (Cloudflare) · 21 (quét website gợi ý Extension Repo khi mở app, bỏ repo đã có) · 22 (nhiều thư mục cục bộ)
· 25 (tracker) · 28 (dung lượng/tốc độ Android) · 33, 37, 38 (hợp nhất tiện ích, ký hiệu bộ đã hợp nhất, cài đặt Hợp Nhất Tiện Ích) · 35 (Health Connect) · 42 (Telegram).

## B4. Dựng và kiểm thử (sau `MỐC 1 DUYỆT`)
- 3 APK mobile (arm64-v8a, armeabi-v7a, x86_64) + 3 APK **`YumiHub Android TV`** dựng riêng với cờ TV, không có Comic, Novel, Google Play Books, Booru.
- Cài và thử trên AVD (API 23 nếu đạt, API 34, Android TV) và **thiết bị thật nếu `adb devices` thấy**. Mỗi mục: ảnh + video trong `audit-0.5.6/evidence/B/`.
- Đặt gói vào `output/0.5.6/`. Không ghi đè gói của Phần C.

## Không làm
Không sửa `overlay/windows/**`, script đóng gói Windows, README, không chạy lệnh ghi của git. Cần sửa tệp do C giữ thì ghi yêu cầu vào STATUS.

## Điều chỉnh 22:10
Các tệp điều hướng/màn hình chính/cài đặt giao diện do Phần A (Fable) giữ để làm U12, U13. B dừng sửa các tệp đó.
