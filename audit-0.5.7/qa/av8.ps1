$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
A shell "rm -rf /sdcard/YomiHub/local/YH /sdcard/YomiHub/localanime; mkdir -p /sdcard/YomiHub/local/YHVideoTest" | Out-Null
A push D:\yh\backup_test\Test_Anime_VOD.mp4 /sdcard/YomiHub/local/YHVideoTest/Tap01.mp4 | Out-Null
A shell "ls -la /sdcard/YomiHub/local/YHVideoTest/" | ForEach-Object { Log "LS $_" }
A logcat -c | Out-Null
A shell am force-stop com.yomihub.app | Out-Null; Start-Sleep 1
A shell monkey -p com.yomihub.app -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 20
A logcat -d | Select-String "scan summary|title scan" | Select-Object -First 4 | ForEach-Object { Log ("SCAN " + $_.Line.Substring([Math]::Max(0,$_.Line.IndexOf('_scan')))) }
