$EV="$QA\evidence\avd29"; New-Item -ItemType Directory -Force $EV | Out-Null
$adb="D:\yh\tools\android-sdk\platform-tools\adb.exe"
& $adb devices | ForEach-Object { Log "DEV $_" }
$em = (& $adb devices) -match '^emulator-\d+\s+device' | ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -Last 1
Log "EMU=$em"
if($em){ for($i=0;$i -lt 26;$i++){ $b=(& $adb -s $em shell getprop sys.boot_completed 2>$null); if("$b".Trim() -eq '1'){break}; Start-Sleep 5 }
 Log ("boot=" + (& $adb -s $em shell getprop sys.boot_completed) + " sdk=" + (& $adb -s $em shell getprop ro.build.version.sdk) + " rel=" + (& $adb -s $em shell getprop ro.build.version.release))
 Set-Content "$QA\qa\avd29_serial.txt" $em }
