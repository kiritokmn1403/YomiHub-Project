# FLOW 5b: Settings > Bat/Tat tinh nang > Quan ly danh sach kho Truyen tranh (chevron row y~1222)
GoMore
$null=MoreItem '^Cài đặt' '05b_settings'
$null=MoreItem '^Bật/Tắt' '05b_features'
Tap 720 1222; Start-Sleep 4; Shot '05b_repo_list'; $null=Ui '05b_repo_list'
Swipe 720 2000 720 900 300; Start-Sleep 1; Shot '05b_repo_list_b'
