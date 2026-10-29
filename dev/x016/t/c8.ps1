& $ADB shell '(printf "CONNECT 1.1.1.1:80 HTTP/1.0\r\n\r\nGET / HTTP/1.0\r\nHost: one.one.one.one\r\n\r\n"; sleep 70) | nc 127.0.0.1 8118 | head -4; echo rc=$?' 2>&1
& $ADB shell '(printf "GET /api/ip HTTP/1.0\r\nHost: check.torproject.org\r\n\r\n"; sleep 70) | nc check.torproject.org 80 | head -12; echo rc=$?' 2>&1
