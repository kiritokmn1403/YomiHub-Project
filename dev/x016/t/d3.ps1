function Scroll { & $ADB shell input swipe 540 1700 540 600 400; Start-Sleep 1 }
Reset
Tap 1012 2170 3
Scroll; Scroll; Scroll
L 20
TapText '^Cài đặt$' 3
Scroll
L 25
TapText 'Cloudflare Bypass Setting' 3
Shot 'd3_cf'
L 30
"pid=$(& $ADB shell pidof $PKG)"
