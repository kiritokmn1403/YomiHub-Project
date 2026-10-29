$D='D:\Claude A.I\dev\x020\fx'; $jar="$D\kwjar.txt"; Remove-Item $jar -ErrorAction SilentlyContinue
$ua='Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36'
& curl.exe -s -m 30 -A $ua -c $jar -o "$D\kw_pre.js" https://kwiky.com/api/state/v1/preload
$tok = [regex]::Match((Get-Content "$D\kw_pre.js" -Raw),"meta.content = '([^']+)'").Groups[1].Value
foreach ($g in @('76d59e04-97fa-4ced-aa99-b86ffaf756a2')) {
foreach ($u in @('https://kwiky.com/api/v1/gateway/v1/quickies/metadata?quickieIds=8334ace9-3a7a-48ef-96ee-344c7c8d6a3e,d4667afc-6869-46a4-911c-54069b56e508&pagetype=feed&init=true','https://kwiky.com/api/v1/gateway/v1/quickies/getKwikiesFromOnlinePerformers?page=2&size=3&gender=f','https://kwiky.com/api/v1/gateway/v1/keywords/populartags')) {
  & curl.exe -s -m 30 -A $ua -b $jar -c $jar -H "Accept: application/json" -H "x-xsrf-token: $tok" -H "x-gateway: $g" -e https://kwiky.com/ -o "$D\kw_t.json" -w "%{http_code} %{size_download} $g $u`n" $u
  if (Test-Path "$D\kw_t.json") { $c = Get-Content "$D\kw_t.json" -Raw; if ($c) { $c.Substring(0,[Math]::Min(900,$c.Length)) } }; ""
}}
