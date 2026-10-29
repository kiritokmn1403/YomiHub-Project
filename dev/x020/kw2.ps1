$D='D:\Claude A.I\dev\x020\fx'; $jar="$D\kwjar2.txt"; Remove-Item $jar -ErrorAction SilentlyContinue
$ua='Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36'
& curl.exe -s -m 30 -A $ua -c $jar -o "$D\kw_pre2.js" https://kwiky.com/api/state/v1/preload
$tok = [regex]::Match((Get-Content "$D\kw_pre2.js" -Raw),"meta.content = '([^']+)'").Groups[1].Value
$ck = @{}; Get-Content $jar | Where-Object { $_ -notmatch '^#' -and $_.Trim() } | ForEach-Object { $f = $_ -split "`t"; $ck[$f[5]] = $f[6] }
$u='https://kwiky.com/api/v1/gateway/v1/quickies/getKwikiesFromOnlinePerformers?page=1&size=3&gender=f'
foreach ($set in @('', 'smvid', 'smeid', 'smtid', 'consent', 'smeid,smtid,smvid')) {
  $c = ($set -split ',' | Where-Object { $_ } | ForEach-Object { "$_=$($ck[$_])" }) -join '; '
  $r = & curl.exe -s -m 30 -A $ua -H "Accept: application/json" -H "x-xsrf-token: $tok" -H "x-gateway: 76d59e04-97fa-4ced-aa99-b86ffaf756a2" -H "Cookie: $c" -o NUL -w "%{http_code}" $u
  "[$set] -> $r"
}
