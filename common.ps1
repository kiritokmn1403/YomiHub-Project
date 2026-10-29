# YomiHub build kit - shared settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$KIT = if ($PSScriptRoot) { $PSScriptRoot } else { 'D:\A.I Project\A.I Project - YomiHub Project' }
$YH    = if ($env:YH_ROOT) { $env:YH_ROOT } else { 'D:\yh' }  # 0.1.7: YH_ROOT=Y: (subst) for Windows builds
$TOOLS = "$YH\tools"
$LOGS  = "$KIT\logs"
New-Item -ItemType Directory -Force -Path $YH,$TOOLS,$LOGS | Out-Null
$env:JAVA_HOME        = "$TOOLS\jdk"
$env:ANDROID_HOME     = "$TOOLS\android-sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:RUSTUP_HOME      = "$TOOLS\rustup"
$env:CARGO_HOME       = "$TOOLS\cargo"
$env:PUB_CACHE        = "$YH\pub-cache"
$env:GRADLE_USER_HOME = "$YH\gradle-home"
$env:FLUTTER_ROOT     = "$TOOLS\flutter"
$env:GIT_CONFIG_GLOBAL = "$YH\.gitconfig"
$env:PATH = "$TOOLS\git\cmd;$TOOLS\mingw64\bin;$TOOLS\flutter\bin;$TOOLS\jdk\bin;$TOOLS\cargo\bin;$TOOLS\android-sdk\cmdline-tools\latest\bin;$TOOLS\android-sdk\platform-tools;" + $env:PATH

function Say($m) { $t = Get-Date -Format 'HH:mm:ss'; Write-Host "[$t] $m" -ForegroundColor Cyan; Add-Content "$LOGS\status.txt" "[$t] $m" }
function Get-File($url, $out) {
  for ($i=1; $i -le 4; $i++) {
    & curl.exe -L --fail --retry 3 -o $out $url
    if ($LASTEXITCODE -eq 0 -and (Test-Path $out)) { return }
    Say "  download retry $i : $url"; Start-Sleep 5
  }
  throw "Download failed: $url"
}
function Expand-To($zip, $dest) {
  $tmp = "$YH\_x"; if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  & tar.exe -xf $zip -C (New-Item -ItemType Directory -Force $tmp).FullName
  if ($LASTEXITCODE -ne 0) { Say "  tar warning (exit $LASTEXITCODE) for $zip - continuing" }
  $items = Get-ChildItem $tmp
  $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $tmp }
  if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
  New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
  Move-Item $src $dest
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
}
# Segmented parallel download with resume (GitHub release CDN is slow per
# connection here, and its signed URLs expire after a few minutes).
function Get-FileFast($url, $out, [int]$parts = 16) {
  $final = (& curl.exe -sIL -o NUL -w "%{url_effective}" $url)
  $hdr = (& curl.exe -sI $final) -join "`n"
  $m = [regex]::Match($hdr, '(?im)^content-length:\s*(\d+)')
  if (-not $m.Success) { Get-File $url $out; return }
  $len = [int64]$m.Groups[1].Value
  $dir = "$out.parts"; if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }; New-Item -ItemType Directory -Force $dir | Out-Null
  $chunk = [int64][math]::Ceiling($len / $parts)
  for ($round = 1; $round -le 30; $round++) {
    if ($round -gt 1) { $final = (& curl.exe -sIL -o NUL -w "%{url_effective}" $url) }
    # curl config file: a command line with dozens of signed URLs is too long
    $cfg = New-Object System.Collections.Generic.List[string]
    $cfg.Add('parallel'); $cfg.Add('parallel-immediate'); $cfg.Add("parallel-max = $parts"); $n = 0
    for ($i=0; $i -lt $parts; $i++) {
      $a = $i*$chunk; $b = [math]::Min($len-1, $a+$chunk-1); $need = $b - $a + 1
      $have = 0; Get-ChildItem $dir -Filter "p$i.*" | ForEach-Object { $have += $_.Length }
      if ($have -ge $need) { continue }
      if ($n -gt 0) { $cfg.Add('next') }
      $cfg.Add('silent'); $cfg.Add('show-error'); $cfg.Add('http1.1'); $cfg.Add('fail'); $cfg.Add('max-time = 240')
      $cfg.Add("range = $($a+$have)-$b"); $cfg.Add(('output = "{0}"' -f ("$dir\p$i.$round" -replace '\\','/')))
      $cfg.Add(('url = "{0}"' -f $final)); $n++
    }
    if ($n -eq 0) { break }
    $got = 0; Get-ChildItem $dir -Filter 'p*' | ForEach-Object { $got += $_.Length }
    Say ("  round {0}: {1:N1}/{2:N1} MB, {3} parts left" -f $round, ($got/1MB), ($len/1MB), $n)
    [IO.File]::WriteAllLines("$dir\curl.cfg", $cfg)
    & curl.exe -K "$dir\curl.cfg" 2>$null
  }
  $fs = [IO.File]::Create($out)
  for ($i=0; $i -lt $parts; $i++) {
    Get-ChildItem $dir -Filter "p$i.*" | Sort-Object { [int]($_.Extension.TrimStart('.')) } | ForEach-Object {
      $bytes = [IO.File]::ReadAllBytes($_.FullName); $fs.Write($bytes,0,$bytes.Length) }
  }
  $fs.Close(); Remove-Item $dir -Recurse -Force
  if ((Get-Item $out).Length -ne $len) { throw "Size mismatch for $url" }
}
function Gh-Api($path) { Invoke-RestMethod -Headers @{ 'User-Agent'='yomihub-kit' } "https://api.github.com/$path" }
