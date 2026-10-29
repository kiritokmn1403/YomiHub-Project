$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 5
# Click Tab 'Them'
& $adb shell "input tap 945 2232"
Start-Sleep 2
# Scroll down to reveal Gioi thieu
& $adb shell "input swipe 540 1800 540 600 300"
Start-Sleep 2
# Tap Gioi thieu (lower part of screen)
& $adb shell "input tap 540 2053"
Start-Sleep 3
& $adb shell "screencap -p /sdcard/about_v036.png"
& $adb pull /sdcard/about_v036.png "C:\Users\nguye\.gemini\antigravity\brain\2f2621bc-68e7-4a50-a219-0d68c3c2001e\about_v036.png"
