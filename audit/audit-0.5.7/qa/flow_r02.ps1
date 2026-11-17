$EV="$QA\evidence\phone\qa1r"
# FLOW 2b: switch Old -> New app UI (Appearance), capture, then ALWAYS restore Old
GoMore
$null=MoreItem '^Cài đặt' 'r07_settings'
$null=MoreItem '^Giao diện' 'r02_appearance'
Swipe 720 2000 720 900 300; Start-Sleep 1
$ok=TapText '^Mới'; Start-Sleep 3; Shot 'r02_ui_new_appearance'; $null=Ui 'r02_ui_new_appearance'
Back; Start-Sleep 2; Back; Start-Sleep 3; Shot 'r02_ui_new_home'; $null=Ui 'r02_ui_new_home'
Tap 178 158; Start-Sleep 3; Shot 'r02_ui_new_lib'
Log ("fg " + (Fg))
# FLOW 2c: RESTORE Old UI via Settings > Giao dien (new UI More page: Cai dat at ~y2250 after swipe)
Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9
for($i=0;$i -lt 4;$i++){ if(Find '^Thêm Thêm'){break}; Back; Start-Sleep 2 }
TapText '^Thêm Thêm' | Out-Null; Start-Sleep 4
Swipe 720 2200 720 400 500; Start-Sleep 2
Tap 720 2250; Start-Sleep 4
$null=MoreItem '^Giao diện' 'r02c_appearance'
Swipe 720 2000 720 900 300; Start-Sleep 2
TapText '^Cũ' | Out-Null; Start-Sleep 3; Shot 'r02_ui_restored_old'
Back; Start-Sleep 1; Back; Start-Sleep 3; Shot 'r02_ui_old_home'
$null=Ui 'r02_ui_old_home'
