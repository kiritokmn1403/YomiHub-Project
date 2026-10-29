. 'D:\Claude A.I\dev\x019\t\c.ps1'
TapText '^Add$' 2 | Out-Null
Tap 990 2060 2
Shot 't22_dl'
Start-Sleep 20
Adb shell ls -R /storage/emulated/0/YomiHub/downloads 2>&1 | Select-Object -Last 12
