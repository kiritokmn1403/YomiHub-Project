. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB logcat -c
Launch 8
Tap 848 2169 5
TapText '^Extensions$' 5
for ($i=0; $i -lt 4; $i++) { $n = Find-Node '^Manga Million$'; if ($n) { break }; Swipe 540 1800 540 900 }
"node: $($n.x),$($n.y)"
if ($n) { Tap $n.x $n.y 25 }
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'swallowed|FATAL|HttpException|System.err' | Select-Object -Last 15 | ForEach-Object { "$_" }
& $ADB logcat -d -b events 2>&1 | Select-String 'am_crash' | Select-Object -Last 5 | ForEach-Object { "$_" }
L2 'ins' | Select-String 'Manga Million' -Context 0,3
