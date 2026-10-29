& $ADB shell '(printf "GET /capabilities HTTP/1.0\r\n\r\n"; sleep 3) | nc 127.0.0.1 47321 | head -3; echo rc=$?' 2>&1
& $ADB shell '(printf "CONNECT 1.1.1.1:80 HTTP/1.0\r\n\r\n"; sleep 20) | nc 127.0.0.1 8118 | head -3; echo rc=$?' 2>&1
& $ADB shell 'netstat -tln 2>/dev/null | head -20 || ss -tln' 2>&1
& $ADB logcat -d -t 400 | Select-String -Pattern 'Tor|tor:|Bootstrapped' | Select-Object -Last 12 | ForEach-Object { "$_" }
