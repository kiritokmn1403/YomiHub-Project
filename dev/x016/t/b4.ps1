function Alive { $p = (& $ADB shell pidof $PKG) ; "pid=$p" }
function Scroll { & $ADB shell input swipe 540 1700 540 600 400; Start-Sleep 1 }
function Go($r) { & $ADB shell am start -a android.intent.action.VIEW -d "yomihub://open?route=$r" $PKG | Out-Null; Start-Sleep 4 }
Reset
Shot 'b4_home'
Go '/settings'
Shot 'b4_settings'
L 25
TapText 'Cloudflare Bypass Setting' 3
Shot 'b4_cf'
L 25
Back
Go '/appearance'
Scroll
Shot 'b4_appear'
L 30
Alive
