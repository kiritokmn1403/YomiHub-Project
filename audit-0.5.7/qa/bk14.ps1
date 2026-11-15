$EV="$QA\evidence\backup"
Wake
ToMore; for($i=0;$i -lt 4 -and -not (Find 'Sao L.u & ..ng B'); $i++){ Swipe 720 2200 720 900 400; Start-Sleep 1 }
TapText 'Sao L.u & ..ng B' | Out-Null; Start-Sleep 3
Shot b14_section
TapText 'Kh.i ph.c b.n sao l.u' | Out-Null; Start-Sleep 4
Tap 1160 196; Start-Sleep 2
A shell input text pc | Out-Null; Start-Sleep 1
A shell input keyevent 66 | Out-Null; Start-Sleep 4
if (-not (TapText 'pc_.in\.backup')) { Log 'FILE NOT FOUND'; exit }
Start-Sleep 14
TapText '^Thay th' | Out-Null; Start-Sleep 5
for($k=0;$k -lt 4;$k++){ Ui b14_dlg | Out-Null; if (Find '^OK$') { TapText '^OK$' | Out-Null; Start-Sleep 4 } elseif (Find '^Thay th.$') { Shot b14_confirm; TapText '^Thay th.$' | Out-Null; Log 'CONFIRMED'; break } else { Start-Sleep 3 } }
Set-Content "$EV\b14_started.txt" (Get-Date -Format 'HH:mm:ss')
