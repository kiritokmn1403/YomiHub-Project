& $ADB shell am start -a android.intent.action.VIEW -d "https://check.torproject.org/" com.android.chrome 2>&1 | Select-Object -Last 1
Start-Sleep 25
$n = Find-Node '(Accept|Chấp nhận|Use without|Không|No thanks|Tiếp tục)'
if ($n) { "dismiss $($n.label)"; & $ADB shell input tap $n.x $n.y; Start-Sleep 15 }
Shot 'c3_chrome'
L 25
