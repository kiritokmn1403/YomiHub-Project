. 'D:\Claude A.I\dev\x021\t\h.ps1'
Back 2; Back 2; Back 2
TapText "^Film & Movie Extension Settings" 4
TapText '^Source$' 3
$n = Find-Node '^RoPhim'
"node $($n.label) $($n.x),$($n.y)"
if ($n) { Tap 300 $n.y 15 } else { L2 'f' | Select-Object -First 30 }
Shot2 't23_rophim'
