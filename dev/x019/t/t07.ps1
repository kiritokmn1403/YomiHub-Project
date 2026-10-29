. 'D:\Claude A.I\dev\x019\t\c.ps1'
function Seek($p) { for ($i=0; $i -lt 25; $i++) { if (Find-Node $p) { return $true }; Adb shell input swipe 540 1800 540 700 300 | Out-Null; Start-Sleep 1 }; return $false }
Back 2
TapText '^Extensions$' 4 | Out-Null
if (Seek '^RoyalRoad$') { TapText '^RoyalRoad$' 25 | Out-Null } else { "royalroad not found" }
Adb shell input swipe 540 700 540 1900 200 | Out-Null
Adb shell input swipe 540 700 540 1900 200 | Out-Null
TapText '^Source$' 3 | Out-Null
TapText '^RoyalRoad' 25 | Out-Null
Shot 't07_rr'
Labels 't07_rr' | Select-Object -First 30
