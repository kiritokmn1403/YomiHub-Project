# Fetches every request listed in dev\missing.txt and records it in dev\fixtures.json
$D = 'D:\Claude A.I\dev'
New-Item -ItemType Directory -Force "$D\fx" | Out-Null
$map = @{}
if (Test-Path "$D\fixtures.json") {
  (Get-Content "$D\fixtures.json" -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $map[$_.Name] = $_.Value }
}
$doh = 'https://1.1.1.1/dns-query'
foreach ($line in Get-Content "$D\missing.txt" -Encoding UTF8) {
  if (-not $line.Trim()) { continue }
  $r = $line | ConvertFrom-Json
  $k = $r.key
  $bodyJson = $r.bodyText
  $sha = [BitConverter]::ToString((New-Object Security.Cryptography.SHA1Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($k))).Replace('-','').Substring(0,16)
  $file = "fx_$sha.txt"
  $args2 = @('-sS','-L','-m','60','--compressed','-o',"$D\fx\$file",'-w','%{http_code}')
  if ($r.url -match 'pornhub|fikfap') { $args2 += @('--doh-url',$doh) }
  if ($r.headers) { $r.headers.PSObject.Properties | ForEach-Object { $args2 += @('-H', "$($_.Name): $($_.Value)") } }
  if ($r.method -eq 'POST') {
    [IO.File]::WriteAllText("$D\fx\body_$sha.json", $bodyJson, (New-Object Text.UTF8Encoding $false))
    $args2 += @('-X','POST','-H','Content-Type: application/json','--data-binary',"@$D\fx\body_$sha.json")
  }
  $code = & curl.exe @args2 $r.url
  "$code $k"
  $map[$k] = @{ file = $file; status = [int]$code }
}
$map | ConvertTo-Json -Depth 5 | Set-Content "$D\fixtures.json" -Encoding UTF8
