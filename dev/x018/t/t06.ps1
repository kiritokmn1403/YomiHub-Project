. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb shell am force-stop $PKG
Adb logcat -c
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 14
Tap 1012 2136 3
Labels 't05_more' | Select-Object -First 25
TapText '^(Cài đặt|Settings)' 3 | Out-Null
Labels 't05_settings' | Select-Object -First 25
TapText '^(Giao diện|Appearance)' 3 | Out-Null
for ($i=0; $i -lt 4; $i++) { if (Find-Node '(Ngôn ngữ ứng dụng|App language)') { break }; Adb shell input swipe 540 1700 540 900 400; Start-Sleep 2 }
TapText '(Ngôn ngữ ứng dụng|App language)' 3 | Out-Null
Shot 't05_langdlg'
for ($i=0; $i -lt 6; $i++) { if (Find-Node '^English') { break }; Adb shell input swipe 540 1500 540 900 400; Start-Sleep 2 }
TapText '^English' 4 | Out-Null
Shot 't05_after'
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 14
Tap 878 2136 4
Shot 't05_browse_en'
Labels 't05_browse_en' | Select-Object -First 30
Tap 1012 2136 3
Shot 't05_more_en'
Labels 't05_more_en' | Select-Object -First 40
Crash | Select-String -NotMatch 'LocalLibraryScanner' | Select-Object -Last 20
