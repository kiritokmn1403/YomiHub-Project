. 'D:\Claude A.I\dev\x019\t\c.ps1'
Adb logcat -c | Out-Null
Tap 540 1000 1
Adb shell input swipe 900 1200 150 1200 200 | Out-Null
Start-Sleep 3
Adb shell input swipe 900 1200 150 1200 200 | Out-Null
Start-Sleep 35
Shot 't15_p3'
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'flutter' | Select-Object -Last 15 | ForEach-Object { "$_" }
