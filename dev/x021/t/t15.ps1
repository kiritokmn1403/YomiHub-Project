. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB logcat -c
Tap 540 1092 25
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
L2 'ti' | Select-Object -First 14 | Select-String -NotMatch 'Tab '
Back 2; Back 2
TapText '^Source$' 4
for ($i=0; $i -lt 4; $i++) { $n = Find-Node '^Toonily'; if ($n) { break }; Swipe 540 1800 540 900 }
"node $($n.label) $($n.x),$($n.y)"
