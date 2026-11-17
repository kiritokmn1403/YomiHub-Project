$a = (A shell "cat /proc/19175/stat") -split ' '; Start-Sleep 10; $b = (A shell "cat /proc/19175/stat") -split ' '
Log ("CPU ticks in 10s: utime +" + ([int64]$b[13]-[int64]$a[13]) + " stime +" + ([int64]$b[14]-[int64]$a[14]) + " total utime=" + $b[13])
A shell "grep -E 'VmRSS|Threads' /proc/19175/status" | ForEach-Object { Log $_ }
