. 'D:\Claude A.I\dev\x023\t\h.ps1'
if (-not (EnsureEmulator)) { return }
$apk = Get-ChildItem 'D:\Claude A.I\dev\x023\YomiHub-0.2.3-dev-*.apk' | Sort-Object LastWriteTime | Select-Object -Last 1
& $ADB install -r $apk.FullName 2>&1 | Select-Object -Last 1
& $ADB shell am force-stop com.yomihub.app
Launch 20
Tap 848 2169 4
Swipe 900 273 100 273 300
Tap 820 273 3
Tap 194 426 4
Tap 300 694 14
Tap 270 783 12
for ($i=0; $i -lt 3; $i++) { & $ADB shell input swipe 540 1900 540 300 150; Start-Sleep 1 }
Start-Sleep 2
Tap 300 1593 18
for ($i=0; $i -lt 4; $i++) { & $ADB shell input swipe 540 1800 540 600 300; Start-Sleep 1 }
Start-Sleep 1
Shot2 't15_b_moved'
Start-Sleep 5
& $ADB shell am force-stop com.yomihub.app
Start-Sleep 2
Launch 20
Tap 694 2169 5
Tap 899 270 3
Tap 600 560 18
Shot2 't15_c_reopen'
