# NOTES_F1 — YomiHub 0.5.7: lỗi mạng trong `logs 7.txt` (tác nhân F1)

Thời gian làm: 14/11/2026 09:55 → 10:30 (Asia/Saigon). Đầu vào: `audit-0.5.7/input/logs 7.txt` (12–14/11/2026, bản 0.5.6.1 APK Android 6 trên máy Xiaomi arm64).
Phạm vi: chỉ sửa Dart trong `overlay/` (không sửa Kotlin, không commit). Bản gốc các tệp đã sửa: `audit-0.5.7/backup/src_0571/<đường dẫn>`; 18 tệp i18n trước khi thêm chuỗi: `audit-0.5.7/backup/src_0571/assets/yomihub_i18n_f1/`.

**Giới hạn phải nói rõ:** mọi thứ dưới đây chỉ được kiểm bằng `flutter test` + `flutter analyze` trên Windows. CHƯA chạy trên điện thoại/AVD, chưa dựng APK. Phần Tor (đổi cầu nối qua cổng điều khiển) và Cloudflare (WebView) phụ thuộc mã native/WebView nên cần kiểm trên máy thật trước khi coi là xong.

---

## 1. Cầu nối Kotatsu bị gửi vào 127.0.0.1:9 (6 cảnh báo)

**Yêu cầu:** yêu cầu tới `http://127.0.0.1:47350/kotatsu/...` không được đi qua proxy/VPN.

**Nguyên nhân (đã xác định bằng mã + log):**
- `overlay/lib/yomihub/vpn/vpn_state.dart` `activeProxy()` (dòng 59–68): khi Tor bật mà chưa kết nối và Kill switch bật → trả `http://127.0.0.1:9` (cố ý chặn để không lộ IP).
- `overlay/lib/services/http/m_client.dart` `httpClient()` (bản cũ dòng 72–76, 98–104, 122–126): proxy được gắn cho CẢ client của tiện ích (`rhttp.StaticProxy(... ProxyCondition.all)` và `findProxy = (_) => 'PROXY ...'`), không loại trừ địa chỉ loopback. Tiện ích Kotatsu là tiện ích JS gọi cầu nối nội bộ cổng 47350 bằng chính client đó (`lib/eval/javascript/http.dart` `_toHttpResponse`).
- Log 12/11 16:18:53–16:19:13: `tcp connect error 127.0.0.1:9 ConnectionRefused` đúng lúc Tor đang khởi động (16:17:26 bật, 16:18:55 "Tor chưa kết nối được sau 90 giây"), dòng 330 của log còn ghi "Kill switch đang chặn tiện ích này". Kể cả khi Tor đã kết nối thì yêu cầu này cũng hỏng, vì Tor không cho đi tới 127.0.0.1.
- Hậu quả phụ: `_toHttpResponse` coi đó là "cầu nối chết" → `markDead()` + khởi động lại cầu nối 3 lần/lượt; việc khởi động lại cắt luôn yêu cầu của các nguồn Kotatsu khác (các dòng "Kotatsu: connection closed" 16:18:31–16:19:19).
- Suy ra từ log: các nguồn Kotatsu khác cùng lúc vẫn ra Internet (có HTTP 404/405/500/522 thật) trong khi Kill switch đang chặn → người dùng đang dùng phạm vi VPN "theo từng tiện ích", chỉ CBHentai (Kotatsu) được đưa vào Tor.

**Đã sửa:**
- `lib/yomihub/vpn/vpn_state.dart` (+65 dòng từ dòng 83): `isLoopbackHost()` (localhost, *.localhost, 127.0.0.0/8, ::1, ::ffff:127.x); `jvmBridgePorts` {47350, 47360}; `jvmBridgeProxy`; `bridgeWouldLeak()`; thêm `webViewProxy()` + `routeNote()` (dùng ở mục 3).
- `lib/yomihub/net/loopback_bypass.dart` (MỚI): `YomiLoopbackBypassClient` – yêu cầu loopback đi bằng client trực tiếp (`MClient.defaultClient`, dart:io), còn lại đi client có proxy; `YomiRouteBlocked`.
- `lib/services/http/m_client.dart` dòng 121–135, 150: cả nhánh rhttp lẫn nhánh dart:io đều bọc bằng `YomiLoopbackBypassClient` khi có proxy; `findProxy` trả `DIRECT` cho loopback.
- `lib/eval/javascript/http.dart` dòng 127–129: lỗi do bộ chặn rò rỉ không còn kích hoạt khởi động lại cầu nối.
- `lib/yomihub/savior/savior.dart` dòng 173, `lib/yomihub/player/player_net.dart` dòng 39: tải xuống / trình phát cũng không đưa URL loopback vào proxy.
- `lib/yomihub/vpn/vpn_service.dart` dòng 195–198 (`_syncJvmProxy`): ghi `YomiVpnState.jvmBridgeProxy` (chỉ Android).

**Bộ chặn rò rỉ (quan trọng, là quyết định thiết kế của tôi – cần Opus/chủ dự án xem):** cầu nối Kotatsu/IReader tự tải trang bằng OkHttp trong JVM của app, đường mạng của nó theo proxy của JVM (`jvmProxy` = `proxyFor(null)`), KHÔNG theo client của tiện ích. Nếu chỉ "cho loopback đi thẳng" thì một tiện ích Kotatsu được chọn đi Tor theo phạm vi từng tiện ích sẽ ra Internet bằng IP thật. Vì vậy: yêu cầu tới cổng 47350/47360 chỉ được đi khi proxy của JVM trùng proxy của tiện ích (Android + phạm vi "Tất cả tiện ích"); ngược lại bị chặn với thông báo tiếng Việt rõ ràng (có dịch 18 ngôn ngữ) thay vì "Cầu nối Kotatsu chưa chạy".
- Hệ quả với đúng cấu hình của người dùng trong log (chỉ CBHentai-Kotatsu đi Tor): CBHentai (Kotatsu) VẪN chưa dùng được qua Tor – nhưng không còn khởi động lại cầu nối, không còn làm hỏng các nguồn Kotatsu khác, và báo đúng lý do. Phạm vi "Tất cả tiện ích" trên Android thì dùng được (JVM đi cùng proxy; khi Tor chưa lên thì JVM bị Kill switch chặn bên trong).
- Windows: `jvm_bridge.dart` không gắn proxy cho JVM của Kotatsu/IReader → luôn bị chặn khi tiện ích được định tuyến (trước đây cũng hỏng, giờ có thông báo đúng).

**Còn lại (mục 1):** muốn Kotatsu/IReader đi VPN theo từng tiện ích cần sửa Kotlin `YomiKotatsu.kt` (`Ctx.httpClient`, dòng ~710) để nhận proxy theo từng nguồn (vd. Dart gửi proxy kèm yêu cầu, Kotlin dùng `ProxySelector` theo nguồn) và gắn proxy cho JVM trên Windows. Chưa làm vì không kiểm thử được Kotlin ở đây. `lib/yomihub/extensions/ext_errors.dart` dòng 87 (gợi ý Kill switch) chỉ khớp chuỗi `127.0.0.1:9,` / `)` / dấu cách – lỗi OkHttp "Failed to connect to /127.0.0.1:9" ở cuối chuỗi có thể không khớp; tệp này tôi không sửa.

## 2. Tor kẹt 45–50 % với cầu nối "snowflake" (10 lỗi)

**Nguyên nhân:**
- Người dùng đặt cầu nối cố định "snowflake" (log: `Tor dùng cầu nối "snowflake" (theo cài đặt)`). `android/.../YomiVpn.kt` `startBridgeWatcher()` (dòng 320–354): chế độ cố định chỉ `applyBridge(mode)` rồi thoát; chỉ chế độ "auto" mới đổi cầu nối khi kẹt. Nên snowflake kẹt thì kẹt mãi.
- Thông báo "sau 90 giây" đến từ `scheduleTorWaiterTimeout` (YomiVpn.kt dòng 435–448, cố định 90 s) + `vpn_service.dart` `_startTor`.
- Phần kẹt tự thân là do mạng/Snowflake (V5 trong VPN_FIX.md – ngoài mã); có 5 phiên ngày 13/11 snowflake vẫn lên 100 %.

**Đã sửa (chỉ Dart, không đụng V1–V8):**
- `lib/yomihub/vpn/tor_fallback.dart` (MỚI, thuần Dart): `TorBridgeFallback.order()` = cầu nối đã chọn → các cầu nối còn lại có dòng bridge (snowflake/obfs4/meek; gói không có webtunnel) → kết nối thẳng; `TorStallTracker`: "kẹt" = phần trăm bootstrap KHÔNG TĂNG trong 75 s (cầu nối) / 40 s (kết nối thẳng) – cùng ngưỡng với watcher "auto" của native; bootstrap chậm nhưng vẫn tăng thì không bị ngắt; hết danh sách thì quay về cầu nối đã chọn và dừng.
- `lib/yomihub/vpn/vpn_service.dart` dòng 209–308: cài đặt `torBridgeFallback` (mặc định BẬT), `_torStallWatch` hỏi `torDiag` mỗi 5 s song song với `torStart`, đổi cầu nối trực tiếp qua kênh `torBridges` sẵn có (Kotlin áp qua cổng điều khiển, không khởi động lại Tor). Dòng 416, 484–492, 692–695, 713, 768: khởi động/dừng watcher, không ghi nhầm "theo cài đặt" cho cầu nối dự phòng, thông báo 90 s dùng câu "đang thử cầu nối … ở nền" đã có sẵn.
- `lib/yomihub/vpn/vpn_screen.dart` dòng 372–380: công tắc "Tự đổi cầu nối khi Tor bị kẹt" (chỉ hiện trên Android khi chọn snowflake/obfs4/meek). TẮT = hành vi cũ (chỉ dùng đúng cầu nối đã chọn). Chế độ "Tự động" và "Tắt" (không cầu nối) giữ nguyên.
- Nhật ký tiếng Việt: `[VPN] Tor kẹt ở 45% – Asking for relay descriptors suốt 76 giây với cầu nối "snowflake" – tự chuyển sang cầu nối "obfs4" (lần thử 2/4)…`; khi xong: `Tor đã kết nối qua cầu nối "obfs4" sau khi cầu nối đã chọn "snowflake" bị kẹt…`; khi hết cách: `Tor không kết nối được bằng cách nào (đã thử lần lượt: …) – quay lại cầu nối đã chọn…, hãy dùng Cloudflare WARP`.

**Còn lại (mục 2):**
- CHƯA kiểm trên thiết bị: việc Kotlin nhận `torBridges` với mode mới giữa lúc bootstrap và tor đổi cầu nối thật (đường mã có sẵn từ 0.4.5 cho `setTorBridge`, nhưng chưa ai chạy nó tự động).
- Mốc 90 s của `torStart` (Kotlin) giữ nguyên; lỗi "Tor chưa kết nối được sau 90 giây" vẫn ghi mức ERROR một lần mỗi lần bật.
- Kết nối thẳng nằm cuối danh sách: người chọn cầu nối để giấu việc dùng Tor với nhà mạng nên tắt công tắc mới (đã ghi trong phụ đề).
- Windows: chưa có dự phòng (tor.exe phải khởi động lại để đổi cầu nối; chờ cố định 240 s ở `win_vpn.dart` dòng 406).
- Chưa nhớ "cầu nối chạy được lần trước": mỗi lần bật vẫn thử cầu nối đã chọn trước (tốn tối đa 75 s nếu nó chết).

## 3. Giải xong Cloudflare trên WebView nhưng vẫn bị chặn (CBHentai 5 lỗi, MangaDex)

**Đã kiểm tra đường đi cookie/UA của từng engine:**
- Engine dart/JS (qua `MClient.init`): `MCookieManager._applyCookies` gắn cookie đã lưu + ép User-Agent của WebView theo host (`YomiCf.uaFor`). ĐÚNG. **Thiếu:** ngay sau đó `LoggerInterceptor` gọi `CloudScraper.applyTo` điền `sec-ch-ua` của hồ sơ CloudScraper ("Google Chrome" v140, nền tảng theo cài đặt) – mâu thuẫn với User-Agent thật của WebView (vd. `Chrome/141 … wv`). Accept-Language cũng lấy từ hồ sơ cố định.
- Engine mihon (APK): `MihonService.getCookie()` gửi `cookie` + `user-agent`; `DalvikHandler.kt` dòng 64–105 nạp vào cookie jar và `network.setUA()`; `UserAgentInterceptor` ép UA cho mọi yêu cầu OkHttp; `AndroidCookieJar` còn đọc thẳng cookie của WebView. ĐÚNG, không thiếu cookie/UA.
- Kotatsu: `yomiSolveCloudflare` trả UA, cookie lấy từ WebView. Không đổi.

**Lỗ hổng tìm được (nguyên nhân khả dĩ nhất của 5 dòng CBHentai – suy luận từ mã + nhịp thời gian trong log, KHÔNG tái hiện được ở đây):**
- `m_client.dart` `_handleResolveCf` (bản cũ dòng ~716–745) coi là "đã giải" ngay khi WebView CÓ cookie `cf_clearance` cho host. Cookie cũ còn sót trong WebView (hết hạn, hoặc lấy ở IP khác do bật/tắt VPN) làm nó báo "đã giải" tức thì dù trang vẫn là trang xác minh/chặn → tiện ích thử lại với cookie vô dụng → "đã giải xong … nhưng vẫn không tải được trang". Log 12/11 06:28:49 / 06:28:54 / 06:28:57 cách nhau 3–5 giây: quá nhanh so với một lần giải thật.
- Tiện ích APK chỉ được thử WebView ẩn (`/resolve_cf`), không bao giờ được mở trang xác minh có giao diện như các engine khác.
- `mihon/service.dart` `_isCf` coi mọi lỗi 403/503 của cầu nối là Cloudflare (MangaDex "không giải được Cloudflare" có thể chỉ là 403 thường) – không sửa được nếu không đổi Kotlin để trả header `server`.

**Đã sửa:**
- `lib/yomihub/cloudflare/cf_identity.dart` (MỚI, thuần Dart): `CfIdentity` (UA + `navigator.userAgentData.brands/mobile/platform` + `navigator.languages` của WebView đã vượt xác minh) → `sec-ch-ua*` khớp tuyệt đối, `accept-language` kiểu Chromium; bản lưu cũ chỉ có UA thì suy ra từ UA; Firefox/Safari thì không gửi client hints. `cfPageState()` phân biệt trang thường / trang xác minh (`_cf_chl_opt`, `#challenge-form`, tiêu đề) / trang chặn (1020).
- `lib/yomihub/cloudflare/cf_challenge.dart`: dòng 46–53, 78–129 lưu/đọc danh tính theo host (khoá `id:<host>` trong box `yomihub_cf_ua`), `pageState()`, `passed()`; dòng 188–197, 210–226 `saveFromWebView` chụp danh tính; dòng 328 trang xác minh có giao diện dùng dấu hiệu trang thay cho tiêu đề (tiêu đề bị dịch theo ngôn ngữ).
- `lib/services/http/m_client.dart`: dòng 398–409 áp cả danh tính (không chỉ UA) cho yêu cầu mang `cf_clearance`; dòng 709–820 `_handleResolveCf` + `_headlessResolveCf`: chỉ "đã giải" khi có cookie VÀ WebView đã rời trang xác minh; trả thêm `page`; tham số `interactive: true` chạy đủ chuỗi `YomiCf.solve` (một lần/host, rồi trang xác minh có giao diện); dòng 220 truyền `sourceId` cho `YomiCfFallbackInterceptor`.
- `lib/yomihub/cloudscraper/cloudscraper.dart` dòng 150–163: yêu cầu đã có `cf_clearance` thì không điền `sec-ch-ua` của hồ sơ CloudScraper.
- `lib/eval/mihon/service.dart` dòng 403–424: gọi `/resolve_cf` với `interactive: true`; dòng log lỗi (vẫn mức ERROR, vẫn có "[Cloudflare]" nên vẫn vào nhóm "[Lỗi Nguồn 403 / Cloudflare]") ghi thêm: đã gửi cf_clearance/UA hay chưa, WebView chỉ nhận trang chặn, và ghi chú khi WebView và tiện ích đi HAI đường mạng khác nhau (cf_clearance gắn với IP).
- `lib/yomihub/cloudflare/cf_webfetch.dart` dòng 74–75, 144–145: cùng ghi chú đường mạng; tải trang qua WebView cũng kiểm dấu hiệu trang xác minh.

**Còn lại (mục 3):**
- Không tái hiện được hentaicube.xyz/MangaDex ở đây; chưa có bằng chứng chạy thật là 5 lỗi sẽ hết. Dấu vân tay TLS/HTTP-2 của rhttp/OkHttp khác Chrome – không sửa được bằng header; với engine dart/JS đã có sẵn đường dự phòng tải trang qua WebView, engine mihon thì chưa có.
- `interactive: true` có thể làm trang xác minh bật lên khi tìm kiếm toàn cục với tiện ích APK (đã có giới hạn sẵn: cài đặt CloudScraper "interactive", chỉ khi app đang mở, từ chối thì nhớ 10 phút, thất bại nhớ 60 giây) – cần xem trên máy thật.
- Log cũng cho thấy trang đã đổi tên miền (ảnh tải từ `hentaicb.help` lúc 19:17:31) – có thể hentaicube.xyz chỉ còn trả 403; nên dùng "Đổi URL".

## 4. OpenVPN "máy chủ từ chối đăng nhập (sai tài khoản/mật khẩu)"

Không phải lỗi mã. `vpn_tunnels.dart` dòng 478–479 in câu này khi log OpenVPN có `AUTH_FAILED`; VPN Gate được nối với `vpn`/`vpn` (dòng 674–675) – đúng. VPN_FIX.md mục 6 đã ghi nhận trên AVD: `public-vpn-0` trả `AUTH_FAILED` sau PUSH_REQUEST dù tài khoản đúng (phía máy chủ), máy chủ khác thì vào được. Câu chữ hơi gây hiểu lầm với VPN Gate (người dùng không nhập tài khoản); đề xuất (chưa sửa, cần thêm chuỗi dịch): với hồ sơ `vpngate_*` ghi "máy chủ VPN Gate này từ chối phiên – hãy chọn máy chủ khác".

---

## Tệp đã đổi (tương đối so với `overlay/`)
Mới: `lib/yomihub/net/loopback_bypass.dart`, `lib/yomihub/vpn/tor_fallback.dart`, `lib/yomihub/cloudflare/cf_identity.dart`, `test/yh_057_f1_net_test.dart`.
Sửa: `lib/services/http/m_client.dart`, `lib/eval/javascript/http.dart`, `lib/eval/mihon/service.dart`, `lib/yomihub/vpn/vpn_state.dart`, `lib/yomihub/vpn/vpn_service.dart`, `lib/yomihub/vpn/vpn_screen.dart`, `lib/yomihub/cloudflare/cf_challenge.dart`, `lib/yomihub/cloudflare/cf_webfetch.dart`, `lib/yomihub/cloudscraper/cloudscraper.dart`, `lib/yomihub/savior/savior.dart`, `lib/yomihub/player/player_net.dart`, và 18 tệp `assets/yomihub_i18n/*.json` (thêm 3 chuỗi ở cuối mỗi tệp, 1578 → 1581 khoá, không đổi khoá cũ).
Tệp dùng chung cần lưu ý khi gộp: `m_client.dart`, 18 tệp i18n (tôi chỉ nối thêm ở cuối tệp).
Không sửa: Kotlin, `custom_draggable_tabbar.dart`, các tệp của S1.

## Công cụ / lệnh
- Đọc/sửa: `grep`, `sed -n`, python đọc-sửa-ghi (thay chuỗi có `assert count == 1`), `git diff` để lấy số dòng.
- Kiểm thử: job PowerShell trong `jobs/pending_fast/` dùng `q057_lib.ps1` (`Sync-Overlay`, `Run-Tests`, `flutter analyze --no-pub`): `f1_net1.ps1`, `f1_net2.ps1`, `f1_net3.ps1`; log ở `jobs/done/f1_net{1,2,3}.log` (UTF-16LE).

## Kết quả kiểm thử (trích log)
- `f1_net1` (10:19:42): analyze 10 mục → `2 issues found` = 1 info có sẵn từ trước (`cf_challenge.dart:338 curly_braces_in_flow_control_structures`) + 1 `unused_import` trong test của tôi (đã xoá); test `yh_057_f1_net_test` + `yh_057_vpn_test` + `yh_0561_vpn_resume_test`: `00:02 +36: All tests passed!` / `### TEST EXIT 0`.
- `f1_net2` (10:21:30, sau khi thêm i18n): `yh_057_f1_net`, `yh_043`, `yh_049`, `yh_050`, `yh_051`, `yh_052`, `yh_053`, `yh_054`, `yh_056_a`, `yh_056`: `00:19 +158: All tests passed!` / `### TEST EXIT 0` (gồm test "every tr() text has an English translation").
- `f1_net3` (10:24:16, bản cuối của `loopback_bypass.dart`, `http.dart`, test): `yh_057_f1_net` + 2 test VPN + `yh_056_a`: `00:12 +86: All tests passed!` / `### TEST EXIT 0`; analyze 3 tệp vừa đổi: `No issues found! (ran in 85.3s)` / `### ANALYZE EXIT 0`.
- Test mới `test/yh_057_f1_net_test.dart`: 18 test (5 loopback/proxy trong đó 1 test chạy máy chủ HTTP loopback thật qua `MClient.httpClient` khi Kill switch bật; 7 dự phòng Tor; 6 Cloudflare).
- KHÔNG chạy: toàn bộ bộ test, `flutter analyze lib` toàn phần, dựng APK/Windows, thiết bị thật/AVD. Nhánh rhttp (thư viện native) không nạp được trong `flutter test` nên phần bọc `YomiLoopbackBypassClient` quanh client rhttp chỉ được kiểm ở mức "đối tượng trả về đúng kiểu" + phân tích tĩnh.
