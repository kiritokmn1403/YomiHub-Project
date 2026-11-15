$EV="$QA\evidence\phone\qa1r"; New-Item -ItemType Directory -Force $EV | Out-Null
$apk='D:\Claude A.I\output\0.5.7\YomiHub-0.5.7-arm64-v8a.apk'
Wake
Log ("install: " + ((A install -r -d $apk) -join ' '))
$d = A shell dumpsys package $PKG
$d | Select-String 'versionName|versionCode|lastUpdateTime|firstInstallTime' | ForEach-Object { Log $_.Line.Trim() }
Stop; Start-Sleep 1
$p=Start-Process adb -ArgumentList '-s',$S,'shell','screenrecord','--time-limit','14','/sdcard/r01.mp4' -PassThru -WindowStyle Hidden
Start-Sleep 1
Launch
Start-Sleep 15
A pull /sdcard/r01.mp4 "$EV\01_launch.mp4" | Out-Null
Shot '01_after'
