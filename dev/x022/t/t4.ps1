. 'D:\Claude A.I\dev\x022\t\h.ps1'
Tap 665 268 1
Shot2 't4_filter_open'
Start-Sleep 20
Shot2 't4_filter_loaded'
L2 'flt' | Select-Object -First 30
Back 2
Tap 639 136 5
Shot2 't4_offline'
L2 'off' | Select-Object -First 15
Back 2
CrashCheck
