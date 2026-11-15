# FLOW 4b: open reader from Activity > History, then inspect
Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9
A logcat -c | Out-Null
TapText '^Hoạt đ' | Out-Null; Start-Sleep 3
TapText 'Lịch sử' | Out-Null; Start-Sleep 3; Shot '04b_history'
Tap 360 800; Start-Sleep 10; Shot '04b_reader_a'; $null=Ui '04b_reader_a'
Tap 720 1480; Start-Sleep 2; Shot '04b_reader_menu'; $null=Ui '04b_reader_menu'
Log ("fg " + (Fg))
