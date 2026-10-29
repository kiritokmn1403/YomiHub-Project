. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 9
Tap 877 2169 3
TapText '^Film & Movie Setting' 3 | Out-Null
TapText '^Đề xuất' 20 | Out-Null
Shot 't03_suggest'
Labels 't03_suggest' | Select-Object -First 30
TapText '^Nguồn' 3 | Out-Null
for ($i=0; $i -lt 4; $i++) { if (Find-Node '^YouTube') { break }; Adb shell input swipe 540 1700 540 900 300; Start-Sleep 2 }
TapText '^YouTube' 10 | Out-Null
Shot 't03_yt'
Labels 't03_yt' | Select-Object -First 30
TapText '^Short' 25 | Out-Null
Shot 't03_short'
Labels 't03_short' | Select-Object -First 20
Crash | Select-String -NotMatch 'LocalLibraryScanner' | Select-Object -Last 25
