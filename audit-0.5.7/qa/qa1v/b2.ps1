GoHome
TapText 'Duy.t Tab 4' | Out-Null; Start-Sleep 3; Shot 'b2_browse'; $null=Ui 'b2_browse'
Get-Content "$EV\ui_b2_browse.txt" -Encoding UTF8
