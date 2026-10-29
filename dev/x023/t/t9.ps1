. 'D:\Claude A.I\dev\x023\t\h.ps1'
function OpenCh {
  Tap 848 2169 4
  Swipe 900 273 100 273 300
  Tap 820 273 3
  Tap 194 426 4
  Tap 300 694 14
  Tap 270 783 12
  Tap 405 1957 18
}
& $ADB shell am force-stop com.yomihub.app
Launch 20
OpenCh
for ($i=0; $i -lt 4; $i++) { & $ADB shell input swipe 540 600 540 1800 250; Start-Sleep 1 }
Start-Sleep 1
Tap 540 1100 2
Shot2 't9_b_moved'
Start-Sleep 5
& $ADB shell am force-stop com.yomihub.app
Start-Sleep 2
Launch 20
OpenCh
Tap 540 1100 2
Shot2 't9_c_reopen'
