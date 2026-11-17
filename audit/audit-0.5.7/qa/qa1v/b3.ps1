Tap 500 1700; Start-Sleep 12; Shot 'b3_list'; $null=Ui 'b3_list'
Tap 360 1000; Start-Sleep 8; Shot 'b3_detail'; $null=Ui 'b3_detail'
Get-Content "$EV\ui_b3_detail.txt" -Encoding UTF8 | Select-Object -First 40
