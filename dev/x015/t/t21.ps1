Reset
Tap 877 2170 3
Tap 656 270 3
& $ADB shell input swipe 540 1900 540 300 300; Start-Sleep 1
& $ADB shell input swipe 540 1900 540 300 300; Start-Sleep 2
TapText "Nguồn cục bộ" 5
Tap 270 800 5
Tap 540 1505 7
Tap 1000 500 1
TapText "^Hình trong hình$" 4
Start-Sleep 2
Shot 't21_mini'
& $ADB shell input tap 712 1830; Start-Sleep -Milliseconds 120; & $ADB shell input tap 712 1830
Start-Sleep 7
Tap 1000 500 1
L 12
& $ADB logcat -d | Select-String "YomiMiniPlayer" | Select-Object -Last 5
