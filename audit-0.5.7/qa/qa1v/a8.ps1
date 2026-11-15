GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4
Tap 360 1000; Start-Sleep 6; Shot 'a8_detail'; $null=Ui 'a8_detail'
A logcat -c | Out-Null
Tap 720 1000; Start-Sleep 12; Shot 'a8_r_t12'; $null=Ui 'a8_r_t12'
Get-Content "$EV\ui_a8_detail.txt" -Encoding UTF8 | Select-Object -First 12
