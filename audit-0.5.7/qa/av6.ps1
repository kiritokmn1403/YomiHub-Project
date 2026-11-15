$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
Tap 808 1341
for($i=0;$i -lt 20;$i++){ Start-Sleep 5; $l = A shell "grep -a 'Kh.i ph.c xong' /sdcard/YomiHub/logs.txt 2>/dev/null; ls /sdcard/Download/*/logs.txt /sdcard/*/logs.txt 2>/dev/null"; if("$l" -match 'xong'){break} }
Log ("RESULT " + ($l -join ' | '))
TapText 'Th.vi.n Tab 1' | Out-Null; Start-Sleep 6
Shot a6_library
Ui a6_library | Out-Null
