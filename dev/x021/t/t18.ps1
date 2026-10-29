. 'D:\Claude A.I\dev\x021\t\h.ps1'
Back 3
TapText '^Source$' 3
for ($i=0; $i -lt 4; $i++) { $n = Find-Node '^Toonily\nEnglish'; if ($n) { break }; Swipe 540 1800 540 1100 }
"node $($n.x),$($n.y)"
if ($n) { Tap 300 $n.y 15 }
L2 'toon' | Select-Object -First 10
TapText '^Filter$' 12
Shot2 't18_filter'
L2 'flt' | Select-Object -First 40
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'Filters of|swallowed' | Select-Object -Last 5 | ForEach-Object { "$_" }
