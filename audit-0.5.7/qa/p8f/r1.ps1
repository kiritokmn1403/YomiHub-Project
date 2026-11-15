A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Shot 'r1_hist'; $ns=Ui 'r1_hist'
Get-Content "$EV\ui_r1_hist.txt" -Encoding UTF8
