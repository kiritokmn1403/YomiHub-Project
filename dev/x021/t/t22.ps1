. 'D:\Claude A.I\dev\x021\t\h.ps1'
Tap 450 1614 15
Shot2 't22_chapter'
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'E/flutter|swallowed' | Select-Object -Last 5 | ForEach-Object { "$_" }
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
