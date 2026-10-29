. 'D:\Claude A.I\dev\x020\t\c.ps1'
$T = 'D:\Claude A.I\dev\x021\t'
function Shot2($name) { & $ADB shell screencap -p /sdcard/yh_shot.png | Out-Null; & $ADB pull /sdcard/yh_shot.png "$T\shots\$name.png" 2>&1 | Out-Null; "shot $name" }
function L2($name) { Labels $name | Select-Object -First 60 }
function Swipe($x1,$y1,$x2,$y2,$ms=400) { & $ADB shell input swipe $x1 $y1 $x2 $y2 $ms; Start-Sleep 1 }
function Launch($wait=12) { & $ADB shell monkey -p com.yomihub.app -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null; Start-Sleep $wait }
function Route($r, $wait=4) { & $ADB shell am start -a android.intent.action.VIEW -d "'yomihub://open?route=$r'" com.yomihub.app 2>&1 | Out-Null; Start-Sleep $wait }
