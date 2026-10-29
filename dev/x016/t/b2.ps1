function Alive { $p = (& $ADB shell pidof $PKG) ; "pid=$p" }
function Scroll { & $ADB shell input swipe 540 1700 540 700 300; Start-Sleep 1 }
Reset
Tap 1012 2170 3
Scroll; Scroll
TapText '^Cài đặt$' 3
Shot 'b2_settings'
L 30
Scroll
TapText 'Cloudflare Bypass Setting' 3
Shot 'b2_cf'
L 30
Back
Alive
