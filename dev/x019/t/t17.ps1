. 'D:\Claude A.I\dev\x019\t\c.ps1'
Back 2
Start-Sleep 35
Shot 't17_tr'
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'YomiImageTranslate|flutter' | Select-Object -Last 12 | ForEach-Object { "$_" }
