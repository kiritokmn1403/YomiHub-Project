# Shared helpers for YomiHub emulator tests
$SDK = "$env:LOCALAPPDATA\Android\Sdk"
$ADB = "$SDK\platform-tools\adb.exe"
$EMU = "$SDK\emulator\emulator.exe"
$T = 'D:\Claude A.I\dev\x018\t'
New-Item -ItemType Directory -Force "$T\shots" | Out-Null
$PKG = 'com.yomihub.app'
function Adb { & $ADB @args 2>&1 | ForEach-Object { "$_" } }
function Shot($name) {
  $tmp = "/sdcard/yh_shot.png"
  & $ADB shell screencap -p $tmp | Out-Null
  & $ADB pull $tmp "$T\shots\$name.png" 2>&1 | Out-Null
  "shot $name"
}
function Tap($x, $y, $wait = 2) { & $ADB shell input tap $x $y; Start-Sleep $wait }
function Back($wait = 2) { & $ADB shell input keyevent 4; Start-Sleep $wait }
function TypeText($s) { & $ADB shell input text ($s -replace ' ', '%s'); Start-Sleep 1 }
function Dump($name) {
  & $ADB shell uiautomator dump /sdcard/yh_ui.xml | Out-Null
  & $ADB pull /sdcard/yh_ui.xml "$T\shots\$name.xml" 2>&1 | Out-Null
}
function EnsureEmulator {
  $state = ((& $ADB get-state 2>&1) -join '').Trim()
  if ($state -ne 'device') {
    "starting emulator"
    $cmd = '"' + $EMU + '" -avd Medium_Phone_API_37.0 -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -dns-server 8.8.8.8,1.1.1.1'
    Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } | Out-Null
    for ($i = 0; $i -lt 60; $i++) { if (((& $ADB devices) -join ' ') -match 'emulator-\d+\s+device') { break }; Start-Sleep 5 }
    if (((& $ADB get-state 2>&1) -join '').Trim() -ne 'device') { "EMULATOR DID NOT START"; Get-Content "$T\emu_err.txt" -ErrorAction SilentlyContinue | Select-Object -Last 15; return $false }
  }
  $t0 = Get-Date
  while (((& $ADB shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
    if (((Get-Date) - $t0).TotalSeconds -gt 300) { "BOOT TIMEOUT"; Get-Content "$T\emu_err.txt" -ErrorAction SilentlyContinue | Select-Object -Last 15; return $false }
    Start-Sleep 5
  }
  "booted after $([int]((Get-Date) - $t0).TotalSeconds)s"
  & $ADB shell settings put global window_animation_scale 0
  & $ADB shell settings put global transition_animation_scale 0
  & $ADB shell settings put global animator_duration_scale 0
  & $ADB shell wm size
  return $true
}

function Get-UiXml {
  & $ADB shell uiautomator dump /sdcard/yh_ui.xml 2>&1 | Out-Null
  & $ADB pull /sdcard/yh_ui.xml "$T\ui_tmp.xml" 2>&1 | Out-Null
  return [IO.File]::ReadAllText("$T\ui_tmp.xml", [Text.Encoding]::UTF8)
}
function Find-Node($pattern) {
  $xml = Get-UiXml
  $ms = [regex]::Matches($xml, '<node [^>]*>')
  foreach ($m in $ms) {
    $node = $m.Value
    $labels = [regex]::Matches($node, '(?:text|content-desc)="([^"]*)"') | ForEach-Object { [Net.WebUtility]::HtmlDecode($_.Groups[1].Value) }
    foreach ($l in $labels) {
      if ($l -and $l -match $pattern) {
        $b = [regex]::Match($node, 'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
        return @{ label = $l; x = [int](([int]$b.Groups[1].Value + [int]$b.Groups[3].Value) / 2); y = [int](([int]$b.Groups[2].Value + [int]$b.Groups[4].Value) / 2) }
      }
    }
  }
  return $null
}
function TapText($pattern, $wait = 3) {
  $n = Find-Node $pattern
  if ($n) { Write-Host "tap '$($n.label)' at $($n.x),$($n.y)"; & $ADB shell input tap $n.x $n.y; Start-Sleep $wait; return $true }
  Write-Host "NOT FOUND: $pattern"; return $false
}
function Labels($name) {
  $xml = Get-UiXml
  [IO.File]::WriteAllText("$T\shots\$name.xml", $xml, [Text.Encoding]::UTF8)
  "--- labels $name ---"
  [regex]::Matches($xml, '<node [^>]*>') | ForEach-Object {
    $node = $_.Value
    $b = [regex]::Match($node, 'bounds="([^"]+)"').Groups[1].Value
    [regex]::Matches($node, '(?:text|content-desc)="([^"]+)"') | ForEach-Object { "$([Net.WebUtility]::HtmlDecode($_.Groups[1].Value)) @ $b" }
  }
}
function Crash {
  $p = ((& $ADB shell pidof $PKG) -join '').Trim()
  "app pid: $p"
  $c = & $ADB logcat -d -b crash 2>&1 | Select-String -Pattern 'yomihub' -Context 0,25
  if ($c) { "--- APP CRASH ---"; $c | ForEach-Object { "$_" } | Select-Object -Last 80 }
  & $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'E/flutter|I/flutter|Unhandled Exception|YomiVpn|TorService|WireGuard' | Select-Object -Last 50 | ForEach-Object { "$_" }
}
