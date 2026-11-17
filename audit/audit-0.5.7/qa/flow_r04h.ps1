$EV="$QA\evidence\phone\qa1r"
Start-Sleep 5; Shot 'r04h_a'; $null=Ui 'r04h_a'
Swipe 720 900 720 2200 300; Start-Sleep 2; Shot 'r04h_b'; $null=Ui 'r04h_b'
A logcat -d -s flutter:V *:E | Select-Object -Last 25 | ForEach-Object { Log $_ }
