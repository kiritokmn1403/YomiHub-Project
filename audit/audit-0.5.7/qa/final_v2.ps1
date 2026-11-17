$EV="$QA\evidence\phone\final"; New-Item -ItemType Directory -Force $EV | Out-Null; $TAG="fv3"
A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Tap 720 364; Start-Sleep 3
Shot "${TAG}_pre"
A logcat -c | Out-Null
Tap 1080 2000; Log 'tapped Kungfu'
Start-Sleep 12
$rec = Start-Process -FilePath "D:\yh\tools\android-sdk\platform-tools\adb.exe" -ArgumentList @("-s","281038ac31217ece",'shell','screenrecord','--time-limit','45','/sdcard/fv3.mp4') -PassThru -WindowStyle Hidden
Start-Sleep 12; Tap 720 1300; Log 'tap1'; Start-Sleep 2; Shot "${TAG}_tap1"
Start-Sleep 14; Tap 720 1300; Log 'tap2'; Start-Sleep 2; Shot "${TAG}_tap2"
Start-Sleep 18
A pull /sdcard/fv3.mp4 "$EV\${TAG}.mp4" | Out-Null
A shell "tail -n 8 /sdcard/YomiHub/logs.txt" > "$EV\${TAG}_applog.txt"
A logcat -d > "$EV\${TAG}_logcat.txt"
Tap 105 112; Start-Sleep 3; Shot "${TAG}_afterback"
A shell "dumpsys activity activities | grep -i -E 'mResumedActivity|pinned' | head -3" | ForEach-Object { Log $_ }
