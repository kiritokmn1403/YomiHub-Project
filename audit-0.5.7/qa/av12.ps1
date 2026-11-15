$global:S="emulator-5554"; $EV="$QA\evidence\avd29"
Shot a12_player1
Start-Sleep 4
Shot a12_player2
A shell wm size | ForEach-Object { Log "WM $_" }
