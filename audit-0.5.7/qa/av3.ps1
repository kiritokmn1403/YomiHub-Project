$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3
for($i=0;$i -lt 4 -and -not (Find 'Sao L.u & ..ng B'); $i++){ Swipe 540 1700 540 700 400; Start-Sleep 1 }
TapText 'Sao L.u & ..ng B' | Out-Null; Start-Sleep 3
TapText 'Kh.i ph.c b.n sao l.u' | Out-Null; Start-Sleep 4
Shot a3_picker
Ui a3_picker | Out-Null
