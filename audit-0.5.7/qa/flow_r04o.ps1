$EV="$QA\evidence\phone\qa1r"
Log ((A shell ping -c 2 -W 3 uploads.mangadex.org) -join ' | ')
Log ((A shell ping -c 2 -W 3 api.mangadex.org) -join ' | ')
Tap 1190 181; Start-Sleep 20; Shot 'r04o_reload'; $null=Ui 'r04o_reload'
