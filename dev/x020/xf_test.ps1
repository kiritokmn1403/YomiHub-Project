$X='D:\Claude A.I\dev\x020\fx'; $j="$X\xfjar.txt"; Remove-Item $j -ErrorAction SilentlyContinue
$ua='Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36'
& curl.exe -sL -m 40 -A $ua -c $j -o "$X\xf_home.html" -w "home %{http_code}`n" https://www.xfree.com/
foreach ($u in @('https://www.xfree.com/api/rs/homepage/?lgbt=1&device=mobile&limit=12','https://www.xfree.com/api/post/1350354','https://www.xfree.com/api/settings','https://www.xfree.com/api/tag/popular','https://www.xfree.com/search?q=blonde','https://www.xfree.com/post/1350354')) {
  & curl.exe -sL -m 40 -A $ua -b $j -c $j -H "Accept: application/json, text/plain, */*" -e https://www.xfree.com/ -o "$X\xf_t.json" -w "%{http_code} %{size_download} $u`n" $u
  (Get-Content "$X\xf_t.json" -Raw).Substring(0,[Math]::Min(200,(Get-Item "$X\xf_t.json").Length)); ""
}
Get-Content $j | Select-Object -Last 6
