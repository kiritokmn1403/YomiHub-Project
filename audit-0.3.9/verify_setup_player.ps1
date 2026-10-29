$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$setup = Join-Path $project 'output/YomiHub-0.3.9-windows-x64-Setup.exe'
$zip = Join-Path $project 'output/YomiHub-0.3.9-windows-x64.zip'
$assembly = [Reflection.Assembly]::LoadFile($setup)
$stream = $assembly.GetManifestResourceStream('AppZip')
if ($null -eq $stream) { throw 'Missing embedded AppZip' }
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $embeddedHash = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
} finally {
    $stream.Dispose()
    $sha.Dispose()
}
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
if ($embeddedHash -ne $zipHash) { throw 'Embedded ZIP differs from delivered ZIP' }
if ((Get-Item -LiteralPath $setup).VersionInfo.FileVersion -ne '0.3.9.0') { throw 'Incorrect Setup version' }
$record = @{
    setup_sha256 = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash.ToLowerInvariant()
    embedded_zip_sha256 = $embeddedHash
    version = '0.3.9.0'
}
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verified-setup-player-final.json') -Encoding UTF8
$record | ConvertTo-Json
