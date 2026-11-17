$EV="$QA\evidence\backup"
A shell "grep -a 'Sao l' /sdcard/YomiHub/logs.txt | tail -n 3" | Out-File -Encoding UTF8 "$EV\applog_b20.txt"
Start-Sleep 2
Ui b20_now | Out-Null
TapText 'Th.vi.n Tab 1' | Out-Null; Start-Sleep 5
Shot b20_note9_library_after_restore
Ui b20_lib | Out-Null
