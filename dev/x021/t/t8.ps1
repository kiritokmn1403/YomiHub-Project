. 'D:\Claude A.I\dev\x021\t\h.ps1'
Tap 540 1806 15
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
Tap 540 1990 15
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
L2 'ext2' | Select-Object -First 30 | Select-String -NotMatch 'Tab '
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'swallowed|FATAL|DalvikHandler|HttpException' | Select-Object -Last 15 | ForEach-Object { "$_" }
& $ADB logcat -d -b crash 2>&1 | Select-Object -First 30 | ForEach-Object { "$_" }
& $ADB logcat -d -b events 2>&1 | Select-String 'am_crash' | Select-Object -Last 5 | ForEach-Object { "$_" }
