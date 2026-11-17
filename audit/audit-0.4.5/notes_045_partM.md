
#### M. Sửa phần Short (Shorties) của tiện ích Pornhub (sheet Website Extension – `https://www.pornhub.com/shorties`) – 30/10/2026 18:10–

Mọi yêu cầu kiểm tra đều chạy bằng `curl.exe` trên Windows, phân giải tên miền qua DoH `--doh-url https://1.1.1.1/dns-query`. DNS mặc định của nhà mạng trả về lỗi (`000`) – chặn bằng DNS. Chỉ đối chiếu cấu trúc trang/JSON (khoá `vkey`, `token`, mã HTTP), không lưu nội dung.

Kết quả kiểm tra:
- `/shorties` trả 200: còn `var token`, `ddSeed`, `ddOffset = 10` và 5 clip đầu (`"vkey"`, `"videoTitle"`, `"imageUrl"`). Cách tách hiện tại vẫn đúng.
- `/shorties/get?token=<token mới>&offset=10&orientation=straight&seed=…` trả 200 JSON `{"seed","offset","videos":[…]}`.
- `view_video.php` vẫn có `flashvars_*`, gồm `mediaDefinitions` HLS 240/480/720 và mp4 `remote`.
- **Token cũ/không hợp lệ** gọi `/shorties/get` trả **403 HTML "Down for Maintenance"**.

**Nguyên nhân lỗi:**
- Token của trang có hạn: chuỗi token bắt đầu bằng thời điểm unix.
- Short Video mở feed ở **trang ngẫu nhiên 1–3** (`ShortsStore.randomStartPage`).
- `pornhub.js` dùng lại `yh_ph_short_state` đã lưu từ phiên trước khi `page > 1`, nên gửi token đã hết hạn. Server trả 403 HTML, `JSON.parse` lỗi, và Short Video hiện "Pornhub Shorties: HTTP 403" thay vì video.
- Lỗi văng từ `search()` chứ không phải danh sách rỗng, nên `yomi_shorts.dart` không thử lại từ trang 1.

**Sửa:**
1. `assets/yomihub_extensions/pornhub.js` (phiên bản tiện ích 0.2.0 → **0.2.1**, `builtin_extensions.dart`, để bản đã cài được cập nhật):
   - `st.ts` lưu thời điểm lấy token; token cũ hơn **15 phút** thì tải lại `/shorties`.
   - `shortiesApi` coi HTTP ≥ 400 hoặc thân trả về là HTML là lỗi rõ ràng (`HTTP 403 (HTML)`).
   - `shorties()` bắt lỗi 401/403/HTML thì tạo phiên mới (`shorties(1)`) một lần.
2. `lib/yomihub/player/yomi_shorts.dart`:
   - Lỗi ở lần tải đầu khi trang ngẫu nhiên > 1: thử lại từ trang 1 một lần (áp dụng cho mọi nguồn Short).
   - `_pick`: chọn biến thể HLS tốt nhất **≤ 720p** thay vì phần tử đầu (1080p). Trên máy ảo, CDN `*.phncdn.com` chỉ đạt ~25–150 KB/s, trình phát thường báo "Tự chuyển server: 480p HLS (tải quá 12s)".
   - Clip không phát được và lỗi trình phát ghi vào Nhật ký (`Shorts <nguồn>: …`, FC 34).

**Kiểm thử trên máy ảo** (`Medium_Phone_API_37.0`, APK x86_64 dựng 19:47; nguồn NSFW chỉ bật trên máy ảo thử; video `e045_ph_shorts_fixed.mp4`):
- Máy ảo khởi chạy bằng `-gpu swiftshader_indirect` bị thoát hẳn (tiến trình qemu biến mất) khi app phát video: 2 lần, 19:05 và 19:56. Đổi sang **`-gpu host`** thì chạy ổn định.
- Pornhub (18+) › nút **Short**: feed mở, có clip đầu. Lưu lượng mạng của máy ảo **9,7 MB trong 20 s**. Vuốt sang clip kế: 3,5 MB/15 s. So 2 ảnh chụp cách nhau 2 s bằng máy (không xem nội dung): khác biệt điểm ảnh trung bình 15,1 → **video đang chạy**.
- Nhật ký ghi đúng một clip lỗi: `Shorts Pornhub (18+): lỗi phát video: Failed to open http://127.0.0.1:…/yh_hls?u=…720P_4000K…` (dòng mới theo FC 34). Feed vẫn chuyển tiếp các clip khác.
- Lần chạy trước (`-gpu swiftshader_indirect`, bản 18:52): màn hình đen, mạng ~0. Đó là do trình giả lập đồ hoạ phần mềm, không phải do app.

**Tor trên máy ảo, lần chạy cuối** (`-gpu host`, 20:16–20:18):
- Chọn Snowflake trước rồi bật Tor. Sau ~30 s có `{"IsTor":true,"IP":"192.42.116.92"}`.
- Dòng chẩn đoán `[VPN] Tor: UseBridges=…` và "Tor dùng cầu nối … (theo cài đặt)" là mức INFO. Mức này chỉ ghi vào `logs.txt` khi bật "Ghi nhật ký chi tiết" (từ 0.2.3). Chế độ Tự động ghi WARNING nên luôn có trong nhật ký.
