$EV="$QA\evidence\backup"
Shot b16_now
Ui b16_now | Out-Null
A shell "tail -n 5 /sdcard/YomiHub/logs.txt" | Out-File -Encoding UTF8 "$EV\applog_b16.txt"
A shell "top -b -n 1 | head -12" | Out-File -Encoding UTF8 "$EV\top_b16.txt"
