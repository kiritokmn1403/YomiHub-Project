$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
$adb="D:\yh\tools\android-sdk\platform-tools\adb.exe"
$rec = Start-Process -FilePath $adb -ArgumentList @('-s','emulator-5554','shell','screenrecord','--time-limit','25','/sdcard/a14.mp4') -PassThru -WindowStyle Hidden
Start-Sleep 3; Tap 540 1100; Start-Sleep 1; Shot a14_controls
Start-Sleep 6; Shot a14_t2
Start-Sleep 18
A pull /sdcard/a14.mp4 "$EV\avd29_video_playback.mp4" | Out-Null
Log ("REC " + (Get-Item "$EV\avd29_video_playback.mp4").Length)
A logcat -d | Select-String "YomiHub|media_kit|mpv.*(error|fail)|AndroidRuntime|NoSuchField" | Select-Object -Last 10 | ForEach-Object { Log "LC $($_.Line)" }
