param(
    [string]$name = "screenshot.png"
)

. "$PSScriptRoot\common.ps1"
$scDir = "D:\A.I Project\YomiHub Project\output\screenshots"
$artDir = "C:\Users\nguye\.gemini\antigravity\brain\48d96891-e7f0-4019-8457-b8aa7a4f496a"

New-Item -ItemType Directory -Force -Path $scDir | Out-Null
New-Item -ItemType Directory -Force -Path $artDir | Out-Null

$outFile = "$scDir\$name"
$artFile = "$artDir\$name"

& "$TOOLS\android-sdk\platform-tools\adb.exe" shell screencap -p /sdcard/sc.png
& "$TOOLS\android-sdk\platform-tools\adb.exe" pull /sdcard/sc.png "$outFile" | Out-Null
& "$TOOLS\android-sdk\platform-tools\adb.exe" shell rm /sdcard/sc.png

if (Test-Path $outFile) {
    Copy-Item $outFile $artFile -Force
    Write-Host "Captured $name ($((Get-Item $outFile).Length) bytes)"
} else {
    Write-Warning "Failed to capture $name"
}
