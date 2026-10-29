if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\output\YomiHub-0.1.5-x86_64.apk' 2>&1 | Select-Object -Last 1
& $ADB shell am force-stop $PKG
& $ADB logcat -c
& $ADB shell am start -a android.intent.action.VIEW -d "yomihub://open?route=%2Fbrowser" com.yomihub.app | Out-Null
Start-Sleep 9
Shot 't20_shortcut'
L 8
