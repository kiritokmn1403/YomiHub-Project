. 'D:\Claude A.I\dev\x020\t\c.ps1'
if (-not (EnsureEmulator)) { return }
$apk = Get-ChildItem 'D:\Claude A.I\dev\x020\YomiHub-0.2.0-dev-*x86_64*.apk' | Sort-Object LastWriteTime | Select-Object -Last 1
"install $($apk.Name): " + ((Adb install -r $apk.FullName) -join ' ')
(Adb shell dumpsys package com.yomihub.app) | Select-String 'versionName|minSdk' | Select-Object -First 3 | ForEach-Object { "$_".Trim() }
Adb logcat -c | Out-Null
Adb shell am force-stop $PKG | Out-Null
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 2; Shot 't01_splash1'
Start-Sleep 2; Shot 't01_splash2'
Start-Sleep 14
Shot 't01_home'
Labels 't01_home' | Select-Object -First 30
Crash
