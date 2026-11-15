$EV="$QA\evidence\backup"
Wake; A logcat -c | Out-Null
A shell am start -W -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | ForEach-Object { Log $_ }
Start-Sleep 12
Log (Fg)
A logcat -d -b crash | Select-Object -First 30 | ForEach-Object { Log $_ }
A logcat -d -s YomiHub:* AndroidRuntime:E flutter:E | Select-Object -First 20 | ForEach-Object { Log $_ }
Shot "b0b_after_start"
