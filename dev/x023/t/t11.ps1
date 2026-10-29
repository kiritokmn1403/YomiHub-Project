. 'D:\Claude A.I\dev\x023\t\h.ps1'
Tap 300 1593 18
for ($i=0; $i -lt 5; $i++) { & $ADB shell input swipe 540 1800 540 600 300; Start-Sleep 1 }
Start-Sleep 1
Tap 540 1100 2
Shot2 't11_b_moved'
Tap 540 1100 1
Start-Sleep 5
& $ADB shell am force-stop com.yomihub.app
Start-Sleep 2
Launch 20
Tap 848 2169 4
Swipe 900 273 100 273 300
Tap 820 273 3
Tap 194 426 4
Tap 300 694 14
Tap 270 783 14
Tap 870 2160 20
Tap 540 1100 2
Shot2 't11_c_reopen'
