$ErrorActionPreference = 'Continue'
$W = 'D:\yh\wintest023'
Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
if (Test-Path $W) { Remove-Item $W -Recurse -Force -ErrorAction SilentlyContinue }
Expand-Archive 'D:\Claude A.I\output\YomiHub-0.2.3-windows-x64-full.zip' $W -Force
"files: " + (Get-ChildItem $W -Recurse -File | Measure-Object).Count
$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$W\YomiHub.exe`""; CurrentDirectory = $W }
"YomiHub pid $($r.ProcessId) rc $($r.ReturnValue)"
Start-Sleep 60
Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('YomiHub.exe','java.exe','javaw.exe') } | ForEach-Object { "$($_.ProcessId) $($_.Name) $([Math]::Round($_.WorkingSetSize/1MB)) MB  " + ($_.CommandLine -replace '.{0,0}(-cp .{60}).*', '$1') }
foreach ($u in 'http://127.0.0.1:47350/kotatsu/ping','http://127.0.0.1:47360/ireader/ping') { try { "$u -> " + (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 $u).Content } catch { "$u -> ERR $($_.Exception.Message)" } }
try { $l = Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 'http://127.0.0.1:47350/kotatsu/list?source=TRUYENQQ&kind=popular&page=1'; "truyenqq " + $l.Content.Substring(0,200) } catch { "tq err $($_.Exception.Message)" }
$docs = [Environment]::GetFolderPath('MyDocuments')
$log = Get-ChildItem "$docs\YomiHub" -Recurse -Filter 'logs.txt' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($log) { "log: $($log.FullName) $($log.LastWriteTime)"; Get-Content $log.FullName -Tail 25 -Encoding UTF8 }
$cr = Get-ChildItem "$docs\YomiHub" -Recurse -Filter 'crash_reports*' -ErrorAction SilentlyContinue | Select-Object -First 2
$cr | ForEach-Object { "crash file $($_.FullName) $($_.LastWriteTime)" }
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $b.Width,$b.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location,[System.Drawing.Point]::Empty,$b.Size); $bmp.Save('D:\Claude A.I\dev\x023\t\shots\win_run.png'); 'screenshot saved'
Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 8
"after close: " + ((Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'yomihub.bridge|wintest023' } | Measure-Object).Count) + " helper processes left"
