param([switch]$Tv)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
. "$projectRoot/common.ps1"
$aapt = 'D:/yh/tools/android-sdk/build-tools/36.0.0/aapt.exe'
$signer = 'D:/yh/tools/android-sdk/build-tools/36.0.0/apksigner.bat'
$prefix = if ($Tv) { 'YumiHub-Android-TV' } else { 'YomiHub' }
$expectedLabel = if ($Tv) { 'YumiHub Android TV' } else { 'YomiHub' }
$records = @()
foreach ($abi in 'armeabi-v7a','arm64-v8a','x86_64') {
    $expectedCode = @{ 'armeabi-v7a' = 1031; 'arm64-v8a' = 2031; 'x86_64' = 4031 }[$abi]
    $file = "$projectRoot/output/$prefix-0.3.9-$abi.apk"
    $metadata = (& $aapt dump badging $file) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $metadata -notmatch "versionName='0.3.9'" -or $metadata -notmatch "versionCode='$expectedCode'" -or $metadata -notmatch "name='com.yomihub.app'" -or $metadata -notmatch "application-label:'$expectedLabel'") {
        throw "Incorrect APK metadata: $file"
    }
    $signature = (& $signer verify --verbose --print-certs $file) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Invalid APK signature: $file" }
    $digest = [regex]::Match($signature, 'Signer #1 certificate SHA-256 digest: ([a-fA-F0-9]+)').Groups[1].Value
    $old = "$projectRoot/output/$prefix-0.3.8-$abi.apk"
    $oldSignature = (& $signer verify --print-certs $old) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Cannot verify previous signer: $old" }
    $oldDigest = [regex]::Match($oldSignature, 'Signer #1 certificate SHA-256 digest: ([a-fA-F0-9]+)').Groups[1].Value
    if (-not $digest -or $digest -ne $oldDigest) { throw "Signer differs from 0.3.8: $file" }
    $records += [pscustomobject]@{ file = [IO.Path]::GetFileName($file); version = '0.3.9'; code = $expectedCode; label = $expectedLabel; signatureValid = $true; sameSignerAs038 = $true; signerSha256 = $digest }
}
$records | ConvertTo-Json | Set-Content -LiteralPath "$PSScriptRoot/verified-$prefix-apks.json" -Encoding UTF8
$records | Select-Object file,version,code,signatureValid,sameSignerAs038 | Format-Table -AutoSize
