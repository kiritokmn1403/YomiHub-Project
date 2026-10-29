. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 3; Shot 't02_s3'
Start-Sleep 1; Shot 't02_s4'
Start-Sleep 4
Tap 877 2169 3
Shot 't02_browse'
Labels 't02_browse' | Select-Object -First 50
TapText '^Film & Movie Setting' 3 | Out-Null
Shot 't02_film'
Labels 't02_film' | Select-Object -First 40
TapText '^YouTube' 6 | Out-Null
Shot 't02_yt'
Labels 't02_yt' | Select-Object -First 40
Crash | Select-Object -Last 15
