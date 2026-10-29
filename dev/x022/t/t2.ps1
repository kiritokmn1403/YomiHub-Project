. 'D:\Claude A.I\dev\x022\t\h.ps1'
Tap 540 1812 4
for ($i=0; $i -lt 8; $i++) { if (Find-Node '^SpeedTest') { break }; Swipe 540 1700 540 900 }
TapText '^SpeedTest' 4
L2 'st0' | Select-Object -First 30
TapText '^(Start test|Bắt đầu đo)' 2
Start-Sleep 12
Shot2 't2_speed_mid'
Start-Sleep 30
Shot2 't2_speed'
L2 'st1' | Select-Object -First 40
CrashCheck
