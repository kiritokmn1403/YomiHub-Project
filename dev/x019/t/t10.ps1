. 'D:\Claude A.I\dev\x019\t\c.ps1'
Back 2; Back 2; Back 2
TapText '^Browse' 3 | Out-Null
Adb shell input swipe 100 273 900 273 300 | Out-Null
Start-Sleep 1
TapText 'Comic Setting' 3 | Out-Null
TapText '^Source$' 3 | Out-Null
TapText '^MangaDex \(Kotatsu\)' 15 | Out-Null
TapText '^Filter$' 5 | Out-Null
Shot 't10_kfilter'
Labels 't10_kfilter' | Select-Object -First 45
