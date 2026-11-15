Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9
for($i=0;$i -lt 4;$i++){ if(Find '^Thêm Thêm'){break}; Back; Start-Sleep 2 }
TapText '^Thêm Thêm' | Out-Null; Start-Sleep 4
Swipe 720 2200 720 400 500; Start-Sleep 2
$null=Ui 'x3_a'; Shot 'x3_a'
