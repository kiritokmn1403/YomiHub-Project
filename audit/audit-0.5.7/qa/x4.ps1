GoHome
TapText '^Thư viện Tab 1' | Out-Null; Start-Sleep 2; Tap 577 158; Start-Sleep 3
if(-not (TapText 'Akujiki')){ Tap 1080 1000 }; Start-Sleep 5
Tap 500 2140; Start-Sleep 1; Shot '09_try_1s'; Start-Sleep 2; Shot '09_try_3s'
A logcat -d -s flutter:V *:E | Select-Object -Last 40 | ForEach-Object { Log $_ }
