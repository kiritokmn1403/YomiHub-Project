. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 9
Tap 877 2169 3
TapText '^Film & Movie Setting' 3 | Out-Null
for ($i=0; $i -lt 4; $i++) { if (Find-Node '^YouTube') { break }; Adb shell input swipe 540 1700 540 1100 400; Start-Sleep 3 }
Start-Sleep 2
TapText '^YouTube' 4 | Out-Null
TapText '^YouTube' 10 | Out-Null
Shot 't04_yt'
Labels 't04_yt' | Select-Object -First 30
TapText '^Short' 30 | Out-Null
Shot 't04_short'
Labels 't04_short' | Select-Object -First 20
Start-Sleep 10; Shot 't04_short2'
Adb shell input swipe 540 1600 540 500 250
Start-Sleep 12; Shot 't04_short3'
Crash | Select-String -NotMatch 'LocalLibraryScanner' | Select-Object -Last 25
