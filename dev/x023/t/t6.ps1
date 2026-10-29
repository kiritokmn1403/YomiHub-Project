. 'D:\Claude A.I\dev\x023\t\h.ps1'
Tap 899 270 3
Tap 400 527 18
Shot2 't6_a_open'
for ($i=0; $i -lt 4; $i++) { & $ADB shell input swipe 540 600 540 1800 250; Start-Sleep 1 }
Start-Sleep 1
Tap 540 1100 2
Shot2 't6_b_moved'
Start-Sleep 5
& $ADB shell am force-stop com.yomihub.app
Start-Sleep 2
Launch 20
Tap 694 2169 5
Tap 899 270 3
Tap 400 527 18
Tap 540 1100 2
Shot2 't6_c_reopen'
CrashCheck
