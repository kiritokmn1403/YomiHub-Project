. 'D:\Claude A.I\dev\x023\t\h.ps1'
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
Shot2 't16_reopen_same'
