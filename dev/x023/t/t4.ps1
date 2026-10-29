. 'D:\Claude A.I\dev\x023\t\h.ps1'
Tap 405 1957 18
Shot2 't4_open'
for ($i=0; $i -lt 6; $i++) { & $ADB shell input swipe 540 1700 540 500 250; Start-Sleep 1 }
Start-Sleep 5
Shot2 't4_before_kill'
& $ADB shell am force-stop com.yomihub.app
Start-Sleep 2
Launch 20
Tap 848 2169 4
Tap 300 694 15
Tap 270 783 12
Tap 405 1957 18
Shot2 't4_after_reopen'
CrashCheck
