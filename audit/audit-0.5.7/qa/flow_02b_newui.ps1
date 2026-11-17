# FLOW 2b: switch Old -> New app UI (Appearance), capture, then ALWAYS restore Old
GoMore
$null=MoreItem '^Cài đặt' '07_settings'
$null=MoreItem '^Giao diện' '02_appearance'
Swipe 720 2000 720 900 300; Start-Sleep 1
$ok=TapText '^Mới'; Start-Sleep 3; Shot '02_ui_new_appearance'; $null=Ui '02_ui_new_appearance'
Back; Start-Sleep 2; Back; Start-Sleep 3; Shot '02_ui_new_home'; $null=Ui '02_ui_new_home'
Tap 178 158; Start-Sleep 3; Shot '02_ui_new_lib'
Log ("fg " + (Fg))
