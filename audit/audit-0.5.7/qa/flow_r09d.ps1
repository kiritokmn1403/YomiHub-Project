$EV="$QA\evidence\phone\qa1r"
Log ((A shell dumpsys power | Select-String 'mWakefulness=|Display Power') -join ' | ')
Log ("fg: " + (Fg))
Wake; Start-Sleep 2; Shot 'r09d_wake'; $null=Ui 'r09d_wake'
