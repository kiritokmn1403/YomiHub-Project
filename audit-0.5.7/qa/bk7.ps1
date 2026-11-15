$EV="$QA\evidence\backup"
for($i=0;$i -lt 12;$i++){ $l = A shell "ls -la /sdcard/Download/YomiHub_test/ | grep 2026-11-15"; Log ("LS " + ($l -join " | ")); if(-not ($l -match "partial")){break}; Start-Sleep 10 }
Shot b7_done
Ui b7_done | Out-Null
A shell "grep -a -i \"sao l\" /sdcard/YomiHub/logs.txt | tail -n 4" | Out-File -Encoding UTF8 "$EV\applog_b7.txt"
