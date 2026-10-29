. 'D:\Claude A.I\dev\x021\t\h.ps1'
Swipe 540 1800 540 600
TapText '^About$' 4
Swipe 540 1800 540 600
L2 'about' | Select-Object -First 30
TapText 'GitHub projects used' 4
Shot2 't2_github'
L2 'gh' | Select-Object -First 30
