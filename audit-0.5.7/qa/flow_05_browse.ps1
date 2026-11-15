# FLOW 5/6: Duyet -> Nguon / Tien ich / De xuat; icons (filter sheet / repos)
GoHome
TapText '^187 Duyệt Tab 4' | Out-Null; Start-Sleep 4; Shot '05_browse_sources'
TapText '^Tiện ích \d+' | Out-Null; Start-Sleep 4; Shot '05_browse_ext'; $null=Ui '05_browse_ext'
Tap 1104 182; Start-Sleep 3; Shot '06_icon1'; $null=Ui '06_icon1'; Back; Start-Sleep 2
Tap 1272 182; Start-Sleep 3; Shot '06_icon2'; $null=Ui '06_icon2'; Back; Start-Sleep 2
TapText '^Đề xuất' | Out-Null; Start-Sleep 5; Shot '05_browse_suggest'; $null=Ui '05_browse_suggest'
