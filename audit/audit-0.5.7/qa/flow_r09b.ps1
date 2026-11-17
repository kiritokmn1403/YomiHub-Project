$EV="$QA\evidence\phone\qa1r"
A logcat -c | Out-Null
Tap 1080 1000; Start-Sleep 20; Shot 'r09b_t20'; $null=Ui 'r09b_t20'
Start-Sleep 15; Shot 'r09b_t35'
Log ("fg: " + (Fg))
