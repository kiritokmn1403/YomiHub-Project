. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
function Seek($p) { for ($i=0; $i -lt 6; $i++) { if (Find-Node $p) { return $true }; Adb shell input swipe 540 1800 540 900 400 | Out-Null; Start-Sleep 2 }; return $false }
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 14
Tap 1012 2136 3
Seek '^(Cài đặt|Settings)' | Out-Null
TapText '^(Cài đặt|Settings)' 3 | Out-Null
Labels 't07_settings' | Select-Object -First 25
Seek '^(Giao diện|Appearance)' | Out-Null
TapText '^(Giao diện|Appearance)' 3 | Out-Null
Seek '(Ngôn ngữ ứng dụng|App language)' | Out-Null
TapText '(Ngôn ngữ ứng dụng|App language)' 3 | Out-Null
Shot 't07_langdlg'
Labels 't07_langdlg' | Select-Object -First 30
Seek '^English' | Out-Null
TapText '^English' 4 | Out-Null
Shot 't07_after'
Labels 't07_after' | Select-Object -First 20
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 14
Tap 878 2136 4
Shot 't07_browse_en'
Labels 't07_browse_en' | Select-Object -First 30
Tap 1012 2136 3
Shot 't07_more_en'
Labels 't07_more_en' | Select-Object -First 30
Seek '^VPN' | Out-Null
TapText '^VPN' 4 | Out-Null
Shot 't07_vpn_en'
Labels 't07_vpn_en' | Select-Object -First 40
Crash | Select-String -NotMatch 'LocalLibraryScanner' | Select-Object -Last 20
