. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB logcat -c
Tap 450 2061 20
Shot2 't25_player'
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'E/flutter|mpv|media_kit|swallowed|Exception' | Select-Object -Last 8 | ForEach-Object { "$_" }
& $ADB shell dumpsys media_session 2>&1 | Select-String 'state=' | Select-Object -First 3 | ForEach-Object { "$_" }
& $ADB shell input keyevent 3; Start-Sleep 4
Shot2 't25_pip'
& $ADB shell dumpsys activity activities 2>&1 | Select-String 'pinned|PIP|mPictureInPicture' | Select-Object -First 5 | ForEach-Object { "$_" }
