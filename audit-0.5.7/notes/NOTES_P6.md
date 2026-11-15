# NOTES_P6 - U11 Giao dien Moi (Shiori), tac nhan P6 (Sonnet), 14/11/2026 (Asia/Saigon)

## Yeu cau
U11: dua bo giao dien Shiori vao ung dung khi uiStyle = Moi (Cu giu nguyen 100%):
1. O bia luoi thu vien/duyet dung ShioriCard/ShioriBadge (giu cham/giu, chon nhieu, huy hieu, chip Hop nhat).
2. An o cai dat "gop thu vien" (mergeLibraryNavMobile) khi Moi.
3. ShioriTransitions cho chuyen trang router khi Moi (neu con suc).
Khong dung: player/anime, cloudflare, vpn, m_client, merge, health, browser, ext_errors, isolate_service, Android TV.

## Hien trang tim thay
(dang khao sat)

## Tep sua
(chua)

## Lenh/job
(chua)

## Ket qua test
(chua)

## Viec con lai
(chua)

## Cap nhat 16:20 - da sua (chua chay)
- cover_view_widget.dart: o cua luoi (thu vien/duyet/lich su) khi Moi && !isTv: ban kinh ShioriShape.cover + bong Shiori; lang nghe YomiPrefs.changes.
- library_entry_utils.dart: LibraryBadgeWidget (Hop nhat/Local/da tai/chua doc) va EntryBadgeChip -> ShioriBadge khi Moi.
- library_gridview_widget.dart: badge ngon ngu bo nen cardColor khi Moi.
- ui_style.dart: them YomiUi.debugOverride (cho test).
- custom_navigation_settings.dart: an o "gop thu vien" khi Moi.
- router.dart: pageBuilder ShioriPageTransition cho Android/Windows khi Moi (chon luc dung router, doi giao dien can khoi dong lai); Cu giu nguyen.
- Khong them chuoi tr() moi (khong can i18n_P6.json). Test: test/yh_057_p6_test.dart; job jobs/pending_fast/p6_a.ps1. Tool: tools/p6_patch.py, p6_patch2.py.

## Ket qua that (16:14)
- p6_a: analyze 17 van de, 0 error; toan bo la warning co san o tep khac (unnecessary_non_null_assertion...) + 1 info unnecessary_import trong ui_style.dart do toi them -> da go import, p6_b: `flutter analyze lib/yomihub/ui` = "No issues found!". Tep sua khac khong co canh bao.
- p6_a test: yh_057_p6_test 7/7 "All tests passed!".
- p6_b: yh_057_p6 + yh_049 + yh_056_c2_ui + yh_056_r22_hub_phone: "+49: All tests passed!" (TEST EXIT 0).
## Viec con lai
- Chua kiem tren thiet bi/anh chup that Cu/Moi (Android, Windows). Lop phu cua ShioriCoverCard/ShioriCard/ShioriHeader/Theme chua dung (dung token+ShioriBadge tren CoverViewWidget thay vi thay nguyen widget de giu hanh vi chạm/giu/TV).
- Chuyen trang Shiori chi co hieu luc khi khoi dong lai ung dung sau khi doi giao dien.
- Badge nguon (goc duoi trai) o luoi chua doi sang Shiori; luoi duyet (MangaImageCardWidget) huong loi ke thua CoverViewWidget.
