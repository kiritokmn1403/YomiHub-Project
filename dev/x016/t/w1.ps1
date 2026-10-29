$exe = 'D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe'
"exe: $((Get-Item $exe).Length) $((Get-Item $exe).VersionInfo.ProductName) $((Get-Item $exe).VersionInfo.FileDescription)"
Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
"docs before: " + (Test-Path "$env:USERPROFILE\Documents\YomiHub") + " / Mangayomi: " + (Test-Path "$env:USERPROFILE\Documents\Mangayomi\databases\yomihub_prefs.hive")
$docs = [Environment]::GetFolderPath('MyDocuments'); "mydocs=$docs"
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$exe`"" } | Out-Null
Start-Sleep 4; $bmpA=1; Start-Sleep 14
$p = Get-Process YomiHub -ErrorAction SilentlyContinue
"proc: $($p.Id) title='$($p.MainWindowTitle)' mem=$([int]($p.WorkingSet64/1MB))MB"
Get-ChildItem "$docs\YomiHub" -ErrorAction SilentlyContinue | ForEach-Object { "  YomiHub\$($_.Name)" }
Get-ChildItem "$docs\YomiHub\databases" -ErrorAction SilentlyContinue | Select-Object -First 8 | ForEach-Object { "  db\$($_.Name) $($_.Length)" }
Get-ItemProperty 'HKCU:\Software\Classes\yomihub\shell\open\command' -ErrorAction SilentlyContinue | ForEach-Object { "proto yomihub: $($_.'(default)')" }
Get-ItemProperty 'HKCU:\Software\Classes\mangayomi\shell\open\command' -ErrorAction SilentlyContinue | ForEach-Object { "proto mangayomi: $($_.'(default)')" }
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save('D:\Claude A.I\test\shots\win016_a.png'); "screen saved $($b.Width)x$($b.Height)"
"alive after 18s: $([bool](Get-Process YomiHub -ErrorAction SilentlyContinue))"
