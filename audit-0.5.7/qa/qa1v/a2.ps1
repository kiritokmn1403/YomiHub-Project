A shell cmd statusbar collapse | Out-Null
Fg | Log
for($i=0;$i -lt 8;$i++){ $ns=Ui "a2_$i"; $m=Find 'Shirley' 0 $ns; if($m){ Log "FOUND $(Lbl $m) $($m.X1),$($m.Y1)"; break }; Swipe 720 2000 720 700 400; Start-Sleep 2 }
Shot 'a2_end'
