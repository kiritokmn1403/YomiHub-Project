$EV="$QA\evidence\phone\qa1r"
# FLOW 3: Library settings sheet open/close x N (regression: 40x "Null check" in _IndicatorPainter)
$N=10
Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9
A logcat -c | Out-Null
TapText '^Truyện tr' | Out-Null; Start-Sleep 2
Shot 'r03_lib_before'
# filter/settings icon = 3rd icon of the top bar (search, filter, more) at approx (1187,343) on 1440x2960
for($i=1;$i -le $N;$i++){
  Tap 1187 343; Start-Sleep -Milliseconds 1400
  if($i -eq 1){ Shot 'r03_sheet_open_1'; $null=Ui 'r03_sheet_open' }
  if($i -eq $N){ Shot "r03_sheet_open_$N" }
  Back; Start-Sleep -Milliseconds 900
}
Shot 'r03_after_loop'
Log ("fg: " + (Fg))
A logcat -d > "$EV\r03_logcat.txt"
$bad = Select-String -Path "$EV\r03_logcat.txt" -Pattern 'Null check|FATAL EXCEPTION|_IndicatorPainter' | Select-Object -First 10
if($bad){ Log "LOGCAT-HITS:"; $bad | ForEach-Object { Log $_.Line } } else { Log "LOGCAT: no Null check / FATAL" }
