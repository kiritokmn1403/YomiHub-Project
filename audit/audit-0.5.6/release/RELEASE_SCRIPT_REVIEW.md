# Nhan xet release_056.ps1 (doi chieu release_055.ps1)

Ban goc giu nguyen; ban sua: `release_056_fixed.ps1`. Chua chay gi len GitHub.

## Loi / thieu sot trong release_056.ps1
1. Thieu buoc kiem cuoi (055 co: liet ke asset, so size, HEAD download, releases/latest). 056 chi in "upload complete" -> khong phat hien tai thieu/sai size.
2. Ma HTTP cua curl chi in ra, khong kiem (201); upload loi van "thanh cong".
3. `catch` nuot moi loi (401, mang, 403) nhu "Release chua co" -> co the tao Release trung/loi mo ho. Sua: chi tao khi 404.
4. Body Release: neu thieu changelog, roi ve chuoi "YomiHub 0.5.6 (0.5.6+48) Release" (am tham). Sua: bat buoc co `output\0.5.6\YomiHub-0.5.6-changelog.md`, chan neu con `<<...>>` (hien con 2 cho giu trong changelog nguon).
5. Changelog nguon trong audit-0.5.6/release khac ban trong output/0.5.6 (byte 30) -> buoc (a) cua publish ghi de, bien `<<NGAY PHAT HANH>>`/`<<QA2>>` phai dien truoc.
6. Duong dan: dung `$PSScriptRoot\output\0.5.6` dung; tag `v0.5.6` dung; target_commitish `main` chi dung khi tag/commit da push (publish.ps1 push truoc).
7. Tep da co: bo qua neu cung size & state uploaded, tru .md/.txt (luon tai lai - hop ly vi SHA256SUMS/changelog doi). Khac size -> xoa roi tai lai: dung.
8. `--data-binary @file` nap ca tep (~260 MB) vao RAM; chap nhan duoc (055 dung cung cach), co the doi `-T`.
9. Tai them `TECHNICAL_UPDATE_NOTES.md` len Release (nhu 055): giu.

## Commit (tuong minh, khong add -A)
Them: overlay/ (47 sua + moi: integrations/, ui/shiori/, ui_style.dart, library_hub*, side_swipe, rejected_seek, clearance_cookie, test yh_056_*), README.md, TECHNICAL_UPDATE_NOTES.md, .gitignore, make_appxbundle.ps1, build_056*.ps1, sync_056.ps1, release_056*.ps1, release_056_publish.ps1, audit-0.5.6/{YomiHub-0.5.6-changelog.md, changed_files.txt, overlay_manifest_056.txt, release/*.md (3 tep ban thao + review), notes/, coordination/}. (0.5.5 chi dua 3 tep audit len.)
Loai: output/ (~1,9 GB), src/mangayomi-0.9.95/ (403 MB, CHUA co trong .gitignore!), jobs/, audit-0.5.6/{evidence 276 MB, backup 89 MB, inputs 9,6 MB, jobsrc, review, status}, apk/zip/exe/appxbundle/mp4/png, keystore-password.txt, *.jks.
## .gitignore: de xuat them (chua sua)
```
# -- 0.5.6 (11/11/2026)
/src/mangayomi-0.9.95/
/src/mangayomi-0.9.95b/
/audit-0.5.6/evidence/
/audit-0.5.6/backup/
/audit-0.5.6/inputs/
/audit-0.5.6/jobsrc/
/audit-0.5.6/review/
/audit-0.5.6/status/
/audit-0.5.6/qa/
/audit-0.5.6/*.ps1
```
(Cac quy tac *.apk, *.zip, *.exe, *.mp4, *.jks, keystore-password.txt, /output/, /jobs/ da co.)
Luu y: `git diff` canh bao CRLF->LF tren vai tep overlay (khong loi).

## Chuoi nhay cam
Tim cac mau token GitHub/Telegram va hai chuoi nhan dang rieng trong overlay (tep sua/moi), audit-0.5.6/{notes,coordination,release,review}, README, TECHNICAL_UPDATE_NOTES: khong co. `password\s*=` chi khop o mot so tep da duoc git theo doi tu truoc (l10n sinh tu dong, js_polyfills.dart), khong phai khoa that.

## Dieu kien truoc -Execute
Truyen `-Qa2 "<ket qua>" -ReleaseDate dd/MM/yyyy`; sua ban thao "CHUA phat hanh" trong TECHNICAL_NOTES/README section (script chan neu con). 
