& $ADB shell am force-stop $PKG
& $ADB logcat -c
& $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
Start-Sleep 75
& $ADB logcat -d | Select-String -Pattern 'Bootstrapped|tor-android|TorService|\[warn\]|\[err\]' | Select-Object -Last 15 | ForEach-Object { "$_" }
& $ADB shell 'ip addr show tun0 | grep inet' 2>&1
& $ADB shell '(printf "CONNECT 1.1.1.1:80 HTTP/1.0\r\n\r\nGET / HTTP/1.0\r\nHost: one.one.one.one\r\n\r\n"; sleep 40) | nc 127.0.0.1 8118 | head -4; echo rc=$?' 2>&1
