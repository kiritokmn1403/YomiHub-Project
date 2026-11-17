$EV="$QA\evidence\backup"
A push "D:\yh\backup_test\yomihub_2026-11-15_19_33_59.270739.backup" /sdcard/Download/YomiHub_test/pc_win.backup | Select-Object -Last 1 | ForEach-Object { Log "PUSH $_" }
A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/YomiHub_test/pc_win.backup | Out-Null
Wake
Ui b9_now | Out-Null
if (-not (Find 'Kh.i ph.c b.n sao l.u')) { ToMore; for($i=0;$i -lt 4 -and -not (Find 'Sao L.u & ..ng B'); $i++){ Swipe 720 2200 720 900 400; Start-Sleep 1 }; TapText 'Sao L.u & ..ng B' | Out-Null; Start-Sleep 3 }
TapText 'Kh.i ph.c b.n sao l.u' | Out-Null; Start-Sleep 4
Shot b9_picker
Ui b9_picker | Out-Null
