# timeout: 25
. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb shell cmd connectivity airplane-mode disable
$apk = 'D:\Claude A.I\dev\x018\YomiHub-0.1.8-dev-x86_64-release.apk'
"install: " + ((Adb install -r -d $apk) -join ' ')
Adb shell am force-stop $PKG
Adb logcat -c
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep -Milliseconds 1500; Shot 't01_splash1'
Start-Sleep 2; Shot 't01_splash2'
Start-Sleep 4; Shot 't01_home'
Labels 't01_home' | Select-Object -First 40
Crash
