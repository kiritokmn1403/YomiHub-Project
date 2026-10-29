& $ADB shell 'ping -c1 -W3 check.torproject.org' 2>&1 | Select-Object -First 2
& $ADB shell 'ip route get 1.1.1.1; ip rule | head -20' 2>&1
& $ADB shell 'printf "GET / HTTP/1.0\r\nHost: one.one.one.one\r\n\r\n" | nc -w 20 1.1.1.1 80 | head -5' 2>&1
& $ADB shell 'id; dumpsys connectivity | grep -i "VPN CONNECTED\|tun0" | head -5' 2>&1
& $ADB logcat -d | Select-String -Pattern 'hev|YomiTorVpn|tun2socks|TProxy' | Select-Object -Last 15 | ForEach-Object { "$_" }
