# FLOW 11 (Kiem Tra Cap Nhat) + 13 (Bao cao loi / Nhat Ky Ung Dung) from More > Gioi thieu
GoMore
Start-Sleep 3
for($k=0;$k -lt 3;$k++){ if(Find '^Phiên bản'){break}; TapText '^Giới thiệu' 0 1 | Out-Null; Start-Sleep 4 }
Shot '11_about'
if(TapText '^Kiểm tra cập nhật$'){ Start-Sleep 2; Shot '11_update_check'; $null=Ui '11_update_check'; Start-Sleep 5 }
if(TapText '^Báo cáo lỗi'){ Start-Sleep 4; Shot '13_bugreports'; $null=Ui '13_bugreports'; Back; Start-Sleep 3 }
if(TapText '^Nhật ký ứng dụng'){ Start-Sleep 4; Shot '13_applog'; $null=Ui '13_applog'; Swipe 720 2000 720 900 300; Start-Sleep 1; Shot '13_applog_b'; $null=Ui '13_applog_b' } else { Log 'applog row missing' }
