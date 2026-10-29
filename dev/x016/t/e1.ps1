Reset
& $ADB logcat -c
& $ADB shell monkey -p com.yomihub.app -s 1606 --throttle 120 --pct-syskeys 0 --pct-appswitch 2 --ignore-security-exceptions -v 2000 2>&1 | Select-Object -Last 6
& $ADB shell cmd connectivity airplane-mode disable
"pid=$(& $ADB shell pidof $PKG)"
& $ADB logcat -d | Select-String -Pattern 'FATAL EXCEPTION|ANR in com.yomihub|E/flutter|Unhandled Exception' | Select-Object -First 20 | ForEach-Object { "$_" }
