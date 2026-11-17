Log "devices: $((& adb devices) -join ' | ')"
Log ("before: " + ((A shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode|lastUpdateTime') -join ' ; '))
$apk='D:\Claude A.I\output\0.5.7\YomiHub-0.5.7-arm64-v8a.apk'
Log ("sha256 " + (Get-FileHash $apk -Algorithm SHA256).Hash)
Log ("install: " + ((A install -r $apk) -join ' '))
Log ("after: " + ((A shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode|lastUpdateTime') -join ' ; '))
GoHome; Start-Sleep 3; Shot 'q4_01_home'
