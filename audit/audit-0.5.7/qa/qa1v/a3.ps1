A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Duy.t Tab 4' | Out-Null; Start-Sleep 3
TapText '^MangaDex Ti' | Out-Null; Start-Sleep 12; Shot 'a3_mdx'; $null=Ui 'a3_mdx'
Get-Content "$EV\ui_a3_mdx.txt" -Encoding UTF8 | Select-Object -First 14
