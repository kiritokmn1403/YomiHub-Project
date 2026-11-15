$EV="$QA\evidence\backup"
Tap 720 1647; Start-Sleep 5
for($k=0;$k -lt 3;$k++){ Ui b12_dlg | Out-Null; if (Find '^OK$') { TapText '^OK$' | Out-Null; Start-Sleep 4 } elseif (Find '^Thay th.$') { Shot b12_confirm; TapText '^Thay th.$' | Out-Null; break } else { Start-Sleep 3 } }
for($i=0;$i -lt 24;$i++){ Start-Sleep 5; $l = A shell "tail -n 6 /sdcard/YomiHub/logs.txt"; if("$l" -match 'xong: pc_win|L.i|ERROR'){break} }
$l | Select-String "Sao" | ForEach-Object { Log "APPLOG $($_.Line)" }
Start-Sleep 3; GoHome; Start-Sleep 4
Shot b12_library
