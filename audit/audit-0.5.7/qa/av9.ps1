$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
Tap 63 257; Start-Sleep 2
Tap 400 120; Start-Sleep 3
Tap 765 257; Start-Sleep 2
A shell input text YHVideo | Out-Null; Start-Sleep 3
A shell input keyevent 111 | Out-Null; Start-Sleep 2
Shot a9_search
Ui a9_search | Out-Null
