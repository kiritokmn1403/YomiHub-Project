$EV="$QA\evidence\phone\qa1r"
A logcat -c | Out-Null
Tap 360 1000; Start-Sleep 12; Shot 'r04d_a'; $null=Ui 'r04d_a'
Log ("fg: " + (Fg))
