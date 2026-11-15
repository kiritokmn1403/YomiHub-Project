$EV="$QA\evidence\backup"
Tap 1148 2659
Start-Sleep 8
Shot b6_created
Ui b6_created | Out-Null
A shell "tail -n 15 /sdcard/YomiHub/logs.txt" | Out-File -Encoding UTF8 "$EV\applog_b6.txt"
A shell "ls -la /sdcard/Download/YomiHub_test/" | Out-File -Encoding UTF8 "$EV\ls_b6.txt"
