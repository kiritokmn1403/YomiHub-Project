$EV="$QA\evidence\phone\qa1r"
Start-Sleep 8; $null=Ui 'r04j_a'
Swipe 720 800 720 2300 400; Start-Sleep 10; Shot 'r04j_b'; $null=Ui 'r04j_b'
A logcat -d | Select-String 'flutter' | Select-Object -Last 15 | ForEach-Object { Log $_.Line }
