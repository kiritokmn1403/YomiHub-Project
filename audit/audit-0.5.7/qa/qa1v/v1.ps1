A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Tap 720 364; Start-Sleep 3
$n0 = (A shell "grep -c 'sau 8' /sdcard/YomiHub/logs.txt") -join ''; Log "sau8 BEFORE=[$n0]"
$l0 = (A shell "wc -l < /sdcard/YomiHub/logs.txt") -join ''; Log "loglines BEFORE=[$l0]"
A logcat -c | Out-Null
A shell rm -f /sdcard/qa1v_rec.mp4 | Out-Null
$p = Start-Process -FilePath adb -ArgumentList @('-s',$S,'shell','screenrecord','--time-limit','60','/sdcard/qa1v_rec.mp4') -PassThru -WindowStyle Hidden
Start-Sleep 2
Tap 1080 2000; Log 'tapped Kungfu'
Start-Sleep 4; Shot 'v1_t6'
Start-Sleep 6; Shot 'v1_t12'
Tap 720 1300; Start-Sleep 1; Shot 'v1_tap'; $null=Ui 'v1_tap'
Start-Sleep 12; Shot 'v1_t27'
A shell "dumpsys activity activities | grep -i -E 'mResumedActivity|pinned' | head -3" | ForEach-Object { Log $_ }
Start-Sleep 25
Wait-Process -Id $p.Id -Timeout 30 -ErrorAction SilentlyContinue
A pull /sdcard/qa1v_rec.mp4 "$EV\v1_rec.mp4" | Out-Null; Log 'rec pulled'
A logcat -d > "$EV\v1_logcat.txt"
$n1 = (A shell "grep -c 'sau 8' /sdcard/YomiHub/logs.txt") -join ''; Log "sau8 AFTER=[$n1]"
A shell "tail -n 25 /sdcard/YomiHub/logs.txt" | ForEach-Object { Log $_ }
