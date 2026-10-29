param([string]$list)
$out = 'D:\Claude A.I\dev\x021\net'
foreach ($line in Get-Content $list) {
  if (-not $line.Trim()) { continue }
  $name, $url = $line -split ' ', 2
  & curl.exe -s -L -m 40 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36" -o "$out\$name" -w "$name %{http_code} %{size_download} %{url_effective}`n" $url
}
