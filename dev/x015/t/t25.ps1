if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\output\YomiHub-0.1.5-x86_64.apk' 2>&1 | Select-Object -Last 1
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
Tap 713 1900 1
Tap 857 1705 9
Shot 't25_exp'
Tap 1000 500 1
L 10
$l = & $ADB logcat -d -s flutter; $l | Select-String "YomiMini" | Select-Object -Last 4
