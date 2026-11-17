A shell cmd statusbar collapse | Out-Null
A shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode|lastUpdateTime' | ForEach-Object { Log $_.Line.Trim() }
GoHome
Shot 'a1_home'
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Shot 'a1_hist'; $null=Ui 'a1_hist'
Get-Content "$EV\ui_a1_hist.txt" -Encoding UTF8
