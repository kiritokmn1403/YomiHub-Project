$EV="$QA\evidence\phone\qa1r"
A shell cmd statusbar collapse | Out-Null; Key 3; Start-Sleep 1
GoHome; Shot 'r09g_home'
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Tap 720 364; Start-Sleep 3; Shot 'r09g_hist'
Tap 1080 1000; Start-Sleep 12; Shot 'r09g_t12'; $null=Ui 'r09g_t12'
Start-Sleep 10; Shot 'r09g_t22'
