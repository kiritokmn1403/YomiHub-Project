$EV="$QA\evidence\phone\qa1r"
Log ((A shell dumpsys power | Select-String 'Wakefulness|mScreenOn|mHoldingDisplay|Display Power|mInteractive') -join ' | ')
A shell input keyevent 224; Start-Sleep 1
A shell settings put system screen_off_timeout 600000 | Out-Null
A shell svc power stayon true | Out-Null
A shell wm dismiss-keyguard | Out-Null; Start-Sleep 2
Shot 'r09e_a'; Log ("fg: " + (Fg))
