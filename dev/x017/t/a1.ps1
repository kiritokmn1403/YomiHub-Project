# 0.1.7 A1: install x86_64 over 0.1.6, launch, crash check, push local-folder fixtures
if (-not (EnsureEmulator)) { return }
& $ADB shell settings put global animator_duration_scale 1
$apk = 'D:\Claude A.I\output\YomiHub-0.1.7-x86_64.apk'
"apk: $((Get-Item $apk).Length)"
& $ADB install -r $apk 2>&1 | Select-Object -Last 3
& $ADB shell dumpsys package com.yomihub.app | Select-String versionName
& $ADB shell am force-stop $PKG
& $ADB logcat -c
# fixtures
$fx = "$env:TEMP\fx017"; Remove-Item $fx -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $fx | Out-Null
& tar.exe -xzf 'D:\Claude A.I\dev\x017\fx017.tgz' -C $fx
& $ADB shell rm -rf /sdcard/LocalA /sdcard/LocalB
& $ADB push "$fx\LocalA" /sdcard/ 2>&1 | Select-Object -Last 1
& $ADB push "$fx\LocalB" /sdcard/ 2>&1 | Select-Object -Last 1
& $ADB shell appops set com.yomihub.app MANAGE_EXTERNAL_STORAGE allow
& $ADB shell find /sdcard/LocalA /sdcard/LocalB
& $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
Start-Sleep 12; Shot 'x17_a1_home'
L 30
Crash
