# YomiHub Lite (Android 5.0+/6.0): Mangayomi v0.5.2 engine + YomiHub branding, Flutter 3.29.3
$ErrorActionPreference = 'Continue'
# paths without spaces: MinGW's gcc (Rust build scripts) breaks on "D:\A.I Project"
if (-not (Test-Path 'Y:\tools')) { & subst.exe Y: 'D:\A.I Project\yh' }
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
if (Test-Path 'Y:\tools') {
  $YH = 'Y:'; $TOOLS = 'Y:\tools'
  $env:JAVA_HOME = "$TOOLS\jdk"; $env:ANDROID_HOME = "$TOOLS\android-sdk"; $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
  $env:RUSTUP_HOME = "$TOOLS\rustup"; $env:CARGO_HOME = "$TOOLS\cargo"; $env:GRADLE_USER_HOME = "Y:\gradle-home"
  $env:PATH = "$TOOLS\git\cmd;$TOOLS\mingw64\bin;$TOOLS\jdk\bin;$TOOLS\cargo\bin;$TOOLS\android-sdk\cmdline-tools\latest\bin;$TOOLS\android-sdk\platform-tools;" + $env:PATH
} else { "WARNING: Y: subst not available" }
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -ErrorAction SilentlyContinue
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
# MinGW resolves its own real path; "D:\A.I Project" (space) breaks its linker -> a copy at D:\yhmingw64
if (-not (Test-Path 'D:\yhmingw64\bin\x86_64-w64-mingw32-gcc.exe')) {
  "copying MinGW to D:\yhmingw64"
  & robocopy.exe "D:\A.I Project\yh\tools\mingw64" 'D:\yhmingw64' /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
}
$env:PATH = 'D:\yhmingw64\bin;' + $env:PATH
$F = "$TOOLS\flutter329"
if (-not (Test-Path "$F\bin\flutter.bat")) {
  "downloading Flutter 3.29.3"
  $zip = "$YH\flutter_3.29.3.zip"
  if (-not (Test-Path $zip)) { & curl.exe -L --fail --retry 5 -o $zip "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.29.3-stable.zip" }
  $tmp = "$YH\_f329"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  & tar.exe -xf $zip -C (New-Item -ItemType Directory -Force $tmp).FullName
  Move-Item "$tmp\flutter" $F
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not (Test-Path "$TOOLS\android-sdk\cmake\3.18.1\bin\cmake.exe")) {
  "installing cmake 3.18.1"
  $sm = Get-ChildItem "$TOOLS\android-sdk\cmdline-tools" -Recurse -Filter sdkmanager.bat | Select-Object -First 1
  ("y`n" * 10) | & $sm.FullName --sdk_root="$TOOLS\android-sdk" --install "cmake;3.18.1" 2>&1 | Select-Object -Last 3
}
$env:FLUTTER_ROOT = $F
$env:PUB_CACHE = "$YH\pub-cache-329"
$env:PATH = "$F\bin;$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
$L = "$YH\lite\mangayomi"
if (-not (Test-Path "$L\pubspec.yaml")) {
  New-Item -ItemType Directory -Force "$YH\lite" | Out-Null
  & git clone -q --depth 1 --branch v0.5.2 https://github.com/kodjodevf/mangayomi.git $L
}
& tar.exe -xzf 'D:\Claude A.I\dev\x019\lite_overlay.tgz' -C $L
$pw = (Get-Content "$YH\keystore-password.txt" -Raw).Trim()
Set-Content "$L\android\key.properties" ("storePassword=$pw`nkeyPassword=$pw`nkeyAlias=yomihub`nstoreFile=" + ("$YH\yomihub-release.jks" -replace '\\','/')) -Encoding ascii
$fl = ($F -replace '\\','\\'); $sd = ($env:ANDROID_HOME -replace '\\','\\')
# Gradle 8.3 of this engine needs JDK 17 (Flutter would pick Android Studio's newer JBR)
$gp = "$L\android\gradle.properties"
if (-not (Select-String -Path $gp -Pattern 'org.gradle.java.home' -Quiet)) { Add-Content $gp ("`norg.gradle.java.home=" + ("$TOOLS\jdk" -replace '\\','/')) }
Set-Content "$L\android\local.properties" "flutter.sdk=$fl`nsdk.dir=$sd" -Encoding ascii
Push-Location $L
& flutter.bat --version 2>&1 | Select-Object -First 3
& flutter.bat config --no-analytics 2>&1 | Out-Null
& flutter.bat pub get 2>&1 | Select-Object -Last 5
$t0 = Get-Date
& flutter.bat build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64 2>&1 | Select-Object -Last 40
"build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t0).TotalMinutes
Pop-Location
$out = 'D:\Claude A.I\output'
foreach ($abi in 'arm64-v8a','armeabi-v7a','x86_64') {
  $f = "$L\build\app\outputs\flutter-apk\app-$abi-release.apk"
  if (Test-Path $f) { Copy-Item $f "$out\YomiHub-Lite-0.1.9-$abi.apk" -Force; "Lite $abi " + [math]::Round((Get-Item $f).Length/1MB,1) + " MB" }
}
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
