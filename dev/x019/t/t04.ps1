. 'D:\Claude A.I\dev\x019\t\c.ps1'
Adb shell input swipe 900 273 100 273 300 | Out-Null
Start-Sleep 2
TapText 'Novel Setting' 3 | Out-Null
TapText '^Extensions$' 6 | Out-Null
Shot 't04_novel_ext'
Labels 't04_novel_ext' | Select-Object -First 40
