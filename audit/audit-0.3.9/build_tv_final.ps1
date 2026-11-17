$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
. "$projectRoot/common.ps1"
$buildRoot = 'D:/A.I Project/yh/build/mangayomi'
$labelFile = Join-Path $buildRoot 'android/app/src/main/res/values/strings.xml'
$originalBytes = [IO.File]::ReadAllBytes($labelFile)
$utf8 = [Text.UTF8Encoding]::new($false)
$version = '0.3.9'
foreach ($abi in 'armeabi-v7a','arm64-v8a','x86_64') {
    if (-not (Test-Path "$projectRoot/output/YomiHub-$version-$abi.apk")) {
        throw "Package the final mobile APK first: $abi"
    }
}
Push-Location $buildRoot
try {
    $originalText = $utf8.GetString($originalBytes)
    $tvText = $originalText.Replace('<string name="app_name">YomiHub</string>', '<string name="app_name">YumiHub Android TV</string>')
    if ($tvText -eq $originalText) { throw 'Expected mobile application label not found' }
    [IO.File]::WriteAllText($labelFile, $tvText, $utf8)
    & 'D:/yh/tools/flutter/bin/flutter.bat' build apk --no-pub --release --split-per-abi --target-platform android-arm,android-arm64,android-x64 --split-debug-info D:/yh/symbols --dart-define=IS_TV_BUILD=true '--dart-define=APP_NAME=YumiHub Android TV' *> "$PSScriptRoot/build-tv-final.log"
    if ($LASTEXITCODE -ne 0) { throw "TV build failed: $LASTEXITCODE" }
    foreach ($abi in 'armeabi-v7a','arm64-v8a','x86_64') {
        Copy-Item -LiteralPath "$buildRoot/build/app/outputs/flutter-apk/app-$abi-release.apk" -Destination "$projectRoot/output/YumiHub-Android-TV-$version-$abi.apk"
    }
} finally {
    [IO.File]::WriteAllBytes($labelFile, $originalBytes)
    Pop-Location
}
