A logcat -d > "$EV\a9_logcat.txt"
A shell "ls -la /sdcard/YomiHub/" | Log
A shell "grep -c 'sau 8' /sdcard/YomiHub/logs.txt" | Log
A shell "tail -n 12 /sdcard/YomiHub/logs.txt" | Log
