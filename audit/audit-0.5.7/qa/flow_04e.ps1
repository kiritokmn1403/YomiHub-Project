GoHome
Tap 1296 2650; Start-Sleep 3
Tap 720 1540; Start-Sleep 4
$pts=@(@(1080,1000),@(360,2000),@(1080,2000)); $i=2
foreach($p in $pts){ Tap $p[0] $p[1]; Start-Sleep 12; Shot "04e_item$i"; $null=Ui "04e_item$i"; $i++; Back; Start-Sleep 3 }
