. 'D:\Claude A.I\dev\x021\t\h.ps1'
if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\output\YomiHub-0.2.1-x86_64.apk' 2>&1 | Select-Object -Last 1
"version: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode') -join ' ')
& $ADB logcat -c; & $ADB logcat -b crash -c
Launch 18
TapText "^Browse\n" 4
TapText '^Source$' 4
$n = Find-Node '^Manga Million'
if ($n) { Tap 300 $n.y 20 }
L2 'mm' | Select-Object -First 9
Shot2 't30_final'
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
& $ADB logcat -d -b events 2>&1 | Select-String 'am_crash|am_anr' | Select-Object -Last 5 | ForEach-Object { "$_" }
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'HiveError|swallowed|E/flutter' | Select-Object -Last 6 | ForEach-Object { "$_" }
