$EV="$QA\evidence\phone\qa1r"
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Swipe 720 2100 720 900 300; Start-Sleep 1; Swipe 720 2100 720 900 300; Start-Sleep 1
if(TapText '^C.i .+t$'){ Start-Sleep 3; Shot 'r07e_settings'; $null=Ui 'r07e_settings' }
