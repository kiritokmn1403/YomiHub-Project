# make_appxbundle_058.ps1: Build Windows .appx and .appxbundle for YomiHub 0.5.8
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing

$pubVer = ([regex]::Match((Get-Content "$KIT\overlay\pubspec.yaml" -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)')).Groups[1].Value
if ($pubVer -ne '0.5.8') { throw "overlay/pubspec.yaml là '$pubVer', kỳ vọng 0.5.8" }
$ver = '0.5.8'
$verQuad = "$ver.0"   # AppxManifest Version bắt buộc 4 phần (0.5.8.0)
$makeappx = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\makeappx.exe"
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
$rel = "$YH\buildwin\mangayomi\build\windows\x64\runner\Release"
$out = "$KIT\output"

if (-not (Test-Path "$rel\YomiHub.exe")) {
    throw "Windows release build not found at $rel\YomiHub.exe. Run build_win.ps1 first."
}

Say "APPXBUILD START: Packaging YomiHub $ver into .appxbundle"

$layout = "$YH\buildwin\appx_layout"
if (Test-Path $layout) { Remove-Item $layout -Recurse -Force }
New-Item -ItemType Directory -Force -Path $layout | Out-Null

# 1) Copy application files
& robocopy $rel $layout /MIR /NFL /NDL /NJH /NJS /NP /XD .git | Out-Null
Say "Copied release files to layout"

# 2) Generate required AppX visual assets
$assetsDir = "$layout\Assets"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

$srcIconPath = "$YH\buildwin\mangayomi\assets\app_icons\icon.png"
if (-not (Test-Path $srcIconPath)) {
    $srcIconPath = "$KIT\src\mangayomi\assets\app_icons\icon.png"
}
$srcImg = [System.Drawing.Image]::FromFile($srcIconPath)

function Resize-Icon($img, $w, $h, $dest) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

Resize-Icon $srcImg 50 50 "$assetsDir\StoreLogo.png"
Resize-Icon $srcImg 150 150 "$assetsDir\Square150x150Logo.png"
Resize-Icon $srcImg 44 44 "$assetsDir\Square44x44Logo.png"
Resize-Icon $srcImg 310 150 "$assetsDir\Wide310x150Logo.png"
Resize-Icon $srcImg 620 300 "$assetsDir\SplashScreen.png"
$srcImg.Dispose()
Say "Generated AppX assets in $assetsDir"

# 3) Generate AppxManifest.xml
$manifestContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Package
  xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities">
  <Identity
    Name="YomiHub"
    ProcessorArchitecture="x64"
    Publisher="CN=YomiHub, O=YomiHub, C=VN"
    Version="$verQuad" />
  <Properties>
    <DisplayName>YomiHub</DisplayName>
    <PublisherDisplayName>YomiHub Team</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
    <Description>YomiHub - Free, Open-Source Manga, Anime &amp; Novel Reader</Description>
  </Properties>
  <Resources>
    <Resource Language="en-US" />
    <Resource Language="vi-VN" />
  </Resources>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.14393.0" MaxVersionTested="10.0.26100.0" />
  </Dependencies>
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
  <Applications>
    <Application Id="App"
      Executable="YomiHub.exe"
      EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements
        DisplayName="YomiHub"
        Description="YomiHub - Free, Open-Source Manga, Anime &amp; Novel Reader"
        BackgroundColor="#1e1e2e"
        Square150x150Logo="Assets\Square150x150Logo.png"
        Square44x44Logo="Assets\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="Assets\Wide310x150Logo.png" />
        <uap:SplashScreen Image="Assets\SplashScreen.png" />
      </uap:VisualElements>
    </Application>
  </Applications>
</Package>
"@
Set-Content -Path "$layout\AppxManifest.xml" -Value $manifestContent -Encoding UTF8
Say "Generated AppxManifest.xml"

# 4) Certificate generation / export
$certSubject = "CN=YomiHub, O=YomiHub, C=VN"
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $certSubject } | Select-Object -First 1
if (-not $cert) {
    Say "Creating self-signed code-signing certificate for $certSubject"
    $cert = New-SelfSignedCertificate -Type Custom -Subject $certSubject `
        -KeyUsage DigitalSignature -FriendlyName "YomiHub AppX Certificate" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
}

$pfxPass = "YomiHub2026"
$secPass = ConvertTo-SecureString -String $pfxPass -Force -AsPlainText
$pfxPath = "$YH\buildwin\yomihub_appx.pfx"
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $secPass | Out-Null
Say "Exported PFX certificate to $pfxPath"

$cerPath = "$out\YomiHub-RootCA.cer"
Export-Certificate -Cert $cert -FilePath $cerPath -Force | Out-Null
Say "Exported public certificate to $cerPath"

# 5) Build single .appx package
$appxPath = "$YH\buildwin\yomihub_x64.appx"
if (Test-Path $appxPath) { Remove-Item $appxPath -Force }
Say "Running makeappx pack -> $appxPath"
& $makeappx pack /d $layout /p $appxPath /nv /o
if ($LASTEXITCODE -ne 0) { throw "makeappx pack failed (exit $LASTEXITCODE)" }

# 6) Sign the .appx
Say "Signing $appxPath"
& $signtool sign /fd SHA256 /a /f $pfxPath /p $pfxPass $appxPath
if ($LASTEXITCODE -ne 0) { throw "signtool sign failed on .appx (exit $LASTEXITCODE)" }

# 7) Build .appxbundle
$bundleStaging = "$YH\buildwin\bundle_staging"
if (Test-Path $bundleStaging) { Remove-Item $bundleStaging -Recurse -Force }
New-Item -ItemType Directory -Force -Path $bundleStaging | Out-Null
Copy-Item $appxPath "$bundleStaging\YomiHub_x64.appx"

$bundlePath = "$out\YomiHub-$ver-windows-x64.appxbundle"
if (Test-Path $bundlePath) { Remove-Item $bundlePath -Force }
Say "Running makeappx bundle -> $bundlePath"
& $makeappx bundle /d $bundleStaging /p $bundlePath /o /bv $verQuad
if ($LASTEXITCODE -ne 0) { throw "makeappx bundle failed (exit $LASTEXITCODE)" }

# 8) Sign the .appxbundle
Say "Signing $bundlePath"
& $signtool sign /fd SHA256 /a /f $pfxPath /p $pfxPass $bundlePath
if ($LASTEXITCODE -ne 0) { throw "signtool sign failed on .appxbundle (exit $LASTEXITCODE)" }

# 9) Helper install scripts
$installBat = "$out\Install-YomiHub.bat"
@"
@echo off
setlocal
echo ========================================================
echo   YomiHub Windows AppX Installer
echo ========================================================
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-YomiHub.ps1"
pause
"@ | Set-Content -Path $installBat -Encoding ASCII

$installPs1 = "$out\Install-YomiHub.ps1"
@"
# Install-YomiHub.ps1: Installs the certificate and AppX bundle
`$ErrorActionPreference = 'Stop'
Write-Host "--- YomiHub Windows AppX Installer ---" -ForegroundColor Cyan
`$dir = `$PSScriptRoot

# 1. Install certificate to Trusted People
`$cer = Join-Path `$dir "YomiHub-RootCA.cer"
if (Test-Path `$cer) {
    Write-Host "[1/2] Installing root certificate to Trusted People..." -ForegroundColor Yellow
    `$cert = Import-Certificate -FilePath `$cer -CertStoreLocation "Cert:\LocalMachine\TrustedPeople"
    Write-Host "      Installed: `$(`$cert.Subject)" -ForegroundColor Green
} else {
    Write-Host "[!] YomiHub-RootCA.cer not found, skipping certificate import." -ForegroundColor Red
}

# 2. Add AppX package
`$bundle = Get-ChildItem -Path `$dir -Filter "YomiHub-*-windows-x64.appxbundle" | Select-Object -First 1
if (`$bundle) {
    Write-Host "[2/2] Installing `$(`$bundle.Name)..." -ForegroundColor Yellow
    Add-AppxPackage -Path `$bundle.FullName
    Write-Host "      Installation complete! You can now launch YomiHub from the Start Menu." -ForegroundColor Green
} else {
    Write-Host "[!] AppX bundle not found in `$dir" -ForegroundColor Red
}
"@ | Set-Content -Path $installPs1 -Encoding UTF8

Say "APPXBUILD COMPLETE: Created $bundlePath ($([math]::Round((Get-Item $bundlePath).Length / 1MB, 2)) MB)"
Say "Created install scripts: $installBat, $installPs1"
