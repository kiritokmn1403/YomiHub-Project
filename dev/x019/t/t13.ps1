. 'D:\Claude A.I\dev\x019\t\c.ps1'
Adb logcat -c | Out-Null
Tap 500 1625 18
Shot 't13_reader0'
Tap 540 1200 3
Labels 't13_bar' | Select-Object -First 20
TapText '(Dịch ảnh|Translate image)' 3 | Out-Null
Labels 't13_sheet' | Select-Object -First 15
