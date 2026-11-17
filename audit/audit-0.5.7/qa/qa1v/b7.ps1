Tap 360 1000; Start-Sleep 8; Shot 'b7_detail'; $null=Ui 'b7_detail'
Get-Content "$EV\ui_b7_detail.txt" -Encoding UTF8 | Select-Object -First 30
