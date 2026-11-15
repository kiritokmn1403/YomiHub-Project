# FLOW 6: filter sheet in Nguon tab, language page overflow (repos?)
GoHome
TapText '^187 Duyệt Tab 4' | Out-Null; Start-Sleep 4
Tap 1272 182; Start-Sleep 3; Shot '06_sources_filter'; $null=Ui '06_sources_filter'; Back; Start-Sleep 2
Tap 1104 182; Start-Sleep 3; Shot '06_sources_icon1'; $null=Ui '06_sources_icon1'; Back; Start-Sleep 2
TapText '^Tiện ích \d+' | Out-Null; Start-Sleep 3
Tap 1272 182; Start-Sleep 3; Tap 1356 182; Start-Sleep 3; Shot '06_ext_overflow'; $null=Ui '06_ext_overflow'
