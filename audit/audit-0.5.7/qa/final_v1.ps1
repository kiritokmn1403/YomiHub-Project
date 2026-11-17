$EV="$QA\evidence\phone\final"; New-Item -ItemType Directory -Force $EV | Out-Null; $TAG="fv1"
A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Tap 720 364; Start-Sleep 3
Shot "${TAG}_pre"
A logcat -c | Out-Null
Tap 1080 2000; Log 'tapped Kungfu'
Start-Sleep 30; Shot "${TAG}_t30"
Start-Sleep 8; Shot "${TAG}_t40"
Tap 720 1300; Start-Sleep 1; Shot "${TAG}_t42tap"
Start-Sleep 8; Shot "${TAG}_t52"
A shell "dumpsys SurfaceFlinger --list | grep -i -E 'yomihub|SurfaceTexture|ImageReader'" | ForEach-Object { Log $_ }
A logcat -d > "$EV\${TAG}_logcat.txt"
A shell "tail -n 6 /sdcard/YomiHub/logs.txt" > "$EV\${TAG}_applog.txt"
Tap 720 1300; Start-Sleep 1; Tap 105 112; Start-Sleep 3; Shot "${TAG}_afterback"
Log (Fg)
A shell "dumpsys activity activities | grep -i -E 'mResumedActivity|pinned' | head -3" | ForEach-Object { Log $_ }
