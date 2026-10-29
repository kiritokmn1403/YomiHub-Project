Tap 1012 2170 3; TapText "^Trình duyệt$" 5
Start-Sleep 5
Shot 't9_browser0'
$n = Find-Node 'Tìm kiếm|URL|search'
"addr: $($n.label)"
Tap 500 137 1
& $ADB shell input text "https://www.w3schools.com/html/html5_video.asp"
& $ADB shell input keyevent 66
Start-Sleep 12
Shot 't9_page'
L 25
$fab = Find-Node 'Savior'
"fab: $($fab.label) $($fab.x),$($fab.y)"
if ($fab) { & $ADB shell input tap $fab.x $fab.y; Start-Sleep 2; Shot 't9_sheet'; L 20 }
