$EV="$QA\evidence\phone\qa1r"
Swipe 720 2100 720 900 300; Start-Sleep 1; Swipe 720 2100 720 900 300; Start-Sleep 1
if(TapText '^C.i .+t$'){ Start-Sleep 3; Shot 'r07d_settings'; $null=Ui 'r07d_settings' }
