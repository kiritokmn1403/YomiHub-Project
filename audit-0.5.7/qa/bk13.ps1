$EV="$QA\evidence\backup"
A shell "tail -n 25 /sdcard/YomiHub/logs.txt" | Out-File -Encoding UTF8 "$EV\applog_b12.txt"
Log done
