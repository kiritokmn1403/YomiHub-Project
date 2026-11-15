Log (A shell dumpsys connectivity | Select-String 'NetworkAgentInfo|state:' | Select-Object -First 6 | Out-String)
Log ("ping: " + ((A shell ping -c 2 -W 2 8.8.8.8) -join ' | '))
Log ("wifi: " + ((A shell dumpsys wifi | Select-String 'Wi-Fi is|mWifiInfo' | Select-Object -First 3) -join ' | '))
Log ("airplane: " + (A shell settings get global airplane_mode_on))
