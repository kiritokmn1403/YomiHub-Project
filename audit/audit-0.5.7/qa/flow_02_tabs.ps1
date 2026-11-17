# FLOW 2: Library hub tabs (top tab bar is NOT in the uiautomator tree -> tap by coordinates, 1440x2960)
Wake; TapText 'Thư viện Tab 1' | Out-Null; Start-Sleep 2
# hub tab centers: Truyen tranh, Phim & Dien anh, Tieu thuyet, Play Books (y=158)
$tabs = @(@(178,'02_tab_truyen'),@(577,'02_tab_phim'),@(918,'02_tab_tieuthuyet'),@(1288,'02_tab_playbooks'),@(178,'02_tab_truyen_back'))
foreach($t in $tabs){ Tap $t[0] 158; Start-Sleep 3; Shot $t[1]; $null=Ui $t[1] }
