$EV="$QA\evidence\phone\qa1r"
A logcat -c | Out-Null
$n=Nodes; $m=@($n | Where-Object {$_.D -match 'Hiển thị menu|Quay lại'}).Count
Log "menu markers: $m"
if(-not (Find 'Quay lại')){ Tap 720 1480; Start-Sleep 2 }
for($i=1;$i -le 10;$i++){
  Tap 1250 2679; Start-Sleep -Milliseconds 1500
  if($i -eq 1){ Shot 'r04q_settings_open1'; $null=Ui 'r04q_settings_open1' }
  if($i -eq 10){ Shot 'r04q_settings_open10' }
  Back; Start-Sleep -Milliseconds 1000
  if(-not (Find 'Quay lại')){ Tap 720 1480; Start-Sleep -Milliseconds 1200 }
}
Shot 'r04q_after'
Log ("fg: " + (Fg))
A logcat -d > "$EV\r04q_logcat.txt"
$bad = Select-String -Path "$EV\r04q_logcat.txt" -Pattern 'Null check|FATAL EXCEPTION|_IndicatorPainter|Exception' | Select-Object -First 10
if($bad){ Log "LOGCAT-HITS:"; $bad | ForEach-Object { Log $_.Line } } else { Log "LOGCAT: no Null check / FATAL / Exception" }
