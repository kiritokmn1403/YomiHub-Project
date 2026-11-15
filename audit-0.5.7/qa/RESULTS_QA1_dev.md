# RESULTS QA1 dev build 0.5.7+50 (Note 9)
| Flow | Ket qua | Bang chung |
|---|---|---|
| 2 Thu vien hub + doi giao dien | DAT (da xem anh) | evidence/phone/qa1/02_tabs_montage.png (4 tab), 02_ui_new_montage.png, 02_ui_new_library.png (giao dien Moi), 02_ui_old_home.png (da khoi phuc Cu: nav Thu vien/Booru/Cap nhat/Duyet/Them) |

| 4 Reader + sheet cai dat x10 | CHUA DAT (bi chan, khong phai FAIL cua app) | Reader MO duoc tu MangaDex (VI) Shirley Madison Ch.11 (13 trang) va MangaDex(unlocked) (26 trang) nhung anh deu "Khong tai duoc anh nay" (04g_reader_menu.png, 04m_reader_menu.png). Cham giua (y=800/1000/1200, giu 90ms) KHONG goi menu -> khong mo duoc sheet cai dat, chua lam vong 10 lan, chua grep logcat. Nguon khac chet: Comick (RhttpException), CoManhua (DNS), WebtoonScan/FoxTruyen (loi/khong ket qua), Lich su 4 muc: 1 "khong co trang nao" (04d), 2 mo webview google.com (04e_item3). Hang doi tai xuong trong (04c_queue.png) nen khong co chuong tai san. Nghi van: lop loi anh nuot cham giua (can xac nhan khi co anh that). |
| 9 Resume video | CHUA DAT (bi chan) | Lich su > Phim mo muc "Tap 69 Thuong Nguyen Do": trinh phat chi quay spinner 15 s (09b_play_a.png) roi sau 50 s la man den ngang co nut Play, khong co thanh thoi gian, khong phat (09c_t50.png). Truoc do Akujiki (AnimeOnsen) cham tap khong mo player (09_play_t16s.png). Khong the xac nhan resume. |
