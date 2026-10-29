. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB shell am force-stop com.yomihub.app
& $ADB logcat -c; & $ADB logcat -b crash -c
Launch 10
$out = & $ADB shell monkey -p com.yomihub.app --throttle 200 --pct-syskeys 0 --pct-appswitch 2 -s 2110 1200 2>&1
$out | Select-Object -Last 4 | ForEach-Object { "$_" }
& $ADB shell cmd connectivity airplane-mode disable
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
& $ADB logcat -d -b crash 2>&1 | Select-Object -First 20 | ForEach-Object { "$_" }
& $ADB logcat -d -b events 2>&1 | Select-String 'am_crash|am_anr' | Select-Object -Last 5 | ForEach-Object { "$_" }
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'swallowed|E/flutter' | Select-Object -Last 8 | ForEach-Object { "$_" }
