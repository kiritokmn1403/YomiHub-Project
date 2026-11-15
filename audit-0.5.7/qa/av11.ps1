$adb="D:\yh\tools\android-sdk\platform-tools\adb.exe"
foreach($s in @('emulator-5554','281038ac31217ece')){ Log ("$s FOCUS " + ((& $adb -s $s shell "dumpsys window | grep mCurrentFocus") -join ' ')) }
Get-CimInstance Win32_Process -Filter "Name='scrcpy.exe'" | ForEach-Object { Log ("SCRCPY $($_.ProcessId) :: $($_.CommandLine)") }
& $adb -s emulator-5554 logcat -d -t 40 | Select-String "YomiHub|mpv|media_kit|AndroidRuntime" | Select-Object -Last 12 | ForEach-Object { Log "LC $($_.Line)" }
