# NOTES_I18 - Feature Check 30 (chuoi chua dich) - 14/11/2026 (Asia/Saigon), I18 (Sonnet)

## Yeu cau
Ra soat chuoi tieng Viet hien thi chua qua `tr()` trong: builtin_extensions, wifi_settings_screen, health_connect_screen, microg_screen, win_diag(+screen), ilovepdf, vpn_screen (UI), share_screen; boc `tr()`, dich 18 ngon ngu, kiem trung nguyen van.

## Cach quet
Script heuristic (dong co dau tieng Viet, khong co `tr(`) + doi chieu moi literal voi khoa trong en.json (1615 khoa luc dau).

## Da boc tr() (tep -> so chuoi)
- health/health_connect_screen.dart: 9 (DropdownMenuItem "N phut" -> tr('{p0} phút'), bo `const` o 2 danh sach items). Khoa da co san.
- microg/microg_screen.dart: 1 (" • đang tắt" -> tr('đang tắt')).
- vpn/vpn_screen.dart: 1 ('Không rõ' trong hop thoai quoc gia).
- wifi/wifi_settings_screen.dart: 6 (ten mang mau "Wi-Fi Gia Đình" - bo const; 4 dong bao cao TXT xuat/sao chep: Thoi gian/Tong so mang/Bao mat/Mat khau). Them SUA LOI: so sanh `pass.contains('Không có mật khẩu')` o danh gia an toan khong khop khi doi ngon ngu (chuoi duoc tr thanh '(Không có mật khẩu hoặc mở)') -> them `pass == tr('(Không có mật khẩu hoặc mở)')`.
- win/win_diag.dart: 8 thong bao van de (thieu DLL/xray/tor/bridge/libmpv/WebView2/Java) + chuoi tom tat may (6 mau: luong, thu muc, co/khong/khong co). Them import yomi_tr.dart. Luu y: van de/tom tat dich theo ngon ngu luc chay chan doan; doi ngon ngu can bam "Kiem tra lai".
- Chi can them ban dich (ma nguon da goi tr/trNotes): 13 ghi chu tien ich o builtin_extensions.dart (hien qua trNotes o manga_home_screen).
- ilovepdf.dart, share_screen.dart: khong can sua ma (nhan cong cu da qua tr(t.label), khoa da co; share chi con chuoi log).

## Co y bo qua
- builtin_extensions.dart: `name:` 'VTVgo – Truyền hình', 'Dâm Cô Nương (18+)', 'Xôi Lạc TV' (ten rieng/thuong hieu tien ich); log 438-445 ('[Tiện ích] ...').
- wifi_settings_screen.dart: 81/104-108 (khop ket qua `netsh` tieng Viet - du lieu he thong, khong phai UI); 189-210 AppLogger.
- win_diag.dart: AppLogger (111,119,124,128).
- share_screen.dart: toan bo YomiShareLog (nhat ky), vpn_screen.dart: yomiLogVpnError (nhat ky).
- vpn_tunnels.dart, vpn_service.dart, lan_share.dart, playbooks_settings_screen.dart: ngoai pham vi giao (F1/PB/P5), chua quet.

## i18n
- notes/i18n_I18.json: 30 khoa moi x 18 ngon ngu (13 ghi chu + 17 chuoi UI/chan doan). Generator: audit-0.5.7/tools/i18n_I18_gen_a.py. Gop bang `i18n_merge.py I18`: moi tep 1615 -> 1645 khoa (kiem placeholder dat).
- Kiem trung nguyen van tieng Viet (key == value): toan 18 tep chi con ten rieng/ky hieu ("{p0}×", "NetSetMan", "{p0} Booru", "Health Connect", "Play Books", "Shader", "Comic • APK Mihon", "Film & Movie • APK Aniyomi", "Tiếng Việt" o ar/id = ten ngon ngu) -> hop le.
- Sua 1 muc chua dich that: id.json "Güncel-\nlemeler" (con tieng Tho Nhi Ky) -> "Pem-\nbaruan". Sao luu: audit-0.5.7/backup/src_0571/assets/yomihub_i18n_I18/id.json.
- Cac muc ar/es/es_419/id/tr con ky tu Viet chi la ten rieng "Cốc Cốc" -> hop le.

## Kiem thu
Job `jobs/pending_fast/i18_fc30.ps1` (analyze health/microg/win/wifi/vpn + test yh_049, yh_052). Ket qua: xem muc duoi.

## Con lai
- vpn_tunnels.dart/vpn_service.dart/lan_share.dart/playbooks_settings_screen.dart: can ra soat bang cung phuong phap (thuoc F1/P5/PB).

## Ket qua kiem thu (chay that, 14/11/2026)
- Job i18_fc30: analyze health: No issues; microg: No issues; vpn: No issues; wifi: 9 info co san (deprecated Radio groupValue/onChanged, DropdownButtonFormField value; khong phai do I18); win: 1 info prefer_interpolation (do I18) -> da sua.
- Job i18_fc30b: analyze win: No issues found! (EXIT 0).
- flutter test yh_049 + yh_052: "+27: All tests passed!" (TEST EXIT 0), gom 'every tr() text has an English translation'.
- Chua lam: thu tren thiet bi (doi ngon ngu -> man Chan doan Windows/Wi-Fi/Health).
