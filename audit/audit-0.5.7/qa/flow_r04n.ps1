$EV="$QA\evidence\phone\qa1r"
Start-Sleep 15; Shot 'r04n_wait'
A logcat -d > "$EV\r04n_logcat.txt"
Select-String -Path "$EV\r04n_logcat.txt" -Pattern 'flutter|yomihub|Exception' | Select-Object -Last 30 | ForEach-Object { Log $_.Line }
