# make_appxbundle.ps1: Build Windows .appx and .appxbundle for YomiHub 0.3.8
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing

$ver = ([regex]::Match((Get-Content "$KIT\overlay\pubspec.yaml" -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)')).Groups[1].Value
if (-not $ver) { throw 'Cannot read application version from overlay/pubspec.yaml' }
$verQuad = "$ver.0"
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
Export-Certificate -Cert $cert -FilePath "$out\YomiHub-RootCA.cer" | Out-Null
Say "Certificate exported: $out\YomiHub-RootCA.cer"

# 5) Pack .appx
$bundleDir = "$YH\buildwin\bundle_staging"
if (Test-Path $bundleDir) { Remove-Item $bundleDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null

$appxFile = "$bundleDir\YomiHub_${ver}_x64.appx"
& $makeappx pack /d $layout /p $appxFile /o
if ($LASTEXITCODE -ne 0) { throw "makeappx pack failed with exit code $LASTEXITCODE" }
Say "Created package: $appxFile"

# Sign .appx
& $signtool sign /fd SHA256 /a /f $pfxPath /p $pfxPass $appxFile
if ($LASTEXITCODE -ne 0) { throw "signtool sign .appx failed with exit code $LASTEXITCODE" }
Say "Signed .appx package"

# 6) Bundle into .appxbundle
$bundleFile = "$out\YomiHub-$ver-windows-x64.appxbundle"
if (Test-Path $bundleFile) { Remove-Item $bundleFile -Force }
& $makeappx bundle /d $bundleDir /p $bundleFile /o
if ($LASTEXITCODE -ne 0) { throw "makeappx bundle failed with exit code $LASTEXITCODE" }
Say "Created bundle: $bundleFile"

# Sign .appxbundle
& $signtool sign /fd SHA256 /a /f $pfxPath /p $pfxPass $bundleFile
if ($LASTEXITCODE -ne 0) { throw "signtool sign .appxbundle failed with exit code $LASTEXITCODE" }
Say ("APPXBUNDLE DONE: {0} ({1:N1} MB)" -f (Split-Path $bundleFile -Leaf), ((Get-Item $bundleFile).Length/1MB))

# Also create helper install script that permanently resolves 0x800B010A
$installScript = @"
# Install YomiHub AppX / AppXBundle
`$ErrorActionPreference = 'Stop'
Write-Host "Dang cai dat chung chi so YomiHub (Root & TrustedPeople)..." -ForegroundColor Cyan
`$cer = Join-Path `$PSScriptRoot "YomiHub-RootCA.cer"
if (Test-Path `$cer) {
    # Fix 0x800B010A: Import to BOTH Root (Trusted Root CAs) and TrustedPeople
    & certutil.exe -addstore -f Root `$cer | Out-Null
    & certutil.exe -addstore -f TrustedPeople `$cer | Out-Null
    Import-Certificate -FilePath `$cer -CertStoreLocation "Cert:\LocalMachine\Root" -ErrorAction SilentlyContinue | Out-Null
    Import-Certificate -FilePath `$cer -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" -ErrorAction SilentlyContinue | Out-Null
    Import-Certificate -FilePath `$cer -CertStoreLocation "Cert:\CurrentUser\Root" -ErrorAction SilentlyContinue | Out-Null
    Import-Certificate -FilePath `$cer -CertStoreLocation "Cert:\CurrentUser\TrustedPeople" -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "Dang cai dat YomiHub-$ver-windows-x64.appxbundle..." -ForegroundColor Green
Add-AppxPackage -Path (Join-Path `$PSScriptRoot "YomiHub-$ver-windows-x64.appxbundle")
Write-Host "Cai dat YomiHub thanh cong!" -ForegroundColor Green
"@
Set-Content -Path "$out\Install-YomiHub.ps1" -Value $installScript -Encoding UTF8

# Helper .bat that auto-elevates as administrator
$batScript = @"
@echo off
setlocal
cd /d "%~dp0"
echo ========================================================
echo   CAI DAT YOMIHUB $ver WINDOWS (.appxbundle)
echo ========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Dang yeu cau quyen Administrator de xac minh chung chi so...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~dpnx0\"\"' -Verb RunAs"
    exit /b
)
echo [1/2] Cai dat chung chi goc vao Root va TrustedPeople (Khac phuc 0x800B010A)...
certutil -addstore -f Root "YomiHub-RootCA.cer" >nul 2>&1
certutil -addstore -f TrustedPeople "YomiHub-RootCA.cer" >nul 2>&1

echo [2/2] Cai dat goi ung dung YomiHub...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-AppxPackage -Path '.\YomiHub-$ver-windows-x64.appxbundle'"

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo   CAI DAT HOAN TAT THANH CONG!
    echo ========================================================
) else (
    echo.
    echo Co loi xay ra trong qua trinh Add-AppxPackage.
)
pause
"@
Set-Content -Path "$out\Install-YomiHub.bat" -Value $batScript -Encoding ASCII
Say "Generated Install-YomiHub.bat and Install-YomiHub.ps1"
