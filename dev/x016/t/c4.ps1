& $ADB shell input keyevent 4
& $ADB shell am force-stop com.android.chrome
& $ADB shell 'which curl wget nc toybox ping'
& $ADB shell 'echo -e "GET /api/ip HTTP/1.0\r\nHost: check.torproject.org\r\n\r\n" | nc -w 20 check.torproject.org 80' 2>&1 | Select-Object -Last 6
& $ADB shell 'curl -s -m 30 https://check.torproject.org/api/ip' 2>&1
