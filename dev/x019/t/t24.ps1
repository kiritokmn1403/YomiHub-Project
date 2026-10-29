. 'D:\Claude A.I\dev\x019\t\c.ps1'
Tap 270 800 12
Shot 't24_det'
Tap 965 2160 30
Shot 't24_play'
Adb shell input keyevent 4
Start-Sleep 5
Shot 't24_afterback'
(Adb shell dumpsys activity activities) | Select-String -Pattern 'windowingMode=pinned|mode=pinned|isInPictureInPictureMode=true|pinned' | Select-Object -First 5 | ForEach-Object { "$_" }
