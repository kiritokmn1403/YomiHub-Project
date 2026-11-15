$EV="$QA\evidence\phone\qa1r"
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Swipe 720 2100 720 900 300; Start-Sleep 1; Swipe 720 2100 720 900 300; Start-Sleep 1
if(TapText '^Gi.i thi.u'){ Start-Sleep 3; Shot 'r13a_about'; $null=Ui 'r13a_about' }
