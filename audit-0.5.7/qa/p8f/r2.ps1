GoHome
TapText 'Duy.t Tab 4' | Out-Null; Start-Sleep 4
if(-not (TapText 'MangaDex')){ Tap 400 875 }; Start-Sleep 8
Tap 1020 181; Start-Sleep 2; A shell input text 'Shirley'; Start-Sleep 1; Key 66; Start-Sleep 9; Shot 'r2_search'
Tap 360 1000; Start-Sleep 10; Shot 'r2_detail'; $null=Ui 'r2_detail'
A logcat -c | Out-Null
if(-not (TapText 'Ch\.11')){ Tap 600 2140 }
Start-Sleep 20; Shot 'r2_t20'
Start-Sleep 40; Shot 'r2_t60'; $null=Ui 'r2_t60'
A logcat -d > "$EV\r2_logcat_full.txt"
A logcat -d -s flutter:I > "$EV\r2_logcat_flutter.txt"
Get-Content "$EV\ui_r2_detail.txt" -Encoding UTF8 | Select-Object -First 12
Get-Content "$EV\ui_r2_t60.txt" -Encoding UTF8
(Get-Content "$EV\r2_logcat_flutter.txt").Count
