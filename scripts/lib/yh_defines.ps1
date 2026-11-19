# yh_defines.ps1 - YomiHub 0.5.9: --dart-define cho dang nhap Google (doc secrets\google_oauth.json, KHONG commit)
function Get-YhDefines {
  $p = Join-Path 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project' 'secrets\google_oauth.json'
  if (-not (Test-Path $p)) { Write-Warning "Khong co $p - ban dung se khong co cau hinh dang nhap Google san"; return @() }
  $j = Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json
  return @(
    "--dart-define=YH_GOOGLE_TV_CLIENT_ID=$($j.android_tv_device_flow.client_id)",
    "--dart-define=YH_GOOGLE_TV_CLIENT_SECRET=$($j.android_tv_device_flow.client_secret)",
    "--dart-define=YH_GOOGLE_DESKTOP_CLIENT_ID=$($j.windows_desktop.client_id)",
    "--dart-define=YH_GOOGLE_DESKTOP_CLIENT_SECRET=$($j.windows_desktop.client_secret)"
  )
}
