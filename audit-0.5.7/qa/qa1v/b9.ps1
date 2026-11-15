Tap 720 1858; Start-Sleep 4; Shot 'b9_retry'; $null=Ui 'b9_retry'
Get-Content "$EV\ui_b9_retry.txt" -Encoding UTF8 | ForEach-Object { $_.Substring(0,[Math]::Min(100,$_.Length)) }
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4
Tap 720 364; Start-Sleep 3; Shot 'b9_phim'; $null=Ui 'b9_phim'
Get-Content "$EV\ui_b9_phim.txt" -Encoding UTF8 | ForEach-Object { $_.Substring(0,[Math]::Min(120,$_.Length)) }
