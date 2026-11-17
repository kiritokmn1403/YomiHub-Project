# Tao junction D:\Claude A.I va D:\yh tro toi vi tri moi trong D:\A.I Project (khi thu muc da duoc chuyen).
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pairs = @(@('D:\Claude A.I', $root), @('D:\yh', (Join-Path (Split-Path -Parent $root) 'yh')))
foreach ($p in $pairs) {
  $link = $p[0]; $target = $p[1]
  if (-not (Test-Path $target)) { continue }
  if ((Resolve-Path $target).Path -ieq $link) { continue }
  if (Test-Path $link) {
    $it = Get-Item $link -Force
    if ($it.LinkType) { if ((@($it.Target)[0]) -ieq $target -and (Test-Path "$link\")) { continue }; cmd /c rmdir "$link"; New-Item -ItemType Junction -Path $link -Target $target | Out-Null; Write-Host "Junction $link -> $target (sua)"; continue }
    $files = @(Get-ChildItem $link -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike 'runner*_alive.txt' })
    if ($files.Count -gt 0) { Write-Host "Giu nguyen $link (co $($files.Count) tep)" -ForegroundColor Yellow; continue }
    Remove-Item $link -Recurse -Force
  }
  New-Item -ItemType Junction -Path $link -Target $target | Out-Null
  Write-Host "Junction $link -> $target" -ForegroundColor Green
}
