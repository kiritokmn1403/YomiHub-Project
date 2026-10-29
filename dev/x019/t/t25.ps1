. 'D:\Claude A.I\dev\x019\t\c.ps1'
Shot 't25_a'
Start-Sleep 15
Shot 't25_b'
Adb shell input keyevent 4
Start-Sleep 5
Shot 't25_c'
(Adb shell dumpsys activity activities) | Select-String -Pattern 'pinned' | Select-Object -First 5 | ForEach-Object { "$_" }
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'mpv|ffmpeg|E/flutter|Failed to|403' | Select-Object -Last 12 | ForEach-Object { "$_" }
