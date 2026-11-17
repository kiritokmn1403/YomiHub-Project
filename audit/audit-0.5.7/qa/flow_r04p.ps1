$EV="$QA\evidence\phone\qa1r"
Log ((A shell ping -c 2 -W 3 google.com) -join ' | ')
Log ((A shell ping -c 2 -W 3 8.8.8.8) -join ' | ')
Log ((A shell getprop net.dns1) -join ' ')
Log ((A shell settings get global private_dns_mode) -join ' ')
Log ((A shell dumpsys connectivity | Select-String 'VPN|NetworkAgentInfo' | Select-Object -First 4) -join ' | ')
Start-Sleep 10; Shot 'r04p_after'
