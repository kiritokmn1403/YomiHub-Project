Log ("fg before back: " + (Fg))
Back; Start-Sleep 3; Shot 'c1_back'; $null=Ui 'c1_back'
Log ("fg after back: " + (Fg))
A shell "dumpsys activity activities | grep -i -E 'mResumedActivity|pinned|Pinned' | head -4" | ForEach-Object { Log $_ }
A logcat -c | Out-Null
GoHome
TapText '^Truyện tr' | Out-Null; Start-Sleep 2
for($i=1;$i -le 5;$i++){ Tap 1187 343; Start-Sleep -Milliseconds 1400; if($i -eq 1){ Shot 'c1_libsheet'; $null=Ui 'c1_libsheet' }; Back; Start-Sleep -Milliseconds 900 }
Shot 'c1_lib_after'
Log ("fg: " + (Fg))
# reader
TapText 'Duy.t Tab 4' | Out-Null; Start-Sleep 3
TapText '^MangaDex Ti' | Out-Null; Start-Sleep 12
Tap 1020 181; Start-Sleep 2
A shell input text 'Shirley' | Out-Null; Start-Sleep 1; Key 66; Start-Sleep 8
Tap 360 1000; Start-Sleep 6
$m=Find 'Vol.2 Ch.11'; if($m){ Tap 500 (($m.Y1+$m.Y2)/2) } else { Log 'NOCH11' }
Start-Sleep 10; Shot 'c1_reader'
Tap 720 1480; Start-Sleep 2; Shot 'c1_reader_menu'; $null=Ui 'c1_reader_menu'
for($i=1;$i -le 5;$i++){
  Tap 1250 2679; Start-Sleep -Milliseconds 1500
  if($i -eq 1){ Shot 'c1_rsheet'; $null=Ui 'c1_rsheet' }
  Back; Start-Sleep -Milliseconds 1000
  if(-not (Find 'Quay lại')){ Tap 720 1480; Start-Sleep -Milliseconds 1200 }
}
Shot 'c1_reader_after'
A logcat -d > "$EV\c1_logcat.txt"
Log ("fg: " + (Fg))
