$F='D:\Claude A.I\dev\x020\h\fx'
$f = Get-ChildItem "$F\*.hdr" | Select-Object -First 1
$raw = Get-Content $f.FullName -Raw
"len $($raw.Length)"
$blocks = $raw -split "`r?`n`r?`n" | Where-Object { $_.Trim() -ne '' }
"blocks $($blocks.Count)"
$last = $blocks[-1]
"lastlen $($last.Length)"
$hd=@{}
foreach ($hl in ($last -split "`r?`n")) { if ($hl -match '^([^:]+):\s*(.*)$') { $k=$matches[1].ToLower(); $hd[$k]=$matches[2] } }
"keys: $($hd.Keys -join ',')"
