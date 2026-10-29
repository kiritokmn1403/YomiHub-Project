. 'D:\Claude A.I\dev\x021\t\h.ps1'
Swipe 540 1900 540 900
L2 'f' | Select-String -Pattern 'RoPhim|HotPhim|Anime47|AVSub|VTV' 
$n = Find-Node '^RoPhim'
if ($n) { Tap 300 $n.y 15; Shot2 't24_rophim'; Tap 270 800 12; Shot2 't24_rp_detail' }
