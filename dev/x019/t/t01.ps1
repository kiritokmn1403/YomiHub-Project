. 'D:\Claude A.I\dev\x019\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb logcat -c | Out-Null
"install: " + ((Adb install -r 'D:\Claude A.I\dev\x019\YomiHub-0.1.9-dev-x86_64-release.apk') -join ' ')
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 2; Shot 't01_splash1'
Start-Sleep 1; Shot 't01_splash2'
Start-Sleep 12
Shot 't01_home'
Labels 't01_home' | Select-Object -First 30
Crash
