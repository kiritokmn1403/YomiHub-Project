. 'D:\Claude A.I\dev\x022\t\h.ps1'
if (-not (EnsureEmulator)) { return }
$apk = Get-ChildItem 'D:\Claude A.I\dev\x022\YomiHub-0.2.2-dev-*.apk' | Sort-Object LastWriteTime | Select-Object -Last 1
"install $($apk.Name)"
& $ADB install -r $apk.FullName 2>&1 | Select-Object -Last 1
"version: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode') -join ' ')
& $ADB logcat -c; & $ADB logcat -b crash -c; & $ADB logcat -b events -c
Launch 20
L2 'home' | Select-Object -First 25
Shot2 't1_home'
CrashCheck
