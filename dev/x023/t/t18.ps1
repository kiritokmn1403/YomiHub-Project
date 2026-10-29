. 'D:\Claude A.I\dev\x023\t\h.ps1'
if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\output\YomiHub-0.2.3-x86_64.apk' 2>&1 | Select-Object -Last 1
"version: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode') -join ' ')
& $ADB logcat -b events -c; & $ADB logcat -b crash -c
& $ADB shell am force-stop com.yomihub.app
Launch 20
& $ADB shell monkey -p com.yomihub.app --pct-syskeys 0 --pct-appswitch 2 --throttle 120 -s 5151 3000 2>&1 | Select-Object -Last 2
& $ADB shell cmd connectivity airplane-mode disable
Start-Sleep 3
CrashCheck
