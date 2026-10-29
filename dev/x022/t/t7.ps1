. 'D:\Claude A.I\dev\x022\t\h.ps1'
if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\output\YomiHub-0.2.2-x86_64.apk' 2>&1 | Select-Object -Last 1
"version: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode') -join ' ')
& $ADB logcat -b events -c; & $ADB logcat -b crash -c
Launch 25
L2 'rel' | Select-Object -First 6
& $ADB shell monkey -p com.yomihub.app --pct-syskeys 0 --pct-appswitch 2 --throttle 120 -s 9090 2000 2>&1 | Select-Object -Last 2
& $ADB shell cmd connectivity airplane-mode disable
Start-Sleep 3
CrashCheck
& $ADB pull /sdcard/YomiHub/logs.txt "$T\logs_rel.txt" 2>&1 | Out-Null
Get-Content "$T\logs_rel.txt" -Encoding UTF8 | Select-String '^\[08/10/2026 1[4-9].*\]\[ERROR\]' | Select-Object -Last 10 | ForEach-Object { "$_".Substring(0, [Math]::Min(220, "$_".Length)) }
