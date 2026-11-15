$EV="$QA\evidence\backup"
ToMore
for($i=0;$i -lt 4 -and -not (Find 'Sao L.u & ..ng B'); $i++){ Swipe 720 2200 720 900 400; Start-Sleep 1 }
if (MoreItem 'Sao L.u & ..ng B' 'b1_backup_section') { Log 'opened Sao Luu & Dong Bo' }
