Tap 500 2175; Start-Sleep 10; Shot 'b8_t10'; $null=Ui 'b8_t10'
Start-Sleep 25; Shot 'b8_t35'; $null=Ui 'b8_t35'
Get-Content "$EV\ui_b8_t35.txt" -Encoding UTF8 | Select-Object -First 20
