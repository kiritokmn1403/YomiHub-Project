$EV="$QA\evidence\backup"
for($i=0;$i -lt 28;$i++){ $l = A shell "grep -a -E 'xong: pc_win|kh.i ph.c b.n sao l.u YomiHub|\]\[ERROR\]' /sdcard/YomiHub/logs.txt | tail -n 3"; if("$l" -match 'pc_win'){break}; Start-Sleep 5 }
$l | ForEach-Object { Log "APPLOG $_" }
A shell "dumpsys window | grep mCurrentFocus" | ForEach-Object { Log "FOCUS $_" }
