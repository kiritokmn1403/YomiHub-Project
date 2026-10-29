. 'D:\Claude A.I\dev\x019\t\c.ps1'
TapText 'Don.t allow' 2 | Out-Null
Adb shell am force-stop com.google.android.youtube
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 8
TapText '^Browse' 3 | Out-Null
TapText 'Film & Movie Setting' 3 | Out-Null
TapText '^Source$' 3 | Out-Null
TapText '^YouTube' 12 | Out-Null
Labels 't20_yt' | Select-Object -First 14
TapText '^Short' 30 | Out-Null
Shot 't20_short'
Labels 't20_short' | Select-Object -First 20
