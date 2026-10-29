Reset
Tap 1012 2170 3
& $ADB shell input swipe 540 1800 540 500 300; Start-Sleep 2
TapText "^Cài đặt$" 3
& $ADB shell input swipe 540 1800 540 400 300; Start-Sleep 2
TapText "Hình trong hình" 3
TapText "Luôn dùng cửa sổ nổi" 2
Back 2; Back 2; Back 2
Tap 877 2170 3
Tap 656 270 3
& $ADB shell input swipe 540 1900 540 300 300; Start-Sleep 1
& $ADB shell input swipe 540 1900 540 300 300; Start-Sleep 2
TapText "Nguồn cục bộ" 5
Tap 270 800 5
Tap 540 1505 7
Tap 1000 500 1
TapText "^Hình trong hình$" 4
Shot 't15_mini'
L 30
Crash
