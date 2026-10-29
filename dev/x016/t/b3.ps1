function Alive { $p = (& $ADB shell pidof $PKG) ; "pid=$p" }
function Scroll { & $ADB shell input swipe 540 1700 540 500 400; Start-Sleep 1 }
function GoSettings { Reset; Tap 1012 2170 3; Scroll; Scroll; Scroll; Scroll; L 25; TapText '^Cài đặt$' 3 }
GoSettings
Shot 'b3_settings'
L 30
Scroll
L 30
TapText 'Cloudflare Bypass Setting' 3
Shot 'b3_cf'
L 30
Back
Alive
