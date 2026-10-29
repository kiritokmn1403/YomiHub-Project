# timeout handled by fj5
function Scroll { & $ADB shell input swipe 540 1700 540 600 400; Start-Sleep 1 }
TapText '^Dịch vụ VPN' 3
L 30
TapText '^Tor' 2
L 30
TapText 'Bật Tor' 5
Shot 'c2_after_tap'
L 20
for ($i=0; $i -lt 24; $i++) {
  $n = Find-Node '^(OK|Đồng ý|Cho phép)$'
  if ($n) { "consent dialog -> tap $($n.label)"; & $ADB shell input tap $n.x $n.y; Start-Sleep 2 }
  $tun = (& $ADB shell ip addr show tun0 2>&1) -join ' '
  if ($tun -match 'inet ') { "TUN UP after $($i*5)s: $tun"; break }
  Start-Sleep 5
}
Shot 'c2_state'
L 20
& $ADB shell dumpsys connectivity 2>&1 | Select-String -Pattern 'VPN|tun0' | Select-Object -First 8 | ForEach-Object { "$_" }
& $ADB logcat -d -s YomiTorVpn:* AndroidRuntime:E | Select-Object -Last 20
