. 'D:\Claude A.I\dev\x019\t\c.ps1'
if (-not (EnsureEmulator)) { return }
"install: " + ((Adb install -r 'D:\Claude A.I\dev\x019\YomiHub-0.1.9-dev-x86_64-release.apk') -join ' ')
Adb shell am force-stop $PKG
Adb logcat -c | Out-Null
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 16
TapText '^Browse' 3 | Out-Null
Adb shell input swipe 100 273 900 273 300 | Out-Null
Start-Sleep 1
TapText 'Comic Setting' 3 | Out-Null
TapText '^Source$' 3 | Out-Null
TapText '^MangaDex \(Kotatsu\)' 15 | Out-Null
Tap 800 800 15
Tap 500 1625 50
Shot 't18_tr'
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'YomiImageTranslate' | Select-Object -Last 8 | ForEach-Object { "$_" }
