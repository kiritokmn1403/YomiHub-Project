$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
A logcat -c | Out-Null
A shell am start -W -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | ForEach-Object { Log "AM $_" }
Start-Sleep 18
A shell "dumpsys window | grep mCurrentFocus" | ForEach-Object { Log "FOCUS $_" }
Shot a16_tv
Ui a16_tv | Out-Null
A logcat -d | Select-String "FATAL|AndroidRuntime: Process|YomiHub :" | Select-Object -Last 5 | ForEach-Object { Log "LC $($_.Line)" }
