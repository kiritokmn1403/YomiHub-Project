# reading direction unknown: try swipe left (next page for LTR)
Swipe 1200 1500 200 1500 250; Start-Sleep 3; Shot 'a5_p2'
Swipe 1200 1500 200 1500 250; Start-Sleep 2; Swipe 1200 1500 200 1500 250; Start-Sleep 2; Swipe 1200 1500 200 1500 250; Start-Sleep 2; Swipe 1200 1500 200 1500 250; Start-Sleep 3; Shot 'a5_p5'
A shell "grep -c 'sau 8' /sdcard/YomiHub/logs.txt" | Log
A logcat -d > "$EV\a5_logcat.txt"
