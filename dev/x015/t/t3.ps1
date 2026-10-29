# T3: turn Tor on, then WARP -> expect exclusivity dialog
TapText '^Tor$' 2
TapText 'Bật Tor' 4
Shot 't3_tor_on'
& $ADB shell input swipe 540 1600 540 600 300; Start-Sleep 1
TapText '^Cloudflare WARP$' 2
TapText '^Bật WARP' 3
Shot 't3_dialog'
L 30
