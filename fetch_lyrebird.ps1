# fetch_lyrebird.ps1 – YomiHub 0.4.5: Tor pluggable transports (lyrebird) for Android.
# *.so is git-ignored, so the binaries are not in the repository. This script downloads
# the Tor Expert Bundle 16.0 for Android, checks the official SHA-256 sums and copies
# lyrebird into overlay\android\app\src\main\jniLibs\<abi>\liblyrebird.so.
$ErrorActionPreference = 'Stop'
$ver = '16.0'
$kit = $PSScriptRoot
$tmp = Join-Path $env:TEMP "yh_tor_$ver"; New-Item -ItemType Directory -Force $tmp | Out-Null
$sums = @{
  'aarch64' = 'bf8f4c63652fd7daa62288713c7fa512f244a5b972808f6251450e5fdfca9120'
  'armv7'   = '13befa352b64c32ba460b63066179bb1c9eaf6c3ea7057ae860dcdd22b8acf7b'
  'x86_64'  = 'ab3152ba164bcd49e50175086c62e40ffa2bf9002a4f6473f77111bd88b0462b'
}
$abi = @{ 'aarch64' = 'arm64-v8a'; 'armv7' = 'armeabi-v7a'; 'x86_64' = 'x86_64' }
foreach ($a in $sums.Keys) {
  $f = "tor-expert-bundle-android-$a-$ver.tar.gz"
  $p = Join-Path $tmp $f
  & curl.exe -s -L -m 300 -o $p "https://archive.torproject.org/tor-package-archive/torbrowser/$ver/$f"
  $h = (Get-FileHash $p -Algorithm SHA256).Hash.ToLower()
  if ($h -ne $sums[$a]) { throw "SHA-256 mismatch for $f" }
  $x = Join-Path $tmp $a; New-Item -ItemType Directory -Force $x | Out-Null
  & tar.exe -xzf $p -C $x
  $dst = Join-Path $kit "overlay\android\app\src\main\jniLibs\$($abi[$a])"
  New-Item -ItemType Directory -Force $dst | Out-Null
  Copy-Item (Join-Path $x 'tor\pluggable_transports\lyrebird') (Join-Path $dst 'liblyrebird.so') -Force
  "ok $($abi[$a])"
}
Copy-Item (Join-Path $tmp 'aarch64\tor\pluggable_transports\pt_config.json') (Join-Path $kit 'overlay\assets\yomihub_vpn\tor_pt_config.json') -Force
