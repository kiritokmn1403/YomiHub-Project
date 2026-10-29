. 'D:\Claude A.I\dev\x021\t\h.ps1'
TapText "^Browse\n" 4
TapText '^Source$' 4
L2 's' | Select-Object -First 30 | Select-String -NotMatch 'Tab '
