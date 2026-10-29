. 'D:\Claude A.I\dev\x019\t\c.ps1'
Tap 540 1854 2
Back 2
Start-Sleep 40
Shot 't14_translated'
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'mlkit|MlKit|TextRecognizer|OCR|Dịch ảnh|E/flutter|vision' | Select-Object -Last 25 | ForEach-Object { "$_" }
