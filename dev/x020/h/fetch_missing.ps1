# fetch every request in h\missing.txt into h\fx (+ index.json with status/headers)
$H='D:\Claude A.I\dev\x020\h'; $F="$H\fx"; New-Item -ItemType Directory -Force $F | Out-Null
$idxPath="$F\index.json"
$idx = @{}; if (Test-Path $idxPath) { (Get-Content $idxPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $idx[$_.Name] = $_.Value } }
$lines = @(Get-Content "$H\missing.txt" -Encoding UTF8 | Where-Object { $_.Trim() -ne '' })
foreach ($l in $lines) {
  $r = $l | ConvertFrom-Json
  $n = ([BitConverter]::ToString((New-Object Security.Cryptography.MD5CryptoServiceProvider).ComputeHash([Text.Encoding]::UTF8.GetBytes($r.key))) -replace '-','').Substring(0,16)
  $a = @('-s','-L','--compressed','-m','40','-o',"$F\$n.body",'-D',"$F\$n.hdr",'-w','%{http_code}')
  if ($r.headers) { $r.headers.psobject.Properties | ForEach-Object { $a += @('-H', "$($_.Name): $($_.Value)") } }
  if ($r.method -eq 'POST') { $a += @('-X','POST'); if ($r.body) { [IO.File]::WriteAllText("$F\$n.req", $r.body); $a += @('--data-binary',"@$F\$n.req") } }
  $code = & curl.exe @a $r.url 2>$null
  $hd = @{}
  if (Test-Path "$F\$n.hdr") {
    $raw = [IO.File]::ReadAllText("$F\$n.hdr")
    $blocks = @($raw -split "`r?`n`r?`n" | Where-Object { $_.Trim() -ne '' })
    if ($blocks.Count -gt 0) {
      foreach ($hl in ($blocks[$blocks.Count-1] -split "`r?`n")) { if ($hl -match '^([^:]+):\s*(.*)$') { $k=$matches[1].ToLower(); if ($hd.ContainsKey($k)) { $hd[$k] = $hd[$k] + ', ' + $matches[2] } else { $hd[$k] = $matches[2] } } }
    }
  }
  $idx[$r.key] = @{ file = "$n.body"; status = [int]$code; headers = $hd }
  "$code $($r.method) $($r.url)"
}
[IO.File]::WriteAllText($idxPath, ($idx | ConvertTo-Json -Depth 6))
