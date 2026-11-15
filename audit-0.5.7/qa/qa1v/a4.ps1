Tap 1020 181; Start-Sleep 2
A shell input text 'Shirley' | Out-Null; Start-Sleep 1; Key 66; Start-Sleep 8
Shot 'a4_search'
Tap 360 1000; Start-Sleep 6; Shot 'a4_detail'; $null=Ui 'a4_detail'
$m=Find 'Vol.2 Ch.11'; if($m){ Tap 500 (($m.Y1+$m.Y2)/2) } else { Log 'NOCH11' }
A logcat -c | Out-Null
Start-Sleep 3; Shot 'a4_r_t3'
Start-Sleep 4; Shot 'a4_r_t7'
Start-Sleep 8; Shot 'a4_r_t15'
