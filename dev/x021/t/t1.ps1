. 'D:\Claude A.I\dev\x020\t\c.ps1'
$T = 'D:\Claude A.I\dev\x021\t'; New-Item -ItemType Directory -Force "$T\shots" | Out-Null
function Shot2($name) { & $ADB shell screencap -p /sdcard/yh_shot.png | Out-Null; & $ADB pull /sdcard/yh_shot.png "$T\shots\$name.png" 2>&1 | Out-Null; "shot $name" }
if (-not (EnsureEmulator)) { return }
"installed before: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String versionName) -join ' ')
& $ADB install -r 'D:\Claude A.I\dev\x021\YomiHub-0.2.1-dev-x86_64-release.apk' 2>&1 | Select-Object -Last 2
"installed now: " + ((& $ADB shell dumpsys package com.yomihub.app | Select-String versionName) -join ' ')
& $ADB logcat -c
& $ADB shell am force-stop com.yomihub.app
& $ADB shell monkey -p com.yomihub.app -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
Start-Sleep 3; Shot2 't1_splash1'
Start-Sleep 3; Shot2 't1_splash2'
Start-Sleep 20; Shot2 't1_home'
Crash
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'HiveError|FATAL|swallowed|AndroidRuntime' | Select-Object -Last 20 | ForEach-Object { "$_" }
