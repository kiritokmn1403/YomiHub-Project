. 'D:\Claude A.I\dev\x019\t\c.ps1'
if (-not (EnsureEmulator)) { return }
"install: " + ((Adb install -r 'D:\Claude A.I\output\YomiHub-0.1.9-x86_64.apk') -join ' ')
(Adb shell dumpsys package com.yomihub.app) | Select-String 'versionName|minSdk' | Select-Object -First 3 | ForEach-Object { "$_".Trim() }
Adb logcat -c | Out-Null
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 20
TapText '^More' 3 | Out-Null
Labels 't32_more' | Select-Object -First 25
Crash
