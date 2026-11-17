$pts=@(@(1080,1000),@(360,2000),@(1080,2000))
$k=0
foreach($p in $pts){ $k++
  Back; Start-Sleep 2
  if(-not (Find 'Lịch sử')){ Log 'not on history'; Shot "b1_state$k" }
  Tap $p[0] $p[1]; Start-Sleep 14; Shot "b1_item$k"; $null=Ui "b1_item$k"
}
A logcat -d > "$EV\b1_logcat.txt"
