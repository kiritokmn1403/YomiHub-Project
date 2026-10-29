. 'D:\Claude A.I\dev\x020\t\c.ps1'
TapText '^More$' 3 | Out-Null
TapText '^Settings$' 3 | Out-Null
Shot 't02_settings1'
Adb shell input swipe 540 1700 540 600 400; Start-Sleep 2
Shot 't02_settings2'
Labels 't02_set' | Select-Object -First 60
TapText 'AdBlock' 4 | Out-Null
Shot 't02_adblock'
Back
TapText 'AirDrop' 4 | Out-Null
Adb shell input swipe 540 1700 540 500 400; Start-Sleep 2
Shot 't02_airdrop'
Labels 't02_air' | Select-Object -First 40
Back
Crash
