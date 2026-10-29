. 'D:\Claude A.I\dev\x018\t\c.ps1'
$l = & $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'flutter' | Select-String -NotMatch 'LocalLibraryScanner'
$i = 0; foreach ($x in $l) { if ("$x" -match '#0 ') { break }; $i++ }
$l[([Math]::Max(0,$i-25))..($i)] | ForEach-Object { "$_" }
