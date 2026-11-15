# FLOW 4 (v2): library -> first comic detail -> chapter -> reader; network now OK
Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9
A logcat -c | Out-Null
Tap 360 1000; Start-Sleep 4; Shot '04_detail'
Tap 700 2175; Start-Sleep 12; Shot '04_reader_1'; $null=Ui '04_reader_1'
Tap 720 1480; Start-Sleep 2; Shot '04_reader_menu'; $null=Ui '04_reader_menu'
