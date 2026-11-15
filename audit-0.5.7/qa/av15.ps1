$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
$apk="$root\output\0.5.7\YumiHub-Android-TV-0.5.7-x86_64.apk"
$pkg = (& "D:\yh\tools\android-sdk\build-tools\*\aapt.exe" dump badging $apk 2>$null | Select-String "^package:" | Select-Object -First 1)
Log "BADGING $pkg"
A install -r $apk | Select-Object -Last 1 | ForEach-Object { Log "INSTALL $_" }
A logcat -c | Out-Null
A shell "pm list packages | grep -i yomi" | ForEach-Object { Log "PKG $_" }
$id = if ("$pkg" -match "name='([^']+)'") { $Matches[1] } else { 'com.yomihub.tv' }
A shell monkey -p $id 1 | Out-Null
Start-Sleep 20
A shell "dumpsys window | grep mCurrentFocus" | ForEach-Object { Log "FOCUS $_" }
Shot a15_tv
Ui a15_tv | Out-Null
A logcat -d | Select-String "FATAL|AndroidRuntime: Process|YomiHub :" | Select-Object -Last 5 | ForEach-Object { Log "LC $($_.Line)" }
