# VPN 0.5.7 — kiểm tra và sửa lỗi (12/11/2026)

## Trạng thái: ĐÃ CHẠY TRÊN AVD 12–13/11/2026 – xem mục "Kết quả AVD 12–13/11/2026" ở cuối (phần dưới đây là ghi chép đọc mã ban đầu)
- Runner công việc (`3_run_jobs.bat` / `3b_run_fast_jobs.bat`) KHÔNG chạy: `jobs/runner_fast_alive.txt` và `runner_alive.txt` dừng ở 11/11 23:16 UTC, tác vụ thử đặt vào `pending_fast` không được xử lý sau 35 giây (`a6_probe1.ps1` cũng nằm chờ). Môi trường của tôi là VM Linux, không có adb/flutter/emulator nên KHÔNG thể: chạy AVD, chụp ảnh trước/sau, `flutter test`, `flutter analyze`, dựng APK.
- Vì vậy mọi mục dưới đây là kết quả ĐỌC MÃ + log 0.5.6 (`audit-0.5.6/inputs/logs (6).txt`); chưa có bằng chứng chạy thực. Không có ảnh, không có APK thử.
- Đã chuẩn bị sẵn: `jobs/pending/vpn057_build.ps1` (kiểm BUILD_LOCK, ghi "VPN <giờ>", chép 4 tệp đã sửa sang `D:\yh\build\mangayomi`, `flutter test` toàn bộ, `flutter analyze lib`, dựng x86_64 → `audit-0.5.7/vpn/apk/YomiHub-0.5.7-vpn-x86_64.apk`, trả khóa). Không ghi vào `output/0.5.6`. Khởi động lại runner là nó tự chạy; log ở `jobs/done/vpn057_build.log` (UTF-16).

## Lỗi tìm được (đọc mã)
| # | Triệu chứng | Nguyên nhân (tệp:dòng, trước sửa) | Trạng thái |
|---|---|---|---|
| V1 | Mihon Proxy/Xray với link vmess/vless TLS có `sni=` hoặc `"host":""` rỗng: bật "kết nối" nhưng không ra Internet (TLS lỗi) | `vpn_tunnels.dart` `_stream`: `q['sni'] ?? q['peer'] ?? q['host'] ?? host` — chuỗi rỗng không phải null nên serverName=''; `config()` lại đổi địa chỉ thành IP → SNI là IP. Tương tự Host của ws khi không có `host`. | ĐÃ SỬA (chưa chạy thật) |
| V2 | Tor toàn thiết bị, chế độ "ứng dụng đã chọn": nếu mọi gói đã chọn đều đã gỡ → VPN áp cho CẢ MÁY gồm YomiHub, Tor tự vào hầm của chính nó (vòng lặp, mất mạng) | `YomiTorVpnService.kt` ~dòng 99-102: `addAllowedApplication` lỗi bị nuốt, danh sách cho phép rỗng = mọi ứng dụng | ĐÃ SỬA: không tạo hầm, báo lỗi tiếng Việt |
| V3 | Nhật ký ghi "Tor đã kết nối (muộn hơn thời gian chờ)" và chẩn đoán mạch Tor 2 lần ở MỌI lần bật Tor bình thường (log 31/10 06:17:09, 08:30:30…) | `vpn_service.dart` handler `torStatus` → `_onTorLateOn` chạy ngay khi native báo ON, ~300 ms trước khi `torStart` trả về | ĐÃ SỬA: chờ `_pendingTorStart`, nếu đã chạy thì thoát im lặng; ON thật sự muộn vẫn được nhận |
| V4 | Tắt Tor khi dịch vụ còn đang bind (svc==null): Tor vẫn khởi động nền sau đó (Dart hiện OFF) | `YomiVpn.kt` `torStop` (dòng ~407): nhánh `svc == null` chỉ đặt cờ OFF, `bindService` đã gửi vẫn tiếp tục | ĐÃ SỬA (cờ `torStopRequested` + `holdTorDormant`, không unbind, không vòng khởi động lại) – kiểm AVD ĐẠT, xem cuối tệp |
| V5 | Tor kẹt 45–75% trên mạng chặn Tor (log 08/11: 8 lần "dừng ở 45%/50%", ghi mức ERROR dù Tor vẫn thử nền) | Chủ yếu do mạng/Snowflake bên ngoài; mức log ERROR cho trạng thái hồi phục được là hơi nặng | NGOÀI MÃ / không sửa |
| V6 | 04/11 09:04 "Tor làm ứng dụng thoát" giả | đã sửa ở 0.5.2 (`_clearTorGuard`); không tái hiện | ĐÃ XỬ LÝ TRƯỚC |

Chưa kiểm vì thiếu runtime: WARP (cổng UDP dự phòng, `_warpReachable`), OpenVPN/VPN Gate, đổi chế độ khi đang chạy, thoát app khi VPN bật, `dumpsys connectivity`, IP ngoài (`check.torproject.org`). Các điểm cần xem khi có runner: `setWarpMode` gọi lại `setWarpEnabled(true)` khi đang UP (GoBackend đổi cấu hình), `_applyTorVpn` khi đổi chế độ, và V4.

## Tệp đã sửa (overlay)
- `overlay/lib/yomihub/vpn/vpn_tunnels.dart` (`_stream`: hàm `nz`, SNI/Host)
- `overlay/lib/yomihub/vpn/vpn_service.dart` (`_onTorLateOn`)
- `overlay/android/app/src/main/kotlin/com/kodjodevf/mangayomi/YomiTorVpnService.kt` (`startTunnel`)
- Test mới: `overlay/test/yh_057_vpn_test.dart` — 6 test (V1 x3: vmess/vless/reality; định tuyến kill-switch, scope, normaliseProxy). CHƯA CHẠY.

## Việc còn lại khi runner chạy
1. Khởi động `3_run_jobs.bat`; `vpn057_build.ps1` tự chạy (hoặc chép sang `pending_fast`).
2. Đọc `jobs/done/vpn057_build.log`: TEST_EXIT, ANALYZE_EXIT=0, APK.
3. Cài `-r` lên AVD `YomiHub056_Phone_API34`, chạy lại từng chế độ, chụp ảnh trước/sau (0.5.6 vs bản thử), kiểm `dumpsys connectivity` và IP ngoài; cập nhật mục này.


## Kết quả AVD 12–13/11/2026
AVD `YomiHub056_Phone_API34` (x86_64, Google APIs, 2 GB RAM, `-gpu host`; với `-gpu swiftshader_indirect` qemu văng 0xc0000005 hai lần lúc mở YomiHub – lỗi máy ảo, không phải app). Phạm vi VPN của app: "Toàn bộ thiết bị". IP thật của mạng thử: 113.177.247.151. Bật "Bật ghi nhật ký" (Giới thiệu) để `logs.txt` có dòng [VPN]. Chỉ một máy ảo chạy mỗi lúc (AVD_LOCK "VPN …"; hai lần chờ A6 trả khóa).

APK đã dựng (x86_64 release, `audit-0.5.7/vpn/apk/`, versionName vẫn `0.5.6`/versionCode 4048 vì pubspec chưa nâng):
| Tệp | Nội dung | SHA-256 |
|---|---|---|
| `YomiHub-0.5.6.1-vpn-x86_64-truocV4.apk` (vpn057_apk4) | V1+V2+V3, `YomiVpn.kt` cũ của build (30/10) | – (bản trung gian) |
| `YomiHub-0.5.6.1-vpn-x86_64-V4a.apk` (vpn057_apk5) | + V4 (overlay `YomiVpn.kt` của agent trước) | `FD88C396…628944` |
| **`YomiHub-0.5.6.1-vpn-x86_64.apk` (vpn057_apk6, BẢN CUỐI)** | + V4b (cổng Tor) | `F1704210C98529864E19E844403C8BA93450D446569F7E1AAFAC9D8041356A62` |

| # | Mục | Kết quả | Bằng chứng (`evidence/`) |
|---|---|---|---|
| 1 | Cài `-r`, `dumpsys package` | ĐẠT: cài đè giữ dữ liệu; `lastUpdateTime` 23:17:55 (apk4), 00:46:31 (apk5), 02:01:19 (apk6) đúng giờ cài; versionName `0.5.6` (4048) – chưa nâng số phiên bản | log `jobs/done/v2_emu1/v2_inst/v2_emu8.log` |
| 2 | Tor toàn thiết bị | ĐẠT: "Đã kết nối • HTTP 8118 • SOCKS 9050 • Toàn bộ thiết bị" sau 15–21 s; `dumpsys connectivity` có `ni{VPN CONNECTED}` tun0 198.18.0.1, DNS 198.18.0.2; Chrome `check.torproject.org` "Congratulations… configured to use Tor", IP 185.220.101.27 (apk4) / 204.8.96.66 (apk6). Tắt → NO-VPN, IP về 113.177.247.151. (Lệnh `nc` từ adb shell không ra Internet qua tun2socks của Tor – chỉ ảnh hưởng công cụ đo, Chrome đi bình thường.) | `v2_tor0_before`, `v2_tor2_state`, `v2_tor3_chrome`, `v2_tor4_off`, `v2_v4b_chrome_tor` (`v2_tor1_connecting` trùng `tor2` – không tính) |
| 2b | V3 log "muộn" | ĐẠT: phiên Tor 23:44–23:45 chỉ có dòng `[VPN] Tor: UseBridges=0 … PROGRESS=100`, không có "Tor đã kết nối (muộn hơn thời gian chờ)" | `v2_logs_v3.txt`, `v2_logs_on` |
| 3 | V4 bật→tắt trong 0,3–1 s | ĐẠT (apk5/apk6): sau 30 s không có cổng 9050/8118 nghe, 0 kết nối TCP của uid app, không có mạng VPN, UI "VPN đang tắt" (tor ở trạng thái `DisableNetwork=1`; luồng `tor` vẫn trong tiến trình như thiết kế – tor-android không khởi động lại được trong cùng tiến trình). Trên apk4 (chưa có V4) với nhịp 1 s cũng không thấy Tor chạy nền → lỗi gốc không tái hiện được bằng adb, bản sửa V4 giữ làm phòng ngừa. | `v2_v4_apk4_*`, `v2_v4_fix_*`, `v2_v4b_fastoff`, `v2_v4b_30s` |
| 3b | **V4b (lỗi mới do V4)**: bật lại sau khi tắt sớm | apk5 KHÔNG ĐẠT: "Tor • Đã kết nối • HTTP 0 • SOCKS 0", không tạo VPN thiết bị, proxy trong app tắt (`torRunning=false`) dù UI báo đã kết nối. Nguyên nhân: TorService chỉ đọc cổng một lần khi cổng điều khiển vừa lên; lúc đó đã `DisableNetwork=1` nên chưa có listener → cổng = 0. Sửa (`YomiVpn.kt`): `refreshTorPorts()` hỏi `GETINFO net/listeners/socks|httptunnel` trên luồng io ở nhánh bật lại và ở `torStatus` khi ON mà cổng = 0; `torInfo()` dùng cổng này khi TorService trả 0. apk6 ĐẠT: "HTTP 8118 • SOCKS 9050 • Toàn bộ thiết bị" sau 14 s, có VPN, 7 kết nối, Chrome qua Tor (204.8.96.66); tắt → hết listener, 0 kết nối. | `v2_v4_fix_on_again` (lỗi), `v2_v4b_on_again`, `v2_v4b_chrome_tor` |
| 4a | Cloudflare WARP | ĐẠT: kết nối 22–23 s; VPN tun0 DNS 1.1.1.1/1.0.0.1/2606:4700:4700::1111; Chrome `cdn-cgi/trace` `warp=on`, ip 2a09:bac5:…, colo HKG; shell ra 2a09:bac1:… | `v2_warp1_on`, `v2_warp2_chrome_trace` |
| 4b | WireGuard (hồ sơ "Cloudflare WARP • YomiHub") | KHÔNG ĐẠT trên apk6 (V8) → ĐÃ SỬA, kiểm lại ĐẠT ở mục "V7/V8" cuối tệp: tunnel lên (VPN 104, DNS 1.1.1.1) nhưng logcat `Handshake did not complete after 5 seconds` lặp liên tục, không ra Internet (Chrome trắng, DNS lỗi); UI vẫn ghi "Đã kết nối". Hồ sơ cũ/khóa WARP đã hết hạn là nguyên nhân khả dĩ (WARP cùng peer bắt tay được qua cổng khác) – ngoài mã; nhưng UI báo "Đã kết nối" khi chưa bắt tay là lỗi hiển thị (chưa sửa: cần đọc `lastHandshake` từ GoBackend `getStatistics`). Không có hồ sơ WireGuard khác để thử. | `v2_wg0_dialog`, `v2_wg1_state`, `v2_wg2_chrome_trace` |
| 5 | Xray (V1) | Chỉ kiểm bằng test đơn vị (`test/yh_057_vpn_test.dart`, 3 test V1) – không có máy chủ vmess/vless thử | – |
| 6 | OpenVPN / VPN Gate | ĐẠT: tải 96 máy chủ; `public-vpn-0` bị máy chủ trả `AUTH_FAILED` sau PUSH_REQUEST (app gửi vpn/vpn đúng – phía máy chủ); `public-vpn-127` "Initialization Sequence Completed", VPN 108, DNS 10.236.254.254/8.8.8.8, Chrome trace ip 219.100.37.236 loc=JP; Tắt → NO-VPN. OpenVPN hồ sơ riêng: 0 hồ sơ – không kiểm. | `v2_vg0_list`, `v2_vg1_state` (lỗi auth), `v2_vg3_state`, `v2_vg4_chrome_trace` |
| 7a | Đổi chế độ khi đang chạy | ĐẠT: Tor (VPN 103) → bật WARP → hộp thoại "Chỉ bật được 1 dịch vụ VPN… Chuyển sang Cloudflare WARP" → WARP kết nối 22 s (VPN 107), Tor về dormant (không listener, 0 kết nối); WARP → WireGuard cũng chuyển đúng (103 → 104). Không FATAL. | `v2_sw0_dialog`, `v2_sw1_warp` |
| 7b | Vuốt app khỏi đa nhiệm khi VPN bật | Không văng (không FATAL/ANR, tiến trình còn sống, VPN còn). Trên apk6 (V7 – ĐÃ SỬA, kiểm lại ĐẠT ở mục "V7/V8" cuối tệp) mở lại app thì giao diện lệch trạng thái: WireGuard → app báo "VPN đang tắt" trong khi `GoBackend$VpnService` + VPN 104 vẫn chạy (máy mất mạng mà app nói tắt; phải force-stop); WARP → app kẹt "Đang kết nối…" > 1,5 phút trong khi tunnel cũ vẫn bắt tay và đi WARP. Nguyên nhân: Activity/Flutter engine tạo lại → `YomiVpn`/`YomiTunnels` mới tạo `GoBackend` mới, không biết tunnel của instance cũ. Đề xuất 0.5.7: dùng chung một `GoBackend` + `Tunnel` cấp tiến trình (companion object) cho WARP và WireGuard và để Dart hỏi trạng thái khi khởi tạo; hoặc tắt tunnel khi task bị gỡ. | `v2_swipe0_recents`, `v2_swipe1_recents_warp`, `v2_swipe2_reopen`, `v2_swipe3_reopen_30s` |
| 8 | DNS riêng | ĐẠT phần kiểm được: công tắc DoH bật/tắt và lưu (checked=true, nhà cung cấp Cloudflare); DNS hệ thống (`dumpsys`: eth0/wlan0 10.0.2.3, `private_dns_mode` mặc định) không đổi – đúng thiết kế (DoH chỉ cho kết nối của YomiHub). DNS do đường hầm cấp: Tor 198.18.0.2, WARP 1.1.1.1, WireGuard 1.1.1.1, VPN Gate 10.236.254.254/8.8.8.8. KHÔNG KIỂM ĐƯỢC hiệu lực DoH trong app (không bắt được truy vấn 1.1.1.1:443 lúc thử). Đã trả DoH về tắt. | `v2_dns1_doh_on` |

Ghi chú: ảnh `v2_dbg_*`, `v2_dns1_doh` (chưa bật), `v2_v3_after_off`, `v2_vg2_state` là ảnh phụ/không tính. Bản sao để đối chiếu: `YomiVpn.kt.build_apk4.txt` (YomiVpn.kt trong build trước khi đồng bộ), `YomiVpn.kt.truoc_V4b.txt`. Tệp đã chép sang `D:\yh\build\mangayomi`: chỉ `android/.../YomiVpn.kt` (V4 + V4b). Không chạm điện thoại thật, không ghi `output/`. AVD đã tắt, AVD_LOCK/BUILD_LOCK để trống.

Còn mở sau đợt này: V5 (mạng chặn Tor – ngoài mã). V7, V8 đã sửa và kiểm ở mục dưới. Không chạy lại `flutter test`/`flutter analyze`: đợt này chỉ đổi Kotlin, bản release biên dịch thành công (BUILD_EXIT=0).


## V7/V8 – sửa và kiểm AVD 13/11/2026
Theo yêu cầu người dùng, sửa luôn trong 0.5.6.1.

**Mã (overlay, chỉ chép các tệp này sang `D:\yh\build\mangayomi`):**
- `android/.../YomiWg.kt` (MỚI): một `GoBackend` + hai `Tunnel` (`yomihub-warp`, `yomihub-wg`) dùng chung cả tiến trình; Activity mới chỉ trỏ lại listener về kênh của mình. `stats()` đọc `getStatistics` → `handshake` (latestHandshakeEpochMillis), `rx`.
- `YomiVpn.kt`, `YomiTunnels.kt`: bỏ `GoBackend` riêng theo Activity, dùng `YomiWg`; thêm phương thức `wgStatus`.
- `lib/yomihub/vpn/vpn_tunnels.dart`: hàm thuần `wgHealth`, `wgResume`, `warpResume`; WireGuard chỉ "Đã kết nối" sau khi có bắt tay (chờ tối đa 15 s, có gửi gói kích hoạt); không bắt tay → `wgDown`, trạng thái lỗi, thông báo "Không bắt tay được với máy chủ WireGuard "…" sau 15 giây – YomiHub đã gỡ đường hầm để máy không mất mạng…"; lưu `activeWireGuard` để mở lại app thì nhận lại đường hầm đang chạy (adopt) hoặc gỡ đường hầm mồ côi. Bỏ hai hồ sơ dựng sẵn "Cloudflare WARP/WARP+ • YomiHub" (khoá dùng chung cũ, Cloudflare không trả lời; mục Cloudflare WARP dùng tài khoản riêng vẫn chạy) – xoá một lần, ghi log.
- `lib/yomihub/vpn/vpn_service.dart`: lúc khởi động WARP theo `warpResume`: đang chạy → nhận lại (hết kẹt "Đang kết nối…"); công tắc bật mà tiến trình mới → kết nối lại; công tắc tắt mà đường hầm chạy → gỡ.
- Test mới `test/yh_0561_vpn_resume_test.dart` (12 test). Job `vpn057_apk7`: `flutter test` VPN 18/18 đạt (12 mới + 6 cũ), `flutter analyze lib/yomihub/vpn` + test: No issues found, dựng release BUILD_EXIT=0.
- Bản sao trước sửa: `audit-0.5.7/vpn/truoc_V7V8/`.

**APK cuối:** `audit-0.5.7/vpn/apk/YomiHub-0.5.6.1-vpn-x86_64.apk` 186 794 220 B, SHA-256 `7A86FFEBB984874CF6369121DBCF5C4BCF0059A28BCDA677835B8DC072C75A84` (bản trước, chỉ có V4b: `…-V4b.apk`). Cài `-r` lúc 06:26:11.

| Mục | Kết quả | Ảnh (`evidence/`) |
|---|---|---|
| Hồi quy Tor | ĐẠT: "Đã kết nối • HTTP 8118 • SOCKS 9050 • Toàn bộ thiết bị" sau 14 s, có VPN | `v3_reg1_tor` |
| Hồi quy Tor → WARP | ĐẠT: hộp thoại chuyển, WARP kết nối 7 s, VPN mới, IP Cloudflare 2a09:bac1:…; Tor về dormant (không listener) | `v3_reg2_warp` |
| Hồ sơ dựng sẵn | ĐẠT: WireGuard "0 hồ sơ", log "Đã bỏ hồ sơ WireGuard dựng sẵn…" | `v3_reg0_start` |
| V7 WARP | ĐẠT: vuốt app (tiến trình sống, VPN 104 còn) → mở lại: "Cloudflare WARP • Đã kết nối", cùng mạng 104, log "Mở lại YomiHub: WARP vẫn đang chạy – đã đồng bộ trạng thái" (2 lần, 06:29 và 06:52); bấm "Tắt" → NO-VPN, IP về 113.177.247.151 | `v3_v7warp0_recents`, `v3_v7warp1_reopen`, `v3_v7warp2_off` |
| V8 WireGuard hỏng | ĐẠT: hồ sơ endpoint 192.0.2.1 khoá ngẫu nhiên → thẻ "Đang kết nối…" (không còn "Đã kết nối"), sau 15 s gỡ đường hầm, NO-VPN, IP thật, log lỗi tiếng Việt như trên | `v3_v8_0_imported`, `v3_v8_1_waiting`, `v3_v8_2_result` |
| V8 WireGuard chạy được | ĐẠT: hồ sơ dựng từ tài khoản WARP của app (endpoint 162.159.192.5:500) → "Received handshake response" sau 0,4 s → "Đã kết nối", IP 104.28.219.203 (Cloudflare). Hai lần thử trước cùng khoá (cổng 2408 lúc 06:36, cổng 500 lúc 06:55) không bắt tay vì UDP của mạng thử chập chờn – app báo lỗi và gỡ đường hầm đúng thiết kế V8 | `v3_v7wg0_connected` |
| V7 WireGuard | ĐẠT: vuốt app khi WireGuard bật (tiến trình 4257 sống, VPN 102 còn) → mở lại: "VPN đang bật: WireGuard • 162.159.192.5:500 • Đã kết nối", log "Mở lại YomiHub: WireGuard … vẫn đang chạy – đã đồng bộ trạng thái"; bấm "Tắt" → NO-VPN, IP thật (không cần force-stop) | `v3_v7wg1_recents`, `v3_v7wg2_reopen`, `v3_v7wg3_off` |
| FATAL/ANR | Không có trong mọi lượt | – |

Ghi chú: (1) log lỗi V8 bị bộ phân loại gắn nhãn "[Lỗi Nguồn 403 / Cloudflare]" vì câu có chữ "Cloudflare" – chỉ là nhãn, chưa sửa. (2) Phần mất mạng thật sự khi chờ (≤15 s) vẫn xảy ra với hồ sơ hỏng ở phạm vi "Toàn bộ thiết bị". (3) OpenVPN/VPN Gate vẫn dùng `VPNHelper` theo Activity – chưa kiểm vuốt app với OpenVPN. (4) AVD thử còn 4 hồ sơ WireGuard thử (một hồ sơ chứa khoá tài khoản WARP của chính máy ảo); tệp cấu hình tạm trong `/data/local/tmp` đã xoá. Công cụ: `jobs/v3_mkwg.sh` (tạo cấu hình, không in khoá), `jobs/v3_type.sh`, `jobs/v2_lib.ps1`.
