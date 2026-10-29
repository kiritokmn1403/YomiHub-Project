$X='D:\Claude A.I\dev\x020\fx'; $j="$X\phjar.txt"; Remove-Item $j -ErrorAction SilentlyContinue
$ua='Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36'
& curl.exe -sL -m 40 -A $ua -b "accessAgeDisclaimerPH=1; age_verified=1" -c $j -o "$X\ph_s2.html" https://www.pornhub.com/shorties
$h = Get-Content "$X\ph_s2.html" -Raw
$tok = [regex]::Match($h,'var token = "([^"]+)"').Groups[1].Value
$seed = [regex]::Match($h,'ddSeed = (\d+)').Groups[1].Value
$off = [regex]::Match($h,'ddOffset = (\d+)').Groups[1].Value
"tok=$($tok.Length) seed=$seed off=$off"
$u = "https://www.pornhub.com/shorties/get?token=$([uri]::EscapeDataString($tok))&offset=$([int]$off+10)&orientation=straight&seed=$seed"
& curl.exe -sL -m 40 -A $ua -b $j -b "accessAgeDisclaimerPH=1; age_verified=1" -H "X-Requested-With: XMLHttpRequest" -H "Accept: application/json" -e https://www.pornhub.com/shorties -o "$X\ph_get.json" -w "%{http_code} %{size_download}`n" $u
(Get-Content "$X\ph_get.json" -Raw).Substring(0, [Math]::Min(1500,(Get-Item "$X\ph_get.json").Length))
