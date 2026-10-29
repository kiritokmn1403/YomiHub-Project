. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
$apk = Get-ChildItem 'D:\Claude A.I\dev\x018\YomiHub-0.1.8-dev-x86_64-release.apk'
"apk $($apk.LastWriteTime)"
Adb install -r $apk.FullName | Select-Object -Last 2
Adb logcat -c
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 10
TapText '^(Thêm|More)$' 3 | Out-Null
TapText '^(Cài đặt|Settings)$' 3 | Out-Null
TapText '^(Giao diện|Appearance)$' 3 | Out-Null
for ($i=0; $i -lt 4; $i++) { if (Find-Node '^(Ngôn ngữ ứng dụng|App language)') { break }; Adb shell input swipe 540 1700 540 900 400; Start-Sleep 2 }
TapText '^(Ngôn ngữ ứng dụng|App language)' 3 | Out-Null
Shot 't05_langdlg'
for ($i=0; $i -lt 6; $i++) { if (Find-Node '^English') { break }; Adb shell input swipe 540 1500 540 900 400; Start-Sleep 2 }
TapText '^English' 4 | Out-Null
Back 2; Back 2; Back 2
Shot 't05_more_en'
Labels 't05_more_en' | Select-Object -First 40
TapText '^Browse$' 4 | Out-Null
Shot 't05_browse_en'
Labels 't05_browse_en' | Select-Object -First 40
TapText '^More$' 3 | Out-Null
for ($i=0; $i -lt 3; $i++) { if (Find-Node '^VPN') { break }; Adb shell input swipe 540 1700 540 900 400; Start-Sleep 2 }
TapText '^VPN' 4 | Out-Null
Shot 't05_vpn_en'
Labels 't05_vpn_en' | Select-Object -First 50
Crash | Select-String -NotMatch 'LocalLibraryScanner' | Select-Object -Last 20
