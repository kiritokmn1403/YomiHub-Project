# FLOW 1: cold start + loading screen (5 s) recorded
Wake; Stop; Start-Sleep 2
A logcat -c | Out-Null
A shell rm -f /sdcard/qa_launch.mp4 | Out-Null
$p = Start-Process adb -ArgumentList @('-s',$S,'shell','screenrecord','--time-limit','20','/sdcard/qa_launch.mp4') -WindowStyle Hidden -PassThru
Start-Sleep 2
Launch
foreach($t in 1,3,5,8){ Start-Sleep -Seconds $(if($t -eq 1){1}else{2}); Shot ("01_launch_t{0:00}s" -f $t) }
Start-Sleep 12
$p.WaitForExit(15000) | Out-Null
Start-Sleep 2
A pull /sdcard/qa_launch.mp4 "$EV\01_launch.mp4" | Out-Null
Log "video pulled"
$ns = Ui '01_after_launch'
Log ("fg: " + (Fg))
