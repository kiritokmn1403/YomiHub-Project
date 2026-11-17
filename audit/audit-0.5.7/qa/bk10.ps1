$EV="$QA\evidence\backup"
Tap 1314 196; Start-Sleep 1
A shell input text pc | Out-Null; Start-Sleep 1
A shell input keyevent 66 | Out-Null; Start-Sleep 4
Ui b10_search | Out-Null
if (TapText 'pc_' ) { Start-Sleep 14 }
Shot b10_mode
Ui b10_mode | Out-Null
