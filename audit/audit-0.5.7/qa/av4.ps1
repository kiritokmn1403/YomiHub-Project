$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
Tap 94 147; Start-Sleep 2
TapText '^Downloads' | Out-Null; Start-Sleep 3
TapText 'YH_PC' | Out-Null; Start-Sleep 3
Shot a4_file
TapText 'pc_win' | Out-Null; Start-Sleep 12
Shot a4_mode
Ui a4_mode | Out-Null
