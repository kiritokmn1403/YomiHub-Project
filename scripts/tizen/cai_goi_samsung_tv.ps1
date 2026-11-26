# cai_goi_samsung_tv.ps1 - YomiHub 0.6.7: cai goi TV + Samsung Certificate Extension cho Tizen Studio (D:\tizen-studio).
# package-manager-cli.exe can quyen Administrator: chu du an chay tep .bat cung thu muc (tu hien hop UAC).
# Khong chua mat khau/token. Nhat ky: audit\audit-0.6.7\release\tizen\cai_goi_samsung_tv.log
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$log = Join-Path $root 'audit\audit-0.6.7\release\tizen\cai_goi_samsung_tv.log'
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
Start-Transcript -Path $log -Append | Out-Null
$pm = 'D:\tizen-studio\package-manager\package-manager-cli.exe'
if (-not (Test-Path $pm)) { Write-Host "Chua co Tizen Studio o D:\tizen-studio"; Stop-Transcript | Out-Null; Read-Host 'Enter de dong'; exit 1 }
Write-Host '=== Bat kho mo rong Samsung ==='
$extra = & $pm extra --list 2>&1
$extra | Write-Host
foreach ($name in @('Samsung Certificate Extension', 'Samsung Tizen TV SDK', 'TV Extensions')) {
  if ($extra -match [regex]::Escape($name)) { & $pm extra --activate --name $name 2>&1 | Write-Host }
}
Write-Host '=== Danh sach goi ==='
$pkgs = & $pm show-pkgs --no-java-check 2>&1
$pkgs | Write-Host
$want = @()
foreach ($line in $pkgs) {
  $t = ($line -split '\s+') | Where-Object { $_ }
  foreach ($w in $t) { if ($w -match '^(cert-add-on|Certificate-Manager|TV-SAMSUNG[-\w\.]*|Samsung-Certificate[-\w\.]*|WebCLI|TOOLS)$') { $want += $w } }
}
$want = $want | Select-Object -Unique
Write-Host ('=== Cai: ' + ($want -join ', ') + ' ===')
if ($want.Count -gt 0) { & $pm install --accept-license --no-java-check @want 2>&1 | Write-Host }
Write-Host '=== XONG ==='
Stop-Transcript | Out-Null
Read-Host 'Da cai xong. Nhan Enter de dong cua so'
