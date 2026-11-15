# FLOW 9: play Akujiki Reijou (anime) ep12 ~30s, back out, reopen -> resume position
GoHome
TapText '^Thư viện Tab 1' | Out-Null; Start-Sleep 2; Tap 577 158; Start-Sleep 3
if(-not (TapText 'Akujiki')){ Tap 1080 1000 }; Start-Sleep 5
Tap 500 2140; Start-Sleep 6; Shot '09_play_t06s'; Log (Fg)
Start-Sleep 10; Shot '09_play_t16s'; $null=Ui '09_play_t16'
