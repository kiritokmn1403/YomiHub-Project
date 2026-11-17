$EV="$QA\evidence\backup"
Ui b17_now | Out-Null
A shell "top -b -n 1 | grep -i yomihub" | ForEach-Object { Log "TOP $_" }
A shell "ls -la /data/data/com.yomihub.app/ 2>&1 | head -2; run-as com.yomihub.app ls -la files 2>&1 | head" | ForEach-Object { Log "FS $_" }
A shell "grep -a -c Sao /sdcard/YomiHub/logs.txt; tail -n 2 /sdcard/YomiHub/logs.txt" | ForEach-Object { Log "LOG $_" }
