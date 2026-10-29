param(
    [string]$name = "win_yomihub_v034.png"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots"
$artDir = "C:\Users\nguye\.gemini\antigravity\brain\1a3c0eed-bdc1-409b-992d-85c81d759828"

New-Item -ItemType Directory -Force -Path $scDir | Out-Null
New-Item -ItemType Directory -Force -Path $artDir | Out-Null

$outFile = "$scDir\$name"
$artFile = "$artDir\$name"

$exe = "D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe"

Write-Host "Launching YomiHub 0.3.4 for test verification..."
$proc = Start-Process -FilePath $exe -PassThru

# Wait for window to load and render
Start-Sleep -Seconds 7

# Capture entire primary screen or window
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

$bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bmp.Dispose()

# Close the test process
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

if (Test-Path $outFile) {
    Copy-Item $outFile $artFile -Force
    Write-Host "Captured Windows test screenshot: $name ($((Get-Item $outFile).Length) bytes)"
} else {
    Write-Warning "Failed to capture Windows screenshot"
}
