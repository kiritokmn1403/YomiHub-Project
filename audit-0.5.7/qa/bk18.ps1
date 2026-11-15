$EV="$QA\evidence\backup"
A shell pidof com.yomihub.app | ForEach-Object { Log "PID $_" }
A shell "top -b -n 1 -o PID,%CPU,RES,ARGS | grep -i -E \"yomi|mangayomi\"" | ForEach-Object { Log "TOP $_" }
A logcat -d -t 400 | Select-String "flutter|YomiHub|lowmemory|ActivityManager.*yomihub|Isar" | Select-Object -Last 15 | ForEach-Object { Log "LC $($_.Line)" }
