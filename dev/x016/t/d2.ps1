function Go($r) { & $ADB shell am start -a android.intent.action.VIEW -d "yomihub://open?route=$r" $PKG 2>&1 | Out-Null; Start-Sleep 4 }
Go '/settings'
Shot 'd2_settings'
TapText 'Cloudflare Bypass Setting' 3
Shot 'd2_cf'
L 30
Back
Back
Go '/extensionsRepo'
Start-Sleep 6
Shot 'd2_repo'
L 20
"pid=$(& $ADB shell pidof $PKG)"
