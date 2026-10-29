$ua='Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/140 Mobile Safari/537.36'
Get-Content 'D:\Claude A.I\dev\x020\fx\head.txt' | Where-Object { $_ -match '^http' } | ForEach-Object {
  $r = & curl.exe -s -r 0-1023 -o NUL -m 30 -A $ua -e $(([uri]$_).Scheme + '://' + ([uri]$_).Host + '/') -w "%{http_code} %{content_type} %{size_download}" $_
  "$r  $($_.Substring(0,[Math]::Min(110,$_.Length)))"
}
