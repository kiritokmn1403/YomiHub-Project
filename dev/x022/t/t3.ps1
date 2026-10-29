. 'D:\Claude A.I\dev\x022\t\h.ps1'
& $ADB shell am force-stop com.yomihub.app
Launch 18
Tap 848 2169 4
TapText '^Source' 4
L2 'src' | Select-Object -First 40
$n = Find-Node '^Manga Million'
if ($n) { Tap 300 $n.y 15 } else { "no MM" }
L2 'mm' | Select-Object -First 25
Shot2 't3_src'
