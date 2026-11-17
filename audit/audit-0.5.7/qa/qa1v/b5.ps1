A shell "ping -c 2 -W 3 api.comick.fun" | ForEach-Object { Log $_ }
Back; Start-Sleep 2
Tap 500 2440; Start-Sleep 14; Shot 'b5_list'; $null=Ui 'b5_list'
Get-Content "$EV\ui_b5_list.txt" -Encoding UTF8 | Select-Object -First 16
