. 'D:\Claude A.I\dev\x019\t\c.ps1'
"install: " + ((Adb install -r 'D:\Claude A.I\dev\x019\YomiHub-0.1.9-dev-x86_64-release.apk') -join ' ')
Adb shell am force-stop $PKG
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 16
TapText '^Browse' 3 | Out-Null
TapText 'Film & Movie Setting' 3 | Out-Null
TapText '^Source$' 3 | Out-Null
TapText '^YouTube' 12 | Out-Null
Tap 800 800 12
Tap 965 2160 40
Shot 't26_play'
