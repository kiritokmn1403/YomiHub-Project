. 'D:\Claude A.I\dev\x023\t\h.ps1'
if (-not (EnsureEmulator)) { return }
$apk = Get-ChildItem 'D:\Claude A.I\dev\x023\YomiHub-0.2.3-dev-*.apk' | Sort-Object LastWriteTime | Select-Object -Last 1
"install $($apk.Name)"
& $ADB install -r $apk.FullName 2>&1 | Select-Object -Last 1
"version: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode') -join ' ')
& $ADB logcat -c; & $ADB logcat -b crash -c; & $ADB logcat -b events -c
& $ADB shell am force-stop com.yomihub.app
Launch 25
"--- meminfo after launch ---"
& $ADB shell dumpsys meminfo com.yomihub.app | Select-String 'TOTAL PSS|TOTAL RSS|Native Heap|Dalvik Heap' | Select-Object -First 4 | ForEach-Object { "$_" }
& $ADB shell am send-trim-memory com.yomihub.app RUNNING_CRITICAL 2>&1
Start-Sleep 6
"--- meminfo after trim ---"
& $ADB shell dumpsys meminfo com.yomihub.app | Select-String 'TOTAL PSS|TOTAL RSS|Native Heap|Dalvik Heap' | Select-Object -First 4 | ForEach-Object { "$_" }
& $ADB pull /sdcard/YomiHub/logs.txt "$T\logs_app.txt" 2>&1 | Out-Null
Get-Content "$T\logs_app.txt" -Encoding UTF8 -Tail 8
CrashCheck
