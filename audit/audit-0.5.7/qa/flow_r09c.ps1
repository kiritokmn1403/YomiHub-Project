$EV="$QA\evidence\phone\qa1r"
$p=Start-Process adb -ArgumentList '-s',$S,'shell','screenrecord','--time-limit','6','/sdcard/r09c.mp4' -PassThru -WindowStyle Hidden
Start-Sleep 8
A pull /sdcard/r09c.mp4 "$EV\09c_player.mp4" | Out-Null
Log ((A shell dumpsys media_session | Select-String 'state=PlaybackState|active=|package=|metadata:' | Select-Object -First 8) -join ' | ')
Log ((A shell dumpsys window | Select-String 'mCurrentFocus|rotation|mCurrentRotation' | Select-Object -First 3) -join ' | ')
Log ((A shell dumpsys audio | Select-String 'yomihub|AudioPlaybackConfiguration' | Select-Object -First 4) -join ' | ')
