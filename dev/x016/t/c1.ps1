function Alive { $p = (& $ADB shell pidof $PKG) ; "pid=$p" }
function Scroll { & $ADB shell input swipe 540 1700 540 600 400; Start-Sleep 1 }
Reset
Tap 1012 2170 3
Scroll; Scroll; Scroll
TapText '^VPN & DNS$' 3
Shot 'c1_hub'
L 25
TapText 'ứng dụng ngoài' 3
L 20
TapText '^Toàn bộ thiết bị$' 3
Shot 'c1_apps'
Back
TapText '^Dịch vụ VPN$' 3
L 30
Shot 'c1_services'
