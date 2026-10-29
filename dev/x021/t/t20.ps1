. 'D:\Claude A.I\dev\x021\t\h.ps1'
Swipe 1000 273 150 273
TapText "^Novel Extension Settings" 4
TapText '^Source$' 3
L2 'nv' | Select-Object -First 30 | Select-String -NotMatch 'Tab [0-9] of 7'
