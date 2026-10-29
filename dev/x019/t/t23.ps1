. 'D:\Claude A.I\dev\x019\t\c.ps1'
Tap 70 136 3
Tap 800 800 12
Labels 't23_det' | Select-Object -First 6
Tap 965 2160 25
Shot 't23_play'
Adb shell input keyevent 4
Start-Sleep 4
Shot 't23_afterback'
(Adb shell dumpsys activity activities) | Select-String -Pattern 'pinned|PINNED|mode=pinned|windowingMode=pinned' | Select-Object -First 5 | ForEach-Object { "$_" }
