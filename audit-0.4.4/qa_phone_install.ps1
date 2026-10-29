# timeout: 8
. "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\qa044.ps1"
$global:SER = 'K75THMJVHA95EARO'
$apk = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\0.4.4\YomiHub-0.4.4-arm64-v8a.apk"
"apk exists: $(Test-Path $apk) $((Get-Item $apk).Length)"
A shell input keyevent 224
A logcat -c
A install -r $apk
A shell dumpsys package com.yomihub.app | Select-String "versionName|versionCode" | Select-Object -First 2
RecStart 'p044_start' 60
A shell monkey -p com.yomihub.app -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 14
Snap 'p01_start'
Start-Sleep 6
Snap 'p02_home'
Dump 'p02_home'
A shell pidof com.yomihub.app
