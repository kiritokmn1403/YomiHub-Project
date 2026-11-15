$adb="D:\yh\tools\android-sdk\platform-tools\adb.exe"
& $adb devices -l | ForEach-Object { Log "DEV $_" }
foreach($s in @('emulator-5554','281038ac31217ece')){
 Log ("$s model=" + (& $adb -s $s shell getprop ro.product.model) + " sdk=" + (& $adb -s $s shell getprop ro.build.version.sdk) + " wm=" + (& $adb -s $s shell wm size) + " focus=" + ((& $adb -s $s shell "dumpsys window | grep mCurrentFocus") -join ' ') + " date=" + (& $adb -s $s shell date))
 & $adb -s $s shell "dumpsys activity activities | grep -E 'Hist #|mResumedActivity' | head -6" | ForEach-Object { Log "  ACT $_" }
}
