$EV="$QA\evidence\backup"
TapText '^H.y$' | Out-Null; Start-Sleep 3
Ui b11_after_cancel | Out-Null
TapText 'Kh.i ph.c b.n sao l.u' | Out-Null; Start-Sleep 4
Tap 1160 196; Start-Sleep 2
A shell input text pc | Out-Null; Start-Sleep 1
A shell input keyevent 66 | Out-Null; Start-Sleep 4
Ui b11_search | Out-Null
if (TapText 'pc_.in\.backup') { Start-Sleep 14 }
Shot b11_mode
Ui b11_mode | Out-Null
