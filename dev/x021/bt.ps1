$b = 'D:\Claude A.I\dev\x021\bridge\yomihub_bridge\build\install\yomihub-bridge'
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'yomihub.bridge.MainKt' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
$data = 'D:\Claude A.I\dev\x021\bdata'; New-Item -ItemType Directory -Force $data | Out-Null
$cmd = "cmd.exe /c `"`"D:\yh\win_deps\mesjre\jre\jre\bin\java.exe`" -cp `"$b\lib\*`" yomihub.bridge.MainKt --data `"$data`" > `"$data\out.log`" 2>&1`""
$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd }
"pid $($r.ProcessId)"
for ($i=0; $i -lt 30; $i++) { Start-Sleep 1; try { $p = Invoke-RestMethod -TimeoutSec 3 http://127.0.0.1:47350/kotatsu/ping; break } catch {} }
"ping: $($p | ConvertTo-Json -Compress)"
$t0 = Get-Date
$l = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 "http://127.0.0.1:47350/kotatsu/list?source=TRUYENQQ&kind=popular&page=1"
"truyenqq list $($l.StatusCode) $([int]((Get-Date)-$t0).TotalSeconds)s " + $l.Content.Substring(0, [Math]::Min(300, $l.Content.Length))
try { $l2 = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 "http://127.0.0.1:47350/kotatsu/list?source=MANGADEX&kind=popular&page=1"; "mangadex " + $l2.Content.Substring(0, 300) } catch { "mangadex err " + $_.ErrorDetails.Message }
$jar = "$data\ireader-en-allnovel.jar"
& curl.exe -s -L -o $jar https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/jar/ireader-en-allnovel-v2.1.jar
"jar $((Get-Item $jar).Length)"
try { $ld = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 ("http://127.0.0.1:47360/ireader/load?path=" + [uri]::EscapeDataString($jar)); "load " + $ld.Content } catch { "load err " + $_.ErrorDetails.Message }
Start-Sleep 1
Get-Content "D:\Claude A.I\dev\x021\bdata\out.log" -Tail 40
try { $ls = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 ("http://127.0.0.1:47360/ireader/sources"); $id = ($ls.Content | ConvertFrom-Json)[0]; "ir src $id"; $li = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 "http://127.0.0.1:47360/ireader/list?source=$id&kind=popular&page=1"; "ir list " + $li.Content.Substring(0, [Math]::Min(300,$li.Content.Length)) } catch { "ir err " + $_.ErrorDetails.Message + $_ }
