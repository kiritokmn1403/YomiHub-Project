$f = "D:\A.I Project\A.I Project - YomiHub Project\logs\flutter_build_tv.txt"
if (Test-Path $f) {
    $fs = [System.IO.FileStream]::new($f, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $sr = [System.IO.StreamReader]::new($fs, [System.Text.Encoding]::UTF8)
    $txt = $sr.ReadToEnd()
    $sr.Close()
    $fs.Close()
    $lines = $txt -split "`r?`n"
    Write-Host "--- flutter_build_tv.txt (Lines $($lines.Count)) Last 10: ---"
    $lines[-10..-1] | ForEach-Object { Write-Host $_ }
}

$fw = "D:\A.I Project\A.I Project - YomiHub Project\logs\win_bridge.txt"
if (Test-Path $fw) {
    $fs = [System.IO.FileStream]::new($fw, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $sr = [System.IO.StreamReader]::new($fs, [System.Text.Encoding]::UTF8)
    $txt = $sr.ReadToEnd()
    $sr.Close()
    $fs.Close()
    $lines = $txt -split "`r?`n"
    Write-Host "--- win_bridge.txt (Lines $($lines.Count)) Last 5: ---"
    $lines[-5..-1] | ForEach-Object { Write-Host $_ }
}
