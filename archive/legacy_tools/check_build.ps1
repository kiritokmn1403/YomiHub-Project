$f = "D:\A.I Project\A.I Project - YomiHub Project\logs\flutter_build.txt"
if (Test-Path $f) {
    try {
        $fs = [System.IO.FileStream]::new($f, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $sr = [System.IO.StreamReader]::new($fs, [System.Text.Encoding]::UTF8)
        $txt = $sr.ReadToEnd()
        $sr.Close()
        $fs.Close()
        $lines = $txt -split "`r?`n"
        Write-Host "--- flutter_build.txt (Total $($lines.Count) lines) Last 15 lines: ---"
        $lines[-15..-1] | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Host "Error reading flutter_build: $_"
    }
}

$fw = "D:\A.I Project\A.I Project - YomiHub Project\logs\win_build.txt"
if (Test-Path $fw) {
    try {
        $fs2 = [System.IO.FileStream]::new($fw, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $sr2 = [System.IO.StreamReader]::new($fs2, [System.Text.Encoding]::UTF8)
        $txt2 = $sr2.ReadToEnd()
        $sr2.Close()
        $fs2.Close()
        $lines2 = $txt2 -split "`r?`n"
        Write-Host "--- win_build.txt (Total $($lines2.Count) lines) Last 15 lines: ---"
        $lines2[-15..-1] | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Host "Error reading win_build: $_"
    }
}
