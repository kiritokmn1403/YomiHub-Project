$X='D:\Claude A.I\dev\x020'
$ua='Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36'
$j="$X\fx\jar.txt"; Remove-Item $j -ErrorAction SilentlyContinue
Get-Content "$X\fx\urls.txt" | Where-Object { $_ -match "`t" } | ForEach-Object {
  $n,$u = $_ -split "`t",2
  for ($i=0;$i -lt 2;$i++) { $r = & curl.exe -sL -m 40 -A $ua -b $j -c $j -D "$X\fx\$n.hdr" -H "Accept-Language: vi-VN,vi;q=0.9" -o "$X\fx\$n" -w "%{http_code} %{size_download} %{url_effective}" $u 2>&1; "$n try$i $r" }
}
Get-Content $j | Select-Object -Last 5
