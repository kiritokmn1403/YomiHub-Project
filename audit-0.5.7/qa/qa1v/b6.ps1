GoHome
TapText 'Th. vi.n Tab 1' | Out-Null; Start-Sleep 4; Shot 'b6_lib'; $null=Ui 'b6_lib'
Get-Content "$EV\ui_b6_lib.txt" -Encoding UTF8 | Select-Object -First 22
