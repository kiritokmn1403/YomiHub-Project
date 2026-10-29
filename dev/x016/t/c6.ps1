"--- via Tor HTTP tunnel 8118 (direct) ---"
& $ADB shell '(printf "CONNECT check.torproject.org:80 HTTP/1.0\r\n\r\nGET /api/ip HTTP/1.0\r\nHost: check.torproject.org\r\n\r\n"; sleep 25) | nc -w 30 127.0.0.1 8118 | head -12' 2>&1
"--- via device VPN (tun0 -> hev -> Tor SOCKS) ---"
& $ADB shell '(printf "GET /api/ip HTTP/1.0\r\nHost: check.torproject.org\r\n\r\n"; sleep 25) | nc -w 30 check.torproject.org 80 | head -12' 2>&1
