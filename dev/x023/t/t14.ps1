. 'D:\Claude A.I\dev\x023\t\h.ps1'
if (-not (EnsureEmulator)) { return }
$apk = Get-ChildItem 'D:\Claude A.I\dev\x023\YomiHub-0.2.3-dev-*.apk' | Sort-Object LastWriteTime | Select-Object -Last 1
& $ADB install -r $apk.FullName 2>&1 | Select-Object -Last 1
& $ADB shell am force-stop com.yomihub.app
Launch 20
Tap 694 2169 5
Tap 899 270 3
Tap 600 560 18
Tap 540 1100 2
Shot2 't14_a_hist_open'
Tap 540 1100 1
for ($i=0; $i -lt 3; $i++) { & $ADB shell input swipe 540 1800 540 600 300; Start-Sleep 1 }
Start-Sleep 1
Tap 540 1100 2
Shot2 't14_b_moved'
Tap 540 1100 1
Start-Sleep 5
& $ADB shell am force-stop com.yomihub.app
Start-Sleep 2
Launch 20
Tap 694 2169 5
Tap 899 270 3
Tap 600 560 18
Tap 540 1100 2
Shot2 't14_c_reopen'
CrashCheck
