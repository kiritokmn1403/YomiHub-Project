$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
Tap 540 1285; Start-Sleep 4
Ui a5_src | Out-Null
if (Find '^OK$') { TapText '^OK$' | Out-Null; Start-Sleep 4 }
Shot a5_confirm
Ui a5_confirm | Out-Null
